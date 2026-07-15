// test/features/week_agenda_screen_test.dart
// Baseline widget-test coverage for WeekAgendaScreen's tap-based
// range-selection state machine (replaces the old long-press-drag gesture).
// Covers all 8 locked behavior rules from quick task 260714-spo's plan.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/agenda/week_agenda_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Fake Notifiers
// ---------------------------------------------------------------------------

/// WeatherNotifier stub with real forecast entries — needed by the long-press
/// (weather-detail) test group so `_showDetail`'s score/forecast guard opens.
class FakeWeatherWithForecasts extends WeatherNotifier {
  FakeWeatherWithForecasts(this.forecasts);
  final List<HourlyForecast> forecasts;

  @override
  Future<List<HourlyForecast>> build() async => forecasts;
}

/// WeatherNotifier stub — empty forecast. Used by the tap-state-machine
/// tests where score/forecast content is irrelevant.
class FakeWeatherEmpty extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => const [];
}

/// ProfileNotifier stub — exact fixture reused from home_screen_refresh_test.dart.
class FakeProfileNotifier extends ProfileNotifier {
  @override
  Future<UserProfile> build() async => const UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 10.0,
          tempMaxIdealC: 30.0,
          windMaxIdealKmh: 25.0,
          rainMaxIdealMm: 1.0,
        ),
        allowedDurations: [2, 3],
        theme: 'system',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );
}

/// AvailabilityNotifier stub — optional seeded blocked-hours map.
class FakeAvailabilityNotifier extends AvailabilityNotifier {
  FakeAvailabilityNotifier([this.seed = const {}]);
  final Map<DateTime, BlockType> seed;

  @override
  Future<Map<DateTime, BlockType>> build() async => seed;
}

/// LocationNotifier stub — Amsterdam (exact fixture reused verbatim).
class FakeLocationNotifier extends LocationNotifier {
  @override
  Future<LocationData> build() async =>
      const LocationData(lat: 52.3676, lon: 4.9041, city: 'Amsterdam');
}

/// SlotsNotifier stub — empty slots (exact fixture reused verbatim).
class FakeStaticSlotsNotifier extends SlotsNotifier {
  @override
  SlotsState build() => const SlotsLoaded([], reason: null);
}

/// PlannedRidesNotifier stub — optional seeded rides; `add()` is faked to
/// avoid touching SharedPreferences, and records calls in [added] so tests
/// can assert on commit behavior (Rule 8).
class FakePlannedRidesNotifier extends PlannedRidesNotifier {
  FakePlannedRidesNotifier([this.seed = const []]);
  final List<PlannedRide> seed;
  final List<PlannedRide> added = [];

  @override
  List<PlannedRide> build() => seed;

