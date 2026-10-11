// test/features/rides_two_pane_test.dart
//
// Ritten en Peloton naast elkaar vanaf expanded (quick-plan 261011-jru): op
// een telefoon de tabs zoals altijd, op 1280 breed twee kolommen met elk hun
// kop en hun eigen bolletje (CLUB-25).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/features/peloton/buddies_tab.dart';
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

Future<void> _pumpRidesScreen(
  WidgetTester tester,
  Size size, {
  int peloton = 0,
  int rides = 0,
}) async {
  SharedPreferences.setMockInitialValues({'hint_seen_rides': true});
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ridesTabAttentionCountProvider.overrideWithValue(rides),
        pelotonTabAttentionCountProvider.overrideWithValue(peloton),
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

void main() {
  testWidgets('telefoon (400x800): tabs zoals altijd', (tester) async {
    await _pumpRidesScreen(tester, const Size(400, 800));
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(TabBarView), findsOneWidget);
  });

  testWidgets('1280x800: Ritten en Peloton naast elkaar, geen tabs',
      (tester) async {
    await _pumpRidesScreen(tester, const Size(1280, 800));
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsNothing);

    final rides = find.byType(RidesTab);
    final buddies = find.byType(BuddiesTab);
    expect(rides.hitTestable(), findsOneWidget);
    expect(buddies.hitTestable(), findsOneWidget);
    expect(
      tester.getTopLeft(buddies).dx,
      greaterThan(tester.getTopLeft(rides).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('1280x800: elke kolomkop zijn eigen bolletje', (tester) async {
    await _pumpRidesScreen(
      tester,
      const Size(1280, 800),
      peloton: 2,
      rides: 1,
    );
    Finder badgeNextTo(String label) => find.descendant(
          // De dichtstbijzijnde Row: label plus bolletje, niet de hele body.
          of: find
              .ancestor(of: find.text(label), matching: find.byType(Row))
              .first,
          matching: find.byType(Badge),
        );
    expect(find.text('Ritten'), findsOneWidget);
    expect(find.text('Peloton'), findsOneWidget);
    expect(
      (tester.widget<Badge>(badgeNextTo('Ritten')).label! as Text).data,
      '1',
    );
    expect(
      (tester.widget<Badge>(badgeNextTo('Peloton')).label! as Text)
          .data,
      '2',
    );
  });
}
