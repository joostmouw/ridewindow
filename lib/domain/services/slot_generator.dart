import '../models/hourly_score.dart';
import '../models/ride_slot.dart';
import '../models/ride_tier.dart';

/// Generates ride slots of the given durations from a list of hourly scores.
/// Slot boundaries use the exclusive-end convention [start, end):
/// a 2h slot starting at 09:00 covers 09:00–11:00 with end == 11:00.
class SlotGenerator {
  List<RideSlot> generate(
    List<HourlyScore> scores, {
    required List<int> allowedDurations,
  }) {
    if (scores.isEmpty) return [];

    final slots = <RideSlot>[];

    for (final d in allowedDurations) {
      if (scores.length < d) continue;

      for (var i = 0; i <= scores.length - d; i++) {
        final window = scores.sublist(i, i + d);
        final overallScore =
            window.fold(0.0, (sum, s) => sum + s.overall) / d;
        final tier = rideTierFromScore(overallScore);
        final start = window.first.time;
        // end is exclusive: one hour past the last scored hour
        final end = window.last.time.add(const Duration(hours: 1));

        slots.add(RideSlot(
          start: start,
          end: end,
          overallScore: overallScore,
          tier: tier,
          hours: window,
        ),);
      }
    }

    // Sort by start time ascending, then by overallScore descending
    slots.sort((a, b) {
      final cmp = a.start.compareTo(b.start);
      if (cmp != 0) return cmp;
      return b.overallScore.compareTo(a.overallScore);
    });

    return slots;
  }
}
