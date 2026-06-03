// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// WeatherNotifier fetches the forecast via WeatherRepository and exposes it
/// as `AsyncValue<List<HourlyForecast>>`. Riverpod wraps the Future in AsyncValue
/// automatically, providing loading / data / error states out of the box.
///
/// Watches locationProvider so that when the location changes (GPS or city override),
/// the forecast is automatically re-fetched for the new location.
///
/// No BuildContext dependency — fully testable in isolation via ProviderContainer.

@ProviderFor(WeatherNotifier)
final weatherProvider = WeatherNotifierProvider._();

/// WeatherNotifier fetches the forecast via WeatherRepository and exposes it
/// as `AsyncValue<List<HourlyForecast>>`. Riverpod wraps the Future in AsyncValue
/// automatically, providing loading / data / error states out of the box.
///
/// Watches locationProvider so that when the location changes (GPS or city override),
/// the forecast is automatically re-fetched for the new location.
///
/// No BuildContext dependency — fully testable in isolation via ProviderContainer.
final class WeatherNotifierProvider
    extends $AsyncNotifierProvider<WeatherNotifier, List<HourlyForecast>> {
  /// WeatherNotifier fetches the forecast via WeatherRepository and exposes it
  /// as `AsyncValue<List<HourlyForecast>>`. Riverpod wraps the Future in AsyncValue
  /// automatically, providing loading / data / error states out of the box.
  ///
  /// Watches locationProvider so that when the location changes (GPS or city override),
  /// the forecast is automatically re-fetched for the new location.
  ///
  /// No BuildContext dependency — fully testable in isolation via ProviderContainer.
  WeatherNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'weatherProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$weatherNotifierHash();

  @$internal
  @override
  WeatherNotifier create() => WeatherNotifier();
}

String _$weatherNotifierHash() => r'28d97e2ae3a24e6dce839c89cc63f8ada1da0f89';

/// WeatherNotifier fetches the forecast via WeatherRepository and exposes it
/// as `AsyncValue<List<HourlyForecast>>`. Riverpod wraps the Future in AsyncValue
/// automatically, providing loading / data / error states out of the box.
///
/// Watches locationProvider so that when the location changes (GPS or city override),
/// the forecast is automatically re-fetched for the new location.
///
/// No BuildContext dependency — fully testable in isolation via ProviderContainer.

abstract class _$WeatherNotifier extends $AsyncNotifier<List<HourlyForecast>> {
  FutureOr<List<HourlyForecast>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<List<HourlyForecast>>, List<HourlyForecast>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<HourlyForecast>>, List<HourlyForecast>>,
        AsyncValue<List<HourlyForecast>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
