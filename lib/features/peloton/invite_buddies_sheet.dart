import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ridewindow/core/analytics_events.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/group_crest.dart';
import 'package:ridewindow/features/peloton/group_error_text.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/analytics_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/services/peloton_gateway.dart';

/// Nodigt maatjes of een hele groep uit voor een concreet tijdvak (epic #62,
/// CLUB-12).
///
/// Maakt de gedeelde rit pas aan wanneer je werkelijk iemand uitnodigt — een
/// `group_rides`-rij zonder deelnemers is niets meer dan ruis in de database,
/// en zou ook in "ritten die jij organiseert" opduiken terwijl er niemand
/// gevraagd is. Een groepsrit is daarop de uitzondering: daar is de groep de
/// deelnemer, en de leden zien de rit via `group_id` (0012, `is_ride_member`).
///
/// **Slice 2 van epic #65.** Na het kiezen van maatjes vraagt de app welke
/// vensters je voorlegt. Kies je er meer dan een, dan komen ze als keuze bij de
/// rit te staan en geeft iedereen aan wanneer hij kan. Kies je er een, dan is
/// het precies wat het altijd was: een uitnodiging voor dat ene tijdvak.
///
/// **Groep of maatjes (fase 35).** Zit je in een groep, dan kies je eerst met
/// wie je rijdt: een groep, of losse maatjes -- nooit allebei. Een
/// participant-rij van een niet-lid op een groepsrit geeft geen toegang
/// (0012), dus "groep plus Fleur" zou Fleur een uitnodiging beloven voor een
/// rit die ze nooit te zien krijgt. Zonder groepen is het scherm wat het was.
///
/// Bestaat er al een eigen gewone rit op exact dit tijdvak, dan wordt die
/// hergebruikt. Zonder die controle levert twee keer uitnodigen twee
/// groepsritten op, en dat is precies de duplicatiefout die plan 21-13 al eens
/// heeft opgeleverd — in een andere gedaante, met dezelfde oorzaak: een sleutel
/// die uit tijd is afgeleid en niet consequent vergeleken wordt.
Future<void> showInviteBuddiesSheet(
  BuildContext context,
  WidgetRef ref, {
  required DateTime start,
  required DateTime end,
  required double plannedScore,
}) async {
  // Alles wat van `ref` of `context` komt vóór de eerste await (les 34-04):
  // na een await kan het scherm al weg zijn.
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final gateway = ref.read(pelotonGatewayProvider);
  final myName = ref.read(profileProvider).value?.userName;
  final me = ref.read(currentUserIdProvider);

  final List<Friend> friends;
  try {
    friends = await ref.read(friendsProvider.future);
  } catch (error) {
    // Stond tot 2026-09-21 buiten de try/catch van het versturen: een
    // netwerkfout bij het ophalen van je maatjes liet de uitnodigknop
    // zichtbaar niets doen (sweep "stille takken").
    debugPrint('Peloton: maatjes ophalen mislukt: $error');
    messenger.showSnackBar(SnackBar(content: Text(s.pelotonInviteFailed)));
    return;
  }

  // Een groepenfout mag het uitnodigen van maatjes niet blokkeren: dan is het
  // scherm gewoon het oude.
  List<PelotonGroup> groups;
  try {
    groups = await ref.read(myGroupsProvider.future);
  } catch (error) {
    debugPrint('Peloton: groepen ophalen mislukt: $error');
    groups = const [];
  }

  if (!context.mounted) return;

  if (friends.isEmpty && groups.isEmpty) {
    messenger.showSnackBar(
      SnackBar(content: Text(s.pelotonNeedFriendsFirst)),
    );
    return;
  }

  final target = await showModalBottomSheet<_InviteTarget>(
    context: context,
    showDragHandle: true,
    isScrollControlled: groups.isNotEmpty,
    builder: (context) =>
        _InviteTargetPicker(friends: friends, groups: groups),
  );

  if (target == null) return;
  if (!context.mounted) return;

  switch (target) {
    case _GroupTarget(:final group):
      await _inviteGroup(
        context,
        ref,
        group: group,
        start: start,
        end: end,
        plannedScore: plannedScore,
        myName: myName,
        messenger: messenger,
        gateway: gateway,
      );
    case _FriendsTarget(:final friendIds):
      if (friendIds.isEmpty) return;
      await _inviteFriends(
        context,
        ref,
        friends: friends,
        selected: friendIds,
        start: start,
        end: end,
        plannedScore: plannedScore,
        myName: myName,
        me: me,
        messenger: messenger,
        gateway: gateway,
      );
  }
}

