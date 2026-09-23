// test/providers/peloton_groups_providers_test.dart
//
// De groepsproviders van fase 34: uitgelogd niets (en de gateway blijft
// onaangeroerd), ingelogd een splitsing in groepen waar je lid bent en groepen
// waar je aanvraag loopt, en een groep op id zonder tweede netwerkronde.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';

FakeGroupGateway _gateway() => FakeGroupGateway(
      me: _me,
      groups: {
        'g1': FakeGroupGateway.group(
          'g1',
          'zaterdagclub',
          members: [
            FakeGroupGateway.member(_me, role: GroupRole.admin),
          ],
        ),
        'g2': FakeGroupGateway.group(
          'g2',
          'Buren',
          members: [
            FakeGroupGateway.member('uid-a', groupId: 'g2'),
            FakeGroupGateway.member(_me, groupId: 'g2', joinedDay: 1),
          ],
        ),
        'g3': FakeGroupGateway.group(
          'g3',
          'Dinsdagclub',
          members: [
            FakeGroupGateway.member(
              'uid-b',
              groupId: 'g3',
              role: GroupRole.admin,
            ),
          ],
          requests: [FakeGroupGateway.request('r1', _me, groupId: 'g3')],
        ),
      },
    );

ProviderContainer _container(FakeGroupGateway gateway, {String? userId = _me}) {
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
  test('uitgelogd: lege lijsten, gateway onaangeroerd', () async {
    final gateway = _gateway();
    final c = _container(gateway, userId: null);

    expect(await c.read(visibleGroupsProvider.future), isEmpty);
    expect(await c.read(myGroupsProvider.future), isEmpty);
    expect(await c.read(myPendingGroupsProvider.future), isEmpty);
    expect(await c.read(pelotonGroupProvider('g1').future), isNull);
    expect(gateway.calls, isEmpty);
  });

  test('myGroups: alleen lidmaatschappen, op naam zonder hoofdletters',
      () async {
    final c = _container(_gateway());

    final mine = await c.read(myGroupsProvider.future);
    expect(mine.map((g) => g.id), ['g2', 'g1']);
  });

  test('myPendingGroups: alleen groepen waar je aanvraag loopt', () async {
    final c = _container(_gateway());

    final pending = await c.read(myPendingGroupsProvider.future);
    expect(pending.map((g) => g.id), ['g3']);
  });

  test('pelotonGroup: op id, null voor onbekend, een netwerkronde', () async {
    final gateway = _gateway();
    final c = _container(gateway);
    // Houdt de gedeelde bron vast, zoals een scherm dat doet.
    c.listen(visibleGroupsProvider, (_, _) {});

    expect(
      (await c.read(pelotonGroupProvider('g1').future))?.name,
      'zaterdagclub',
    );
    expect((await c.read(pelotonGroupProvider('g3').future))?.id, 'g3');
    expect(await c.read(pelotonGroupProvider('onbekend').future), isNull);
    expect(gateway.calls.where((l) => l == 'listGroups'), hasLength(1));
  });
}
