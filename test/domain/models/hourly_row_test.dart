// test/domain/models/hourly_row_test.dart
// Unit tests for HourlyRow class and buildHourlyRows helper function.

import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_row.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';

void main() {
  group('buildHourlyRows', () {
    final baseTime = DateTime(2026, 6, 10, 9, 0);

    RideSlot makeSlot(List<HourlyScore> hours) => RideSlot(
          start: baseTime,
          end: baseTime.add(const Duration(hours: 3)),
          overallScore: 80,
          tier: const Perfect(),
          hours: hours,
        );

    test('returns empty list when slot has no hours', () {
      final slot = makeSlot([]);
      final result = buildHourlyRows(slot, []);
      expect(result, isEmpty);
    });

    test('fills forecast fields correctly when times match', () {
      final t1 = baseTime;
      final score = HourlyScore(
        overall: 85,
        temperatureScore: 90,
        rainScore: 80,
        windScore: 88,
        time: t1,
      );
      final forecast = HourlyForecast(
        temperatureC: 22.5,
        apparentTemperatureC: 21.0,
        precipitationMm: 0.1,
        precipitationProbability: 5.0,
        windspeedKmh: 12.0,
        winddirectionDeg: 180.0,
        time: t1,
      );

      final slot = makeSlot([score]);
      final result = buildHourlyRows(slot, [forecast]);

      expect(result, hasLength(1));
      final row = result.first;
      expect(row.time, t1);
      expect(row.temperatureC, 22.5);
      expect(row.apparentTemperatureC, 21.0);
      expect(row.precipitationMm, 0.1);
      expect(row.windspeedKmh, 12.0);
      expect(row.overallScore, 85);
      expect(row.temperatureScore, 90);
      expect(row.rainScore, 80);
      expect(row.windScore, 88);
    });

    test('uses null fields when forecast hour is missing', () {
      final t1 = baseTime;
      final t2 = baseTime.add(const Duration(hours: 1));
      final scores = [
        HourlyScore(
          overall: 85,
          temperatureScore: 90,
          rainScore: 80,
          windScore: 88,
          time: t1,
        ),
        HourlyScore(
          overall: 70,
          temperatureScore: 75,
          rainScore: 65,
          windScore: 72,
          time: t2,
        ),
      ];
      // Only provide forecast for t1, not t2
      final forecasts = [
        HourlyForecast(
          temperatureC: 22.5,
          apparentTemperatureC: 21.0,
          precipitationMm: 0.1,
          precipitationProbability: 5.0,
          windspeedKmh: 12.0,
          winddirectionDeg: 180.0,
          time: t1,
        ),
      ];

      final slot = makeSlot(scores);
      final result = buildHourlyRows(slot, forecasts);

      expect(result, hasLength(2));

      // t1: all forecast fields filled
      expect(result[0].temperatureC, 22.5);
      expect(result[0].windspeedKmh, 12.0);

      // t2: forecast missing → null fields
      expect(result[1].time, t2);
      expect(result[1].temperatureC, isNull);
      expect(result[1].apparentTemperatureC, isNull);
      expect(result[1].precipitationMm, isNull);
      expect(result[1].windspeedKmh, isNull);
      // Score fields still present from the score
      expect(result[1].overallScore, 70);
      expect(result[1].temperatureScore, 75);
    });

    test('handles multiple scores with multiple matching forecasts', () {
      final times = List.generate(3, (i) => baseTime.add(Duration(hours: i)));
      final scores = times
          .map(
            (t) => HourlyScore(
              overall: 80,
              temperatureScore: 85,
              rainScore: 78,
              windScore: 82,
              time: t,
            ),
          )
          .toList();
      final forecasts = times
          .map(
            (t) => HourlyForecast(
              temperatureC: 20.0,
              apparentTemperatureC: 19.0,
              precipitationMm: 0.0,
              precipitationProbability: 0.0,
              windspeedKmh: 10.0,
              winddirectionDeg: 90.0,
              time: t,
            ),
          )
          .toList();

      final slot = makeSlot(scores);
      final result = buildHourlyRows(slot, forecasts);

      expect(result, hasLength(3));
      for (final row in result) {
        expect(row.temperatureC, 20.0);
        expect(row.precipitationMm, 0.0);
        expect(row.windspeedKmh, 10.0);
        expect(row.overallScore, 80);
      }
    });
  });
}
