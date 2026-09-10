import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_tolerances.freezed.dart';
part 'weather_tolerances.g.dart';

@freezed
abstract class WeatherTolerances with _$WeatherTolerances {
  const factory WeatherTolerances({
    @Default(12.0) double tempMinIdealC,
    @Default(26.0) double tempMaxIdealC,
    @Default(15.0) double windMaxIdealKmh,
    @Default(0.5) double rainMaxIdealMm,

    /// Hoe zwaar donker meetelt, van 0,0 (maakt niet uit) tot 1,0 (alleen bij
    /// daglicht). Anders dan de vier hierboven is dit geen grens maar een
    /// gewicht: er bestaat geen "maximaal aantal donkere minuten" waarboven het
    /// ineens niet meer kan. Zie `daylight.dart` voor wat de app ermee doet.
    ///
    /// Staat bewust hier en niet los in [UserProfile]: op het profielscherm
    /// staat hij naast temperatuur, regen en wind, en wie er één verandert
    /// verwacht dat ze samen bewaard worden.
    @Default(0.5) double darknessWeight,
  }) = _WeatherTolerances;

  factory WeatherTolerances.fromJson(Map<String, dynamic> json) =>
      _$WeatherTolerancesFromJson(json);
}
