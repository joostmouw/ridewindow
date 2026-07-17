---
phase: 16-pwa-installability-ios-polish
plan: 03
subsystem: navigation
tags: [pwa, ios, standalone, go-router, back-button, safe-area-nav]

requires:
  - phase: 16-pwa-installability-ios-polish (Plan 01)
    provides: "Branded manifest.json/index.html (viewport-fit=cover, PWA installability meta) -- standalone-mode is only reachable once the app is installable"
provides:
  - "lib/core/safe_back_button.dart: SafeBackButton widget -- back-arrow+pop when Navigator.canPop(), else home-icon+GoRouter.go(fallbackRoute)"
  - "AvailabilityScreen (all 3 AppBar states), RideDetailScreen, and router.dart's invalid-DetailArgs error page all wired to SafeBackButton -- no more standalone-mode dead ends"
affects: [16-04]

tech-stack:
  added: []
  patterns:
    - "Navigation dead-end guard: use plain Navigator.of(context).canPop() (never the go_router context.canPop() extension) for the poppable check, so a widget builds identically with or without a GoRouter ancestor -- required because several existing widget tests wrap screens in bare MaterialApp(home: child) with no GoRouter at all"
    - "Null-safe custom-localization lookup (Localizations.of<S>(context, S) instead of S.of(context)!) when a widget must never throw in localization-delegate-less test harnesses, falling back to a plain literal or MaterialLocalizations (always present via MaterialApp's built-in English fallback)"

key-files:
  created:
    - lib/core/safe_back_button.dart
    - test/core/safe_back_button_test.dart
    - test/features/availability_no_dead_end_test.dart
  modified:
    - lib/app/router.dart
    - lib/features/availability/availability_screen.dart
    - lib/features/detail/ride_detail_screen.dart

key-decisions:
  - "Null-safe Localizations.of<S>(context, S) lookup (not S.of(context)!) for the non-poppable tooltip -- a literal reading of the plan's action text would throw inside the plain MaterialApp(home: ...) harness the plan's own acceptance criteria requires to never throw."

requirements-completed: [PWA-04]

duration: ~10min
completed: 2026-07-17
---

# Phase 16 Plan 03: Standalone-Mode Navigation Dead-End Fix (SafeBackButton) Summary

**One shared `SafeBackButton` widget (back-arrow+pop when `Navigator.canPop()`, else home-icon+`go('/home')`) closes a real, already-existing standalone-mode dead end on `AvailabilityScreen`'s onboarding-arrival path, plus two latent cold-launch gaps on `RideDetailScreen` and the invalid-`DetailArgs` error page.**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-07-17
- **Tasks:** 2/2
- **Files modified:** 6 (3 new, 3 modified)

