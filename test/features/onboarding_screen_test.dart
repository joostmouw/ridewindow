/// Widget tests voor OnboardingScreen.
///
/// Dekt Phase 4 success criteria 2 (vier preset-labels zichtbaar, 'Volgende' knop).
/// Tests gebruiken GoRouter fixture + FakeAvailabilityNotifier override zodat
/// geen SharedPreferences of echte provider-keten nodig is.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/features/onboarding/onboarding_screen.dart';
import 'package:ridewindow/providers/availability_notifier.dart';

// ---------------------------------------------------------------------------
// Fake AvailabilityNotifier: retourneert lege blocked-map zonder I/O
// ---------------------------------------------------------------------------

class FakeAvailabilityNotifier extends AvailabilityNotifier {
  @override
  Future<Map<DateTime, BlockType>> build() async => const {};
}

// ---------------------------------------------------------------------------
// Helper: GoRouter-fixture met OnboardingScreen als root
// ---------------------------------------------------------------------------

Widget _buildTestApp() {
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
    overrides: [
      availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
    ],
    child: MaterialApp.router(routerConfig: router),
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
  testWidgets('OnboardingScreen: tapping eerste preset geeft geen fout', (tester) async {
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
}
