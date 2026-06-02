import '../models/ride_slot.dart';
import '../models/ride_tier.dart';

/// Filters ride slots by availability and quality tier.
/// Poor-tier slots (score < 50) are hidden from the UI per SLOT-04.
/// Blocked hours use the same [start, end) convention as RideSlot.
class AvailabilityFilter {
  /// Removes slots that overlap any hour in [blockedHours].
  ///
  /// A slot overlaps a blocked hour if any hour within [slot.start, slot.end)
  /// is in [blockedHours]. The slot's end is exclusive.
  List<RideSlot> removeBlocked(
    List<RideSlot> slots,
    Set<DateTime> blockedHours,
  ) {
    return slots.where((slot) => !_overlapsBlocked(slot, blockedHours)).toList();
  }

  /// Removes Poor-tier slots (hidden from the UI per SLOT-04).
  List<RideSlot> removeHiddenPoor(List<RideSlot> slots) {
    return slots.where((slot) => slot.tier is! Poor).toList();
  }

  /// Applies both [removeBlocked] and [removeHiddenPoor].
  List<RideSlot> apply(List<RideSlot> slots, Set<DateTime> blockedHours) {
    return removeHiddenPoor(removeBlocked(slots, blockedHours));
  }

  bool _overlapsBlocked(RideSlot slot, Set<DateTime> blockedHours) {
    var current = slot.start;
    while (current.isBefore(slot.end)) {
      if (blockedHours.contains(current)) return true;
      current = current.add(const Duration(hours: 1));
    }
    return false;
  }
}
