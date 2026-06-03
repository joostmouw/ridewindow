// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Gegenereerde providernaam: locationProvider (Notifier-suffix gestript door code-gen).
/// Bestaande consumers (HomeScreen, WeatherNotifier) blijven ongewijzigd.

@ProviderFor(LocationNotifier)
final locationProvider = LocationNotifierProvider._();

/// Gegenereerde providernaam: locationProvider (Notifier-suffix gestript door code-gen).
/// Bestaande consumers (HomeScreen, WeatherNotifier) blijven ongewijzigd.
final class LocationNotifierProvider
    extends $AsyncNotifierProvider<LocationNotifier, LocationData> {
  /// Gegenereerde providernaam: locationProvider (Notifier-suffix gestript door code-gen).
  /// Bestaande consumers (HomeScreen, WeatherNotifier) blijven ongewijzigd.
  LocationNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'locationProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$locationNotifierHash();

  @$internal
  @override
  LocationNotifier create() => LocationNotifier();
}

String _$locationNotifierHash() => r'dba8db1047e13d9d94372f84a1806a8eb37bce35';

/// Gegenereerde providernaam: locationProvider (Notifier-suffix gestript door code-gen).
/// Bestaande consumers (HomeScreen, WeatherNotifier) blijven ongewijzigd.

abstract class _$LocationNotifier extends $AsyncNotifier<LocationData> {
  FutureOr<LocationData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LocationData>, LocationData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<LocationData>, LocationData>,
        AsyncValue<LocationData>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
