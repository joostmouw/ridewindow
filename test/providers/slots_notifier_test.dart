import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/clock_provider.dart';
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

/// WeatherNotifier stub die op commando kan falen — gebruikt om REFRESH-04's
/// "stale data survives a failed refresh" gedrag te bewijzen via de publieke
/// ProviderContainer.refresh() API (niet via copyWithPrevious, dat @internal is).
class FakeWeatherFlaky extends WeatherNotifier {
  List<HourlyForecast> forecasts;
  bool shouldFail = false;
  FakeWeatherFlaky(this.forecasts);

  @override
  Future<List<HourlyForecast>> build() async {
    if (shouldFail) throw Exception('offline');
    return forecasts;
  }
}

/// WeatherNotifier stub die vanaf de allereerste build() faalt -- simuleert
/// het "nog nooit geladen" pad (geen eerdere succesvolle waarde).
class FakeWeatherNeverLoaded extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async {
    throw Exception('offline from the start');
  }
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
          nowProvider.overrideWithValue(baseTime),
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
          nowProvider.overrideWithValue(baseTime),
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
          nowProvider.overrideWithValue(baseTime),
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
          nowProvider.overrideWithValue(baseTime),
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

    test(
        'preserves last-known slots when weatherProvider errors after a prior success (REFRESH-04)',
        () async {
      final goodForecasts = _forecasts(baseTime, 6);
      final fakeWeather = FakeWeatherFlaky(goodForecasts);

      final container = ProviderContainer(
        // Disable Riverpod's default exponential-backoff retry (up to 10
        // attempts) so a single simulated failure settles into AsyncError
        // immediately -- otherwise this test would need to wait through
        // several real-time retry delays before hasError becomes true.
        retry: (retryCount, error) => null,
        overrides: [
          nowProvider.overrideWithValue(baseTime),
          weatherProvider.overrideWith(() => fakeWeather),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier({})),
        ],
      );
      addTearDown(container.dispose);

      await container.read(weatherProvider.future);
      await container.read(profileProvider.future);
      await container.read(availabilityProvider.future);

      final stateBefore = container.read(slotsProvider);
      expect(stateBefore, isA<SlotsLoaded>());
      final loadedBefore = stateBefore as SlotsLoaded;
      expect(loadedBefore.slots, isNotEmpty);

      // Simuleer een refresh die faalt (bijv. offline) na een eerder succes.
      fakeWeather.shouldFail = true;
      // Publieke API -- dit laat Riverpod intern de vorige waarde bewaren op
      // de resulterende AsyncError (copyWithPrevious, niet direct aanroepen).
      container.refresh(weatherProvider);
      // Wacht tot de gefaalde rebuild daadwerkelijk is opgelost.
      await container.read(weatherProvider.future).then(
            (_) => null,
            onError: (_) => null,
          );

      final weatherAfter = container.read(weatherProvider);
      expect(weatherAfter.hasError, isTrue);
      expect(weatherAfter.hasValue, isTrue);

      final stateAfter = container.read(slotsProvider);
      expect(stateAfter, isA<SlotsLoaded>());
      final loadedAfter = stateAfter as SlotsLoaded;

      // Stale data overleeft de fout — identiek aan de staat vóór de fout.
      expect(loadedAfter.slots.length, equals(loadedBefore.slots.length));
      expect(loadedAfter.reason, equals(loadedBefore.reason));
    });

    test(
        'never-loaded weather error still yields empty slots (regression)',
        () async {
      final container = ProviderContainer(
        // Disable retry -- see comment in the REFRESH-04 test above.
        retry: (retryCount, error) => null,
        overrides: [
          nowProvider.overrideWithValue(baseTime),
          weatherProvider.overrideWith(() => FakeWeatherNeverLoaded()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier({})),
        ],
      );
      addTearDown(container.dispose);

      // weatherProvider.future rejects since build() throws on the very
      // first call -- catch it here so the test doesn't fail on the await.
      await container.read(weatherProvider.future).catchError((_) => <HourlyForecast>[]);
      await container.read(profileProvider.future);
      await container.read(availabilityProvider.future);

      final weatherState = container.read(weatherProvider);
      expect(weatherState.hasError, isTrue);
      expect(weatherState.hasValue, isFalse);

      final state = container.read(slotsProvider);
      expect(state, isA<SlotsLoaded>());
      final loaded = state as SlotsLoaded;
      expect(loaded.slots, isEmpty);
    });
  });
}
