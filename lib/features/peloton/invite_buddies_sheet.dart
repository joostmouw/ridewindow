import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ridewindow/core/analytics_events.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/analytics_provider.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';

/// Nodigt maatjes uit voor een concreet tijdvak (epic #62).
///
/// Maakt de gedeelde rit pas aan wanneer je werkelijk iemand uitnodigt — een
/// `group_rides`-rij zonder deelnemers is niets meer dan ruis in de database,
/// en zou ook in "ritten die jij organiseert" opduiken terwijl er niemand
/// gevraagd is.
///
/// **Slice 2 van epic #65.** Na het kiezen van maatjes vraagt de app welke
/// vensters je voorlegt. Kies je er meer dan een, dan komen ze als keuze bij de
/// rit te staan en geeft iedereen aan wanneer hij kan. Kies je er een, dan is
/// het precies wat het altijd was: een uitnodiging voor dat ene tijdvak.
///
/// Bestaat er al een gedeelde rit van jou op exact dit tijdvak, dan wordt die
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
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final friends = await ref.read(friendsProvider.future);

  if (!context.mounted) return;

  if (friends.isEmpty) {
    messenger.showSnackBar(
      SnackBar(content: Text(s.pelotonNeedFriendsFirst)),
    );
    return;
  }

  final selected = await showModalBottomSheet<Set<String>>(
    context: context,
    showDragHandle: true,
    builder: (context) => _FriendPicker(friends: friends),
  );

  if (selected == null || selected.isEmpty) return;
  if (!context.mounted) return;

  // Stap 2: welke vensters leg je voor? Het venster waar je vandaan komt staat
  // aangevinkt; de rest komt uit dezelfde slot-generator die Home voedt, zodat
  // de keuze over vensters gaat die de app ook echt aanbeveelt.
  final windows = await _pickWindows(
    context,
    ref,
    start: start,
    end: end,
    plannedScore: plannedScore,
  );
  if (windows == null || windows.isEmpty) return;

  final gateway = ref.read(pelotonGatewayProvider);
  final myName = ref.read(profileProvider).value?.userName;

  try {
    final existing = await ref.read(groupRidesProvider.future);
    final mine = existing.where(
      (r) => r.start.isAtSameMomentAs(start) && r.end.isAtSameMomentAs(end),
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
    trackEvent(ref, kEvPelotonInvite, props: {
      'kind': 'ride',
      'count': selected.length,
      'windows': windows.length,
    });
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

class _FriendPicker extends StatefulWidget {
  const _FriendPicker({required this.friends});

  final List<Friend> friends;

  @override
  State<_FriendPicker> createState() => _FriendPickerState();
}

class _FriendPickerState extends State<_FriendPicker> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(s.pelotonPickFriends, style: theme.textTheme.titleLarge),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final friend in widget.friends)
                  CheckboxListTile(
                    value: _selected.contains(friend.userId),
                    title: Text(friend.label(s.pelotonUnnamedFriend)),
                    onChanged: (checked) => setState(() {
                      if (checked ?? false) {
                        _selected.add(friend.userId);
                      } else {
                        _selected.remove(friend.userId);
                      }
                    }),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                child: Text(s.pelotonInviteAction),
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
