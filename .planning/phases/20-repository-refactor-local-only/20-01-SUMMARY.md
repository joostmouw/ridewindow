---
phase: 20-repository-refactor-local-only
plan: 01
subsystem: database
tags: [shared_preferences, riverpod, repository-pattern, availability]

# Dependency graph
requires:
  - phase: 04-availability-calendar
    provides: AvailabilityNotifier with SharedPreferences persistence, canonicalHourKey/normalizeBlockedHours in availability_key.dart
provides:
  - AvailabilityRepository (lib/data/repositories/availability_repository.dart) — the sole owner of the `availability.blockedHours` and `availability.updatedAt` SharedPreferences keys
  - BlockType enum relocated to plain-Dart lib/domain/models/block_type.dart, re-exported from availability_notifier.dart
  - The repository pattern shape (constructor-injected SharedPreferences, public key constants, `save(..., {bool stamp = true})`) that plans 20-02 and 20-03 will replicate for profile and calendar domains
affects: [20-02, 20-03, 20-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Repository pattern: plain-Dart class takes SharedPreferences via constructor, exposes public static const key constants, no Riverpod/Flutter imports"
    - "updatedAt stamping: epoch-ms int written in the same save() call as the data, via an optional `stamp` bool parameter — mirrors weather.lastRefreshed in WeatherRepository"
    - "Backward-compatible enum relocation via `export` — moves a type to plain-Dart ground without touching any of its 24 existing import sites"

key-files:
  created:
    - lib/domain/models/block_type.dart
    - lib/data/repositories/availability_repository.dart
    - test/data/repositories/availability_repository_test.dart
  modified:
    - lib/providers/availability_notifier.dart
    - lib/providers/availability_notifier.g.dart

key-decisions:
  - "BlockType enum moved to lib/domain/models/block_type.dart with a re-export from availability_notifier.dart — avoids touching 24 existing import sites across lib/ and test/"
  - "availabilityRepositoryProvider constructs its repository via SharedPreferences.getInstance() (async), not the app's sharedPrefsProvider — sharedPrefsProvider throws UnimplementedError unless overridden, and every existing availability test relies on SharedPreferences.setMockInitialValues + getInstance()"
  - "AvailabilityRepository.save() takes an optional `stamp` bool (default true) so plan 20-02 can reuse the same shape for D-07 without availability needing a caller that ever sets it false today"
  - "readUpdatedAt() returns null when the field has never been written — no retroactive 'now' stamping (D-08); nothing in this phase reads the value to decide anything, it exists for phase 21"

requirements-completed: []

# Metrics
duration: ~35min
completed: 2026-07-31
---

# Phase 20 Plan 01: Availability Repository Refactor Summary

**AvailabilityRepository now owns `availability.blockedHours` + `availability.updatedAt` as plain Dart; AvailabilityNotifier is a thin Riverpod layer over it with an unchanged public API.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-07-31T14:xx:xxZ
- **Completed:** 2026-07-31T15:02:43Z
- **Tasks:** 4
- **Files modified:** 5 (2 created domain/repo files, 1 modified notifier + its generated file, 1 created test file) — plus 1 deferred-items.md note

## Accomplishments
- `BlockType` lives in plain-Dart `lib/domain/models/block_type.dart`; all 24 existing import sites across `lib/` and `test/` remain untouched thanks to a re-export from `availability_notifier.dart`.
- `AvailabilityRepository` is the single source of truth for the `availability.blockedHours` storage format (unchanged byte-for-byte) and additively owns the new `availability.updatedAt` epoch-ms stamp.
- `AvailabilityNotifier` is now a thin layer: `build()` and all five mutators (`toggleCustomHour`, `setCustomHours`, `seedPreset`, `importCalendarBlocks`, `clearAll`) talk to the repository instead of doing SharedPreferences I/O directly, with unchanged signatures and logic.
- New `test/data/repositories/availability_repository_test.dart` covers exactly the risk the wider suite doesn't: reading pre-existing on-disk data (mixed UTC/local keys, corrupt entries) and the exact write format.

## Task Commits

Each task was committed atomically:

1. **Task 1: Verhuis BlockType naar lib/domain/models/ met een re-export** - `8569d0b` (refactor)
2. **Task 2: Schrijf AvailabilityRepository als plain Dart** - `8824057` (feat)
3. **Task 3: Sla AvailabilityNotifier af tot een dunne laag over de repository** - `ed81177` (refactor)
4. **Task 4: Unit-tests voor AvailabilityRepository, inclusief het bestaande-data-pad** - `09625cf` (test)

_No plan-metadata commit — per worktree isolation rules, STATE.md/ROADMAP.md updates are owned by the orchestrator after merge._

## Files Created/Modified
- `lib/domain/models/block_type.dart` - New plain-Dart home for `enum BlockType { work, custom, calendar }`, zero imports
- `lib/data/repositories/availability_repository.dart` - `readLocal()`, `save(hours, {stamp})`, `readUpdatedAt()`; owns `kBlockedHoursKey`/`kUpdatedAtKey`
- `lib/providers/availability_notifier.dart` - Re-exports `BlockType`; new `availabilityRepositoryProvider`; `build()` and all 5 mutators now delegate to the repository; `_persist()` and the local `_key` constant removed
- `lib/providers/availability_notifier.g.dart` - Regenerated via `dart run build_runner build` to add `availabilityRepositoryProvider`
- `test/data/repositories/availability_repository_test.dart` - 7 `test()` blocks: existing-format read (UTC+local, normalized), corrupt-entry skip, exact write format, `save()` stamps `updatedAt`, `save(stamp: false)` does not stamp, `readUpdatedAt()` null on missing field

## Decisions Made
See `key-decisions` in frontmatter. Most consequential: the re-export pattern for `BlockType` and the `getInstance()`-not-`sharedPrefsProvider` choice for the new repository provider — both were called out explicitly in the plan's `<interfaces>` section and followed as specified.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written for all four tasks and their acceptance criteria.

### Out-of-scope discovery (logged, not fixed)

**1. Pre-existing date-boundary bug in `test/platform/notification_service_test.dart`**
- **Found during:** Task 4 full-suite verification (`flutter test`)
- **Issue:** `scheduleEveningBefore tijdberekening: 19:00 de dag voor slotDay` fails with a month mismatch whenever the suite runs on the last calendar day of a month (today, 2026-07-31, is such a day). Root cause is `slotDay.day - 1` raw-integer arithmetic instead of proper `DateTime` subtraction — rolls to `0` when `slotDay` is the 1st of a month.
- **Scope:** File is not in this plan's `files_modified` list and was not touched by any of the 4 tasks (all scoped to `lib/domain/models/`, `lib/data/repositories/availability_repository.dart`, `lib/providers/availability_notifier.dart`). Confirmed pre-existing and date-triggered, not a regression from this plan.
- **Action:** Logged to `.planning/phases/20-repository-refactor-local-only/deferred-items.md` per the executor's scope-boundary rule. Not fixed.

---

**Total deviations:** 0 auto-fixed. 1 out-of-scope issue logged, not fixed.
**Impact on plan:** None on this plan's own correctness. `flutter test` full suite: **329 passed / 1 failed** — the plan's floor of "at least 317 passed" (D-12) is met; the single failure is the unrelated pre-existing bug above, not "0 failed" as the plan's verification section states literally. Documented here rather than silently accepted.

## Issues Encountered

`dart run build_runner build --delete-conflicting-outputs` regenerated stale `.g.dart` doc-comment/hash drift in three unrelated files (`auth_notifier.g.dart`, `planned_rides_notifier.g.dart`, `profile_notifier.g.dart`) that were out of sync with their `.dart` sources from before this plan started. Reverted those three files with `git checkout --` to keep this plan's diff scoped to the availability domain; re-verified `flutter analyze` and the availability test suite still passed after the revert. Not fixed as part of this plan (out of scope) — a future task should re-run `build_runner build` project-wide to catch up all stale generated files at once.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The repository-pattern shape established here (constructor-injected `SharedPreferences`, public key constants, `save(..., {bool stamp = true})`, `readUpdatedAt()` never retroactively stamping) is ready for plan 20-02 to replicate against the profile domain's twelve keys and eight mutators, and for plan 20-03 against the calendar domain. Plan 20-04 can now assert on the import graph that `AvailabilityRepository` has zero Riverpod/Flutter dependencies. `lib/platform/background_task.dart` still references the raw `'availability.blockedHours'` string literal directly — that cleanup is explicitly plan 20-04's job, left untouched here per the plan's own verification section.

---
*Phase: 20-repository-refactor-local-only*
*Completed: 2026-07-31*

## Self-Check: PASSED

All created files verified present on disk: `lib/domain/models/block_type.dart`,
`lib/data/repositories/availability_repository.dart`,
`test/data/repositories/availability_repository_test.dart`,
`.planning/phases/20-repository-refactor-local-only/20-01-SUMMARY.md`,
`.planning/phases/20-repository-refactor-local-only/deferred-items.md`.
All 5 commits verified present in `git log`: `8569d0b`, `8824057`, `ed81177`, `09625cf`, `942fc26`.
