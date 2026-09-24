// test/features/group_members_admin_test.dart
//
// Ledenbeheer op het groepsscherm (schets 015, vraag 2, variant A): alleen een
// beheerder ziet ⋮ achter de leden (CLUB-07, CLUB-08). Beheerder maken en
// afnemen, de uitleg voor de laatste beheerder, en eruit halen met een
// snackbar die echt ongedaan maakt: pas na het sluiten gaat er iets naar de
// database.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/group_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/theme/app_icons.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';
const _lastAdmin =
    'Je bent de enige beheerder. Maak eerst iemand anders beheerder, dan kun je dit afgeven.';

/// Jij en Anna beheerder, Ingrid gewoon lid. Met [soleAdmin] ben jij de enige
/// beheerder; met [meMember] ben jij een gewoon lid.
FakeGroupGateway _gateway({bool soleAdmin = false, bool meMember = false}) =>
    FakeGroupGateway(
      me: _me,
      groups: {
        'g1': FakeGroupGateway.group(
          'g1',
          'Dinsdagclub',
          members: [
            FakeGroupGateway.member(
              _me,
              role: meMember ? GroupRole.member : GroupRole.admin,
              name: 'Ik',
            ),
            FakeGroupGateway.member(
              'uid-a',
              role: soleAdmin ? GroupRole.member : GroupRole.admin,
              name: 'Anna',
              joinedDay: 1,
            ),
            FakeGroupGateway.member('uid-i', name: 'Ingrid', joinedDay: 2),
          ],
        ),
      },
    );

Future<void> _open(WidgetTester tester, FakeGroupGateway gateway) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('peloton')),
      ),
      GoRoute(
        path: '/peloton/group/:groupId',
        builder: (_, state) =>
            GroupScreen(groupId: state.pathParameters['groupId'] ?? ''),
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
  router.push('/peloton/group/g1');
  await tester.pumpAndSettle();
}

Finder _row(String uid) => find.byKey(ValueKey('group-member-$uid'));

Finder _menuOf(String uid) => find.descendant(
      of: _row(uid),
      matching: find.byIcon(AppIcons.dotsThreeVertical),
    );

