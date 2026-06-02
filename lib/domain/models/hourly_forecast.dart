import 'package:freezed_annotation/freezed_annotation.dart';

part 'hourly_forecast.freezed.dart';
part 'hourly_forecast.g.dart';

@freezed
abstract class HourlyForecast with _$HourlyForecast {
  const factory HourlyForecast({
    @JsonKey(name: 'temperature_2m') required double? temperatureC,
    @JsonKey(name: 'apparent_temperature') required double? apparentTemperatureC,
    @JsonKey(name: 'precipitation') required double? precipitationMm,
    @JsonKey(name: 'precipitation_probability')
    required double? precipitationProbability,
    @JsonKey(name: 'windspeed_10m') required double? windspeedKmh,
    @JsonKey(name: 'winddirection_10m') required double? winddirectionDeg,
    required DateTime time,
  }) = _HourlyForecast;

  factory HourlyForecast.fromJson(Map<String, dynamic> json) =>
      _$HourlyForecastFromJson(json);
}
