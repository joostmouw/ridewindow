// lib/core/safe_back_button.dart
// PWA-04: standalone-mode navigation dead-end guard.
//
// A back button that gracefully falls back to a home-navigation affordance
// when there is no route to pop -- e.g. arriving at a screen via
// `context.go()` (which REPLACES navigation history rather than pushing) or
// a cold reload / direct launch landing with no history at all. In a
// standalone installed PWA there is no browser chrome to fall back on, so a
// screen relying on an unconditional `BackButton()` (or the implicit
// auto-back Flutter shows when it thinks it can pop) can become a genuine
// dead end.
//
// Uses plain `Navigator.of(context).canPop()` (never the go_router
// `context.canPop()` extension) for the poppable check, so this widget
// builds identically whether or not a GoRouter ancestor is present -- this
// matters because several existing widget tests in this codebase wrap
// screens in a bare `MaterialApp(home: child)` with NO GoRouter ancestor at
// all (e.g. ride_detail_screen_calendar_test.dart's `wrapInMaterial`).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

class SafeBackButton extends StatelessWidget {
  const SafeBackButton({super.key, this.fallbackRoute = '/home'});

  /// Route navigated to via `GoRouter.go()` when there is nothing to pop.
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    // Null-safe localization lookup: some existing widget-test harnesses
    // (e.g. ride_detail_screen_calendar_test.dart) wrap screens in a plain
    // `MaterialApp(home: child)` with no `S.delegate` registered, in which
    // case `S.of(context)` (`Localizations.of<S>(context, S)!`) would throw
    // a null-check error during build -- violating this widget's own
    // "never throws when built" contract. `MaterialLocalizations` is always
    // available (MaterialApp provides a default English fallback
    // internally regardless of `localizationsDelegates`), so it is safe to
    // rely on unconditionally for the poppable-state tooltip.
    final localizedS = Localizations.of<S>(context, S);
    final tooltip = canPop
        ? MaterialLocalizations.of(context).backButtonTooltip
        : (localizedS?.navHome ?? 'Home');

    return IconButton(
      icon: Icon(canPop ? Icons.arrow_back : Icons.home_outlined),
      tooltip: tooltip,
      onPressed: () {
        final router = GoRouter.maybeOf(context);
        if (canPop) {
          if (router != null) {
            context.pop();
          } else {
            Navigator.of(context).pop();
          }
        } else {
          // No-op if no GoRouter is present -- there is nothing sensible to
          // do without a router, and this path is only reachable in a real
          // app where GoRouter is always mounted.
          router?.go(fallbackRoute);
        }
      },
    );
  }
}
