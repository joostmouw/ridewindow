// lib/features/peloton/groups_section.dart
// De sectie Groepen bovenaan de Peloton-tab (schets 015, vraag 1, variant A).
//
// Per groep een kaart met kenteken, naam, ledental en de chip "beheerder" als
// jij beheerder bent; daaronder de groepen waar jouw aanvraag loopt. Zonder
// groepen één uitnodigende kaart in plaats van een lege kop. De kop draagt de
// info-knop met de regels (CLUB-28) en, zodra er groepen zijn, "+ Nieuwe
// groep". Uitgelogd staat deze sectie er niet: [BuddiesTab] toont dan zijn
// eigen uitgelogde staat.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ridewindow/core/analytics_events.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/group_crest.dart';
import 'package:ridewindow/features/peloton/group_error_text.dart';
import 'package:ridewindow/features/peloton/group_name_sheet.dart';
import 'package:ridewindow/features/peloton/group_rules_sheet.dart';
import 'package:ridewindow/features/shared/section_card.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/analytics_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/theme/app_icons.dart';

class GroupsSection extends ConsumerStatefulWidget {
  const GroupsSection({super.key});

  @override
  ConsumerState<GroupsSection> createState() => _GroupsSectionState();
}

class _GroupsSectionState extends ConsumerState<GroupsSection> {
  bool _busy = false;

  Future<void> _create(List<PelotonGroup> mine) async {
    if (_busy) return;
    final s = S.of(context);
    // Messenger en router vóór de eerste await: na de sheet kan deze widget
    // al opnieuw gebouwd zijn (patroon uit buddies_tab).
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    // De grens eerst hier, zodat je geen naam verzint voor een groep die de
    // database toch weigert. De database toetst zelf ook (too_many_groups).
    if (mine.length >= kMaxGroupsPerAccount) {
      messenger.showSnackBar(
        SnackBar(content: Text(s.groupErrorTooManyGroupsSelf)),
      );
      return;
    }

    final name = await showGroupNameSheet(
      context,
      title: s.groupCreateTitle,
      hint: s.groupCreateHint,
      actionLabel: s.groupsCreateAction,
    );
    if (name == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final id = await ref.read(pelotonGatewayProvider).createGroup(name);
      ref.invalidate(visibleGroupsProvider);
      // Alleen het soort gebeurtenis: nooit de naam of het id van de groep.
      trackEvent(ref, kEvPelotonInvite, props: {'kind': 'group_created'});
      router.push('/peloton/group/$id');
    } catch (error) {
      debugPrint('Peloton: groep maken mislukt: $error');
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
    final mine = ref.watch(myGroupsProvider);
    final pending = ref.watch(myPendingGroupsProvider);

    final myList = mine.value ?? const <PelotonGroup>[];
    final pendingList = pending.value ?? const <PelotonGroup>[];
    final hasAny = myList.isNotEmpty || pendingList.isNotEmpty;

    final Widget body;
    if (mine.hasError || pending.hasError) {
      body = _GroupsErrorRow(
        label: s.pelotonRetry,
        onRetry: () => ref.invalidate(visibleGroupsProvider),
      );
    } else if (!mine.hasValue || !pending.hasValue) {
      body = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (!hasAny) {
      body = _EmptyGroups(
        onCreate: _busy ? null : () => _create(myList),
      );
    } else {
      body = Column(
        children: [
          for (final g in myList)
            _GroupTile(
              group: g,
              subtitle: s.groupMemberCount(g.memberCount),
              trailing: g.isAdmin(me) ? const GroupAdminChip() : null,
            ),
          for (final g in pendingList)
            _GroupTile(group: g, subtitle: s.groupRequestPendingShort),
        ],
      );
    }

    return SectionCard(
      title: s.groupsSection,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GroupRulesButton(),
          if (hasAny)
            TextButton.icon(
              onPressed: _busy ? null : () => _create(myList),
              icon: const Icon(AppIcons.plus, size: 18),
              label: Text(s.groupsNew),
            ),
        ],
      ),
      children: [body],
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.subtitle,
    this.trailing,
  });

  final PelotonGroup group;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: GroupCrest(name: group.name),
      title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: () => context.push('/peloton/group/${group.id}'),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups({required this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          Icon(
            AppIcons.usersThree,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            s.groupsEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            s.groupsEmptyHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onCreate,
            child: Text(s.groupsCreateAction),
          ),
        ],
      ),
    );
  }
}

class _GroupsErrorRow extends StatelessWidget {
  const _GroupsErrorRow({required this.label, required this.onRetry});

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
