import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/services/scoring_engine.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

part 'hourly_scores_provider.g.dart';

/// Exposes scored hourly weather data for ALL forecast hours (not just slot hours).
/// Used by the agenda screen to color every hour block.
@riverpod
List<HourlyScore> allHourlyScores(Ref ref) {
  final weatherValue = ref.watch(weatherProvider);
  final profileValue = ref.watch(profileProvider);

  if (weatherValue.isLoading ||
      weatherValue.hasError ||
      profileValue.isLoading ||
      profileValue.hasError) {
    return [];
  }

  final forecasts = weatherValue.requireValue;
  final tolerances = profileValue.requireValue.tolerances;
  final engine = ScoringEngine();

  return forecasts.map((f) => engine.score(f, tolerances)).toList();
}
