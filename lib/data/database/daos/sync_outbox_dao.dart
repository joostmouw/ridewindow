import 'package:drift/drift.dart';
import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/database/tables/sync_outbox_entries.dart';

part 'sync_outbox_dao.g.dart';

@DriftAccessor(tables: [SyncOutboxEntries])
class SyncOutboxDao extends DatabaseAccessor<AppDatabase>
    with _$SyncOutboxDaoMixin {
  SyncOutboxDao(super.db);

  /// Inserts a new pending row for (entity, entityKey), or — if one already
  /// exists — overwrites its operation/payload/queuedAt and resets
  /// attempts/lastError to a clean state. This is what makes five rapid
  /// local writes to the same entity leave exactly one outbox row.
  Future<void> enqueueOrCoalesce({
    required String entity,
    required String entityKey,
    required String operation,
    required String payload,
  }) {
    final companion = SyncOutboxEntriesCompanion.insert(
      entity: entity,
      entityKey: entityKey,
      operation: Value(operation),
      payload: payload,
      queuedAt: DateTime.now().millisecondsSinceEpoch,
      attempts: const Value(0),
      lastError: const Value(null),
    );
    return into(syncOutboxEntries).insert(
      companion,
      onConflict: DoUpdate(
        (_) => companion,
        target: [syncOutboxEntries.entity, syncOutboxEntries.entityKey],
      ),
    );
  }

  /// All pending rows, ready to be drained.
  Future<List<SyncOutboxEntry>> pendingRows() {
    return select(syncOutboxEntries).get();
  }

  /// Emits the current pending row count, updating live as rows are
  /// enqueued/removed. Backs the SYNC-06 sync status indicator.
  Stream<int> watchPendingCount() {
    final countExp = syncOutboxEntries.id.count();
    final query = selectOnly(syncOutboxEntries)..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// A row was successfully sent — remove it entirely.
  Future<void> markSent(int id) {
    return (delete(syncOutboxEntries)..where((t) => t.id.equals(id))).go();
  }

  /// A row failed to send — increment its attempt counter and record the
  /// error, but leave it pending for the next drain.
  Future<void> markFailed(int id, String error) async {
    final row = await (select(syncOutboxEntries)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    await (update(syncOutboxEntries)..where((t) => t.id.equals(id))).write(
      SyncOutboxEntriesCompanion(
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  /// A row has crossed [SyncOutboxService.kMaxSendAttempts] and will never
  /// be retried again — permanently removes it. Same underlying delete as
  /// [markSent] (both take the row out of the table entirely), kept as a
  /// separate name so a drain log line reading "dropped" vs. "sent" is
  /// unambiguous about which one happened. Because this is a hard delete,
  /// [pendingRows]/[watchPendingCount] — both unfiltered selects over this
  /// table — automatically stop counting a dropped row; there is no
  /// separate "dropped" flag to filter on.
  Future<void> dropRow(int id) {
    return (delete(syncOutboxEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Verwijdert elke openstaande rij en geeft terug hoeveel er weg zijn.
  ///
  /// Alleen gebruikt door het verborgen debugmenu ("Inspect sync outbox"): het
  /// laat een vastgelopen outbox op het toestel zelf legen, waarmee "oude
  /// rijen die nooit meer weg gaan" te onderscheiden is van "de drain faalt
  /// structureel" — na een wis blijft de teller op 0, of hij klimt meteen
  /// terug. Geen enkel productiepad roept dit aan; daar verdwijnen rijen
  /// alleen via [markSent] (bevestigde send) of [dropRow] (attempt-plafond).
  Future<int> clearAll() {
    return delete(syncOutboxEntries).go();
  }
}
