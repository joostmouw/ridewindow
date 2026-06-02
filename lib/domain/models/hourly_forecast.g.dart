// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hourly_forecast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HourlyForecast _$HourlyForecastFromJson(Map<String, dynamic> json) =>
    _HourlyForecast(
      temperatureC: (json['temperature_2m'] as num?)?.toDouble(),
      apparentTemperatureC: (json['apparent_temperature'] as num?)?.toDouble(),
      precipitationMm: (json['precipitation'] as num?)?.toDouble(),
      precipitationProbability:
          (json['precipitation_probability'] as num?)?.toDouble(),
      windspeedKmh: (json['windspeed_10m'] as num?)?.toDouble(),
      winddirectionDeg: (json['winddirection_10m'] as num?)?.toDouble(),
      time: DateTime.parse(json['time'] as String),
    );

Map<String, dynamic> _$HourlyForecastToJson(_HourlyForecast instance) =>
    <String, dynamic>{
      'temperature_2m': instance.temperatureC,
      'apparent_temperature': instance.apparentTemperatureC,
      'precipitation': instance.precipitationMm,
      'precipitation_probability': instance.precipitationProbability,
      'windspeed_10m': instance.windspeedKmh,
      'winddirection_10m': instance.winddirectionDeg,
      'time': instance.time.toIso8601String(),
    };
