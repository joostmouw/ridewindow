/// Widget tests voor OnboardingScreen.
///
/// Dekt Phase 4 success criteria 2 (vier preset-labels zichtbaar, 'Volgende' knop).
/// Tests gebruiken GoRouter fixture + FakeAvailabilityNotifier override zodat
/// geen SharedPreferences of echte provider-keten nodig is.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/features/onboarding/onboarding_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Fake AvailabilityNotifier: retourneert lege blocked-map zonder I/O
// ---------------------------------------------------------------------------

class FakeAvailabilityNotifier extends AvailabilityNotifier {
  @override
  Future<Map<DateTime, BlockType>> build() async => const {};
}

/// Een notifier waarbij het wegschrijven van het preset stukloopt.
///
/// Voor test 4, de consistentie-sweep op de toestemmingskaart die niet
/// dichtging: overal waar een knop pas ná een geslaagde async actie navigeert,
/// betekent een fout dat de knop zichtbaar niets doet. Op dit scherm is dat het
/// ergst -- een nieuwe gebruiker zit dan vast op stap een.
class _StukkeAvailabilityNotifier extends AvailabilityNotifier {
  @override
  Future<Map<DateTime, BlockType>> build() async => const {};

  @override
  Future<void> seedPreset(Map<DateTime, BlockType> preset) async {
    throw StateError('schema wegschrijven mislukt');
  }
}

// ---------------------------------------------------------------------------
// Helper: GoRouter-fixture met OnboardingScreen als root
// ---------------------------------------------------------------------------

/// [overrides] vervangt de standaardoverrides in plaats van ze aan te vullen:
/// Riverpod weigert dezelfde provider twee keer in één container.
Widget _buildTestApp({List<Override>? overrides}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const Scaffold(body: Text('Welcome')),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/availability',
        builder: (_, __) => const Scaffold(body: Text('Availability')),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides ??
        [availabilityProvider.overrideWith(() => FakeAvailabilityNotifier())],
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
  // Test 1: Alle vier preset-labels zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('OnboardingScreen toont alle vier preset-labels', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Avonden & weekenden'), findsOneWidget);
    expect(find.text('Ochtenden & weekenden'), findsOneWidget);
    expect(find.text('Alleen weekenden'), findsOneWidget);
    expect(find.text('Stel mijn eigen schema in'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 2: Tapping een preset optie (geen crash, setState werkt)
  // ---------------------------------------------------------------------------
  testWidgets('OnboardingScreen: tapping eerste preset geeft geen fout',
      (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // Tap de eerste preset tile ('Avonden & weekenden')
    await tester.tap(find.text('Avonden & weekenden'));
    await tester.pumpAndSettle();

    // Verifieer dat de widget nog aanwezig is (geen navigatie, geen crash)
    expect(find.text('Avonden & weekenden'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 3: 'Volgende →' knop zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('OnboardingScreen toont "Volgende" knop', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // Unicode arrow \u2192 staat ook in de knoptekst
    expect(find.text('Volgende \u2192'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 4: onboarding loopt nooit dood op een mislukte schrijfactie
  // ---------------------------------------------------------------------------
  testWidgets('OnboardingScreen gaat door naar Home ook als het preset faalt',
      (tester) async {
    // Consistentie-sweep op de toestemmingskaart die niet dichtging
    // (Androidguju67, 1.0.35+46). Daar hing `Navigator.pop()` achter een await
    // die gooide; hier hing `context.go('/home')` op dezelfde manier achter
    // `seedPreset`. Een lege agenda is te repareren vanuit Profiel; een knop
    // die niets doet op het eerste scherm dat een tester ziet, is dat niet.
    await tester.pumpWidget(_buildTestApp(overrides: [
      availabilityProvider.overrideWith(_StukkeAvailabilityNotifier.new),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alleen weekenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volgende \u2192'));
    await tester.pumpAndSettle();

    // De fout wordt gemeld en niet ingeslikt, maar hij houdt de gebruiker niet
    // tegen.
    expect(tester.takeException(), isA<StateError>());
    expect(find.text('Home'), findsOneWidget);
  });
}
