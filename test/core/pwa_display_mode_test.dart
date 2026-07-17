// test/core/pwa_display_mode_test.dart
// Unit tests for the isStandaloneDisplayMode/isIosBrowserMode testable seam
// (Phase 16 Plan 02, PWA-03). Verifies the debug-override gating logic that
// lets these getters be exercised on the Dart VM (flutter test), where the
// real package:web-backed implementation is never compiled in.

import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/core/pwa_display_mode.dart';

void main() {
  tearDown(() {
    debugIsWebOverride = null;
    debugIsStandaloneOverride = null;
    debugIsIosBrowserOverride = null;
  });

  group('isStandaloneDisplayMode / isIosBrowserMode', () {
    test(
      'both default to false when debugIsWebOverride is false (native/Android), '
      'regardless of the other debug overrides',
      () {
        debugIsWebOverride = false;
        debugIsStandaloneOverride = true;
        debugIsIosBrowserOverride = true;

        expect(isStandaloneDisplayMode, isFalse);
        expect(isIosBrowserMode, isFalse);
      },
    );

    test(
      'isStandaloneDisplayMode is true when debugIsWebOverride = true and '
      'debugIsStandaloneOverride = true',
      () {
        debugIsWebOverride = true;
        debugIsStandaloneOverride = true;

        expect(isStandaloneDisplayMode, isTrue);
      },
    );

    test(
      'isIosBrowserMode is true when debugIsWebOverride = true and '
      'debugIsIosBrowserOverride = true, independent of the standalone override',
      () {
        debugIsWebOverride = true;
        debugIsIosBrowserOverride = true;
        debugIsStandaloneOverride = false;

        expect(isIosBrowserMode, isTrue);
      },
    );
  });
}
