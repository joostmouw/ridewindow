import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:ridewindow/data/database/daos/sync_outbox_dao.dart';

/// Drains the offline outbox (SYNC-05). Deliberately network-agnostic: the
/// actual cloud upsert/delete calls are injected by the caller, so this
/// class never imports the cloud SDK and stays fully unit testable without
/// mocking a fluent query builder.
class SyncOutboxService {
  SyncOutboxService(this._dao);

  final SyncOutboxDao _dao;

  /// A row that has failed to send this many times in a row is dropped
  /// instead of retried again (plan 21-12). Deliberately NOT a backoff
  /// schedule or a retry policy — REQUIREMENTS.md puts scheduled/backoff
  /// retry out of scope for this phase (restated in 21-10/21-11). This is a
  /// bounded refusal to keep silently retrying a payload that has already
  /// proven, this many times in a row, that it cannot be sent — e.g. the
  /// shape defect this plan fixes, where every single attempt failed the
  /// exact same way forever.
  ///
  /// Chosen small on purpose: `drain()` runs on every foreground cycle
  /// (`CloudSyncReconciler.reconcileOnForeground()`) and right after
  /// sign-in, so 5 strikes means a wedged device clears within a handful of
  /// app-switches — recovering visibly, not "forever" (the actual defect
  /// this plan fixes), while still being high enough that a couple of
  /// genuinely transient failures (e.g. two bad network blips in a row)
  /// don't get mistaken for a permanently-broken payload.
  static const kMaxSendAttempts = 5;

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
        final attemptNumber = row.attempts + 1;
        // The one debugPrint every failure gets — this is the part that
        // would have saved the whole 21-10/21-11/21-12 session: previously
        // markFailed() swallowed the error into a database column with no
        // logcat trace at all. A drain where every row succeeds logs
        // nothing.
        debugPrint(
          'SyncOutboxService: send failed for ${row.entity}/${row.entityKey} '
          '(attempt $attemptNumber/$kMaxSendAttempts): $e',
        );
        if (attemptNumber >= kMaxSendAttempts) {
          // Crossed the ceiling — drop it instead of leaving it pending
          // forever. The row is gone, so this is the only record of why;
          // log loudly rather than let it vanish silently.
          await _dao.dropRow(row.id);
          debugPrint(
            'SyncOutboxService: dropping ${row.entity}/${row.entityKey} '
            'after $attemptNumber failed attempts — it will not be retried '
            'again. Last error: $e',
          );
        } else {
          await _dao.markFailed(row.id, e.toString());
        }
        // Deliberately continue to the next row rather than abort the whole
        // drain — one failing entity must not block every other pending row.
      }
    }
  }
}
