import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/providers/availability_notifier.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AvailabilityNotifier', () {
    test('cold start empty — nieuw container levert lege Set<DateTime> op', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked, isEmpty);
    });

    test('toggle adds hour — toggleHour voegt DateTime toe aan set', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dt = DateTime.utc(2026, 6, 14, 9, 0);
      await container.read(availabilityProvider.notifier).toggleHour(dt);

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked, contains(dt));
    });

    test('toggle removes hour — toggleHour tweemaal verwijdert DateTime uit set', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dt = DateTime.utc(2026, 6, 14, 10, 0);
      await container.read(availabilityProvider.notifier).toggleHour(dt);
      await container.read(availabilityProvider.notifier).toggleHour(dt);

      final blocked = await container.read(availabilityProvider.future);
      expect(blocked, isNot(contains(dt)));
    });

    test('persists across re-create — toggle dan dispose dan nieuw container → dt aanwezig', () async {
      final container1 = ProviderContainer();
      final dt = DateTime.utc(2026, 6, 15, 8, 0);
      await container1.read(availabilityProvider.notifier).toggleHour(dt);
      container1.dispose();

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final blocked = await container2.read(availabilityProvider.future);
      expect(blocked, contains(dt));
    });
  });
}
