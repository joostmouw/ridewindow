import 'package:test/test.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';

void main() {
  final base = DateTime(2025, 7, 1, 9);

  group('HourlyScore', () {
    test('equality: identical fields are equal', () {
      final a = HourlyScore(
        overall: 85.0,
        temperatureScore: 90.0,
        rainScore: 100.0,
        windScore: 80.0,
        time: base,
      );
      final b = HourlyScore(
        overall: 85.0,
        temperatureScore: 90.0,
        rainScore: 100.0,
        windScore: 80.0,
        time: base,
      );
      expect(a, equals(b));
    });

    test('copyWith: overall updated, others unchanged', () {
      final original = HourlyScore(
        overall: 85.0,
        temperatureScore: 90.0,
        rainScore: 100.0,
        windScore: 80.0,
        time: base,
      );
      final copy = original.copyWith(overall: 75.0);
      expect(copy.overall, 75.0);
      expect(copy.temperatureScore, original.temperatureScore);
      expect(copy.rainScore, original.rainScore);
      expect(copy.windScore, original.windScore);
      expect(copy.time, original.time);
    });
  });
}
