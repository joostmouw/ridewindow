import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/services/availability_key.dart';

part 'availability_notifier.g.dart';

/// Beschrijft het type geblokkeerd uur.
/// - [work]: geblokkeerd via een werk-preset (geseed door onboarding of profiel)
/// - [custom]: handmatig geblokkeerd door de gebruiker
/// - [calendar]: geimporteerd uit Google Calendar
enum BlockType { work, custom, calendar }

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
    // Bestaande installs hebben zowel UTC- als lokale sleutels opgeslagen; alles
    // wordt hier op de canonieke vorm gebracht zodat oude blokken blijven werken.
    return normalizeBlockedHours(result);
  }

  /// Wisselt de aanwezigheid van [hour] als [BlockType.custom] entry.
  /// Verwijdert de entry als die al aanwezig is met type custom; voegt toe anders.
  Future<void> toggleCustomHour(DateTime hour) async {
    final current = await future;
    final key = canonicalHourKey(hour);
    final next = Map<DateTime, BlockType>.from(current);
    if (next[key] == BlockType.custom) {
      next.remove(key);
    } else {
      next[key] = BlockType.custom;
    }
    await _persist(next);
    state = AsyncData(next);
  }

  /// Zet of wist meerdere uren in één batch.
  /// Als [block] true is, worden alle [hours] als [BlockType.custom] gezet.
  /// Als [block] false is, worden alle [hours] gewist (alleen custom, niet work).
  Future<void> setCustomHours(List<DateTime> hours, {required bool block}) async {
    final current = await future;
    final next = Map<DateTime, BlockType>.from(current);
    for (final hour in hours) {
      final key = canonicalHourKey(hour);
      if (block) {
        if (next[key] != BlockType.work && next[key] != BlockType.calendar) {
          next[key] = BlockType.custom;
        }
      } else {
        if (next[key] == BlockType.custom) {
          next.remove(key);
        }
      }
    }
    await _persist(next);
    state = AsyncData(next);
  }

  /// Vervangt de work-blokken door [preset] en laat de rest ongemoeid.
  ///
  /// Presets beschrijven uitsluitend een werkpatroon. Eerder verving dit de
  /// volledige map, waardoor een tik op een preset-chip stilzwijgend alle
  /// handmatige en geïmporteerde blokken wiste. Volgt nu hetzelfde patroon als
  /// [importCalendarBlocks]: gericht één type verversen.
  Future<void> seedPreset(Map<DateTime, BlockType> preset) async {
    final current = await future;
    final next = Map<DateTime, BlockType>.from(current)
      ..removeWhere((_, type) => type == BlockType.work);
    for (final entry in preset.entries) {
      final key = canonicalHourKey(entry.key);
      if (!next.containsKey(key)) {
        next[key] = BlockType.work;
      }
    }
    await _persist(next);
    if (ref.mounted) state = AsyncData(next);
  }

  /// Importeert uren uit Google Calendar als [BlockType.calendar] entries.
  /// Verwijdert eerst alle bestaande calendar-entries voor de opgegeven week,
  /// dan voegt de nieuwe toe. Laat work- en custom-blocks ongemoeid.
  Future<void> importCalendarBlocks(Map<DateTime, BlockType> calendarBlocks) async {
    final current = await future;
    final next = Map<DateTime, BlockType>.from(current);
    // Verwijder bestaande calendar-entries
    next.removeWhere((_, type) => type == BlockType.calendar);
    // Voeg nieuwe calendar-entries toe (overschrijf niet work/custom)
    for (final entry in calendarBlocks.entries) {
      final key = canonicalHourKey(entry.key);
      if (!next.containsKey(key)) {
        next[key] = BlockType.calendar;
      }
    }
    await _persist(next);
    state = AsyncData(next);
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
