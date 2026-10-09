// test/data/repositories/peloton_cache_store_test.dart
//
// De koude-startcache voor gedeelde ritten en groepen (bug 0a). Waarom hij
// bestaat en waarom hij per account gesleuteld is, staat in de store zelf en
// in `.planning/debug/planned-kaartjes-koude-start.md`.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/peloton_cache_store.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';

GroupRide _ride() => GroupRide(
      id: 'r1',
      ownerId: 'uid-buddy',
      start: DateTime(2026, 9, 12, 9),
      end: DateTime(2026, 9, 12, 13),
      plannedScore: 91.5,
      ownerName: 'Maatje',
      note: 'Mooi weer',
      groupId: 'g1',
      participants: const [
        RideParticipant(
          userId: 'uid-me',
          status: ParticipantStatus.accepted,
          displayName: 'Joost',
        ),
      ],
      options: [
        RideOption(
          id: 'o1',
          rideId: 'r1',
          start: DateTime(2026, 9, 12, 10),
          end: DateTime(2026, 9, 12, 12),
          plannedScore: 88,
          votes: const [
            OptionVote(optionId: 'o1', userId: 'uid-me', canRide: true),
          ],
        ),
      ],
    );

PelotonGroup _group() => PelotonGroup(
      id: 'g1',
      name: 'Dinsdagclub',
      createdAt: DateTime(2026, 9, 1, 20),
      members: [
        GroupMember(
          groupId: 'g1',
          userId: 'uid-me',
          role: GroupRole.admin,
          displayName: 'Joost',
          joinedAt: DateTime(2026, 9, 1, 20),
        ),
        GroupMember(
          groupId: 'g1',
          userId: 'uid-buddy',
          role: GroupRole.member,
          displayName: 'Anna',
          joinedAt: DateTime(2026, 9, 2, 8, 30),
        ),
      ],
      requests: [
        GroupJoinRequest(
          id: 'q1',
          groupId: 'g1',
          userId: 'uid-new',
          createdAt: DateTime(2026, 9, 10, 12),
          proposedBy: 'uid-buddy',
          displayName: 'Nieuwe',
          proposedByName: 'Anna',
        ),
      ],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ritten overleven de round-trip inclusief geneste lijsten en datums',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final store = PelotonCacheStore(prefs);

    await store.saveGroupRides('uid-me', [_ride()]);
    final back = store.readGroupRides('uid-me');

    expect(back, hasLength(1));
    final ride = back!.single;
    expect(ride.id, 'r1');
    expect(ride.ownerId, 'uid-buddy');
    expect(ride.start, DateTime(2026, 9, 12, 9));
    expect(ride.end, DateTime(2026, 9, 12, 13));
    expect(ride.plannedScore, 91.5);
    expect(ride.ownerName, 'Maatje');
    expect(ride.note, 'Mooi weer');
    expect(ride.groupId, 'g1');
    expect(ride.participants.single.userId, 'uid-me');
    expect(ride.participants.single.status, ParticipantStatus.accepted);
    final option = ride.options.single;
    expect(option.start, DateTime(2026, 9, 12, 10));
    expect(option.votes.single.canRide, isTrue);
  });

  test('groepen overleven de round-trip met de gateway-sortering intact',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final store = PelotonCacheStore(prefs);

    await store.saveGroups('uid-me', [_group()]);
    final back = store.readGroups('uid-me');

    expect(back, hasLength(1));
    final group = back!.single;
    expect(group.id, 'g1');
    expect(group.name, 'Dinsdagclub');
    expect(group.createdAt, DateTime(2026, 9, 1, 20));
    expect(group.members, hasLength(2));
    // fromJson loopt via fromRows, dus de beheerder-eerst-sortering van de
    // gateway geldt ook voor wat uit de cache komt.
    expect(group.members.first.isAdmin, isTrue);
    final request = group.requests.single;
    expect(request.proposedBy, 'uid-buddy');
    expect(request.proposedByName, 'Anna');
    expect(request.createdAt, DateTime(2026, 9, 10, 12));
  });

  test('is per account: opslaan voor de een leest niet bij de ander',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final store = PelotonCacheStore(prefs);

    await store.saveGroupRides('uid-me', [_ride()]);
    await store.saveGroups('uid-me', [_group()]);

    expect(store.readGroupRides('uid-ander'), isNull);
    expect(store.readGroups('uid-ander'), isNull);
  });

  test('corrupte of vormloze JSON leest als geen cache, niet als een crash',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PelotonCacheStore.ridesKeyFor('uid-me'), '{geen lijst');
    await prefs.setString(PelotonCacheStore.groupsKeyFor('uid-me'), '{"vorm":1}');
    final store = PelotonCacheStore(prefs);

    expect(store.readGroupRides('uid-me'), isNull);
    expect(store.readGroups('uid-me'), isNull);
  });

  test('clearAllAccounts raakt alleen de cache-sleutels', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = PelotonCacheStore(prefs);
    await store.saveGroupRides('uid-me', [_ride()]);
    await store.saveGroups('uid-ander', [_group()]);
    await prefs.setString('peloton.seenFriends.uid-me', 'blijf');

    await store.clearAllAccounts();

    expect(store.readGroupRides('uid-me'), isNull);
    expect(store.readGroups('uid-ander'), isNull);
    expect(prefs.getString('peloton.seenFriends.uid-me'), 'blijf');
  });
}
