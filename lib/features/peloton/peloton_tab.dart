import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/services/invite_code.dart';
import 'package:ridewindow/features/peloton/invite_landing_screen.dart';
import 'package:ridewindow/features/shared/section_card.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/theme/app_icons.dart';

/// De Peloton-tab onder "Rides" (epic #62).
///
/// Bevat wat je met je maatjes doet: wie het zijn, uitnodigingen die je krijgt,
/// en ritten die jij organiseert. Bewust géén losse route — Joost wilde dit
/// naast "Mijn ritten" hebben, want uitnodigen begint bij een rit.
class PelotonTab extends ConsumerStatefulWidget {
  const PelotonTab({super.key});

  @override
  ConsumerState<PelotonTab> createState() => _PelotonTabState();
}

class _PelotonTabState extends ConsumerState<PelotonTab> {
  final _codeController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Ververst alles wat van de cloud komt na een wijziging. Eén plek, zodat
  /// een nieuwe actie niet per ongeluk maar de helft bijwerkt.
  void _invalidateAll() {
    ref.invalidate(friendsProvider);
    ref.invalidate(groupRidesProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareInvite() => _run(() async {
        final s = S.of(context);
        final code =
            await ref.read(pelotonGatewayProvider).createFriendInvite();
        if (!mounted) return;
        // De code staat óók in de tekst, niet alleen in de link: de link opent
        // vandaag de PWA en niet de native app (daarvoor zijn Android App
        // Links nodig), dus wie de app al heeft is met overtypen sneller uit.
        await Share.share(
          s.pelotonInviteShareLink(inviteLinkFor(code), code),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.pelotonYourCode(code))),
        );
      });

