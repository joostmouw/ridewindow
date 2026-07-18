// test/features/ride_detail_screen_test.dart
// Widget tests for RideDetailScreen (Wave 2 full screen).
//
// TDD RED: Written before implementation. Tests define expected behavior:
//   - AppBar toont start/eindtijd van slot
//   - Score-banner toont tier-emoji en label
//   - Info-kaart "Uurlijks" toont rijen per HourlyRow
//   - "i"-knop opent InsightsSheet via showModalBottomSheet
//   - Placeholder-knoppen tonen een SnackBar
//
// Tests gebruiken een MaterialApp wrapper (niet go_router) voor widget isolation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/features/detail/ride_detail_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/platform/notification_service.dart';
import 'package:ridewindow/providers/hourly_scores_provider.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// NotificationService stub — avoids the real flutter_local_notifications
/// platform channel, which is not available in a plain widget test
/// (LateInitializationError on FlutterLocalNotificationsPlatform.instance).
class FakeNotificationService extends NotificationService {
  @override
  Future<bool> canScheduleExact() async => false;

  @override
  Future<void> scheduleEveningBefore({
    required DateTime slotDay,
    required String slotTitle,
    required bool exact,
  }) async {}
}

// ---------------------------------------------------------------------------
// Fake Notifiers — RideDetailScreen is a ConsumerStatefulWidget and reads
// allHourlyScoresProvider, weatherProvider and plannedRidesProvider
// directly, so a bare MaterialApp with no ProviderScope ancestor throws
// "Bad state: No ProviderScope found".
//
// allHourlyScoresProvider is overridden with a fixed value (the slot's own
// `hours`, exactly what these tests construct and assert against) rather
// than left to compute via the real ScoringEngine from weatherProvider +
// profileProvider — the tests care about "does the widget render this
// HourlyScore data correctly", not "does the scoring engine agree with the
// fixture's hardcoded tier/score".
// ---------------------------------------------------------------------------

/// WeatherNotifier stub that returns exactly the forecasts passed to the
/// widget under test, so _effectiveForecasts (hourly table, avg temp/wind/
/// rain) sees the same timestamps the widget filters by.
class FakeWeatherNotifier extends WeatherNotifier {
  FakeWeatherNotifier(this.forecasts);
  final List<HourlyForecast> forecasts;

  @override
  Future<List<HourlyForecast>> build() async => forecasts;
}

/// PlannedRidesNotifier stub — empty by default; add()/remove() are faked
/// to avoid touching SharedPreferences.
class FakePlannedRidesNotifier extends PlannedRidesNotifier {
  @override
  List<PlannedRide> build() => [];

  @override
  void add(PlannedRide ride) {
    state = [...state, ride];
  }

  @override
  void remove(PlannedRide ride) {
    state =
        state.where((r) => r.start != ride.start || r.end != ride.end).toList();
  }
}

