import 'package:test/test.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/services/scoring_engine.dart';

HourlyForecast _forecast({
  double? temp,
  double? apparent,
  double? rain,
  double? windspeed,
  double? prob,
  double? dir,
}) =>
    HourlyForecast(
      temperatureC: temp,
      apparentTemperatureC: apparent,
      precipitationMm: rain,
      precipitationProbability: prob,
      windspeedKmh: windspeed,
      winddirectionDeg: dir,
      time: DateTime(2025, 7, 1, 9),
    );

void main() {
  const tolerances = WeatherTolerances(); // defaults: 12/26°C, 15km/h, 0.5mm
  final engine = ScoringEngine();

  group('ideal conditions', () {
    test('all ideal → all sub-scores 100, overall 100', () {
      final result = engine.score(
        _forecast(temp: 19, apparent: 19, rain: 0.0, windspeed: 5.0),
        tolerances,
      );
      expect(result.temperatureScore, 100.0);
      expect(result.rainScore, 100.0);
      expect(result.windScore, 100.0);
      expect(result.overall, closeTo(100.0, 0.01));
    });
  });

  group('temperature scoring', () {
    test('cold edge: temp=-10 → temperatureScore == 0.0', () {
      // -10 is 22 below min=12, fade=20 → score = 1-(22/20) = -0.1 → clamped 0
      final result = engine.score(
        _forecast(temp: -10, rain: 0.0, windspeed: 5.0),
        tolerances,
      );
      expect(result.temperatureScore, 0.0);
    });

    test('hot edge: temp=50 → temperatureScore == 0.0', () {
      // 50 is 24 above max=26, fade=20 → score = 1-(24/20) = -0.2 → clamped 0
      final result = engine.score(
        _forecast(temp: 50, rain: 0.0, windspeed: 5.0),
        tolerances,
      );
      expect(result.temperatureScore, 0.0);
    });

    test('boundary at min: temp=12.0 → temperatureScore == 100.0', () {
      final result = engine.score(
        _forecast(temp: 12.0, rain: 0.0, windspeed: 5.0),
        tolerances,
      );
      expect(result.temperatureScore, 100.0);
    });

    test('boundary at max: temp=26.0 → temperatureScore == 100.0', () {
      final result = engine.score(
        _forecast(temp: 26.0, rain: 0.0, windspeed: 5.0),
        tolerances,
      );
      expect(result.temperatureScore, 100.0);
    });

    test('just below min: temp=2.0 → temperatureScore == 50.0', () {
      // 2 is 10 below min=12, fade=20 → score = 1-(10/20) = 0.5 → 50
      final result = engine.score(
        _forecast(temp: 2.0, rain: 0.0, windspeed: 5.0),
        tolerances,
      );
      expect(result.temperatureScore, closeTo(50.0, 0.01));
    });

    test('apparent temperature drags score down', () {
      // temp=20 (in ideal range → 100), apparent=0 (12 below min → 40)
      // min(100, 40) = 40
      final result = engine.score(
        _forecast(temp: 20, apparent: 0, rain: 0.0, windspeed: 5.0),
        tolerances,
      );
      expect(result.temperatureScore, lessThan(100.0));
    });

    test('null apparent temperature: only temperatureC used', () {
      final result = engine.score(
        _forecast(temp: 20, apparent: null, rain: 0.0, windspeed: 5.0),
        tolerances,
      );
      expect(result.temperatureScore, 100.0);
    });
  });

  group('rain scoring', () {
    test('light rain boundary: rain=0.5 → rainScore == 100.0', () {
      final result = engine.score(
        _forecast(temp: 19, rain: 0.5, windspeed: 5.0),
        tolerances,
      );
      expect(result.rainScore, 100.0);
    });

    test('just above light: rain=0.6 → rainScore < 100.0', () {
      final result = engine.score(
        _forecast(temp: 19, rain: 0.6, windspeed: 5.0),
        tolerances,
      );
      expect(result.rainScore, lessThan(100.0));
    });

    test('heavy rain: rain=5.5 (0.5+5.0) → rainScore == 0.0', () {
      final result = engine.score(
        _forecast(temp: 19, rain: 5.5, windspeed: 5.0),
        tolerances,
      );
      expect(result.rainScore, 0.0);
    });
  });

  group('wind scoring', () {
    test('calm: wind=0.0 → windScore == 100.0', () {
      final result = engine.score(
        _forecast(temp: 19, rain: 0.0, windspeed: 0.0),
        tolerances,
      );
      expect(result.windScore, 100.0);
    });

    test('at boundary: wind=15.0 → windScore == 100.0', () {
      final result = engine.score(
        _forecast(temp: 19, rain: 0.0, windspeed: 15.0),
        tolerances,
      );
      expect(result.windScore, 100.0);
    });

    test('strong wind: wind=55.0 (15+40) → windScore == 0.0', () {
      final result = engine.score(
        _forecast(temp: 19, rain: 0.0, windspeed: 55.0),
        tolerances,
      );
      expect(result.windScore, 0.0);
    });

    test('mid wind: wind=35.0 (15+20, halfway) → windScore == 50.0', () {
      final result = engine.score(
        _forecast(temp: 19, rain: 0.0, windspeed: 35.0),
        tolerances,
      );
      expect(result.windScore, closeTo(50.0, 0.01));
    });
  });

  group('null inputs — SCOR-04', () {
    test('all nulls → all sub-scores == 50.0', () {
      final result = engine.score(
        _forecast(temp: null, rain: null, windspeed: null),
        tolerances,
      );
      expect(result.temperatureScore, 50.0);
      expect(result.rainScore, 50.0);
      expect(result.windScore, 50.0);
    });

    test('all nulls → overall == 50.0', () {
      final result = engine.score(
        _forecast(temp: null, rain: null, windspeed: null),
        tolerances,
      );
      // 0.6*min(50,50,50) + 0.4*mean(50,50,50) = 0.6*50 + 0.4*50 = 50
      expect(result.overall, closeTo(50.0, 0.01));
    });

    test('mixed nulls: temp=19 (100), rain=null (50), wind=null (50)', () {
      final result = engine.score(
        _forecast(temp: 19, rain: null, windspeed: null),
        tolerances,
      );
      expect(result.temperatureScore, 100.0);
      expect(result.rainScore, 50.0);
      expect(result.windScore, 50.0);
      // overall = 0.6*min(100,50,50) + 0.4*(100+50+50)/3
      //         = 0.6*50 + 0.4*(200/3) = 30 + 26.67 ≈ 56.67
      expect(result.overall, closeTo(56.67, 0.1));
    });
  });

  group('D-14 aggregation formula verification', () {
    test('formula: 0.6*min + 0.4*mean verified with known sub-scores', () {
      // Construct inputs that yield t≈80, r≈60, w≈70 sub-scores:
      // temp=20 (ideal) → t=100; wind=35 (15+20) → w=50; rain=3.5 (0.5+3) → r=40
      // Easier: use all-null clamp inputs to verify formula numerically.
      // Direct formula test with t=100, r=100, w=100: overall=100 (verified above).
      // Use known: temp=2 (→50), rain=5.5 (→0), wind=55 (→0)
      // overall = 0.6*min(50,0,0) + 0.4*(50+0+0)/3 = 0 + 0.4*16.67 ≈ 6.67
      final result = engine.score(
        _forecast(temp: 2.0, rain: 5.5, windspeed: 55.0),
        tolerances,
      );
      expect(result.temperatureScore, closeTo(50.0, 0.01));
      expect(result.rainScore, 0.0);
      expect(result.windScore, 0.0);
      // 0.6*0 + 0.4*(50+0+0)/3 ≈ 6.67
      expect(result.overall, closeTo(6.67, 0.1));
    });
  });
}
