---
phase: 16-pwa-installability-ios-polish
plan: 02
subsystem: ui
tags: [pwa, ios, safari, display-mode, home-screen, flutter-web, riverpod-free-widget]

requires:
  - phase: 16-pwa-installability-ios-polish (Plan 01)
    provides: "Branded manifest.json/index.html with viewport-fit=cover, apple-touch-icon, theme-color -- the meta-tag foundation display-mode: standalone detection depends on"
provides:
  - "lib/core/pwa_display_mode.dart: isStandaloneDisplayMode/isIosBrowserMode testable getters (debug-override pattern matching platform_info.dart)"
  - "lib/core/pwa_display_mode_stub.dart / pwa_display_mode_web.dart: conditional-import split keeping package:web out of the Android/VM build"
  - "lib/features/shared/add_to_home_screen_overlay.dart: persistent top banner, no dismiss, no shared_preferences (D-04)"
  - "web: promoted from transitive to direct pubspec.yaml dependency"
  - "addToHomeScreenHint l10n string (NL/EN)"
affects: [16-03, 16-04]

tech-stack:
  added: ["web: ^1.1.0 (direct dependency, was already transitive via drift_flutter)"]
  patterns:
    - "Conditional import for web-only code: `import 'x_stub.dart' if (dart.library.js_interop) 'x_web.dart' as impl;` -- lets flutter test (Dart VM) always resolve the stub while the real web build resolves the package:web implementation"
    - "Debug-override getters gated on isWebPlatform FIRST (isWebPlatform && (override ?? realImpl())) so a false override always wins over other overrides -- needed to satisfy the 'native ignores all other overrides' behavior case"

key-files:
  created:
    - lib/core/pwa_display_mode.dart
    - lib/core/pwa_display_mode_stub.dart
    - lib/core/pwa_display_mode_web.dart
    - lib/features/shared/add_to_home_screen_overlay.dart
    - test/core/pwa_display_mode_test.dart
    - test/features/shared/add_to_home_screen_overlay_test.dart
  modified:
    - pubspec.yaml
    - lib/main.dart
    - lib/l10n/app_nl.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_nl.dart
    - lib/l10n/app_localizations_en.dart

key-decisions:
  - "isStandaloneDisplayMode/isIosBrowserMode gate on isWebPlatform BEFORE applying their own debug overrides (isWebPlatform && (debugOverride ?? impl())), not the naive (debugOverride ?? (isWebPlatform && impl())) ordering -- required so debugIsWebOverride=false always wins regardless of what debugIsStandaloneOverride/debugIsIosBrowserOverride are set to (first behavior case in the plan)."
  - "Overlay uses Theme.of(context).colorScheme.inverseSurface/onInverseSurface (MD3 tonal roles) for the banner, matching the material-3 skill's 'never hardcode colors' rule and consistent with ScreenHintOverlay's existing use of Theme.of(context).colorScheme.scrim elsewhere."

requirements-completed: [PWA-03]

duration: ~25min
completed: 2026-07-17
---

# Phase 16 Plan 02: Add-to-Home-Screen Overlay Summary

