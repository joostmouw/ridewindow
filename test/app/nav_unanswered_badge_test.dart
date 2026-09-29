// test/app/nav_unanswered_badge_test.dart
//
// Het rode bolletje "wacht op je" (CLUB-25, schets 016 vraag 1 A). Wat het
// telt, staat in test/providers/peloton_attention_test.dart.
//
// Zonder pushmeldingen is de onderbalk de plek waar je moet zien dat er iets
// op je wacht. Onderbalk en de tab Peloton lezen dezelfde provider, dus deze
// tests zetten die ene provider op 0, 2 en 12 en kijken op beide plekken.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/app/scaffold_with_nav.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/features/planned/planned_rides_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/ride_entries_provider.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

class _FakePlannedRides extends PlannedRidesNotifier {
  @override
  Future<List<PlannedRide>> build() async => const [];
}

class _FakeWeather extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => const [];
}

Future<void> _pumpShell(
  WidgetTester tester,
  int count, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

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
        theme: buildAppTheme(brightness),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpRidesScreen(
  WidgetTester tester,
  int count, {
  int rides = 0,
}) async {
  SharedPreferences.setMockInitialValues({'hint_seen_rides': true});
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ridesTabAttentionCountProvider.overrideWithValue(rides),
        pelotonTabAttentionCountProvider.overrideWithValue(count),
        rideEntriesProvider.overrideWithValue(const []),
        currentUserIdProvider.overrideWithValue(null),
        plannedRidesProvider.overrideWith(_FakePlannedRides.new),
        weatherProvider.overrideWith(_FakeWeather.new),
      ],
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: const PlannedRidesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Finder _navBadges() => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byType(Badge),
    );

Finder _tabBadges() => find.descendant(
      of: find.byType(TabBar),
      matching: find.byType(Badge),
    );

void main() {
  group('onderbalk', () {
    testWidgets('bij 0 staat er geen bolletje', (tester) async {
      await _pumpShell(tester, 0);
      expect(_navBadges(), findsNothing);
      expect(find.textContaining('wachten op je'), findsNothing);
    });

    testWidgets('bij 2 staat er een bolletje met 2 op Ritten', (tester) async {
      await _pumpShell(tester, 2);
      expect(_navBadges(), findsOneWidget);
      final badge = tester.widget<Badge>(_navBadges());
      expect((badge.label! as Text).data, '2');
      // Op de Ritten-bestemming, niet op een andere.
      final ritten = find.ancestor(
        of: find.text('Ritten'),
        matching: find.byType(NavigationDestination),
      );
      expect(
        find.descendant(of: ritten, matching: find.byType(Badge)),
        findsOneWidget,
      );
    });

    testWidgets('het bolletje blijft staan als Ritten gekozen is',
        (tester) async {
      await _pumpShell(tester, 2);
      await tester.tap(find.text('Ritten'));
      await tester.pumpAndSettle();
      expect(find.text('/rides'), findsOneWidget);
      expect(_navBadges(), findsOneWidget);
    });

    testWidgets('boven 9 staat er 9+', (tester) async {
      await _pumpShell(tester, 12);
      final badge = tester.widget<Badge>(_navBadges());
      expect((badge.label! as Text).data, '9+');
    });

    testWidgets('een schermlezer hoort Ritten en het aantal', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpShell(tester, 2);
      expect(
        find.bySemanticsLabel(
          RegExp(r'Ritten[\s\S]*2 dingen wachten op je|'
              r'2 dingen wachten op je[\s\S]*Ritten'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('het bolletje is rood uit het thema, ook donker',
        (tester) async {
      await _pumpShell(tester, 2, brightness: Brightness.dark);
      final badge = tester.widget<Badge>(_navBadges());
      // Geen eigen kleur: dan geldt de M3-standaard colorScheme.error.
      expect(badge.backgroundColor, isNull);
      expect(badge.textColor, isNull);
    });
  });

  group('tab Peloton', () {
    testWidgets('bij 0 alleen "Peloton"', (tester) async {
      await _pumpRidesScreen(tester, 0);
      expect(find.text('Peloton'), findsOneWidget);
      expect(_tabBadges(), findsNothing);
    });

    testWidgets('bij 2 hetzelfde getal naast "Peloton"', (tester) async {
      await _pumpRidesScreen(tester, 2);
      expect(find.text('Peloton'), findsOneWidget);
      expect(_tabBadges(), findsOneWidget);
      expect(
        (tester.widget<Badge>(_tabBadges()).label! as Text).data,
        '2',
      );
    });

    testWidgets('bij 12 staat er 9+ en past de tab op 360 dp met grote tekst',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpRidesScreen(tester, 12);
      expect(
        (tester.widget<Badge>(_tabBadges()).label! as Text).data,
        '9+',
      );
      expect(tester.takeException(), isNull);
    });
  });

  // Video 29 september: "Peloton 1" terwijl de 1 een ritvraag op de tab
  // Ritten was. Elk getal hoort op de tab waar het over gaat.
  group('elke tab zijn eigen getal', () {
    Finder badgeOn(String tab) => find.descendant(
          of: find.ancestor(of: find.text(tab), matching: find.byType(Tab)),
          matching: find.byType(Badge),
        );

    testWidgets('een ritvraag staat op Ritten, niet op Peloton',
        (tester) async {
      await _pumpRidesScreen(tester, 0, rides: 1);
      expect(badgeOn('Ritten'), findsOneWidget);
      expect(badgeOn('Peloton'), findsNothing);
    });

    testWidgets('allebei: twee bolletjes met elk hun getal', (tester) async {
      await _pumpRidesScreen(tester, 2, rides: 1);
      expect(
        (tester.widget<Badge>(badgeOn('Ritten')).label! as Text).data,
        '1',
      );
      expect(
        (tester.widget<Badge>(badgeOn('Peloton')).label! as Text).data,
        '2',
      );
    });
  });
}
