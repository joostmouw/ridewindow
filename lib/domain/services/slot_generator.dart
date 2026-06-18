import 'dart:math';

import '../models/hourly_forecast.dart';
import '../models/hourly_score.dart';
import '../models/ride_slot.dart';
import '../models/ride_tier.dart';

/// Computes wind direction variability penalty for a list of forecasts.
/// Returns a value between 0.0 (consistent) and 0.10 (highly variable).
double windVariabilityPenalty(List<HourlyForecast> forecasts) {
  final dirs = forecasts
      .map((f) => f.winddirectionDeg)
      .whereType<double>()
      .toList();
  if (dirs.length < 2) return 0.0;
  double sinSum = 0, cosSum = 0;
  for (final d in dirs) {
    sinSum += sin(d * pi / 180);
    cosSum += cos(d * pi / 180);
  }
  final meanLength = sqrt(sinSum * sinSum + cosSum * cosSum) / dirs.length;
  final variability = 1.0 - meanLength;
  return (variability * 0.10).clamp(0.0, 0.10);
}

/// Generates ride slots of the given durations from a list of hourly scores.
/// Slot boundaries use the exclusive-end convention [start, end):
/// a 2h slot starting at 09:00 covers 09:00–11:00 with end == 11:00.
class SlotGenerator {
  /// Generate all valid sliding-window slots.
  ///
  /// [minHour]/[maxHour] filter out night hours (default 0–24 = no filter).
  /// Hours must be contiguous (1h apart) within a window.
  List<RideSlot> generate(
    List<HourlyScore> scores, {
    required List<int> allowedDurations,
    int minHour = 0,
    int maxHour = 24,
  }) {
    if (scores.isEmpty) return [];

    final slots = <RideSlot>[];

    for (final d in allowedDurations) {
      if (scores.length < d) continue;

      for (var i = 0; i <= scores.length - d; i++) {
        final window = scores.sublist(i, i + d);

        // Night filter: skip if any hour is outside [minHour, maxHour)
        if (window.any((s) => s.time.hour < minHour || s.time.hour >= maxHour)) {
          continue;
        }

        // Contiguity: all hours must be exactly 1h apart
        if (!_isContiguous(window)) continue;

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

  /// Apply slot-level penalties: trend (declining score) and wind consistency.
  /// Call after [generate], before availability filtering.
  List<RideSlot> refine(List<RideSlot> slots, List<HourlyForecast> forecasts) {
    return slots.map((slot) {
      final trendPen = _trendPenalty(slot.hours);

      final slotForecasts = forecasts
          .where(
            (f) =>
                !f.time.isBefore(slot.start) && f.time.isBefore(slot.end),
          )
          .toList();
      final windPen = _windConsistencyPenalty(slotForecasts);

      final adjusted =
          (slot.overallScore * (1.0 - trendPen) * (1.0 - windPen))
              .clamp(0.0, 100.0);
      final tier = rideTierFromScore(adjusted);

      return RideSlot(
        start: slot.start,
        end: slot.end,
        overallScore: adjusted,
        tier: tier,
        hours: slot.hours,
      );
    }).toList();
  }

  /// Remove overlapping inferior slots. Two slots "significantly overlap"
  /// when >50% of the shorter slot's hours are shared. Greedy: keep best first.
  List<RideSlot> dedup(List<RideSlot> slots) {
    final sorted = [...slots]
      ..sort((a, b) => b.overallScore.compareTo(a.overallScore));
    final kept = <RideSlot>[];
    for (final slot in sorted) {
      if (!kept.any((p) => _overlapRatio(p, slot) > 0.5)) {
        kept.add(slot);
      }
    }
    // Re-sort by start time ascending, then score descending
    kept.sort((a, b) {
      final cmp = a.start.compareTo(b.start);
      if (cmp != 0) return cmp;
      return b.overallScore.compareTo(a.overallScore);
    });
    return kept;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  bool _isContiguous(List<HourlyScore> window) {
    for (var i = 1; i < window.length; i++) {
      if (window[i].time.difference(window[i - 1].time).inHours != 1) {
        return false;
      }
    }
    return true;
  }

  /// Penalize slots where the second half scores worse than the first half.
  /// A declining score means conditions are worsening — the cyclist will
  /// start in good weather and end in bad weather. Max 15% penalty.
  double _trendPenalty(List<HourlyScore> hours) {
    if (hours.length < 2) return 0.0;
    final mid = hours.length ~/ 2;
    final firstAvg =
        hours.sublist(0, mid).fold(0.0, (s, h) => s + h.overall) / mid;
    final secondAvg = hours
            .sublist(mid)
            .fold(0.0, (s, h) => s + h.overall) /
        (hours.length - mid);
    if (secondAvg >= firstAvg) return 0.0; // improving or stable
    final drop = (firstAvg - secondAvg) / 100.0; // normalized 0–1
    return (drop * 0.15).clamp(0.0, 0.15);
  }

  /// Penalize slots with highly variable wind direction (gusty/turbulent).
  /// Uses circular standard deviation of wind direction. Max 10% penalty.
  double _windConsistencyPenalty(List<HourlyForecast> forecasts) {
    final dirs = forecasts
        .map((f) => f.winddirectionDeg)
        .whereType<double>()
        .toList();
    if (dirs.length < 2) return 0.0;
    double sinSum = 0, cosSum = 0;
    for (final d in dirs) {
      sinSum += sin(d * pi / 180);
      cosSum += cos(d * pi / 180);
    }
    final meanLength = sqrt(sinSum * sinSum + cosSum * cosSum) / dirs.length;
    // meanLength: 1.0 = all same direction, 0.0 = uniformly distributed
    final variability = 1.0 - meanLength;
    return (variability * 0.10).clamp(0.0, 0.10);
  }

  /// Fraction of [b]'s hours that overlap with [a]. Returns 0.0–1.0.
  double _overlapRatio(RideSlot a, RideSlot b) {
    final overlapStart = a.start.isAfter(b.start) ? a.start : b.start;
    final overlapEnd = a.end.isBefore(b.end) ? a.end : b.end;
    if (!overlapStart.isBefore(overlapEnd)) return 0.0;
    final overlapHours = overlapEnd.difference(overlapStart).inHours;
    final bHours = b.end.difference(b.start).inHours;
    if (bHours == 0) return 0.0;
    return overlapHours / bHours;
  }
}
