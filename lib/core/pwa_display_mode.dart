// lib/core/pwa_display_mode.dart
// Testable seam for PWA install-state detection (Phase 16 Plan 02, PWA-03),
// following the exact pattern of lib/core/platform_info.dart:
// `debugIsWebOverride`/`isWebPlatform`.
//
// `isStandaloneDisplayMode` answers "is the app already installed and
// running standalone (display-mode: standalone matches)?" and
// `isIosBrowserMode` answers "is this iOS Safari (not Chrome/desktop)?".
// Both resolve to `false` on native/Android (gated by `isWebPlatform`) and
// on the Dart VM test runner (which always compiles the stub
// implementation, never `package:web`).

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:ridewindow/core/platform_info.dart';

import 'pwa_display_mode_stub.dart'
    if (dart.library.js_interop) 'pwa_display_mode_web.dart' as impl;

/// Test-only override for [isStandaloneDisplayMode]. `null` means "use the
/// real platform value". Always reset to `null` in `tearDown()`.
@visibleForTesting
bool? debugIsStandaloneOverride;

/// Test-only override for [isIosBrowserMode]. `null` means "use the real
/// platform value". Always reset to `null` in `tearDown()`.
@visibleForTesting
bool? debugIsIosBrowserOverride;

/// Whether the app is currently running installed/standalone (i.e. the
/// browser's `display-mode: standalone` media query matches). Always
/// `false` on native/Android -- gated on [isWebPlatform] first so that a
/// `debugIsWebOverride = false` test setup always wins, regardless of
/// [debugIsStandaloneOverride].
bool get isStandaloneDisplayMode =>
    isWebPlatform && (debugIsStandaloneOverride ?? impl.readIsStandalone());

/// Whether the app is currently running in an iOS Safari browser tab
/// (Home Screen not yet added). Always `false` on native/Android and on
/// desktop/Android Chrome -- gated on [isWebPlatform] first, same rationale
/// as [isStandaloneDisplayMode].
bool get isIosBrowserMode =>
    isWebPlatform && (debugIsIosBrowserOverride ?? impl.readIsIosUserAgent());
