// test/features/group_requests_test.dart
//
// Aanvragen en voordragen (CLUB-03 herzien, CLUB-27): een beheerder ziet
// bovenaan het groepsscherm de open aanvragen en accepteert of wijst af; ieder
// lid draagt een maatje voor, een beheerder voegt direct toe; op de
// Peloton-tab ziet een beheerder al hoeveel aanvragen er openstaan.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/buddies_tab.dart';
import 'package:ridewindow/features/peloton/group_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';

const _friends = [
  Friend(userId: 'uid-i', displayName: 'Ingrid'),
  Friend(userId: 'uid-j', displayName: 'Jacco'),
  Friend(userId: 'uid-m', displayName: 'Mark'),
];

/// Dinsdagclub: jij (beheerder, of met [meMember] gewoon lid), Anna
/// beheerder, Ingrid lid. Open aanvragen: Piet via de link, Mark voorgedragen
/// door Anna. Als gewoon lid heb jij daarnaast Quinten voorgedragen.
FakeGroupGateway _gateway({
  bool meMember = false,
  List<Friend> friends = _friends,
  int extraMembers = 0,
}) =>
    FakeGroupGateway(
      me: _me,
      friends: friends,
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
              role: GroupRole.admin,
              name: 'Anna',
              joinedDay: 1,
            ),
            FakeGroupGateway.member('uid-i', name: 'Ingrid', joinedDay: 2),
            for (var i = 0; i < extraMembers; i++)
              FakeGroupGateway.member('uid-x$i', name: 'X$i', joinedDay: 3),
          ],
          requests: [
            FakeGroupGateway.request('r1', 'uid-p', name: 'Piet'),
            FakeGroupGateway.request(
              'r2',
              'uid-m',
              name: 'Mark',
              proposedBy: 'uid-a',
              proposedByName: 'Anna',
              createdDay: 1,
            ),
            if (meMember)
              FakeGroupGateway.request(
                'r3',
                'uid-q',
                name: 'Quinten',
                proposedBy: _me,
                proposedByName: 'Ik',
                createdDay: 2,
              ),
          ],
        ),
      },
    );

Widget _app(FakeGroupGateway gateway, GoRouter router) => ProviderScope(
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
    );

Future<void> _open(WidgetTester tester, FakeGroupGateway gateway) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
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
  await tester.pumpWidget(_app(gateway, router));
  await tester.pumpAndSettle();
  router.push('/peloton/group/g1');
  await tester.pumpAndSettle();
}

Finder _request(String id) => find.byKey(ValueKey('group-request-$id'));
Finder _member(String uid) => find.byKey(ValueKey('group-member-$uid'));
Finder _friendRow(String uid) => find.byKey(ValueKey('group-propose-$uid'));