/// Het groepspad: één groepsrit met `group_id`, zonder participant-rijen.
///
/// Geen `inviteToRide` per lid. Wie er bij het uitzetten in de groep zat is
/// een momentopname; de rit hoort bij de groep zoals die is, en een nieuw lid
/// ziet hem daarom ook (35-CONTEXT).
Future<void> _inviteGroup(
  BuildContext context,
  WidgetRef ref, {
  required PelotonGroup group,
  required DateTime start,
  required DateTime end,
  required double plannedScore,
  required String? myName,
  required ScaffoldMessengerState messenger,
  required PelotonGateway gateway,
}) async {
  final s = S.of(context);

  // Twee groepsritten van dezelfde groep op hetzelfde tijdvak zijn er één te
  // veel, ook als een ander lid de eerste uitzette. Vóór het vensterscherm,
  // zodat niemand eerst vensters kiest om daarna te horen dat het niet kan.
  try {
    final existing = await ref.read(groupRidesProvider.future);
    final duplicate = existing.any(
      (r) =>
          r.groupId == group.id &&
          r.start.isAtSameMomentAs(start) &&
          r.end.isAtSameMomentAs(end),
    );
    if (duplicate) {
      messenger.showSnackBar(
        SnackBar(content: Text(s.groupRideAlreadyExists(group.name))),
      );
      ref.invalidate(groupRidesProvider);
      return;
    }
  } catch (error) {
    debugPrint('Peloton: groepsritten ophalen mislukt: $error');
    messenger.showSnackBar(SnackBar(content: Text(s.pelotonInviteFailed)));
    return;
  }

  if (!context.mounted) return;

  final List<RideSlot>? windows;
  try {
    windows = await _pickWindows(
      context,
      ref,
      start: start,
      end: end,
      plannedScore: plannedScore,
    );
  } catch (error) {
    debugPrint('Peloton: vensters voorleggen mislukt: $error');
    messenger.showSnackBar(SnackBar(content: Text(s.pelotonInviteFailed)));
    return;
  }
  if (windows == null || windows.isEmpty) return;

  try {
    final ride = await gateway.createGroupRide(
      start: start,
      end: end,
      plannedScore: plannedScore,
      ownerName: myName,
      groupId: group.id,
    );

    if (windows.length > 1) {
      await gateway.proposeOptions(
        rideId: ride.id,
        windows: [
          for (final w in windows)
            (start: w.start, end: w.end, plannedScore: w.overallScore),
        ],
      );
    }

    ref.invalidate(groupRidesProvider);
    // Geen groepsnaam en geen id: welke groep is geen getal maar een club.
    trackEvent(
      ref,
      kEvPelotonInvite,
      props: {
        'kind': 'group_ride',
        'windows': windows.length,
      },
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          windows.length > 1
              ? s.pelotonWindowsSent(windows.length)
              : s.groupRideSent(group.name),
        ),
      ),
    );
  } catch (error) {
    // Een groepsfout heeft een eigen zin (bijv. je bent net uit de groep
    // gezet); al het andere de gewone uitnodigfout, om dezelfde reden als in
    // [_inviteFriends]: een melding die naar de verkeerde oorzaak wijst is
    // erger dan een vage.
    debugPrint('Peloton: groepsrit uitzetten mislukt: $error');
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error is GroupException
              ? groupErrorTextOf(s, error, groupName: group.name)
              : s.pelotonInviteFailed,
        ),
      ),
    );
  }
}

