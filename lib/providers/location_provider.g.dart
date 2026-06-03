// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(location)
final locationProvider = LocationProvider._();

final class LocationProvider
    extends $FunctionalProvider<LocationData, LocationData, LocationData>
    with $Provider<LocationData> {
  LocationProvider._()
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
  String debugGetCreateSourceHash() => _$locationHash();

  @$internal
  @override
  $ProviderElement<LocationData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocationData create(Ref ref) {
    return location(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationData>(value),
    );
  }
}

String _$locationHash() => r'b037bf9dbbed0b7ad55e2872de3c8e2034d89296';
