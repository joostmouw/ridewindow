// test/features/group_landing_test.dart
//
// De landing van een groepslink, /group/:code (CLUB-02 herzien, plan 34-07):
// uitgelogd de code bewaren en naar inloggen wijzen, ingelogd meteen een
// aanvraag, al lid meteen het groepsscherm, en een gewone zin bij elke fout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/group_landing_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/services/pending_invite_store.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';
const _code = 'ABCDEFGH';

FakeGroupGateway _gateway() {
  final gateway = FakeGroupGateway(
    me: _me,
    groups: {
      'g1': FakeGroupGateway.group(
        'g1',
        'Dinsdagclub',
        members: [FakeGroupGateway.member('uid-admin', role: GroupRole.admin)],
      ),
    },
  );
  gateway.inviteCodes[_code] = 'g1';
  return gateway;
}

GoRouter _router() => GoRouter(
      initialLocation: '/group/$_code',
      routes: [
        GoRoute(
          path: '/group/:code',
          builder: (_, state) =>
              GroupLandingScreen(code: state.pathParameters['code'] ?? ''),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('profiel')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/peloton/group/:groupId',
          builder: (_, state) =>
              Scaffold(body: Text('groep-${state.pathParameters['groupId']}')),
        ),
      ],
    );

Widget _app(GoRouter router, FakeGroupGateway gateway, String? userId) =>
    ProviderScope(
      overrides: [
        pelotonGatewayProvider.overrideWithValue(gateway),
        currentUserIdProvider.overrideWithValue(userId),
      ],
      child: MaterialApp.router(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: ThemeData(extensions: const [RideWindowTheme.light]),
        routerConfig: router,
      ),
    );

Future<GoRouter> _pump(
  WidgetTester tester,
  FakeGroupGateway gateway, {
  String? userId = _me,
}) async {
  SharedPreferences.setMockInitialValues({});
  final router = _router();
  addTearDown(router.dispose);
  await tester.pumpWidget(_app(router, gateway, userId));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('uitgelogd: uitnodiging, Log in en doe mee, Niet nu, code bewaard',
      (tester) async {
    final gateway = _gateway();
    await _pump(tester, gateway, userId: null);

    expect(find.text('Uitnodiging voor een groep'), findsOneWidget);
    expect(find.text('Je bent uitgenodigd voor een groep'), findsOneWidget);
    expect(
      find.text('Log in, dan gaat je aanvraag naar de beheerders van de groep.'),
      findsOneWidget,
    );
    expect(find.text('Log in en doe mee'), findsOneWidget);
    expect(find.text('Niet nu'), findsOneWidget);
    expect(gateway.calls, isEmpty);
    expect(await PendingInviteStore.readGroup(), _code);
  });

  testWidgets('uitgelogd: Log in en doe mee gaat naar Profiel', (tester) async {
    await _pump(tester, _gateway(), userId: null);
    await tester.tap(find.text('Log in en doe mee'));
    await tester.pumpAndSettle();
    expect(find.text('profiel'), findsOneWidget);
  });

  testWidgets('uitgelogd: Niet nu gaat naar Home', (tester) async {
    await _pump(tester, _gateway(), userId: null);
    await tester.tap(find.text('Niet nu'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('ingelogd: aanvraag ingediend, met knop naar de groep',
      (tester) async {
    final gateway = _gateway();
    await _pump(tester, gateway);

    expect(gateway.calls, contains('redeemGroupInvite:$_code'));
    expect(
      find.text('Je aanvraag voor Dinsdagclub ligt bij de beheerders'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Zodra een beheerder je accepteert, staat de groep op je Peloton-tab.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Naar de groep'));
    await tester.pumpAndSettle();
    expect(find.text('groep-g1'), findsOneWidget);
  });

  testWidgets('ingelogd en al lid: meteen het groepsscherm', (tester) async {
    final gateway = _gateway()..redeemStatus = GroupJoinStatus.member;
    await _pump(tester, gateway);

    expect(find.text('groep-g1'), findsOneWidget);
  });

  testWidgets('verlopen link: gewone zin en Opnieuw proberen', (tester) async {
    final gateway = _gateway()..inviteCodes.clear();
    await _pump(tester, gateway);

    expect(
      find.text(
        'Deze groepslink werkt niet meer. Vraag iemand uit de groep om een '
        'nieuwe.',
      ),
      findsOneWidget,
    );
    expect(find.text('Opnieuw proberen'), findsOneWidget);

    await tester.tap(find.text('Opnieuw proberen'));
    await tester.pumpAndSettle();
    expect(
      gateway.calls.where((c) => c.startsWith('redeemGroupInvite')).length,
      2,
    );
  });

  testWidgets('volle groep en 10 groepen geven hun eigen zin', (tester) async {
    final full = _gateway()..failWith['redeemGroupInvite'] = GroupError.groupFull;
    await _pump(tester, full);
    expect(
      find.text(
        'Deze groep heeft al 30 leden, het maximum. Een beheerder kan eerst '
        'iemand uit de groep halen.',
      ),
      findsOneWidget,
    );

    final many = _gateway()
      ..failWith['redeemGroupInvite'] = GroupError.tooManyGroups;
    await _pump(tester, many);
    expect(
      find.text(
        'Je zit al in 10 groepen, het maximum. Verlaat eerst een andere groep.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('inloggen terwijl het scherm openstaat: inwisselen start vanzelf',
      (tester) async {
    final gateway = _gateway();
    final router = await _pump(tester, gateway, userId: null);
    expect(await PendingInviteStore.readGroup(), _code);

    await tester.pumpWidget(_app(router, gateway, _me));
    await tester.pumpAndSettle();

    expect(gateway.calls, ['redeemGroupInvite:$_code']);
    expect(
      find.text('Je aanvraag voor Dinsdagclub ligt bij de beheerders'),
      findsOneWidget,
    );
    expect(await PendingInviteStore.readGroup(), isNull);
  });
}
