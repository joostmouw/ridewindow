import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/services/availability_filter.dart';
import 'package:ridewindow/domain/services/scoring_engine.dart';
import 'package:ridewindow/domain/services/slot_generator.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

part 'slots_notifier.g.dart';

// ---------------------------------------------------------------------------
// SlotsState: sealed class voor expliciete empty-state (SLOT-05)
// ---------------------------------------------------------------------------

/// Sealed basis voor de slots-provider output.
/// Gebruik patroonmatching om SlotsLoaded te onderscheiden.
sealed class SlotsState {
  const SlotsState();
}

/// Provider heeft slots berekend (lijst kan leeg zijn als [reason] != null).
final class SlotsLoaded extends SlotsState {
  /// Gefilterde, niet-Poor ride slots; leeg als [reason] != null.
  final List<RideSlot> slots;

  /// Reden voor lege lijst, of null als er wel slots zijn.
  final SlotsEmptyReason? reason;

  const SlotsLoaded(this.slots, {this.reason});
}

/// Reden waarom de slots-lijst leeg is.
enum SlotsEmptyReason {
  /// Geen enkel uur haalt een acceptabele score (alle slots zijn Poor-tier).
  badWeather,

  /// Er zijn goede uren maar alle zijn geblokkeerd door de gebruiker.
  allBlocked,
}

// ---------------------------------------------------------------------------
// SlotsNotifier: reactieve provider — hercomputed bij elke input-wijziging
// ---------------------------------------------------------------------------

/// SlotsNotifier combineert weer, profiel en beschikbaarheid tot gefilterde
/// `List<RideSlot>`. Riverpod hercomputed automatisch als een van de drie
/// providers een nieuwe waarde emit — geen handmatige refresh nodig.
///
/// Gebruikt synchrone `Notifier<SlotsState>` zodat de UI nooit hoeft te wachten
/// op een Future; loading-propagatie wordt via het [SlotsLoaded] leeg-pad gedaan.
@riverpod
class SlotsNotifier extends _$SlotsNotifier {
  static final _scoring = ScoringEngine();
  static final _generator = SlotGenerator();
  static final _filter = AvailabilityFilter();

  @override
  SlotsState build() {
    // Observeer alle drie upstream providers reactief.
    final weatherValue = ref.watch(weatherProvider);
    final profileValue = ref.watch(profileProvider);
    final availValue = ref.watch(availabilityProvider);

    // Als een van de drie nog laadt of een fout heeft: geef lege slots terug.
    if (weatherValue.isLoading ||
        weatherValue.hasError ||
        profileValue.isLoading ||
        profileValue.hasError ||
        availValue.isLoading ||
        availValue.hasError) {
      return const SlotsLoaded([]);
    }

    final forecasts = weatherValue.requireValue;
    final profile = profileValue.requireValue;
    final blockedHours = availValue.requireValue;

    // Score alle uren (incl. regenkans + niet-lineaire curves).
    final scores = forecasts
        .map((fc) => _scoring.score(fc, profile.tolerances))
        .toList();

    // Genereer slots voor alle toegestane rijduren (nachtfilter 06–22).
    var allSlots = _generator.generate(
      scores,
      allowedDurations: profile.allowedDurations,
      minHour: 6,
      maxHour: 22,
    );

    // Pas slot-niveau penalties toe (trend + windconsistentie).
    allSlots = _generator.refine(allSlots, forecasts);

    // Verwijder geblokkeerde uren én Poor-tier slots.
    var filtered = _filter.apply(allSlots, blockedHours);

    // Dedup: verwijder overlappende inferieure slots.
    filtered = _generator.dedup(filtered);

    if (filtered.isNotEmpty) {
      return SlotsLoaded(filtered);
    }

    // Bepaal reden voor lege lijst.
    final reason = _determineReason(allSlots, blockedHours);
    return SlotsLoaded(const [], reason: reason);
  }

  /// Bepaalt waarom de gefilterde lijst leeg is.
  ///
  /// - Als er geen slots waren vóór filtering (of allemaal Poor): [SlotsEmptyReason.badWeather].
  /// - Als er wel slots waren maar alle geblokkeerd: [SlotsEmptyReason.allBlocked].
  SlotsEmptyReason? _determineReason(
    List<RideSlot> allSlots,
    Map<DateTime, BlockType> blockedHours,
  ) {
    if (allSlots.isEmpty) return SlotsEmptyReason.badWeather;

    // Verwijder alleen Poor-tier (zonder blocked-filter) om te zien of er
    // inhoudelijk goede slots zijn.
    final nonPoorSlots = _filter.removeHiddenPoor(allSlots);

    if (nonPoorSlots.isEmpty) return SlotsEmptyReason.badWeather;

    // Er zijn non-Poor slots maar ze zijn allemaal geblokkeerd.
    return SlotsEmptyReason.allBlocked;
  }
}
