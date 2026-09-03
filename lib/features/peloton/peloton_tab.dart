import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/services/invite_code.dart';
import 'package:ridewindow/features/peloton/invite_landing_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) return _SignedOutState(s: s, theme: theme);

    final friends = ref.watch(friendsProvider);
    final invites = ref.watch(pendingRideInvitesProvider);
    final owned = ref.watch(ownedGroupRidesProvider);

    return RefreshIndicator(
      onRefresh: () async => _invalidateAll(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (invites.value?.isNotEmpty ?? false) ...[
            _SectionHeader(s.pelotonPendingInvites),
            for (final ride in invites.value!)
              _InviteCard(
                ride: ride,
                busy: _busy,
                onAccept: () => _respond(ride, accepted: true),
                onDecline: () => _respond(ride, accepted: false),
              ),
          ],
          _SectionHeader(s.pelotonFriends),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FilledButton.tonalIcon(
              onPressed: _busy ? null : _shareInvite,
              icon: const Icon(Icons.person_add_alt),
              label: Text(s.pelotonInviteFriend),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          if (owned.value?.isNotEmpty ?? false) ...[
            _SectionHeader(s.pelotonOwnedRides),
            for (final ride in owned.value!)
              _OwnedRideRow(ride: ride, s: s),
          ],
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
              Icons.groups_outlined,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

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
        icon: const Icon(Icons.person_remove_outlined),
        tooltip: S.of(context).pelotonRemoveFriend,
        onPressed: onRemove,
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
      leading: const Icon(Icons.groups),
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
          const Icon(Icons.cloud_off_outlined),
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
