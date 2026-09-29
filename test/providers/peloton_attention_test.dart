// test/providers/peloton_attention_test.dart
//
// Het rode bolletje telt drie dingen die je nog niet zag: ritvragen (tab
// Ritten), aanvragen die bij jou als beheerder liggen en nieuwe maatjes (tab
// Peloton). Sinds 2026-09-29 telt "gezien" en niet "beantwoord": zo doen
// Instagram en Facebook het, en in de video van die dag bleef het bolletje
// staan terwijl Joost ernaar keek. Deze tests bewaken elk deel, de som, de
// verdeling over de tabs, en dat bestaande maatjes na de update van build 61
// niet ineens als nieuw tellen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/seen_friends_store.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/ride_entries_provider.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';
const _anna = 'uid-anna';
const _bram = 'uid-bram';

class _FakePlannedRides extends PlannedRidesNotifier {
  @override
  Future<List<PlannedRide>> build() async => const [];
}

ProviderContainer _container(FakeGroupGateway gateway, {String? userId = _me}) {
  final container = ProviderContainer(
    retry: (_, __) => null,
    overrides: [
      pelotonGatewayProvider.overrideWithValue(gateway),
      currentUserIdProvider.overrideWithValue(userId),
      plannedRidesProvider.overrideWith(_FakePlannedRides.new),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Houdt alles levend, wacht tot de bronnen er zijn en leest dan het getal.
Future<int> _attention(ProviderContainer c) async {
  c.listen(pelotonAttentionCountProvider, (_, __) {});
  await c.read(plannedRidesProvider.future);
  await c.read(groupRidesProvider.future);
  await c.read(myGroupsProvider.future);
  await c.read(unseenFriendsProvider.future);
  await c.read(unseenGroupRequestsProvider.future);
  await c.read(unseenRideInvitesProvider.future);
  return c.read(pelotonAttentionCountProvider);
}

PelotonGroup _club({required GroupRole myRole, int requests = 2}) =>
    FakeGroupGateway.group(
      'g1',
      'On the Roll',
      members: [
        FakeGroupGateway.member(_anna, role: GroupRole.admin),
        FakeGroupGateway.member(_me, role: myRole, joinedDay: 1),
      ],
      requests: [
        for (var i = 0; i < requests; i++)
          FakeGroupGateway.request('r$i', 'uid-new-$i', createdDay: i),
      ],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('groepsaanvragen', () {
    test('als beheerder tellen de open aanvragen mee', () async {
      final c = _container(
        FakeGroupGateway(groups: {'g1': _club(myRole: GroupRole.admin)}),
      );
      expect(await _attention(c), 2);
      expect(c.read(openGroupRequestCountProvider), 2);
    });

    test('als gewoon lid wachten ze niet op jou', () async {
      final c = _container(
        FakeGroupGateway(groups: {'g1': _club(myRole: GroupRole.member)}),
      );
      expect(await _attention(c), 0);
    });

    test('je eigen aanvraag telt niet', () async {
      final club = FakeGroupGateway.group(
        'g1',
        'On the Roll',
        members: [FakeGroupGateway.member(_me, role: GroupRole.admin)],
        requests: [FakeGroupGateway.request('r-me', _me)],
      );
      final c = _container(FakeGroupGateway(groups: {'g1': club}));
      expect(await _attention(c), 0);
    });
  });

  group('nieuwe maatjes', () {
    test('de eerste keer na de update is niemand nieuw', () async {
      final c = _container(
        FakeGroupGateway(friends: const [Friend(userId: _anna)]),
      );
      expect(await _attention(c), 0);
      final prefs = await SharedPreferences.getInstance();
      expect(SeenFriendsStore(prefs).seenFor(_me), {_anna});
    });

    test('een maatje dat er later bijkomt telt als nieuw', () async {
      SharedPreferences.setMockInitialValues({
        SeenFriendsStore.keyFor(_me): [_anna],
      });
      final c = _container(
        FakeGroupGateway(
          friends: const [Friend(userId: _anna), Friend(userId: _bram)],
        ),
      );
      expect(await _attention(c), 1);
    });

    test('markAllSeen haalt het bolletje weg en onthoudt het', () async {
      SharedPreferences.setMockInitialValues({
        SeenFriendsStore.keyFor(_me): <String>[],
      });
      final c = _container(
        FakeGroupGateway(friends: const [Friend(userId: _bram)]),
      );
      expect(await _attention(c), 1);

      await c.read(unseenFriendsProvider.notifier).markAllSeen();
      expect(c.read(pelotonAttentionCountProvider), 0);
      final prefs = await SharedPreferences.getInstance();
      expect(SeenFriendsStore(prefs).seenFor(_me), {_bram});
    });

    test('wat een ander account zag, geldt niet voor jou', () async {
      SharedPreferences.setMockInitialValues({
        SeenFriendsStore.keyFor('uid-other'): [_anna],
        SeenFriendsStore.keyFor(_me): <String>[],
      });
      final c = _container(
        FakeGroupGateway(friends: const [Friend(userId: _anna)]),
      );
      expect(await _attention(c), 1);
    });

    test('uitgelogd is er niets en wordt er niets opgeslagen', () async {
      final c = _container(
        FakeGroupGateway(friends: const [Friend(userId: _anna)]),
        userId: null,
      );
      expect(await _attention(c), 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });
  });

  test('de drie delen worden opgeteld', () async {
    SharedPreferences.setMockInitialValues({
      SeenFriendsStore.keyFor(_me): [_anna],
    });
    final gw = FakeGroupGateway(
      groups: {'g1': _club(myRole: GroupRole.admin, requests: 1)},
      friends: const [Friend(userId: _anna), Friend(userId: _bram)],
    );
    gw.rides.add(
      FakeGroupGateway.groupRide('open', ownerId: _anna, groupId: 'g1'),
    );
    final c = _container(gw);
    // 1 rit zonder jouw antwoord + 1 aanvraag + 1 nieuw maatje.
    expect(await _attention(c), 3);
    // Elk op de tab waar het staat: de ritvraag op Ritten, de rest op Peloton.
    expect(c.read(ridesTabAttentionCountProvider), 1);
    expect(c.read(pelotonTabAttentionCountProvider), 2);
  });

  group('gezien is genoeg', () {
    test('een geziene ritvraag telt niet meer, maar wacht nog wel', () async {
      final gw = FakeGroupGateway(groups: {
        'g1': _club(myRole: GroupRole.member, requests: 0),
      });
      gw.rides.add(
        FakeGroupGateway.groupRide('open', ownerId: _anna, groupId: 'g1'),
      );
      final c = _container(gw);
      expect(await _attention(c), 1);

      final keys = c.read(pendingRideKeysProvider);
      await c.read(unseenRideInvitesProvider.notifier).markSeen(keys);
      expect(c.read(pelotonAttentionCountProvider), 0);
      // Gezien is niet beantwoord: de rit staat nog steeds op jou te wachten.
      expect(c.read(unansweredRideCountProvider), 1);

      final prefs = await SharedPreferences.getInstance();
      expect(SeenRideInvitesStore(prefs).seenFor(_me), keys.toSet());
    });

    test('na een herstart blijft een geziene ritvraag gezien', () async {
      final gw = FakeGroupGateway(groups: {
        'g1': _club(myRole: GroupRole.member, requests: 0),
      });
      gw.rides.add(
        FakeGroupGateway.groupRide('open', ownerId: _anna, groupId: 'g1'),
      );
      final first = _container(gw);
      await _attention(first);
      await first
          .read(unseenRideInvitesProvider.notifier)
          .markSeen(first.read(pendingRideKeysProvider));

      final second = _container(gw);
      expect(await _attention(second), 0);
    });

    test('alleen wat getoond is, geldt als gezien', () async {
      final gw = FakeGroupGateway(groups: {
        'g1': _club(myRole: GroupRole.member, requests: 0),
      });
      gw.rides
        ..add(FakeGroupGateway.groupRide('a', ownerId: _anna, groupId: 'g1'))
        ..add(FakeGroupGateway.groupRide('b', ownerId: _anna, groupId: 'g1'));
      final c = _container(gw);
      expect(await _attention(c), 2);
      final keys = c.read(pendingRideKeysProvider);
      await c.read(unseenRideInvitesProvider.notifier).markSeen([keys.first]);
      expect(c.read(ridesTabAttentionCountProvider), 1);
    });

    test('een geziene groepsaanvraag telt niet meer', () async {
      final c = _container(
        FakeGroupGateway(groups: {'g1': _club(myRole: GroupRole.admin)}),
      );
      expect(await _attention(c), 2);
      await c.read(unseenGroupRequestsProvider.notifier).markAllSeen();
      expect(c.read(pelotonAttentionCountProvider), 0);
      // De chip op de groepskaart telt nog gewoon: die zegt wat er open ligt.
      expect(c.read(openGroupRequestCountProvider), 2);
    });

    test('een nieuwe aanvraag na het kijken telt wel', () async {
      SharedPreferences.setMockInitialValues({
        SeenGroupRequestsStore.keyFor(_me): ['r0'],
      });
      final c = _container(
        FakeGroupGateway(groups: {'g1': _club(myRole: GroupRole.admin)}),
      );
      expect(await _attention(c), 1);
    });
  });

  group('unseenFriendCount', () {
    test('nooit vastgelegd telt als nul', () {
      expect(unseenFriendCount(current: const ['a', 'b'], seen: null), 0);
    });

    test('een weggevallen maatje maakt niets negatief', () {
      expect(unseenFriendCount(current: const ['a'], seen: {'a', 'b'}), 0);
    });
  });
}
