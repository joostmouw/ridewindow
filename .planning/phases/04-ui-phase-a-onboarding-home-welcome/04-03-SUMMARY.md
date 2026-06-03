---
phase: 04-ui-phase-a-onboarding-home-welcome
plan: "03"
subsystem: ui/onboarding
tags: [flutter, go_router, riverpod, onboarding, welcome, availability-stub]
dependency_graph:
  requires: ["04-02"]
  provides: ["WelcomeScreen", "OnboardingScreen with preset selection", "AvailabilityScreen stub", "router.dart with real imports"]
  affects:
    - lib/features/welcome/welcome_screen.dart
    - lib/features/onboarding/onboarding_screen.dart
    - lib/features/availability/availability_screen.dart
    - lib/app/router.dart
tech_stack:
  added: []
  patterns:
    - "ConsumerStatefulWidget for Riverpod-integrated screen with local state"
    - "CustomPainter (_DashedBorderPainter) for dashed border effect on custom preset option"
    - "weekStart calculation: DateTime.now() - (weekday - DateTime.monday) days"
decisions:
  - "Dart records not used for preset data — plain const class _PresetOption is cleaner and compiles without Dart 3 records syntax issues"
  - "Dashed border implemented via _DashedBorderPainter CustomPainter using path.computeMetrics() — Flutter Border API does not support BorderStyle.dashed"
  - "_HomeScreenPlaceholder retained in router.dart as Wave 4 will replace it with real HomeScreen import"
metrics:
  duration: "~11 minutes"
  completed: "2026-06-03"
  tasks_completed: 2
  files_changed: 4
---

# Phase 4 Plan 03: WelcomeScreen + OnboardingScreen + AvailabilityScreen stub + router real imports Summary

**One-liner:** WelcomeScreen with cycling emoji + green CTA, OnboardingScreen with 4 preset tiles (selection feedback + seedPreset + SharedPreferences flag + go_router navigation), AvailabilityScreen stub, and router.dart updated to real imports (HomeScreen placeholder for Wave 4).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | WelcomeScreen + AvailabilityScreen stub | 7f18b68 | lib/features/welcome/welcome_screen.dart, lib/features/availability/availability_screen.dart |
| 2 | OnboardingScreen + router.dart real imports | 84dfe0a | lib/features/onboarding/onboarding_screen.dart, lib/app/router.dart |

## What Was Built

### Task 1: WelcomeScreen + AvailabilityScreen stub

