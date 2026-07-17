// test/features/shared/add_to_home_screen_overlay_test.dart
// Widget tests for AddToHomeScreenOverlay (Phase 16 Plan 02, PWA-03).
// Gating matrix: native (web=false), desktop/Android-web (web=true, ios=false),
// iOS Safari not installed (web=true, ios=true, standalone=false) -- the only
// case where the banner renders -- and iOS installed/standalone (all true).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/core/pwa_display_mode.dart';
import 'package:ridewindow/features/shared/add_to_home_screen_overlay.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

Future<void> _pumpOverlay(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      // Positioned requires a Stack ancestor -- mirrors the real usage in
      // lib/main.dart's MaterialApp.router builder.
      home: Scaffold(body: Stack(children: [AddToHomeScreenOverlay()])),
    ),
  );
}

void main() {
  tearDown(() {
    debugIsWebOverride = null;
    debugIsStandaloneOverride = null;
    debugIsIosBrowserOverride = null;
  });

  testWidgets(
    'renders nothing when debugIsWebOverride = false (native)',
    (tester) async {
      debugIsWebOverride = false;
      await _pumpOverlay(tester);

      expect(find.byType(Text), findsNothing);
    },
  );

  testWidgets(
    'renders nothing when web = true but ios browser = false (desktop/Android Chrome)',
    (tester) async {
      debugIsWebOverride = true;
      debugIsIosBrowserOverride = false;
      await _pumpOverlay(tester);

      expect(find.byType(Text), findsNothing);
    },
  );

  testWidgets(
    'renders the banner text when web = true, ios = true, standalone = false',
    (tester) async {
      debugIsWebOverride = true;
      debugIsIosBrowserOverride = true;
      debugIsStandaloneOverride = false;
      await _pumpOverlay(tester);

      expect(
        find.text(
          "Tap the Share icon, then \"Add to Home Screen\" to install RideWindow.",
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'renders nothing when web = true, ios = true, standalone = true (already installed)',
    (tester) async {
      debugIsWebOverride = true;
      debugIsIosBrowserOverride = true;
      debugIsStandaloneOverride = true;
      await _pumpOverlay(tester);

      expect(find.byType(Text), findsNothing);
    },
  );
}
