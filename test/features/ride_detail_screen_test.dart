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
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/features/detail/ride_detail_screen.dart';

Widget wrapInMaterial(Widget child) {
  return MaterialApp(
    home: child,
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
      ));
      await tester.pump();

      // AppBar should contain time range text
      expect(find.textContaining('09:00'), findsWidgets);
      expect(find.textContaining('13:00'), findsWidgets);
    });

    testWidgets('Score-banner toont tier-emoji voor Perfect slot', (tester) async {
      final slot = makeSlot(tier: const Perfect());
      final forecasts = makeForecasts(slot.start);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
      ));
      await tester.pump();

      // Perfect tier uses 🟢 emoji
      expect(find.textContaining('🟢'), findsWidgets);
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
      ));
      await tester.pump();

      // Poor tier uses ⚪ emoji
      expect(find.textContaining('⚪'), findsWidgets);
    });

    testWidgets('Score-banner toont beschrijvingstekst voor Perfect', (tester) async {
      final slot = makeSlot(tier: const Perfect());
      final forecasts = makeForecasts(slot.start);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
      ));
      await tester.pump();

      expect(find.textContaining('Perfect'), findsWidgets);
    });

    testWidgets('Uurlijkse tabel toont tijd van elke HourlyRow', (tester) async {
      final start = DateTime(2026, 6, 13, 9, 0);
      final slot = makeSlot(start: start);
      final forecasts = makeForecasts(start, count: 2);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
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
      ));
      await tester.pump();

      // "i" button should be findable
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('"i"-knop opent InsightsSheet via showModalBottomSheet', (tester) async {
      final slot = makeSlot();
      final forecasts = makeForecasts(slot.start);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
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
      ));
      await tester.pump();

      // Scroll to bottom to find the button
      await tester.scrollUntilVisible(
        find.textContaining('agenda'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('agenda'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('"Herinner me" knop toont SnackBar', (tester) async {
      final slot = makeSlot();
      final forecasts = makeForecasts(slot.start);

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
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

    testWidgets('Info-kaart "Weer" toont gemiddelde temperatuur', (tester) async {
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
      ));
      await tester.pump();

      // Average 21°C should be shown (avg of 20 and 22)
      expect(find.textContaining('21°C'), findsWidgets);
    });

    testWidgets('Info-kaart "Weer" toont "Droog" bij nul neerslag', (tester) async {
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
      ));
      await tester.pump();

      expect(find.textContaining('Droog'), findsOneWidget);
    });

    testWidgets('Leeg slot (geen hours) toont scherm zonder crash', (tester) async {
      final slot = makeSlot(hours: []);
      final forecasts = <HourlyForecast>[];

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(slot: slot, forecasts: forecasts),
      ));
      await tester.pump();

      // Screen should render without crashing and show dash fallback
      expect(find.textContaining('—'), findsWidgets);
    });
  });
}
