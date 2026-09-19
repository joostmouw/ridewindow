// De "zet op beginscherm"-balk moet weg te klikken zijn, maar niet voorgoed.
//
// Fase 16 koos bewust voor géén wegklikknop (D-04) zodat de balk zou blijven
// aandringen tot de app geïnstalleerd was. Een tester liet op 2026-09-19 zien
// wat dat in de praktijk betekent: een strook van elk scherm permanent
// onzichtbaar. Deze test legt de middenweg vast -- wegklikken sluimert een
// week, drie keer wegklikken is definitief.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/install_hint_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final nu = DateTime(2026, 9, 19, 12);

  group('de beslissing', () {
    test('nooit weggeklikt: zichtbaar', () {
      expect(
        installHintSuppressed(dismissCount: 0, dismissedAt: null, now: nu),
        isFalse,
      );
    });

    test('net weggeklikt: een week stil', () {
      expect(
        installHintSuppressed(
          dismissCount: 1,
          dismissedAt: nu.subtract(const Duration(days: 3)),
          now: nu,
        ),
        isTrue,
      );
    });

    test('na een week mag hij het nog eens vragen', () {
      expect(
        installHintSuppressed(
          dismissCount: 1,
          dismissedAt: nu.subtract(const Duration(days: 8)),
          now: nu,
        ),
        isFalse,
      );
    });

    test('precies op de grens telt als verlopen', () {
      expect(
        installHintSuppressed(
          dismissCount: 1,
          dismissedAt: nu.subtract(InstallHintStore.kSnooze),
          now: nu,
        ),
        isFalse,
      );
    });

    test('drie keer weggeklikt is definitief, ook na een jaar', () {
      expect(
        installHintSuppressed(
          dismissCount: InstallHintStore.kMaxDismissals,
          dismissedAt: nu.subtract(const Duration(days: 365)),
          now: nu,
        ),
        isTrue,
        reason: 'wie hem drie keer wegklikt, meent het',
      );
    });
  });

  group('de opslag', () {
    test('telt op en onthoudt wanneer', () async {
      SharedPreferences.setMockInitialValues({});
      final store = InstallHintStore(await SharedPreferences.getInstance());

      expect(store.dismissCount, 0);
      expect(store.dismissedAt, isNull);
      expect(store.isSuppressed(now: nu), isFalse);

      await store.recordDismissal(now: nu);

      expect(store.dismissCount, 1);
      expect(store.dismissedAt, nu);
      expect(store.isSuppressed(now: nu), isTrue);
      expect(
        store.isSuppressed(now: nu.add(const Duration(days: 8))),
        isFalse,
      );
    });

    test('na drie keer blijft hij stil', () async {
      SharedPreferences.setMockInitialValues({});
      final store = InstallHintStore(await SharedPreferences.getInstance());

      for (var i = 0; i < InstallHintStore.kMaxDismissals; i++) {
        await store.recordDismissal(now: nu.add(Duration(days: i * 10)));
      }

      expect(store.dismissCount, 3);
      expect(
        store.isSuppressed(now: nu.add(const Duration(days: 400))),
        isTrue,
      );
    });

    test('staat los van de profile.*-sleutels die naar de cloud gaan', () {
      for (final key in [
        InstallHintStore.kDismissedAtKey,
        InstallHintStore.kDismissCountKey,
      ]) {
        expect(key.startsWith('pwa.'), isTrue);
        expect(key.startsWith('profile.'), isFalse);
      }
    });
  });
}
