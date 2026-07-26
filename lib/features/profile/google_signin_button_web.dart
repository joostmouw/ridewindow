// lib/features/profile/google_signin_button_web.dart
// Real google_sign_in_web-backed implementation, only compiled into the
// web/JS/Wasm build target (via the conditional import in
// google_signin_button.dart). Never referenced from the Android/VM build or
// from `flutter test`.

import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

Widget renderGoogleSignInButton() => web_only.renderButton();
