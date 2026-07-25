// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gps_permission_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Beheert de GPS-toestemmings-state machine.
/// Gegenereerde providernaam: gpsPermissionProvider

@ProviderFor(GpsPermissionNotifier)
final gpsPermissionProvider = GpsPermissionNotifierProvider._();

/// Beheert de GPS-toestemmings-state machine.
/// Gegenereerde providernaam: gpsPermissionProvider
final class GpsPermissionNotifierProvider
    extends $AsyncNotifierProvider<GpsPermissionNotifier, LocationPermission> {
  /// Beheert de GPS-toestemmings-state machine.
  /// Gegenereerde providernaam: gpsPermissionProvider
  GpsPermissionNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'gpsPermissionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$gpsPermissionNotifierHash();

  @$internal
  @override
  GpsPermissionNotifier create() => GpsPermissionNotifier();
}

String _$gpsPermissionNotifierHash() =>
    r'a9f8b1c7440f066015442e31b87e0cd717d3b4f7';

/// Beheert de GPS-toestemmings-state machine.
/// Gegenereerde providernaam: gpsPermissionProvider

abstract class _$GpsPermissionNotifier
    extends $AsyncNotifier<LocationPermission> {
  FutureOr<LocationPermission> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<LocationPermission>, LocationPermission>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<LocationPermission>, LocationPermission>,
        AsyncValue<LocationPermission>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
