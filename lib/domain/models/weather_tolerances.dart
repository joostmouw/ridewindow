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
  }) = _WeatherTolerances;

  factory WeatherTolerances.fromJson(Map<String, dynamic> json) =>
      _$WeatherTolerancesFromJson(json);
}
