import 'dart:math';

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
    final r = _rainScore(
      forecast.precipitationMm,
      forecast.precipitationProbability,
      tolerances.rainMaxIdealMm,
    );
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

  /// Rain score combines actual precipitation amount with precipitation
  /// probability. When probability data is unavailable, only amount is used.
  double _rainScore(
    double? precipitationMm,
    double? precipitationProbability,
    double rainMaxIdeal,
  ) {
    final amountScore = _precipAmountScore(precipitationMm, rainMaxIdeal);
    if (precipitationProbability == null) return amountScore;
    final probScore = _precipProbabilityScore(precipitationProbability);
    return amountScore < probScore ? amountScore : probScore;
  }

  /// Concave power curve (p=0.7): getting wet at all is the big penalty,
  /// then diminishing returns — once soaked, more rain barely matters.
  double _precipAmountScore(double? mm, double rainMaxIdeal) {
    if (mm == null) return 50.0;
    if (mm <= rainMaxIdeal) return 100.0;
    final excess = mm - rainMaxIdeal;
    const range = 5.0;
    final ratio = (excess / range).clamp(0.0, 1.0);
    return (100.0 * (1.0 - pow(ratio, 0.7))).clamp(0.0, 100.0);
  }

  /// Probability score: 0% → 100, 50% → 60, 100% → 20.
  /// Even 100% probability scores 20 (not 0) because probability alone
  /// without confirmed heavy rain is less severe than actual downpour.
  double _precipProbabilityScore(double probability) {
    return (100.0 - probability * 0.8).clamp(0.0, 100.0);
  }

  /// Convex power curve (p=1.5): a bit of extra wind is tolerable,
  /// but it gets exponentially worse at high speeds (safety concern).
  double _windScore(double? windspeedKmh, double windMaxIdeal) {
    if (windspeedKmh == null) return 50.0;
    if (windspeedKmh <= windMaxIdeal) return 100.0;
    final excess = windspeedKmh - windMaxIdeal;
    const range = 40.0;
    final ratio = (excess / range).clamp(0.0, 1.0);
    return (100.0 * (1.0 - pow(ratio, 1.5))).clamp(0.0, 100.0);
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
