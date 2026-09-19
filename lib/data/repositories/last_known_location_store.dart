import 'package:shared_preferences/shared_preferences.dart';

/// De laatste positie die de app werkelijk gemeten heeft.
///
/// **Waarom dit buiten `profile.*` staat.** Het profiel wordt naar Supabase
/// gesynct en komt op je andere toestellen terug. Een gemeten positie hoort
/// daar niet bij: hij zegt iets over dit toestel op dit moment, niet over de
/// gebruiker. Vandaar een eigen sleutelruimte `location.*`, alleen lokaal.
///
/// **Waarom een aparte klasse en geen veld in ProfileRepository.** De
/// WorkManager-isolate moet hem ook kunnen lezen, en die heeft geen Flutter.
/// Deze klasse raakt daarom niets buiten `shared_preferences` (REG-05).
class LastKnownLocationStore {
  LastKnownLocationStore(this._prefs);

  final SharedPreferences _prefs;

  static const kLatKey = 'location.lastLat';
  static const kLonKey = 'location.lastLon';
  static const kAtKey = 'location.lastAtMillis';

  /// De laatst gemeten positie, of null als er nog nooit een peiling lukte.
  LastKnownLocation? read() {
    final lat = _prefs.getDouble(kLatKey);
    final lon = _prefs.getDouble(kLonKey);
    final at = _prefs.getInt(kAtKey);
    if (lat == null || lon == null || at == null) return null;
    return LastKnownLocation(
      lat: lat,
      lon: lon,
      at: DateTime.fromMillisecondsSinceEpoch(at),
    );
  }

  /// Leg een geslaagde peiling vast. [now] is injecteerbaar voor tests.
  Future<void> write({
    required double lat,
    required double lon,
    DateTime? now,
  }) async {
    await _prefs.setDouble(kLatKey, lat);
    await _prefs.setDouble(kLonKey, lon);
    await _prefs.setInt(
      kAtKey,
      (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }
}

class LastKnownLocation {
  const LastKnownLocation({
    required this.lat,
    required this.lon,
    required this.at,
  });

  final double lat;
  final double lon;
  final DateTime at;
}
