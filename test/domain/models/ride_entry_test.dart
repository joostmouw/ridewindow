// test/domain/models/ride_entry_test.dart
//
// De samenvoeging van vier bronnen tot één lijst (schets 008).
//
// Wat hier bewaakt wordt is niet dat er een lijst uitkomt, maar dat een rit
// die in twee bronnen zit één regel blijft en dan de júiste rol draagt.
// Uitnodigen begint bij een rit die je al bekijkt, dus wie maatjes vraagt heeft
// dat tijdvak vrijwel altijd al als persoonlijke rit staan -- zonder
// ontdubbeling zou dezelfde rit als "Alleen jij" én als "Jij organiseert" in de
// lijst komen. Dat is precies de tegenspraak die dit scherm moest opheffen, en
// aan een screenshot van één rit is het niet te zien.

import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';

const _me = 'uid-me';
const _other = 'uid-other';

DateTime _at(int day, int hour) => DateTime(2026, 9, day, hour);

GroupRide _group({
  required String id,
  required String ownerId,
  required int day,
  int startHour = 9,
  int endHour = 13,
  List<RideParticipant> participants = const [],
}) =>
    GroupRide(
      id: id,
      ownerId: ownerId,
      start: _at(day, startHour),
      end: _at(day, endHour),
      plannedScore: 80,
      ownerName: ownerId == _me ? 'Ik' : 'Maatje',
      participants: participants,
    );

PlannedRide _planned(int day, {int startHour = 9, int endHour = 13}) =>
    PlannedRide(
      start: _at(day, startHour),
      end: _at(day, endHour),
      plannedScore: 42,
    );

