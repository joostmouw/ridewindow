import 'package:freezed_annotation/freezed_annotation.dart';

import 'hourly_score.dart';
import 'ride_tier.dart';

part 'ride_slot.freezed.dart';

@freezed
abstract class RideSlot with _$RideSlot {
  const factory RideSlot({
    /// Inclusive start of slot.
    required DateTime start,

    /// Exclusive end of slot — [start, end) convention.
    required DateTime end,

    required double overallScore,
    required RideTier tier,
    required List<HourlyScore> hours,
  }) = _RideSlot;
}
