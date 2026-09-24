// test/features/peloton_groups_section_test.dart
//
// De sectie Groepen op de Peloton-tab (schets 015, vraag 1, variant A):
// kaarten, lege staat, aanvraagkaarten, maken tot op het groepsscherm, de
// 10-groepengrens en de info-knop. En: uitgelogd verandert er niets.

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

Future<GoRouter> _pump(
  WidgetTester tester,
  FakeGroupGateway gateway, {
  String? userId = _me,
}) async {
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
        currentUserIdProvider.overrideWithValue(userId),
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
  return router;
}

FakeGroupGateway _twoGroups() => FakeGroupGateway(
      me: _me,
      friends: const [Friend(userId: 'uid-a', displayName: 'Anna')],
      groups: {
        'g1': FakeGroupGateway.group(
          'g1',
          'Dinsdagclub',
          members: [
            FakeGroupGateway.member(_me, role: GroupRole.admin),
            FakeGroupGateway.member('uid-a', joinedDay: 1),
            FakeGroupGateway.member('uid-b', joinedDay: 2),
          ],
        ),
        'g2': FakeGroupGateway.group(
          'g2',
          'Buren',
          members: [
            FakeGroupGateway.member(_me, groupId: 'g2'),
          ],
        ),
      },
    );

void main() {
  testWidgets('uitgelogd: geen groepen, de uitgelogde staat blijft',
      (tester) async {
    final gateway = _twoGroups();
    await _pump(tester, gateway, userId: null);

    expect(find.text('GROEPEN'), findsNothing);
    expect(find.text('Groep maken'), findsNothing);
    expect(gateway.calls, isEmpty);
  });

  testWidgets('geen groepen: uitnodigende kaart met Groep maken',
      (tester) async {
    await _pump(tester, FakeGroupGateway(me: _me));

    expect(find.text('GROEPEN'), findsOneWidget);
    expect(find.text('Fiets je met een vaste club?'), findsOneWidget);
    expect(find.text('Groep maken'), findsOneWidget);
    expect(find.text('Nieuwe groep'), findsNothing);
  });

  testWidgets('twee groepen: namen, ledental, beheerder-chip en Nieuwe groep',
      (tester) async {
    await _pump(tester, _twoGroups());

    expect(find.text('Dinsdagclub'), findsOneWidget);
    expect(find.text('Buren'), findsOneWidget);
    expect(find.text('3 leden'), findsOneWidget);
    expect(find.text('1 lid'), findsOneWidget);
    expect(find.text('beheerder'), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Dinsdagclub'),
          matching: find.byType(ListTile),
        ),
        matching: find.text('beheerder'),
      ),
      findsOneWidget,
    );
    expect(find.text('Nieuwe groep'), findsOneWidget);
    expect(find.text('Fiets je met een vaste club?'), findsNothing);
  });

  testWidgets('aanvraag loopt: kaart zonder ledental', (tester) async {
    await _pump(
      tester,
      FakeGroupGateway(
        me: _me,
        groups: {
          'g3': FakeGroupGateway.group(
            'g3',
            'Zondagrijders',
            members: [
              FakeGroupGateway.member(
                'uid-b',
                groupId: 'g3',
                role: GroupRole.admin,
              ),
              FakeGroupGateway.member('uid-c', groupId: 'g3'),
            ],
            requests: [FakeGroupGateway.request('r1', _me, groupId: 'g3')],
          ),
        },
      ),
    );

    expect(find.text('Zondagrijders'), findsOneWidget);
    expect(find.text('aanvraag loopt'), findsOneWidget);
    expect(find.text('2 leden'), findsNothing);
  });

  testWidgets('tik op een kaart opent het groepsscherm', (tester) async {
    await _pump(tester, _twoGroups());
    await tester.tap(find.text('Buren'));
    await tester.pumpAndSettle();
    expect(find.text('groep-g2'), findsOneWidget);
  });

  testWidgets('groep maken: sheet, naam, en door naar het groepsscherm',
      (tester) async {
    final gateway = FakeGroupGateway(me: _me);
    await _pump(tester, gateway);

    await tester.tap(find.text('Groep maken'));
    await tester.pumpAndSettle();
    expect(find.text('Nieuwe groep'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Dinsdagclub');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Groep maken').last);
    await tester.pumpAndSettle();

    expect(gateway.calls, contains('createGroup:Dinsdagclub'));
    expect(find.text('groep-g-new-1'), findsOneWidget);
  });

  testWidgets('met 10 groepen: geen sheet maar de grenszin', (tester) async {
    final gateway = FakeGroupGateway(
      me: _me,
      groups: {
        for (var i = 0; i < kMaxGroupsPerAccount; i++)
          'g$i': FakeGroupGateway.group(
            'g$i',
            'Groep $i',
            members: [FakeGroupGateway.member(_me, groupId: 'g$i')],
          ),
      },
    );
    await _pump(tester, gateway);

    await tester.tap(find.text('Nieuwe groep'));
    await tester.pumpAndSettle();

    // Geen sheet: de titel "Nieuwe groep" staat er alleen als kopknop.
    expect(find.text('Nieuwe groep'), findsOneWidget);
    expect(
      find.text(
        'Je zit al in 10 groepen, het maximum. Verlaat eerst een andere groep.',
      ),
      findsOneWidget,
    );
    expect(gateway.calls.where((c) => c.startsWith('createGroup')), isEmpty);
  });

  testWidgets('createGroup faalt met too_many_groups: zin in een snackbar',
      (tester) async {
    final gateway = FakeGroupGateway(me: _me)
      ..failWith['createGroup'] = GroupError.tooManyGroups;
    await _pump(tester, gateway);

    await tester.tap(find.text('Groep maken'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Dinsdagclub');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Groep maken').last);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Je zit al in 10 groepen, het maximum. Verlaat eerst een andere groep.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('info-knop naast Groepen opent de regels', (tester) async {
    await _pump(tester, _twoGroups());

    await tester.tap(find.byTooltip('Zo werken groepen'));
    await tester.pumpAndSettle();

    expect(find.text('Zo werken groepen'), findsWidgets);
    expect(
      find.textContaining('maximaal 30 leden'),
      findsOneWidget,
    );
  });

  testWidgets('Maatjes staat er nog, onder Groepen', (tester) async {
    await _pump(tester, _twoGroups());

    final groups = tester.getTopLeft(find.text('GROEPEN'));
    final friends = tester.getTopLeft(find.text('MAATJES'));
    expect(groups.dy, lessThan(friends.dy));
  });
}
