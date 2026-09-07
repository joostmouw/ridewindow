// test/providers/peloton_providers_test.dart
//
// Regressie voor het gat dat de tweeaccountstest van 2026-09-07 blootlegde:
// na het accepteren van een uitnodiging viel de rit tussen alle providers door
// en was hij nergens in de app meer te zien. `joinedGroupRides` is de
// ontbrekende derde categorie naast "uitgenodigd" en "van mij".

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/services/peloton_gateway.dart';

const _me = 'uid-me';
const _buddy = 'uid-buddy';

/// Alleen `listGroupRides` doet er hier toe; de rest van de poort mag gooien
/// als een test hem per ongeluk aanraakt -- dat is informatiever dan een
/// stilzwijgende lege lijst.
class _FakeGateway implements PelotonGateway {
  _FakeGateway(this.rides);

  final List<GroupRide> rides;

  @override
  Future<List<GroupRide>> listGroupRides() async => rides;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} niet nodig');
}

GroupRide _ride({
  required String id,
  required String ownerId,
  List<RideParticipant> participants = const [],
}) =>
    GroupRide(
      id: id,
      ownerId: ownerId,
      start: DateTime(2026, 9, 12, 9),
      end: DateTime(2026, 9, 12, 13),
      plannedScore: 91,
      ownerName: 'Maatje',
      participants: participants,
    );

RideParticipant _participant(String userId, ParticipantStatus status) =>
    RideParticipant(userId: userId, status: status);

ProviderContainer _containerWith(List<GroupRide> rides, {String? userId = _me}) {
  final container = ProviderContainer(
    overrides: [
      pelotonGatewayProvider.overrideWithValue(_FakeGateway(rides)),
      currentUserIdProvider.overrideWithValue(userId),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('joinedGroupRides', () {
    test('bevat een rit van een maatje die ik heb geaccepteerd', () async {
      final container = _containerWith([
        _ride(
          id: 'r1',
          ownerId: _buddy,
          participants: [_participant(_me, ParticipantStatus.accepted)],
        ),
      ]);

      final joined = await container.read(joinedGroupRidesProvider.future);

      expect(joined, hasLength(1));
      expect(joined.single.id, 'r1');
    });

    test('bevat géén rit die ik zelf organiseer', () async {
      // Die hoort in ownedGroupRides thuis; hem hier ook tonen zou hem twee
      // keer op Home zetten.
      final container = _containerWith([
        _ride(
          id: 'r1',
          ownerId: _me,
          participants: [_participant(_buddy, ParticipantStatus.accepted)],
        ),
      ]);

      expect(await container.read(joinedGroupRidesProvider.future), isEmpty);
      expect(await container.read(ownedGroupRidesProvider.future), hasLength(1));
    });

    test('bevat géén uitnodiging waar ik nog niet op geantwoord heb', () async {
      // Die staat al bovenaan de Peloton-tab met een Join-knop; hem óók onder
      // "waar je aan meedoet" zetten zou suggereren dat je al ja hebt gezegd.
      final container = _containerWith([
        _ride(
          id: 'r1',
          ownerId: _buddy,
          participants: [_participant(_me, ParticipantStatus.invited)],
        ),
      ]);

      expect(await container.read(joinedGroupRidesProvider.future), isEmpty);
      expect(
        await container.read(pendingRideInvitesProvider.future),
        hasLength(1),
      );
    });

    test('bevat géén rit die ik heb afgezegd', () async {
      final container = _containerWith([
        _ride(
          id: 'r1',
          ownerId: _buddy,
          participants: [_participant(_me, ParticipantStatus.declined)],
        ),
      ]);

      expect(await container.read(joinedGroupRidesProvider.future), isEmpty);
    });

    test('is leeg wanneer niemand is ingelogd, en gooit niet', () async {
      // Peloton is additief (REQUIREMENTS.md regel 8): uitgelogd merkt een
      // gebruiker van het hele epic niets, ook geen foutmelding. De poort mag
      // dan niet eens aangeraakt worden -- vandaar dat de fake hier gooit als
      // dat toch gebeurt.
      final container = _containerWith(
        [
          _ride(
            id: 'r1',
            ownerId: _buddy,
            participants: [_participant(_me, ParticipantStatus.accepted)],
          ),
        ],
        userId: null,
      );

      expect(await container.read(joinedGroupRidesProvider.future), isEmpty);
    });
  });
}
