// test/domain/services/drag_run_counter_test.dart
// Unit tests for countSelectionRuns (backlog #35 logic) — pure function,
// no BuildContext/widget dependency.

import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/domain/services/drag_run_counter.dart';

void main() {
  group('countSelectionRuns', () {
    test('empty set returns 0', () {
      expect(countSelectionRuns(<DateTime>{}), 0);
    });

    test('single cell returns 1', () {
      final cells = {DateTime.utc(2026, 7, 13, 9)};
      expect(countSelectionRuns(cells), 1);
    });

    test('three consecutive hours on the same day return 1 run', () {
      final cells = {
        DateTime.utc(2026, 7, 13, 9),
        DateTime.utc(2026, 7, 13, 10),
        DateTime.utc(2026, 7, 13, 11),
      };
      expect(countSelectionRuns(cells), 1);
    });

    test('same hour on three different days returns 3 runs', () {
      final cells = {
        DateTime.utc(2026, 7, 13, 17),
        DateTime.utc(2026, 7, 14, 17),
        DateTime.utc(2026, 7, 15, 17),
      };
      expect(countSelectionRuns(cells), 3);
    });

    test('two separate runs on the same day with a gap return 2', () {
      final cells = {
        DateTime.utc(2026, 7, 13, 9),
        DateTime.utc(2026, 7, 13, 10),
        DateTime.utc(2026, 7, 13, 14),
      };
      expect(countSelectionRuns(cells), 2);
    });

    test('mixed case: 2 runs on one day + 1 run on a different day returns 3', () {
      final cells = {
        DateTime.utc(2026, 7, 13, 9),
        DateTime.utc(2026, 7, 13, 10),
        DateTime.utc(2026, 7, 13, 14),
        DateTime.utc(2026, 7, 14, 8),
      };
      expect(countSelectionRuns(cells), 3);
    });

    test('insertion order does not affect the count (function sorts internally)', () {
      final cells = {
        DateTime.utc(2026, 7, 13, 14),
        DateTime.utc(2026, 7, 13, 9),
        DateTime.utc(2026, 7, 14, 8),
        DateTime.utc(2026, 7, 13, 10),
      };
      expect(countSelectionRuns(cells), 3);
    });
  });
}
