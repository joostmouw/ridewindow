// lib/providers/last_refreshed_provider.dart
// LastRefreshedNotifier: leest lastRefreshed timestamp uit SharedPreferences.
// Gegenereerde providernaam: lastRefreshedProvider

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'last_refreshed_provider.g.dart';

/// SharedPreferences sleutel voor de lastRefreshed timestamp.
const kLastRefreshedKey = 'weather.lastRefreshed';

/// Leest de lastRefreshed timestamp uit SharedPreferences.
/// Retourneert null als er nog nooit een fetch is geweest.
/// Gegenereerde naam: lastRefreshedProvider
@riverpod
class LastRefreshedNotifier extends _$LastRefreshedNotifier {
  @override
  Future<DateTime?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(kLastRefreshedKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Herlaad timestamp vanuit SharedPreferences.
  /// Aanroepen bij foreground resume in HomeScreen.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
