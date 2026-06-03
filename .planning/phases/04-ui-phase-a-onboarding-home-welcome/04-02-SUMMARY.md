---
phase: 04-ui-phase-a-onboarding-home-welcome
plan: "02"
subsystem: routing/providers/core
tags: [go_router, riverpod, routing, availability-presets, tdd, config]
dependency_graph:
  requires: ["04-01"]
  provides: ["GoRouter with onboarding redirect", "buildPreset() API", "LocationData/locationProvider", "kDefaultLat/kDefaultLon/kDefaultCity"]
  affects:
    - pubspec.yaml
    - lib/core/config.dart
    - lib/providers/location_provider.dart
    - lib/providers/location_provider.g.dart
    - lib/providers/availability_presets.dart
    - lib/app/router.dart
    - lib/app/router.g.dart
    - test/providers/availability_presets_test.dart
tech_stack:
  added: ["go_router 17.3.0 (resolved ^17.2.3)"]
  patterns:
    - "Pure-Dart preset builder (buildPreset) with work-hours-only semantics"
    - "GoRouter @Riverpod(keepAlive: true) provider with async SharedPreferences redirect"
    - "Stub screen classes in router.dart enabling Wave 3 screen creation without circular deps"
key_files:
  created:
    - lib/core/config.dart
    - lib/providers/location_provider.dart
    - lib/providers/location_provider.g.dart
    - lib/providers/availability_presets.dart
    - lib/app/router.dart
    - lib/app/router.g.dart
    - test/providers/availability_presets_test.dart
  modified:
    - pubspec.yaml
    - pubspec.lock
decisions:
  - "go_router resolved to 17.3.0 (plan specified ^17.2.3 — semver compatible, accepted)"
  - "Test date corrected from DateTime(2026,6,9) (Tuesday) to DateTime(2026,6,8) (Monday) — assert in buildPreset enforced weekday check"
  - "Lint fixes applied to availability_presets.dart: doc comment angle brackets → backticks, assert trailing comma added"
metrics:
  duration: "~26 minutes"
  completed: "2026-06-03"
  tasks_completed: 2
  files_changed: 9
---

# Phase 4 Plan 02: go_router + config + LocationProvider + availability_presets + GoRouter Summary

**One-liner:** Added go_router 17.3.0, Amsterdam config constants, LocationProvider stub, buildPreset() preset builder for all three availability presets, and GoRouter with SharedPreferences-based onboarding redirect and four routes (/welcome, /onboard, /home, /availability).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | go_router pubspec + config.dart + LocationProvider stub | f859557 | pubspec.yaml, pubspec.lock, lib/core/config.dart, lib/providers/location_provider.dart, lib/providers/location_provider.g.dart, lib/providers/slots_notifier.g.dart |
| 2 | availability_presets.dart + GoRouter (TDD RED→GREEN) | 675c25f | lib/providers/availability_presets.dart, lib/app/router.dart, lib/app/router.g.dart, test/providers/availability_presets_test.dart |

## What Was Built

### Task 1: go_router + config.dart + LocationProvider stub

- Added `go_router: ^17.2.3` to pubspec.yaml (resolved to 17.3.0 — semver compatible)
- Created `lib/core/config.dart` with three pure-Dart constants: `kDefaultLat = 52.3676`, `kDefaultLon = 4.9041`, `kDefaultCity = 'Amsterdam'`
- Created `lib/providers/location_provider.dart` with `LocationData` class and `@riverpod LocationData location(Ref ref)` stub returning Amsterdam defaults
- Generated `lib/providers/location_provider.g.dart` via build_runner
- `dart analyze lib/core/ lib/providers/location_provider.dart` → No issues found

### Task 2: availability_presets.dart + GoRouter (TDD RED→GREEN)

**RED phase:** Created `test/providers/availability_presets_test.dart` with 5 tests. Tests failed as expected (compile error: `lib/providers/availability_presets.dart` did not exist).

**GREEN phase:** Created `lib/providers/availability_presets.dart`:
- `enum AvailabilityPreset { eveningsAndWeekends, morningsAndWeekends, weekendsOnly, custom }`
- `buildPreset(AvailabilityPreset preset, DateTime weekStart)` — returns `Map<DateTime, BlockType>` of work-blocked hours
- Preset semantics: presets define FREE hours; all other hours become `BlockType.work`
  - `eveningsAndWeekends`: ma-vr 17:00-22:00 free + za/zo all free → work = ma-vr 00-16 + 23
  - `morningsAndWeekends`: ma-vr 06:00-08:00 free + za/zo all free → work = ma-vr 00-05 + 09-23
  - `weekendsOnly`: za/zo all free → work = all 24h mon-fri
  - `custom`: returns empty map (user picks manually)
