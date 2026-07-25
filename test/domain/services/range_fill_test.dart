// Unit tests voor computeRangeFillKeys (BACKLOG-rne: two-tap range-select).
// Pure function tests — no widget/BuildContext dependency.

import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/services/range_fill.dart';
import 'package:ridewindow/providers/availability_notifier.dart';

void main() {
  group('computeRangeFillKeys', () {
    test('ascending: anchor 9, second-tap 11, same day, no blocks -> [9, 10, 11]', () {
      final anchor = DateTime(2026, 7, 13, 9);
      final secondTap = DateTime(2026, 7, 13, 11);

      final result = computeRangeFillKeys(
        anchorKey: anchor,
        secondTapKey: secondTap,
        blockedHours: const {},
      );

      expect(result, [
        DateTime(2026, 7, 13, 9),
        DateTime(2026, 7, 13, 10),
        DateTime(2026, 7, 13, 11),
      ]);
    });

    test('descending: anchor 11, second-tap 9, same day, no blocks -> still [9, 10, 11] ascending', () {
      final anchor = DateTime(2026, 7, 13, 11);
      final secondTap = DateTime(2026, 7, 13, 9);

      final result = computeRangeFillKeys(
        anchorKey: anchor,
        secondTapKey: secondTap,
        blockedHours: const {},
      );

      expect(result, [
        DateTime(2026, 7, 13, 9),
        DateTime(2026, 7, 13, 10),
        DateTime(2026, 7, 13, 11),
      ]);
    });

    test('same key for anchor and second tap -> single-element list', () {
      final key = DateTime(2026, 7, 13, 9);

      final result = computeRangeFillKeys(
        anchorKey: key,
        secondTapKey: key,
        blockedHours: const {},
      );

      expect(result, [DateTime(2026, 7, 13, 9)]);
    });

    test('work-blocked hour in the middle is skipped, not overwritten', () {
      final anchor = DateTime(2026, 7, 13, 9);
      final secondTap = DateTime(2026, 7, 13, 13);
      final blocked = {
        DateTime(2026, 7, 13, 11): BlockType.work,
      };

      final result = computeRangeFillKeys(
        anchorKey: anchor,
        secondTapKey: secondTap,
        blockedHours: blocked,
      );

      expect(result, [
        DateTime(2026, 7, 13, 9),
        DateTime(2026, 7, 13, 10),
        DateTime(2026, 7, 13, 12),
        DateTime(2026, 7, 13, 13),
      ]);
    });

    test('calendar-blocked hour in the middle is skipped, not overwritten', () {
      final anchor = DateTime(2026, 7, 13, 9);
      final secondTap = DateTime(2026, 7, 13, 13);
      final blocked = {
        DateTime(2026, 7, 13, 11): BlockType.calendar,
      };

      final result = computeRangeFillKeys(
        anchorKey: anchor,
        secondTapKey: secondTap,
        blockedHours: blocked,
      );

      expect(result, [
        DateTime(2026, 7, 13, 9),
        DateTime(2026, 7, 13, 10),
        DateTime(2026, 7, 13, 12),
        DateTime(2026, 7, 13, 13),
      ]);
    });

    test('already-custom hour in the middle is included (toggleable, not a skip case)', () {
      final anchor = DateTime(2026, 7, 13, 9);
      final secondTap = DateTime(2026, 7, 13, 11);
      final blocked = {
        DateTime(2026, 7, 13, 10): BlockType.custom,
      };

      final result = computeRangeFillKeys(
        anchorKey: anchor,
        secondTapKey: secondTap,
        blockedHours: blocked,
      );

      expect(result, [
        DateTime(2026, 7, 13, 9),
        DateTime(2026, 7, 13, 10),
        DateTime(2026, 7, 13, 11),
      ]);
    });
  });
}
