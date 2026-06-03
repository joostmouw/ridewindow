// test/features/insights_sheet_test.dart
// Widget tests voor InsightsSheet volledige implementatie (Wave 3).
//
// TDD RED: Geschreven voor de implementatie. Tests definiëren verwacht gedrag:
//   - Drie LinearProgressIndicator balken (temp, regen, wind) zijn aanwezig
//   - Elke balk toont de gemiddelde sub-score van slot.hours
//   - Score-labels worden getoond per factor (bijv. "95 · Ideaal")
//   - Eén-regel uitleg per factor aanwezig
//   - Totale score rij onderaan zichtbaar
//   - "Begrijpen" knop sluit de sheet
//   - Lege hours-lijst vallt terug op score 50.0 (geen crash)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/features/detail/insights_sheet.dart';

Widget wrapInMaterial(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

RideSlot makeSlot({
  List<HourlyScore>? hours,
  double overallScore = 93,
  RideTier? tier,
}) {
  final start = DateTime(2026, 6, 13, 9, 0); // zaterdag
  final end = DateTime(2026, 6, 13, 13, 0);
  return RideSlot(
    start: start,
    end: end,
    overallScore: overallScore,
    tier: tier ?? const Perfect(),
    hours: hours ??
        [
          HourlyScore(
            overall: 93,
            temperatureScore: 95,
            rainScore: 90,
            windScore: 85,
            time: start,
          ),
          HourlyScore(
            overall: 91,
            temperatureScore: 93,
            rainScore: 88,
            windScore: 83,
            time: start.add(const Duration(hours: 1)),
          ),
        ],
  );
}

void main() {
  group('InsightsSheet', () {
    testWidgets('Drie LinearProgressIndicator balken zijn aanwezig', (tester) async {
      final slot = makeSlot();
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      // Drie factoren → drie LinearProgressIndicator widgets
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    });

    testWidgets('Sheet-titel toont tier-label en score', (tester) async {
      final slot = makeSlot(overallScore: 93, tier: const Perfect());
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      // Titel: "Waarom 'Perfect' — 93/100"
      expect(find.textContaining('Perfect'), findsWidgets);
      expect(find.textContaining('93'), findsWidgets);
    });

    testWidgets('Meta-tekst toont dag, tijden en duur', (tester) async {
      final slot = makeSlot();
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      // Meta: "zaterdag 09:00 – 13:00 · 4u"
      expect(find.textContaining('zaterdag'), findsWidgets);
      expect(find.textContaining('09:00'), findsWidgets);
      expect(find.textContaining('13:00'), findsWidgets);
      expect(find.textContaining('4u'), findsWidgets);
    });

    testWidgets('Factor-labels zijn zichtbaar (Temperatuur, Neerslag, Wind)', (tester) async {
      final slot = makeSlot();
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      expect(find.textContaining('Temperatuur'), findsWidgets);
      expect(find.textContaining('Neerslag'), findsWidgets);
      expect(find.textContaining('Wind'), findsWidgets);
    });

    testWidgets('Score-label "Ideaal" wordt getoond voor hoge temperatuurscore', (tester) async {
      // temperatureScore avg = 94 → ≥ 80 → "Ideaal"
      final slot = makeSlot(
        hours: [
          HourlyScore(
            overall: 93,
            temperatureScore: 94,
            rainScore: 90,
            windScore: 85,
            time: DateTime(2026, 6, 13, 9, 0),
          ),
        ],
      );
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      expect(find.textContaining('Ideaal'), findsWidgets);
    });

    testWidgets('Score-label "Droog" wordt getoond voor hoge neerslags core', (tester) async {
      // rainScore avg = 88 → ≥ 80 → "Droog"
      final slot = makeSlot(
        hours: [
          HourlyScore(
            overall: 88,
            temperatureScore: 85,
            rainScore: 88,
            windScore: 85,
            time: DateTime(2026, 6, 13, 9, 0),
          ),
        ],
      );
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      expect(find.textContaining('Droog'), findsWidgets);
    });

    testWidgets('Score-label "Rustig" wordt getoond voor hoge windscore', (tester) async {
      // windScore avg = 82 → ≥ 80 → "Rustig"
      final slot = makeSlot(
        hours: [
          HourlyScore(
            overall: 82,
            temperatureScore: 80,
            rainScore: 80,
            windScore: 82,
            time: DateTime(2026, 6, 13, 9, 0),
          ),
        ],
      );
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      expect(find.textContaining('Rustig'), findsWidgets);
    });

    testWidgets('Totale score rij is zichtbaar onderaan', (tester) async {
      final slot = makeSlot(overallScore: 93);
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      // Totaal-rij: "Overall score" aan de linkerkant
      expect(find.textContaining('Overall score'), findsOneWidget);
    });

    testWidgets('"Begrijpen" knop is zichtbaar', (tester) async {
      final slot = makeSlot();
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      expect(find.textContaining('Begrijpen'), findsOneWidget);
    });

    testWidgets('Lege hours-lijst veroorzaakt geen crash (fallback score 50)', (tester) async {
      final slot = makeSlot(hours: [], overallScore: 50);
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      // Should render three progress bars even with empty hours
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    });

    testWidgets('Acceptabel score-label bij gemiddelde temp in 60-79 bereik', (tester) async {
      // temperatureScore avg = 70 → ≥ 60 < 80 → "Acceptabel"
      final slot = makeSlot(
        hours: [
          HourlyScore(
            overall: 70,
            temperatureScore: 70,
            rainScore: 75,
            windScore: 72,
            time: DateTime(2026, 6, 13, 9, 0),
          ),
        ],
      );
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      expect(find.textContaining('Acceptabel'), findsWidgets);
    });

    testWidgets('Uitleg-tekst "Lichte wind" wordt getoond bij matige windscore', (tester) async {
      // windScore avg = 82 → ≥ 80 → "Lichte wind — nauwelijks merkbaar"
      final slot = makeSlot(
        hours: [
          HourlyScore(
            overall: 82,
            temperatureScore: 82,
            rainScore: 82,
            windScore: 82,
            time: DateTime(2026, 6, 13, 9, 0),
          ),
        ],
      );
      await tester.pumpWidget(wrapInMaterial(InsightsSheet(slot: slot)));
      await tester.pump();

      expect(find.textContaining('Lichte wind'), findsWidgets);
    });
  });
}
