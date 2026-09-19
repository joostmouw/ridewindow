// test/features/shared/add_to_home_screen_overlay_test.dart
// Widget tests for AddToHomeScreenOverlay (Phase 16 Plan 02, PWA-03).
// Gating matrix: native (web=false), desktop/Android-web (web=true, ios=false),
// iOS Safari not installed (web=true, ios=true, standalone=false) -- the only
// case where the banner renders -- and iOS installed/standalone (all true).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/data/repositories/install_hint_store.dart';
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
          "Tap the Share icon, then \"Add to Home Screen\" to install Ridewindow.",
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

  // ── Wegklikken (D-04 teruggedraaid op 2026-09-19) ──
  //
  // De balk had bewust geen wegklikknop, zodat hij zou blijven aandringen tot
  // de app geïnstalleerd was. Een tester meldde het gevolg: hij dekt bovenaan
  // permanent een strook van elk scherm af.

  testWidgets('de balk is weg te klikken', (tester) async {
    SharedPreferences.setMockInitialValues({});
    debugIsWebOverride = true;
    debugIsIosBrowserOverride = true;
    debugIsStandaloneOverride = false;

    await _pumpOverlay(tester);
    await tester.pumpAndSettle();

    expect(find.byType(IconButton), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(
      find.byType(IconButton),
      findsNothing,
      reason: 'na wegklikken hoort er niets meer te staan',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(InstallHintStore.kDismissCountKey), 1);
  });

  testWidgets('een eerder weggeklikte balk komt binnen een week niet terug',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      InstallHintStore.kDismissCountKey: 1,
      InstallHintStore.kDismissedAtKey:
          DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
    });
    debugIsWebOverride = true;
    debugIsIosBrowserOverride = true;
    debugIsStandaloneOverride = false;

    await _pumpOverlay(tester);
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('maar na een week wel', (tester) async {
    SharedPreferences.setMockInitialValues({
      InstallHintStore.kDismissCountKey: 1,
      InstallHintStore.kDismissedAtKey:
          DateTime.now().subtract(const Duration(days: 9)).millisecondsSinceEpoch,
    });
    debugIsWebOverride = true;
    debugIsIosBrowserOverride = true;
    debugIsStandaloneOverride = false;

    await _pumpOverlay(tester);
    await tester.pumpAndSettle();

    expect(find.byType(IconButton), findsOneWidget);
  });
}
