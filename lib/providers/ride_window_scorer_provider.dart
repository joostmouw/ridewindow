import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/domain/services/ride_window_scorer.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

part 'ride_window_scorer_provider.g.dart';

/// Ook tijdens een refresh dezelfde laatst bekende voorspelling blijven
/// gebruiken. De weersfout staat al op Home; terugveren naar de planscore
/// zou een verslechterde rit ineens weer goed laten lijken.
@riverpod
RideWindowScorer? rideWindowScorer(Ref ref) {
  final forecasts = ref.watch(weatherProvider).value;
  final profile = ref.watch(profileProvider).value;
  final location = ref.watch(locationProvider).value;
  if (forecasts == null || profile == null) return null;
  return RideWindowScorer(
    forecasts: forecasts,
    tolerances: profile.tolerances,
    latitude: location?.lat,
    longitude: location?.lon,
  );
}
