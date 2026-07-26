// test/web/pwa_install_meta_test.dart
// Verifies web/index.html and web/manifest.json carry real RideWindow PWA
// installability metadata (PWA-01/PWA-02) instead of the default Flutter
// template placeholders. Guards against a regression ever silently
// reintroducing the generic Flutter icon references, brand color, or a
// missing viewport-fit=cover tag (which would break iOS Safari safe-area
// detection for every existing AppBar/SafeArea widget).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('web/index.html', () {
    final contents = File('web/index.html').readAsStringSync();

    test('has viewport-fit=cover for iOS Safari safe-area detection', () {
      expect(contents, contains('viewport-fit=cover'));
    });

    test('has the legacy apple-mobile-web-app-capable meta tag', () {
      expect(contents, contains('apple-mobile-web-app-capable'));
    });

    test('apple-touch-icon points at the branded 180x180 asset', () {
      expect(contents, contains('Icon-apple-touch-180.png'));
      expect(contents, isNot(contains('apple-touch-icon" href="icons/Icon-192.png"')));
    });

    test('has all 5 representative apple-touch-startup-image splash tags', () {
      expect(contents, contains('apple-splash-750x1334.png'));
      expect(contents, contains('apple-splash-1170x2532.png'));
      expect(contents, contains('apple-splash-1179x2556.png'));
      expect(contents, contains('apple-splash-1284x2778.png'));
      expect(contents, contains('apple-splash-1290x2796.png'));
    });
  });

  group('web/manifest.json', () {
    final contents = File('web/manifest.json').readAsStringSync();

    test('advertises the real RideWindow name, not the Flutter placeholder', () {
      expect(contents, contains('"RideWindow"'));
      expect(contents, isNot(contains('A new Flutter project.')));
    });

    test('uses the official brand colors, not the Flutter default', () {
      // #C5D4B6 = AppColors.brandLight (app background), #234934 =
      // AppColors.brandDark (scheme seed). #2E7D32 is the *old* green — it
      // survives in app_colors.dart only as the "Perfect" score color, which
      // is a different meaning of the same hex and must never leak back here.
      expect(contents, contains('"background_color": "#C5D4B6"'));
      expect(contents, contains('"theme_color": "#234934"'));
      expect(contents, isNot(contains('#2E7D32')));
      expect(contents, isNot(contains('#0175C2')));
    });
  });

  group('web shell color consistency', () {
    // The actual invariant: index.html and manifest.json must agree. When they
    // drift, iOS paints one color then repaints with the other — a visible
    // flash on every cold start. This is what regressed between 17 and 25 July
    // 2026, when the brand-color commit touched only Dart code.
    final html = File('web/index.html').readAsStringSync();
    final manifest = File('web/manifest.json').readAsStringSync();

    test('index.html theme-color matches manifest theme_color', () {
      expect(html, contains('name="theme-color" content="#234934"'));
      expect(manifest, contains('"theme_color": "#234934"'));
    });

    test('index.html background matches manifest background_color', () {
      expect(html, contains('name="background-color" content="#C5D4B6"'));
      expect(html, contains('background-color: #C5D4B6;'));
      expect(manifest, contains('"background_color": "#C5D4B6"'));
    });

    test('no stale #2E7D32 anywhere in the web shell', () {
      expect(html, isNot(contains('#2E7D32')));
      expect(manifest, isNot(contains('#2E7D32')));
    });
  });
}
