import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/providers/app_database_provider.dart';

part 'weather_notifier.g.dart';

/// WeatherNotifier fetches the forecast via WeatherRepository and exposes it
/// as `AsyncValue<List<HourlyForecast>>`. Riverpod wraps the Future in AsyncValue
/// automatically, providing loading / data / error states out of the box.
///
/// No BuildContext dependency — fully testable in isolation via ProviderContainer.
@riverpod
class WeatherNotifier extends _$WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() {
    return ref.watch(weatherRepositoryProvider).getForecast();
  }
}
