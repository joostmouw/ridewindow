import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/availability_repository.dart';
import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/services/availability_key.dart';

export 'package:ridewindow/domain/models/block_type.dart' show BlockType;

part 'availability_notifier.g.dart';

/// Construeert de [AvailabilityRepository]. Gebruikt bewust `getInstance()`
/// (asynchroon), niet `sharedPrefsProvider` — die gooit `UnimplementedError`
/// tenzij overschreven, en de bestaande availability-tests leunen allemaal op
/// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.
@riverpod
Future<AvailabilityRepository> availabilityRepository(Ref ref) async {
  return AvailabilityRepository(await SharedPreferences.getInstance());
}

/// AvailabilityNotifier beheert de geblokkeerde uren als `Map<DateTime, BlockType>`.
///
/// Persistentie loopt via [AvailabilityRepository]. Deze notifier is een
/// dunne laag: hij houdt de publieke API en de mutatie-logica, de repository
/// is de enige plek die het opslagformaat kent.
///
/// Volledig context-loos en testbaar via ProviderContainer.
@riverpod
class AvailabilityNotifier extends _$AvailabilityNotifier {
  @override
  Future<Map<DateTime, BlockType>> build() async {
    final repo = await ref.watch(availabilityRepositoryProvider.future);
    return repo.readLocal();
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
    final repo = await ref.read(availabilityRepositoryProvider.future);
    await repo.save(next);
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
    final repo = await ref.read(availabilityRepositoryProvider.future);
    await repo.save(next);
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
    final repo = await ref.read(availabilityRepositoryProvider.future);
    await repo.save(next);
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
    final repo = await ref.read(availabilityRepositoryProvider.future);
    await repo.save(next);
    state = AsyncData(next);
  }

  /// Wist alle geblokkeerde uren.
  Future<void> clearAll() async {
    final repo = await ref.read(availabilityRepositoryProvider.future);
    await repo.save(const {});
    state = const AsyncData(<DateTime, BlockType>{});
  }
}
