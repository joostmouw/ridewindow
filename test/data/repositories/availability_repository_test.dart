import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/database/sync_outbox_entity_types.dart';
import 'package:ridewindow/data/repositories/availability_repository.dart';
import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/services/availability_key.dart';

void main() {
  // Deze suite gebruikt plain test()/group() (geen testWidgets()), dus
  // Flutter's TestWidgetsFlutterBinding wordt niet automatisch geinitialiseerd.
  // SharedPreferences.getInstance() heeft ServicesBinding.instance nodig om
  // het platform-kanaal te resolven — zonder deze regel faalt elke test met
  // "Binding has not yet been initialized." (zie weather_repository_test.dart).
  TestWidgetsFlutterBinding.ensureInitialized();

  late AvailabilityRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = AvailabilityRepository(prefs);
  });

  test('Test 1 — bestaand formaat blijft leesbaar (UTC + lokale sleutel, genormaliseerd)',
      () async {
    SharedPreferences.setMockInitialValues({
      'availability.blockedHours': [
        '2026-06-14T09:00:00.000Z|custom',
        '2026-06-14T10:00:00.000|work',
      ],
    });
    final prefs = await SharedPreferences.getInstance();
    repo = AvailabilityRepository(prefs);

    final result = repo.readLocal();

    final expected = normalizeBlockedHours({
      DateTime.parse('2026-06-14T09:00:00.000Z'): BlockType.custom,
      DateTime.parse('2026-06-14T10:00:00.000'): BlockType.work,
    });

    expect(result, equals(expected));
    expect(result.length, 2);
  });

  test('Test 2 — corrupte entries worden overgeslagen, niet gegooid', () async {
    SharedPreferences.setMockInitialValues({
      'availability.blockedHours': [
        'onzin',
        '2026-06-14T09:00:00.000Z|bestaatniet',
        '2026-06-14T11:00:00.000Z|custom',
      ],
    });
    final prefs = await SharedPreferences.getInstance();
    repo = AvailabilityRepository(prefs);

    final result = repo.readLocal();

    expect(result.length, 1);
    expect(
      result[canonicalHourKey(DateTime.parse('2026-06-14T11:00:00.000Z'))],
      BlockType.custom,
    );
  });

  test('Test 3 — schrijfformaat is byte-voor-byte het oude', () async {
    final entry = DateTime.parse('2026-06-14T09:00:00.000Z');
    await repo.save({entry: BlockType.custom}, stamp: false);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('availability.blockedHours');

    expect(raw, equals(['2026-06-14T09:00:00.000Z|custom']));
  });

  test('Test 4 — save() stempelt availability.updatedAt', () async {
    final before = DateTime.now().millisecondsSinceEpoch;

    await repo.save({
      DateTime.parse('2026-06-14T09:00:00.000Z'): BlockType.custom,
    });

    final after = DateTime.now().millisecondsSinceEpoch;
    final stamped = repo.readUpdatedAt();

    expect(stamped, isNotNull);
    expect(stamped! >= before, isTrue);
    expect(stamped <= after, isTrue);
  });

  test('Test 5 — save(stamp: false) stempelt niet', () async {
    final prefs = await SharedPreferences.getInstance();
    const knownStamp = 1700000000000;
    await prefs.setInt('availability.updatedAt', knownStamp);

    await repo.save(
      {DateTime.parse('2026-06-14T09:00:00.000Z'): BlockType.custom},
      stamp: false,
    );

    expect(repo.readUpdatedAt(), knownStamp);
  });

  test('Test 6 — readUpdatedAt() geeft null op een installatie zonder dat veld',
      () async {
    expect(repo.readUpdatedAt(), isNull);
  });

  group('outbox-aware save (Task 2, SYNC-12)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'a single save() with 5 hour changes enqueues exactly one outbox row '
        'matching toRecurringRow(hours)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final signedInRepo = AvailabilityRepository(
        prefs,
        outbox: db.syncOutboxDao,
        userId: 'uid-1',
      );

      final hours = {
        DateTime(2026, 7, 27, 9): BlockType.work,
        DateTime(2026, 7, 27, 10): BlockType.work,
        DateTime(2026, 7, 28, 17): BlockType.custom,
        DateTime(2026, 7, 29, 8): BlockType.custom,
        DateTime(2026, 7, 30, 14): BlockType.calendar,
      };

      await signedInRepo.save(hours);

      final pending = await db.syncOutboxDao.pendingRows();
      expect(pending, hasLength(1));
      expect(pending.single.entity, kOutboxEntityAvailability);
      expect(pending.single.entityKey, 'uid-1');
      expect(pending.single.operation, 'upsert');
      // Plan 21-12: the previous assertion here (`equals(toRecurringRow(hours))`)
      // encoded the defect directly — it expected the enqueued payload to be
      // the bare recurring map, which is not a legal `public.availability`
      // row (PostgREST would receive weekday-hour keys as column names). Do
      // not "restore" that shape; the wrapped row below is correct and
      // matches `test/data/database/outbox_payload_shape_test.dart`.
      expect(
        jsonDecode(pending.single.payload),
        equals({'user_id': 'uid-1', 'recurring': toRecurringRow(hours)}),
      );
    });

    test(
        'resetForAccountSwitch() wist de uren zonder tijdstempel en zonder '
        'outbox-rij -- de cloudkopie van het nieuwe account blijft heel',
        () async {
      // Regressie voor het dataverlies van 2026-09-07. De "Start fresh"-tak
      // van de accountwissel riep clearAll() aan, en die gaat via save():
      // stempelt updatedAt op nu en enqueuet een upsert. Gevolg: de reconcile
      // zag lokaal-leeg als nieuwer dan de cloud en haalde het echte rooster
      // nooit terug, en de outbox duwde de leegte omhoog. Het weekrooster van
      // een echte gebruiker is daarmee lokaal en server-side verdwenen.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = AvailabilityRepository(
        prefs,
        outbox: db.syncOutboxDao,
        userId: 'uid-1',
      );

      await repo.save({
        DateTime(2026, 7, 27, 9): BlockType.work,
        DateTime(2026, 7, 27, 10): BlockType.work,
      });
      expect(repo.readLocal(), hasLength(2));
      expect(repo.readUpdatedAt(), isNotNull);

      final beforeReset = (await db.syncOutboxDao.pendingRows()).length;

      await repo.resetForAccountSwitch();

      // Lokaal leeg, maar zonder tijdstempel: readUpdatedAt() moet null zijn,
      // want daarop hangt de `local == null`-tak van
      // CloudSyncReconciler._reconcileAvailability die de cloud-rij
      // onvoorwaardelijk overneemt.
      expect(repo.readLocal(), isEmpty);
      expect(
        repo.readUpdatedAt(),
        isNull,
        reason: 'een tijdstempel op "nu" laat lokaal-leeg de cloud verslaan',
      );

      // En geen enkele nieuwe outbox-rij: de leegte mag nooit omhoog.
      expect(
        (await db.syncOutboxDao.pendingRows()).length,
        beforeReset,
        reason: 'resetForAccountSwitch mag niets naar de cloud enqueuen',
      );
    });

    test(
        'constructed without outbox/userId enqueues nothing and keeps '
        'existing local-write behaviour', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final signedOutRepo = AvailabilityRepository(prefs);

      await signedOutRepo.save(
        {DateTime(2026, 7, 27, 9): BlockType.custom},
      );

      expect(signedOutRepo.readLocal().length, 1);
    });

    test('stampUpdatedAt(value) sets the exact epoch-ms value, not now()',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = AvailabilityRepository(prefs);
      final known = DateTime.fromMillisecondsSinceEpoch(1700000000000);

      await repo.stampUpdatedAt(known);

      expect(repo.readUpdatedAt(), 1700000000000);
    });
  });
}
