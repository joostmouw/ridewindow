import '../models/ride_slot.dart';
import '../models/ride_tier.dart';
import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/services/availability_key.dart';

/// Filters ride slots by availability and quality tier.
/// Poor-tier slots (score < 50) are hidden from the UI per SLOT-04.
/// Blocked hours use the same [start, end) convention as RideSlot.
class AvailabilityFilter {
  /// Removes slots that overlap any hour in [blockedHours].
  ///
  /// A slot overlaps a blocked hour if any hour within [slot.start, slot.end)
  /// is blocked. The slot's end is exclusive.
  /// All entries in [blockedHours] block, regardless of [BlockType] — the type
  /// only determines *when* they apply (see [BlockedHours]).
  List<RideSlot> removeBlocked(
    List<RideSlot> slots,
    Map<DateTime, BlockType> blockedHours,
  ) {
    final blocked = BlockedHours(blockedHours);
    return slots.where((slot) => !_overlapsBlocked(slot, blocked)).toList();
  }

  /// Removes Poor-tier slots (hidden from the UI per SLOT-04).
  List<RideSlot> removeHiddenPoor(List<RideSlot> slots) {
    return slots.where((slot) => slot.tier is! Poor).toList();
  }

  /// Applies both [removeBlocked] and [removeHiddenPoor].
  List<RideSlot> apply(
    List<RideSlot> slots,
    Map<DateTime, BlockType> blockedHours,
  ) {
    return removeHiddenPoor(removeBlocked(slots, blockedHours));
  }

  bool _overlapsBlocked(RideSlot slot, BlockedHours blocked) {
    var current = slot.start;
    while (current.isBefore(slot.end)) {
      if (blocked.isBlocked(current)) return true;
      current = current.add(const Duration(hours: 1));
    }
    return false;
  }
}
