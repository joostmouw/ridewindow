// test/providers/group_rides_providers_test.dart
//
// Groepsritten in de providers (fase 35, CLUB-13/14/25).
//
// Een groepsrit krijgt geen participant-rij per lid. Zonder aanpassing gaf
// `statusFor` op zo'n rit null, en viel hij tussen alle providers door:
// niet invited, niet accepted, niet van jou. Dat is precies de vorm van de
// fout van 2026-09-07 (een geaccepteerde rit die nergens meer stond). Deze
// tests bewaken dat hij als "wacht op jou" in de lijst komt, dat antwoorden
// de rij aanmaakt, en dat de teller hetzelfde getal geeft als de lijst.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/features/peloton/ride_response.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/ride_entries_provider.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';
const _anna = 'uid-anna';

class _FakePlannedRides extends PlannedRidesNotifier {
  @override
  Future<List<PlannedRide>> build() async => const [];
}

/// Een gateway met groep g1 ("On the Roll") waarin jij en Anna zitten.
FakeGroupGateway _gatewayWithClub() => FakeGroupGateway(
      groups: {
        'g1': FakeGroupGateway.group(
          'g1',
          'On the Roll',
          members: [
            FakeGroupGateway.member(_anna, role: GroupRole.admin),
            FakeGroupGateway.member(_me, joinedDay: 1),
          ],
        ),
      },
    );

