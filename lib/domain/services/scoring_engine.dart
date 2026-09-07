import 'dart:math';

import '../models/hourly_forecast.dart';
import '../models/hourly_score.dart';
import '../models/weather_tolerances.dart';

/// De losse scorecurves, publiek zodat de **uitleg** in de UI ze kan aanroepen
/// in plaats van na te bouwen.
///
/// Deze klasse bestaat sinds de infovensters niet alleen vertellen wát een
/// meting is maar ook waaróm hij deze score kreeg (Joost, 2026-09-07). Die
/// tekst noemt concrete voorbeelden — "bij 32° zou dit 70 zijn" — en die
/// moeten uit dezelfde formule komen als de score zelf. Een tweede kopie van
/// deze curves in de presentatielaag zou stilzwijgend gaan afwijken zodra
/// iemand hier een grens verschuift, en dan liegt de app over zijn eigen
/// kernwaarde.
///
/// [ScoringEngine] hieronder roept precies deze functies aan; er is geen
/// tweede implementatie.
abstract final class MetricScores {
  /// Hoeveel graden buiten je ideale bereik het duurt voor de
  /// temperatuurscore van 100 naar 0 zakt. Lineair, dus 5 punten per graad.
  static const tempFadeRangeC = 20.0;

  /// Over hoeveel mm bóven je grens de regenscore van 100 naar 0 zakt.
  static const rainFadeRangeMm = 5.0;

  /// Over hoeveel km/u bóven je grens de windscore van 100 naar 0 zakt.
  static const windFadeRangeKmh = 40.0;

  /// Scoort een waarde tegen een symmetrisch ideaalbereik. 100 binnen het
  /// bereik, daarbuiten lineair aflopend over [fadeRange] aan elke kant.
  static double linear(
    double value,
    double minIdeal,
    double maxIdeal,
    double fadeRange,
  ) {
    if (value >= minIdeal && value <= maxIdeal) return 100.0;
    if (value < minIdeal) {
      return (100.0 * (1.0 - (minIdeal - value) / fadeRange)).clamp(0.0, 100.0);
    }
    return (100.0 * (1.0 - (value - maxIdeal) / fadeRange)).clamp(0.0, 100.0);
  }

  /// Concave machtscurve (p=0,7): nát worden is de grote straf, daarna vlakt
  /// het af — als je toch doorweekt bent maakt meer regen weinig uit.
  static double rainAmount(double mm, double idealMax) {
    if (mm <= idealMax) return 100.0;
    final ratio = ((mm - idealMax) / rainFadeRangeMm).clamp(0.0, 1.0);
    return (100.0 * (1.0 - pow(ratio, 0.7))).clamp(0.0, 100.0);
  }

  /// Kansscore: 0% → 100, 50% → 60, 100% → 20. Ook bij 100% kans blijft er 20
  /// staan, want een grote kans is minder erg dan bevestigde stortregen.
  static double rainProbability(double probability) =>
      (100.0 - probability * 0.8).clamp(0.0, 100.0);

  /// Convexe machtscurve (p=1,5): een beetje extra wind is te doen, maar het
  /// wordt exponentieel erger — bij hoge snelheden is het een veiligheidsissue.
  static double wind(double kmh, double idealMax) {
    if (kmh <= idealMax) return 100.0;
    final ratio = ((kmh - idealMax) / windFadeRangeKmh).clamp(0.0, 1.0);
    return (100.0 * (1.0 - pow(ratio, 1.5))).clamp(0.0, 100.0);
  }
}

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

    final overall =
        (0.6 * _min3(t, r, w) + 0.4 * (t + r + w) / 3.0).clamp(0.0, 100.0);

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
    final tempScore = _linearScore(
        temperatureC, minIdeal, maxIdeal, MetricScores.tempFadeRangeC);
    if (apparentTemperatureC == null) return tempScore;
    final apparentScore = _linearScore(
        apparentTemperatureC, minIdeal, maxIdeal, MetricScores.tempFadeRangeC);
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

  double _precipAmountScore(double? mm, double rainMaxIdeal) {
    if (mm == null) return 50.0;
    return MetricScores.rainAmount(mm, rainMaxIdeal);
  }

  double _precipProbabilityScore(double probability) =>
      MetricScores.rainProbability(probability);

  double _windScore(double? windspeedKmh, double windMaxIdeal) {
    if (windspeedKmh == null) return 50.0;
    return MetricScores.wind(windspeedKmh, windMaxIdeal);
  }

  double _linearScore(
    double value,
    double minIdeal,
    double maxIdeal,
    double fadeRange,
  ) =>
      MetricScores.linear(value, minIdeal, maxIdeal, fadeRange);

  double _min3(double a, double b, double c) =>
      a < b ? (a < c ? a : c) : (b < c ? b : c);
}
