// lib/app/router.dart
// go_router configuratie met onboarding redirect.
// Wave 3: WelcomeScreen, OnboardingScreen en AvailabilityScreen zijn echte imports.
// Wave 4: HomeScreen is echte import (Wave 4 voltooid).
// Wave 5: /detail route toegevoegd met DetailArgs via state.extra.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridewindow/features/welcome/welcome_screen.dart';
import 'package:ridewindow/features/onboarding/onboarding_screen.dart';
import 'package:ridewindow/features/availability/availability_screen.dart';
import 'package:ridewindow/features/home/home_screen.dart';
import 'package:ridewindow/features/detail/detail_args.dart';
import 'package:ridewindow/features/detail/ride_detail_screen.dart';

part 'router.g.dart';

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
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboard',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/availability',
        builder: (context, state) => const AvailabilityScreen(),
      ),
      GoRoute(
        path: '/detail',
        builder: (context, state) {
          // T-05-01: null-safe cast — guard against invalid navigation calls.
          if (state.extra is! DetailArgs) {
            return const Scaffold(
              body: Center(child: Text('Ongeldige navigatieargumenten.')),
            );
          }
          final args = state.extra as DetailArgs;
          return RideDetailScreen(slot: args.slot, forecasts: args.forecasts);
        },
      ),
    ],
  );
}
