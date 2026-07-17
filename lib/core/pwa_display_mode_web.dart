// lib/core/pwa_display_mode_web.dart
// Real package:web-backed implementation, only compiled into the web/JS/Wasm
// build target (via the conditional import in lib/core/pwa_display_mode.dart).
// Never referenced from the Android/VM build or from `flutter test`.

import 'package:web/web.dart' as web;

bool readIsStandalone() =>
    web.window.matchMedia('(display-mode: standalone)').matches;

bool readIsIosUserAgent() {
  final userAgent = web.window.navigator.userAgent;
  return userAgent.contains('iPhone') ||
      userAgent.contains('iPad') ||
      userAgent.contains('iPod');
}
