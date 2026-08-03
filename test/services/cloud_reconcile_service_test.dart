import 'package:test/test.dart';
import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/services/cloud_reconcile_service.dart';

void main() {
  late CloudReconcileService service;

  setUp(() {
    service = CloudReconcileService();
  });

  group('parseProfileRow', () {
    test('returns null when the row is null (no cloud profile yet)', () {
      expect(service.parseProfileRow(null), isNull);
    });

    test('parses a row into UserProfile + updated_at DateTime', () {
      final result = service.parseProfileRow({
        'user_id': 'uid-1',
        'temp_min_ideal_c': 8.0,
        'temp_max_ideal_c': 24.0,
        'wind_max_ideal_kmh': 20.0,
        'rain_max_ideal_mm': 1.0,
        'allowed_durations': [2, 4],
        'theme': 'dark',
        'locale': 'en',
        'location_override': 'Utrecht',
        'user_name': 'Joost',
        'notif_evening_before': true,
        'notif_morning_of': false,
        'notif_weekly_digest': true,
        'updated_at': '2026-08-01T12:00:00.000Z',
      });

      expect(result, isNotNull);
      expect(result!.profile.userName, 'Joost');
      expect(result.profile.theme, 'dark');
      expect(result.updatedAt, DateTime.parse('2026-08-01T12:00:00.000Z'));
    });
  });

  group('parseAvailabilityRow', () {
    test('returns null when the row is null (no cloud availability yet)', () {
      expect(service.parseAvailabilityRow(null), isNull);
    });

    test('parses a row into a BlockType map + updated_at DateTime', () {
      final result = service.parseAvailabilityRow({
        'recurring': {'2-9': 'work', '2-17': 'custom'},
        'updated_at': '2026-08-01T12:00:00.000Z',
      });

      expect(result, isNotNull);
      expect(result!.hours.length, 2);
      expect(result.hours.values.toSet(), {BlockType.work, BlockType.custom});
      expect(result.updatedAt, DateTime.parse('2026-08-01T12:00:00.000Z'));
    });
  });
}
