import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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

        expect(
          upsertCalls,
          containsAll(<String>[
            'profile:uid1:${jsonEncode({'a': 1})}',
            'availability:uid1:${jsonEncode({'b': 2})}',
          ]),
        );
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

  group('failure logging + attempt ceiling (Task 3, plan 21-12)', () {
    late List<String> messages;
    late void Function(String? message, {int? wrapWidth}) originalDebugPrint;

    setUp(() {
      messages = <String>[];
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) messages.add(message);
      };
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
    });

    test(
      'a failing send logs exactly one message naming the entity, entityKey, '
      'attempt count and error',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'availability',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: '{}',
        );

        await service.drain(
          upsertFn: (entity, key, payload) async {
            throw Exception('network down');
          },
          deleteFn: (entity, key) async {},
        );

        final failureLine = messages.firstWhere((m) => m.contains('send failed'));
        expect(failureLine, contains('availability'));
        expect(failureLine, contains('uid1'));
        expect(failureLine, contains('attempt 1'));
        expect(failureLine, contains('network down'));
      },
    );

    // AANGEPAST bij het samenvoegen van twee parallelle 21-12/21-13-takken.
    // Deze test heette "a drain where every row succeeds logs nothing" en eiste
    // `expect(messages, isEmpty)`. Dat is bewust omgedraaid, op grond van wat er
    // op 2026-08-04 op het toestel gebeurde:
    //
    // - Zwijgen bij succes maakt "de drain vond niets" niet te onderscheiden van
    //   "de drain heeft nooit gedraaid". Dat onderscheid is in 21-10 en 21-11
    //   twee keer verkeerd gelezen, met een toestelsessie per keer als prijs.
    // - Een kale telling is bovendien niet herleidbaar: een drain meldde
    //   "1 sent" terwijl de availability-rij in Postgres onaangeroerd bleef —
    //   de geslaagde send was een profile-rij. Dat leverde bijna een onterechte
    //   SYNC-05 PASS op.
    //
    // De prijs is één regel per foreground-cyclus in logcat. Dat is goedkoper
    // dan een sessie diagnose.
    test('elke drain logt één samenvatting, met de verzonden entiteiten',
        () async {
      final dao = db.syncOutboxDao;
      await dao.enqueueOrCoalesce(
        entity: 'profile',
        entityKey: 'uid1',
        operation: 'upsert',
        payload: '{}',
      );

      await service.drain(
        upsertFn: (entity, key, payload) async {},
        deleteFn: (entity, key) async {},
      );

      expect(messages, hasLength(1));
      expect(
        messages.single,
        allOf(
          contains('drain done'),
          contains('1 pending'),
          contains('1 sent'),
          contains('(profile)'),
          contains('0 failed'),
        ),
      );
    });

    test('een lege outbox logt óók een samenvatting', () async {
      await service.drain(
        upsertFn: (entity, key, payload) async {},
        deleteFn: (entity, key) async {},
      );

      expect(
        messages.single,
        allOf(contains('0 pending'), contains('0 sent'), contains('0 failed')),
        reason: 'juist deze regel onderscheidt "niets te doen" van '
            '"nooit gedraaid"',
      );
    });

    test(
      'a row that fails kMaxSendAttempts times in a row is dropped, not '
      'retried again, and the drop is logged loudly',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'availability',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: '{}',
        );

        for (var i = 0; i < SyncOutboxService.kMaxSendAttempts; i++) {
          await service.drain(
            upsertFn: (entity, key, payload) async {
              throw Exception('permanently broken shape');
            },
            deleteFn: (entity, key) async {},
          );
        }

        expect(await dao.pendingRows(), isEmpty);
        expect(
          messages.any(
            (m) =>
                m.contains('dropping') &&
                m.contains('availability') &&
                m.contains('uid1') &&
                m.contains('permanently broken shape'),
          ),
          isTrue,
          reason: 'Expected a loud drop log line. Captured: $messages',
        );
      },
    );

    test(
      'a row below the ceiling (kMaxSendAttempts - 1 failures) stays pending '
      'with an incremented attempt count — 21-10 behaviour unchanged',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'availability',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: '{}',
        );

        for (var i = 0; i < SyncOutboxService.kMaxSendAttempts - 1; i++) {
          await service.drain(
            upsertFn: (entity, key, payload) async {
              throw Exception('still broken');
            },
            deleteFn: (entity, key) async {},
          );
        }

        final remaining = await dao.pendingRows();
        expect(remaining, hasLength(1));
        expect(remaining.single.attempts, SyncOutboxService.kMaxSendAttempts - 1);
      },
    );

    test(
      'watchPendingCount reaches 0 after a row is dropped by the attempt '
      'ceiling — the status text must not stay stuck on "Syncing..."',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'availability',
          entityKey: 'uid1',
          operation: 'upsert',
          payload: '{}',
        );

        for (var i = 0; i < SyncOutboxService.kMaxSendAttempts; i++) {
          await service.drain(
            upsertFn: (entity, key, payload) async {
              throw Exception('permanently broken shape');
            },
            deleteFn: (entity, key) async {},
          );
        }

        final count = await dao.watchPendingCount().first;
        expect(count, 0);
      },
    );
  });

  group('rate-limit-weigering (fase 38, RATE-05, plan 38-02)', () {
    test(
      'een geweigerde rij telt geen poging en overleeft de pogingenregel: '
      'vijf drains later bestaat hij nog, attempts = 0',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'feedback',
          entityKey: 'f1',
          operation: 'upsert',
          payload: '{"id":"f1"}',
        );

        var refusals = 0;
        // Twee drains méér dan het plafond aan pogingen: bewijst dat de
        // weigering de telling niet alleen vertraagt maar helemaal niet raakt.
        for (var i = 0; i < SyncOutboxService.kMaxSendAttempts + 2; i++) {
          await service.drain(
            upsertFn: (entity, key, payload) async {
              throw const RateLimitedRefusal(
                table: 'feedback',
                subject: 'sender',
              );
            },
            deleteFn: (entity, key) async {},
            onRateLimited: (refusal) => refusals++,
          );
        }

        final remaining = await dao.pendingRows();
        expect(
          remaining,
          hasLength(1),
          reason: 'de rij is niet kapot, hij mag er vandaag alleen niet uit '
              '(F-03). Hij dropt hem na vijf pogingen was de precies de '
              'fout die RATE-05 moest voorkomen.',
        );
        expect(
          remaining.single.attempts,
          0,
          reason: 'een weigering is geen poging',
        );
        expect(
          refusals,
          SyncOutboxService.kMaxSendAttempts + 2,
          reason: 'elke drain meldt zijn weigering aan de callback',
        );
      },
    );

    test(
      'de weigering wordt ook herkend in een gewone fouttekst van PostgREST, '
      'met tabel en soort uit de melding',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'feedback',
          entityKey: 'f2',
          operation: 'upsert',
          payload: '{"id":"f2"}',
        );

        final refusals = <RateLimitedRefusal>[];
        await service.drain(
          upsertFn: (entity, key, payload) async {
            // Zo komt de weigering bij de app binnen als de reconciler hem
            // níet heeft omgewikkeld: ingebed in de tekst van de fout die
            // insertRow gooit.
            throw Exception(
              'PostgrestException(message: rw_rate_limited:feedback:sender, '
              'code: 42900, details: null, hint: null)',
            );
          },
          deleteFn: (entity, key) async {},
          onRateLimited: refusals.add,
        );

        final remaining = await dao.pendingRows();
        expect(remaining, hasLength(1));
        expect(remaining.single.attempts, 0);
        expect(refusals.single.table, 'feedback');
        expect(refusals.single.subject, 'sender');
      },
    );

    test(
      'een gewone fout valt nog wél onder de pogingenregel -- de weigerings-tak '
      'mag geen enkele andere fout opeten',
      () async {
        final dao = db.syncOutboxDao;
        await dao.enqueueOrCoalesce(
          entity: 'feedback',
          entityKey: 'f3',
          operation: 'upsert',
          payload: '{"id":"f3"}',
        );

        for (var i = 0; i < SyncOutboxService.kMaxSendAttempts; i++) {
          await service.drain(
            upsertFn: (entity, key, payload) async {
              throw Exception('network down');
            },
            deleteFn: (entity, key) async {},
          );
        }

        expect(
          await dao.pendingRows(),
          isEmpty,
          reason: 'bestaand gedrag bewaard (21-12): een rij die vijf keer '
              'faalt met een gewone fout wordt gedropt',
        );
      },
    );

    test('tryFrom herkent alleen echte weigeringen', () {
      const refusal = RateLimitedRefusal(table: 'feedback', subject: 'account');
      expect(
        RateLimitedRefusal.tryFrom(refusal),
        same(refusal),
        reason: 'al omgewikkeld: dan niet opnieuw parsen maar hergebruiken',
      );

      final parsed = RateLimitedRefusal.tryFrom(
        Exception(
          '{"code":"42900","message":"rw_rate_limited:app_events:device"}',
        ),
      );
      expect(parsed, isNotNull);
      expect(parsed!.table, 'app_events');
      expect(parsed.subject, 'device');

      expect(RateLimitedRefusal.tryFrom(Exception('network down')), isNull);
      expect(
        RateLimitedRefusal.tryFrom(Exception('rw_rate_limited')),
        isNull,
        reason: 'zonder tabel en soort is het geen herkende weigering',
      );
      expect(
        RateLimitedRefusal.tryFrom(
          Exception('new row violates check constraint "feedback_rating_range"'),
        ),
        isNull,
        reason: 'een CHECK-weigering is een gewone fout, geen dagplafond',
      );
    });
  });
}
