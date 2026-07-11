// lib/core/platform_info.dart
// Testable seam for kIsWeb-gated behavior (Phase 13 Plan 01, LOC-06/LOC-07).
//
// Why this indirection exists: `kIsWeb` is defined as `identical(0, 0.0)`, a
// compile-time constant that always evaluates to `false` when compiled for
// the Dart VM (which is what `flutter test` runs on). It can never be
// toggled at runtime, so any UI/behavior branch gated directly on `kIsWeb`
// is permanently untestable via `flutter test`.
//
// Every future web-only branch in this codebase that needs test coverage
// should import `isWebPlatform` from this file instead of importing
// `kIsWeb` directly from `package:flutter/foundation.dart`.

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

/// Test-only override for [isWebPlatform]. Defaults to `null`, meaning
/// "use the real platform value". Set to `true`/`false` in tests to force
/// web/non-web behavior; always reset to `null` in `tearDown()` since this
/// is a process-global mutable variable.
@visibleForTesting
bool? debugIsWebOverride;

/// Whether the app is currently running on the web platform.
///
/// Prefer this over importing `kIsWeb` directly so that web-gated behavior
/// remains testable via [debugIsWebOverride].
bool get isWebPlatform => debugIsWebOverride ?? kIsWeb;
