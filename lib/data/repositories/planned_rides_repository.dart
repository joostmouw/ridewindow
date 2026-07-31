import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/planned_ride.dart';

/// Enige bron van waarheid voor de sleutel `planned_rides` in SharedPreferences.
///
/// Persistentie via SharedPreferences: een JSON-lijst van [PlannedRide.toJson]
/// onder de sleutel [kPlannedRidesKey], ongewijzigd ten opzichte van hoe
/// `PlannedRidesNotifier` dit altijd al opsloeg (D-01).
class PlannedRidesRepository {
  PlannedRidesRepository(this._prefs);

  final SharedPreferences _prefs;

  static const kPlannedRidesKey = 'planned_rides';
  static const kUpdatedAtKey = 'planned_rides.updatedAt';

  /// Leest de geplande ritten van schijf, synchroon — `_prefs` is al ingeladen.
  ///
  /// Filtert ritten die al voorbij zijn (`end` niet meer na het begin van
  /// vandaag) en sorteert het resultaat op `start`. Dit hoort bij de
  /// leesoperatie zelf, net als `AvailabilityRepository.readLocal()`'s
  /// `normalizeBlockedHours()`-aanroep.
  List<PlannedRide> readLocal() {
    final raw = _prefs.getString(kPlannedRidesKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return list
        .map(PlannedRide.fromJson)
        .where((r) => r.end.isAfter(todayStart))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Schrijft [rides] weg in het bestaande formaat. Als [stamp] true is
  /// (default), wordt [kUpdatedAtKey] bijgewerkt naar nu (epoch-ms).
  Future<void> save(List<PlannedRide> rides, {bool stamp = true}) async {
    final json = jsonEncode(rides.map((r) => r.toJson()).toList());
    await _prefs.setString(kPlannedRidesKey, json);
    if (stamp) {
      await _prefs.setInt(
        kUpdatedAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  /// Geeft het epoch-ms tijdstip van de laatste [save]-aanroep, of `null` als
  /// dat veld nog nooit geschreven is.
  ///
  /// Een ontbrekende waarde wordt hier **niet** retroactief op "nu" gezet
  /// (D-08). Fase 20 leest dit veld nergens om iets te beslissen — de getter
  /// bestaat voor fase 21.
  int? readUpdatedAt() => _prefs.getInt(kUpdatedAtKey);
}
