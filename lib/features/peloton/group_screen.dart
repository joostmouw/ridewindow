// lib/features/peloton/group_screen.dart
// Het groepsscherm (schets 015, vraag 2, variant A).
//
// Kop met kenteken, naam en "N leden · sinds <datum>", daaronder de leden met
// "(jij)" bij jezelf en de chip "beheerder". Van een lid staat er niets anders
// dan naam en rol (CLUB-05). Wie alleen een aanvraag heeft, ziet dat die bij
// de beheerders ligt en kan hem intrekken.
//
// Alleen een beheerder ziet ⋮ achter de leden (beheerder maken of afnemen,
// uit de groep halen) en bovenaan de open aanvragen met Accepteren/Afwijzen
// (CLUB-27). Ieder lid kan een maatje voordragen; bij een beheerder heet dat
// "Maatje toevoegen" en is het meteen lidmaatschap.
//
// Ieder lid deelt de groepslink vanuit de hero (HERZIENING 34-CONTEXT); wie
// hem opent, doet een aanvraag. Het appbar-menu (plan 06) heeft voor een
// beheerder Naam wijzigen, Link vervangen, Groep verlaten en Groep opheffen,
// voor een gewoon lid alleen Groep verlaten.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ridewindow/core/analytics_events.dart';
import 'package:ridewindow/core/safe_back_button.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/group_crest.dart';
import 'package:ridewindow/features/peloton/group_dialogs.dart';
import 'package:ridewindow/features/peloton/group_error_text.dart';
import 'package:ridewindow/features/peloton/group_link.dart';
import 'package:ridewindow/features/peloton/group_name_sheet.dart';
import 'package:ridewindow/features/peloton/group_propose_sheet.dart';
import 'package:ridewindow/features/peloton/group_rules_sheet.dart';
import 'package:ridewindow/features/shared/section_card.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/analytics_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/theme/app_icons.dart';

class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

enum _MemberAction { promote, demote, remove }

enum _GroupAction { rename, replaceLink, leave, disband }

class _GroupScreenState extends ConsumerState<GroupScreen> {
  bool _busy = false;

  /// Leden die een beheerder eruit haalt terwijl de snackbar met "Ongedaan
  /// maken" nog staat. Ze zijn al uit de lijst en het ledental, maar de
  /// database weet nog van niets.
  ///
  /// Waarom uitgesteld: opnieuw toevoegen na een verwijdering kan alleen voor
  /// maatjes van de beheerder, en zet `joined_at` en de rol opnieuw (en
  /// daarmee de opvolgvolgorde). Echt ongedaan maken kan dus alleen door de
  /// verwijdering nog niet te versturen.
  final Set<String> _pendingRemovals = {};

