// test/providers/peloton_cache_test.dart
//
// Bug 0a (dossier `.planning/debug/planned-kaartjes-koude-start.md`):
// groupRides en visibleGroups openen op de SharedPreferences-kopie en laten
// het netwerk stil bijwerken, zodat PLANNED bij een koude start niet meer
// springt. Deze tests leggen de vier takken vast: geen cache, wel cache,
// falende refresh, en uitgelogd.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/peloton_cache_store.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/services/peloton_gateway.dart';

const _me = 'uid-me';

/// Stuurbare nep-poort: wat hij teruggeeft, hoe vaak hij geroepen is, en of
/// hij mag gooien. De rest van de poort gooit bewust -- een test die een
/// onverwachte methode raakt, faalt liever luid dan stil.
class _FakeGateway implements PelotonGateway {
  Completer<List<GroupRide>> ridesCompleter = Completer();
  List<PelotonGroup> groups = const [];
  List<Friend> friends = const [];
  Object? error;
  int listRidesCalls = 0;
  int listGroupsCalls = 0;
  int listFriendsCalls = 0;

  @override
  Future<List<GroupRide>> listGroupRides() {
    listRidesCalls++;
    if (error != null) return Future.error(error!);
    return ridesCompleter.future;
  }

  @override
  Future<List<PelotonGroup>> listGroups() {
    listGroupsCalls++;
    if (error != null) return Future.error(error!);
    return Future.value(groups);
  }

  @override
  Future<List<Friend>> listFriends() {
    listFriendsCalls++;
    if (error != null) return Future.error(error!);
    return Future.value(friends);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} niet nodig');
}

GroupRide _ride(String id) => GroupRide(
      id: id,
      ownerId: 'uid-buddy',
      start: DateTime(2026, 9, 12, 9),
      end: DateTime(2026, 9, 12, 13),
      plannedScore: 91,
    );

PelotonGroup _group(String name) =>
    PelotonGroup(id: 'g-$name', name: name, createdAt: DateTime(2026, 9, 1));

