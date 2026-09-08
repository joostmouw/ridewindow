// test/core/safe_back_button_test.dart
// Widget tests for SafeBackButton (Phase 16 Plan 03, PWA-04).
// Verifies the back-arrow+pop vs. home-icon+go('/home') branching, and that
// the widget never throws when built without a GoRouter ancestor -- matching
// the existing widget-test harness pattern used throughout this codebase
// (`MaterialApp(home: child)` with no GoRouter, e.g.
// ride_detail_screen_calendar_test.dart's wrapInMaterial helper).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ridewindow/core/safe_back_button.dart';
import 'package:ridewindow/theme/app_icons.dart';

void main() {
  group('SafeBackButton', () {
    testWidgets(
      'shows arrow_back and pops when Navigator can pop',
      (tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Center(child: Text('Home'))),
        ),);

        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(leading: const SafeBackButton()),
              body: const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(AppIcons.arrowLeft), findsOneWidget);
        expect(find.byIcon(AppIcons.house), findsNothing);

        await tester.tap(find.byIcon(AppIcons.arrowLeft));
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
      },
    );

    testWidgets(
      'shows home_outlined and navigates to fallbackRoute when GoRouter '
      'has no prior push (canPop false)',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/foo',
          routes: [
            GoRoute(
              path: '/foo',
              builder: (context, state) => Scaffold(
                appBar: AppBar(leading: const SafeBackButton()),
                body: const SizedBox.shrink(),
              ),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('HomeScreen'))),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.byIcon(AppIcons.house), findsOneWidget);
        expect(find.byIcon(AppIcons.arrowLeft), findsNothing);

        await tester.tap(find.byIcon(AppIcons.house));
        await tester.pumpAndSettle();

        expect(find.text('HomeScreen'), findsOneWidget);
      },
    );

    testWidgets(
      'never throws when built (or tapped) inside a plain MaterialApp with '
      'no GoRouter ancestor -- regression guard for existing test harnesses',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SafeBackButton()));
        await tester.pumpAndSettle();

        expect(find.byIcon(AppIcons.house), findsOneWidget);

        // Tapping must be a no-op, not a crash -- there is nothing sensible
        // to do without a GoRouter present.
        await tester.tap(find.byIcon(AppIcons.house));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
