// test/web/app_display_name_test.dart
// Verifies that every place which puts the app's name in front of a user
// agrees on the same string.
//
// Why this test exists: on 2026-08-07 a user had both the native app and the
// installed PWA on one home screen and saw two different names side by side —
// "ridewindow" under one icon, "RideWindow" under the other. The web side was
// inconsistent with itself too: manifest.json said "RideWindow" while
// index.html's <title> and apple-mobile-web-app-title said "ridewindow".
//
// The assertion deliberately checks that the sources AGREE, rather than that
// each one equals a hardcoded literal. That is the same lesson quick-260726-ka2
// wrote down after pwa_install_meta_test.dart had asserted on the literal
// '#2E7D32' and therefore had to be rewritten the moment the brand colour
// legitimately changed: pin the invariant, not today's value. Renaming the app
// should take one edit plus this test agreeing again — not a test failure that
// tempts someone to "fix" the test.
//
// Note on scope: pubspec.yaml's `name: ridewindow` is NOT covered here. That is
// the Dart package identifier and it is *required* to be lowercase snake_case;
// it is never shown to a user.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pulls the value out of `<meta name="..." content="VALUE">`.
String? _metaContent(String html, String metaName) {
  final match = RegExp(
    '<meta\\s+name="${RegExp.escape(metaName)}"\\s+content="([^"]*)"',
  ).firstMatch(html);
  return match?.group(1);
}

String? _title(String html) =>
    RegExp(r'<title>([^<]*)</title>').firstMatch(html)?.group(1);

String? _androidLabel(String xml) =>
    RegExp(r'android:label="([^"]*)"').firstMatch(xml)?.group(1);

void main() {
  final indexHtml = File('web/index.html').readAsStringSync();
  final manifest = jsonDecode(File('web/manifest.json').readAsStringSync())
      as Map<String, dynamic>;
  final androidManifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  group('user-visible app name', () {
    test('every source is present and non-empty', () {
      expect(
        _androidLabel(androidManifest),
        isNotNull,
        reason: 'android:label missing from AndroidManifest.xml',
      );
      expect(
        _title(indexHtml),
        isNotNull,
        reason: '<title> missing from web/index.html',
      );
      expect(
        _metaContent(indexHtml, 'apple-mobile-web-app-title'),
        isNotNull,
        reason: 'apple-mobile-web-app-title missing from web/index.html',
      );
      expect(manifest['name'], isNotNull);
      expect(manifest['short_name'], isNotNull);
    });

    test('all five agree on one spelling', () {
      final names = <String, String?>{
        'AndroidManifest.xml android:label': _androidLabel(androidManifest),
        'web/index.html <title>': _title(indexHtml),
        'web/index.html apple-mobile-web-app-title':
            _metaContent(indexHtml, 'apple-mobile-web-app-title'),
        'web/manifest.json name': manifest['name'] as String?,
        'web/manifest.json short_name': manifest['short_name'] as String?,
      };

      final distinct = names.values.toSet();
      expect(
        distinct,
        hasLength(1),
        reason: 'The app is named inconsistently across surfaces. '
            'A user with both the native app and the installed PWA sees these '
            'side by side on one home screen:\n'
            '${names.entries.map((e) => '  ${e.key}: "${e.value}"').join('\n')}',
      );
    });

    test('the agreed name is not the Flutter template placeholder', () {
      // Guards the degenerate way to make the test above pass: setting every
      // source to the same wrong value.
      final name = manifest['name'] as String;
      expect(
        name,
        isNot('ridewindow'),
        reason: 'lowercase "ridewindow" is the Dart package id, not the '
            'brand name — docs/store-listing.md and CLAUDE.md say RideWindow',
      );
      expect(name, isNot('web'));
      expect(name, isNot(contains('A new Flutter project')));
    });
  });
}
