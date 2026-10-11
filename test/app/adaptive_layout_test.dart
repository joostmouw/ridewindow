// test/app/adaptive_layout_test.dart
//
// Tabletweergave (quick-plan 261011-jru): breedteklassen volgens Material 3,
// onderbalk op de telefoon en een navigatierail vanaf 600 dp, en de
// leesbreedte van 640 dp op Welcome, Onboarding en Profiel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ridewindow/app/scaffold_with_nav.dart';
import 'package:ridewindow/app/window_size.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/ride_entries_provider.dart';
import 'package:ridewindow/theme/app_theme.dart';

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _pumpShell(WidgetTester tester, Size size, {int count = 0}) async {
  _setSize(tester, size);
  Widget page(String name) => Center(child: Text(name));
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ScaffoldWithNav(navigationShell: shell),
        branches: [
          for (final p in ['/home', '/agenda', '/rides', '/profile'])
            StatefulShellBranch(
              routes: [GoRoute(path: p, builder: (_, __) => page(p))],
            ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pelotonAttentionCountProvider.overrideWithValue(count),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: buildAppTheme(Brightness.light),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpReadable(WidgetTester tester, Size size) async {
  _setSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ReadableWidth(
          child: ListView(
            key: const ValueKey('list'),
            children: const [ListTile(title: Text('a'))],
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('windowSizeClassFor', () {
    test('grenzen op 600 en 840', () {
      expect(windowSizeClassFor(0), WindowSizeClass.compact);
      expect(windowSizeClassFor(599), WindowSizeClass.compact);
      expect(windowSizeClassFor(600), WindowSizeClass.medium);
      expect(windowSizeClassFor(839), WindowSizeClass.medium);
      expect(windowSizeClassFor(840), WindowSizeClass.expanded);
      expect(windowSizeClassFor(1280), WindowSizeClass.expanded);
    });
  });

  group('shell', () {
    testWidgets('telefoon (400x800): onderbalk, geen rail', (tester) async {
      await _pumpShell(tester, const Size(400, 800));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    for (final size in const [Size(700, 1000), Size(1280, 800)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}: rail, '
          'geen onderbalk', (tester) async {
        await _pumpShell(tester, size);
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.destinations, hasLength(4));
        for (final label in ['Home', 'Agenda', 'Ritten', 'Profiel']) {
          expect(
            find.descendant(
              of: find.byType(NavigationRail),
              matching: find.text(label),
            ),
            findsOneWidget,
          );
        }
        await tester.tap(find.text('Ritten'));
        await tester.pumpAndSettle();
        expect(find.text('/rides'), findsOneWidget);
      });
    }

    testWidgets('de rail toont hetzelfde bolletje (9+ bij 12)',
        (tester) async {
      await _pumpShell(tester, const Size(1280, 800), count: 12);
      final badges = find.descendant(
        of: find.byType(NavigationRail),
        matching: find.byType(Badge),
      );
      expect(badges, findsOneWidget);
      expect((tester.widget<Badge>(badges).label! as Text).data, '9+');
      expect(unansweredBadgeLabel(12), '9+');
    });
  });

  group('ReadableWidth', () {
    testWidgets('telefoon: volle breedte', (tester) async {
      await _pumpReadable(tester, const Size(400, 800));
      expect(tester.getSize(find.byKey(const ValueKey('list'))).width, 400);
    });

    testWidgets('1280x800: hooguit 640 breed en gecentreerd', (tester) async {
      await _pumpReadable(tester, const Size(1280, 800));
      final list = find.byKey(const ValueKey('list'));
      expect(tester.getSize(list).width, lessThanOrEqualTo(kReadableMaxWidth));
      expect(tester.getCenter(list).dx, 640);
      // De hoogte blijft strak: de lijst vult het lichaam.
      expect(tester.getSize(list).height, 800);
    });
  });
}