## Accomplishments
- `SafeBackButton` (`lib/core/safe_back_button.dart`): computes `Navigator.of(context).canPop()` via the plain Flutter API (never the go_router extension), so it works identically whether or not a `GoRouter` ancestor is mounted -- required because existing widget tests (e.g. `ride_detail_screen_calendar_test.dart`) wrap screens in a bare `MaterialApp(home: child)` with no router at all.
- Wired into the 3 concrete dead-end spots: `AvailabilityScreen`'s 3 `AppBar`s (loading/error/data), `RideDetailScreen`'s `_buildAppBar`, and `router.dart`'s invalid-`DetailArgs` error `Scaffold` (which previously had zero navigation affordance whatsoever).
- New `test/features/availability_no_dead_end_test.dart` proves the concrete onboarding-arrival dead end end-to-end via a real `GoRouter` at `initialLocation: '/availability?from=onboarding'`: `canPop` is false → home icon shown (not a back arrow) → tap navigates to `/home`.
- Confirmed via before/after `git stash` comparison that this plan's changes introduce **zero new test failures** anywhere they touch -- both `test/features/availability_screen_test.dart` (11 failures) and `test/features/detail/ride_detail_screen_calendar_test.dart` (4 failures) have identical failure counts before and after this plan's edits; these are a pre-existing, already-documented test-suite health issue (BACKLOG.md #11), unrelated to this plan's scope.

## Task Commits

1. **Task 1 RED: failing tests for SafeBackButton** - `6b96db1` (test)
2. **Task 1 GREEN: SafeBackButton widget implementation** - `2764a6c` (feat)
3. **Task 2: wire SafeBackButton into the 3 dead-end spots + regression test** - `6920989` (feat)

_No REFACTOR commit needed -- implementation was minimal/clean on first pass._

## Files Created/Modified
- `lib/core/safe_back_button.dart` -- the `SafeBackButton` widget
- `lib/features/availability/availability_screen.dart` -- all 3 `leading: const BackButton()` occurrences replaced with `leading: const SafeBackButton()`
- `lib/features/detail/ride_detail_screen.dart` -- `_buildAppBar` gains explicit `leading: const SafeBackButton()` (previously relied on Flutter's implicit auto-back, which shows no icon at all when there is no history)
- `lib/app/router.dart` -- invalid-`DetailArgs` error `Scaffold` gains an `AppBar` with `SafeBackButton`
- `test/core/safe_back_button_test.dart` -- 3 widget tests covering the behavior matrix
- `test/features/availability_no_dead_end_test.dart` -- end-to-end regression test for the onboarding-arrival case via a real `GoRouter`

## Decisions Made
- Used a null-safe `Localizations.of<S>(context, S)` lookup instead of `S.of(context)!` (which would throw a null-check error) for the non-poppable-state tooltip, falling back to a plain `'Home'` literal when no `S` delegate is registered. This is necessary because the plan's own acceptance criteria require `SafeBackButton` to "never throw when built ... inside a plain `MaterialApp(home: ...)` with no `GoRouter` ancestor" -- and that harness (matching `ride_detail_screen_calendar_test.dart`'s pattern) has no localization delegates configured either. `MaterialLocalizations.of(context).backButtonTooltip` is used for the poppable-state tooltip since Flutter's `MaterialApp` always provides a default English fallback for it regardless of `localizationsDelegates`.
- The new `availability_no_dead_end_test.dart` explicitly sets `localizationsDelegates: S.localizationsDelegates`, `supportedLocales: S.supportedLocales`, and `theme: ThemeData(extensions: const [RideWindowTheme.light])` on its `MaterialApp.router` -- required because `AvailabilityScreen` itself (unlike `SafeBackButton`) does call `S.of(context)` and `context.rw` unconditionally, and would throw without them.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Guarded `S.of(context)` with a null-safe lookup to satisfy the plan's own "never throws" acceptance criteria**
- **Found during:** Task 1, while implementing `SafeBackButton` against the already-written RED tests
- **Issue:** The plan's `<action>` text specifies computing the non-poppable tooltip via `S.of(context).navHome`. A literal `S.of(context)` call (`Localizations.of<S>(context, S)!`) throws a null-check error when built inside a `MaterialApp(home: ...)` with no `S.delegate` registered -- exactly the harness the plan's own acceptance criteria requires `SafeBackButton` to survive ("never throws when built ... inside a plain `MaterialApp(home: ...)` with no `GoRouter` ancestor").
- **Fix:** Used `Localizations.of<S>(context, S)` (nullable) instead, falling back to a plain `'Home'` string literal when the delegate is absent. The poppable-state tooltip uses `MaterialLocalizations.of(context).backButtonTooltip`, which Flutter's `MaterialApp` always provides regardless of app-supplied `localizationsDelegates`.
- **Files modified:** `lib/core/safe_back_button.dart`
- **Verification:** All 3 tests in `test/core/safe_back_button_test.dart` pass, including the plain-`MaterialApp`-no-GoRouter regression guard (built and tapped, no exception).
- **Committed in:** `2764a6c` (Task 1 GREEN commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 -- correctness fix needed for the plan's own specified acceptance criteria to actually hold)
**Impact on plan:** No scope creep -- same file, same task boundary; the fix makes the implementation satisfy the plan's own stated contract.

## Issues Encountered
- Pre-existing, already-documented test-suite health issue (BACKLOG.md #11): `test/features/availability_screen_test.dart` (11 failures) and `test/features/detail/ride_detail_screen_calendar_test.dart` (4 failures) both fail on `context.rw` / `S.of(context)` null-check errors in widget-test harnesses that provide no `ThemeData` extension / localization delegates. Confirmed via `git stash` before/after comparison that these failure counts are **identical before and after this plan's changes** -- i.e. entirely pre-existing and out of this plan's scope per the Scope Boundary rule. Not fixed here.
- Did not run the full `flutter test` suite to completion -- it is dominated by the same pre-existing, already-tracked test-suite health issue (69+ failures observed partway through a full run, growing), making a full-suite pass/fail signal not meaningful for this plan's verification. Instead verified via targeted before/after diffs on every file this plan touches (see Accomplishments) that zero new failures were introduced.

## User Setup Required
None -- no external service configuration required.

## Next Phase Readiness
- PWA-04 is satisfied: `SafeBackButton` closes the one concrete existing gap (onboarding→Availability) and the two latent cold-launch gaps (Ride Detail, invalid-args error page).
- The remaining Phase 16 scope (real-iPhone manual verification pass, PWA-05) can proceed; `SafeBackButton`'s actual on-device tap behavior in standalone mode has not yet been visually verified on a physical iPhone.
- BACKLOG.md #11 (test-suite health) remains open and unrelated to this plan -- worth prioritizing separately given its growing scope (69+ failures across multiple feature test files).

---
*Phase: 16-pwa-installability-ios-polish*
*Completed: 2026-07-17*

## Self-Check: PASSED

All created/modified files verified present on disk. All 3 task commits (`6b96db1`, `2764a6c`, `6920989`) verified present in `git log`.
