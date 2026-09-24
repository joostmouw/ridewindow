import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ridewindow/core/analytics_events.dart';
import 'package:ridewindow/core/safe_back_button.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/group_error_text.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/analytics_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/services/pending_invite_store.dart';
import 'package:ridewindow/theme/app_icons.dart';

typedef _GroupJoin = ({
  String groupId,
  String? groupName,
  GroupJoinStatus status
});

/// Waar een gedeelde groepslink op uitkomt: `/group/:code` (CLUB-02 herzien).
///
/// Gebouwd naar het model van `InviteLandingScreen`: wie op de link tikt heeft
/// zijn keuze al gemaakt, dus ingelogd wordt er meteen ingewisseld. Sinds de
/// herziening van 2026-09-23 maakt de link geen lid maar een **aanvraag**;
/// ben je al lid, dan ga je meteen naar het groepsscherm.
///
/// **Afwijking van schets 015.** De schets toonde uitgelogd "Joost nodigt je
/// uit voor Dinsdagclub, 9 fietsers". Dat kan niet: uitgelogd heeft de app op
/// geen enkele groepstabel rechten (0012/0013) en de rpc eist `auth.uid()`.
/// Daarvoor zou een nieuwe serverfunctie nodig zijn, en de gedeelde tekst
/// noemt de groepsnaam al. Dit scherm zegt daarom alleen dat het om een groep
/// gaat en wat inloggen doet.
class GroupLandingScreen extends ConsumerStatefulWidget {
  const GroupLandingScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<GroupLandingScreen> createState() => _GroupLandingScreenState();
}

class _GroupLandingScreenState extends ConsumerState<GroupLandingScreen> {
  Future<_GroupJoin>? _redeem;

  @override
  void initState() {
    super.initState();
    if (ref.read(currentUserIdProvider) != null) {
      _start();
    } else {
      // Uitgelogd kan er niets ingewisseld worden. De code wordt bewaard zodat
      // hij het inloggen overleeft; account_section wisselt hem daarna in.
      PendingInviteStore.saveGroup(widget.code);
    }
  }

  void _start() {
    final redeem = _redeemOnce();
    // Bij "Opnieuw proberen" kan de fout vallen vóór de FutureBuilder in het
    // volgende frame luistert; zonder eigen luisteraar telt hij dan als
    // onafgehandeld. De FutureBuilder krijgt de fout gewoon nog. (Niet
    // `ignore()`: dat laat ook latere luisteraars niets meer zien.)
    redeem.then<void>((_) {}, onError: (Object _) {});
    setState(() {
      _redeem = redeem;
    });
  }

  Future<_GroupJoin> _redeemOnce() {
    return ref
        .read(pelotonGatewayProvider)
        .redeemGroupInvite(widget.code)
        .then((result) {
      ref.invalidate(visibleGroupsProvider);
      // Alleen `kind`, nooit de code: dat is een sleutel, geen statistiek.
      trackEvent(
        ref,
        kEvPelotonInvite,
        props: {'kind': 'group_redeemed_link'},
      );
      if (result.status == GroupJoinStatus.member && mounted) {
        // Schets: "daarna sta je op het groepsscherm". De SafeBackButton
        // daar valt terug op Home, want er is niets om naar terug te gaan.
        context.go('/peloton/group/${result.groupId}');
      }
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final signedIn = ref.watch(currentUserIdProvider) != null;

    // Logt iemand in terwijl dit scherm openstaat, dan meteen inwisselen. De
    // bewaarde code gaat eerst weg, anders wisselt account_section hem na het
    // inloggen nog een keer in.
    ref.listen(currentUserIdProvider, (previous, next) {
      if (previous == null && next != null && _redeem == null) {
        PendingInviteStore.clearGroup();
        _start();
      }
    });

    return Scaffold(
      // Van buiten de app binnengekomen: er is meestal niets om naar terug te
      // poppen. SafeBackButton valt dan terug op Home (zie InviteLandingScreen).
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: Text(s.groupJoinTitle),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: !signedIn
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Message(
                      icon: AppIcons.usersThree,
                      title: s.groupJoinSignedOutTitle,
                      detail: s.groupJoinSignedOutBody,
                      theme: theme,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go('/profile'),
                      child: Text(s.groupJoinSignIn),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Text(s.groupNotNow),
                    ),
                  ],
                )
              : FutureBuilder<_GroupJoin>(
                  future: _redeem,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _Message(
                        icon: AppIcons.hourglass,
                        title: s.groupJoining,
                        theme: theme,
                      );
                    }
                    if (snapshot.hasError) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Message(
                            icon: AppIcons.linkBreak,
                            title: groupErrorTextOf(s, snapshot.error!),
                            theme: theme,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _start,
                            child: Text(s.pelotonRetry),
                          ),
                        ],
                      );
                    }
                    final result = snapshot.data;
                    if (result == null ||
                        result.status == GroupJoinStatus.member) {
                      // Lid: de navigatie naar het groepsscherm loopt al.
                      return _Message(
                        icon: AppIcons.hourglass,
                        title: s.groupJoining,
                        theme: theme,
                      );
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Message(
                          icon: AppIcons.hourglass,
                          title: s.groupJoinRequested(
                            result.groupName ?? s.groupUnnamed,
                          ),
                          detail: s.groupJoinRequestedHint,
                          theme: theme,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () =>
                              context.go('/peloton/group/${result.groupId}'),
                          child: Text(s.groupOpenGroup),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.theme,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (detail != null) ...[
          const SizedBox(height: 8),
          Text(
            detail!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
