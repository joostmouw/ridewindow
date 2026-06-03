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
    child: MaterialApp.router(routerConfig: router),
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
  // Test 2: Titel 'perfecte rijmoment' zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('WelcomeScreen toont titel met "perfecte rijmoment"', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('perfecte rijmoment'), findsOneWidget);
  });
}