ProviderContainer _container(_FakeGateway gateway, {String? userId = _me}) {
  final container = ProviderContainer(
    overrides: [
      pelotonGatewayProvider.overrideWithValue(gateway),
      currentUserIdProvider.overrideWithValue(userId),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('groupRides met cache', () {
    test('zonder cache haalt hij het netwerk en schrijft de kopie', () async {
      final gateway = _FakeGateway();
      final container = _container(gateway);
      container.listen(groupRidesProvider, (_, __) {});
      gateway.ridesCompleter.complete([_ride('vers')]);

      final rides = await container.read(groupRidesProvider.future);

      expect(rides.single.id, 'vers');
      expect(gateway.listRidesCalls, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(
        PelotonCacheStore(prefs).readGroupRides(_me)!.single.id,
        'vers',
      );
    });

    test('met cache opent hij op de kopie en ververst daarna state én kopie',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await PelotonCacheStore(prefs).saveGroupRides(_me, [_ride('kopie')]);
      final gateway = _FakeGateway();
      final container = _container(gateway);
      container.listen(groupRidesProvider, (_, __) {});

      // De gateway hangt nog op de completer, en toch is er al een waarde.
      final first = await container.read(groupRidesProvider.future);
      expect(first.single.id, 'kopie');
      expect(gateway.listRidesCalls, 1);

      gateway.ridesCompleter.complete([_ride('vers')]);
      await pumpEventQueue();

      expect(container.read(groupRidesProvider).value!.single.id, 'vers');
      expect(
        PelotonCacheStore(prefs).readGroupRides(_me)!.single.id,
        'vers',
      );
    });

    test('een falende refresh laat de kopie staan en gooit niet', () async {
      final prefs = await SharedPreferences.getInstance();
      await PelotonCacheStore(prefs).saveGroupRides(_me, [_ride('kopie')]);
      final gateway = _FakeGateway()..error = StateError('offline');
      final container = _container(gateway);
      container.listen(groupRidesProvider, (_, __) {});

      final first = await container.read(groupRidesProvider.future);
      expect(first.single.id, 'kopie');
      await pumpEventQueue();

      // Peloton is additief: een haperend netwerk mag de ritten niet
      // wegnemen, ook niet als een foutscherm.
      final state = container.read(groupRidesProvider);
      expect(state.hasError, isFalse);
      expect(state.value!.single.id, 'kopie');
      expect(
        PelotonCacheStore(prefs).readGroupRides(_me)!.single.id,
        'kopie',
      );
    });

    test('uitgelogd is leeg, zonder poort en zonder cache-lezing', () async {
      final prefs = await SharedPreferences.getInstance();
      await PelotonCacheStore(prefs).saveGroupRides(_me, [_ride('kopie')]);
      final gateway = _FakeGateway();
      final container = _container(gateway, userId: null);

      expect(await container.read(groupRidesProvider.future), isEmpty);
      expect(gateway.listRidesCalls, 0);
    });
  });

  group('visibleGroups met cache', () {
    test('met cache opent hij op de kopie en ververst daarna', () async {
      final prefs = await SharedPreferences.getInstance();
      await PelotonCacheStore(prefs).saveGroups(_me, [_group('Oud')]);
      final gateway = _FakeGateway()..groups = [_group('Vers')];
      final container = _container(gateway);
      container.listen(visibleGroupsProvider, (_, __) {});

      final first = await container.read(visibleGroupsProvider.future);
      expect(first.single.name, 'Oud');
      await pumpEventQueue();

      expect(container.read(visibleGroupsProvider).value!.single.name, 'Vers');
      expect(
        PelotonCacheStore(prefs).readGroups(_me)!.single.name,
        'Vers',
      );
    });

    test('zonder cache sorteert en schrijft hij zoals de oude provider deed',
        () async {
      final gateway = _FakeGateway()
        ..groups = [_group('Zulu'), _group('alfa')];
      final container = _container(gateway);

      final groups = await container.read(visibleGroupsProvider.future);

      expect(groups.map((g) => g.name), ['alfa', 'Zulu']);
      final prefs = await SharedPreferences.getInstance();
      expect(
        PelotonCacheStore(prefs).readGroups(_me)!.map((g) => g.name),
        ['alfa', 'Zulu'],
      );
    });

    test('uitgelogd is leeg en raakt de poort niet', () async {
      final gateway = _FakeGateway();
      final container = _container(gateway, userId: null);

      expect(await container.read(visibleGroupsProvider.future), isEmpty);
      expect(gateway.listGroupsCalls, 0);
    });
  });

  group('friends met cache', () {
    test('zonder cache haalt hij het netwerk en schrijft de kopie', () async {
      final gateway = _FakeGateway()
        ..friends = const [Friend(userId: 'uid-anna', displayName: 'Anna')];
      final container = _container(gateway);

      final friends = await container.read(friendsProvider.future);

      expect(friends.single.userId, 'uid-anna');
      expect(gateway.listFriendsCalls, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(
        PelotonCacheStore(prefs).readFriends(_me)!.single.displayName,
        'Anna',
      );
    });

    test('met cache opent hij op de kopie en ververst daarna state én kopie',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await PelotonCacheStore(prefs)
          .saveFriends(_me, const [Friend(userId: 'oud', displayName: 'Oud')]);
      final gateway = _FakeGateway()
        ..friends = const [Friend(userId: 'nieuw', displayName: 'Nieuw')];
      final container = _container(gateway);
      container.listen(friendsProvider, (_, __) {});

      // De waarde is er meteen; de refresh loopt daarna.
      final first = await container.read(friendsProvider.future);
      expect(first.single.userId, 'oud');
      await pumpEventQueue();

      expect(container.read(friendsProvider).value!.single.userId, 'nieuw');
      expect(
        PelotonCacheStore(prefs).readFriends(_me)!.single.userId,
        'nieuw',
      );
    });

    test('een falende refresh laat de kopie staan en gooit niet', () async {
      final prefs = await SharedPreferences.getInstance();
      await PelotonCacheStore(prefs)
          .saveFriends(_me, const [Friend(userId: 'oud', displayName: 'Oud')]);
      final gateway = _FakeGateway()..error = StateError('offline');
      final container = _container(gateway);
      container.listen(friendsProvider, (_, __) {});

      final first = await container.read(friendsProvider.future);
      expect(first.single.userId, 'oud');
      await pumpEventQueue();

      // Dit is precies het beeld van de Oppo: offline "Try again" onder
      // GROUPS, terwijl de lijst er wel is.
      final state = container.read(friendsProvider);
      expect(state.hasError, isFalse);
      expect(state.value!.single.userId, 'oud');
    });

    test('uitgelogd is leeg, zonder poort en zonder cache-lezing', () async {
      final prefs = await SharedPreferences.getInstance();
      await PelotonCacheStore(prefs)
          .saveFriends(_me, const [Friend(userId: 'oud')]);
      final gateway = _FakeGateway();
      final container = _container(gateway, userId: null);

      expect(await container.read(friendsProvider.future), isEmpty);
      expect(gateway.listFriendsCalls, 0);
    });
  });
}
