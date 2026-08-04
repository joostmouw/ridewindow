import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:ridewindow/data/database/daos/sync_outbox_dao.dart';

/// Drains the offline outbox (SYNC-05). Deliberately network-agnostic: the
/// actual cloud upsert/delete calls are injected by the caller, so this
/// class never imports the cloud SDK and stays fully unit testable without
/// mocking a fluent query builder.
class SyncOutboxService {
  SyncOutboxService(this._dao, {void Function(String message)? log})
      : _log = log ?? _debugPrintLog;

  final SyncOutboxDao _dao;

  /// Where this service's diagnostics go. Injectable purely so a test can
  /// assert on them (plan 21-12) — production always gets `debugPrint`,
  /// matching `CloudSyncReconciler`'s own logging.
  final void Function(String message) _log;

  static void _debugPrintLog(String message) => debugPrint(message);

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
    var sent = 0;
    var failed = 0;
    // Plan 21-13: which entities actually went through. The first version of
    // this logging only counted them, and that cost a full verification round:
    // a drain reported "1 sent" while the `availability` row in Postgres was
    // provably untouched, and there was no way to tell from the log which row
    // that success belonged to. A count alone is not attributable.
    final sentEntities = <String>[];

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
        sent++;
        sentEntities.add(row.entity);
      } catch (e) {
        await _dao.markFailed(row.id, e.toString());
        failed++;
        // Plan 21-12: this log line is the whole point. Before it existed the
        // error went only into Drift's `lastError` column, which nothing read
        // or displayed, so a drain that failed on every single row looked
        // exactly like a drain that had nothing to do. `attempts` is the
        // pre-increment value from the row we just read, so +1 is the attempt
        // that just failed.
        _log(
          'SyncOutbox: send failed for ${row.entity}/${row.entityKey} '
          '(operation=${row.operation}, attempt ${row.attempts + 1}): $e',
        );
        // Deliberately continue to the next row rather than abort the whole
        // drain — one failing entity must not block every other pending row.
      }
    }

    // Always emitted, including for an empty outbox: "0 pending" and "the
    // drain never ran at all" are the two states this phase has repeatedly
    // confused, and only a line that is present in the first case can tell
    // them apart.
    final sentDetail = sentEntities.isEmpty ? '' : ' (${sentEntities.join(', ')})';
    _log(
      'SyncOutbox: drain done — ${rows.length} pending, $sent sent$sentDetail, '
      '$failed failed',
    );
  }
}