void main() {
  group('buildRideEntries', () {
    test('zet alle vier de soorten in één lijst, op begintijd gesorteerd', () {
      final entries = buildRideEntries(
        planned: [_planned(18, startHour: 7, endHour: 9)],
        owned: [_group(id: 'g1', ownerId: _me, day: 14)],
        joined: [_group(id: 'g2', ownerId: _other, day: 16)],
        invites: [_group(id: 'g3', ownerId: _other, day: 13)],
      );

      expect(
        entries.map((e) => e.start.day).toList(),
        [13, 14, 16, 18],
        reason: 'chronologisch, niet gegroepeerd per rol',
      );
      expect(
        entries.map((e) => e.role).toList(),
        [RideRole.pending, RideRole.organiser, RideRole.joined, RideRole.solo],
      );
    });

    test(
        'een persoonlijke rit op hetzelfde tijdvak als een rit die jij '
        'organiseert wordt één regel, met de rol van de gedeelde rit', () {
      final entries = buildRideEntries(
        planned: [_planned(14)],
        owned: [_group(id: 'g1', ownerId: _me, day: 14)],
        joined: const [],
        invites: const [],
      );

      expect(entries, hasLength(1));
      expect(entries.single.role, RideRole.organiser);
      // De persoonlijke rij blijft hangen aan de regel: zonder die verwijzing
      // is hij na het afzeggen van de groepsrit niet meer op te ruimen en
      // blijft er een wees achter in `planned_rides`.
      expect(entries.single.planned, isNotNull);
      expect(entries.single.group, isNotNull);
    });

    test('de score van de gedeelde rit wint van die van de persoonlijke rij',
        () {
      final entries = buildRideEntries(
        planned: [_planned(14)], // plannedScore 42
        owned: [_group(id: 'g1', ownerId: _me, day: 14)], // plannedScore 80
        joined: const [],
        invites: const [],
      );

      expect(entries.single.plannedScore, 80);
    });

    test('een openstaande uitnodiging wint van elke andere rol op dat tijdvak',
        () {
      final entries = buildRideEntries(
        planned: [_planned(14)],
        owned: const [],
        joined: const [],
        invites: [_group(id: 'g1', ownerId: _other, day: 14)],
      );

      expect(entries.single.role, RideRole.pending);
    });

    test('een tijdvak dat maar één minuut verschilt blijft twee ritten', () {
      final entries = buildRideEntries(
        planned: [_planned(14)],
        owned: [_group(id: 'g1', ownerId: _me, day: 14, endHour: 12)],
        joined: const [],
        invites: const [],
      );

      expect(entries, hasLength(2),
          reason: 'ontdubbelen gaat op start én eind, niet op de dag');
    });

    test('notBefore snijdt weg wat voorbij is, en laat vandaag staan', () {
      final entries = buildRideEntries(
        planned: [
          _planned(10), // voorbij
          _planned(14), // straks
        ],
        owned: const [],
        joined: const [],
        invites: const [],
        notBefore: DateTime(2026, 9, 14),
      );

      expect(entries.map((e) => e.start.day).toList(), [14]);
    });

    test('zonder notBefore blijft alles staan', () {
      final entries = buildRideEntries(
        planned: [_planned(10), _planned(14)],
        owned: const [],
        joined: const [],
        invites: const [],
      );

      expect(entries, hasLength(2));
    });
  });

  group('RideEntry', () {
    test('telt wie meegaat en wie nog moet antwoorden, apart', () {
      final entry = buildRideEntries(
        planned: const [],
        owned: [
          _group(
            id: 'g1',
            ownerId: _me,
            day: 14,
            participants: const [
              RideParticipant(userId: 'a', status: ParticipantStatus.accepted),
              RideParticipant(userId: 'b', status: ParticipantStatus.accepted),
              RideParticipant(userId: 'c', status: ParticipantStatus.invited),
              RideParticipant(userId: 'd', status: ParticipantStatus.declined),
            ],
          ),
        ],
        joined: const [],
        invites: const [],
      ).single;

      expect(entry.acceptedCount, 2);
      expect(entry.pendingCount, 1);
    });

    test('alleen wat van jou alleen is, is weg te vegen', () {
      RideEntry entryFor(RideRole role) => switch (role) {
            RideRole.solo => buildRideEntries(
                planned: [_planned(14)],
                owned: const [],
                joined: const [],
                invites: const []).single,
            RideRole.organiser => buildRideEntries(
                planned: const [],
                owned: [_group(id: 'g', ownerId: _me, day: 14)],
                joined: const [],
                invites: const []).single,
            RideRole.joined => buildRideEntries(
                planned: const [],
                owned: const [],
                joined: [_group(id: 'g', ownerId: _other, day: 14)],
                invites: const []).single,
            RideRole.pending => buildRideEntries(
                planned: const [],
                owned: const [],
                joined: const [],
                invites: [_group(id: 'g', ownerId: _other, day: 14)]).single,
          };

      expect(entryFor(RideRole.solo).isRemovable, isTrue);
      expect(entryFor(RideRole.organiser).isRemovable, isTrue);
      // Andermans rit veeg je niet weg -- de rit blijft bestaan, jij gaat
      // alleen niet mee.
      expect(entryFor(RideRole.joined).isRemovable, isFalse);
      expect(entryFor(RideRole.pending).isRemovable, isFalse);
    });

    test('ownerName is leeg op je eigen rit, en gevuld op die van een ander',
        () {
      final own = buildRideEntries(
        planned: const [],
        owned: [_group(id: 'g', ownerId: _me, day: 14)],
        joined: const [],
        invites: const [],
      ).single;
      final theirs = buildRideEntries(
        planned: const [],
        owned: const [],
        joined: [_group(id: 'g', ownerId: _other, day: 14)],
        invites: const [],
      ).single;

      expect(own.ownerName, isNull,
          reason: '"Je gaat mee met jezelf" bestaat niet');
      expect(theirs.ownerName, 'Maatje');
    });

    test(
        'de sleutel komt uit UTC, zodat een cloud-rit en zijn lokale kopie '
        'dezelfde rit blijven', () {
      final local = DateTime(2026, 8, 8, 12);
      expect(
        RideEntry.slotKey(local, local.add(const Duration(hours: 2))),
        RideEntry.slotKey(
          local.toUtc(),
          local.toUtc().add(const Duration(hours: 2)),
        ),
      );
    });
  });

  group('countByRole', () {
    test('telt elke rol, ook de rollen die op nul staan', () {
      final counts = countByRole(buildRideEntries(
        planned: [_planned(18, startHour: 7, endHour: 9)],
        owned: [
          _group(id: 'g1', ownerId: _me, day: 14),
          _group(id: 'g2', ownerId: _me, day: 20),
        ],
        joined: [_group(id: 'g3', ownerId: _other, day: 16)],
        invites: const [],
      ));

      expect(counts[RideRole.organiser], 2);
      expect(counts[RideRole.joined], 1);
      expect(counts[RideRole.solo], 1);
      expect(counts[RideRole.pending], 0,
          reason: 'een rol op nul hoort in de map te staan, niet te ontbreken '
              '-- de filterrij leest hem op om te beslissen of hij verschijnt');
    });
  });
}
