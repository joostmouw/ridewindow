import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:ridewindow/data/repositories/weather_repository.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

import 'weather_notifier_test.mocks.dart';

@GenerateMocks([WeatherRepository])

/// FakeLocationNotifier retourneert een vaste locatie (Amsterdam) voor tests.
class FakeLocationNotifier extends LocationNotifier {
  @override
  Future<LocationData> build() async => const LocationData(
        lat: 52.3676,
        lon: 4.9041,
        city: 'Amsterdam',
      );
}

void main() {
  final testForecast = HourlyForecast(
    temperatureC: 18.0,
    apparentTemperatureC: 16.5,
    precipitationMm: 0.0,
    precipitationProbability: 5.0,
    windspeedKmh: 12.0,
    winddirectionDeg: 270.0,
    time: DateTime.utc(2026, 6, 10, 9, 0),
  );

  group('WeatherNotifier', () {
    test('starts in loading state', () {
      final mock = MockWeatherRepository();
      final completer = Completer<List<HourlyForecast>>();
      when(mock.getForecast(lat: anyNamed('lat'), lon: anyNamed('lon')))
          .thenAnswer((_) => completer.future);

      final container = ProviderContainer(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(mock),
          locationProvider.overrideWith(FakeLocationNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      // weatherProvider is the generated name for WeatherNotifier in Riverpod 3.x
      final state = container.read(weatherProvider);
      expect(state, isA<AsyncLoading>());
    });

    test('transitions to data on success', () async {
      final mock = MockWeatherRepository();
      when(mock.getForecast(lat: anyNamed('lat'), lon: anyNamed('lon')))
          .thenAnswer((_) => Future.value([testForecast]));

      final container = ProviderContainer(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(mock),
          locationProvider.overrideWith(FakeLocationNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(weatherProvider.future);
      expect(result, hasLength(1));
      expect(result.first.time, equals(testForecast.time));
    });

    test('transitions to error state on failure', () async {
      final mock = MockWeatherRepository();
      // Use async throw so the error goes through the Future pipeline
      when(mock.getForecast(lat: anyNamed('lat'), lon: anyNamed('lon')))
          .thenAnswer((_) async {
        throw Exception('network');
      });

      final container = ProviderContainer(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(mock),
          locationProvider.overrideWith(FakeLocationNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      // Keep the subscription alive so the provider isn't disposed prematurely
      final sub = container.listen<AsyncValue<List<HourlyForecast>>>(
        weatherProvider,
        (prev, next) {},
        fireImmediately: true,
      );

      // Pump microtasks to let the async error propagate
      for (int i = 0; i < 20; i++) {
        await Future.microtask(() {});
      }

      final state = container.read(weatherProvider);
      sub.close();

      // Riverpod 3.x auto-retry: after an error the state stays AsyncLoading
      // but hasError is true and error contains the thrown exception.
      expect(state.hasError, isTrue);
      expect(state.error, isA<Exception>());
    });
  });
}
