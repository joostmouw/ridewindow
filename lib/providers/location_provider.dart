import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridewindow/core/cities.dart';
import 'package:ridewindow/core/config.dart';
import 'package:ridewindow/data/repositories/last_known_location_store.dart';
import 'package:ridewindow/domain/services/timezone_sanity.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';

part 'location_provider.g.dart';

/// Waar de getoonde plek vandaan komt. De UI moet dit kunnen zien: een positie
/// die we gemeten hebben is iets heel anders dan een standaard waar we op zijn
/// teruggevallen, en dat verschil was tot nu toe onzichtbaar.
enum LocationSource {
  /// De gebruiker koos zelf een stad.
  override,

  /// Vers gemeten met GPS.
  gps,

  /// De laatste geslaagde peiling; GPS gaf nu niets.
  lastKnown,

  /// Niets bekend -- Amsterdam, omdat we iets moeten tonen.
  fallback,
}

/// Locatie-data voor de weersvoorspelling.
class LocationData {
  const LocationData({
    required this.lat,
    required this.lon,
    required this.city,
    required this.source,
    this.measuredAt,
  });

  final double lat;
  final double lon;
  final String city;
  final LocationSource source;

  /// Wanneer deze positie gemeten is. Null voor [LocationSource.override] en
  /// [LocationSource.fallback] -- die zijn niet gemeten.
  final DateTime? measuredAt;

  /// Weten we werkelijk waar de gebruiker is, of tonen we een aanname?
  bool get isGuess => source == LocationSource.fallback;

  /// Staat de klok van dit toestel op een ander werelddeel dan deze plek?
  /// Zie `timezone_sanity.dart` voor waarom dit een benadering mag zijn.
  bool get clockMismatch => clockLooksForeign(
        lon: lon,
        deviceOffset: DateTime.now().timeZoneOffset,
      );

  /// Moet de gebruiker hierover iets te horen krijgen op Home?
  bool get needsWarning => isGuess || clockMismatch;
}

/// Gegenereerde providernaam: locationProvider (Notifier-suffix gestript door code-gen).
/// Bestaande consumers (HomeScreen, WeatherNotifier) blijven ongewijzigd.
@riverpod
class LocationNotifier extends _$LocationNotifier {
  @override
  Future<LocationData> build() async {
    // Bewust `getInstance()` en niet `sharedPrefsProvider`, om dezelfde reden
    // als profile_notifier.dart: die provider gooit UnimplementedError tenzij
    // hij overschreven is, en de tests leunen op setMockInitialValues.
    final store = LastKnownLocationStore(await SharedPreferences.getInstance());

    // Stap 1: check city override uit profile (LOC-05: override heeft voorrang)
    final profile = await ref.watch(profileProvider.future);
    final override = profile.locationOverride;
    if (override != null) {
      final city = kCities.firstWhere(
        (c) => c.name == override,
        orElse: () => kCities.first,
      );
      return LocationData(
        lat: city.lat,
        lon: city.lon,
        city: city.name,
        source: LocationSource.override,
      );
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
        // Vastleggen, zodat de achtergrondtaak -- die geen GPS kan vragen --
        // dezelfde plek gebruikt als dit scherm. Zonder dit overschreef die
        // taak elke drie uur de verse voorspelling met die van Amsterdam.
        await store.write(lat: pos.latitude, lon: pos.longitude);
        return LocationData(
          lat: pos.latitude,
          lon: pos.longitude,
          city: kGpsCityLabel,
          source: LocationSource.gps,
          measuredAt: DateTime.now(),
        );
      } catch (_) {
        // Timeout of andere fout — val door naar stap 3 (T-07-02-02 mitigatie)
      }
    }

    // Stap 3: de laatste peiling die wél lukte. Op iOS-Safari is dit niet de
    // uitzondering maar de regel: die vraagt toestemming elke sessie opnieuw,
    // dus zonder dit geheugen begint elke sessie in Amsterdam.
    final last = store.read();
    if (last != null) {
      return LocationData(
        lat: last.lat,
        lon: last.lon,
        city: kGpsCityLabel,
        source: LocationSource.lastKnown,
        measuredAt: last.at,
      );
    }

    // Stap 4: fallback naar Amsterdam default (LOC-04). Dit is een gok en de
    // app hoort dat te zeggen -- zie LocationData.isGuess.
    return const LocationData(
      lat: kDefaultLat,
      lon: kDefaultLon,
      city: kDefaultCity,
      source: LocationSource.fallback,
    );
  }
}
