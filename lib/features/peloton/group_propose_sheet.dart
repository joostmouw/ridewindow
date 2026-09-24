// lib/features/peloton/group_propose_sheet.dart
// "Maatje voordragen" / "Maatje toevoegen" (schets 015, CLUB-03 herzien).
//
// Ieder lid draagt een maatje voor: dat wordt een aanvraag voor de
// beheerders. Een beheerder die hetzelfde doet, maakt het maatje meteen lid.
// Wie al lid is of al een aanvraag heeft, staat erbij maar is niet aan te
// tikken. De sheet kijkt live naar de groep, zodat een voordracht meteen
// zichtbaar wordt; de uitkomst staat als regel in de sheet zelf, niet als
// snackbar achter de sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/group_error_text.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';

Future<void> showGroupProposeSheet(
  BuildContext context, {
  required String groupId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _GroupProposeSheet(groupId: groupId),
  );
}

class _GroupProposeSheet extends ConsumerStatefulWidget {
  const _GroupProposeSheet({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_GroupProposeSheet> createState() => _GroupProposeSheetState();
}

class _GroupProposeSheetState extends ConsumerState<_GroupProposeSheet> {
  /// Wie er nu onderweg is; dubbel tikken doet niets dubbel.
  final Set<String> _busy = {};

  /// De laatste uitkomst, als regel bovenaan de sheet.
  String? _message;
  bool _messageIsError = false;

  Future<void> _propose(PelotonGroup group, Friend friend) async {
    if (_busy.contains(friend.userId)) return;
    final s = S.of(context);
    final name = friend.label(s.pelotonUnnamedFriend);
    // Container vooraf: de sheet kan intussen dicht zijn.
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy.add(friend.userId));
    try {
      final status = await ref.read(pelotonGatewayProvider).proposeGroupMember(
            groupId: group.id,
            userId: friend.userId,
          );
      container.invalidate(visibleGroupsProvider);
      if (!mounted) return;
      setState(() {
        _messageIsError = false;
        _message = status == GroupJoinStatus.member
            ? s.groupFriendAddedMember(name)
            : s.groupFriendProposed(name);
      });
    } catch (error) {
      debugPrint('Peloton: maatje voordragen mislukt: $error');
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = groupErrorTextOf(
          s,
          error,
          groupName: group.name,
          personName: name,
        );
      });
    } finally {
      if (mounted) setState(() => _busy.remove(friend.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(currentUserIdProvider);
    final group = ref.watch(pelotonGroupProvider(widget.groupId)).value;
    final friendsAsync = ref.watch(friendsProvider);

    final isAdmin = group?.isAdmin(me) ?? false;
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final Widget body;
    if (group == null || (!friendsAsync.hasValue && !friendsAsync.hasError)) {
      body = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (friendsAsync.hasError) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Row(
          children: [
            Expanded(child: Text(s.groupErrorGeneric, style: muted)),
            TextButton(
              onPressed: () => ref.invalidate(friendsProvider),
              child: Text(s.pelotonRetry),
            ),
          ],
        ),
      );
    } else if (friendsAsync.value!.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Text(s.groupNoFriendsToPropose, style: muted),
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final f in friendsAsync.value!)
            _FriendRow(
              key: ValueKey('group-propose-${f.userId}'),
              label: f.label(s.pelotonUnnamedFriend),
              trailing: _trailingFor(s, theme, group, f, isAdmin),
            ),
        ],
      );
    }

    final banner = group != null && group.isFull
        ? s.groupErrorFullNamed(group.name)
        : _message;
    final bannerIsError = (group != null && group.isFull) || _messageIsError;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
            child: Text(
              isAdmin ? s.groupAddFriend : s.groupProposeFriend,
              style: theme.textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              isAdmin ? s.groupAddFriendHint : s.groupProposeFriendHint,
              style: muted,
            ),
          ),
          if (banner != null) _Banner(text: banner, isError: bannerIsError),
          body,
        ],
      ),
    );
  }

  Widget _trailingFor(
    S s,
    ThemeData theme,
    PelotonGroup group,
    Friend friend,
    bool isAdmin,
  ) {
    final mutedSmall = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    if (group.isMember(friend.userId)) {
      return Text(s.groupAlreadyMember, style: mutedSmall);
    }
    if (group.requestFor(friend.userId) != null) {
      return Text(s.groupRequestPendingShort, style: mutedSmall);
    }
    // Vol: geen knoppen, de banner zegt waarom.
    if (group.isFull) return const SizedBox.shrink();
    final busy = _busy.contains(friend.userId);
    return FilledButton.tonal(
      onPressed: busy ? null : () => _propose(group, friend),
      child: Text(isAdmin ? s.groupAddAction : s.groupProposeAction),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({super.key, required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: CircleAvatar(
        child: Text(label.characters.first.toUpperCase()),
      ),
      title: Text(label),
      trailing: trailing,
    );
  }
}

/// Regel bovenaan de sheet: een grens of fout in errorContainer, een gelukte
/// voordracht in secondaryContainer. Beide paren kloppen in licht en donker.
class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isError ? scheme.errorContainer : scheme.secondaryContainer;
    final fg = isError ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg),
        ),
      ),
    );
  }
}
