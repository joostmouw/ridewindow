// test/web/index_html_meta_tag_test.dart
// Verifies web/index.html carries a real Google Web OAuth client ID meta tag
// (CAL-06) — google_sign_in_web reads this <meta name="google-signin-client_id">
// tag at runtime to bootstrap the GIS SDK on web. Guards against an unreplaced
// copy-paste placeholder ever being committed.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'web/index.html bevat een echte google-signin-client_id meta tag, geen placeholder',
    () {
      final contents = File('web/index.html').readAsStringSync();

      expect(contents, contains('name="google-signin-client_id"'));
      expect(contents, contains('.apps.googleusercontent.com'));
      expect(contents, isNot(contains('YOUR_WEB_OAUTH_CLIENT_ID')));
    },
  );
}
