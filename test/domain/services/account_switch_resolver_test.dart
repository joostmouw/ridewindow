import 'package:test/test.dart';
import 'package:ridewindow/domain/services/account_switch_resolver.dart';

void main() {
  group('resolveAccountSwitch', () {
    test('geen lokaal record (null) levert firstSignIn op', () {
      expect(
        resolveAccountSwitch(signedInUid: 'abc', lastSyncedUid: null),
        AccountSwitchDecision.firstSignIn,
      );
    });

    test('zelfde uid levert sameAccount op', () {
      expect(
        resolveAccountSwitch(signedInUid: 'abc', lastSyncedUid: 'abc'),
        AccountSwitchDecision.sameAccount,
      );
    });

    test('ander uid levert differentAccount op', () {
      expect(
        resolveAccountSwitch(signedInUid: 'abc', lastSyncedUid: 'xyz'),
        AccountSwitchDecision.differentAccount,
      );
    });

    test(
        'lege string lastSyncedUid wordt behandeld als differentAccount, niet firstSignIn',
        () {
      expect(
        resolveAccountSwitch(signedInUid: 'abc', lastSyncedUid: ''),
        AccountSwitchDecision.differentAccount,
      );
    });
  });
}