  @override
  void add(PlannedRide ride) {
    added.add(ride);
    state = [...state, ride];
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps a `WeekAgendaScreen` wrapped in a fully-faked `ProviderScope`.
Future<void> pumpAgendaApp(
  WidgetTester tester, {
  Map<DateTime, BlockType> blockedHours = const {},
  List<PlannedRide> plannedRides = const [],
  WeatherNotifier Function()? weatherFn,
  FakePlannedRidesNotifier? plannedRidesNotifier,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        weatherProvider.overrideWith(weatherFn ?? () => FakeWeatherEmpty()),
        profileProvider.overrideWith(() => FakeProfileNotifier()),
        availabilityProvider.overrideWith(() => FakeAvailabilityNotifier(blockedHours)),
        locationProvider.overrideWith(() => FakeLocationNotifier()),
        slotsProvider.overrideWith(() => FakeStaticSlotsNotifier()),
        plannedRidesProvider.overrideWith(
          () => plannedRidesNotifier ?? FakePlannedRidesNotifier(plannedRides),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: ThemeData(extensions: [RideWindowTheme.light]),
        home: const WeekAgendaScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  /// Mirrors production's exact cell-timestamp derivation (add whole days
  /// first, then rebuild the DateTime at the target hour via field
  /// construction) so results stay identical to production across a DST
  /// transition week.
  DateTime cellTime(int n, int hour) {
    final day = today.add(Duration(days: n));
    return DateTime(day.year, day.month, day.day, hour);
  }

  /// Generates one HourlyForecast per (day offset 0-6, hour 6-22) combination
  /// so every cell used by any test has a resolvable score/forecast.
  List<HourlyForecast> buildForecastsFor(DateTime today) {
    final forecasts = <HourlyForecast>[];
    for (var dayOffset = 0; dayOffset <= 6; dayOffset++) {
      for (var hour = 6; hour <= 22; hour++) {
        forecasts.add(
          HourlyForecast(
            temperatureC: 20.0,
            apparentTemperatureC: 19.0,
            precipitationMm: 0.0,
            precipitationProbability: 5.0,
            windspeedKmh: 10.0,
            winddirectionDeg: 90.0,
            time: today.add(Duration(days: dayOffset, hours: hour)),
          ),
        );
      }
    }
    return forecasts;
  }

  Finder cellFinder(int dayIndex, int hour) =>
      find.byKey(ValueKey('cell_${dayIndex}_$hour'));

  bool cellHasCheckmark(WidgetTester tester, int dayIndex, int hour) =>
      find
          .descendant(of: cellFinder(dayIndex, hour), matching: find.byIcon(Icons.check))
          .evaluate()
          .isNotEmpty;

  setUp(() {
    SharedPreferences.setMockInitialValues({'hint_seen_agenda': true});
  });

  testWidgets(
    'Test 1 (Rule 1): tap an empty hour with no active selection opens a 1-hour anchor',
    (tester) async {
      await pumpAgendaApp(tester);

      await tester.tap(cellFinder(0, 9));
      await tester.pump();

      expect(cellHasCheckmark(tester, 0, 9), isTrue);
      expect(find.text('1 uur geselecteerd'), findsOneWidget);
      expect(find.text('Rit inplannen (1u)'), findsOneWidget);
    },
  );

  testWidgets(
    'Test 2 (Rules 2/4): repeated same-day taps recompute against the fixed original anchor',
    (tester) async {
      await pumpAgendaApp(tester);

      await tester.tap(cellFinder(0, 9));
      await tester.pump();

      await tester.tap(cellFinder(0, 12));
      await tester.pump();
      expect(find.text('4 uur geselecteerd'), findsOneWidget);

      // Tapping 10 must recompute against the ORIGINAL anchor (9), shrinking
      // to 9-10, NOT using the previous far edge (12) as a reference.
      await tester.tap(cellFinder(0, 10));
      await tester.pump();
      expect(find.text('2 uur geselecteerd'), findsOneWidget);

      await tester.tap(cellFinder(0, 14));
      await tester.pump();
      expect(find.text('6 uur geselecteerd'), findsOneWidget);
    },
  );

  testWidgets(
    'Test 3 (Rule 3): re-tapping the anchor while still exactly 1 hour cancels the selection',
    (tester) async {
      await pumpAgendaApp(tester);

      await tester.tap(cellFinder(1, 10));
      await tester.pump();
      expect(find.text('1 uur geselecteerd'), findsOneWidget);

      await tester.tap(cellFinder(1, 10));
      await tester.pump();

      expect(find.text('1 uur geselecteerd'), findsNothing);
      expect(find.text('Rit inplannen (1u)'), findsNothing);
      expect(cellHasCheckmark(tester, 1, 10), isFalse);
    },
  );

  testWidgets(
    'Test 4 (Rule 5): tapping a different day discards the old selection and starts a new one',
    (tester) async {
      await pumpAgendaApp(tester);

      await tester.tap(cellFinder(0, 9));
      await tester.pump();
      expect(cellHasCheckmark(tester, 0, 9), isTrue);

      await tester.tap(cellFinder(2, 11));
      await tester.pump();

      expect(cellHasCheckmark(tester, 0, 9), isFalse);
      expect(cellHasCheckmark(tester, 2, 11), isTrue);
      expect(find.text('1 uur geselecteerd'), findsOneWidget);
    },
  );

  testWidgets(
    'Test 5 (Rule 6): tapping a blocked or planned cell is always a no-op',
    (tester) async {
      final blocked = {cellTime(0, 6): BlockType.work};
      final planned = [
        PlannedRide(start: cellTime(0, 20), end: cellTime(0, 20).add(const Duration(hours: 1)), plannedScore: 80),
      ];
      await pumpAgendaApp(tester, blockedHours: blocked, plannedRides: planned);

      await tester.tap(cellFinder(0, 9));
      await tester.pump();
      expect(find.text('1 uur geselecteerd'), findsOneWidget);

      await tester.tap(cellFinder(0, 6));
      await tester.pump();
      expect(find.text('1 uur geselecteerd'), findsOneWidget);
      expect(cellHasCheckmark(tester, 0, 9), isTrue);
      expect(cellHasCheckmark(tester, 0, 6), isFalse);

      await tester.tap(cellFinder(0, 20));
      await tester.pump();
      expect(find.text('1 uur geselecteerd'), findsOneWidget);
      expect(cellHasCheckmark(tester, 0, 9), isTrue);
    },
  );

  testWidgets(
    'Test 6 (Rule 7): long-press any cell always opens the weather-detail sheet, never disturbing a selection',
    (tester) async {
      final blocked = {cellTime(0, 6): BlockType.work};
      await pumpAgendaApp(
        tester,
        blockedHours: blocked,
        weatherFn: () => FakeWeatherWithForecasts(buildForecastsFor(today)),
      );

      // Long-press a free cell with no active selection.
      await tester.longPress(cellFinder(0, 9));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('9:00 – 10:00'), findsOneWidget);

      // Dismiss the sheet by tapping outside its content area.
      await tester.tapAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      // Open an anchor, then long-press the blocked cell.
      await tester.tap(cellFinder(0, 9));
      await tester.pump();
      expect(find.text('1 uur geselecteerd'), findsOneWidget);

      await tester.longPress(cellFinder(0, 6));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('6:00 – 7:00'), findsOneWidget);

      await tester.tapAt(const Offset(20, 80));
      await tester.pumpAndSettle();

      // Selection must be untouched.
      expect(find.text('1 uur geselecteerd'), findsOneWidget);

      // Long-pressing the currently-selected anchor cell itself also opens
      // the sheet (tap and long-press coexist).
      await tester.longPress(cellFinder(0, 9));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('9:00 – 10:00'), findsOneWidget);
    },
  );

  testWidgets(
    'Test 7 (Rule 8): Plan rit commits via the notifier and clears selection; Annuleer clears without committing',
    (tester) async {
      final fakeNotifier = FakePlannedRidesNotifier();
      await pumpAgendaApp(tester, plannedRidesNotifier: fakeNotifier);

      await tester.tap(cellFinder(0, 9));
      await tester.pump();

      await tester.tap(find.text('Rit inplannen (1u)'));
      await tester.pump();

      expect(fakeNotifier.added.length, 1);
      expect(find.text('Rit inplannen (1u)'), findsNothing);
      expect(cellHasCheckmark(tester, 0, 9), isFalse);
      expect(find.text('Rit ingepland (1u)!'), findsOneWidget);

      await tester.tap(cellFinder(1, 9));
      await tester.pump();
      expect(find.text('1 uur geselecteerd'), findsOneWidget);

      await tester.tap(find.text('Annuleer'));
      await tester.pump();

      expect(fakeNotifier.added.length, 1);
      expect(find.text('1 uur geselecteerd'), findsNothing);
      expect(cellHasCheckmark(tester, 1, 9), isFalse);
    },
  );
}