**A testable `isStandaloneDisplayMode`/`isIosBrowserMode` detection seam (conditional-import-based, native-Android-safe) plus a persistent top-of-screen "Add to Home Screen" banner wired into `MaterialApp.router`, satisfying PWA-03 with zero shared_preferences persistence per D-04.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-17
- **Tasks:** 2/2
- **Files modified:** 12 (6 new, 6 modified — pubspec.yaml, lib/main.dart, 4 l10n files, plus 2 test files listed as created since they're new)

## Accomplishments
- New `lib/core/pwa_display_mode.dart` testable seam exposing `isStandaloneDisplayMode`/`isIosBrowserMode`, following the exact `platform_info.dart` debug-override pattern
- Conditional-import split (`pwa_display_mode_stub.dart` / `pwa_display_mode_web.dart`) keeps `package:web` out of the Android build and out of `flutter test` entirely — confirmed via a green `flutter build apk --debug` and a green `flutter build web --release`
- New `AddToHomeScreenOverlay` widget: top-positioned, MD3-tonal (`inverseSurface`/`onInverseSurface`), no dismiss button, no persistence — reappears every session in iOS Safari until the app is actually installed
- Wired into `lib/main.dart`'s `MaterialApp.router` via a single `builder:` parameter, so the banner appears above all 8 routes without per-screen wiring
- `web` promoted from a transitive to a direct `pubspec.yaml` dependency (already resolved at 1.1.1 via `drift_flutter`, so no new package install — no legitimacy checkpoint needed)
- All 7 behavior-block test cases pass; `flutter analyze` clean on all new/modified files (one pre-existing, untouched `prefer_const_constructors` info on `lib/main.dart:134` predates this plan and is out of scope)

## Task Commits

Each task was committed atomically (TDD: RED → GREEN):

1. **Task 1 RED: failing tests for detection seam + overlay** - `bbb016b` (test)
2. **Task 1 GREEN: display-mode seam + AddToHomeScreenOverlay widget** - `b0ef3cc` (feat)
3. **Task 2: wire overlay into MaterialApp.router** - `3dc3e5d` (feat)

_No REFACTOR commit needed — implementation was already minimal/clean on first pass._

## Files Created/Modified
- `lib/core/pwa_display_mode.dart` — `isStandaloneDisplayMode`/`isIosBrowserMode` getters + `debugIsStandaloneOverride`/`debugIsIosBrowserOverride`
- `lib/core/pwa_display_mode_stub.dart` — no-op `false`-returning implementation (Android/VM/test target)
- `lib/core/pwa_display_mode_web.dart` — real `package:web` `window.matchMedia`/`navigator.userAgent` implementation (web target only)
- `lib/features/shared/add_to_home_screen_overlay.dart` — the persistent banner widget
- `lib/main.dart` — added `builder:` to `MaterialApp.router` wrapping routed child + overlay in a `Stack`
- `pubspec.yaml` — `web: ^1.1.0` added as a direct dependency under a new "Phase 16 — PWA install detection" comment
- `lib/l10n/app_nl.arb` / `app_en.arb` — new `addToHomeScreenHint` key; regenerated `app_localizations*.dart` via `flutter gen-l10n`
- `test/core/pwa_display_mode_test.dart` — 3 unit tests for the debug-override gating logic
- `test/features/shared/add_to_home_screen_overlay_test.dart` — 4 widget tests for the render-gating matrix

## Decisions Made
- Gated both getters on `isWebPlatform` *before* consulting their own debug override (`isWebPlatform && (override ?? impl())`) rather than the plan's literal-reading `(override ?? (isWebPlatform && impl()))` — the latter would let `debugIsStandaloneOverride = true` win even when `debugIsWebOverride = false`, failing the plan's own first behavior case ("both default to false when debugIsWebOverride is false, regardless of the other debug overrides"). This is a same-intent correction, not a scope change — the plan's prose already specified the correct observable behavior, and this is the implementation that satisfies it.
- Used `colorScheme.inverseSurface`/`onInverseSurface` MD3 tonal-pair tokens for the banner (per the material-3 skill's "never hardcode colors, only pair tokens correctly" rule), rather than a raw color.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected getter override-precedence to match the plan's own specified behavior**
- **Found during:** Task 1, writing the implementation against the already-written RED tests
- **Issue:** A literal reading of the plan's action text ("each resolving `override ?? (isWebPlatform && impl.readX())`") produces a getter where an explicit `debugIsStandaloneOverride = true` overrides `debugIsWebOverride = false`, contradicting the plan's own first `<behavior>` bullet ("both default to false when debugIsWebOverride is false ... regardless of the other debug overrides").
- **Fix:** Reordered to `isWebPlatform && (debugOverride ?? impl())` so `isWebPlatform` (itself gateable via `debugIsWebOverride`) is checked first and short-circuits to `false` before any override is consulted.
- **Files modified:** `lib/core/pwa_display_mode.dart`
- **Verification:** All 3 unit tests in `test/core/pwa_display_mode_test.dart` pass, including the native-overrides-everything case.
- **Committed in:** `b0ef3cc` (Task 1 GREEN commit)

**2. [Rule 1 - Bug] Test helper needed a `Stack` ancestor for `Positioned`**
- **Found during:** Task 1, first GREEN test run
- **Issue:** The widget test originally pumped `AddToHomeScreenOverlay` directly inside `Scaffold(body: ...)`. Since the overlay's `build()` returns a `Positioned` widget when visible, this throws Flutter's "Positioned widgets must be placed inside a Stack" error — not a production bug (real usage in `lib/main.dart` always wraps it in a `Stack` per Task 2's design), but the test fixture didn't yet mirror that.
- **Fix:** Wrapped the pumped widget in `Stack(children: [AddToHomeScreenOverlay()])` in the test helper, matching the real `lib/main.dart` `builder:` usage.
- **Files modified:** `test/features/shared/add_to_home_screen_overlay_test.dart`
- **Verification:** All 4 widget tests pass.
- **Committed in:** `b0ef3cc` (Task 1 GREEN commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — correctness fixes needed for the plan's own specified/intended behavior to actually hold)
**Impact on plan:** No scope creep — both fixes make the implementation match the plan's stated intent exactly; same files, same task boundaries.

## Issues Encountered
None beyond the two auto-fixed items above.

## User Setup Required
None — no external service configuration required. (Real-iPhone Safari verification of the banner's actual visual appearance is deferred to PWA-05's manual verification pass later in Phase 16, per the phase context.)

## Next Phase Readiness
- PWA-03 is satisfied: the detection seam and overlay are wired at the app-shell level and covered by tests.
- Standalone-mode back/close navigation audit (D-05) and the Drift web storage-eviction concern remain for subsequent 16-0x plans.
- The overlay's real on-device appearance (text wrapping, safe-area clearance, actual Safari `display-mode` detection) has not yet been visually verified on a physical iPhone — that verification belongs to PWA-05's dedicated manual-testing plan, not this one.

---
*Phase: 16-pwa-installability-ios-polish*
*Completed: 2026-07-17*

## Self-Check: PASSED

All created files verified present on disk (`lib/core/pwa_display_mode.dart`, `lib/core/pwa_display_mode_stub.dart`, `lib/core/pwa_display_mode_web.dart`, `lib/features/shared/add_to_home_screen_overlay.dart`, `test/core/pwa_display_mode_test.dart`, `test/features/shared/add_to_home_screen_overlay_test.dart`). All 3 task commits (`bbb016b`, `b0ef3cc`, `3dc3e5d`) verified present in `git log --oneline`.
