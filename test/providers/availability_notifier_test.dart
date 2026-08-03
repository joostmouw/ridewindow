import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/availability_notifier.dart';

/// Task 3 (plan 21-04): availabilityRepositoryProvider now also watches
/// appDatabaseProvider (for the outbox DAO). The real appDatabaseProvider
/// opens a disk-backed Drift database via path_provider, which needs a real
/// platform channel unavailable in a plain `test()` (no widget binding) —
/// every ProviderContainer in this suite therefore overrides it with an
/// in-memory database.
List<Override> _testOverrides() => [
      appDatabaseProvider.overrideWith((ref) => AppDatabase(NativeDatabase.memory())),
    ];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AvailabilityNotifier', () {
    test('cold start empty — nieuw container levert lege Map<DateTime, BlockType> op', () async {
      final container = ProviderContainer(overrides: _testOverrides());
      addTearDown(container.dispose);

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked, isEmpty);
    });

    test('toggle adds hour — toggleCustomHour voegt BlockType.custom entry toe', () async {
      final container = ProviderContainer(overrides: _testOverrides());
      addTearDown(container.dispose);

      final dt = DateTime(2026, 6, 14, 9, 0);
      await container.read(availabilityProvider.notifier).toggleCustomHour(dt);

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked.containsKey(dt), isTrue);
      expect(blocked[dt], equals(BlockType.custom));
    });

    test('toggle removes hour — toggleCustomHour tweemaal verwijdert de entry', () async {
      final container = ProviderContainer(overrides: _testOverrides());
      addTearDown(container.dispose);

      final dt = DateTime(2026, 6, 14, 10, 0);
      await container.read(availabilityProvider.notifier).toggleCustomHour(dt);
      await container.read(availabilityProvider.notifier).toggleCustomHour(dt);

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked.containsKey(dt), isFalse);
    });

    test('seedPreset zet de work-blokken — dt aanwezig met BlockType.work', () async {
      final container = ProviderContainer(overrides: _testOverrides());
      addTearDown(container.dispose);

      final dt = DateTime(2026, 6, 16, 8, 0);
      final preset = {dt: BlockType.work};
      await container.read(availabilityProvider.notifier).seedPreset(preset);

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked[dt], equals(BlockType.work));
    });

    test('seedPreset laat custom- en calendar-blokken staan (audit C1)', () async {
      final container = ProviderContainer(overrides: _testOverrides());
      addTearDown(container.dispose);
      final notifier = container.read(availabilityProvider.notifier);

      final custom = DateTime(2026, 6, 16, 19, 0);
      final calendar = DateTime(2026, 6, 17, 14, 0);
      await notifier.toggleCustomHour(custom);
      await notifier.importCalendarBlocks({calendar: BlockType.calendar});

      await notifier.seedPreset({DateTime(2026, 6, 16, 8, 0): BlockType.work});

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked[custom], equals(BlockType.custom),
          reason: 'een preset-chip mag handmatige blokken niet wissen',);
      expect(blocked[calendar], equals(BlockType.calendar),
          reason: 'een preset-chip mag geimporteerde agenda-blokken niet wissen',);
      expect(blocked[DateTime(2026, 6, 16, 8, 0)], equals(BlockType.work));
    });

    test('seedPreset vervangt eerdere work-blokken', () async {
      final container = ProviderContainer(overrides: _testOverrides());
      addTearDown(container.dispose);
      final notifier = container.read(availabilityProvider.notifier);

      final oud = DateTime(2026, 6, 16, 8, 0);
      final nieuw = DateTime(2026, 6, 16, 9, 0);
      await notifier.seedPreset({oud: BlockType.work});
      await notifier.seedPreset({nieuw: BlockType.work});

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked.containsKey(oud), isFalse);
      expect(blocked[nieuw], equals(BlockType.work));
    });

    test('clearAll wist de volledige map', () async {
      final container = ProviderContainer(overrides: _testOverrides());
      addTearDown(container.dispose);

      final dt = DateTime(2026, 6, 16, 9, 0);
      await container.read(availabilityProvider.notifier).seedPreset({dt: BlockType.work});
      await container.read(availabilityProvider.notifier).clearAll();

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked, isEmpty);
    });

    test('persists across re-create — toggleCustomHour dan dispose dan nieuw container → dt aanwezig met BlockType.custom', () async {
      final container1 = ProviderContainer(overrides: _testOverrides());
      final dt = DateTime(2026, 6, 15, 8, 0);
      await container1.read(availabilityProvider.notifier).toggleCustomHour(dt);
      container1.dispose();

      final container2 = ProviderContainer(overrides: _testOverrides());
      addTearDown(container2.dispose);

      final blocked = await container2.read(availabilityProvider.future);
      expect(blocked.containsKey(dt), isTrue);
      expect(blocked[dt], equals(BlockType.custom));
    });
  });
}
