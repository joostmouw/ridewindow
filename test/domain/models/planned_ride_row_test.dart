import 'package:test/test.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';

void main() {
  group('PlannedRide.rideId — deterministic sanitized id', () {
    // Herzien in plan 21-13. Deze test verwachtte eerder de LOKALE ISO-vorm
    // ('2026-08-10T09-00-00-000'), wat de bug vastlegde in plaats van het
    // gedrag: dezelfde rit kreeg een andere sleutel zodra hij uit Postgres
    // kwam. De sleutel is nu per definitie de UTC-instant. Zet dit niet terug.
    test('is the sanitized ISO8601 of start in UTC (colons/dots replaced with -)',
        () {
      final start = DateTime.parse('2026-08-10T09:00:00.000');
      final ride = PlannedRide(
        start: start,
        end: DateTime.parse('2026-08-10T13:00:00.000'),
        plannedScore: 82.5,
      );

      expect(
        ride.rideId,
        start.toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-'),
      );
      // Onafhankelijk van de tijdzone van de machine: de sleutel is een
      // UTC-instant, dus hij eindigt altijd op Z.
      expect(ride.rideId, endsWith('Z'));
    });

    test('twee objecten voor hetzelfde tijdstip delen één sleutel, ook als de '
        'een lokaal is en de ander UTC', () {
      final local = DateTime(2026, 8, 10, 9);
      final a = PlannedRide(
        start: local,
        end: local.add(const Duration(hours: 4)),
        plannedScore: 82.5,
      );
      final b = PlannedRide(
        start: local.toUtc(),
        end: local.add(const Duration(hours: 4)).toUtc(),
        plannedScore: 82.5,
      );

      expect(a.rideId, b.rideId);
    });
  });

  group('PlannedRide.toRow/fromRow — public.planned_rides row shape (SYNC-03)', () {
    // Herzien in plan 21-13: de verwachte waarden waren offsetloze lokale
    // strings, wat precies de dubbelzinnigheid was die Postgres als UTC las.
    test('toRow() produces the exact 5-column shape, in UTC', () {
      final start = DateTime.parse('2026-08-10T09:00:00.000');
      final end = DateTime.parse('2026-08-10T13:00:00.000');
      final ride = PlannedRide(start: start, end: end, plannedScore: 82.5);

      final row = ride.toRow('uid-1');

      expect(row, {
        'user_id': 'uid-1',
        'ride_id':
            start.toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-'),
        'start_at': start.toUtc().toIso8601String(),
        'end_at': end.toUtc().toIso8601String(),
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

  // Plan 21-13. De round-trip-test hierboven sluit BINNEN Dart: toRow() schreef
  // een offsetloze string en DateTime.parse() maakt daar weer een lokale
  // DateTime van. Postgres doet dat niet -- start_at is `timestamptz`, dus de
  // waarde wordt genormaliseerd en PostgREST geeft hem terug mét offset. Deze
  // groep begint daarom bij de wire-vorm die de database echt teruggeeft.
  group('rideId overleeft de rondgang door Postgres (plan 21-13)', () {
    /// Bootst na wat PostgREST teruggeeft voor een `timestamptz`: hetzelfde
    /// tijdstip, uitgedrukt in UTC met een expliciete `+00:00`-offset.
    Map<String, dynamic> asPostgrestRow(PlannedRide ride, String userId) => {
          'user_id': userId,
          'ride_id': ride.rideId,
          'start_at':
              ride.start.toUtc().toIso8601String().replaceFirst('Z', '+00:00'),
          'end_at':
              ride.end.toUtc().toIso8601String().replaceFirst('Z', '+00:00'),
          'planned_score': ride.plannedScore,
        };

    test('een lokaal aangemaakte rit en dezelfde rit uit de cloud delen één rideId',
        () {
      final local = PlannedRide(
        start: DateTime(2026, 8, 8, 12),
        end: DateTime(2026, 8, 8, 15),
        plannedScore: 100.0,
      );

      // Voorwaarde voor deze test: de lokale zone moet van UTC verschillen,
      // anders kan de splitsing zich niet voordoen en zou een groene run
      // niets bewijzen. Luid falen is hier beter dan stil slagen.
      expect(
        local.start.timeZoneOffset,
        isNot(Duration.zero),
        reason: 'Deze test moet in een niet-UTC tijdzone draaien; op een '
            'UTC-machine is hij betekenisloos in plaats van geslaagd.',
      );

      final fromCloud = PlannedRide.fromRow(asPostgrestRow(local, 'uid-1'));

      expect(
        fromCloud.rideId,
        local.rideId,
        reason: 'dezelfde rit mag niet twee sleutels krijgen omdat hij door '
            'een timestamptz-kolom is geweest',
      );
    });

    test('toRow() schrijft een expliciete UTC-instant, niet een offsetloze string',
        () {
      final ride = PlannedRide(
        start: DateTime(2026, 8, 8, 12),
        end: DateTime(2026, 8, 8, 15),
        plannedScore: 100.0,
      );

      final row = ride.toRow('uid-1');

      // Zonder offset bepaalt de lezer de betekenis -- precies de dubbelzinnig-
      // heid waar de duplicaatbug uit voortkwam.
      expect(row['start_at'], endsWith('Z'));
      expect(row['end_at'], endsWith('Z'));
      expect(
        DateTime.parse(row['start_at'] as String).isAtSameMomentAs(ride.start),
        isTrue,
      );
    });

    test('fromRow() geeft lokale tijd terug, zodat beide kopieën gelijk tonen',
        () {
      final local = PlannedRide(
        start: DateTime(2026, 8, 8, 12),
        end: DateTime(2026, 8, 8, 15),
        plannedScore: 100.0,
      );

      final fromCloud = PlannedRide.fromRow(asPostgrestRow(local, 'uid-1'));

      // Zonder .toLocal() zou de cloud-kopie op 10:00 renderen waar de lokale
      // op 12:00 staat: geen duplicaat meer, maar twee uur verschil.
      expect(fromCloud.start.hour, local.start.hour);
      expect(fromCloud.start.isUtc, isFalse);
    });
  });
}
