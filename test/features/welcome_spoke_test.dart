/// Widget tests voor de koppeling tussen WelcomeScreen en de spaaktijdlijn.
///
/// De echte speler (geluid + trilling) draait op het toestel; hier wordt met
/// een opnamefake bewaakt dat het scherm hem start, en stopt bij overslaan
/// en bij afbraak. De synchronisatie zelf zit in `kSpokeTicks` en heeft
/// zijn eigen tests (spoke_track_test.dart).

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ridewindow/features/welcome/spoke_track.dart';
import 'package:ridewindow/features/welcome/welcome_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Fake die alleen bijhoudt wat het scherm met de tijdlijn doet.
class _RecordingSpokeTrackPlayer implements SpokeTrackPlayer {
  int startCount = 0;
  int stopCount = 0;

  @override
  void start() => startCount++;

  @override
  void stop() => stopCount++;
}

Widget _buildTestApp(SpokeTrackPlayer player) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => WelcomeScreen(spokeTrackPlayer: player),
      ),
      GoRoute(
        path: '/onboard',
        builder: (_, __) => const Scaffold(body: Text('Onboarding')),
      ),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('nl'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      theme: ThemeData(extensions: const [RideWindowTheme.light]),
    ),
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // Test 1: de intro start de tijdlijn
  // ---------------------------------------------------------------------------
  testWidgets('WelcomeScreen start de spaaktijdlijn', (tester) async {
    final player = _RecordingSpokeTrackPlayer();
    await tester.pumpWidget(_buildTestApp(player));
    await tester.pump();

    expect(player.startCount, 1, reason: 'de rit begint met het scherm');
    expect(player.stopCount, 0);
  });

  // ---------------------------------------------------------------------------
  // Test 2: tikken breekt ook de rit af
  // ---------------------------------------------------------------------------
  testWidgets('tikken om te overslaan stopt geluid en trilling mee',
      (tester) async {
    final player = _RecordingSpokeTrackPlayer();
    await tester.pumpWidget(_buildTestApp(player));
    await tester.pump();

    // De GestureDetector ligt over het hele scherm (HitTestBehavior.opaque),
    // dus een tik in het midden is de overslaan-tik.
    await tester.tap(find.byType(WelcomeScreen));
    await tester.pump();

    expect(
      player.stopCount,
      1,
      reason: 'wie het beeld overslaat hoort geen wiel meer dat er niet staat',
    );
  });

  // ---------------------------------------------------------------------------
  // Test 3: ook afbraak van het scherm stopt de tijdlijn
  // ---------------------------------------------------------------------------
  testWidgets('het weghalen van het scherm stopt de tijdlijn', (tester) async {
    final player = _RecordingSpokeTrackPlayer();
    await tester.pumpWidget(_buildTestApp(player));
    await tester.pump();

    // Zonder tik, gewoon het scherm vervangen: de dispose moet stoppen.
    await tester.pumpWidget(const ProviderScope(child: SizedBox()));
    await tester.pump();

    expect(
      player.stopCount,
      1,
      reason: 'loze timers overleven het scherm niet',
    );
  });
}
