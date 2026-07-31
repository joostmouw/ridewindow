import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/services/availability_key.dart';

/// Enige bron van waarheid voor de opslag van geblokkeerde beschikbaarheidsuren.
///
/// Persistentie via SharedPreferences: entries worden opgeslagen als
/// "ISO8601|blocktype" strings (bv. "2026-06-14T09:00:00.000Z|custom")
/// onder de sleutel [kBlockedHoursKey].
class AvailabilityRepository {
  AvailabilityRepository(this._prefs);

  final SharedPreferences _prefs;

  static const kBlockedHoursKey = 'availability.blockedHours';
  static const kUpdatedAtKey = 'availability.updatedAt';

  /// Leest de geblokkeerde uren van schijf, synchroon — `_prefs` is al ingeladen.
  Map<DateTime, BlockType> readLocal() {
    final strings = _prefs.getStringList(kBlockedHoursKey) ?? [];
    final result = <DateTime, BlockType>{};
    for (final entry in strings) {
      try {
        final parts = entry.split('|');
        if (parts.length == 2) {
          final dt = DateTime.parse(parts[0]);
          final blockType = BlockType.values.byName(parts[1]);
          result[dt] = blockType;
        }
      } catch (_) {
        // Corrupte entries worden overgeslagen (T-04-01: Tampering via SharedPreferences)
      }
    }
    // Bestaande installs hebben zowel UTC- als lokale sleutels opgeslagen; alles
    // wordt hier op de canonieke vorm gebracht zodat oude blokken blijven werken.
    return normalizeBlockedHours(result);
  }

  /// Schrijft [hours] weg in het bestaande formaat. Als [stamp] true is
  /// (default), wordt [kUpdatedAtKey] bijgewerkt naar nu (epoch-ms).
  Future<void> save(Map<DateTime, BlockType> hours, {bool stamp = true}) async {
    await _prefs.setStringList(
      kBlockedHoursKey,
      hours.entries
          .map((e) => '${e.key.toIso8601String()}|${e.value.name}')
          .toList(),
    );
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
