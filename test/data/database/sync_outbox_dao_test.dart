import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncOutboxDao', () {
    test(
      'enqueueOrCoalesce called 5x for the same (entity, entityKey) leaves one row with the latest payload and attempts=0',
      () async {
        final dao = db.syncOutboxDao;

        for (var i = 1; i <= 5; i++) {
          await dao.enqueueOrCoalesce(
            entity: 'profile',
            entityKey: 'uid1',
            operation: 'upsert',
            payload: '{"a":$i}',
          );
        }

        final rows = await dao.pendingRows();
        expect(rows, hasLength(1));
        expect(rows.single.payload, '{"a":5}');
        expect(rows.single.attempts, 0);
      },
    );

    test(
      'markFailed increments attempts and sets lastError; row remains pending',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'profile',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: '{"a":1}',
        );
        final id = (await dao.pendingRows()).single.id;

        await dao.markFailed(id, 'boom');

        final rows = await dao.pendingRows();
        expect(rows, hasLength(1));
        expect(rows.single.attempts, 1);
        expect(rows.single.lastError, 'boom');
      },
    );

    test(
      'a fresh enqueueOrCoalesce after markFailed resets attempts to 0 and lastError to null',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'profile',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: '{"a":1}',
        );
        final id = (await dao.pendingRows()).single.id;
        await dao.markFailed(id, 'boom');

        await dao.enqueueOrCoalesce(
          entity: 'profile',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: '{"a":2}',
        );

        final rows = await dao.pendingRows();
        expect(rows, hasLength(1));
        expect(rows.single.attempts, 0);
        expect(rows.single.lastError, isNull);
        expect(rows.single.payload, '{"a":2}');
      },
    );

    test('markSent removes the row entirely', () async {
      final dao = db.syncOutboxDao;
      await dao.enqueueOrCoalesce(
        entity: 'profile',
        entityKey: 'uid1',
        operation: 'upsert',
        payload: '{"a":1}',
      );
      final id = (await dao.pendingRows()).single.id;

      await dao.markSent(id);

      expect(await dao.pendingRows(), isEmpty);
    });

    test(
      'watchPendingCount emits 0 on an empty table and updates when a row is enqueued',
      () async {
        final dao = db.syncOutboxDao;

        expect(
          dao.watchPendingCount(),
          emitsInOrder([0, 1]),
        );

        // Give the initial watch a moment to be established before writing.
        await Future<void>.delayed(Duration.zero);

        await dao.enqueueOrCoalesce(
          entity: 'profile',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: '{"a":1}',
        );
      },
    );
  });
}
