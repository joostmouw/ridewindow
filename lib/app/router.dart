// lib/app/router.dart
// go_router configuratie met onboarding redirect.
// Scherm-classes worden geimporteerd nadat Wave 3 ze aanmaakt.
// Tijdelijk: stub imports voor WelcomeScreen, OnboardingScreen, HomeScreen,
// AvailabilityScreen — vervang door echte imports in Wave 3/4.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'router.g.dart';

// Tijdelijke stubs zodat dit bestand compileert vóór Wave 3 de echte schermen aanmaakt.
// Wave 3 vervangt deze met echte imports.
class _WelcomeScreenStub extends StatelessWidget {
  const _WelcomeScreenStub();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Welcome (stub)')));
}

class _OnboardingScreenStub extends StatelessWidget {
  const _OnboardingScreenStub();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Onboarding (stub)')));
}

class _HomeScreenStub extends StatelessWidget {
  const _HomeScreenStub();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Home (stub)')));
}

class _AvailabilityScreenStub extends StatelessWidget {
  const _AvailabilityScreenStub();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Mijn schema (stub)')));
}

/// GoRouter met onboarding-redirect en vier Phase 4 routes.
///
/// Redirect: controleert SharedPreferences 'onboarding_complete'.
/// false of afwezig → /welcome; true → geen redirect.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('onboarding_complete') ?? false;
      if (!done) return '/welcome';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const _WelcomeScreenStub(),
      ),
      GoRoute(
        path: '/onboard',
        builder: (context, state) => const _OnboardingScreenStub(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const _HomeScreenStub(),
      ),
      GoRoute(
        path: '/availability',
        builder: (context, state) => const _AvailabilityScreenStub(),
      ),
    ],
  );
}
