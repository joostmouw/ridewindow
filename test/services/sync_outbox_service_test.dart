import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/services/sync_outbox_service.dart';

void main() {
  late AppDatabase db;
  late SyncOutboxService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = SyncOutboxService(db.syncOutboxDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncOutboxService.drain', () {
    test(
      'calls upsertFn for upsert rows and deleteFn for delete rows, then clears them all',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'profile',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: jsonEncode({'a': 1}),
        );
        await dao.enqueueOrCoalesce(
          entity: 'availability',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: jsonEncode({'b': 2}),
        );
        await dao.enqueueOrCoalesce(
          entity: 'planned_ride',
          entityKey: 'uid1:ride1',
          operation: 'delete',
          payload: '{}',
        );

        final upsertCalls = <String>[];
        final deleteCalls = <String>[];

        await service.drain(
          upsertFn: (entity, key, payload) async {
            upsertCalls.add('$entity:$key:${jsonEncode(payload)}');
          },
          deleteFn: (entity, key) async {
            deleteCalls.add('$entity:$key');
          },
        );

        expect(upsertCalls, containsAll(<String>[
          'profile:uid1:${jsonEncode({'a': 1})}',
          'availability:uid1:${jsonEncode({'b': 2})}',
        ]));
        expect(deleteCalls, ['planned_ride:uid1:ride1']);
        expect(await dao.pendingRows(), isEmpty);
      },
    );

    test(
      'a throwing upsertFn marks that row failed but still processes the rest',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'profile',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: '{}',
        );
        await dao.enqueueOrCoalesce(
          entity: 'availability',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: '{}',
        );

        await service.drain(
          upsertFn: (entity, key, payload) async {
            if (entity == 'profile') {
              throw Exception('network down');
            }
          },
          deleteFn: (entity, key) async {},
        );

        final remaining = await dao.pendingRows();
        expect(remaining, hasLength(1));
        expect(remaining.single.entity, 'profile');
        expect(remaining.single.attempts, 1);
      },
    );

    test('drain on an empty outbox calls neither callback and does not throw', () async {
      var upsertCalled = false;
      var deleteCalled = false;

      await service.drain(
        upsertFn: (entity, key, payload) async {
          upsertCalled = true;
        },
        deleteFn: (entity, key) async {
          deleteCalled = true;
        },
      );

      expect(upsertCalled, isFalse);
      expect(deleteCalled, isFalse);
    });

    test(
      'a second drain() call while one is still in flight does not double-send a row',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'profile',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: '{}',
        );

        final releaseFirstCall = Completer<void>();
        var callCount = 0;

        // First drain() is deliberately not awaited yet — it blocks inside
        // its own upsertFn until releaseFirstCall completes, simulating a
        // real drain still in flight when a second trigger fires (e.g.
        // foreground reconcile racing a post-sign-in drain).
        final firstDrain = service.drain(
          upsertFn: (entity, key, payload) async {
            callCount++;
            await releaseFirstCall.future;
          },
          deleteFn: (entity, key) async {},
        );

        // Second call while the first is still in flight — its own
        // upsertFn must never run; only the first call's closures see rows.
        final secondDrain = service.drain(
          upsertFn: (entity, key, payload) async {
            callCount++;
          },
          deleteFn: (entity, key) async {},
        );

        releaseFirstCall.complete();
        await Future.wait([firstDrain, secondDrain]);

        expect(callCount, 1);
        expect(await dao.pendingRows(), isEmpty);
      },
    );
  });

  // Plan 21-12. These exist because phase 21 twice shipped a sync path that
  // failed in complete silence: the error was written to Drift's `lastError`
  // column and nothing ever read it, so "the drain fails on every row" and
  // "the outbox is empty" produced identical logs. If someone removes the
  // logging again, these fail.
  group('SyncOutboxService drain logging', () {
    late List<String> logs;
    late SyncOutboxService loggingService;

    setUp(() {
      logs = <String>[];
      loggingService = SyncOutboxService(db.syncOutboxDao, log: logs.add);
    });

    test('a failing row logs its entity, key and error alongside markFailed', () async {
      final dao = db.syncOutboxDao;
      await dao.enqueueOrCoalesce(
        entity: 'profile',
        entityKey: 'uid1',
        operation: 'upsert',
        payload: '{}',
      );

      await loggingService.drain(
        upsertFn: (entity, key, payload) async => throw Exception('network down'),
        deleteFn: (entity, key) async {},
      );

      final failureLine = logs.firstWhere(
        (line) => line.contains('send failed'),
        orElse: () => '',
      );
      expect(
        failureLine,
        isNotEmpty,
        reason: 'a failed send must log, not only write lastError',
      );
      expect(failureLine, contains('profile'));
      expect(failureLine, contains('uid1'));
      expect(failureLine, contains('network down'));
      expect(failureLine, contains('attempt 1'));

      // The log must agree with what was persisted — a log line that says
      // something different from `lastError` would be worse than none.
      final remaining = await dao.pendingRows();
      expect(remaining.single.lastError, contains('network down'));
    });

    test('every drain emits a summary line, including an empty one', () async {
      await loggingService.drain(
        upsertFn: (entity, key, payload) async {},
        deleteFn: (entity, key) async {},
      );

      expect(
        logs.single,
        allOf(contains('0 pending'), contains('0 sent'), contains('0 failed')),
        reason: 'an empty outbox must still say so, otherwise it is '
            'indistinguishable from a drain that never ran',
      );
    });

    test('the summary counts sent and failed rows separately', () async {
      final dao = db.syncOutboxDao;
      await dao.enqueueOrCoalesce(
        entity: 'profile',
        entityKey: 'uid1',
        operation: 'upsert',
        payload: '{}',
      );
      await dao.enqueueOrCoalesce(
        entity: 'availability',
        entityKey: 'uid1',
        operation: 'upsert',
        payload: '{}',
      );

      await loggingService.drain(
        upsertFn: (entity, key, payload) async {
          if (entity == 'profile') throw Exception('network down');
        },
        deleteFn: (entity, key) async {},
      );

      expect(
        logs.last,
        allOf(contains('2 pending'), contains('1 sent'), contains('1 failed')),
      );
      // Plan 21-13: the summary must name which entity went through, not just
      // count it. A bare "1 sent" was ambiguous enough on a real device that a
      // successful profile send was mistaken for a successful availability
      // send, while the availability row in Postgres was untouched.
      expect(
        logs.last,
        contains('availability'),
        reason: 'the successful entity must be attributable from the log alone',
      );
      expect(logs.last, isNot(contains('(profile')));
    });
  });
}
