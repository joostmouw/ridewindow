// test/features/group_menu_test.dart
//
// Groepsbrede handelingen op het groepsscherm (plan 34-06): de groepslink
// delen (ieder lid, HERZIENING), en het appbar-menu met naam wijzigen, link
// vervangen, verlaten en opheffen (schets 015, vraag 2, variant A).
//
// Het deelmenu wordt via het platformkanaal van share_plus gemockt; de tekst
// staat in arguments['text'].

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/features/peloton/group_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';
const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
const _generic = 'Dat is niet gelukt. Probeer het opnieuw.';

/// Dinsdagclub met jou, Anna en Ingrid. Standaard ben jij beheerder naast
/// Anna. [meMember]: jij bent gewoon lid. [soleAdmin]: jij bent de enige
/// beheerder. [alone]: jij bent het enige lid. [pending]: jij hebt alleen een
/// aanvraag.
FakeGroupGateway _gateway({
  bool meMember = false,
  bool soleAdmin = false,
  bool alone = false,
  bool pending = false,
}) {
  final me = FakeGroupGateway.member(
    _me,
    role: meMember ? GroupRole.member : GroupRole.admin,
    name: 'Ik',
  );
  return FakeGroupGateway(
    me: _me,
    groups: {
      'g1': FakeGroupGateway.group(
        'g1',
        'Dinsdagclub',
        members: [
          if (!pending) me,
          if (!alone) ...[
            FakeGroupGateway.member(
              'uid-a',
              role: (soleAdmin || pending) ? GroupRole.member : GroupRole.admin,
              name: 'Anna',
              joinedDay: 1,
            ),
            FakeGroupGateway.member(
              'uid-i',
              role: pending ? GroupRole.admin : GroupRole.member,
              name: 'Ingrid',
              joinedDay: 2,
            ),
          ],
        ],
        requests: [
          if (pending) FakeGroupGateway.request('r1', _me, name: 'Ik'),
        ],
      ),
    },
  );
}

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

final _menuButton = find.byTooltip('Groepsopties');

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(_menuButton);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String item) async {
  await _openMenu(tester);
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final shared = <String>[];

  setUp(() {
    shared.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _shareChannel,
      (call) async {
        final args = call.arguments;
        if (args is Map && args['text'] is String) {
          shared.add(args['text'] as String);
        }
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, null);
  });

  group('groepslink delen', () {
    testWidgets('gewoon lid en beheerder zien de knop, een aanvrager niet',
        (tester) async {
      await _open(tester, _gateway(meMember: true));
      expect(find.text('Deel de groepslink'), findsOneWidget);

      await _open(tester, _gateway());
      expect(find.text('Deel de groepslink'), findsOneWidget);

      await _open(tester, _gateway(pending: true));
      expect(find.text('Je aanvraag ligt bij de beheerders'), findsWidgets);
      expect(find.text('Deel de groepslink'), findsNothing);
    });

    testWidgets('tik deelt tekst met groepsnaam, link en code', (tester) async {
      final gateway = _gateway(meMember: true);
      await _open(tester, gateway);

      await tester.tap(find.text('Deel de groepslink'));
      await tester.pumpAndSettle();

      expect(gateway.calls, contains('groupInviteCode:g1'));
      expect(shared, hasLength(1));
      final code = gateway.inviteCodes.keys.single;
      expect(shared.single, contains('Dinsdagclub'));
      expect(
        shared.single,
        contains('https://my-project-joost.web.app/#/group/$code'),
      );
      expect(shared.single, contains('code $code'));
    });

    testWidgets('mislukte code geeft de generieke foutzin', (tester) async {
      final gateway = _gateway()
        ..failWith['groupInviteCode'] = GroupError.unknown;
      await _open(tester, gateway);

      await tester.tap(find.text('Deel de groepslink'));
      await tester.pumpAndSettle();

      expect(shared, isEmpty);
      expect(find.text(_generic), findsOneWidget);
    });
  });

  group('link vervangen', () {
    testWidgets('beheerder vervangt en deelt meteen de nieuwe code',
        (tester) async {
      final gateway = _gateway();
      gateway.inviteCodes['OUDECODE'] = 'g1';
      await _open(tester, gateway);

      await _choose(tester, 'Link vervangen');

      expect(gateway.calls, contains('replaceGroupInvite:g1'));
      expect(
        find.text('Nieuwe link gemaakt. De oude werkt niet meer.'),
        findsOneWidget,
      );
      final code = gateway.inviteCodes.keys.single;
      expect(code, isNot('OUDECODE'));

      await tester.tap(find.widgetWithText(SnackBarAction, 'Delen'));
      await tester.pumpAndSettle();

      expect(shared, hasLength(1));
      expect(
        shared.single,
        contains('https://my-project-joost.web.app/#/group/$code'),
      );
      // Delen van de nieuwe code vraagt niet nog eens een code op.
      expect(gateway.calls, isNot(contains('groupInviteCode:g1')));
    });
  });
}
