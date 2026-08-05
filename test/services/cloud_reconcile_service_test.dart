import 'package:test/test.dart';
import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';
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

  group('parsePlannedRidesRows', () {
    test('empty rows list parses to an empty list (no "no data yet" sentinel)',
        () {
      expect(service.parsePlannedRidesRows(const []), isEmpty);
    });

    test('maps each row through PlannedRide.fromRow', () {
      final ride = PlannedRide(
        start: DateTime.parse('2026-08-10T09:00:00.000'),
        end: DateTime.parse('2026-08-10T13:00:00.000'),
        plannedScore: 82.5,
      );

      final result = service.parsePlannedRidesRows([ride.toRow('uid-1')]);

      expect(result, hasLength(1));
      expect(result.single.start, ride.start);
      expect(result.single.end, ride.end);
      expect(result.single.plannedScore, ride.plannedScore);
    });
  });

  group('mergePlannedRides — union merge (plan 21-05, SYNC-03)', () {
    PlannedRide ride(String isoStart, double score) => PlannedRide(
          start: DateTime.parse(isoStart),
          end: DateTime.parse(isoStart).add(const Duration(hours: 2)),
          plannedScore: score,
        );

    test(
        'local [A, B] + cloud [B, C] (by rideId) merges to [A, B, C] sorted by '
        'start, localOnly is exactly [A]', () {
      final a = ride('2026-08-10T09:00:00.000', 70.0);
      final b = ride('2026-08-11T09:00:00.000', 75.0);
      // Same rideId as b (same start) but a different cloud-side score —
      // proves the union keeps the LOCAL copy for ids present on both
      // sides (putIfAbsent semantics), not a cloud overwrite.
      final bFromCloud = ride('2026-08-11T09:00:00.000', 999.0);
      final c = ride('2026-08-12T09:00:00.000', 80.0);

      final result = service.mergePlannedRides(
        local: [a, b],
        cloud: [bFromCloud, c],
      );

      expect(result.merged.map((r) => r.rideId).toList(), [
        a.rideId,
        b.rideId,
        c.rideId,
      ]);
      expect(
        result.merged.firstWhere((r) => r.rideId == b.rideId).plannedScore,
        75.0,
        reason: 'local copy of a shared rideId wins the union, not the cloud copy',
      );
      expect(result.localOnly, hasLength(1));
      expect(result.localOnly.single.rideId, a.rideId);
    });

    test('local [A] + cloud [] merges to just [A], localOnly is [A]', () {
      final a = ride('2026-08-10T09:00:00.000', 70.0);

      final result = service.mergePlannedRides(local: [a], cloud: const []);

      expect(result.merged.map((r) => r.rideId).toList(), [a.rideId]);
      expect(result.localOnly, hasLength(1));
      expect(result.localOnly.single.rideId, a.rideId);
    });

    test('local [] + cloud [X] merges to [X], localOnly is empty', () {
      final x = ride('2026-08-10T09:00:00.000', 70.0);

      final result = service.mergePlannedRides(local: const [], cloud: [x]);

      expect(result.merged.map((r) => r.rideId).toList(), [x.rideId]);
      expect(result.localOnly, isEmpty);
    });

    // Plan 21-13. De `ride()`-helper hierboven bouwt beide kanten met een
    // offsetloze string, dus lokaal én "cloud" zijn allebei lokale DateTimes en
    // de splitsing kán zich in die tests niet voordoen. Deze test haalt de
    // cloud-kant door de echte parse-route heen.
    test('dezelfde rit, lokaal en teruggelezen uit Postgres, smelt samen tot één',
        () {
      final local = PlannedRide(
        start: DateTime(2026, 8, 11, 9),
        end: DateTime(2026, 8, 11, 11),
        plannedScore: 75.0,
      );

      expect(
        local.start.timeZoneOffset,
        isNot(Duration.zero),
        reason: 'moet in een niet-UTC tijdzone draaien om iets te bewijzen',
      );

      // Zoals PostgREST een timestamptz teruggeeft: UTC, met expliciete offset.
      final fromCloud = PlannedRide.fromRow({
        'user_id': 'uid-1',
        'ride_id': local.rideId,
        'start_at':
            local.start.toUtc().toIso8601String().replaceFirst('Z', '+00:00'),
        'end_at':
            local.end.toUtc().toIso8601String().replaceFirst('Z', '+00:00'),
        'planned_score': 75.0,
      });

      final result =
          service.mergePlannedRides(local: [local], cloud: [fromCloud]);

      expect(
        result.merged,
        hasLength(1),
        reason: 'één rit die door de cloud is geweest blijft één rit',
      );
      expect(
        result.localOnly,
        isEmpty,
        reason: 'de rit staat al in de cloud, dus er valt niets te pushen',
      );
    });
  });
}
