// lib/app/router.dart
// go_router configuratie met onboarding redirect.
// StatefulShellRoute voor persistente NavigationBar over Home en Profiel.
// Soepele page transitions voor alle routes.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridewindow/theme/app_motion.dart';
import 'package:ridewindow/app/scaffold_with_nav.dart';
import 'package:ridewindow/features/welcome/welcome_screen.dart';
import 'package:ridewindow/features/onboarding/onboarding_screen.dart';
import 'package:ridewindow/features/availability/availability_screen.dart';
import 'package:ridewindow/features/home/home_screen.dart';
import 'package:ridewindow/features/detail/detail_args.dart';
import 'package:ridewindow/features/detail/ride_detail_screen.dart';
import 'package:ridewindow/features/profile/profile_screen.dart';
import 'package:ridewindow/features/agenda/week_agenda_screen.dart';
import 'package:ridewindow/features/planned/planned_rides_screen.dart';

part 'router.g.dart';

/// Pre-loaded SharedPreferences, overridden in main() via ProviderScope.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Must be overridden in ProviderScope'),
);

/// Fade transition voor tab-wissels — effects spring (smooth, no overshoot).
CustomTransitionPage<void> _fadeTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.effectsCurve,
      );
      return FadeTransition(opacity: curved, child: child);
    },
    transitionDuration: AppMotion.effectsDuration,
  );
}

/// Slide-up transition voor detail/modale schermen — spatial spring (bouncy).
CustomTransitionPage<void> _slideUpTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
          .chain(CurveTween(curve: AppMotion.spatialEmphasizedCurve));
      final fadeTween = CurvedAnimation(
        parent: animation,
        curve: AppMotion.effectsCurve,
      );
      return FadeTransition(
        opacity: fadeTween,
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
    transitionDuration: AppMotion.spatialEmphasizedDuration,
  );
}

/// GoRouter met onboarding-redirect, StatefulShellRoute en soepele transitions.
///
/// Redirect: controleert SharedPreferences 'onboarding_complete'.
/// false of afwezig → /welcome; true → geen redirect.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final prefs = ref.read(sharedPrefsProvider);
      final done = prefs.getBool('onboarding_complete') ?? false;
      final loc = state.matchedLocation;
      if (!done &&
          loc != '/welcome' &&
          loc != '/onboard' &&
          loc != '/availability') {
        return '/welcome';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: '/onboard',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const OnboardingScreen()),
      ),

      // Home + Profile als tabs met gedeelde NavigationBar.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    _fadeTransition(state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/agenda',
                pageBuilder: (context, state) =>
                    _fadeTransition(state, const WeekAgendaScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rides',
                pageBuilder: (context, state) =>
                    _fadeTransition(state, const PlannedRidesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    _fadeTransition(state, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/availability',
        pageBuilder: (context, state) =>
            _slideUpTransition(state, const AvailabilityScreen()),
      ),
      GoRoute(
        path: '/detail',
        pageBuilder: (context, state) {
          // T-05-01: null-safe cast — guard against invalid navigation calls.
          if (state.extra is! DetailArgs) {
            return _fadeTransition(
              state,
              const Scaffold(
                body: Center(child: Text('Ongeldige navigatieargumenten.')),
              ),
            );
          }
          final args = state.extra as DetailArgs;
          return _slideUpTransition(
            state,
            RideDetailScreen(
              slot: args.slot,
              forecasts: args.forecasts,
            ),
          );
        },
      ),
    ],
  );
}
