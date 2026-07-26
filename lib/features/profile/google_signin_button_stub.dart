// lib/features/profile/google_signin_button_stub.dart
// No-op implementation compiled for Android/VM builds (and `flutter test`,
// which runs on the Dart VM). Real rendering lives in
// google_signin_button_web.dart, which is only compiled for web targets --
// this file guarantees `google_sign_in_web` (and its `dart:js_interop`-based
// dependency `google_identity_services_web`) is never referenced outside the
// web build. See google_signin_button.dart for the conditional import that
// selects between the two. This branch is unreachable at runtime on
// Android/VM: callers only invoke it from the `!supportsAuthenticate()` web
// branch of AccountSection, which is always false on native (Rule 1 fix,
// 19-03 -- the plan's `package:google_sign_in/web_only.dart` import path does
// not exist in google_sign_in 7.2.0, and importing the real
// `google_sign_in_web/web_only.dart` unconditionally breaks `flutter test`
// compilation on the VM target with `toJS`/`JSObject` CFE errors).

import 'package:flutter/widgets.dart';

Widget renderGoogleSignInButton() => const SizedBox.shrink();
