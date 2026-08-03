import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/database/daos/sync_outbox_dao.dart';
import 'package:ridewindow/data/database/sync_outbox_entity_types.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';

/// Enige bron van waarheid voor de sleutel `planned_rides` in SharedPreferences.
///
/// Persistentie via SharedPreferences: een JSON-lijst van [PlannedRide.toJson]
/// onder de sleutel [kPlannedRidesKey], ongewijzigd ten opzichte van hoe
/// `PlannedRidesNotifier` dit altijd al opsloeg (D-01).
///
/// [outbox]/[userId] zijn optioneel en additief (ARCHITECTURE.md §4a).
/// Anders dan [ProfileRepository]/[AvailabilityRepository] enqueuet niet
/// `save()` zelf een cloud-schrijving — `planned_rides` is een groeiende
/// lijst van losse rijen, geen enkele mutabele blob, dus [add]/[remove]
/// enqueuen elk precies één per-rit outbox-rij (upsert/delete). `save()`
/// blijft de kale lokale schrijfoperatie, gebruikt door de foreground-
/// reconciler om de samengevoegde lijst weg te schrijven zonder een tweede
/// keer te enqueuen. Deze klasse importeert bewust nooit de cloud-SDK zelf
/// (REG-05) — de outbox is een Drift-only afhankelijkheid.
class PlannedRidesRepository {
  PlannedRidesRepository(this._prefs, {SyncOutboxDao? outbox, this.userId})
      : _outbox = outbox;

  final SharedPreferences _prefs;
  final SyncOutboxDao? _outbox;
  final String? userId;

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

  /// Verhuisd uit `PlannedRidesNotifier.add()` — dezelfde dedup-op-start/end
  /// check, dezelfde sortering op start. Enqueuet daarnaast precies één
  /// 'upsert' outbox-rij voor deze ene rit wanneer ingelogd.
  Future<void> add(PlannedRide ride) async {
    final current = readLocal();
    if (current.any((r) => r.start == ride.start && r.end == ride.end)) {
      return;
    }
    final next = [...current, ride]..sort((a, b) => a.start.compareTo(b.start));
    await save(next);
    if (_outbox != null && userId != null) {
      await _outbox.enqueueOrCoalesce(
        entity: kOutboxEntityPlannedRide,
        entityKey: '${userId!}:${ride.rideId}',
        operation: 'upsert',
        payload: jsonEncode(ride.toRow(userId!)),
      );
    }
  }

  /// Verhuisd uit `PlannedRidesNotifier.remove()`. Enqueuet een 'delete'
  /// outbox-rij voor precies deze rit — de payload is `'{}'`, omdat de
  /// drain-stap het delete-filter (user_id + ride_id) uit `entityKey` haalt,
  /// niet uit de payload.
  Future<void> remove(PlannedRide ride) async {
    final current = readLocal();
    final next =
        current.where((r) => r.start != ride.start || r.end != ride.end).toList();
    await save(next);
    if (_outbox != null && userId != null) {
      await _outbox.enqueueOrCoalesce(
        entity: kOutboxEntityPlannedRide,
        entityKey: '${userId!}:${ride.rideId}',
        operation: 'delete',
        payload: '{}',
      );
    }
  }

  /// Alleen gebruikt door de foreground-reconciler (plan 21-05's
  /// `CloudSyncReconciler`) om een rit die lokaal al bestaat maar nog niet in
  /// de cloud staat te pushen, zonder [add]'s dedup/[save] opnieuw te
  /// draaien (de rit staat al in de lokale lijst).
  Future<void> enqueueUpsert(PlannedRide ride) async {
    if (_outbox == null || userId == null) return;
    await _outbox.enqueueOrCoalesce(
      entity: kOutboxEntityPlannedRide,
      entityKey: '${userId!}:${ride.rideId}',
      operation: 'upsert',
      payload: jsonEncode(ride.toRow(userId!)),
    );
  }
}
