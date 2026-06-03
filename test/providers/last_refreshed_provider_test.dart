// test/providers/last_refreshed_provider_test.dart
// ProviderContainer-tests voor LastRefreshedNotifier.
// Dekt Phase 8 Plan 05 success criteria (NOTIF-06).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/providers/last_refreshed_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LastRefreshedNotifier', () {
    test('build — null als geen timestamp opgeslagen', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(lastRefreshedProvider.future);
      expect(result, isNull);
    });

    test('build — leest timestamp uit SharedPreferences', () async {
      const ms = 1748952600000;
      SharedPreferences.setMockInitialValues({kLastRefreshedKey: ms});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(lastRefreshedProvider.future);
      expect(result, equals(DateTime.fromMillisecondsSinceEpoch(ms)));
    });

    test('refresh() — herlaadt state na schrijven naar SharedPreferences', () async {
      // Start met lege prefs
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Eerste read: null
      final first = await container.read(lastRefreshedProvider.future);
      expect(first, isNull);

      // Schrijf een timestamp naar SharedPreferences
      const ms = 1748952600000;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kLastRefreshedKey, ms);

      // Roep refresh() aan op de notifier
      await container.read(lastRefreshedProvider.notifier).refresh();

      // Nu moet de provider de nieuwe waarde teruggeven
      final second = await container.read(lastRefreshedProvider.future);
      expect(second, equals(DateTime.fromMillisecondsSinceEpoch(ms)));
    });
  });
}
