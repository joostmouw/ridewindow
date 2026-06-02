import 'package:test/test.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';

void main() {
  group('rideTierFromScore', () {
    test('100.0 → Perfect', () => expect(rideTierFromScore(100.0), isA<Perfect>()));
    test('85.0 → Perfect (boundary, inclusive)', () => expect(rideTierFromScore(85.0), isA<Perfect>()));
    test('84.9 → Great', () => expect(rideTierFromScore(84.9), isA<Great>()));
    test('70.0 → Great (boundary, inclusive)', () => expect(rideTierFromScore(70.0), isA<Great>()));
    test('69.9 → Acceptable', () => expect(rideTierFromScore(69.9), isA<Acceptable>()));
    test('50.0 → Acceptable (boundary, inclusive)', () => expect(rideTierFromScore(50.0), isA<Acceptable>()));
    test('49.9 → Poor', () => expect(rideTierFromScore(49.9), isA<Poor>()));
    test('0.0 → Poor', () => expect(rideTierFromScore(0.0), isA<Poor>()));
  });
}
