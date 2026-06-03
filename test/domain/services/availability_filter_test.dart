import 'package:test/test.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/services/availability_filter.dart';
import 'package:ridewindow/providers/availability_notifier.dart';

RideSlot _slot(DateTime start, int durationHours, double score) {
  final end = start.add(Duration(hours: durationHours));
  final tier = rideTierFromScore(score);
  final hours = List.generate(
    durationHours,
    (i) => HourlyScore(
      overall: score,
      temperatureScore: score,
      rainScore: score,
      windScore: score,
      time: start.add(Duration(hours: i)),
    ),
  );
  return RideSlot(
    start: start,
    end: end,
    overallScore: score,
    tier: tier,
    hours: hours,
  );
}

void main() {
  final filter = AvailabilityFilter();
  final d = DateTime(2025, 7, 5);

  DateTime h(int hour) => DateTime(d.year, d.month, d.day, hour);

  group('removeBlocked', () {
    test('blocked hour == slot.start → slot removed', () {
      final slot = _slot(h(9), 2, 90.0); // [09:00, 11:00)
      expect(filter.removeBlocked([slot], {h(9): BlockType.custom}), isEmpty);
    });

    test('blocked hour inside slot (not start) → slot removed', () {
      final slot = _slot(h(9), 2, 90.0); // [09:00, 11:00), 10:00 is inside
      expect(filter.removeBlocked([slot], {h(10): BlockType.custom}), isEmpty);
    });

    test('blocked hour == slot.end → slot kept (end is exclusive per [start, end))', () {
      final slot = _slot(h(9), 2, 90.0); // end == 11:00, exclusive
      expect(filter.removeBlocked([slot], {h(11): BlockType.custom}), [slot]);
    });

    test('blocked hour before slot.start → slot kept', () {
      final slot = _slot(h(9), 2, 90.0);
      expect(filter.removeBlocked([slot], {h(8): BlockType.custom}), [slot]);
    });

    test('two slots, one blocked → only unblocked slot remains', () {
      final slotA = _slot(h(9), 2, 90.0);  // [09:00, 11:00)
      final slotB = _slot(h(13), 2, 90.0); // [13:00, 15:00)
      final result = filter.removeBlocked([slotA, slotB], {h(10): BlockType.custom});
      expect(result.length, 1);
      expect(result.first.start, h(13));
    });

    test('empty slots list → returns empty', () {
      expect(filter.removeBlocked([], {h(9): BlockType.custom}), isEmpty);
    });

    test('work-blocked hour also blocks slot (BlockType.work)', () {
      final slot = _slot(h(9), 2, 90.0); // [09:00, 11:00)
      expect(filter.removeBlocked([slot], {h(9): BlockType.work}), isEmpty);
    });
  });

  group('removeHiddenPoor — SLOT-04', () {
    test('mix of all tiers → only Perfect+Great+Acceptable returned', () {
      final slots = [
        _slot(h(8), 2, 90.0),  // Perfect
        _slot(h(10), 2, 75.0), // Great
        _slot(h(12), 2, 55.0), // Acceptable
        _slot(h(14), 2, 40.0), // Poor — hidden
      ];
      final result = filter.removeHiddenPoor(slots);
      expect(result.length, 3);
      expect(result.any((s) => s.tier is Poor), isFalse);
    });

    test('only Poor slots → returns empty list', () {
      final slots = [_slot(h(8), 2, 30.0), _slot(h(10), 2, 20.0)];
      expect(filter.removeHiddenPoor(slots), isEmpty);
    });

    test('no Poor slots → all slots returned', () {
      final slots = [_slot(h(8), 2, 90.0), _slot(h(10), 2, 75.0)];
      expect(filter.removeHiddenPoor(slots).length, 2);
    });
  });

  group('apply (combined filter)', () {
    test('A=Perfect no-overlap, B=Great blocked, C=Acceptable no-overlap, D=Poor no-overlap → [A, C]', () {
      final slotA = _slot(h(8), 2, 90.0);  // Perfect, unblocked → kept
      final slotB = _slot(h(10), 2, 75.0); // Great, blocked at h(10) → removed
      final slotC = _slot(h(12), 2, 55.0); // Acceptable, unblocked → kept
      final slotD = _slot(h(14), 2, 40.0); // Poor → hidden

      final result = filter.apply([slotA, slotB, slotC, slotD], {h(10): BlockType.custom});
      expect(result.length, 2);
      expect(result[0].start, h(8));
      expect(result[1].start, h(12));
    });

    test('apply with empty slots → returns empty', () {
      expect(filter.apply([], {h(9): BlockType.custom}), isEmpty);
    });
  });
}
