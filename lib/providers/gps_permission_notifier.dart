import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
