// test/features/group_screen_test.dart
//
// Het groepsscherm in leesstand (schets 015, vraag 2, variant A, zonder de
// beheerknoppen van plan 05/06): hero, ledenlijst met "(jij)" en de chip
// beheerder en verder niets van een lid (CLUB-05), de aanvraagstaat met
// intrekken, de staat voor een onbekende groep en de weg terug.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/core/safe_back_button.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/group_rules_sheet.dart';
import 'package:ridewindow/features/peloton/group_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';

FakeGroupGateway _gateway({bool meAdmin = false}) => FakeGroupGateway(
      me: _me,
      groups: {
        'g1': FakeGroupGateway.group(
          'g1',
          'Dinsdagclub',
          members: [
            FakeGroupGateway.member(
              'uid-a',
              role: GroupRole.admin,
              name: 'Anna',
            ),
            FakeGroupGateway.member(
              _me,
              role: meAdmin ? GroupRole.admin : GroupRole.member,
              name: 'Ingrid',
              joinedDay: 1,
            ),
            FakeGroupGateway.member(
              'uid-b',
              role: meAdmin ? GroupRole.member : GroupRole.admin,
              name: 'Bert',
              joinedDay: 2,
            ),
          ],
        ),
        'g2': FakeGroupGateway.group(
          'g2',
          'Zondagrijders',
          members: [
            FakeGroupGateway.member(
              'uid-c',
              groupId: 'g2',
              role: GroupRole.admin,
              name: 'Carla',
            ),
          ],
          requests: [FakeGroupGateway.request('r7', _me, groupId: 'g2')],
        ),
        'solo': FakeGroupGateway.group(
          'solo',
          'Alleen ik',
          members: [
            FakeGroupGateway.member(
              _me,
              groupId: 'solo',
              role: GroupRole.admin,
              name: 'Ingrid',
            ),
          ],
        ),
      },
    );

Future<void> _open(
  WidgetTester tester,
  FakeGroupGateway gateway,
  String groupId,
) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('peloton')),
      ),
      GoRoute(
        path: '/rides',
        builder: (_, __) => const Scaffold(body: Text('rides')),
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
  router.push('/peloton/group/$groupId');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lid: titel, hero en leden met (jij) en beheerder-chips',
      (tester) async {
    await _open(tester, _gateway(), 'g1');

    // Appbar-titel en hero dragen allebei de naam.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Dinsdagclub'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('3 leden · sinds '), findsOneWidget);

    final anna = tester.getTopLeft(find.text('Anna')).dy;
    final bert = tester.getTopLeft(find.text('Bert')).dy;
    final ingrid = tester.getTopLeft(find.text('Ingrid (jij)')).dy;
    // De volgorde van het model (dat sorteert zelf in fromRows); het scherm
    // sorteert niet opnieuw.
    expect(anna, lessThan(ingrid));
    expect(ingrid, lessThan(bert));
    expect(find.textContaining('(jij)'), findsOneWidget);
    expect(find.text('beheerder'), findsNWidgets(2));
  });

  testWidgets('per lid alleen naam en chip; zonder naam heet je Fietser',
      (tester) async {
    final gateway = _gateway();
    gateway.groups['g1'] = FakeGroupGateway.group(
      'g1',
      'Dinsdagclub',
      members: [
        FakeGroupGateway.member(_me, role: GroupRole.admin, name: 'Ingrid'),
        GroupMember(
          groupId: 'g1',
          userId: 'uid-x',
          role: GroupRole.member,
          joinedAt: FakeGroupGateway.baseDate,
        ),
      ],
    );
    await _open(tester, gateway, 'g1');

    expect(find.text('Fietser'), findsOneWidget);
    // Twee ledenrijen, elk met precies één regel tekst: de naam.
    final rows = find.byKey(const ValueKey('group-member-uid-x'));
    expect(rows, findsOneWidget);
    final texts = tester
        .widgetList<Text>(
            find.descendant(of: rows, matching: find.byType(Text)))
        .map((t) => t.data)
        .where((d) => d != 'F')
        .toList();
    expect(texts, ['Fietser']);
    expect(find.textContaining('uid-'), findsNothing);
  });

  testWidgets('enig lid: hint om te delen of voor te dragen', (tester) async {
    await _open(tester, _gateway(), 'solo');
    expect(
      find.text(
        'Je bent nog alleen. Deel de groepslink of draag een maatje voor.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('1 lid · sinds '), findsOneWidget);
  });

  testWidgets('aanvraagstaat: geen leden, intrekken gaat terug met snackbar',
      (tester) async {
    final gateway = _gateway();
    await _open(tester, gateway, 'g2');

    expect(find.text('Je aanvraag ligt bij de beheerders'), findsOneWidget);
    expect(find.text('Carla'), findsNothing);
    expect(find.text('LEDEN'), findsNothing);

    await tester.tap(find.text('Aanvraag intrekken'));
    await tester.pumpAndSettle();

    expect(gateway.calls, contains('deleteGroupRequest:r7'));
    expect(find.text('peloton'), findsOneWidget);
    expect(find.text('Aanvraag ingetrokken'), findsOneWidget);
  });

  testWidgets('onbekende groep: uitleg en een knop naar Peloton',
      (tester) async {
    await _open(tester, _gateway(), 'bestaat-niet');

    expect(
      find.text(
        'Deze groep bestaat niet meer, of je bent er geen lid meer van.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Naar Peloton'));
    await tester.pumpAndSettle();
    expect(find.text('rides'), findsOneWidget);
  });

  testWidgets('appbar: terugknop en de groepsregels', (tester) async {
    await _open(tester, _gateway(), 'g1');

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(SafeBackButton),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(GroupRulesButton),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(GroupRulesButton));
    await tester.pumpAndSettle();
    expect(find.text('Zo werken groepen'), findsOneWidget);
    Navigator.of(tester.element(find.text('Zo werken groepen'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SafeBackButton));
    await tester.pumpAndSettle();
    expect(find.text('peloton'), findsOneWidget);
  });
}
