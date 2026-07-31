---
phase: 20-repository-refactor-local-only
plan: 04
subsystem: infra
tags: [shared_preferences, workmanager, repository-pattern, background-isolate, REG-05]

# Dependency graph
requires:
  - phase: 20-repository-refactor-local-only
    provides: "Plan 20-01's AvailabilityRepository and 20-02's ProfileRepository — both plain-Dart, Riverpod-free, constructed via SharedPreferences — exactly what the WorkManager isolate needed"
provides:
  - "lib/platform/background_task.dart reads profile and availability data via the same ProfileRepository/AvailabilityRepository the rest of the app uses, instead of its own third mirrored copy of the keys"
  - "test/structure/background_task_no_supabase_test.dart — an automated, import-graph-following proof (not just an assertion) that the WorkManager isolate stays supabase-free (REG-05, D-14)"
affects: [21]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Import-graph-following structure test: starts from an entry file, follows package:ridewindow/ imports recursively via regex, then checks only lines starting with 'import' (not full file content) for a forbidden substring — avoids the doc-comment false-positive plan 20-02 hit"

key-files:
  created:
    - test/structure/background_task_no_supabase_test.dart
  modified:
    - lib/platform/background_task.dart

key-decisions:
  - "Task 2's test is a structural regression-slot, not a RED/GREEN TDD pair — the plan's own text notes the test would already pass before Task 1's change (there was never a direct supabase import in background_task.dart), so it was written and verified green directly rather than forced through an artificial failing-first cycle"

requirements-completed: [REG-05]

# Metrics
duration: ~20min
completed: 2026-07-31
---

# Phase 20 Plan 04: Background Task Repository Refactor Summary

**background_task.dart's WorkManager isolate now reads profile tolerances/durations/location and blocked hours via ProfileRepository/AvailabilityRepository instead of its own third mirrored copy of the SharedPreferences keys; a new import-graph test proves the isolate stays supabase-free.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-31T16:0x:xxZ
- **Completed:** 2026-07-31T16:26:25Z
- **Tasks:** 2
- **Files modified:** 2 (1 modified, 1 created)

## Accomplishments
- `lib/platform/background_task.dart` no longer owns `_kLocationOverrideKey`, `_kTempMin`, `_kTempMax`, `_kWindMax`, `_kRainMax`, `_kDurations`, or the literal `'availability.blockedHours'` string — the third and last place these keys were duplicated is now gone.
- `_runWeatherRefresh()` reads `locationOverride` via `ProfileRepository(prefs).readLocal().locationOverride`.
- `_computeNextSlot()` reads `tolerances`/`allowedDurations` via `ProfileRepository(prefs).readLocal()` and blocked hours via `AvailabilityRepository(prefs).readLocal()` (already-normalized, canonical-key map — the manual `canonicalHourKey()` parse loop is gone).
- `_kLastRefreshedKey` (`weather.lastRefreshed`) is untouched — it was never mirrored, it's this file's own sole key.
- New `test/structure/background_task_no_supabase_test.dart` builds the import graph from `lib/platform/background_task.dart`, follows every `package:ridewindow/` import recursively, and asserts none of the reachable files' `import` lines contain the substring `supabase` — an automated, structural proof for REG-05/D-14, not a one-off assertion.

## Task Commits

Each task was committed atomically:

1. **Task 1: Vervang de gespiegelde sleutels in background_task.dart door ProfileRepository/AvailabilityRepository** - `e5fe9f7` (refactor)
2. **Task 2: Automatiseerbaar bewijs dat de importgraaf van background_task.dart supabase-vrij is (D-14)** - `43fbc5a` (test)

_No plan-metadata commit — per worktree isolation rules, STATE.md/ROADMAP.md updates are owned by the orchestrator after merge._

## Files Created/Modified
- `lib/platform/background_task.dart` - Removed 5 mirrored key constants + the manual blockedHours parse loop; imports and calls `ProfileRepository(prefs)`/`AvailabilityRepository(prefs)` instead; removed the now-unused `availability_key.dart` (canonicalHourKey) and `providers/availability_notifier.dart` (BlockType) imports
- `test/structure/background_task_no_supabase_test.dart` - Import-graph-following structure test; single `test()` block named for REG-05/D-14; checks only `import`-prefixed lines, not full file content

## Decisions Made
See `key-decisions` in frontmatter. The consequential one: Task 2's test was written and run directly to a green state rather than forced through a RED phase, because the plan's own `<action>` text explicitly documents that the assertion already held true before Task 1's change (no direct supabase import ever existed in this file) — the test is a structural regression-slot for future changes, analogous in spirit to the pre-existing `no_flutter_imports_test.dart`.

## Deviations from Plan

None — plan executed exactly as written for both tasks and their acceptance criteria. All grep-based acceptance criteria (zero mirrored-key matches, `_kLastRefreshedKey` retained, `ProfileRepository(prefs)`/`AvailabilityRepository(prefs)` present, no `providers/`/`availability_key.dart` imports, `REG-05`/`D-14` present in the test) passed on first attempt.

## Issues Encountered

None specific to this plan's changes. `flutter test` (full suite, no path filter) reports 307 passed / 8 failed — the 8 failures are the pre-authorized, pre-existing gap called out explicitly in this plan's orchestrator instructions: 7 UI-layer test files broken by plan 20-03's `PlannedRidesNotifier` async conversion (deferred to plan 20-05, not this plan's concern) plus the documented date-boundary bug in `notification_service_test.dart` (today, 2026-07-31, is the last calendar day of the month). Verified independently that this plan's own files are unaffected: `flutter test test/structure/ test/data/` (36 tests, includes the new test and all pre-existing repository tests from 20-01/20-02/20-03) passes 36/36 clean, and `flutter analyze` reports zero issues in `lib/platform/background_task.dart` or anywhere under `test/structure/` — all 193 analyzer issues found project-wide are in the same pre-existing `test/features/` files affected by the 20-03→20-05 gap.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All three domains (availability, profile, planned rides via 20-01/20-02/20-03) and now the WorkManager background isolate (20-04) read/write through repositories instead of duplicated SharedPreferences key constants. `background_task.dart`'s import graph is now structurally proven supabase-free (REG-05/D-14) via an automated test, not just a manual claim — this closes the last of the three key-mirroring sites the phase set out to eliminate. Phase 21 (sync + migration) can now safely assume there is exactly one place each domain's local keys are read/written from, with no isolate-side copy to keep in sync separately.

---
*Phase: 20-repository-refactor-local-only*
*Completed: 2026-07-31*