  Future<void> _setRole(
    PelotonGroup group,
    GroupMember member,
    GroupRole role,
  ) async {
    if (_busy) return;
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final me = ref.read(currentUserIdProvider);
    final name = member.label(s.pelotonUnnamedFriend);

    // Voorcontrole voor een duidelijke zin; de database weigert het ook
    // (last_admin), en die fout geeft via groupErrorTextOf dezelfde zin.
    if (role == GroupRole.member &&
        member.userId == me &&
        group.adminCount == 1) {
      messenger.showSnackBar(SnackBar(content: Text(s.groupErrorLastAdmin)));
      return;
    }

    // Container vooraf: na de await kan het scherm al dicht zijn.
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy = true);
    try {
      await ref.read(pelotonGatewayProvider).setGroupMemberRole(
            groupId: group.id,
            userId: member.userId,
            role: role,
          );
      container.invalidate(visibleGroupsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            role == GroupRole.admin
                ? s.groupMadeAdmin(name)
                : s.groupAdminRemoved(name),
          ),
        ),
      );
    } catch (error) {
      debugPrint('Peloton: rol wijzigen mislukt: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(groupErrorTextOf(s, error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Uit de groep halen, uitgesteld tot de snackbar sluit (zie
  /// [_pendingRemovals]). Gateway, container en messenger worden vooraf
  /// gepakt, zodat de verwijdering ook doorgaat als het scherm intussen
  /// gesloten is.
  void _remove(PelotonGroup group, GroupMember member) {
    final s = S.of(context);
    final gateway = ref.read(pelotonGatewayProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final userId = member.userId;
    final name = member.label(s.pelotonUnnamedFriend);

    void release() {
      if (!_pendingRemovals.contains(userId)) return;
      if (mounted) {
        setState(() => _pendingRemovals.remove(userId));
      } else {
        _pendingRemovals.remove(userId);
      }
    }

    setState(() => _pendingRemovals.add(userId));
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(s.groupMemberRemoved(name)),
        action: SnackBarAction(label: s.pelotonUndo, onPressed: () {}),
      ),
    );
    controller.closed.then((reason) async {
      if (reason == SnackBarClosedReason.action) {
        release();
        return;
      }
      try {
        await gateway.removeGroupMember(groupId: group.id, userId: userId);
        container.invalidate(visibleGroupsProvider);
        // Pas vrijgeven als de verse lijst er is, anders knippert het lid
        // nog even terug.
        try {
          await container.read(visibleGroupsProvider.future);
        } catch (_) {
          // De lijst zelf toont zijn eigen fout-staat.
        }
        release();
      } catch (error) {
        debugPrint('Peloton: lid verwijderen mislukt: $error');
        release();
        container.invalidate(visibleGroupsProvider);
        messenger.showSnackBar(
          SnackBar(content: Text(groupErrorTextOf(s, error))),
        );
      }
    });
  }

  /// Aanvragen die nu onderweg zijn (accepteren of afwijzen). Een veld en
  /// geen knopstaat: twee tikken vóór de volgende frame mogen ook niets
  /// dubbel doen.
  final Set<String> _busyRequests = {};

  Future<void> _decide(
    PelotonGroup group,
    GroupJoinRequest request, {
    required bool accept,
  }) async {
    if (_busyRequests.contains(request.id)) return;
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final gateway = ref.read(pelotonGatewayProvider);
    final name = request.label(s.pelotonUnnamedFriend);
    setState(() => _busyRequests.add(request.id));
    try {
      if (accept) {
        await gateway.acceptGroupRequest(request.id);
      } else {
        await gateway.deleteGroupRequest(request.id);
      }
      container.invalidate(visibleGroupsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? s.groupRequestAccepted(name)
                : s.groupRequestRejected(name),
          ),
        ),
      );
    } catch (error) {
      debugPrint('Peloton: aanvraag afhandelen mislukt: $error');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            groupErrorTextOf(
              s,
              error,
              groupName: group.name,
              personName: name,
            ),
          ),
        ),
      );
      // Alleen bij een fout vrijgeven: na succes is de aanvraag weg, en een
      // tweede tik op de oude knop mag niets meer doen.
      if (mounted) setState(() => _busyRequests.remove(request.id));
    }
  }

  Widget _memberMenu(PelotonGroup group, GroupMember member, String? me) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final isMe = member.userId == me;
    return PopupMenuButton<_MemberAction>(
      icon: const Icon(AppIcons.dotsThreeVertical),
      tooltip: s.groupMemberMenuTooltip,
      enabled: !_busy,
      onSelected: (action) => switch (action) {
        _MemberAction.promote => _setRole(group, member, GroupRole.admin),
        _MemberAction.demote => _setRole(group, member, GroupRole.member),
        _MemberAction.remove => _remove(group, member),
      },
      itemBuilder: (_) => [
        if (member.isAdmin)
          PopupMenuItem(
            value: _MemberAction.demote,
            child: Text(s.groupRemoveAdmin),
          )
        else
          PopupMenuItem(
            value: _MemberAction.promote,
            child: Text(s.groupMakeAdmin),
          ),
        if (!isMe)
          PopupMenuItem(
            value: _MemberAction.remove,
            child: Text(
              s.groupRemoveMember,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }

  /// Ieder lid mag de groepslink delen (HERZIENING); wie hem opent, doet een
  /// aanvraag die een beheerder beslist.
  Future<void> _shareLink(PelotonGroup group) async {
    if (_busy) return;
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final gateway = ref.read(pelotonGatewayProvider);
    setState(() => _busy = true);
    try {
      final code = await gateway.groupInviteCode(group.id);
      if (!mounted) return;
      // Alleen het soort gebeurtenis: nooit de code, de naam of het id.
      trackEvent(ref, kEvPelotonInvite, props: {'kind': 'group_link_created'});
      // De code staat ook in de tekst: de link opent de PWA, wie de app al
      // heeft typt hem sneller over.
      await Share.share(
        s.groupShareText(group.name, groupLinkFor(code), code),
      );
    } catch (error) {
      debugPrint('Peloton: groepslink delen mislukt: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(groupErrorTextOf(s, error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Link vervangen (beheerder): alle oude codes vervallen, en de snackbar
  /// biedt meteen Delen voor de nieuwe.
  Future<void> _replaceLink(PelotonGroup group) async {
    if (_busy) return;
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final gateway = ref.read(pelotonGatewayProvider);
    setState(() => _busy = true);
    try {
      final code = await gateway.replaceGroupInvite(group.id);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.groupLinkReplaced),
          action: SnackBarAction(
            label: s.groupShareAction,
            onPressed: () async {
              try {
                await Share.share(
                  s.groupShareText(group.name, groupLinkFor(code), code),
                );
              } catch (error) {
                debugPrint('Peloton: nieuwe groepslink delen mislukt: $error');
                messenger.showSnackBar(
                  SnackBar(content: Text(groupErrorTextOf(s, error))),
                );
              }
            },
          ),
        ),
      );
    } catch (error) {
      debugPrint('Peloton: groepslink vervangen mislukt: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(groupErrorTextOf(s, error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Naam wijzigen (beheerder) met dezelfde sheet als maken. Dezelfde naam
  /// opslaan verstuurt niets.
  Future<void> _rename(PelotonGroup group) async {
    if (_busy) return;
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final gateway = ref.read(pelotonGatewayProvider);
    final name = await showGroupNameSheet(
      context,
      initialName: group.name,
      title: s.groupRename,
      actionLabel: s.groupSave,
    );
    if (name == null || name == group.name || !mounted) return;
    setState(() => _busy = true);
    try {
      await gateway.renameGroup(groupId: group.id, name: name);
      container.invalidate(visibleGroupsProvider);
    } catch (error) {
      debugPrint('Peloton: groep hernoemen mislukt: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(groupErrorTextOf(s, error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Verlaten of opheffen: eerst de bevestiging, dan de gateway, dan terug
  /// met een snackbar. Messenger, router en container worden vóór de eerste
  /// await gepakt: na de pop is deze context weg.
  Future<void> _leaveOrDisband(
    PelotonGroup group,
    String? me, {
    required bool disband,
  }) async {
    if (_busy) return;
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final gateway = ref.read(pelotonGatewayProvider);
    final confirmed = disband
        ? await showDisbandGroupDialog(context, group: group)
        : await showLeaveGroupDialog(context, group: group, me: me);
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      if (disband) {
        await gateway.deleteGroup(group.id);
      } else {
        // last_admin kan hier niet: bij vertrek regelt de database de
        // opvolging (ensure_group_admin, 0012).
        await gateway.leaveGroup(group.id);
      }
      container
        ..invalidate(visibleGroupsProvider)
        ..invalidate(groupRidesProvider);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/rides');
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            disband ? s.groupDisbanded(group.name) : s.groupLeft(group.name),
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        'Peloton: groep ${disband ? 'opheffen' : 'verlaten'} mislukt: $error',
      );
      messenger.showSnackBar(
        SnackBar(content: Text(groupErrorTextOf(s, error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Het ⋮-menu in de appbar. Alleen voor leden; een aanvrager heeft
  /// intrekken al op het scherm.
  Widget _groupMenu(PelotonGroup group, String? me) {
    final s = S.of(context);
    final isAdmin = group.isAdmin(me);
    return PopupMenuButton<_GroupAction>(
      icon: const Icon(AppIcons.dotsThreeVertical),
      tooltip: s.groupMenuTooltip,
      enabled: !_busy,
      onSelected: (action) => switch (action) {
        _GroupAction.rename => _rename(group),
        _GroupAction.replaceLink => _replaceLink(group),
        _GroupAction.leave => _leaveOrDisband(group, me, disband: false),
        _GroupAction.disband => _leaveOrDisband(group, me, disband: true),
      },
      // Beheerder: naam, link, verlaten, opheffen. Gewoon lid: alleen
      // verlaten. De database weigert de rest ook (RLS, 0012).
      itemBuilder: (_) => [
        if (isAdmin) ...[
          _menuItem(
            _GroupAction.rename,
            AppIcons.pencilSimple,
            s.groupRename,
          ),
          _menuItem(
            _GroupAction.replaceLink,
            AppIcons.arrowsCounterClockwise,
            s.groupReplaceLink,
          ),
        ],
        _menuItem(_GroupAction.leave, AppIcons.signOut, s.groupLeave),
        if (isAdmin)
          _menuItem(
            _GroupAction.disband,
            AppIcons.trash,
            s.groupDisband,
            color: Theme.of(context).colorScheme.error,
          ),
      ],
    );
  }

  PopupMenuItem<_GroupAction> _menuItem(
    _GroupAction value,
    IconData icon,
    String label, {
    Color? color,
  }) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: color == null ? null : TextStyle(color: color),
              ),
            ),
          ],
        ),
      );

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
    final loaded = group.value;
    final showMenu = loaded != null && loaded.isMember(me);

    return Scaffold(
      appBar: AppBar(
        // Buiten de shell: er is geen onderbalk om op terug te vallen, en de
        // iPhone-webapp heeft geen terugveeg.
        leading: const SafeBackButton(fallbackRoute: '/rides'),
        title: Text(group.value?.name ?? ''),
        actions: [
          const GroupRulesButton(),
          if (showMenu) _groupMenu(loaded, me),
        ],
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
          final isAdmin = g.isAdmin(me);
          // Wie net is weggehaald (snackbar staat nog) is al uit beeld.
          final shown = _pendingRemovals.isEmpty
              ? g
              : PelotonGroup(
                  id: g.id,
                  name: g.name,
                  createdAt: g.createdAt,
                  members: [
                    for (final m in g.members)
                      if (!_pendingRemovals.contains(m.userId)) m,
                  ],
                  requests: g.requests,
                );
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(visibleGroupsProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _GroupHero(
                  group: shown,
                  showCount: true,
                  onShare: _busy ? null : () => _shareLink(g),
                ),
                if (isAdmin && g.openRequests(me).isNotEmpty)
                  SectionCard(
                    title: s.groupRequestsSection,
                    children: [
                      for (final r in g.openRequests(me))
                        _RequestRow(
                          key: ValueKey('group-request-${r.id}'),
                          request: r,
                          busy: _busyRequests.contains(r.id),
                          onAccept: () => _decide(g, r, accept: true),
                          onReject: () => _decide(g, r, accept: false),
                        ),
                    ],
                  ),
                SectionCard(
                  title: s.groupMembersSection,
                  action: TextButton.icon(
                    onPressed: () =>
                        showGroupProposeSheet(context, groupId: g.id),
                    icon: const Icon(AppIcons.userPlus, size: 18),
                    label: Text(
                      isAdmin ? s.groupAddFriend : s.groupProposeFriend,
                    ),
                  ),
                  children: [
                    for (final m in shown.members)
                      _MemberRow(
                        key: ValueKey('group-member-${m.userId}'),
                        member: m,
                        isMe: m.userId == me,
                        trailingAction: isAdmin ? _memberMenu(g, m, me) : null,
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
  const _GroupHero({
    required this.group,
    required this.showCount,
    this.onShare,
  });

  final PelotonGroup group;
  final bool showCount;

  /// Deel de groepslink; alleen voor leden, niet in de aanvraagstaat.
  final VoidCallback? onShare;

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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onShare,
                icon: const Icon(AppIcons.shareNetwork),
                label: Text(s.groupShareLink),
              ),
            ),
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
/// de chip "beheerder". Meer niet (CLUB-05). [trailingAction] is het ⋮-menu,
/// alleen voor beheerders.
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    super.key,
    required this.member,
    required this.isMe,
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

/// Eén open aanvraag: naam, herkomst ("via de groepslink" of "voorgedragen
/// door X") en Accepteren/Afwijzen. Alleen voor beheerders.
class _RequestRow extends StatelessWidget {
  const _RequestRow({
    super.key,
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final GroupJoinRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final label = request.label(s.pelotonUnnamedFriend);
    final origin = request.isViaLink
        ? s.groupRequestViaLink
        : s.groupRequestProposedBy(
            request.proposedByName ?? s.pelotonUnnamedFriend,
          );

    // Naam boven, knoppen eronder: naast elkaar past het niet op een smal
    // toestel (360 dp) met twee knoppen en een lange naam.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Text(label.characters.first.toUpperCase()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyLarge),
                    Text(
                      origin,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Wrap: bij grote tekst of een smal scherm gaan de knoppen onder
          // elkaar in plaats van over de rand.
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: busy ? null : onReject,
                child: Text(s.groupReject),
              ),
              FilledButton.tonal(
                onPressed: busy ? null : onAccept,
                child: Text(s.groupAccept),
              ),
            ],
          ),
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
