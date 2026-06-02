import 'package:freezed_annotation/freezed_annotation.dart';

part 'hourly_score.freezed.dart';

@freezed
abstract class HourlyScore with _$HourlyScore {
  const factory HourlyScore({
    required double overall,
    required double temperatureScore,
    required double rainScore,
    required double windScore,
    required DateTime time,
  }) = _HourlyScore;
}
