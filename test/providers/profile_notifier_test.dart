import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfileNotifier', () {
    test('cold start defaults — leeg SharedPreferences levert defaults op', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final profile = await container.read(profileProvider.future);

      expect(profile.tolerances.tempMinIdealC, equals(12.0));
      expect(profile.tolerances.tempMaxIdealC, equals(26.0));
      expect(profile.tolerances.windMaxIdealKmh, equals(15.0));
      expect(profile.tolerances.rainMaxIdealMm, equals(0.5));
      expect(profile.allowedDurations, equals([2, 3, 5]));
      expect(profile.theme, equals('system'));
      expect(profile.locationOverride, isNull);
      expect(profile.notifEveningBefore, isFalse);
      expect(profile.notifMorningOf, isFalse);
      expect(profile.notifWeeklyDigest, isFalse);
    });

    test('persist tolerances — wijzigingen overleven dispose/re-create cyclus', () async {
      final container1 = ProviderContainer();
      await container1.read(profileProvider.future);

      const updated = WeatherTolerances(
        tempMinIdealC: 10.0,
        tempMaxIdealC: 24.0,
        windMaxIdealKmh: 20.0,
        rainMaxIdealMm: 1.0,
      );

      await container1.read(profileProvider.notifier).updateTolerances(updated);
      container1.dispose();

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final profile = await container2.read(profileProvider.future);

      expect(profile.tolerances.tempMinIdealC, equals(10.0));
      expect(profile.tolerances.tempMaxIdealC, equals(24.0));
      expect(profile.tolerances.windMaxIdealKmh, equals(20.0));
      expect(profile.tolerances.rainMaxIdealMm, equals(1.0));
    });

    test('toggleDuration removes — [2,3,5] → toggle 3 → [2,5]', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(profileProvider.future);
      await container.read(profileProvider.notifier).toggleDuration(3);

      final profile = await container.read(profileProvider.future);
      expect(profile.allowedDurations, equals([2, 5]));
    });

    test('toggleDuration cannot remove last — [2] → toggle 2 → nog steeds [2]', () async {
      // Setup: start met alleen [2] door 3 en 5 weg te togglen
      SharedPreferences.setMockInitialValues({
        'profile.allowedDurations': ['2'],
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(profileProvider.future);
      await container.read(profileProvider.notifier).toggleDuration(2);

      final profile = await container.read(profileProvider.future);
      expect(profile.allowedDurations, equals([2]));
    });
  });
}