/// Het maatjespad: zoals het altijd was, op het hergebruik na.
///
/// Tot fase 35 werd elke rit op hetzelfde tijdvak hergebruikt, ook een
/// groepsrit of andermans rit. `inviteToRide` faalt dan op RLS (andermans rit)
/// of hangt een niet-lid aan een groepsrit waar hij niets van ziet (0012).
/// Alleen een eigen gewone rit is dus te hergebruiken.
Future<void> _inviteFriends(
  BuildContext context,
  WidgetRef ref, {
  required List<Friend> friends,
  required Set<String> selected,
  required DateTime start,
  required DateTime end,
  required double plannedScore,
  required String? myName,
  required String? me,
  required ScaffoldMessengerState messenger,
  required PelotonGateway gateway,
}) async {
  final s = S.of(context);

  // Stap 2: welke vensters leg je voor? Het venster waar je vandaan komt staat
  // aangevinkt; de rest komt uit dezelfde slot-generator die Home voedt, zodat
  // de keuze over vensters gaat die de app ook echt aanbeveelt.
  //
  // Ook dit stond buiten de try/catch: een fout in het voorleggen (bijv. de
  // sheet zelf) liet de knop stil niets doen.
  final List<RideSlot>? windows;
  try {
    windows = await _pickWindows(
      context,
      ref,
      start: start,
      end: end,
      plannedScore: plannedScore,
    );
  } catch (error) {
    debugPrint('Peloton: vensters voorleggen mislukt: $error');
    messenger.showSnackBar(SnackBar(content: Text(s.pelotonInviteFailed)));
    return;
  }
  if (windows == null || windows.isEmpty) return;

  try {
    final existing = await ref.read(groupRidesProvider.future);
    final mine = existing.where(
      (r) =>
          r.isOwnedBy(me) &&
          r.groupId == null &&
          r.start.isAtSameMomentAs(start) &&
          r.end.isAtSameMomentAs(end),
    );

    final ride = mine.isNotEmpty
        ? mine.first
        : await gateway.createGroupRide(
            start: start,
            end: end,
            plannedScore: plannedScore,
            ownerName: myName,
          );

    for (final friend in friends.where((f) => selected.contains(f.userId))) {
      await gateway.inviteToRide(
        rideId: ride.id,
        friendId: friend.userId,
        displayName: friend.displayName,
      );
    }

    // Meer dan een venster is een keuze; een venster is gewoon de rit zelf.
    // In dat tweede geval blijft `group_ride_options` leeg -- een tabel met
    // een rij die nergens over gaat, is erger dan een lege.
    if (windows.length > 1) {
      await gateway.proposeOptions(
        rideId: ride.id,
        windows: [
          for (final w in windows)
            (start: w.start, end: w.end, plannedScore: w.overallScore),
        ],
      );
    }

    ref.invalidate(groupRidesProvider);
    // Hoeveel maatjes tegelijk, niet wie. Een aantal is een getal; een naam
    // zou een persoon zijn. `windows` erbij omdat de vraag van slice 2 is of
    // mensen werkelijk meer dan een venster voorleggen.
    trackEvent(
      ref,
      kEvPelotonInvite,
      props: {
        'kind': 'ride',
        'count': selected.length,
        'windows': windows.length,
      },
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          windows.length > 1
              ? s.pelotonWindowsSent(windows.length)
              : s.pelotonInviteSent,
        ),
      ),
    );
  } catch (error) {
    // Een uitnodiging die niet aankomt mag geen scherm laten crashen; de rit
    // zelf is niet veranderd, dus opnieuw proberen is veilig.
    //
    // Bewust een eigen melding en niet `pelotonCodeInvalid` ("die code werkt
    // niet"). Dat hergebruik heeft op 2026-09-06 een halve sessie gekost: het
    // uitnodigen faalde op een RLS-fout in `group_rides`, maar het scherm
    // sprak over een verlopen code terwijl er in dit pad helemaal geen code
    // bestaat. Een foutmelding die naar de verkeerde oorzaak wijst is erger
    // dan een vage.
    debugPrint('Peloton: uitnodigen mislukt: $error');
    messenger.showSnackBar(SnackBar(content: Text(s.pelotonInviteFailed)));
  }
}

/// Wat de eerste stap oplevert: een groep of een set maatjes, nooit allebei.
sealed class _InviteTarget {
  const _InviteTarget();
}

final class _GroupTarget extends _InviteTarget {
  const _GroupTarget(this.group);
  final PelotonGroup group;
}

final class _FriendsTarget extends _InviteTarget {
  const _FriendsTarget(this.friendIds);
  final Set<String> friendIds;
}

/// Stap 1: met wie rijd je? (schets 016)
///
/// Zonder groepen is dit exact de oude maatjeskiezer: zelfde titel, zelfde
/// vinkjes, zelfde knop. Met groepen staat er één keuze boven de maatjes, en
/// de twee sluiten elkaar uit.
class _InviteTargetPicker extends StatefulWidget {
  const _InviteTargetPicker({required this.friends, required this.groups});

  final List<Friend> friends;
  final List<PelotonGroup> groups;

  @override
  State<_InviteTargetPicker> createState() => _InviteTargetPickerState();
}

class _InviteTargetPickerState extends State<_InviteTargetPicker> {
  final _selected = <String>{};
  String? _groupId;

  bool get _hasGroups => widget.groups.isNotEmpty;

  PelotonGroup? get _group {
    for (final g in widget.groups) {
      if (g.id == _groupId) return g;
    }
    return null;
  }

