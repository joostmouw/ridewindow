// test/features/availability_no_dead_end_test.dart
// Regression guard for PWA-04 (Phase 16 Plan 03): proves the concrete
// onboarding-arrival dead end is fixed. `OnboardingScreen` arrives at
// `/availability?from=onboarding` via `context.go()`, which REPLACES
// navigation history rather than pushing -- so `Navigator.canPop()` is
// false on arrival and, before this plan, `AvailabilityScreen`'s
// unconditional `BackButton()` was visually present but did nothing when
// tapped (a genuine dead end in a standalone installed PWA with no browser
// chrome to fall back on).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/features/availability/availability_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Empty availability map -- no blocked hours, matching a fresh onboarding
/// arrival before the user has made any selections.
class FakeEmptyAvailabilityNotifier extends AvailabilityNotifier {
  @override
  Future<Map<DateTime, BlockType>> build() async => {};
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'onboarding-arrival dead end is fixed: canPop false at '
    '/availability?from=onboarding shows home icon, not a back arrow, and '
    'tapping it navigates to /home',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/availability?from=onboarding',
        routes: [
          GoRoute(
            path: '/availability',
            builder: (context, state) {
              final fromOnboarding =
                  state.uri.queryParameters['from'] == 'onboarding';
              return AvailabilityScreen(fromOnboarding: fromOnboarding);
            },
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('HomeScreen'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availabilityProvider
                .overrideWith(() => FakeEmptyAvailabilityNotifier()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            theme: ThemeData(extensions: const [RideWindowTheme.light]),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // canPop is false (no prior push, context.go() replaced history) ->
      // SafeBackButton must show the home fallback, not a back arrow.
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      expect(find.text('HomeScreen'), findsOneWidget);
    },
  );
}
