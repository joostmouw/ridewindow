import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