Future<void> _openSheet(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('beheerder: Aanvragen boven Leden, met herkomst per aanvraag',
      (tester) async {
    await _open(tester, _gateway());

    expect(find.text('AANVRAGEN'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('AANVRAGEN')).dy,
      lessThan(tester.getTopLeft(find.text('LEDEN')).dy),
    );
    expect(
      find.descendant(of: _request('r1'), matching: find.text('Piet')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _request('r1'),
        matching: find.text('via de groepslink'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _request('r2'),
        matching: find.text('voorgedragen door Anna'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('gewoon lid, ook met een eigen voordracht: geen Aanvragen',
      (tester) async {
    await _open(tester, _gateway(meMember: true));

    expect(find.text('LEDEN'), findsOneWidget);
    expect(find.text('AANVRAGEN'), findsNothing);
    expect(find.text('Accepteren'), findsNothing);
    expect(find.text('Quinten'), findsNothing);
  });

  testWidgets('accepteren: lid erbij, aanvraag weg, snackbar', (tester) async {
    final gateway = _gateway();
    await _open(tester, gateway);

    await tester.tap(
      find.descendant(of: _request('r1'), matching: find.text('Accepteren')),
    );
    await tester.pumpAndSettle();

    expect(gateway.calls, contains('acceptGroupRequest:r1'));
    expect(_request('r1'), findsNothing);
    expect(_member('uid-p'), findsOneWidget);
    expect(find.text('Piet is nu lid'), findsOneWidget);
  });

  testWidgets('dubbel tikken op accepteren doet het maar een keer',
      (tester) async {
    final gateway = _gateway();
    await _open(tester, gateway);

    final button =
        find.descendant(of: _request('r1'), matching: find.text('Accepteren'));
    await tester.tap(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      gateway.calls.where((c) => c == 'acceptGroupRequest:r1').length,
      1,
    );
  });

  testWidgets('accepteren bij een volle groep: zin met groepsnaam en 30',
      (tester) async {
    final gateway = _gateway();
    gateway.failWith['acceptGroupRequest'] = GroupError.groupFull;
    await _open(tester, gateway);

    await tester.tap(
      find.descendant(of: _request('r1'), matching: find.text('Accepteren')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Dinsdagclub heeft al 30 leden, het maximum. Haal eerst iemand uit de groep.',
      ),
      findsOneWidget,
    );
    expect(_request('r1'), findsOneWidget);
  });

  testWidgets('accepteren bij iemand in 10 groepen: zin met zijn naam',
      (tester) async {
    final gateway = _gateway();
    gateway.failWith['acceptGroupRequest'] = GroupError.tooManyGroups;
    await _open(tester, gateway);

    await tester.tap(
      find.descendant(of: _request('r2'), matching: find.text('Accepteren')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Mark zit al in 10 groepen, het maximum.'),
      findsOneWidget,
    );
  });

  testWidgets('afwijzen: aanroep, rij weg, snackbar', (tester) async {
    final gateway = _gateway();
    await _open(tester, gateway);

    await tester.tap(
      find.descendant(of: _request('r2'), matching: find.text('Afwijzen')),
    );
    await tester.pumpAndSettle();

    expect(gateway.calls, contains('deleteGroupRequest:r2'));
    expect(_request('r2'), findsNothing);
    expect(_member('uid-m'), findsNothing);
    expect(find.text('Aanvraag van Mark afgewezen'), findsOneWidget);
  });

  testWidgets('sectiekop Leden: lid draagt voor, beheerder voegt toe',
      (tester) async {
    await _open(tester, _gateway(meMember: true));
    expect(find.text('Maatje voordragen'), findsOneWidget);
    expect(find.text('Maatje toevoegen'), findsNothing);
  });

  testWidgets('sectiekop Leden bij een beheerder: Maatje toevoegen',
      (tester) async {
    await _open(tester, _gateway());
    expect(find.text('Maatje toevoegen'), findsOneWidget);
    expect(find.text('Maatje voordragen'), findsNothing);
  });

  testWidgets('sheet: al lid en aanvraag loopt zonder knop, de rest Voordragen',
      (tester) async {
    await _open(tester, _gateway(meMember: true));
    await _openSheet(tester, 'Maatje voordragen');

    expect(
      find.text('Een beheerder beslist of je maatje lid wordt.'),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _friendRow('uid-i'), matching: find.text('al lid')),
      findsOneWidget,
    );
    expect(
      find.descendant(
          of: _friendRow('uid-i'), matching: find.byType(ButtonStyleButton)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: _friendRow('uid-m'),
        matching: find.text('aanvraag loopt'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
          of: _friendRow('uid-m'), matching: find.byType(ButtonStyleButton)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: _friendRow('uid-j'),
        matching: find.text('Voordragen'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('lid draagt Jacco voor: aanvraag loopt en een zin in de sheet',
      (tester) async {
    final gateway = _gateway(meMember: true);
    await _open(tester, gateway);
    await _openSheet(tester, 'Maatje voordragen');

    await tester.tap(
      find.descendant(
          of: _friendRow('uid-j'), matching: find.text('Voordragen')),
    );
    await tester.pumpAndSettle();

    expect(gateway.calls, contains('proposeGroupMember:g1:uid-j'));
    expect(
      find.descendant(
        of: _friendRow('uid-j'),
        matching: find.text('aanvraag loopt'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Jacco is voorgedragen. Een beheerder beslist.'),
      findsOneWidget,
    );
  });

  testWidgets('beheerder voegt Jacco toe: meteen al lid', (tester) async {
    final gateway = _gateway();
    await _open(tester, gateway);
    await _openSheet(tester, 'Maatje toevoegen');

    expect(find.text('Wie je toevoegt is meteen lid.'), findsOneWidget);
    await tester.tap(
      find.descendant(
          of: _friendRow('uid-j'), matching: find.text('Toevoegen')),
    );
    await tester.pumpAndSettle();

    expect(gateway.calls, contains('proposeGroupMember:g1:uid-j'));
    expect(
      find.descendant(of: _friendRow('uid-j'), matching: find.text('al lid')),
      findsOneWidget,
    );
    expect(find.text('Jacco is nu lid'), findsOneWidget);
    expect(gateway.groups['g1']!.isMember('uid-j'), isTrue);
  });

  testWidgets('voordragen mislukt: de foutzin staat in de sheet',
      (tester) async {
    final gateway = _gateway(meMember: true);
    gateway.failWith['proposeGroupMember'] = GroupError.tooManyGroups;
    await _open(tester, gateway);
    await _openSheet(tester, 'Maatje voordragen');

    await tester.tap(
      find.descendant(
          of: _friendRow('uid-j'), matching: find.text('Voordragen')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Jacco zit al in 10 groepen, het maximum.'),
      findsOneWidget,
    );
  });

  testWidgets('volle groep: banner bovenaan en geen knoppen', (tester) async {
    await _open(tester, _gateway(extraMembers: 27));
    await _openSheet(tester, 'Maatje toevoegen');

    expect(
      find.text(
        'Dinsdagclub heeft al 30 leden, het maximum. Haal eerst iemand uit de groep.',
      ),
      findsOneWidget,
    );
    expect(find.text('Toevoegen'), findsNothing);
  });

  testWidgets('geen maatjes: de sheet zegt hoe je er een uitnodigt',
      (tester) async {
    await _open(tester, _gateway(meMember: true, friends: const []));
    await _openSheet(tester, 'Maatje voordragen');

    expect(
      find.text(
        'Je hebt nog geen maatjes. Nodig er een uit onder Maatjes op de Peloton-tab.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Peloton-tab: beheerder ziet het aantal open aanvragen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final gateway = _gateway();
    gateway.groups['g2'] = FakeGroupGateway.group(
      'g2',
      'Buren',
      members: [
        FakeGroupGateway.member(_me, groupId: 'g2'),
        FakeGroupGateway.member('uid-z', groupId: 'g2', role: GroupRole.admin),
      ],
      requests: [FakeGroupGateway.request('r9', 'uid-p', groupId: 'g2')],
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: BuddiesTab()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(gateway, router));
    await tester.pumpAndSettle();

    expect(find.text('2 aanvragen'), findsOneWidget);
    // Bij Buren ben je gewoon lid: daar geen teller.
    expect(find.text('1 aanvraag'), findsNothing);
  });
}
