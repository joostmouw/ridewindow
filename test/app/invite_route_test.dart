// De deep-link route van epic #62: `/invite/:code`.
//
// Deze test bestaat omdat de eerste verificatie op een toestel misleidend was.
// De PWA toonde "GoException: no routes for location: /invite/YRG4GD6X" terwijl
// de route wel degelijk in de gedeployde bundel zat (`grep '/invite/:code'` op
// de live `main.dart.js` gaf een treffer) -- de service worker serveerde een
// oudere build. Een halfuur zoeken naar een codefout die er niet was.
//
// Een routetest hoort dus niet op een apparaat thuis: dat meet de browsercache
// net zo goed als de code. Hier wordt precies één ding vastgelegd -- dat de
// route bestaat en op het juiste scherm uitkomt -- en dat antwoord is niet te
// vertroebelen door caching.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/app/router.dart';
import 'package:ridewindow/features/peloton/invite_landing_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWithPrefs() async {
    // Onboarding afgerond, anders stuurt de redirect alles naar /welcome en
    // meet deze test die redirect in plaats van de route.
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
  }

  testWidgets(
    '/invite/:code komt uit op het uitnodigingsscherm en geeft de code door',
    (tester) async {
      final container = await containerWithPrefs();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      router.go('/invite/YRG4GD6X');

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
      await tester.pumpAndSettle();

      final screen = tester.widget<InviteLandingScreen>(
        find.byType(InviteLandingScreen),
      );
      expect(
        screen.code,
        'YRG4GD6X',
        reason: 'De code uit het pad moet doorgegeven worden, anders opent de '
            'link wel maar valt er niets te verzilveren.',
      );
    },
  );

  test('de gedeelde link houdt de hash-vorm aan', () {
    // Zonder de `/#/` belandt de link op de server in plaats van in de app, en
    // dat geeft een 404: deze app draait op go_router's default
    // hash-strategie. Verdwijnt de `#` hier, dan is elke al verstuurde
    // uitnodiging stuk.
    expect(inviteLinkFor('ABCD2345'), contains('/#/invite/'));
    expect(inviteLinkFor('ABCD2345'), endsWith('/ABCD2345'));
  });
}
