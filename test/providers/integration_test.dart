/// End-to-end integratietests voor Phase 3 provider-keten.
///
/// Elke test dekt één van de vijf Phase 3 success criteria:
///   1. WeatherNotifier: loading → data transitie (criterion 1)
///   2a. SlotsNotifier recomputed bij weer-wijziging (criterion 2, weather-tak)
///   2b. SlotsNotifier recomputed bij profiel-wijziging (criterion 2, profile-tak)
///   3. AvailabilityNotifier toggle triggert slot-wijziging (criterion 3)
///   5. UserProfile instellingen persisteren ProviderContainer dispose/re-create (criterion 5)
///
/// Alle tests gebruiken ProviderContainer (geen WidgetTester, geen Flutter-UI).
/// SharedPreferences.setMockInitialValues({}) in setUp garandeert geïsoleerde state.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _baseTime = DateTime.utc(2026, 6, 14, 8, 0);

/// 168 uur aan goed-weer forecasts (7 dagen): temp 20°C, wind 10 km/u, regen 0.
List<HourlyForecast> _goodForecasts({int count = 168}) => List.generate(
      count,
      (i) => HourlyForecast(
        temperatureC: 20.0,
        apparentTemperatureC: 20.0,
        precipitationMm: 0.0,
        precipitationProbability: 0.0,
        windspeedKmh: 10.0,
        winddirectionDeg: 180.0,
        time: _baseTime.add(Duration(hours: i)),
      ),
    );

/// 168 uur aan slecht-weer forecasts: zware regen en hoge wind.
List<HourlyForecast> _badForecasts({int count = 168}) => List.generate(
      count,
      (i) => HourlyForecast(
        temperatureC: 5.0,
        apparentTemperatureC: 2.0,
        precipitationMm: 50.0,
        precipitationProbability: 99.0,
        windspeedKmh: 80.0,
        winddirectionDeg: 270.0,
        time: _baseTime.add(Duration(hours: i)),
      ),
    );

// ---------------------------------------------------------------------------
// Fake Notifiers (Riverpod 3.x overrideWith patroon)
// ---------------------------------------------------------------------------

/// Fake WeatherNotifier die een vaste forecast retourneert.
/// Extends WeatherNotifier zodat overrideWith werkt.
class FakeWeatherNotifier extends WeatherNotifier {
  final List<HourlyForecast> _forecasts;
  FakeWeatherNotifier(this._forecasts);

  @override
  Future<List<HourlyForecast>> build() async => _forecasts;
}

/// Fake WeatherNotifier die slechte forecasts retourneert.
class BadWeatherNotifier extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => _badForecasts();
}

/// Fake ProfileNotifier met brede toleranties (meer kans op goede slots).
class FakeProfileNotifier extends ProfileNotifier {
  @override
  Future<UserProfile> build() async => const UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 10.0,
          tempMaxIdealC: 30.0,
          windMaxIdealKmh: 25.0,
          rainMaxIdealMm: 1.0,
        ),
        allowedDurations: [2, 3],
        theme: 'system',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );
}

/// Fake AvailabilityNotifier met initieel lege blocked-map.
class EmptyAvailabilityNotifier extends AvailabilityNotifier {
  @override
  Future<Map<DateTime, BlockType>> build() async => const {};
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // -------------------------------------------------------------------------
  // Criterion 1: WeatherNotifier loading → data transitie
  // -------------------------------------------------------------------------
  test('weather loading→data: WeatherNotifier transitie loading naar data', () async {
    final container = ProviderContainer(
      overrides: [
        weatherRepositoryProvider.overrideWith(
          (ref) => throw UnimplementedError('use FakeWeatherNotifier'),
        ),
        weatherProvider.overrideWith(() => FakeWeatherNotifier(_goodForecasts())),
      ],
    );
    addTearDown(container.dispose);

    // Lees initiële state — auto-dispose provider start in loading
    final initial = container.read(weatherProvider);
    expect(initial, isA<AsyncLoading>());

    // Wacht op data
    final forecasts = await container.read(weatherProvider.future);
    expect(forecasts, isNotEmpty);
    expect(forecasts.first.temperatureC, equals(20.0));
    expect(forecasts.first.precipitationMm, equals(0.0));

    // State is nu AsyncData
    final after = container.read(weatherProvider);
    expect(after, isA<AsyncData<List<HourlyForecast>>>());
    expect(after.requireValue.length, equals(168));
  });

  // -------------------------------------------------------------------------
  // Criterion 2 (weather-tak): slots recomputeren als weather verandert
  // -------------------------------------------------------------------------
  test('slots recompute on weather change: nieuwe forecasts → andere slots', () async {
    final fakeWeather = FakeWeatherNotifier(_goodForecasts());

    final container = ProviderContainer(
      overrides: [
        weatherProvider.overrideWith(() => fakeWeather),
        profileProvider.overrideWith(() => FakeProfileNotifier()),
        availabilityProvider.overrideWith(() => EmptyAvailabilityNotifier()),
      ],
    );
    addTearDown(container.dispose);

    // Wacht tot alle providers klaar zijn
    await container.read(weatherProvider.future);
    await container.read(profileProvider.future);
    await container.read(availabilityProvider.future);

    // Slots met goed weer
    final stateA = container.read(slotsProvider);
    expect(stateA, isA<SlotsLoaded>());
    final slotsA = (stateA as SlotsLoaded).slots;
    expect(slotsA, isNotEmpty);

    // Simuleer overgang naar slecht weer
    fakeWeather.state = AsyncData(_badForecasts());

    // SlotsNotifier hercomputed synchronous na state-update
    final stateB = container.read(slotsProvider);
    expect(stateB, isA<SlotsLoaded>());
    final slotsB = (stateB as SlotsLoaded).slots;

    // Slots moeten verschilt zijn — slecht weer → geen of minder slots
    expect(slotsA.length, isNot(equals(slotsB.length)));
  });

