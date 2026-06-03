import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

// ---------------------------------------------------------------------------
// Test-fixtures
// ---------------------------------------------------------------------------

/// Bouwt een HourlyForecast fixture met opgegeven temperatuur (ideaal weer).
HourlyForecast _goodForecast(DateTime time) => HourlyForecast(
      temperatureC: 18.0,
      apparentTemperatureC: 17.0,
      precipitationMm: 0.0,
      precipitationProbability: 0.0,
      windspeedKmh: 10.0,
      winddirectionDeg: 270.0,
      time: time,
    );

/// Bouwt een HourlyForecast fixture met slecht weer (hoge wind, regen).
HourlyForecast _badForecast(DateTime time) => HourlyForecast(
      temperatureC: 5.0,
      apparentTemperatureC: 2.0,
      precipitationMm: 10.0,
      precipitationProbability: 95.0,
      windspeedKmh: 60.0,
      winddirectionDeg: 270.0,
      time: time,
    );

/// Genereert een lijst van `count` HourlyForecasts vanaf [start] met 1-uurs stappen.
List<HourlyForecast> _forecasts(
  DateTime start,
  int count, {
  bool bad = false,
}) {
  return List.generate(
    count,
    (i) {
      final t = start.add(Duration(hours: i));
      return bad ? _badForecast(t) : _goodForecast(t);
    },
  );
}

// ---------------------------------------------------------------------------
// Fake notifiers voor Riverpod 3.x overrideWith
// ---------------------------------------------------------------------------

class FakeWeatherNotifier extends WeatherNotifier {
  List<HourlyForecast> forecasts;
  FakeWeatherNotifier(this.forecasts);

  @override
  Future<List<HourlyForecast>> build() async => forecasts;
}

class FakeProfileNotifier extends ProfileNotifier {
  @override
  Future<UserProfile> build() async => const UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 10.0,
          tempMaxIdealC: 28.0,
          windMaxIdealKmh: 20.0,
          rainMaxIdealMm: 1.0,
        ),
        allowedDurations: [2, 3],
        theme: 'system',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );
}

class FakeAvailabilityNotifier extends AvailabilityNotifier {
  Map<DateTime, BlockType> initial;
  FakeAvailabilityNotifier(this.initial);

  @override
  Future<Map<DateTime, BlockType>> build() async => initial;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final baseTime = DateTime.utc(2026, 6, 14, 8, 0);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SlotsNotifier', () {
    test('recomputes on weather change — slots wijzigen als weather verandert', () async {
      // Lijst A: goed weer
      final forecastsA = _forecasts(baseTime, 6);
      // Lijst B: slecht weer
      final forecastsB = _forecasts(baseTime, 6, bad: true);

      final fakeWeather = FakeWeatherNotifier(forecastsA);

      final container = ProviderContainer(
        overrides: [
          weatherProvider.overrideWith(() => fakeWeather),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier({})),
        ],
      );
      addTearDown(container.dispose);

      // Wacht tot de state beschikbaar is
      await container.read(weatherProvider.future);

      await container.read(profileProvider.future);
      await container.read(availabilityProvider.future);

      // Lees slots met goed weer
      final stateA = container.read(slotsProvider);
      expect(stateA, isA<SlotsLoaded>());
      final slotsA = (stateA as SlotsLoaded).slots;

      // Zet slecht weer (simuleer update via state)
      fakeWeather.state = AsyncData(forecastsB);

      // Riverpod hercomputed synchronous na state-update
      final stateB = container.read(slotsProvider);
      expect(stateB, isA<SlotsLoaded>());
      final slotsB = (stateB as SlotsLoaded).slots;

      // Slots moeten verschild zijn (goed weer → slecht weer)
      expect(slotsA.length, isNot(equals(slotsB.length)));
    });

    test('recomputes on profile change — slots recomputeren bij tolerantie-wijziging', () async {
      final forecasts = _forecasts(baseTime, 6);

      // Profiel A: brede toleranties (meer slots)
      final fakeProfileA = FakeProfileNotifier();

      final container = ProviderContainer(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherNotifier(forecasts)),
          profileProvider.overrideWith(() => fakeProfileA),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier({})),
        ],
      );
      addTearDown(container.dispose);

      await container.read(weatherProvider.future);
      await container.read(profileProvider.future);
      await container.read(availabilityProvider.future);

      final stateA = container.read(slotsProvider);
      expect(stateA, isA<SlotsLoaded>());

      // Simuleer profiel-wijziging: strenge toleranties (minder slots)
      const strictProfile = UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 20.0,
          tempMaxIdealC: 22.0,
          windMaxIdealKmh: 5.0,
          rainMaxIdealMm: 0.1,
        ),
        allowedDurations: [2],
        theme: 'system',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );
      fakeProfileA.state = const AsyncData(strictProfile);

      final stateB = container.read(slotsProvider);
      expect(stateB, isA<SlotsLoaded>());

      // Na strenge toleranties zijn de slots anders (minder of geen)
      final slotsA = (stateA as SlotsLoaded).slots;
      final slotsB = (stateB as SlotsLoaded).slots;
      expect(slotsA.length, isNot(equals(slotsB.length)));
    });

    test('empty state bad weather — alle slechte scores → SlotsLoaded met reason = badWeather',
        () async {
      final badForecasts = _forecasts(baseTime, 6, bad: true);

      final container = ProviderContainer(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherNotifier(badForecasts)),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier({})),
        ],
      );
      addTearDown(container.dispose);

      await container.read(weatherProvider.future);
      await container.read(profileProvider.future);
      await container.read(availabilityProvider.future);

      final state = container.read(slotsProvider);
      expect(state, isA<SlotsLoaded>());
      final loaded = state as SlotsLoaded;
      expect(loaded.slots, isEmpty);
      expect(loaded.reason, equals(SlotsEmptyReason.badWeather));
    });

    test('empty state all blocked — goede scores maar alle uren geblokkeerd → SlotsLoaded met reason = allBlocked',
        () async {
      final goodForecasts = _forecasts(baseTime, 6);

      // Blokkeer alle uren in de forecast-window
      final blockedHours = Map.fromEntries(
        goodForecasts.map((f) => MapEntry(f.time, BlockType.custom)),
      );

      final container = ProviderContainer(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherNotifier(goodForecasts)),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider
              .overrideWith(() => FakeAvailabilityNotifier(blockedHours)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(weatherProvider.future);
      await container.read(profileProvider.future);
      await container.read(availabilityProvider.future);

      final state = container.read(slotsProvider);
      expect(state, isA<SlotsLoaded>());
      final loaded = state as SlotsLoaded;
      expect(loaded.slots, isEmpty);
      expect(loaded.reason, equals(SlotsEmptyReason.allBlocked));
    });
  });
}
