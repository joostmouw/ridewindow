import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'availability_notifier.g.dart';

/// Beschrijft het type geblokkeerd uur.
/// - [work]: geblokkeerd via een werk-preset (geseed door onboarding of profiel)
/// - [custom]: handmatig geblokkeerd door de gebruiker
enum BlockType { work, custom }

/// AvailabilityNotifier beheert de geblokkeerde uren als `Map<DateTime, BlockType>`.
///
/// Persistentie via SharedPreferences: entries worden opgeslagen als
/// "ISO8601|blocktype" strings (bv. "2026-06-14T09:00:00.000Z|custom")
/// onder de sleutel 'availability.blockedHours'.
///
/// Volledig context-loos en testbaar via ProviderContainer.
@riverpod
class AvailabilityNotifier extends _$AvailabilityNotifier {
  static const _key = 'availability.blockedHours';

  @override
  Future<Map<DateTime, BlockType>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final strings = prefs.getStringList(_key) ?? [];
    final result = <DateTime, BlockType>{};
    for (final entry in strings) {
      try {
        final parts = entry.split('|');
        if (parts.length == 2) {
          final dt = DateTime.parse(parts[0]);
          final blockType = BlockType.values.byName(parts[1]);
          result[dt] = blockType;
        }
      } catch (_) {
        // Corrupte entries worden overgeslagen (T-04-01: Tampering via SharedPreferences)
      }
    }
    return result;
  }

  /// Wisselt de aanwezigheid van [hour] als [BlockType.custom] entry.
  /// Verwijdert de entry als die al aanwezig is met type custom; voegt toe anders.
  Future<void> toggleCustomHour(DateTime hour) async {
    final current = await future;
    final next = Map<DateTime, BlockType>.from(current);
    if (next.containsKey(hour) && next[hour] == BlockType.custom) {
      next.remove(hour);
    } else {
      next[hour] = BlockType.custom;
    }
    await _persist(next);
    state = AsyncData(next);
  }

  /// Vervangt de volledige map met [preset] en persisteert.
  Future<void> seedPreset(Map<DateTime, BlockType> preset) async {
    await _persist(preset);
    state = AsyncData(preset);
  }

  /// Wist alle geblokkeerde uren.
  Future<void> clearAll() async {
    await _persist(const {});
    state = const AsyncData(<DateTime, BlockType>{});
  }

  Future<void> _persist(Map<DateTime, BlockType> hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      hours.entries
          .map((e) => '${e.key.toIso8601String()}|${e.value.name}')
          .toList(),
    );
  }
}
