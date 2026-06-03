import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ridewindow/core/config.dart';

part 'location_provider.g.dart';

/// Locatie-data voor de weersvoorspelling.
/// Phase 7 vervangt deze stub met echte geolocator-aanroep.
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

@riverpod
LocationData location(Ref ref) {
  // Phase 7: vervang door ref.watch(gpsLocationProvider)
  return const LocationData(
    lat: kDefaultLat,
    lon: kDefaultLon,
    city: kDefaultCity,
  );
}
