// lib/core/pwa_display_mode_stub.dart
// No-op implementation compiled for Android/VM builds (and `flutter test`,
// which runs on the Dart VM). Real detection lives in
// lib/core/pwa_display_mode_web.dart, which is only compiled for web
// targets -- this file guarantees package:web is never referenced outside
// the web build. See lib/core/pwa_display_mode.dart for the conditional
// import that selects between the two.

bool readIsStandalone() => false;

bool readIsIosUserAgent() => false;
