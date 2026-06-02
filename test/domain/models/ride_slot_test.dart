import 'package:test/test.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';

void main() {
  final start = DateTime(2025, 7, 5, 9);
  final end = DateTime(2025, 7, 5, 11); // exclusive end: [09:00, 11:00)

  HourlyScore _score(DateTime t) => HourlyScore(
        overall: 86.0,
        temperatureScore: 90.0,
        rainScore: 100.0,
        windScore: 80.0,
        time: t,
      );

  RideSlot _slot({double score = 86.0}) => RideSlot(
        start: start,
        end: end,
        overallScore: score,
        tier: rideTierFromScore(score),
        hours: [_score(start), _score(start.add(const Duration(hours: 1)))],
      );

  group('RideSlot', () {
    test('equality: identical fields are equal', () {
      expect(_slot(), equals(_slot()));
    });

    test('copyWith: overallScore updated', () {
      final copy = _slot().copyWith(overallScore: 90.0);
      expect(copy.overallScore, 90.0);
      expect(copy.start, start);
      expect(copy.end, end);
    });

    test('tier assignment: score 86.0 yields Perfect', () {
      expect(_slot(score: 86.0).tier, isA<Perfect>());
    });

    test('[start, end) convention: end - start == slot duration', () {
      // A 2h slot starting at 09:00 has end == 11:00.
      // The hour at end (11:00) is NOT covered — end is exclusive.
      final slot = _slot();
      expect(slot.end.difference(slot.start), const Duration(hours: 2));
      // Verify 11:00 is not in the hours list
      expect(slot.hours.any((h) => h.time == end), isFalse);
    });
  });
}