  void _confirm() {
    final group = _group;
    Navigator.of(context).pop<_InviteTarget>(
      group != null ? _GroupTarget(group) : _FriendsTarget({..._selected}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final groupChosen = _groupId != null;
    final canConfirm = groupChosen || _selected.isNotEmpty;

    Widget sectionHeader(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );

    final friendTiles = [
      for (final friend in widget.friends)
        CheckboxListTile(
          value: _selected.contains(friend.userId),
          title: Text(friend.label(s.pelotonUnnamedFriend)),
          // Een gekozen groep sluit losse maatjes uit.
          onChanged: groupChosen
              ? null
              : (checked) => setState(() {
                    if (checked ?? false) {
                      _selected.add(friend.userId);
                    } else {
                      _selected.remove(friend.userId);
                    }
                  }),
        ),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              _hasGroups ? s.groupRidePickTitle : s.pelotonPickFriends,
              style: theme.textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (_hasGroups) ...[
                  sectionHeader(s.groupRideSectionGroup),
                  RadioGroup<String>(
                    groupValue: _groupId,
                    onChanged: (id) => setState(() => _groupId = id),
                    child: Column(
                      children: [
                        for (final g in widget.groups)
                          RadioListTile<String>(
                            value: g.id,
                            toggleable: true,
                            // Aangevinkte maatjes sluiten een groep uit.
                            enabled: _selected.isEmpty,
                            secondary: GroupCrest(name: g.name, size: 36),
                            title: Text(
                              g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              g.id == _groupId
                                  ? '${s.groupMemberCount(g.memberCount)}'
                                      ' · ${s.groupRideEveryMemberSees}'
                                  : s.groupMemberCount(g.memberCount),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.friends.isNotEmpty)
                    sectionHeader(s.groupRideSectionFriends),
                ],
                ...friendTiles,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canConfirm ? _confirm : null,
                child: Text(
                  _hasGroups ? s.groupRideNextWindows : s.pelotonInviteAction,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stap 2 van het uitnodigen: welke vensters leg je voor?
///
/// Geeft `null` bij annuleren en een lijst bij bevestigen. Het venster waar de
/// gebruiker vandaan komt zit er altijd in -- ook als de slot-generator hem
/// inmiddels niet meer aanbeveelt, want daar begon deze handeling.
Future<List<RideSlot>?> _pickWindows(
  BuildContext context,
  WidgetRef ref, {
  required DateTime start,
  required DateTime end,
  required double plannedScore,
}) async {
  final state = ref.read(slotsProvider);
  final generated = switch (state) {
    SlotsLoaded(:final slots) => slots,
  };

  final origin = RideSlot(
    start: start,
    end: end,
    overallScore: plannedScore,
    tier: rideTierFromScore(plannedScore),
    hours: const [],
  );

  // Het eigen venster vooraan, de rest op score. Geen dubbele: twee keer
  // hetzelfde tijdvak voorleggen is geen keuze maar een fout, en de database
  // weigert het ook (`group_ride_options_unique`).
  final candidates = <RideSlot>[origin];
  for (final slot in generated) {
    final same = slot.start.isAtSameMomentAs(origin.start) &&
        slot.end.isAtSameMomentAs(origin.end);
    if (!same) candidates.add(slot);
  }

  return showModalBottomSheet<List<RideSlot>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _WindowPicker(candidates: candidates),
  );
}

class _WindowPicker extends StatefulWidget {
  const _WindowPicker({required this.candidates});

  final List<RideSlot> candidates;

  @override
  State<_WindowPicker> createState() => _WindowPickerState();
}

class _WindowPickerState extends State<_WindowPicker> {
  /// Het eerste vakje staat aan: dat is het venster waar de gebruiker vandaan
  /// komt. Bevestigen zonder iets aan te raken levert dus precies de
  /// uitnodiging die de app voor slice 2 ook al gaf.
  late final Set<int> _selected = {0};

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dayFormat =
        DateFormat('EEE d MMM', locale == 'en' ? 'en_US' : 'nl_NL');

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.pelotonPickWindows,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  s.pelotonPickWindowsHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.candidates.length,
              itemBuilder: (context, i) {
                final slot = widget.candidates[i];
                return CheckboxListTile(
                  value: _selected.contains(i),
                  onChanged: (on) => setState(() {
                    if (on ?? false) {
                      _selected.add(i);
                    } else {
                      _selected.remove(i);
                    }
                  }),
                  title: Text(
                    '${dayFormat.format(slot.start)}  '
                    '${_hhmm(slot.start)} – ${_hhmm(slot.end)}',
                  ),
                  subtitle: Text('${slot.overallScore.round()}'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(s.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  // Niets aangevinkt is geen uitnodiging. Uitgrijzen en niet
                  // stilzwijgend het eerste venster terugsturen: dan zou de
                  // app iets versturen wat de gebruiker net heeft uitgezet.
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop([
                            for (final i in _selected.toList()..sort())
                              widget.candidates[i],
                          ]),
                  child: Text(s.pelotonInviteAction),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
