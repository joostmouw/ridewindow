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
  });
}
