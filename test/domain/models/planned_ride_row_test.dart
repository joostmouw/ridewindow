import 'package:test/test.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';

void main() {
  group('PlannedRide.rideId — deterministic sanitized id', () {
    test('is the sanitized ISO8601 of start (colons/dots replaced with -)',
        () {
      final ride = PlannedRide(
        start: DateTime.parse('2026-08-10T09:00:00.000'),
        end: DateTime.parse('2026-08-10T13:00:00.000'),
        plannedScore: 82.5,
      );

      expect(ride.rideId, '2026-08-10T09-00-00-000');
    });
  });

  group('PlannedRide.toRow/fromRow — public.planned_rides row shape (SYNC-03)', () {
    test('toRow() produces the exact 5-column shape', () {
      final ride = PlannedRide(
        start: DateTime.parse('2026-08-10T09:00:00.000'),
        end: DateTime.parse('2026-08-10T13:00:00.000'),
        plannedScore: 82.5,
      );

      final row = ride.toRow('uid-1');

      expect(row, {
        'user_id': 'uid-1',
        'ride_id': '2026-08-10T09-00-00-000',
        'start_at': '2026-08-10T09:00:00.000',
        'end_at': '2026-08-10T13:00:00.000',
        'planned_score': 82.5,
      });
    });

    test('fromRow(toRow(userId)) round-trips to an equal start/end/plannedScore (MIG-08)', () {
      final ride = PlannedRide(
        start: DateTime.parse('2026-08-10T09:00:00.000'),
        end: DateTime.parse('2026-08-10T13:00:00.000'),
        plannedScore: 82.5,
      );

      final roundTripped = PlannedRide.fromRow(ride.toRow('uid-1'));

      expect(roundTripped.start, ride.start);
      expect(roundTripped.end, ride.end);
      expect(roundTripped.plannedScore, ride.plannedScore);
    });
  });
}