  // -------------------------------------------------------------------------
  // Criterion 2 (profile-tak): slots recomputeren als profiel verandert
  // -------------------------------------------------------------------------
  test('slots recompute on profile change: updateTolerances → SlotsNotifier recomputed',
      () async {
    final fakeProfile = FakeProfileNotifier();

    final container = ProviderContainer(
      overrides: [
        weatherProvider.overrideWith(() => FakeWeatherNotifier(_goodForecasts())),
        profileProvider.overrideWith(() => fakeProfile),
        availabilityProvider.overrideWith(() => EmptyAvailabilityNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(weatherProvider.future);
    await container.read(profileProvider.future);
    await container.read(availabilityProvider.future);

    // Slots met brede toleranties
    final stateA = container.read(slotsProvider);
    expect(stateA, isA<SlotsLoaded>());
    final slotsA = (stateA as SlotsLoaded).slots;
    expect(slotsA, isNotEmpty);

    // Simuleer profiel-update: erg strenge toleranties
    const strictProfile = UserProfile(
      tolerances: WeatherTolerances(
        tempMinIdealC: 24.0,
        tempMaxIdealC: 26.0,
        windMaxIdealKmh: 1.0,
        rainMaxIdealMm: 0.0,
      ),
      allowedDurations: [2],
      theme: 'system',
      notifEveningBefore: false,
      notifMorningOf: false,
      notifWeeklyDigest: false,
    );
    fakeProfile.state = const AsyncData(strictProfile);

    // SlotsNotifier hercomputed via ref.watch(profileProvider)
    final stateB = container.read(slotsProvider);
    expect(stateB, isA<SlotsLoaded>());
    final slotsB = (stateB as SlotsLoaded).slots;

    // Na strenge toleranties zijn er minder slots
    expect(slotsB.length, lessThan(slotsA.length));
  });

  // -------------------------------------------------------------------------
  // Criterion 3: AvailabilityNotifier toggle triggert slot-wijziging
  // -------------------------------------------------------------------------
  test(
      'availability toggle triggers slot change: toggleHour blokkeert uren → SlotsLoaded.reason == allBlocked',
      () async {
    final goodForecasts = _goodForecasts(count: 6);

    final container = ProviderContainer(
      overrides: [
        weatherProvider.overrideWith(() => FakeWeatherNotifier(goodForecasts)),
        profileProvider.overrideWith(() => FakeProfileNotifier()),
        availabilityProvider.overrideWith(() => EmptyAvailabilityNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(weatherProvider.future);
    await container.read(profileProvider.future);
    await container.read(availabilityProvider.future);

    // Initieel: goede slots aanwezig
    final initial = container.read(slotsProvider);
    expect(initial, isA<SlotsLoaded>());
    expect((initial as SlotsLoaded).slots, isNotEmpty);

    // Blokkeer alle uren in de forecast-window via toggleCustomHour
    final notifier = container.read(availabilityProvider.notifier);
    for (final fc in goodForecasts) {
      await notifier.toggleCustomHour(fc.time);
    }

    // SlotsNotifier hercomputed na availability-update
    final after = container.read(slotsProvider);
    expect(after, isA<SlotsLoaded>());
    final loaded = after as SlotsLoaded;
    expect(loaded.slots, isEmpty);
    expect(loaded.reason, equals(SlotsEmptyReason.allBlocked));
  });

  // -------------------------------------------------------------------------
  // Criterion 5: UserProfile instellingen persisteren dispose/re-create
  // -------------------------------------------------------------------------
  test('dispose and recreate preserves settings: profiel overleeft container dispose',
      () async {
    // Container 1: schrijf toleranties naar SharedPreferences
    final container1 = ProviderContainer();

    // Wacht op initieel profiel
    await container1.read(profileProvider.future);

    // Schrijf afwijkende toleranties (boven default)
    const customTolerances = WeatherTolerances(
      tempMinIdealC: 5.0,
      tempMaxIdealC: 35.0,
      windMaxIdealKmh: 40.0,
      rainMaxIdealMm: 3.0,
    );
    await container1.read(profileProvider.notifier).updateTolerances(customTolerances);

    // Bevestig dat de state bijgewerkt is
    final profileAfterUpdate =
        await container1.read(profileProvider.future);
    expect(profileAfterUpdate.tolerances.tempMinIdealC, equals(5.0));
    expect(profileAfterUpdate.tolerances.windMaxIdealKmh, equals(40.0));

    // Dispose container 1
    container1.dispose();

    // Container 2: laden vanuit SharedPreferences (mock heeft de waarden)
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);

    final restoredProfile = await container2.read(profileProvider.future);

    // Toleranties moeten hersteld zijn vanuit SharedPreferences
    expect(restoredProfile.tolerances.tempMinIdealC, equals(5.0));
    expect(restoredProfile.tolerances.tempMaxIdealC, equals(35.0));
    expect(restoredProfile.tolerances.windMaxIdealKmh, equals(40.0));
    expect(restoredProfile.tolerances.rainMaxIdealMm, equals(3.0));
  });
}
