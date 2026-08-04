import 'dart:convert';

import 'package:ridewindow/data/database/daos/sync_outbox_dao.dart';

/// Drains the offline outbox (SYNC-05). Deliberately network-agnostic: the
/// actual cloud upsert/delete calls are injected by the caller, so this
/// class never imports the cloud SDK and stays fully unit testable without
/// mocking a fluent query builder.
class SyncOutboxService {
  SyncOutboxService(this._dao);

  final SyncOutboxDao _dao;

  /// Guards against a second `drain()` call racing an in-flight one (plan
  /// 21-10's re-entrancy requirement): `CloudSyncReconciler` now calls
  /// `drain()` both from the foreground path and right after sign-in, and
  /// those two triggers can legitimately overlap (e.g. a foreground event
  /// firing while a post-sign-in drain is still running its network calls).
  /// Without this guard, a second call would re-fetch `pendingRows()` before
  /// the first call's `markSent()` has removed them, sending the same row to
  /// `upsertFn`/`deleteFn` twice. A concurrent second call is deliberately
  /// coalesced into the first call's already-running [Future] rather than
  /// started as its own drain — its own `upsertFn`/`deleteFn` closures are
  /// never invoked, only the first caller's are.
  Future<void>? _inFlightDrain;

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
  }) {
    final existing = _inFlightDrain;
    if (existing != null) return existing;

    final future = _drainInternal(upsertFn: upsertFn, deleteFn: deleteFn);
    _inFlightDrain = future;
    return future.whenComplete(() => _inFlightDrain = null);
  }

  Future<void> _drainInternal({
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
