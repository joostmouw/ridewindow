import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/core/platform_info.dart';

part 'gps_permission_notifier.g.dart';

/// Beheert de GPS-toestemmings-state machine.
/// Gegenereerde providernaam: gpsPermissionProvider
@riverpod
class GpsPermissionNotifier extends _$GpsPermissionNotifier {
  @override
  Future<LocationPermission> build() async {
    return Geolocator.checkPermission();
  }

  /// Vraag toestemming op; update state op basis van resultaat.
  Future<LocationPermission> requestPermission() async {
    final result = await Geolocator.requestPermission();
    state = AsyncData(result);
    return result;
  }

  /// Deep-link naar app-instellingen (deniedForever geval, LOC-04).
  ///
  /// LOC-07: `permission_handler`'s `openAppSettings()` has no web
  /// implementation and throws `UnsupportedError` on web (geolocator_web's
  /// underlying gap). Short-circuit here so this method is a safe no-op on
  /// web; `ProfileScreen` shows browser-specific guidance copy instead
  /// (Task 2 of this plan) and hides the settings button entirely on web.
  Future<void> openSettings() async {
    if (isWebPlatform) return;
    await openAppSettings();
  }
}
