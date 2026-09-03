import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/database/daos/sync_outbox_dao.dart';
import 'package:ridewindow/data/database/sync_outbox_entity_types.dart';
import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/services/availability_key.dart';

/// Enige bron van waarheid voor de opslag van geblokkeerde beschikbaarheidsuren.
///
/// Persistentie via SharedPreferences: entries worden opgeslagen als
/// "ISO8601|blocktype" strings (bv. "2026-06-14T09:00:00.000Z|custom")
/// onder de sleutel [kBlockedHoursKey].
///
/// [outbox]/[userId] zijn optioneel en additief (ARCHITECTURE.md §4a): als
/// beide gezet zijn (signed-in), enqueuet elke [save] precies één
/// cloud-schrijving via de outbox (SYNC-12), ongeacht hoeveel uren wijzigden
/// in die aanroep. Zonder outbox/userId is dit een stille no-op, exact zoals
/// het patroon dat dit vervangt. Deze klasse importeert bewust nooit de
/// cloud-SDK zelf (REG-05) — de outbox is een Drift-only afhankelijkheid.
///
/// De enqueuede payload is `{'user_id': userId, 'recurring': toRecurringRow(hours)}`
/// — een echte rij voor `public.availability` (`user_id`, `recurring`,
/// `version`, `updated_at`), niet de kale `toRecurringRow(hours)`-map zelf.
/// Vóór plan 21-12 werd die kale map rechtstreeks geënqueued, waardoor
/// PostgREST weekday-hour sleutels ("1-9", "6-14") als kolomnamen kreeg
/// aangeboden — een schrijving die nooit kon slagen. Zie
/// `test/data/database/outbox_payload_shape_test.dart` voor de invariant die
/// dit nu bewaakt.
class AvailabilityRepository {
  AvailabilityRepository(this._prefs, {SyncOutboxDao? outbox, this.userId})
      : _outbox = outbox;

  final SharedPreferences _prefs;
  final SyncOutboxDao? _outbox;
  final String? userId;

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
  ///
  /// [enqueue] false betekent: deze schrijving kwam *uit* de cloud, dus hij
  /// hoeft er niet naartoe. Zie [ProfileRepository.save] voor de volledige
  /// redenering — dit is dezelfde lus (backlog #57), met dezelfde
  /// `before update`-trigger op `public.availability`.
  Future<void> save(
    Map<DateTime, BlockType> hours, {
    bool stamp = true,
    bool enqueue = true,
  }) async {
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

    if (enqueue && _outbox != null && userId != null) {
      await _outbox.enqueueOrCoalesce(
        entity: kOutboxEntityAvailability,
        entityKey: userId!,
        operation: 'upsert',
        payload: jsonEncode({'user_id': userId!, 'recurring': toRecurringRow(hours)}),
      );
    }
  }

  /// Zet [kUpdatedAtKey] op een expliciete waarde in plaats van "nu" — alleen
  /// gebruikt bij het overnemen van een gepulde cloud-rij (zie
  /// [ProfileRepository.stampUpdatedAt] voor dezelfde redenering).
  Future<void> stampUpdatedAt(DateTime value) =>
      _prefs.setInt(kUpdatedAtKey, value.millisecondsSinceEpoch);

  /// Geeft het epoch-ms tijdstip van de laatste [save]-aanroep, of `null` als
  /// dat veld nog nooit geschreven is.
  ///
  /// Een ontbrekende waarde wordt hier **niet** retroactief op "nu" gezet
  /// (D-08). Fase 20 leest dit veld nergens om iets te beslissen — de getter
  /// bestaat voor fase 21.
  int? readUpdatedAt() => _prefs.getInt(kUpdatedAtKey);

  /// Enqueuet de *huidige* lokale uren naar de outbox, zonder lokale opslag
  /// of tijdstempel te herschrijven (plan 21-06's `AccountSyncService`).
  /// Alleen gebruikt wanneer een divergentie oplost naar "push local" — de
  /// lokale data is al correct, die moet alleen nog de cloud bereiken.
  /// Stille no-op zonder outbox/userId.
  Future<void> enqueueCurrentState() async {
    if (_outbox == null || userId == null) return;
    final hours = readLocal();
    await _outbox.enqueueOrCoalesce(
      entity: kOutboxEntityAvailability,
      entityKey: userId!,
      operation: 'upsert',
      payload: jsonEncode({'user_id': userId!, 'recurring': toRecurringRow(hours)}),
    );
  }
}