**WelcomeScreen (`lib/features/welcome/welcome_screen.dart`):**
- `StatelessWidget` with `Scaffold(backgroundColor: Colors.white)`
- Centered column: 🚴 emoji (fontSize 80), title "Jouw perfecte rijmoment" (fontSize 28, w800), subtitle (fontSize 15, color #666, height 1.6)
- Green ElevatedButton "Aan de slag →" (backgroundColor #2E7D32, borderRadius 28, padding vertical 16)
- `onPressed: () => context.go('/onboard')` via go_router

**AvailabilityScreen (`lib/features/availability/availability_screen.dart`):**
- Stub `StatelessWidget` with `AppBar(title: Text('Mijn schema'))`
- Body: `Center(child: Text('Beschikbaarheidskalender komt in een volgende update.'))`

### Task 2: OnboardingScreen + router.dart real imports

**OnboardingScreen (`lib/features/onboarding/onboarding_screen.dart`):**
- `ConsumerStatefulWidget` with `AvailabilityPreset? _selected` local state
- Four preset options defined as `const List<_PresetOption>` (plain Dart class, not records)
  1. Avonden & weekenden — `eveningsAndWeekends`, solid border
  2. Ochtenden & weekenden — `morningsAndWeekends`, solid border
  3. Alleen weekenden — `weekendsOnly`, solid border
  4. Stel mijn eigen schema in — `custom`, dashed border via `_DashedBorderPainter`
- Visual selection: green border (#2E7D32) + green background (#E8F5E9) + green text + filled circle check
- Back button (`Icons.arrow_back_ios`) navigates to `/welcome` via `context.go`
- `_handleNext()`:
  - If `_selected == null`: noop (returns early)
  - If `_selected == AvailabilityPreset.custom`: `context.go('/availability')` (no seedPreset)
  - Otherwise: calculates `weekStart` (current week Monday), calls `buildPreset()`, `await ref.read(availabilityProvider.notifier).seedPreset(preset)`, writes `onboarding_complete=true` to SharedPreferences, `context.go('/home')`
- `_DashedBorderPainter`: CustomPainter using `path.computeMetrics()` to draw dashes along a rounded-rect path

**router.dart updates:**
- Removed `_WelcomeScreenStub`, `_OnboardingScreenStub`, `_AvailabilityScreenStub`
- Added real imports for `WelcomeScreen`, `OnboardingScreen`, `AvailabilityScreen`
- `_HomeScreenPlaceholder` retained (Wave 4 creates real HomeScreen)
- GoRoute builders updated to use real screen classes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Flutter Border API does not support BorderStyle.dashed**
- **Found during:** Task 2 implementation
- **Issue:** The plan's interface spec mentioned `BorderStyle.dashed` for the custom preset tile, but this is not a valid Flutter `BorderStyle` value (only `solid` and `none` exist)
- **Fix:** Implemented `_DashedBorderPainter extends CustomPainter` that draws dashes along a rounded-rect path using `path.computeMetrics()`. The container for the custom option omits the standard Border decoration and wraps in `CustomPaint` instead.
- **Files modified:** lib/features/onboarding/onboarding_screen.dart
- **Commit:** 84dfe0a (included in Task 2)

**2. [Rule 1 - Design] Dart 3 records used for preset data would add complexity**
- **Found during:** Task 2 implementation
- **Issue:** The plan suggested using Dart 3 records `(preset: ..., label: ..., sub: ..., isDashed: ...)` but acknowledged "kies de eenvoudigste compileerende variant"
- **Fix:** Used a private `const class _PresetOption` which is cleaner, has named fields, and avoids positional record access syntax
- **Files modified:** lib/features/onboarding/onboarding_screen.dart
- **Commit:** 84dfe0a (included in Task 2)

## Verification Results

```
dart analyze lib/ → No issues found
flutter test --reporter=compact → 106 tests all passed (no change from Plan 02)
grep -c "seedPreset" onboarding_screen.dart → 1
grep -c "onboarding_complete" onboarding_screen.dart → 2
grep -c "context.go" welcome_screen.dart → 2
grep -c "Mijn schema" availability_screen.dart → 2
```

## Success Criteria Verification

1. WelcomeScreen toont titel/sub/knop per mockup.html visuele contract; tapping navigeert naar /onboard — PASS
2. OnboardingScreen toont alle vier presets met selectie-feedback (groen geselecteerde rand + achtergrond) — PASS
3. Tapping een preset en dan "Volgende →": seedPreset + onboarding_complete=true + navigeer /home — PASS
4. Tapping "Set my own schedule" (custom): navigeer /availability (geen seedPreset) — PASS
5. AvailabilityScreen: Scaffold met AppBar("Mijn schema") aanwezig — PASS
6. router.dart gebruikt echte schermklassen (HomeScreen tijdelijk als _HomeScreenPlaceholder) — PASS
7. dart analyze lib/ No issues found — PASS
8. flutter test --reporter=compact slaagt volledig (106 tests) — PASS

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `_HomeScreenPlaceholder` | lib/app/router.dart | ~19 | Wave 4 (04-04) will replace with real HomeScreen import |
| AvailabilityScreen body text | lib/features/availability/availability_screen.dart | ~16 | Phase 6 will replace with full 7×24 calendar grid |

These stubs are intentional. The `_HomeScreenPlaceholder` is documented in router.dart with a `// TODO(wave-4)` comment. AvailabilityScreen stub correctly communicates "coming in a future update" to the user.

## Threat Model Applied

| Threat | Disposition | Applied |
|--------|-------------|---------|
| T-04-03-01 Spoofing via onboarding_complete SharedPreferences | accept | Boolean flag; maximum consequence is re-showing onboarding; no auth impact |
| T-04-03-02 DoS via seedPreset large map | accept | buildPreset generates max 7×24=168 entries; negligible |
| T-04-SC No new package installations | accept | go_router already added in Wave 2 |

## Self-Check: PASSED

Files verified:
- lib/features/welcome/welcome_screen.dart — FOUND
- lib/features/onboarding/onboarding_screen.dart — FOUND
- lib/features/availability/availability_screen.dart — FOUND
- lib/app/router.dart — FOUND (updated)

Commits verified:
- 7f18b68 — FOUND (feat(04-03): WelcomeScreen + AvailabilityScreen stub)
- 84dfe0a — FOUND (feat(04-03): OnboardingScreen + router with real screen imports)
