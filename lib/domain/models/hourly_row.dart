// lib/domain/models/hourly_row.dart
// HourlyRow: pure Dart view-model that merges HourlyScore + HourlyForecast
// for a single hour in a RideSlot.
// No Freezed, no Flutter, no Riverpod — domain-pure.

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';

class HourlyRow {
  final DateTime time;
  final double? temperatureC;
  final double? apparentTemperatureC;
  final double? precipitationMm;
  final double? precipitationProbability;
  final double? windspeedKmh;
  final double? winddirectionDeg;
  final double overallScore;
  final double temperatureScore;
  final double rainScore;
  final double windScore;

  const HourlyRow({
    required this.time,
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.precipitationMm,
    required this.precipitationProbability,
    required this.windspeedKmh,
    required this.winddirectionDeg,
    required this.overallScore,
    required this.temperatureScore,
    required this.rainScore,
    required this.windScore,
  });
}

/// Merges [RideSlot.hours] (scores) with [forecasts] on equal [time].
///
/// For each [HourlyScore] in [slot.hours], the matching [HourlyForecast] is
/// looked up by [DateTime] equality. If no matching forecast is found, a
/// null-forecast is used so all forecast fields are null.
List<HourlyRow> buildHourlyRows(
  RideSlot slot,
  List<HourlyForecast> forecasts,
) {
  return slot.hours.map((score) {
    final fc = forecasts.firstWhere(
      (f) => f.time == score.time,
      orElse: () => HourlyForecast(
        temperatureC: null,
        apparentTemperatureC: null,
        precipitationMm: null,
        precipitationProbability: null,
        windspeedKmh: null,
        winddirectionDeg: null,
        time: score.time,
      ),
    );
    return HourlyRow(
      time: score.time,
      temperatureC: fc.temperatureC,
      apparentTemperatureC: fc.apparentTemperatureC,
      precipitationMm: fc.precipitationMm,
      precipitationProbability: fc.precipitationProbability,
      windspeedKmh: fc.windspeedKmh,
      winddirectionDeg: fc.winddirectionDeg,
      overallScore: score.overall,
      temperatureScore: score.temperatureScore,
      rainScore: score.rainScore,
      windScore: score.windScore,
    );
  }).toList();
}
