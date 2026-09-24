// test/domain/models/ride_entry_test.dart
//
// De samenvoeging van vijf bronnen tot één lijst (schets 008, en sinds
// backlog #66 ook de afgezegde ritten).
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
import 'package:ridewindow/domain/models/peloton_group.dart';
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
  String? groupId,
}) =>
    GroupRide(
      id: id,
      ownerId: ownerId,
      groupId: groupId,
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
            RideRole.declined => buildRideEntries(
                planned: const [],
                owned: const [],
                joined: const [],
                invites: const [],
                declined: [_group(id: 'g', ownerId: _other, day: 14)]).single,
          };

      expect(entryFor(RideRole.solo).isRemovable, isTrue);
      expect(entryFor(RideRole.organiser).isRemovable, isTrue);
      // Andermans rit veeg je niet weg -- de rit blijft bestaan, jij gaat
      // alleen niet mee.
      expect(entryFor(RideRole.joined).isRemovable, isFalse);
      expect(entryFor(RideRole.pending).isRemovable, isFalse);
      // En een afgezegde rit al helemaal niet: die is juist bewaard gebleven
      // om er nog op terug te kunnen komen (backlog #66).
      expect(entryFor(RideRole.declined).isRemovable, isFalse);
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

  // ── Afgezegde ritten (backlog #66) ──
  //
  // Afzeggen was een deur die één kant op ging: `declined` viel uit
  // pendingRideInvites, joinedGroupRides en ownedGroupRides tegelijk en was
  // nergens meer aan te wijzen, terwijl de rij bestond en RLS een terugweg
  // toestond. Deze groep legt de twee eisen vast die elkaar in de weg zitten:
  // de rit moet vindbaar zijn, en hij mag niet in de weg lopen.
  group('afgezegde ritten', () {
    test('krijgen de rol declined en zijn dus vindbaar', () {
      final entries = buildRideEntries(
        planned: const [],
        owned: const [],
        joined: const [],
        invites: const [],
        declined: [_group(id: 'g1', ownerId: _other, day: 14)],
      );

      expect(entries, hasLength(1));
      expect(entries.single.role, RideRole.declined);
      expect(entries.single.isDeclined, isTrue);
    });

    test('staan achteraan in voorrang, dus een eigen plan wint', () {
      // Je zei nee tegen andermans rit, maar datzelfde tijdvak staat nog als
      // jouw eigen rit. Dan is het gewoon jouw rit en hoort hij op Home.
      final entries = buildRideEntries(
        planned: [_planned(14)],
        owned: const [],
        joined: const [],
        invites: const [],
        declined: [_group(id: 'g1', ownerId: _other, day: 14)],
      );

      expect(entries, hasLength(1), reason: 'één tijdvak, één regel');
      expect(entries.single.role, RideRole.solo);
      expect(entries.single.isDeclined, isFalse);
      expect(
        entries.single.planned,
        isNotNull,
        reason: 'de persoonlijke rij blijft eraan hangen',
      );
    });

    test('een geaccepteerde rit wint van een afgezegde op hetzelfde tijdvak',
        () {
      // Kan in theorie niet samen bestaan, maar als de cloud ooit beide
      // teruggeeft moet de lijst niet twee regels tonen.
      final entries = buildRideEntries(
        planned: const [],
        owned: const [],
        joined: [_group(id: 'g1', ownerId: _other, day: 14)],
        invites: const [],
        declined: [_group(id: 'g1', ownerId: _other, day: 14)],
      );

      expect(entries, hasLength(1));
      expect(entries.single.role, RideRole.joined);
    });

    test('zonder afgezegde ritten verandert er niets', () {
      // De parameter heeft een default, dus bestaande aanroepers blijven werken.
      final entries = buildRideEntries(
        planned: const [],
        owned: [_group(id: 'g1', ownerId: _me, day: 14)],
        joined: const [],
        invites: const [],
      );

      expect(entries.single.role, RideRole.organiser);
    });

    test('declined staat achteraan in de enum, en dat is niet cosmetisch', () {
      // De voorrang bij ontdubbeling leunt op deze volgorde.
      expect(RideRole.values.last, RideRole.declined);
      expect(RideRole.declined.index, greaterThan(RideRole.solo.index));
    });
  });

  // ── Groepsritten (fase 35, CLUB-13/14/15) ──
  //
  // Een groepsrit heeft geen participant-rij per lid (geen momentopname), dus
  // wie er meegaat, wie niet en wie nog niet antwoordde volgt uit de huidige
  // leden, niet uit de rijen alleen.
  group('groepsritten', () {
    PelotonGroup clubWith(List<String> uids) => PelotonGroup(
          id: 'club1',
          name: 'On the Roll',
          createdAt: DateTime(2026, 9, 1),
          members: [
            for (final u in uids)
              GroupMember(
                groupId: 'club1',
                userId: u,
                role: GroupRole.member,
                joinedAt: DateTime(2026, 9, 1),
              ),
          ],
        );

    test('GroupRide.fromRow leest group_id', () {
      final row = {
        'id': 'r1',
        'owner_id': _other,
        'start_at': '2026-09-14T07:00:00Z',
        'end_at': '2026-09-14T11:00:00Z',
        'planned_score': 80,
      };
      final plain = GroupRide.fromRow(row);
      expect(plain.groupId, isNull);
      expect(plain.isGroupRide, isFalse);

      final nulled = GroupRide.fromRow({...row, 'group_id': null});
      expect(nulled.groupId, isNull);
      expect(nulled.isGroupRide, isFalse);

      final club = GroupRide.fromRow({...row, 'group_id': 'g1'});
      expect(club.groupId, 'g1');
      expect(club.isGroupRide, isTrue);
    });

    test(
        'twee verschillende gedeelde ritten op hetzelfde tijdvak blijven '
        'allebei staan', () {
      // Een groepsrit van Jacco en jouw eigen rit met Bram, allebei op het
      // beste venster van de week. Vroeger won er één en verdween de ander.
      final entries = buildRideEntries(
        planned: const [],
        owned: [_group(id: 'r1', ownerId: _me, day: 14)],
        joined: const [],
        invites: [
          _group(id: 'r2', ownerId: _other, day: 14, groupId: 'club1'),
        ],
      );

      expect(entries, hasLength(2));
      expect(
        entries.map((e) => e.role).toSet(),
        {RideRole.organiser, RideRole.pending},
      );
      expect(entries[0].key, isNot(entries[1].key));
    });

    test('dezelfde rit in joined en declined blijft één regel', () {
      final entries = buildRideEntries(
        planned: const [],
        owned: const [],
        joined: [_group(id: 'r1', ownerId: _other, day: 14)],
        invites: const [],
        declined: [_group(id: 'r1', ownerId: _other, day: 14)],
      );
      expect(entries, hasLength(1));
      expect(entries.single.role, RideRole.joined);
    });

    test(
        'een persoonlijke rit hangt aan de rit die jij organiseert als twee '
        'gedeelde ritten op dat tijdvak staan', () {
      final entries = buildRideEntries(
        planned: [_planned(14)],
        owned: [_group(id: 'r1', ownerId: _me, day: 14)],
        joined: const [],
        invites: [
          _group(id: 'r2', ownerId: _other, day: 14, groupId: 'club1'),
        ],
      );

      expect(entries, hasLength(2), reason: 'geen losse solo-regel erbij');
      final organiser = entries.firstWhere((e) => e.role == RideRole.organiser);
      final pending = entries.firstWhere((e) => e.role == RideRole.pending);
      expect(organiser.planned, isNotNull);
      expect(pending.planned, isNull);
    });

    test(
        'zonder eigen rit op het tijdvak hangt de persoonlijke rij aan de '
        'regel met de hoogste voorrang', () {
      final entries = buildRideEntries(
        planned: [_planned(14)],
        owned: const [],
        joined: [_group(id: 'r1', ownerId: _other, day: 14)],
        invites: [
          _group(id: 'r2', ownerId: _other, day: 14, groupId: 'club1'),
        ],
      );

      expect(entries, hasLength(2));
      expect(
        entries.firstWhere((e) => e.role == RideRole.pending).planned,
        isNotNull,
      );
      expect(
        entries.firstWhere((e) => e.role == RideRole.joined).planned,
        isNull,
      );
    });

    test(
        'afgezegd + eigen plan wordt solo, ook naast een andere gedeelde rit '
        'als die lager in voorrang staat', () {
      final entries = buildRideEntries(
        planned: [_planned(14)],
        owned: const [],
        joined: const [],
        invites: const [],
        declined: [_group(id: 'r1', ownerId: _other, day: 14)],
      );
      expect(entries.single.role, RideRole.solo);
      expect(entries.single.planned, isNotNull);
    });

    test('telt over de huidige leden, met de organisator als "gaat mee"', () {
      final entry = buildRideEntries(
        planned: const [],
        owned: const [],
        joined: const [],
        invites: [
          _group(
            id: 'r1',
            ownerId: 'owner',
            day: 14,
            groupId: 'club1',
            participants: const [
              RideParticipant(userId: 'a', status: ParticipantStatus.accepted),
              RideParticipant(userId: 'b', status: ParticipantStatus.declined),
            ],
          ),
        ],
        groups: {
          'club1': clubWith(['owner', 'a', 'b', 'c', 'd']),
        },
      ).single;

      expect(entry.isGroupRide, isTrue);
      expect(entry.groupName, 'On the Roll');
      expect(entry.pelotonGroup?.id, 'club1');
      expect(entry.acceptedCount, 2, reason: 'organisator + a');
      expect(entry.declinedCount, 1);
      expect(entry.pendingCount, 2, reason: 'c en d zonder rij');
    });

    test(
        'een lid met een rij invited telt als nog niet, een ex-lid telt '
        'nergens mee', () {
      final entry = buildRideEntries(
        planned: const [],
        owned: const [],
        joined: const [],
        invites: [
          _group(
            id: 'r1',
            ownerId: 'owner',
            day: 14,
            groupId: 'club1',
            participants: const [
              RideParticipant(userId: 'a', status: ParticipantStatus.invited),
              RideParticipant(userId: 'ex', status: ParticipantStatus.accepted),
              RideParticipant(
                userId: 'ex2',
                status: ParticipantStatus.declined,
              ),
            ],
          ),
        ],
        groups: {
          'club1': clubWith(['owner', 'a']),
        },
      ).single;

      expect(entry.acceptedCount, 1, reason: 'alleen de organisator');
      expect(entry.declinedCount, 0);
      expect(entry.pendingCount, 1);
    });

    test(
        'groepsrit zonder bekende groep valt terug op de rijen, zonder '
        'groepsnaam', () {
      final entry = buildRideEntries(
        planned: const [],
        owned: const [],
        joined: const [],
        invites: [
          _group(
            id: 'r1',
            ownerId: 'owner',
            day: 14,
            groupId: 'club1',
            participants: const [
              RideParticipant(userId: 'a', status: ParticipantStatus.accepted),
              RideParticipant(userId: 'b', status: ParticipantStatus.declined),
              RideParticipant(userId: 'c', status: ParticipantStatus.invited),
            ],
          ),
        ],
      ).single;

      expect(entry.isGroupRide, isTrue);
      expect(entry.groupName, isNull);
      expect(entry.pelotonGroup, isNull);
      expect(entry.acceptedCount, 1);
      expect(entry.declinedCount, 1);
      expect(entry.pendingCount, 1);
    });

    test('een gewone gedeelde rit telt zoals altijd', () {
      final entry = buildRideEntries(
        planned: const [],
        owned: [
          _group(
            id: 'r1',
            ownerId: _me,
            day: 14,
            participants: const [
              RideParticipant(userId: 'a', status: ParticipantStatus.accepted),
              RideParticipant(userId: 'b', status: ParticipantStatus.declined),
              RideParticipant(userId: 'c', status: ParticipantStatus.declined),
              RideParticipant(userId: 'd', status: ParticipantStatus.invited),
            ],
          ),
        ],
        joined: const [],
        invites: const [],
        groups: {
          'club1': clubWith([_me, 'a']),
        },
      ).single;

      expect(entry.isGroupRide, isFalse);
      expect(entry.groupName, isNull);
      expect(entry.acceptedCount, 1, reason: 'organisator niet meegeteld');
      expect(entry.declinedCount, 2);
      expect(entry.pendingCount, 1);
    });
  });
}
