import 'package:test/test.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/services/slot_generator.dart';

List<HourlyScore> _buildScores(int count, {double overall = 90.0}) {
  final base = DateTime(2025, 7, 5, 8); // Saturday 08:00
  return List.generate(
    count,
    (i) => HourlyScore(
      overall: overall,
      temperatureScore: overall,
      rainScore: overall,
      windScore: overall,
      time: base.add(Duration(hours: i)),
    ),
  );
}

void main() {
  final generator = SlotGenerator();
  final base = DateTime(2025, 7, 5, 8);

  group('[start, end) boundary convention — SLOT-02', () {
    test('2h slot from 4-score fixture: start=08:00, end=10:00', () {
      final scores = _buildScores(4);
      final slots = generator.generate(scores, allowedDurations: [2]);
      final first = slots.first;
      expect(first.start, base);
      expect(first.end, DateTime(2025, 7, 5, 10));
      // end is exclusive: end - start == 2h
      expect(first.end.difference(first.start), const Duration(hours: 2));
      // 10:00 is NOT in the hours list
      expect(first.hours.any((h) => h.time == first.end), isFalse);
    });

    test('3h slot from 3-score fixture: start=08:00, end=11:00', () {
      final scores = _buildScores(3);
      final slots = generator.generate(scores, allowedDurations: [3]);
      expect(slots.length, 1);
      expect(slots.first.start, base);
      expect(slots.first.end, DateTime(2025, 7, 5, 11));
      expect(slots.first.end.difference(slots.first.start),
          const Duration(hours: 3),);
    });
  });

  group('slot count from fixture — SLOT-01', () {
    test('4-score, [2] → 3 slots (windows at 08, 09, 10)', () {
      final slots = generator.generate(_buildScores(4), allowedDurations: [2]);
      expect(slots.length, 3);
    });

    test('5-score, [3] → 3 slots (windows at 08, 09, 10)', () {
      final slots = generator.generate(_buildScores(5), allowedDurations: [3]);
      expect(slots.length, 3);
    });

    test('5-score, [4, 5] → 2 + 1 = 3 slots', () {
      // n=5, d=4: max(0, 5-4+1)=2 windows; d=5: max(0, 5-5+1)=1 window
      final slots =
          generator.generate(_buildScores(5), allowedDurations: [4, 5]);
      expect(slots.length, 3);
    });

    test('1-score, [2] → 0 slots (too short)', () {
      final slots = generator.generate(_buildScores(1), allowedDurations: [2]);
      expect(slots.length, 0);
    });

    test('empty list, [2, 3] → 0 slots', () {
      final slots = generator.generate([], allowedDurations: [2, 3]);
      expect(slots.length, 0);
    });
  });

  group('score averaging', () {
    test('2-score: first=80, second=60 → overallScore==70', () {
      final scores = [
        HourlyScore(
          overall: 80.0,
          temperatureScore: 80.0,
          rainScore: 80.0,
          windScore: 80.0,
          time: base,
        ),
        HourlyScore(
          overall: 60.0,
          temperatureScore: 60.0,
          rainScore: 60.0,
          windScore: 60.0,
          time: base.add(const Duration(hours: 1)),
        ),
      ];
      final slots = generator.generate(scores, allowedDurations: [2]);
      expect(slots.length, 1);
      expect(slots.first.overallScore, closeTo(70.0, 0.01));
    });
  });

  group('tier assignment — SLOT-04', () {
    test('overall=90.0 → Perfect', () {
      final slots = generator.generate(
        _buildScores(2, overall: 90.0),
        allowedDurations: [2],
      );
      expect(slots.first.tier, isA<Perfect>());
    });

    test('overall=75.0 → Great', () {
      final slots = generator.generate(
        _buildScores(2, overall: 75.0),
        allowedDurations: [2],
      );
      expect(slots.first.tier, isA<Great>());
    });

    test('overall=55.0 → Acceptable', () {
      final slots = generator.generate(
        _buildScores(2, overall: 55.0),
        allowedDurations: [2],
      );
      expect(slots.first.tier, isA<Acceptable>());
    });

    test('overall=40.0 → Poor', () {
      final slots = generator.generate(
        _buildScores(2, overall: 40.0),
        allowedDurations: [2],
      );
      expect(slots.first.tier, isA<Poor>());
    });
  });

  group('4–5h slots — SLOT-01', () {
    test('6-score at 85.0, [4,5]: 3 four-hour + 2 five-hour = 5 total', () {
      final slots = generator.generate(
        _buildScores(6, overall: 85.0),
        allowedDurations: [4, 5],
      );
      expect(slots.length, 5);
    });
  });

  group('night filter', () {
    test('hours at 04:00–07:00 with minHour=6 → only 06:00, 07:00 kept', () {
      final nightBase = DateTime(2025, 7, 5, 4); // 04:00
      final scores = List.generate(
        4,
        (i) => HourlyScore(
          overall: 90.0,
          temperatureScore: 90.0,
          rainScore: 90.0,
          windScore: 90.0,
          time: nightBase.add(Duration(hours: i)), // 04, 05, 06, 07
        ),
      );
      final slots = generator.generate(
        scores,
        allowedDurations: [2],
        minHour: 6,
        maxHour: 22,
      );
      // Only the 06–08 window qualifies
      expect(slots.length, 1);
      expect(slots.first.start.hour, 6);
    });

    test('hours at 20:00–23:00 with maxHour=22 → only 20–22 window', () {
      final eveningBase = DateTime(2025, 7, 5, 20);
      final scores = List.generate(
        4,
        (i) => HourlyScore(
          overall: 90.0,
          temperatureScore: 90.0,
          rainScore: 90.0,
          windScore: 90.0,
          time: eveningBase.add(Duration(hours: i)), // 20, 21, 22, 23
        ),
      );
      final slots = generator.generate(
        scores,
        allowedDurations: [2],
        minHour: 6,
        maxHour: 22,
      );
      expect(slots.length, 1);
      expect(slots.first.start.hour, 20);
    });

    test('default minHour=0, maxHour=24 → no filtering', () {
      final nightBase = DateTime(2025, 7, 5, 2); // 02:00
      final scores = List.generate(
        3,
        (i) => HourlyScore(
          overall: 90.0,
          temperatureScore: 90.0,
          rainScore: 90.0,
          windScore: 90.0,
          time: nightBase.add(Duration(hours: i)),
        ),
      );
      final slots = generator.generate(scores, allowedDurations: [2]);
      expect(slots.length, 2); // 02–04 and 03–05
    });
  });

  group('contiguity check', () {
    test('non-contiguous hours → no slots generated', () {
      final scores = [
        HourlyScore(
          overall: 90.0,
          temperatureScore: 90.0,
          rainScore: 90.0,
          windScore: 90.0,
          time: DateTime(2025, 7, 5, 9),
        ),
        HourlyScore(
          overall: 90.0,
          temperatureScore: 90.0,
          rainScore: 90.0,
          windScore: 90.0,
          time: DateTime(2025, 7, 5, 11), // 2h gap
        ),
      ];
      final slots = generator.generate(scores, allowedDurations: [2]);
      expect(slots.length, 0);
    });
  });

  group('dedup', () {
    test('3h slots shifted by 1h: 09–12 and 10–13 deduped (67% overlap)', () {
      final scores = _buildScores(5); // 08–12, all 90.0
      final slots = generator.generate(scores, allowedDurations: [3]);
      expect(slots.length, 3); // 08–11, 09–12, 10–13
      final deduped = generator.dedup(slots);
      // 09–12 overlaps 67% with 08–11 → removed; 10–13 overlaps 67% with 08–11 → removed
      // Only 08–11 survives (or best by score — all same score so first picked wins)
      expect(deduped.length, lessThan(slots.length));
    });

    test('non-overlapping slots all kept', () {
      final morning = HourlyScore(
        overall: 90.0,
        temperatureScore: 90.0,
        rainScore: 90.0,
        windScore: 90.0,
        time: DateTime(2025, 7, 5, 8),
      );
      final afternoon = HourlyScore(
        overall: 85.0,
        temperatureScore: 85.0,
        rainScore: 85.0,
        windScore: 85.0,
        time: DateTime(2025, 7, 5, 14),
      );
      final slots = [
        RideSlot(
          start: DateTime(2025, 7, 5, 8),
          end: DateTime(2025, 7, 5, 10),
          overallScore: 90.0,
          tier: const Perfect(),
          hours: [morning, morning],
        ),
        RideSlot(
          start: DateTime(2025, 7, 5, 14),
          end: DateTime(2025, 7, 5, 16),
          overallScore: 85.0,
          tier: const Perfect(),
          hours: [afternoon, afternoon],
        ),
      ];
      final deduped = generator.dedup(slots);
      expect(deduped.length, 2);
    });
  });

  group('refine — trend penalty', () {
    test('declining slot gets penalty, stable slot does not', () {
      final declining = [
        HourlyScore(
          overall: 90.0,
          temperatureScore: 90.0,
          rainScore: 90.0,
          windScore: 90.0,
          time: base,
        ),
        HourlyScore(
          overall: 50.0,
          temperatureScore: 50.0,
          rainScore: 50.0,
          windScore: 50.0,
          time: base.add(const Duration(hours: 1)),
        ),
      ];
      final stable = _buildScores(2, overall: 70.0);

      final rawSlots = [
        RideSlot(
          start: declining.first.time,
          end: declining.last.time.add(const Duration(hours: 1)),
          overallScore: 70.0,
          tier: const Great(),
          hours: declining,
        ),
        RideSlot(
          start: stable.first.time,
          end: stable.last.time.add(const Duration(hours: 1)),
          overallScore: 70.0,
          tier: const Great(),
          hours: stable,
        ),
      ];

      final forecasts = List.generate(
        2,
        (i) => HourlyForecast(
          temperatureC: 20,
          apparentTemperatureC: 20,
          precipitationMm: 0,
          precipitationProbability: 0,
          windspeedKmh: 10,
          winddirectionDeg: 180, // consistent direction → no wind penalty
          time: base.add(Duration(hours: i)),
        ),
      );

      final refined = generator.refine(rawSlots, forecasts);
      // Declining slot should score lower than stable slot
      expect(refined[0].overallScore, lessThan(refined[1].overallScore));
    });
  });
}
