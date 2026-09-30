import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/ride_window_scorer_provider.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

class _Weather extends WeatherNotifier {
  _Weather(this.forecasts);
  final List<HourlyForecast> forecasts;
  @override
  Future<List<HourlyForecast>> build() async => forecasts;
  void publish(List<HourlyForecast> value) => state = AsyncData(value);
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
  void changeTemperature() => state = AsyncData(
        state.requireValue.copyWith(
          tolerances: state.requireValue.tolerances.copyWith(tempMinIdealC: 5),
        ),
      );
}

class _Location extends LocationNotifier {
  @override
  Future<LocationData> build() async => const LocationData(
        lat: 52.37,
        lon: 4.9,
        city: 'Amsterdam',
        source: LocationSource.override,
      );
}

void main() {
  final start = DateTime(2026, 10, 3, 12);
  final end = start.add(const Duration(hours: 1));
  HourlyForecast forecast(double temp) => HourlyForecast(
        time: start,
        temperatureC: temp,
        apparentTemperatureC: temp,
        precipitationMm: 0,
        precipitationProbability: 0,
        windspeedKmh: 5,
        winddirectionDeg: 90,
      );

  test('actuele score volgt weer én profiel zonder het plan te herschrijven',
      () async {
    final weather = _Weather([forecast(10)]);
    final profile = _Profile();
    final container = ProviderContainer(overrides: [
      weatherProvider.overrideWith(() => weather),
      profileProvider.overrideWith(() => profile),
      locationProvider.overrideWith(_Location.new),
    ]);
    addTearDown(container.dispose);
    container.listen(rideWindowScorerProvider, (previous, next) {});
    await container.read(weatherProvider.future);
    await container.read(profileProvider.future);
    await container.read(locationProvider.future);
    await container.pump();
    double score() => container
        .read(rideWindowScorerProvider)!
        .score(start, end)!
        .overallScore;
    final original = score();
    profile.changeTemperature();
    await container.pump();
    expect(score(), greaterThan(original));
    final improved = score();
    weather.publish([forecast(-15)]);
    await container.pump();
    expect(score(), lessThan(improved));
    expect(score(), lessThan(50));
  });

  test('geen volledige voorspelling betekent geen nieuwe score', () async {
    final container = ProviderContainer(overrides: [
      weatherProvider.overrideWith(() => _Weather([])),
      profileProvider.overrideWith(_Profile.new),
      locationProvider.overrideWith(_Location.new),
    ]);
    addTearDown(container.dispose);
    container.listen(rideWindowScorerProvider, (previous, next) {});
    await container.read(weatherProvider.future);
    await container.read(profileProvider.future);
    await container.read(locationProvider.future);
    expect(container.read(rideWindowScorerProvider)!.score(start, end), isNull);
  });
}
