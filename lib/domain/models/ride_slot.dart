import 'package:freezed_annotation/freezed_annotation.dart';

import 'hourly_score.dart';
import 'ride_tier.dart';

part 'ride_slot.freezed.dart';

@freezed
abstract class RideSlot with _$RideSlot {
  const factory RideSlot({
    /// Inclusive start of slot.
    required DateTime start,

    /// Exclusive end of slot — [start, end) convention.
    required DateTime end,

    required double overallScore,
    required RideTier tier,
    required List<HourlyScore> hours,
  }) = _RideSlot;
}

/// Index van het slot dat "Best choice" verdient: de **hoogste score**.
///
/// Dit bestaat als losse functie omdat het antwoord ooit stilzwijgend "index 0"
/// was. Home sorteerde op tier en brak gelijk op starttijd, dus binnen dezelfde
/// tier won de vróégste — een rit van 99 kreeg het label terwijl er verderop in
/// de lijst een 100 stond. Het scherm wees dus met veel nadruk de verkeerde
/// kaart aan, en dat raakt de kernwaarde van de app en niet de opmaak.
///
/// Bij een gelijke score wint de vroegste rit: bij twee even goede vensters is
/// het eerstvolgende het bruikbaarst. Keuze van Joost, 2026-09-07.
///
/// Geeft `-1` terug voor een lege lijst.
int indexOfBestSlot(List<RideSlot> slots) {
  if (slots.isEmpty) return -1;
  var best = 0;
  for (var i = 1; i < slots.length; i++) {
    final candidate = slots[i];
    final current = slots[best];
    if (candidate.overallScore > current.overallScore ||
        (candidate.overallScore == current.overallScore &&
            candidate.start.isBefore(current.start))) {
      best = i;
    }
  }
  return best;
}
