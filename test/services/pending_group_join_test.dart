// De groepscode die het inloggen overleeft (CLUB-02, plan 34-07).
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/services/pending_group_join.dart';
import 'package:ridewindow/services/pending_invite_store.dart';

import '../helpers/fake_group_gateway.dart';

void main() {
  FakeGroupGateway gatewayWithGroup() {
    final gateway = FakeGroupGateway(
      groups: {'g1': FakeGroupGateway.group('g1', 'Dinsdagclub')},
    );
    gateway.inviteCodes['ABCDEFGH'] = 'g1';
    return gateway;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('groeps- en maatjescode staan los van elkaar', () async {
    await PendingInviteStore.save('FRIEND12');
    await PendingInviteStore.saveGroup('GROUP123');
    expect(await PendingInviteStore.read(), 'FRIEND12');
    expect(await PendingInviteStore.readGroup(), 'GROUP123');

    await PendingInviteStore.clearGroup();
    expect(await PendingInviteStore.readGroup(), isNull);
    expect(await PendingInviteStore.read(), 'FRIEND12');
  });

  test('de maatjessleutel houdt zijn oude waarde', () async {
    // Een code die vóór deze versie is klaargelegd, moet nog gevonden worden.
    SharedPreferences.setMockInitialValues(
      {'peloton.pendingInviteCode': 'OLDCODE1'},
    );
    expect(PendingInviteStore.friendKey, 'peloton.pendingInviteCode');
    expect(await PendingInviteStore.read(), 'OLDCODE1');
  });

  test('een lege groepscode telt als geen code', () async {
    SharedPreferences.setMockInitialValues({PendingInviteStore.groupKey: ''});
    expect(await PendingInviteStore.readGroup(), isNull);
  });

  test('zonder bewaarde code: null en geen aanroep', () async {
    final gateway = gatewayWithGroup();
    expect(await redeemPendingGroupCode(gateway), isNull);
    expect(gateway.calls, isEmpty);
  });

  test('met code: inwisselen, resultaat terug en de code gewist', () async {
    final gateway = gatewayWithGroup();
    await PendingInviteStore.saveGroup('ABCDEFGH');

    final result = await redeemPendingGroupCode(gateway);

    expect(gateway.calls, ['redeemGroupInvite:ABCDEFGH']);
    expect(result, isNotNull);
    expect(result!.groupId, 'g1');
    expect(result.groupName, 'Dinsdagclub');
    expect(result.status, GroupJoinStatus.requested);
    expect(await PendingInviteStore.readGroup(), isNull);
  });

  test('mislukt inwisselen: fout komt terug en de code is toch weg', () async {
    final gateway = gatewayWithGroup()
      ..failWith['redeemGroupInvite'] = GroupError.groupFull;
    await PendingInviteStore.saveGroup('ABCDEFGH');

    await expectLater(
      redeemPendingGroupCode(gateway),
      throwsA(
        isA<GroupException>()
            .having((e) => e.error, 'error', GroupError.groupFull),
      ),
    );
    expect(await PendingInviteStore.readGroup(), isNull);
  });
}
