// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_tolerances.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeatherTolerances _$WeatherTolerancesFromJson(Map<String, dynamic> json) =>
    _WeatherTolerances(
      tempMinIdealC: (json['tempMinIdealC'] as num?)?.toDouble() ?? 12.0,
      tempMaxIdealC: (json['tempMaxIdealC'] as num?)?.toDouble() ?? 26.0,
      windMaxIdealKmh: (json['windMaxIdealKmh'] as num?)?.toDouble() ?? 15.0,
      rainMaxIdealMm: (json['rainMaxIdealMm'] as num?)?.toDouble() ?? 0.5,
    );

Map<String, dynamic> _$WeatherTolerancesToJson(_WeatherTolerances instance) =>
    <String, dynamic>{
      'tempMinIdealC': instance.tempMinIdealC,
      'tempMaxIdealC': instance.tempMaxIdealC,
      'windMaxIdealKmh': instance.windMaxIdealKmh,
      'rainMaxIdealMm': instance.rainMaxIdealMm,
    };
