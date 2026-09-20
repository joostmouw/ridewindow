import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/units.dart';

/// Waar de eenheidskeuze ligt: op dit toestel, in zijn eigen sleutelruimte.
///
/// Dezelfde afweging als bij `location.*` en `analytics.*`: dit hoort bij het
/// scherm waar je naar kijkt, niet bij je account. Zie de klassenoot van
/// [UnitPrefs] voor waarom dat hier de juiste plek is.
class UnitPrefsStore {
  UnitPrefsStore(this._prefs);

  final SharedPreferences _prefs;

  static const kTempKey = 'units.temp';
  static const kWindKey = 'units.wind';

  UnitPrefs read() => UnitPrefs(
        temp: TempUnit.fromKey(_prefs.getString(kTempKey)),
        wind: WindUnit.fromKey(_prefs.getString(kWindKey)),
      );

  Future<void> writeTemp(TempUnit unit) async {
    await _prefs.setString(kTempKey, unit.key);
  }

  Future<void> writeWind(WindUnit unit) async {
    await _prefs.setString(kWindKey, unit.key);
  }
}
