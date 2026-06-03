import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ridewindow/core/config.dart';
import 'package:ridewindow/core/nl_cities.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';

part 'location_provider.g.dart';

/// Locatie-data voor de weersvoorspelling.
class LocationData {
  const LocationData({
    required this.lat,
    required this.lon,
    required this.city,
  });
  final double lat;
  final double lon;
  final String city;
}

/// Gegenereerde providernaam: locationProvider (Notifier-suffix gestript door code-gen).
/// Bestaande consumers (HomeScreen, WeatherNotifier) blijven ongewijzigd.
@riverpod
class LocationNotifier extends _$LocationNotifier {
  @override
  Future<LocationData> build() async {
    // Stap 1: check city override uit profile (LOC-05: override heeft voorrang)
    final profile = await ref.watch(profileProvider.future);
    final override = profile.locationOverride;
    if (override != null) {
      final city = kNlCities.firstWhere(
        (c) => c.name == override,
        orElse: () => kNlCities.first,
      );
      return LocationData(lat: city.lat, lon: city.lon, city: city.name);
    }

    // Stap 2: check GPS-toestemming
    final permission = await ref.watch(gpsPermissionProvider.future);
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.reduced,
            timeLimit: Duration(seconds: 30),
          ),
        );
        return LocationData(
          lat: pos.latitude,
          lon: pos.longitude,
          city: 'GPS',
        );
      } catch (_) {
        // Timeout of andere fout — val door naar default (T-07-02-02 mitigatie)
      }
    }

    // Stap 3: fallback naar Amsterdam default (LOC-04)
    return const LocationData(
      lat: kDefaultLat,
      lon: kDefaultLon,
      city: kDefaultCity,
    );
  }
}
