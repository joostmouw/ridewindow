// De code uit een groeps- of maatjeslink moet de welkomstschermen overleven
// (plan 34-07). Een nieuwe gebruiker is precies wie een clublink het vaakst
// opent, en die moet eerst door /welcome: zonder deze regel verdween de code
// in de redirect.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/app/router.dart';
import 'package:ridewindow/features/peloton/group_landing_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/services/pending_invite_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Opent [location] in de echte router en geeft de locatie na de redirect
  /// terug, plus de SharedPreferences om te zien wat er bewaard is.
  Future<(String, SharedPreferences)> open(
    WidgetTester tester,
    String location, {
    required bool onboarded,
  }) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': onboarded});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        // Uitgelogd: de landingsschermen raken dan de gateway niet aan.
        currentUserIdProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    router.go(location);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return (router.routerDelegate.currentConfiguration.uri.toString(), prefs);
  }

  testWidgets(
      'onboarding niet af: /group/<code> gaat naar /welcome en de '
      'groepscode is bewaard', (tester) async {
    final (loc, prefs) =
        await open(tester, '/group/ABCDEFGH', onboarded: false);

    expect(loc, '/welcome');
    expect(prefs.getString(PendingInviteStore.groupKey), 'ABCDEFGH');
    expect(prefs.getString(PendingInviteStore.friendKey), isNull);
  });

  testWidgets('onboarding niet af: /invite/<code> bewaart de maatjescode',
      (tester) async {
    final (loc, prefs) =
        await open(tester, '/invite/ABCDEFGH', onboarded: false);

    expect(loc, '/welcome');
    expect(prefs.getString(PendingInviteStore.friendKey), 'ABCDEFGH');
    expect(prefs.getString(PendingInviteStore.groupKey), isNull);
  });

  testWidgets('onboarding niet af: een gewone locatie bewaart niets',
      (tester) async {
    final (loc, prefs) = await open(tester, '/rides', onboarded: false);

    expect(loc, '/welcome');
    expect(prefs.getString(PendingInviteStore.friendKey), isNull);
    expect(prefs.getString(PendingInviteStore.groupKey), isNull);
  });

  testWidgets('onboarding af: /group/<code> blijft /group/<code>',
      (tester) async {
    final (loc, _) = await open(tester, '/group/ABCDEFGH', onboarded: true);

    expect(loc, '/group/ABCDEFGH');
    final screen =
        tester.widget<GroupLandingScreen>(find.byType(GroupLandingScreen));
    expect(screen.code, 'ABCDEFGH');
  });
}