- Assert enforces `weekStart.weekday == DateTime.monday`

All 5 tests pass.

Created `lib/app/router.dart`:
- Stub screen classes (`_WelcomeScreenStub`, `_OnboardingScreenStub`, `_HomeScreenStub`, `_AvailabilityScreenStub`) compile the file before Wave 3 creates real screens
- `@Riverpod(keepAlive: true) GoRouter router(Ref ref)` with `initialLocation: '/home'`, async redirect reading `SharedPreferences 'onboarding_complete'`
- Four routes: `/welcome`, `/onboard`, `/home`, `/availability`
- Generated `lib/app/router.g.dart` via build_runner

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test date was a Tuesday, not Monday**
- **Found during:** Task 2 GREEN phase (assert in buildPreset threw: "weekStart moet een maandag zijn, was: 2")
- **Issue:** Test used `DateTime(2026, 6, 9)` which is Tuesday (weekday=2); the assert in `buildPreset` correctly rejected it
- **Fix:** Updated test to use `DateTime(2026, 6, 8)` (Monday) and updated all inline date references in test body accordingly
- **Files modified:** test/providers/availability_presets_test.dart
- **Commit:** 675c25f (included in Task 2)

**2. [Rule 2 - Lint] availability_presets.dart had two info-level issues**
- **Found during:** Task 2 dart analyze check
- **Issues:** Doc comment used `Map<DateTime, BlockType>` with unescaped angle brackets (unintended_html_in_doc_comment); assert call missing trailing comma (require_trailing_commas)
- **Fix:** Changed doc comment to use backticks; restructured assert call with trailing comma
- **Files modified:** lib/providers/availability_presets.dart
- **Commit:** 675c25f (included in Task 2)

## Verification Results

```
flutter pub deps | grep go_router → go_router 17.3.0
grep -c "kDefaultLat" lib/core/config.dart → 1
grep -c "onboarding_complete" lib/app/router.dart → 2
grep -c "AvailabilityPreset" lib/providers/availability_presets.dart → 8
dart analyze lib/ → No issues found
flutter test (exit 0) → 106 tests passed (was 101 before this plan, +5 new availability_presets tests)
```

## Success Criteria Verification

1. go_router ^17.2.3 in pubspec.yaml, flutter pub get succesvol — PASS (resolved 17.3.0)
2. lib/core/config.dart met kDefaultLat=52.3676, kDefaultLon=4.9041, kDefaultCity='Amsterdam' — PASS
3. locationProvider gegenereerd en retourneert LocationData met Amsterdam defaults — PASS
4. buildPreset() correct: ma-vr 17:00 is vrij bij eveningsAndWeekends; za 00:00 is vrij bij alle presets behalve custom — PASS
5. GoRouter redirect leest 'onboarding_complete', routes /welcome /onboard /home /availability geregistreerd — PASS
6. dart analyze lib/ No issues found — PASS
7. flutter test suite slaagt volledig (106 tests, exit 0) — PASS

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `_WelcomeScreenStub` | lib/app/router.dart | ~16 | Wave 3 (04-03) will replace with real WelcomeScreen import |
| `_OnboardingScreenStub` | lib/app/router.dart | ~23 | Wave 3 (04-03) will replace with real OnboardingScreen import |
| `_HomeScreenStub` | lib/app/router.dart | ~30 | Wave 4 (04-04) will replace with real HomeScreen import |
| `_AvailabilityScreenStub` | lib/app/router.dart | ~37 | Wave 3 (04-03) will replace with real AvailabilityScreen import |

These stubs are intentional and documented in router.dart per the plan. They enable this file to compile before the real screens are created in Wave 3/4.

## Threat Model Applied

| Threat | Disposition | Applied |
|--------|-------------|---------|
| T-04-02-01 Tampering via SharedPreferences 'onboarding_complete' | accept | Boolean flag; false=show onboarding (safe default); no sensitive data |
| T-04-02-02 Elevation of Privilege via stub classes | accept | Compile-time only; Wave 3 replaces stubs; no security impact |
| T-04-SC go_router package legitimacy | mitigate | go_router is flutter.dev publisher; verified in CLAUDE.md tech stack |

## Self-Check: PASSED

Files verified:
- lib/core/config.dart — FOUND
- lib/providers/location_provider.dart — FOUND
- lib/providers/location_provider.g.dart — FOUND
- lib/providers/availability_presets.dart — FOUND
- lib/app/router.dart — FOUND
- lib/app/router.g.dart — FOUND
- test/providers/availability_presets_test.dart — FOUND

Commits verified:
- f859557 — FOUND (feat(04-02): add go_router, config.dart, LocationProvider stub)
- 675c25f — FOUND (feat(04-02): availability_presets + GoRouter with onboarding redirect)
