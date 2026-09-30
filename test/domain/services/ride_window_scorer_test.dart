import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/services/ride_window_scorer.dart';
import 'package:ridewindow/domain/services/scoring_engine.dart';
import 'package:ridewindow/domain/services/slot_generator.dart';

HourlyForecast forecast(DateTime time,
        {double temp = 20,
        double wind = 5,
        double rain = 0,
        double direction = 90}) =>
    HourlyForecast(
      time: time,
      temperatureC: temp,
      apparentTemperatureC: temp,
      precipitationMm: rain,
      precipitationProbability: rain > 0 ? 100 : 0,
      windspeedKmh: wind,
      winddirectionDeg: direction,
    );

void main() {
  final start = DateTime(2026, 10, 3, 18);
  final end = start.add(const Duration(hours: 3));
  const tolerances = WeatherTolerances();
  final forecasts = [
    forecast(start),
    forecast(start.add(const Duration(hours: 1)), temp: 5, direction: 270),
    forecast(start.add(const Duration(hours: 2)), temp: 4, rain: 2),
  ];

  test('gelijk aan de volledige suggestie-pipeline, inclusief daglicht', () {
    final engine = ScoringEngine();
    final generator = SlotGenerator();
    final hours = forecasts.map((f) => engine.score(f, tolerances)).toList();
    final expected = generator
        .applyDaylight(
          generator.refine(
              generator.generate(hours, allowedDurations: [3]), forecasts),
          latitude: 52.37,
          longitude: 4.90,
          darknessWeight: tolerances.darknessWeight,
        )
        .single;
    final actual = RideWindowScorer(
      forecasts: forecasts,
      tolerances: tolerances,
      latitude: 52.37,
      longitude: 4.90,
    ).score(start, end)!;
    expect(actual.overallScore, expected.overallScore);
    expect(actual.hours, hours);
    final average = hours.fold(0.0, (sum, h) => sum + h.overall) / hours.length;
    expect(actual.overallScore, lessThan(average));
  });

  test('een andere temperatuurvoorkeur verandert ook een bestaande rit', () {
    final mild = [forecast(start, temp: 10)];
    final before = RideWindowScorer(forecasts: mild, tolerances: tolerances);
    final after = RideWindowScorer(
      forecasts: mild,
      tolerances: tolerances.copyWith(tempMinIdealC: 5),
    );
    final oneHour = start.add(const Duration(hours: 1));
    expect(after.score(start, oneHour)!.overallScore,
        greaterThan(before.score(start, oneHour)!.overallScore));
  });

  test('slecht weer geeft een lage score, niet een verdwenen plan', () {
    final scorer = RideWindowScorer(
      forecasts: [forecast(start, temp: -15, wind: 100, rain: 10)],
      tolerances: tolerances,
    );
    final slot = scorer.score(start, start.add(const Duration(hours: 1)))!;
    expect(slot.overallScore, lessThan(50));
    expect(slot.tier, isA<Poor>());
  });

  test('ontbrekende eerste, middelste of laatste uur is geen actuele score',
      () {
    for (var i = 0; i < forecasts.length; i++) {
      final incomplete = [...forecasts]..removeAt(i);
      expect(
          RideWindowScorer(forecasts: incomplete, tolerances: tolerances)
              .score(start, end),
          isNull);
    }
  });

  test('volgorde en UTC-notatie veranderen de score niet', () {
    final scorer = RideWindowScorer(
      forecasts: forecasts.reversed.toList(),
      tolerances: tolerances,
    );
    expect(scorer.score(start.toUtc(), end.toUtc())!.overallScore,
        scorer.score(start, end)!.overallScore);
  });

  test('lege, omgekeerde en onvolledige tijdvakken leveren geen score', () {
    final scorer =
        RideWindowScorer(forecasts: forecasts, tolerances: tolerances);
    expect(scorer.score(start, start), isNull);
    expect(scorer.score(end, start), isNull);
    expect(scorer.score(start, end.add(const Duration(minutes: 30))), isNull);
  });
}
