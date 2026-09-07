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

  group('indexOfBestSlot', () {
    RideSlot at(int hour, double score) {
      final s = DateTime(2025, 7, 5, hour);
      final e = s.add(const Duration(hours: 2));
      return RideSlot(
        start: s,
        end: e,
        overallScore: score,
        tier: rideTierFromScore(score),
        hours: [_score(s)],
      );
    }

    test('kiest de hoogste score, ook als die later op de dag ligt', () {
      // Precies de situatie die op 2026-09-07 op het scherm stond: de lijst is
      // chronologisch binnen dezelfde tier, en de vroegste rit scoorde 99
      // terwijl de rit erna 100 haalde. Voor deze fix won plek 0 altijd.
      final slots = [at(6, 99), at(8, 100), at(10, 98)];
      expect(indexOfBestSlot(slots), 1);
    });

    test('bij een gelijke score wint de vroegste rit', () {
      final slots = [at(6, 92), at(8, 92)];
      expect(indexOfBestSlot(slots), 0);
    });

    test('een gelijke score verderop in de lijst kaapt het label niet', () {
      // Andersom dan hierboven: de winnaar staat vooraan en een latere rit
      // evenaart hem. `>` alleen zou hier al goed gaan, maar de expliciete
      // tiebreak moet ook standhouden als de lijst ooit anders gesorteerd wordt.
      final slots = [at(12, 88), at(6, 88)];
      expect(indexOfBestSlot(slots), 1, reason: '06:00 ligt vóór 12:00');
    });

    test('één slot is zijn eigen beste', () {
      expect(indexOfBestSlot([at(9, 71)]), 0);
    });

    test('een lege lijst geeft -1 en crasht niet', () {
      expect(indexOfBestSlot(const []), -1);
    });
  });
}
