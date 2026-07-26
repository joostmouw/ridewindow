// lib/features/profile/google_signin_button.dart
// Testable seam for the web-only Google Sign-In rendered button (D-05/D-06,
// PITFALLS.md #2), following the exact conditional-import pattern of
// lib/core/pwa_display_mode.dart: `google_signin_button_stub.dart` compiles
// for Android/VM (and `flutter test`), `google_signin_button_web.dart`
// compiles only for the web/JS/Wasm target.

import 'google_signin_button_stub.dart'
    if (dart.library.js_interop) 'google_signin_button_web.dart' as impl;

import 'package:flutter/widgets.dart';

/// Renders Google's own Sign-In button (web only). On Android/VM this
/// returns an empty [SizedBox] and is never actually built -- callers only
/// reach this from AccountSection's `!supportsAuthenticate()` web branch,
/// which is always false on native.
Widget renderGoogleSignInButton() => impl.renderGoogleSignInButton();