  Future<void> _redeemCode() => _run(() async {
        final s = S.of(context);
        final raw = _codeController.text;
        if (normalizeInviteCode(raw).isEmpty) return;
        try {
          final friend =
              await ref.read(pelotonGatewayProvider).redeemFriendInvite(raw);
          _codeController.clear();
          _invalidateAll();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s.pelotonFriendAdded(friend.label(s.pelotonUnnamedFriend)),
              ),
            ),
          );
        } catch (_) {
          // Elke fout van de RPC betekent voor de gebruiker hetzelfde: deze
          // code doet het niet. Het onderscheid tussen "bestaat niet" en
          // "verlopen" prijsgeven zou verklappen welke codes wél bestaan.
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.pelotonCodeInvalid)),
          );
        }
      });

  Future<void> _respond(GroupRide ride, {required bool accepted}) =>
      _run(() async {
        await ref
            .read(pelotonGatewayProvider)
            .respondToRide(rideId: ride.id, accepted: accepted);
        _invalidateAll();
      });

  /// Terugkomen op een "ik ga mee".
  ///
  /// **Waarom hier een ongedaan-maken zit en bij [_respond] niet.** Afzeggen is
  /// een deur die maar één kant op gaat: een rit met status `declined` valt uit
  /// [pendingRideInvitesProvider] (die filtert op `invited`), uit
  /// [joinedGroupRidesProvider] (die filtert op `accepted`) en uit
  /// [ownedGroupRidesProvider] (hij is niet van jou). Hij is daarna nergens
  /// meer aan te wijzen, terwijl de rij in de database gewoon bestaat en het
  /// RLS-beleid `group_ride_participants_update_own` een terugweg toestaat.
  /// Een misklik zou dus onherstelbaar zijn zonder dat daar een technische
  /// reden voor is.
  ///
  /// De snackbar overbrugt precies dat gat. Wat hij níét oplost: morgen alsnog
  /// van gedachten veranderen. Daarvoor zou een afgezegde rit zichtbaar moeten
  /// blijven, en dat is een aparte keuze — zie BACKLOG.md.
  Future<void> _withdraw(GroupRide ride) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await _respond(ride, accepted: false);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(s.pelotonWithdrawn),
        action: SnackBarAction(
          label: s.pelotonUndo,
          onPressed: () async {
            await _respond(ride, accepted: true);
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(content: Text(s.pelotonRejoined)),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) return _SignedOutState(s: s, theme: theme);

    final friends = ref.watch(friendsProvider);
    final invites = ref.watch(pendingRideInvitesProvider);
    final owned = ref.watch(ownedGroupRidesProvider);
    final joined = ref.watch(joinedGroupRidesProvider);

    return RefreshIndicator(
      onRefresh: () async => _invalidateAll(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (invites.value?.isNotEmpty ?? false)
            SectionCard(
              title: s.pelotonPendingInvites,
              children: [
                for (final ride in invites.value!)
                  _InviteRow(
                    ride: ride,
                    busy: _busy,
                    onAccept: () => _respond(ride, accepted: true),
                    onDecline: () => _respond(ride, accepted: false),
                  ),
              ],
            ),
          // Volgorde: eerst waar je aan meedoet, dan wat je organiseert, en
          // pas daarna het beheer van je maatjes.
          //
          // Het stond andersom, en dan hing de inhoud die ertoe doet onder een
          // invulveld voor een uitnodigingscode -- je opent deze tab om te zien
          // welke ritten er lopen, niet om een code in te tikken (waargenomen
          // door Joost op het toestel, fase 25 in EIGEN-GEZICHT.md).
          //
          // Voor een verse gebruiker verandert er niets: zonder ritten zijn de
          // twee blokken hierboven verborgen en is de maatjeskaart met zijn
          // uitnodigingsknop meteen het eerste wat je ziet.
          if (joined.value?.isNotEmpty ?? false)
            SectionCard(
              title: s.pelotonJoinedRides,
              children: [
                for (final ride in joined.value!)
                  _JoinedRideRow(
                    ride: ride,
                    s: s,
                    busy: _busy,
                    onWithdraw: () => _withdraw(ride),
                  ),
              ],
            ),
          if (owned.value?.isNotEmpty ?? false)
            SectionCard(
              title: s.pelotonOwnedRides,
              children: [
                for (final ride in owned.value!)
                  _OwnedRideRow(ride: ride, s: s),
              ],
            ),
          SectionCard(
            title: s.pelotonFriends,
            children: [
              friends.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _ErrorRow(
                  label: s.pelotonRetry,
                  onRetry: _invalidateAll,
                ),
                data: (list) => list.isEmpty
                    ? _EmptyFriends(s: s, theme: theme)
                    : Column(
                        children: [
                          for (final friend in list)
                            _FriendRow(
                              friend: friend,
                              fallback: s.pelotonUnnamedFriend,
                              onRemove: _busy
                                  ? null
                                  : () => _run(() async {
                                        await ref
                                            .read(pelotonGatewayProvider)
                                            .removeFriend(friend.userId);
                                        _invalidateAll();
                                      }),
                            ),
                        ],
                      ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              // De twee manieren om er een maatje bij te krijgen staan ín de
              // maatjeskaart, niet eronder als losse besturingselementen. Ze
              // hóren bij die lijst -- dat is wat een kaart zegt.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _busy ? null : _shareInvite,
                    icon: const Icon(AppIcons.userPlus),
                    label: Text(s.pelotonInviteFriend),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: s.pelotonCodeHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _redeemCode(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _busy ? null : _redeemCode,
                      child: Text(s.pelotonJoin),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState({required this.s, required this.theme});

  final S s;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.usersThree,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(s.pelotonSignedOut, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              s.pelotonSignedOutHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends({required this.s, required this.theme});

  final S s;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.pelotonNoFriends, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            s.pelotonNoFriendsHint,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// `_SectionHeader` stond hier tot 2026-09-07 en was de dérde kopie van
// dezelfde koptekst in dit project. Hij zit nu in `SectionCard`
// (features/shared/), samen met het vlak eronder -- want een kop zonder
// dat vlak maakt geen groep, en dat is precies wat deze tab miste.

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.fallback,
    this.onRemove,
  });

  final Friend friend;
  final String fallback;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final name = friend.label(fallback);
    return ListTile(
      leading: CircleAvatar(child: Text(name.characters.first.toUpperCase())),
      title: Text(name),
      trailing: IconButton(
        icon: const Icon(AppIcons.userMinus),
        tooltip: S.of(context).pelotonRemoveFriend,
        onPressed: onRemove,
      ),
    );
  }
}

/// Was een eigen `Card` met eigen marge. Sinds de uitnodigingen in een
/// [SectionCard] staan zou dat een kaart in een kaart zijn, dus dit is nu een
/// gewone regel met dezelfde inspringing als de tegels eromheen.
class _InviteRow extends StatelessWidget {
  const _InviteRow({
    required this.ride,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final GroupRide ride;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.pelotonInvitedBy(ride.ownerName ?? s.pelotonUnnamedFriend),
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(_formatRide(ride), style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: busy ? null : onDecline,
                child: Text(s.pelotonDecline),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: busy ? null : onAccept,
                child: Text(s.pelotonAccept),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Een gedeelde rit van iemand anders waar jij ja op hebt gezegd.
///
/// Bewust met de naam van de organisator in de ondertitel en niet met een
/// deelnemersteller: bij een rit die niet van jou is, is "van wie is dit" de
/// eerste vraag, niet "hoeveel man gaat er mee".
class _JoinedRideRow extends StatelessWidget {
  const _JoinedRideRow({
    required this.ride,
    required this.s,
    required this.busy,
    required this.onWithdraw,
  });

  final GroupRide ride;
  final S s;
  final bool busy;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final owner = ride.ownerName?.trim();
    return ListTile(
      leading: const Icon(AppIcons.usersThree),
      title: Text(_formatRide(ride)),
      subtitle: Text(
        s.pelotonWithOwner(
          owner == null || owner.isEmpty ? s.pelotonUnnamedFriend : owner,
        ),
      ),
      // Een tekstknop en geen kruisje. Een kruisje naast andermans rit leest
      // als "verwijder deze rit", en dat is precies wat hier níét gebeurt --
      // de rit blijft bestaan, jij gaat alleen niet mee.
      trailing: TextButton(
        onPressed: busy ? null : onWithdraw,
        child: Text(s.pelotonWithdraw),
      ),
    );
  }
}

class _OwnedRideRow extends StatelessWidget {
  const _OwnedRideRow({required this.ride, required this.s});

  final GroupRide ride;
  final S s;

  @override
  Widget build(BuildContext context) {
    final joined = ride.accepted.length;
    return ListTile(
      leading: const Icon(AppIcons.usersThree),
      title: Text(_formatRide(ride)),
      subtitle: Text(
        joined == 0 ? s.pelotonNobodyYet : s.pelotonJoinedCount(joined),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.label, required this.onRetry});

  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(AppIcons.cloudSlash),
          const SizedBox(width: 12),
          TextButton(onPressed: onRetry, child: Text(label)),
        ],
      ),
    );
  }
}

/// Bewust hier en niet in een gedeelde helper: de bestaande ritkaarten
/// formatteren via hun eigen `DateFormat`-instanties met de actieve locale, en
/// die uit elkaar trekken hoort bij het moment dat een derde scherm dit ook
/// nodig heeft — niet bij het eerste.
String _formatRide(GroupRide ride) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(ride.start.hour)}:${two(ride.start.minute)} – '
      '${two(ride.end.hour)}:${two(ride.end.minute)}';
}
