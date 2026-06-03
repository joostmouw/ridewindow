import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'availability_notifier.g.dart';

/// AvailabilityNotifier beheert de set geblokkeerde uren als `Set<DateTime>`.
///
/// Persistentie via SharedPreferences: DateTime-waarden worden opgeslagen als
/// ISO-8601 strings onder de sleutel 'availability.blockedHours'.
///
/// Volledig context-loos en testbaar via ProviderContainer.
@riverpod
class AvailabilityNotifier extends _$AvailabilityNotifier {
  static const _key = 'availability.blockedHours';

  @override
  Future<Set<DateTime>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final strings = prefs.getStringList(_key) ?? [];
    return strings.map(DateTime.parse).toSet();
  }

  /// Wisselt de aanwezigheid van [hour] in de geblokkeerde uren.
  /// Voegt toe als afwezig, verwijdert als aanwezig.
  Future<void> toggleHour(DateTime hour) async {
    final current = await future;
    final next = Set<DateTime>.from(current);
    if (next.contains(hour)) {
      next.remove(hour);
    } else {
      next.add(hour);
    }
    await _persist(next);
    state = AsyncData(next);
  }

  /// Wist alle geblokkeerde uren.
  Future<void> clearAll() async {
    await _persist({});
    state = const AsyncData({});
  }

  Future<void> _persist(Set<DateTime> hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      hours.map((dt) => dt.toIso8601String()).toList(),
    );
  }
}
