import 'package:test/test.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';

void main() {
  group('WeatherTolerances', () {
    test('defaults: correct values from plan spec', () {
      const t = WeatherTolerances();
      expect(t.tempMinIdealC, 12.0);
      expect(t.tempMaxIdealC, 26.0);
      expect(t.windMaxIdealKmh, 15.0);
      expect(t.rainMaxIdealMm, 0.5);
    });

    test('equality: two default instances are equal', () {
      expect(const WeatherTolerances(), equals(const WeatherTolerances()));
    });

    test('JSON round-trip: default values survive serialization', () {
      const original = WeatherTolerances();
      final json = original.toJson();
      final restored = WeatherTolerances.fromJson(json);
      expect(restored, equals(original));
    });

    test('JSON round-trip: custom values survive serialization', () {
      const original = WeatherTolerances(
        tempMinIdealC: 10.0,
        tempMaxIdealC: 28.0,
        windMaxIdealKmh: 20.0,
        rainMaxIdealMm: 1.0,
      );
      final json = original.toJson();
      final restored = WeatherTolerances.fromJson(json);
      expect(restored, equals(original));
    });
  });
}
