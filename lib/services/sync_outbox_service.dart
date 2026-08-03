import 'dart:convert';

import 'package:ridewindow/data/database/daos/sync_outbox_dao.dart';

/// Drains the offline outbox (SYNC-05). Deliberately network-agnostic: the
/// actual cloud upsert/delete calls are injected by the caller, so this
/// class never imports the cloud SDK and stays fully unit testable without
/// mocking a fluent query builder.
class SyncOutboxService {
  SyncOutboxService(this._dao);

  final SyncOutboxDao _dao;

  /// Drains every pending row. [upsertFn] and [deleteFn] are injected by the
  /// caller (Wave 3's AccountSyncService/repositories), which is where the
  /// real cloud client's `.from(table).upsert(row)` / `.delete()...` calls
  /// live — this class never imports the cloud SDK itself, which keeps it
  /// trivially unit-testable and keeps it out of any import graph REG-05
  /// cares about.
  Future<void> drain({
    required Future<void> Function(
      String entity,
      String entityKey,
      Map<String, dynamic> payload,
    ) upsertFn,
    required Future<void> Function(String entity, String entityKey) deleteFn,
  }) async {
    final rows = await _dao.pendingRows();
    for (final row in rows) {
      try {
        if (row.operation == 'delete') {
          await deleteFn(row.entity, row.entityKey);
        } else {
          await upsertFn(
            row.entity,
            row.entityKey,
            jsonDecode(row.payload) as Map<String, dynamic>,
          );
        }
        await _dao.markSent(row.id);
      } catch (e) {
        await _dao.markFailed(row.id, e.toString());
        // Deliberately continue to the next row rather than abort the whole
        // drain — one failing entity must not block every other pending row.
      }
    }
  }
}
