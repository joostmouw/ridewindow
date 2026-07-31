import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
