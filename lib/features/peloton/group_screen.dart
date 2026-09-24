// lib/features/peloton/group_screen.dart
// Het groepsscherm (schets 015, vraag 2, variant A), hier nog in leesstand.
//
// Kop met kenteken, naam en "N leden · sinds <datum>", daaronder de leden met
// "(jij)" bij jezelf en de chip "beheerder". Van een lid staat er niets anders
// dan naam en rol (CLUB-05). Wie alleen een aanvraag heeft, ziet dat die bij
// de beheerders ligt en kan hem intrekken. De beheerknoppen (⋮ per lid,
// aanvragen, maatje voordragen) komen in plan 05; het appbar-menu en de
// groepslink in plan 06.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:ridewindow/core/safe_back_button.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/group_crest.dart';
import 'package:ridewindow/features/peloton/group_error_text.dart';
import 'package:ridewindow/features/peloton/group_rules_sheet.dart';
import 'package:ridewindow/features/shared/section_card.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/theme/app_icons.dart';

class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  bool _busy = false;

  Future<void> _withdraw(GroupJoinRequest request) async {
    if (_busy) return;
    final s = S.of(context);
    // Messenger en router vóór de await: na de pop is deze context weg.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(pelotonGatewayProvider).deleteGroupRequest(request.id);
      ref.invalidate(visibleGroupsProvider);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/rides');
      }
      messenger.showSnackBar(
        SnackBar(content: Text(s.groupRequestWithdrawn)),
      );
    } catch (error) {
      debugPrint('Peloton: aanvraag intrekken mislukt: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(groupErrorTextOf(s, error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final me = ref.watch(currentUserIdProvider);
    final group = ref.watch(pelotonGroupProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        // Buiten de shell: er is geen onderbalk om op terug te vallen, en de
        // iPhone-webapp heeft geen terugveeg.
        leading: const SafeBackButton(fallbackRoute: '/rides'),
        title: Text(group.value?.name ?? ''),
        actions: const [GroupRulesButton()],
      ),
      body: group.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _CenteredState(
          icon: AppIcons.cloudSlash,
          text: null,
          action: TextButton(
            onPressed: () => ref.invalidate(visibleGroupsProvider),
            child: Text(s.pelotonRetry),
          ),
        ),
        data: (g) {
          if (g == null) {
            return _CenteredState(
              icon: AppIcons.linkBreak,
              text: s.groupNotFound,
              action: FilledButton(
                onPressed: () => context.go('/rides'),
                child: Text(s.pelotonGoToPeloton),
              ),
            );
          }
          if (g.isPendingFor(me)) {
            final request = g.requestFor(me)!;
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _GroupHero(group: g, showCount: false),
                _PendingCard(
                  onWithdraw: _busy ? null : () => _withdraw(request),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(visibleGroupsProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _GroupHero(group: g, showCount: true),
                SectionCard(
                  title: s.groupMembersSection,
                  children: [
                    for (final m in g.members)
                      _MemberRow(
                        key: ValueKey('group-member-${m.userId}'),
                        member: m,
                        isMe: m.userId == me,
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupHero extends StatelessWidget {
  const _GroupHero({required this.group, required this.showCount});

  final PelotonGroup group;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final since = DateFormat.MMMd(s.localeName).format(group.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          GroupCrest(name: group.name, size: 64),
          const SizedBox(height: 12),
          Text(
            group.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          if (showCount) ...[
            const SizedBox(height: 4),
            Text(
              s.groupHeroSubtitle(s.groupMemberCount(group.memberCount), since),
              textAlign: TextAlign.center,
              style: muted,
            ),
            if (group.memberCount == 1) ...[
              const SizedBox(height: 12),
              Text(
                s.groupOnlyYouHint,
                textAlign: TextAlign.center,
                style: muted,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.onWithdraw});

  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                AppIcons.hourglass,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                s.groupRequestPending,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onWithdraw,
                child: Text(s.groupWithdrawRequest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eén lid: avatar met de eerste letter, de naam (met "(jij)" bij jezelf) en
/// de chip "beheerder". Meer niet (CLUB-05). [trailingAction] is de plek voor
/// het ⋮-menu van plan 05; nu altijd leeg.
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    super.key,
    required this.member,
    required this.isMe,
    // ignore: unused_element_parameter
    this.trailingAction,
  });

  final GroupMember member;
  final bool isMe;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final label = member.label(s.pelotonUnnamedFriend);
    final chip = member.isAdmin ? const GroupAdminChip() : null;

    return ListTile(
      leading: CircleAvatar(
        child: Text(label.characters.first.toUpperCase()),
      ),
      title: Text(isMe ? s.groupYou(label) : label),
      trailing: (chip == null && trailingAction == null)
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (chip != null) chip,
                if (trailingAction != null) trailingAction!,
              ],
            ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.text,
    required this.action,
  });

  final IconData icon;
  final String? text;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            if (text != null) ...[
              const SizedBox(height: 16),
              Text(
                text!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ],
            const SizedBox(height: 16),
            action,
          ],
        ),
      ),
    );
  }
}
