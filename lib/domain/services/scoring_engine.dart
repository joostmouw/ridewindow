import '../models/hourly_forecast.dart';
import '../models/hourly_score.dart';
import '../models/weather_tolerances.dart';

/// Pure-Dart scoring engine for cyclist weather windows.
/// Null weather inputs clamp to 50/100 ("uncertain") per SCOR-04.
/// Overall formula: overall = 0.6·min(t,r,w) + 0.4·mean(t,r,w) per D-14.
class ScoringEngine {
  HourlyScore score(HourlyForecast forecast, WeatherTolerances tolerances) {
    final t = _temperatureScore(
      forecast.temperatureC,
      forecast.apparentTemperatureC,
      tolerances.tempMinIdealC,
      tolerances.tempMaxIdealC,
    );
    final r = _rainScore(forecast.precipitationMm, tolerances.rainMaxIdealMm);
    final w = _windScore(forecast.windspeedKmh, tolerances.windMaxIdealKmh);

    final overall = (0.6 * _min3(t, r, w) + 0.4 * (t + r + w) / 3.0)
        .clamp(0.0, 100.0);

    return HourlyScore(
      overall: overall,
      temperatureScore: t,
      rainScore: r,
      windScore: w,
      time: forecast.time,
    );
  }

  double _temperatureScore(
    double? temperatureC,
    double? apparentTemperatureC,
    double minIdeal,
    double maxIdeal,
  ) {
    if (temperatureC == null) return 50.0;
    final tempScore = _linearScore(temperatureC, minIdeal, maxIdeal, 20.0);
    if (apparentTemperatureC == null) return tempScore;
    final apparentScore =
        _linearScore(apparentTemperatureC, minIdeal, maxIdeal, 20.0);
    return tempScore < apparentScore ? tempScore : apparentScore;
  }

  double _rainScore(double? precipitationMm, double rainMaxIdeal) {
    if (precipitationMm == null) return 50.0;
    if (precipitationMm <= rainMaxIdeal) return 100.0;
    final range = 5.0;
    final score =
        100.0 * (1.0 - (precipitationMm - rainMaxIdeal) / range);
    return score.clamp(0.0, 100.0);
  }

  double _windScore(double? windspeedKmh, double windMaxIdeal) {
    if (windspeedKmh == null) return 50.0;
    if (windspeedKmh <= windMaxIdeal) return 100.0;
    final range = 40.0;
    final score = 100.0 * (1.0 - (windspeedKmh - windMaxIdeal) / range);
    return score.clamp(0.0, 100.0);
  }

  /// Scores a value against a symmetric ideal range [minIdeal, maxIdeal].
  /// Returns 100 within the range; decreases linearly by [fadeRange] on each side.
  double _linearScore(
      double value, double minIdeal, double maxIdeal, double fadeRange,) {
    if (value >= minIdeal && value <= maxIdeal) return 100.0;
    if (value < minIdeal) {
      final score = 100.0 * (1.0 - (minIdeal - value) / fadeRange);
      return score.clamp(0.0, 100.0);
    }
    // value > maxIdeal
    final score = 100.0 * (1.0 - (value - maxIdeal) / fadeRange);
    return score.clamp(0.0, 100.0);
  }

  double _min3(double a, double b, double c) =>
      a < b ? (a < c ? a : c) : (b < c ? b : c);
}
