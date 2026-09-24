// test/features/peloton_code_field_test.dart
//
// Het codeveld op de Peloton-tab kent sinds plan 34-07 ook groepscodes: de
// gedeelde groepstekst zegt "vul code in onder Ritten, tab Peloton", en op
// Android opent de link de PWA en niet de app. Een maatjescode gaat voor en
// raakt de groepen niet aan; een onbekende code geeft dezelfde zin als altijd.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/buddies_tab.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';

/// Kent één maatjescode; elke andere maatjescode faalt zoals de rpc dat doet.
class _Gateway extends FakeGroupGateway {
  _Gateway() : super(me: _me);

  @override
  Future<Friend> redeemFriendInvite(String code) async {
    calls.add('redeemFriendInvite:$code');
    if (code == 'FRIEND12') {
      return const Friend(userId: 'uid-a', displayName: 'Anna');
    }
    throw Exception('invite not found');
  }
}

_Gateway _gateway() {
  final gateway = _Gateway();
  gateway.groups['g1'] = FakeGroupGateway.group(
    'g1',
    'Dinsdagclub',
    members: [FakeGroupGateway.member('uid-admin', role: GroupRole.admin)],
  );
  gateway.inviteCodes['GROUP123'] = 'g1';
  return gateway;
}

Future<void> _pumpAndRedeem(
  WidgetTester tester,
  _Gateway gateway,
  String code,
) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: BuddiesTab()),
      ),
      GoRoute(
        path: '/peloton/group/:groupId',
        builder: (_, state) =>
            Scaffold(body: Text('groep-${state.pathParameters['groupId']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pelotonGatewayProvider.overrideWithValue(gateway),
        currentUserIdProvider.overrideWithValue(_me),
      ],
      child: MaterialApp.router(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: ThemeData(extensions: const [RideWindowTheme.light]),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();

  final field = find.byType(TextField);
  await tester.ensureVisible(field);
  await tester.enterText(field, code);
  await tester.tap(find.text('Meedoen'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('groepscode: aanvraag bij de beheerders', (tester) async {
    final gateway = _gateway();
    await _pumpAndRedeem(tester, gateway, 'GROUP123');

    expect(gateway.calls, containsAllInOrder([
      'redeemFriendInvite:GROUP123',
      'redeemGroupInvite:GROUP123',
    ]));
    expect(
      find.text('Je aanvraag voor Dinsdagclub ligt bij de beheerders'),
      findsOneWidget,
    );
  });

  testWidgets('groepscode en al lid: het groepsscherm opent', (tester) async {
    final gateway = _gateway()..redeemStatus = GroupJoinStatus.member;
    await _pumpAndRedeem(tester, gateway, 'GROUP123');

    expect(find.text('groep-g1'), findsOneWidget);
  });

  testWidgets('geen van beide: dezelfde zin als altijd', (tester) async {
    final gateway = _gateway();
    await _pumpAndRedeem(tester, gateway, 'NOPE2345');

    expect(find.text('Die code werkt niet. Hij kan verlopen zijn.'),
        findsOneWidget);
    // Niet de groepszin: die zou verklappen welke soort code bestaat.
    expect(
      find.textContaining('groepslink werkt niet meer'),
      findsNothing,
    );
  });

  testWidgets('maatjescode: als voorheen, groepen blijven ongemoeid',
      (tester) async {
    final gateway = _gateway();
    await _pumpAndRedeem(tester, gateway, 'FRIEND12');

    expect(find.text('Anna is nu je maatje'), findsOneWidget);
    expect(
      gateway.calls.where((c) => c.startsWith('redeemGroupInvite')),
      isEmpty,
    );
  });

  testWidgets('volle groep: eigen zin, want de code was geldig',
      (tester) async {
    final gateway = _gateway()
      ..failWith['redeemGroupInvite'] = GroupError.groupFull;
    await _pumpAndRedeem(tester, gateway, 'GROUP123');

    expect(find.textContaining('30 leden'), findsOneWidget);
  });
}
