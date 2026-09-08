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

/// Het tweede tabblad onder "Ritten": wie je maatjes zijn en hoe je er een bij
/// krijgt.
///
/// **Dit was `PelotonTab` en droeg tot 2026-09-08 ook de ritten.** Die stonden
/// er in drie secties -- uitnodigingen, waar je aan meedoet, wat je
/// organiseert -- terwijl je eigen geplande ritten één tab verder stonden. Je
/// moest dus twee tabbladen naast elkaar leggen om te zien wat er deze week
/// gebeurt, en wat je organiseerde stond nergens anders (waargenomen door
/// Joost, schets 008). Alle ritten staan nu in één lijst op het eerste
/// tabblad; hier blijft over wat over relaties gaat en niet over ritten.
class BuddiesTab extends ConsumerStatefulWidget {
  const BuddiesTab({super.key});

  @override
  ConsumerState<BuddiesTab> createState() => _BuddiesTabState();
}

class _BuddiesTabState extends ConsumerState<BuddiesTab> {
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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) return _SignedOutState(s: s, theme: theme);

    final friends = ref.watch(friendsProvider);

    return RefreshIndicator(
      onRefresh: () async => _invalidateAll(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
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
