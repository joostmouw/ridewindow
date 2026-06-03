import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/providers/availability_notifier.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AvailabilityNotifier', () {
    test('cold start empty — nieuw container levert lege Map<DateTime, BlockType> op', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked, isEmpty);
    });

    test('toggle adds hour — toggleCustomHour voegt BlockType.custom entry toe', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dt = DateTime.utc(2026, 6, 14, 9, 0);
      await container.read(availabilityProvider.notifier).toggleCustomHour(dt);

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked.containsKey(dt), isTrue);
      expect(blocked[dt], equals(BlockType.custom));
    });

    test('toggle removes hour — toggleCustomHour tweemaal verwijdert de entry', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dt = DateTime.utc(2026, 6, 14, 10, 0);
      await container.read(availabilityProvider.notifier).toggleCustomHour(dt);
      await container.read(availabilityProvider.notifier).toggleCustomHour(dt);

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked.containsKey(dt), isFalse);
    });

    test('seedPreset vervangt de map — dt aanwezig met BlockType.work', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dt = DateTime.utc(2026, 6, 16, 8, 0);
      final preset = {dt: BlockType.work};
      await container.read(availabilityProvider.notifier).seedPreset(preset);

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked[dt], equals(BlockType.work));
    });

    test('clearAll wist de volledige map', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dt = DateTime.utc(2026, 6, 16, 9, 0);
      await container.read(availabilityProvider.notifier).seedPreset({dt: BlockType.work});
      await container.read(availabilityProvider.notifier).clearAll();

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked, isEmpty);
    });

    test('persists across re-create — toggleCustomHour dan dispose dan nieuw container → dt aanwezig met BlockType.custom', () async {
      final container1 = ProviderContainer();
      final dt = DateTime.utc(2026, 6, 15, 8, 0);
      await container1.read(availabilityProvider.notifier).toggleCustomHour(dt);
      container1.dispose();

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final blocked = await container2.read(availabilityProvider.future);
      expect(blocked.containsKey(dt), isTrue);
      expect(blocked[dt], equals(BlockType.custom));
    });
  });
}
