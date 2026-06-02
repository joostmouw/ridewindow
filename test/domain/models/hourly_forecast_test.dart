import 'package:test/test.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';

void main() {
  final base = DateTime(2025, 7, 1, 9);

  group('HourlyForecast', () {
    test('equality: identical fields are equal', () {
      final a = HourlyForecast(
        temperatureC: 20.0,
        apparentTemperatureC: 19.0,
        precipitationMm: 0.0,
        precipitationProbability: 5.0,
        windspeedKmh: 10.0,
        winddirectionDeg: 180.0,
        time: base,
      );
      final b = HourlyForecast(
        temperatureC: 20.0,
        apparentTemperatureC: 19.0,
        precipitationMm: 0.0,
        precipitationProbability: 5.0,
        windspeedKmh: 10.0,
        winddirectionDeg: 180.0,
        time: base,
      );
      expect(a, equals(b));
    });

    test('copyWith: only changed field differs', () {
      final original = HourlyForecast(
        temperatureC: 20.0,
        apparentTemperatureC: 19.0,
        precipitationMm: 0.0,
        precipitationProbability: 5.0,
        windspeedKmh: 10.0,
        winddirectionDeg: 180.0,
        time: base,
      );
      final copy = original.copyWith(precipitationMm: 1.0);
      expect(copy.precipitationMm, 1.0);
      expect(copy.temperatureC, original.temperatureC);
      expect(copy.time, original.time);
    });

    test('JSON round-trip: all fields non-null', () {
      final original = HourlyForecast(
        temperatureC: 18.5,
        apparentTemperatureC: 17.0,
        precipitationMm: 0.2,
        precipitationProbability: 10.0,
        windspeedKmh: 12.0,
        winddirectionDeg: 90.0,
        time: base,
      );
      final json = original.toJson();
      final restored = HourlyForecast.fromJson(json);
      expect(restored, equals(original));
    });

    test('JSON round-trip: all nullable fields null', () {
      final original = HourlyForecast(
        temperatureC: null,
        apparentTemperatureC: null,
        precipitationMm: null,
        precipitationProbability: null,
        windspeedKmh: null,
        winddirectionDeg: null,
        time: base,
      );
      final json = original.toJson();
      final restored = HourlyForecast.fromJson(json);
      expect(restored, equals(original));
    });
  });
}
