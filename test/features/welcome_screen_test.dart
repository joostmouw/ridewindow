/// Widget tests voor WelcomeScreen.
///
/// Dekt Phase 4 success criteria 1 (WelcomeScreen toont bij eerste run).
/// Tests gebruiken GoRouter fixture zodat context.go('/onboard') niet crasht.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/features/welcome/welcome_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Helper: minimale GoRouter-fixture met WelcomeScreen als root
// ---------------------------------------------------------------------------

Widget _buildTestApp() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const WelcomeScreen(),
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // Test 1: 'Aan de slag →' knop zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('WelcomeScreen toont "Aan de slag" knop', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // Zoek op tekstinhoud (Unicode arrow is \u2192)
    expect(find.text('Aan de slag \u2192'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 2: Titel 'perfecte fietsmoment' zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('WelcomeScreen toont titel met "perfecte fietsmoment"',
      (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('perfecte fietsmoment'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 3: de tekst is nooit lang halfzichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('de tekst is voluit zichtbaar zodra hij op zijn plek staat',
      (tester) async {
    // Een tester fotografeerde het welkomscherm met bleke tekst en meldde
    // "font is lastig te lezen met kleuren" (2026-09-08). De kleuren zijn goed
    // -- de titel haalt 9,63:1 op `brandLight`, de subtitel 5,54:1 -- maar de
    // dekking liep mee met de verplaatsing, dus het blok stond 1170 ms
    // halfzichtbaar op zijn plek. Je oog begint te lezen en faalt.
    //
    // Wat hier bewaakt wordt is de scheiding tussen die twee: de dekking is
    // rond 0.46 van de beweging klaar, de verplaatsing loopt door tot 1.0.
    // Koppel ze weer aan elkaar en deze test valt om.
    await tester.pumpWidget(_buildTestApp());

    // In twee stappen, en dat is geen omweg: de verschuiving start via een
    // `Timer` op 3144 ms. Eén grote pump laat die timer vuren maar geeft de
    // controller daarna geen tijd meer, dus dan staat alles nog op nul.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3200)); // timer vuurt
    await tester.pump(const Duration(milliseconds: 1200)); // 2/3 van de 1800 ms

    // Precies de FadeTransition om de tekst, niet die van de router.
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.textContaining('perfecte fietsmoment'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );

    expect(
      fade.opacity.value,
      1.0,
      reason: 'op 2/3 van de verschuiving hoort de tekst al voluit te staan',
    );

    await tester.pumpAndSettle();
  });
}
