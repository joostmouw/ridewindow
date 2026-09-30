import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridewindow/data/repositories/ride_score_alert_store.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/domain/models/watched_ride.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/services/ride_window_scorer.dart';
import 'package:ridewindow/platform/ride_score_alerts.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/ride_entries_provider.dart';
import 'package:ridewindow/providers/ride_score_alerts_provider.dart';
import 'package:ridewindow/providers/ride_window_scorer_provider.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

class _Service extends RideScoreAlerts {
  _Service(super.prefs);
  final List<List<WatchedRide>> calls = [];
  @override
  Future<void> check({
    required RideWindowScorer scorer,
    required String locale,
    List<WatchedRide>? rides,
    String? owner,
    bool retainShared = false,
    DateTime? now,
    bool Function()? isCurrent,
  }) async {
    if (isCurrent?.call() ?? true) calls.add(rides ?? []);
  }
}

class _Weather extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => [];
  void publish() => state = const AsyncData([]);
}

class _Profile extends ProfileNotifier {
  @override
  Future<UserProfile> build() async => const UserProfile(
        tolerances: WeatherTolerances(),
        allowedDurations: [2],
        theme: 'system',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );
}

class _Plans extends PlannedRidesNotifier {
  @override
  Future<List<PlannedRide>> build() async => [];
}

void main() {
  test('appmonitor controleert plannen bij nieuw weer en gewijzigde drempel',
      () async {
    SharedPreferences.setMockInitialValues({kScoreDropThresholdKey: 10});
    final service = _Service(await SharedPreferences.getInstance());
    final weather = _Weather();
    final start = DateTime(2026, 10, 3, 12);
    final entries = [
      for (final role in RideRole.values)
        RideEntry(
          start: start,
          end: start.add(const Duration(hours: 2)),
          plannedScore: 90,
          role: role,
        ),
    ];
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(null),
        profileProvider.overrideWith(_Profile.new),
        weatherProvider.overrideWith(() => weather),
        plannedRidesProvider.overrideWith(_Plans.new),
        ownedGroupRidesProvider.overrideWith((ref) async => []),
        joinedGroupRidesProvider.overrideWith((ref) async => []),
        rideEntriesProvider.overrideWithValue(entries),
        rideWindowScorerProvider.overrideWithValue(
          RideWindowScorer(
            forecasts: [],
            tolerances: const WeatherTolerances(),
          ),
        ),
        rideScoreAlertServiceProvider.overrideWith((ref) async => service),
      ],
    );
    addTearDown(container.dispose);
    container.listen(monitorRideScoresProvider, (previous, next) {});
    await container.read(profileProvider.future);
    await container.read(weatherProvider.future);
    await container.read(plannedRidesProvider.future);
    await container.read(scoreDropThresholdProvider.future);
    await container.read(monitorRideScoresProvider.future);
    expect(service.calls, isNotEmpty);
    expect(service.calls.last, hasLength(3));
    var calls = service.calls.length;
    weather.publish();
    await container.pump();
    await container.read(monitorRideScoresProvider.future);
    expect(service.calls.length, greaterThan(calls));
    calls = service.calls.length;
    await container.read(scoreDropThresholdProvider.notifier).setThreshold(5);
    await container.pump();
    await container.read(monitorRideScoresProvider.future);
    expect(service.calls.length, greaterThan(calls));
  });
}