Future<void> _openMenu(WidgetTester tester, String uid) async {
  await tester.tap(_menuOf(uid));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String uid, String item) async {
  await _openMenu(tester, uid);
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void _hideSnackBar(WidgetTester tester) {
  ScaffoldMessenger.of(tester.element(find.byType(GroupScreen)))
      .hideCurrentSnackBar();
}

void main() {
  testWidgets('gewoon lid: geen ⋮ in de ledenlijst', (tester) async {
    await _open(tester, _gateway(meMember: true));
    expect(find.text('Ingrid'), findsOneWidget);
    expect(find.byIcon(AppIcons.dotsThreeVertical), findsNothing);
  });

  testWidgets('beheerder: een ⋮ achter elk lid, ook achter jezelf',
      (tester) async {
    await _open(tester, _gateway());
    expect(_menuOf(_me), findsOneWidget);
    expect(_menuOf('uid-a'), findsOneWidget);
    expect(_menuOf('uid-i'), findsOneWidget);
    expect(
      find.byTooltip('Opties voor dit lid'),
      findsNWidgets(3),
    );
  });

  testWidgets('menu hangt af van rol en van wie het is', (tester) async {
    await _open(tester, _gateway());

    await _openMenu(tester, 'uid-i');
    expect(find.text('Beheerder maken'), findsOneWidget);
    expect(find.text('Uit de groep halen'), findsOneWidget);
    expect(find.text('Beheerder af'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await _openMenu(tester, 'uid-a');
    expect(find.text('Beheerder af'), findsOneWidget);
    expect(find.text('Uit de groep halen'), findsOneWidget);
    expect(find.text('Beheerder maken'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await _openMenu(tester, _me);
    expect(find.text('Beheerder af'), findsOneWidget);
    expect(find.text('Uit de groep halen'), findsNothing);
    expect(find.text('Beheerder maken'), findsNothing);
  });

  testWidgets('beheerder maken: gateway en daarna de chip bij dat lid',
      (tester) async {
    final gateway = _gateway();
    await _open(tester, gateway);
    expect(
      find.descendant(of: _row('uid-i'), matching: find.text('beheerder')),
      findsNothing,
    );

    await _choose(tester, 'uid-i', 'Beheerder maken');

    expect(gateway.calls, contains('setGroupMemberRole:g1:uid-i:admin'));
    expect(
      find.descendant(of: _row('uid-i'), matching: find.text('beheerder')),
      findsOneWidget,
    );
    expect(find.text('Ingrid is nu beheerder'), findsOneWidget);
  });

  testWidgets('beheerder af bij een ander: rol weg en een melding',
      (tester) async {
    final gateway = _gateway();
    await _open(tester, gateway);

    await _choose(tester, 'uid-a', 'Beheerder af');

    expect(gateway.calls, contains('setGroupMemberRole:g1:uid-a:member'));
    expect(
      find.descendant(of: _row('uid-a'), matching: find.text('beheerder')),
      findsNothing,
    );
    expect(find.text('Anna is geen beheerder meer'), findsOneWidget);
  });

  testWidgets('enige beheerder die zichzelf degradeert: uitleg, geen aanroep',
      (tester) async {
    final gateway = _gateway(soleAdmin: true);
    await _open(tester, gateway);
    final before = List.of(gateway.calls);

    await _choose(tester, _me, 'Beheerder af');

    expect(find.text(_lastAdmin), findsOneWidget);
    expect(
      gateway.calls.where((c) => c.startsWith('setGroupMemberRole')),
      isEmpty,
    );
    expect(gateway.calls, before);
  });

  testWidgets('database weigert met last_admin: dezelfde uitleg',
      (tester) async {
    final gateway = _gateway();
    gateway.failWith['setGroupMemberRole'] = GroupError.lastAdmin;
    await _open(tester, gateway);

    await _choose(tester, _me, 'Beheerder af');

    expect(gateway.calls, contains('setGroupMemberRole:g1:uid-me:member'));
    expect(find.text(_lastAdmin), findsOneWidget);
  });

  testWidgets('eruit halen en ongedaan maken: lid blijft, niets verstuurd',
      (tester) async {
    final gateway = _gateway();
    await _open(tester, gateway);
    expect(find.textContaining('3 leden · sinds '), findsOneWidget);

    await _choose(tester, 'uid-i', 'Uit de groep halen');

    expect(_row('uid-i'), findsNothing);
    expect(find.textContaining('2 leden · sinds '), findsOneWidget);
    expect(find.text('Ingrid is uit de groep gehaald'), findsOneWidget);

    await tester.tap(find.text('Ongedaan maken'));
    await tester.pumpAndSettle();

    expect(_row('uid-i'), findsOneWidget);
    expect(find.textContaining('3 leden · sinds '), findsOneWidget);
    expect(
      gateway.calls.where((c) => c.startsWith('removeGroupMember')),
      isEmpty,
    );
  });

  testWidgets('eruit halen en de snackbar sluit: pas dan de verwijdering',
      (tester) async {
    final gateway = _gateway();
    await _open(tester, gateway);

    await _choose(tester, 'uid-i', 'Uit de groep halen');
    expect(
      gateway.calls.where((c) => c.startsWith('removeGroupMember')),
      isEmpty,
    );

    _hideSnackBar(tester);
    await tester.pumpAndSettle();

    expect(gateway.calls, contains('removeGroupMember:g1:uid-i'));
    expect(_row('uid-i'), findsNothing);
    expect(gateway.groups['g1']!.isMember('uid-i'), isFalse);
  });

  testWidgets('eruit halen mislukt: lid komt terug met de foutzin',
      (tester) async {
    final gateway = _gateway();
    gateway.failWith['removeGroupMember'] = GroupError.unknown;
    await _open(tester, gateway);

    await _choose(tester, 'uid-i', 'Uit de groep halen');
    _hideSnackBar(tester);
    await tester.pumpAndSettle();

    expect(gateway.calls, contains('removeGroupMember:g1:uid-i'));
    expect(_row('uid-i'), findsOneWidget);
    expect(
      find.text('Dat is niet gelukt. Probeer het opnieuw.'),
      findsOneWidget,
    );
  });
}