Widget wrapInMaterial(
  Widget child, {
  List<HourlyForecast> forecasts = const [],
  List<HourlyScore> hours = const [],
}) {
  return ProviderScope(
    overrides: [
      weatherProvider.overrideWith(() => FakeWeatherNotifier(forecasts)),
      allHourlyScoresProvider.overrideWithValue(hours),
      plannedRidesProvider.overrideWith(() => FakePlannedRidesNotifier()),
    ],
    child: MaterialApp(
      home: child,
      locale: const Locale('nl'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      theme: ThemeData(extensions: const [RideWindowTheme.light]),
    ),
  );
}

RideSlot makeSlot({
  DateTime? start,
  DateTime? end,
  double score = 88,
  RideTier? tier,
  List<HourlyScore>? hours,
}) {
  final s = start ?? DateTime(2026, 6, 13, 9, 0); // Saturday
  final e = end ?? DateTime(2026, 6, 13, 13, 0);
  return RideSlot(
    start: s,
    end: e,
    overallScore: score,
    tier: tier ?? const Perfect(),
    hours: hours ??
        [
          HourlyScore(
            overall: 88,
            temperatureScore: 90,
            rainScore: 85,
            windScore: 88,
            time: s,
          ),
          HourlyScore(
            overall: 85,
            temperatureScore: 88,
            rainScore: 82,
            windScore: 85,
            time: s.add(const Duration(hours: 1)),
          ),
        ],
  );
}

List<HourlyForecast> makeForecasts(DateTime start, {int count = 2}) {
  return List.generate(
    count,
    (i) => HourlyForecast(
      temperatureC: 22.0 + i,
      apparentTemperatureC: 21.0 + i,
      precipitationMm: 0.0,
      precipitationProbability: 0.0,
      windspeedKmh: 12.0,
      winddirectionDeg: 90.0,
      time: start.add(Duration(hours: i)),
    ),
  );
}

void main() {
  group('RideDetailScreen', () {
    testWidgets('AppBar toont start- en eindtijd van het slot', (tester) async {
      final slot = makeSlot(
        start: DateTime(2026, 6, 13, 9, 0),
        end: DateTime(2026, 6, 13, 13, 0),
      );
      final forecasts = makeForecasts(slot.start);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      // AppBar should contain time range text
      expect(find.textContaining('09:00'), findsWidgets);
      expect(find.textContaining('13:00'), findsWidgets);
    });

    testWidgets('Score-banner toont tier-emoji voor Perfect slot',
        (tester) async {
      final slot = makeSlot(tier: const Perfect());
      final forecasts = makeForecasts(slot.start);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      // Perfect tier's ScoreBadge shows a satisfied-face Material icon
      // (production migrated from emoji text to Icons during the MD3
      // redesign — see lib/features/shared/score_badge.dart).
      expect(find.byIcon(Icons.sentiment_very_satisfied), findsWidgets);
    });

    testWidgets('Score-banner toont tier-emoji voor Poor slot', (tester) async {
      final slot = makeSlot(
        tier: const Poor(),
        score: 30,
        hours: [
          HourlyScore(
            overall: 30,
            temperatureScore: 30,
            rainScore: 30,
            windScore: 30,
            time: DateTime(2026, 6, 13, 9, 0),
          ),
        ],
      );
      final forecasts = makeForecasts(slot.start, count: 1);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      // Poor tier's ScoreBadge shows a dissatisfied-face Material icon
      // (production migrated from emoji text to Icons during the MD3
      // redesign — see lib/features/shared/score_badge.dart).
      expect(find.byIcon(Icons.sentiment_dissatisfied), findsWidgets);
    });

    testWidgets('Score-banner toont beschrijvingstekst voor Perfect',
        (tester) async {
      final slot = makeSlot(tier: const Perfect());
      final forecasts = makeForecasts(slot.start);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      expect(find.textContaining('Perfect'), findsWidgets);
    });

    testWidgets('Uurlijkse tabel toont tijd van elke HourlyRow',
        (tester) async {
      final start = DateTime(2026, 6, 13, 9, 0);
      final slot = makeSlot(start: start);
      final forecasts = makeForecasts(start, count: 2);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      // Both hours should appear in the hourly table
      expect(find.textContaining('09:00'), findsWidgets);
      expect(find.textContaining('10:00'), findsWidgets);
    });

    testWidgets('Uurlijkse tabel toont temperatuur per rij', (tester) async {
      final start = DateTime(2026, 6, 13, 9, 0);
      final slot = makeSlot(start: start);
      final forecasts = makeForecasts(start, count: 2);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      // Temperature values should be visible
      expect(find.textContaining('22°C'), findsWidgets);
    });

    testWidgets('"i"-knop is zichtbaar in score-banner', (tester) async {
      final slot = makeSlot();
      final forecasts = makeForecasts(slot.start);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      // "i" button should be findable
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('"i"-knop opent InsightsSheet via showModalBottomSheet',
        (tester) async {
      final slot = makeSlot();
      final forecasts = makeForecasts(slot.start);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      // Bottom sheet should have appeared — InsightsSheet stub or content
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('"Toevoegen aan agenda" knop toont SnackBar', (tester) async {
      final slot = makeSlot();
      final forecasts = makeForecasts(slot.start);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      // Scroll to bottom to find the button. Note: production string is
      // "Toevoegen aan Google Agenda" (capital A) — see
      // lib/l10n/app_localizations_nl.dart addToGoogleCalendar.
      await tester.scrollUntilVisible(
        find.textContaining('Agenda'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('Agenda'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('"Herinner me" knop toont SnackBar', (tester) async {
      final slot = makeSlot();
      final forecasts = makeForecasts(slot.start);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(
          slot: slot,
          forecasts: forecasts,
          notificationServiceFactory: () => FakeNotificationService(),
        ),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.textContaining('Herinner'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('Herinner'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Info-kaart "Weer" toont gemiddelde temperatuur',
        (tester) async {
      final start = DateTime(2026, 6, 13, 9, 0);
      final hours = [
        HourlyScore(
          overall: 88,
          temperatureScore: 90,
          rainScore: 85,
          windScore: 88,
          time: start,
        ),
        HourlyScore(
          overall: 85,
          temperatureScore: 88,
          rainScore: 82,
          windScore: 85,
          time: start.add(const Duration(hours: 1)),
        ),
      ];
      final slot = makeSlot(start: start, hours: hours);
      // 20°C and 22°C → avg 21°C
      final forecasts = [
        HourlyForecast(
          temperatureC: 20.0,
          apparentTemperatureC: 19.0,
          precipitationMm: 0.0,
          precipitationProbability: 0.0,
          windspeedKmh: 10.0,
          winddirectionDeg: 90.0,
          time: start,
        ),
        HourlyForecast(
          temperatureC: 22.0,
          apparentTemperatureC: 21.0,
          precipitationMm: 0.0,
          precipitationProbability: 0.0,
          windspeedKmh: 10.0,
          winddirectionDeg: 90.0,
          time: start.add(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      // Average 21°C should be shown (avg of 20 and 22)
      expect(find.textContaining('21°C'), findsWidgets);
    });

    testWidgets('Info-kaart "Weer" toont "Droog" bij nul neerslag',
        (tester) async {
      final start = DateTime(2026, 6, 13, 9, 0);
      final slot = makeSlot(start: start);
      final forecasts = [
        HourlyForecast(
          temperatureC: 22.0,
          apparentTemperatureC: 21.0,
          precipitationMm: 0.0,
          precipitationProbability: 0.0,
          windspeedKmh: 10.0,
          winddirectionDeg: 90.0,
          time: start,
        ),
        HourlyForecast(
          temperatureC: 22.0,
          apparentTemperatureC: 21.0,
          precipitationMm: 0.0,
          precipitationProbability: 0.0,
          windspeedKmh: 10.0,
          winddirectionDeg: 90.0,
          time: start.add(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      expect(find.textContaining('Droog'), findsOneWidget);
    });

    testWidgets('Leeg slot (geen hours) toont scherm zonder crash',
        (tester) async {
      final slot = makeSlot(hours: []);
      final forecasts = <HourlyForecast>[];

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      // Screen should render without crashing and show dash fallback
      expect(find.textContaining('—'), findsWidgets);
    });
  });
}