ProviderContainer _container(FakeGroupGateway gateway, {String? userId = _me}) {
  final container = ProviderContainer(
    // Geen automatische herhaling (Riverpod 3): een falende groepenlijst moet
    // hier direct falen, anders wacht de test op een retry die nooit stopt.
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

/// Houdt de lijst levend en wacht tot alle bronnen geladen zijn. Een falende
/// groepenlijst mag hier niet doorbreken: dat is juist een van de gevallen.
Future<List<RideEntry>> _entries(ProviderContainer c) async {
  c.listen(rideEntriesProvider, (_, __) {});
  c.listen(unansweredRideCountProvider, (_, __) {});
  await c.read(plannedRidesProvider.future);
  await c.read(pendingRideInvitesProvider.future);
  await c.read(ownedGroupRidesProvider.future);
  await c.read(joinedGroupRidesProvider.future);
  await c.read(declinedGroupRidesProvider.future);
  try {
    await c.read(myGroupsProvider.future);
  } on Object catch (_) {
    // Bewust genegeerd; zie de test met failWith['listGroups'].
  }
  return c.read(rideEntriesProvider);
}

DateTime _tomorrowAt(int hour) {
  final t = DateTime.now().add(const Duration(days: 1));
  return DateTime(t.year, t.month, t.day, hour);
}

void main() {
  group('pendingRideInvites', () {
    test(
        'bevat een groepsrit zonder jouw rij en een losse uitnodiging, '
        'niet wat al beantwoord of van jou is', () async {
      final gw = _gatewayWithClub();
      gw.rides.addAll([
        FakeGroupGateway.groupRide('open', ownerId: _anna, groupId: 'g1'),
        FakeGroupGateway.groupRide(
          'invite',
          ownerId: _anna,
          participants: const [
            RideParticipant(userId: _me, status: ParticipantStatus.invited),
          ],
        ),
        FakeGroupGateway.groupRide(
          'yes',
          ownerId: _anna,
          groupId: 'g1',
          participants: const [
            RideParticipant(userId: _me, status: ParticipantStatus.accepted),
          ],
        ),
        FakeGroupGateway.groupRide(
          'no',
          ownerId: _anna,
          groupId: 'g1',
          participants: const [
            RideParticipant(userId: _me, status: ParticipantStatus.declined),
          ],
        ),
        FakeGroupGateway.groupRide('mine', ownerId: _me, groupId: 'g1'),
      ]);
      final c = _container(gw);

      final pending = await c.read(pendingRideInvitesProvider.future);

      expect(pending.map((r) => r.id).toSet(), {'open', 'invite'});
    });
  });

  group('rideEntries', () {
    test('een groepsrit zonder jouw rij staat er één keer, als wacht op jou',
        () async {
      final gw = _gatewayWithClub();
      gw.rides
          .add(FakeGroupGateway.groupRide('r1', ownerId: _anna, groupId: 'g1'));
      final c = _container(gw);

      final entries = await _entries(c);

      expect(entries, hasLength(1));
      expect(entries.single.role, RideRole.pending);
      expect(entries.single.groupName, 'On the Roll');
      expect(entries.single.pelotonGroup?.id, 'g1');
    });

    test('blijft staan als de groepenlijst faalt, alleen zonder groepsnaam',
        () async {
      final gw = _gatewayWithClub()
        ..failWith['listGroups'] = GroupError.notAllowed;
      gw.rides
          .add(FakeGroupGateway.groupRide('r1', ownerId: _anna, groupId: 'g1'));
      final c = _container(gw);

      final entries = await _entries(c);

      expect(entries, hasLength(1));
      expect(entries.single.role, RideRole.pending);
      expect(entries.single.groupName, isNull);
    });
  });

  group('unansweredRideCount', () {
    test('losse uitnodiging + groepsrit zonder rij in de toekomst = 2',
        () async {
      final gw = _gatewayWithClub();
      gw.rides.addAll([
        FakeGroupGateway.groupRide('open', ownerId: _anna, groupId: 'g1'),
        FakeGroupGateway.groupRide(
          'invite',
          ownerId: _anna,
          start: _tomorrowAt(15),
          participants: const [
            RideParticipant(userId: _me, status: ParticipantStatus.invited),
          ],
        ),
        FakeGroupGateway.groupRide(
          'yes',
          ownerId: _anna,
          groupId: 'g1',
          start: _tomorrowAt(6),
          end: _tomorrowAt(8),
          participants: const [
            RideParticipant(userId: _me, status: ParticipantStatus.accepted),
          ],
        ),
        FakeGroupGateway.groupRide(
          'no',
          ownerId: _anna,
          start: _tomorrowAt(18),
          participants: const [
            RideParticipant(userId: _me, status: ParticipantStatus.declined),
          ],
        ),
        FakeGroupGateway.groupRide(
          'mine',
          ownerId: _me,
          groupId: 'g1',
          start: _tomorrowAt(20),
        ),
      ]);
      final c = _container(gw);

      await _entries(c);

      expect(c.read(unansweredRideCountProvider), 2);
    });

    test('een onbeantwoorde groepsrit die al voorbij is telt niet', () async {
      final gw = _gatewayWithClub();
      final now = DateTime.now();
      // Een rit van een uur die een uur geleden eindigde. Na middernacht
      // valt hij al door notBefore uit de lijst; ook dan telt hij niet.
      gw.rides.add(
        FakeGroupGateway.groupRide(
          'past',
          ownerId: _anna,
          groupId: 'g1',
          start: now.subtract(const Duration(hours: 2)),
          end: now.subtract(const Duration(hours: 1)),
        ),
      );
      final c = _container(gw);

      await _entries(c);

      expect(c.read(unansweredRideCountProvider), 0);
    });

    test('uitgelogd is 0', () async {
      final gw = _gatewayWithClub();
      gw.rides
          .add(FakeGroupGateway.groupRide('r1', ownerId: _anna, groupId: 'g1'));
      final c = _container(gw, userId: null);

      await _entries(c);

      expect(c.read(unansweredRideCountProvider), 0);
    });
  });

  group('respondToSharedRide', () {
    test('op een groepsrit gaat het antwoord via respondToGroupRide', () async {
      final gw = _gatewayWithClub();
      final ride =
          FakeGroupGateway.groupRide('r1', ownerId: _anna, groupId: 'g1');
      gw.rides.add(ride);

      await respondToSharedRide(gw, ride, accepted: true, myName: 'Joost');

      expect(gw.calls, contains('respondToGroupRide:r1:true'));
      expect(gw.calls.where((c) => c.startsWith('respondToRide:')), isEmpty);
      final updated = gw.rides.single;
      expect(updated.statusFor(_me), ParticipantStatus.accepted);
      expect(
        updated.participants.singleWhere((p) => p.userId == _me).displayName,
        'Joost',
      );
    });

    test('op een gewone rit gaat het antwoord via respondToRide', () async {
      final gw = _gatewayWithClub();
      final ride = FakeGroupGateway.groupRide(
        'r2',
        ownerId: _anna,
        participants: const [
          RideParticipant(userId: _me, status: ParticipantStatus.invited),
        ],
      );
      gw.rides.add(ride);

      await respondToSharedRide(gw, ride, accepted: false);

      expect(gw.calls, contains('respondToRide:r2:false'));
      expect(
        gw.calls.where((c) => c.startsWith('respondToGroupRide:')),
        isEmpty,
      );
      expect(gw.rides.single.statusFor(_me), ParticipantStatus.declined);
    });
  });

  group('FakeGroupGateway groepsritten', () {
    test('twee keer antwoorden geeft één rij, met het laatste antwoord',
        () async {
      final gw = _gatewayWithClub();
      gw.rides
          .add(FakeGroupGateway.groupRide('r1', ownerId: _anna, groupId: 'g1'));

      await gw.respondToGroupRide(rideId: 'r1', accepted: true);
      await gw.respondToGroupRide(rideId: 'r1', accepted: false);

      final mine = gw.rides.single.participants.where((p) => p.userId == _me);
      expect(mine, hasLength(1));
      expect(mine.single.status, ParticipantStatus.declined);
    });

    test('een niet-lid mag niet antwoorden', () async {
      final gw = _gatewayWithClub()..me = 'uid-stranger';
      gw.rides
          .add(FakeGroupGateway.groupRide('r1', ownerId: _anna, groupId: 'g1'));

      await expectLater(
        gw.respondToGroupRide(rideId: 'r1', accepted: true),
        throwsA(
          isA<GroupException>()
              .having((e) => e.error, 'error', GroupError.notAllowed),
        ),
      );
    });

    test('respondToRide zonder eigen rij doet niets, net als de echte update',
        () async {
      final gw = _gatewayWithClub();
      gw.rides
          .add(FakeGroupGateway.groupRide('r1', ownerId: _anna, groupId: 'g1'));

      await gw.respondToRide(rideId: 'r1', accepted: true);

      expect(gw.rides.single.statusFor(_me), isNull);
    });

    test('een groepsrit voor een vreemde groep aanmaken wordt geweigerd',
        () async {
      final gw = _gatewayWithClub()..me = 'uid-stranger';

      await expectLater(
        gw.createGroupRide(
          start: _tomorrowAt(9),
          end: _tomorrowAt(13),
          plannedScore: 80,
          groupId: 'g1',
        ),
        throwsA(isA<GroupException>()),
      );
      expect(gw.rides, isEmpty);
    });

    test('listGroupRides volgt is_ride_member; na verlaten is de rit weg',
        () async {
      final gw = _gatewayWithClub();
      gw.rides.addAll([
        FakeGroupGateway.groupRide('club', ownerId: _anna, groupId: 'g1'),
        FakeGroupGateway.groupRide(
          'invited',
          ownerId: _anna,
          participants: const [
            RideParticipant(userId: _me, status: ParticipantStatus.invited),
          ],
        ),
        FakeGroupGateway.groupRide('strangers', ownerId: _anna),
        FakeGroupGateway.groupRide('mine', ownerId: _me),
      ]);

      expect(
        (await gw.listGroupRides()).map((r) => r.id).toSet(),
        {'club', 'invited', 'mine'},
      );

      await gw.leaveGroup('g1');

      expect(
        (await gw.listGroupRides()).map((r) => r.id).toSet(),
        {'invited', 'mine'},
        reason: 'CLUB-13: wie de groep verlaat, ziet de groepsrit niet meer',
      );
    });
  });
}
