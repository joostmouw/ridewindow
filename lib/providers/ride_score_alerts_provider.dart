import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridewindow/data/repositories/ride_score_alert_store.dart';
import 'package:ridewindow/domain/models/watched_ride.dart';
import 'package:ridewindow/platform/ride_score_alerts.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/ride_entries_provider.dart';
import 'package:ridewindow/providers/ride_window_scorer_provider.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

part 'ride_score_alerts_provider.g.dart';

@Riverpod(keepAlive: true)
class ScoreDropThreshold extends _$ScoreDropThreshold {
  @override
  Future<int> build() async =>
      RideScoreAlertStore(await SharedPreferences.getInstance()).threshold;

  Future<void> setThreshold(int value) async {
    final store = RideScoreAlertStore(await SharedPreferences.getInstance());
    await store.setThreshold(value);
    state = AsyncData(value);
  }
}

@Riverpod(keepAlive: true)
Future<RideScoreAlerts> rideScoreAlertService(Ref ref) async =>
    RideScoreAlerts(await SharedPreferences.getInstance());

@Riverpod(keepAlive: true)
Future<void> monitorRideScores(Ref ref) async {
  if (kIsWeb) return;
  final threshold = ref.watch(scoreDropThresholdProvider);
  final scorer = ref.watch(rideWindowScorerProvider);
  final weather = ref.watch(weatherProvider);
  final profile = ref.watch(profileProvider).value;
  final entries = ref.watch(rideEntriesProvider);
  final owner = ref.watch(currentUserIdProvider);
  final personalReady = ref.watch(plannedRidesProvider).hasValue;
  final sharedReady = ref.watch(ownedGroupRidesProvider).hasValue &&
      ref.watch(joinedGroupRidesProvider).hasValue;
  // Geen vergelijkingsscore veranderen op oude data terwijl nieuw weer nog
  // onderweg is, of de lokale plannen nog niet geladen zijn.
  if (!threshold.hasValue ||
      scorer == null ||
      profile == null ||
      !personalReady ||
      weather.isLoading ||
      weather.hasError) {
    return;
  }
  final service = await ref.watch(rideScoreAlertServiceProvider.future);
  if (!ref.mounted) return;
  try {
    await service.check(
      scorer: scorer,
      locale: profile.locale,
      rides: WatchedRide.fromEntries(entries),
      owner: owner,
      retainShared: owner != null && !sharedReady,
      isCurrent: () => ref.mounted,
    );
  } catch (_) {
    // Geen rijgegevens in een log, en een meldingsfout blokkeert de app niet.
    debugPrint(
      'Controle van ritscoremeldingen mislukt; volgende ronde opnieuw.',
    );
  }
}
