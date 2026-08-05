import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/database/sync_outbox_entity_types.dart';
import 'package:ridewindow/data/repositories/planned_rides_repository.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';

void main() {
  // Deze suite gebruikt plain test()/group() (geen testWidgets()), dus
  // Flutter's TestWidgetsFlutterBinding wordt niet automatisch geinitialiseerd.
  // SharedPreferences.getInstance() heeft ServicesBinding.instance nodig om
  // het platform-kanaal te resolven — zonder deze regel faalt elke test met
  // "Binding has not yet been initialized." (zie weather_repository_test.dart).
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlannedRidesRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = PlannedRidesRepository(prefs);
  });

  test('Test 1 — nieuw formaat (start/end) blijft leesbaar', () async {
    final now = DateTime.now();
    final future = now.add(const Duration(days: 1));
    final futureEnd = future.add(const Duration(hours: 3));
    SharedPreferences.setMockInitialValues({
      'planned_rides': jsonEncode([
        {
          'start': future.toIso8601String(),
          'end': futureEnd.toIso8601String(),
          'plannedScore': 87.5,
        },
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    repo = PlannedRidesRepository(prefs);

    final result = repo.readLocal();

    expect(result.length, 1);
    expect(result.first.start, future);
    expect(result.first.end, futureEnd);
    expect(result.first.plannedScore, 87.5);
  });

  test(
      "Test 2 — oud formaat ('time') wordt nog steeds correct omgezet naar start/end",
      () async {
    final now = DateTime.now();
    final future = now.add(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      'planned_rides': jsonEncode([
        {
          'time': future.toIso8601String(),
          'plannedScore': 60.0,
        },
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    repo = PlannedRidesRepository(prefs);

    final result = repo.readLocal();

    expect(result.length, 1);
    expect(result.first.start, future);
    expect(result.first.end, future.add(const Duration(hours: 1)));
  });

  test('Test 3 — ritten die al voorbij zijn worden gefilterd', () async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final past = todayStart.subtract(const Duration(days: 2));
    final pastEnd = past.add(const Duration(hours: 2));
    final future = now.add(const Duration(days: 1));
    final futureEnd = future.add(const Duration(hours: 2));
    SharedPreferences.setMockInitialValues({
      'planned_rides': jsonEncode([
        {
          'start': past.toIso8601String(),
          'end': pastEnd.toIso8601String(),
          'plannedScore': 50.0,
        },
        {
          'start': future.toIso8601String(),
          'end': futureEnd.toIso8601String(),
          'plannedScore': 90.0,
        },
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    repo = PlannedRidesRepository(prefs);

    final result = repo.readLocal();

    expect(result.length, 1);
    expect(result.first.start, future);
  });

  test('Test 4 — resultaat is gesorteerd op start', () async {
    final now = DateTime.now();
    final day1 = now.add(const Duration(days: 1));
    final day2 = now.add(const Duration(days: 2));
    final day3 = now.add(const Duration(days: 3));
    SharedPreferences.setMockInitialValues({
      'planned_rides': jsonEncode([
        {
          'start': day3.toIso8601String(),
          'end': day3.add(const Duration(hours: 2)).toIso8601String(),
          'plannedScore': 70.0,
        },
        {
          'start': day1.toIso8601String(),
          'end': day1.add(const Duration(hours: 2)).toIso8601String(),
          'plannedScore': 80.0,
        },
        {
          'start': day2.toIso8601String(),
          'end': day2.add(const Duration(hours: 2)).toIso8601String(),
          'plannedScore': 75.0,
        },
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    repo = PlannedRidesRepository(prefs);

    final result = repo.readLocal();

    expect(result.length, 3);
    expect(result[0].start, day1);
    expect(result[1].start, day2);
    expect(result[2].start, day3);
  });

  test('Test 5 — schrijfformaat is byte-voor-byte het oude', () async {
    final start = DateTime.parse('2026-08-01T09:00:00.000Z');
    final end = DateTime.parse('2026-08-01T12:00:00.000Z');
    final ride = PlannedRide(start: start, end: end, plannedScore: 92.0);

    await repo.save([ride], stamp: false);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('planned_rides');
    final decoded = (jsonDecode(raw!) as List).cast<Map<String, dynamic>>();

    expect(decoded, [
      {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'plannedScore': 92.0,
      },
    ]);
  });

  test('Test 6 — save() stempelt planned_rides.updatedAt', () async {
    final before = DateTime.now().millisecondsSinceEpoch;
    final start = DateTime.now().add(const Duration(days: 1));
    final end = start.add(const Duration(hours: 2));

    await repo.save([
      PlannedRide(start: start, end: end, plannedScore: 55.0),
    ]);

    final after = DateTime.now().millisecondsSinceEpoch;
    final stamped = repo.readUpdatedAt();

    expect(stamped, isNotNull);
    expect(stamped! >= before, isTrue);
    expect(stamped <= after, isTrue);
  });

  test('Test 7 — save(stamp: false) stempelt niet', () async {
    final prefs = await SharedPreferences.getInstance();
    const knownStamp = 1700000000000;
    await prefs.setInt('planned_rides.updatedAt', knownStamp);

    final start = DateTime.now().add(const Duration(days: 1));
    final end = start.add(const Duration(hours: 2));
    await repo.save(
      [PlannedRide(start: start, end: end, plannedScore: 55.0)],
      stamp: false,
    );

    expect(repo.readUpdatedAt(), knownStamp);
  });

  test('Test 8 — readUpdatedAt() geeft null zonder dat veld (D-08)', () async {
    expect(repo.readUpdatedAt(), isNull);
  });

  group('outbox-aware add()/remove() (Task 1, SYNC-03)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    PlannedRide makeRide() {
      final start = DateTime.now().add(const Duration(days: 1));
      final end = start.add(const Duration(hours: 3));
      return PlannedRide(start: start, end: end, plannedScore: 77.0);
    }

    test(
        'add() with outbox+userId calls enqueueOrCoalesce exactly once with '
        'entity: kOutboxEntityPlannedRide, entityKey uid:rideId, operation upsert',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final signedInRepo = PlannedRidesRepository(
        prefs,
        outbox: db.syncOutboxDao,
        userId: 'uid-1',
      );
      final ride = makeRide();

      await signedInRepo.add(ride);

      final pending = await db.syncOutboxDao.pendingRows();
      expect(pending, hasLength(1));
      expect(pending.single.entity, kOutboxEntityPlannedRide);
      expect(pending.single.entityKey, 'uid-1:${ride.rideId}');
      expect(pending.single.operation, 'upsert');
      expect(
        jsonDecode(pending.single.payload),
        equals(ride.toRow('uid-1')),
      );
    });

    test(
        'remove() after add() calls enqueueOrCoalesce with operation delete, '
        'same entityKey, payload {}', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final signedInRepo = PlannedRidesRepository(
        prefs,
        outbox: db.syncOutboxDao,
        userId: 'uid-1',
      );
      final ride = makeRide();
      await signedInRepo.add(ride);

      await signedInRepo.remove(ride);

      final pending = await db.syncOutboxDao.pendingRows();
      // Coalesced onto the same (entity, entityKey) row — still exactly one.
      expect(pending, hasLength(1));
      expect(pending.single.entity, kOutboxEntityPlannedRide);
      expect(pending.single.entityKey, 'uid-1:${ride.rideId}');
      expect(pending.single.operation, 'delete');
      expect(pending.single.payload, '{}');
    });

    test(
        'add() without outbox/userId enqueues nothing and behaves like the '
        'existing shipped add() (dedup + sort unchanged)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final signedOutRepo = PlannedRidesRepository(prefs);
      final ride = makeRide();

      await signedOutRepo.add(ride);
      // Adding the exact same start/end again is a no-op dedup.
      await signedOutRepo.add(ride);

      final result = signedOutRepo.readLocal();
      expect(result, hasLength(1));
      expect(result.first.start, ride.start);
      expect(result.first.end, ride.end);
    });

    test('enqueueUpsert() enqueues one upsert row without touching local storage',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final signedInRepo = PlannedRidesRepository(
        prefs,
        outbox: db.syncOutboxDao,
        userId: 'uid-1',
      );
      final ride = makeRide();

      await signedInRepo.enqueueUpsert(ride);

      final pending = await db.syncOutboxDao.pendingRows();
      expect(pending, hasLength(1));
      expect(pending.single.operation, 'upsert');
      expect(signedInRepo.readLocal(), isEmpty);
    });

    test('enqueueUpsert() without outbox/userId is a silent no-op', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final signedOutRepo = PlannedRidesRepository(prefs);
      final ride = makeRide();

      await signedOutRepo.enqueueUpsert(ride);

      expect(signedOutRepo.readLocal(), isEmpty);
    });
  });

  group('duplicaten over de UTC/lokaal-grens (plan 21-13)', () {
    test('add() met dezelfde rit, één keer lokaal en één keer als UTC, bewaart '
        'er één', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final r = PlannedRidesRepository(prefs);

      final start = DateTime.now().add(const Duration(days: 3));
      final end = start.add(const Duration(hours: 3));

      expect(
        start.timeZoneOffset,
        isNot(Duration.zero),
        reason: 'moet in een niet-UTC tijdzone draaien om iets te bewijzen',
      );

      await r.add(
        PlannedRide(start: start, end: end, plannedScore: 100.0),
      );
      await r.add(
        PlannedRide(
          start: start.toUtc(),
          end: end.toUtc(),
          plannedScore: 100.0,
        ),
      );

      expect(r.readLocal(), hasLength(1));
    });

    test('readLocal() klapt bestaande duplicaten samen tot één rit', () async {
      // Bootst na wat er op het toestel staat: twee opgeslagen kopieën van
      // dezelfde rit, één lokaal geschreven en één uit de cloud gekomen.
      final start = DateTime.now().add(const Duration(days: 3));
      final end = start.add(const Duration(hours: 3));
      SharedPreferences.setMockInitialValues({
        'planned_rides': jsonEncode([
          {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
            'plannedScore': 100.0,
          },
          {
            'start': start.toUtc().toIso8601String(),
            'end': end.toUtc().toIso8601String(),
            'plannedScore': 100.0,
          },
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      final r = PlannedRidesRepository(prefs);

      expect(r.readLocal(), hasLength(1));
    });
  });
}
