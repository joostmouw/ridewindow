---
phase: 21-sync-migration
plan: 12
subsystem: sync
tags: [outbox, supabase, postgrest, drift, availability, logging, retry-ceiling]

# Dependency graph
requires:
  - phase: 21-sync-migration
    provides: cloudSyncReconciler/syncOutboxService as @Riverpod(keepAlive: true) (21-11), SyncOutboxService.drain() wired to both foreground and post-sign-in triggers (21-10)
provides:
  - AvailabilityRepository's two outbox enqueue sites (save(), enqueueCurrentState()) now produce a real public.availability row ({user_id, recurring}) instead of the bare toRecurringRow(hours) map — the actual fix for "account row stuck on Syncing... forever"
  - test/data/database/outbox_payload_shape_test.dart — a table-driven invariant that all three synced entities' enqueue paths produce legal Postgres rows, guarding against a fourth instance of this defect class
  - SyncOutboxService.kMaxSendAttempts (5) + debugPrint on every failed send — a wedged/permanently-broken row is now audible in logcat and self-clears within a handful of foreground cycles instead of retrying silently forever
affects: [22-account-feedback]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Payload-shape invariant testing: drive the real repository's enqueue path (not a hand-built payload) and assert the resulting outbox row's keys are a subset of hand-maintained column-name literals copied from the SQL migration file, with a comment pointing at the source of truth — catches 'a client payload key isn't actually a column name' at the unit-test level instead of at PostgREST's request-time rejection."
    - "Bounded non-backoff attempt ceiling: increment attempts on every failure as before (21-10 behaviour), but once attempts crosses a small constant, hard-delete the row instead of leaving it pending — no new schema/column needed, since pendingRows()/watchPendingCount() are already unfiltered selects over the table and a deleted row is invisible to both for free."
    - "Capturing debugPrint in tests via temporary reassignment of the global debugPrint function (flutter/foundation.dart), same pattern as 21-11's outbox_drain_wiring_test.dart — used here to assert both 'exactly one log per failure' and 'zero logs on an all-success drain'."

key-files:
  created:
    - test/data/database/outbox_payload_shape_test.dart
  modified:
    - lib/data/repositories/availability_repository.dart
    - lib/services/sync_outbox_service.dart
    - lib/data/database/daos/sync_outbox_dao.dart
    - test/data/repositories/availability_repository_test.dart
    - test/services/sync_outbox_service_test.dart
    - .planning/phases/21-sync-migration/REGRESSION-CHECKLIST-21.md

key-decisions:
  - "kMaxSendAttempts = 5, chosen because drain() runs on every foreground cycle (CloudSyncReconciler.reconcileOnForeground()) and right after sign-in — 5 strikes means a wedged device visibly recovers within a handful of app-switches, while still tolerating a couple of genuinely transient failures (e.g. two bad network blips in a row) without mistaking them for a permanently-broken payload. No connectivity-awareness or backoff schedule was added; REQUIREMENTS.md puts that out of scope for this phase (restated in 21-10/21-11), and this constant is documented in-code as deliberately not that."
  - "Dropping a row past the ceiling is a hard delete (SyncOutboxDao.dropRow(), same underlying delete() as markSent()), not a new 'dropped' flag/column. This means pendingRows() and watchPendingCount() — both pre-existing unfiltered selects — automatically stop counting a dropped row with zero additional filtering logic, and no Drift schema migration was needed."
  - "The payload-shape test drives each repository's real enqueue path (ProfileRepository.save(), AvailabilityRepository.save(), PlannedRidesRepository.add()) rather than calling toRow()/toRecurringRow() directly — this is what actually caught the defect class the plan describes: the bug was in the caller (which map got wrapped and enqueued), not in the row-building helpers themselves (toRecurringRow() was always correct)."

requirements-completed: [SYNC-02, SYNC-05, SYNC-06]

# Metrics
duration: ~50min
completed: 2026-08-04
---

# Phase 21 Plan 12: Fix the availability outbox payload shape and outbox silence Summary

**`AvailabilityRepository`'s two outbox enqueue sites now wrap availability changes as a real `public.availability` row (`{user_id, recurring}`) instead of the bare weekday-hour map PostgREST was rejecting as invalid column names, `SyncOutboxService` now logs every failed send instead of swallowing it silently, and a row that fails 5 times in a row is dropped so a wedged device recovers within a few foregrounds instead of never.**

## Performance

- **Duration:** ~50 min
- **Completed:** 2026-08-04
- **Tasks:** 3 completed
- **Files modified:** 6 (1 created, 5 modified)

## Accomplishments

- **Task 1 — RED test, confirmed failing only on availability.** Wrote `test/data/database/outbox_payload_shape_test.dart`, a table-driven test that drives each of `ProfileRepository`, `AvailabilityRepository`, and `PlannedRidesRepository`'s real `save()`/`add()` enqueue path and asserts the resulting outbox payload's keys are a subset of that entity's real Postgres columns (hand-copied literals from `supabase/migrations/0001_accounts_sync.sql`, not parsed at runtime) and always carries `user_id`. Ran it against the pre-fix code: 2/3 passed (profile, planned_rides), availability failed with `Expected: true, Actual: <false>` and reason `availability payload must carry user_id, got keys: (1-9, 2-17)` — the literal defect from the plan's `<objective>`, reproduced.
- **Task 2 — wrapped the payload at both enqueue sites.** `AvailabilityRepository.save()` and `.enqueueCurrentState()` now enqueue `{'user_id': userId, 'recurring': toRecurringRow(hours)}` instead of the bare `toRecurringRow(hours)` map. `entityKey` (still `userId`) and `toRecurringRow()` itself were left untouched, per the plan's explicit instruction — the migration RPC shares the same helper and was already correct. Updated the pre-existing `availability_repository_test.dart:152` assertion, which previously asserted the buggy bare-map shape; left a comment explaining why it changed so a future reader doesn't "restore" it. All 3 payload-shape cases now pass (12 assertions total across the file).
- **Task 3 — made failures audible and bounded retry.** `SyncOutboxService._drainInternal`'s catch block now `debugPrint`s one message per failed send naming the entity, entity key, attempt number, and error — previously `markFailed()` wrote the error into a database column with zero logcat trace, which is why three prior plans' worth of drain defects went unnoticed on-device. Added `SyncOutboxService.kMaxSendAttempts = 5`: once a row's attempt count reaches 5, `SyncOutboxDao.dropRow()` hard-deletes it (same underlying delete as `markSent()`) and a second, loud `debugPrint` records why it was dropped and with what last error — the row itself is gone, so this log line is the only surviving record. Because dropping is a real delete rather than a filtered-out flag, `pendingRows()`/`watchPendingCount()` (both pre-existing unfiltered selects) automatically stop counting a dropped row with no additional filtering logic and no schema migration.

## Task Commits

Each task was committed atomically (TDD RED then GREEN, then a second GREEN task):

1. **Task 1: Payload-shape invariant test, failing on availability** - `502c5ec` (test)
2. **Task 2: Enqueue availability as a real row** - `9bd15fa` (feat)
3. **Task 3: Make a failed send audible, and stop retrying the unsendable forever** - `203eac5` (feat)

_TDD note: Task 1 is a strict RED→GREEN pair with Task 2 (Task 1's test was committed and independently verified failing before Task 2's fix landed — see "RED evidence" below). Task 3 is its own TDD unit: its 5 new tests were written and run against the new logging/ceiling code together, since the behaviour under test (logging + drop) didn't exist at all beforehand to produce a meaningful separate RED commit._

## RED evidence (Task 1, before Task 2's fix)

Ran `flutter test test/data/database/outbox_payload_shape_test.dart` against the code as of `502c5ec` (before `9bd15fa`). 2 of 3 tests passed; the availability case failed:

```
availability: enqueued payload is a legal public.availability row (FAILS today — the payload is the bare recurring map, not a row) [E]
  Expected: true
    Actual: <false>
  availability payload must carry user_id, got keys: (1-9, 2-17)
```

(`1-9`, `2-17` are the two weekday-hour keys the test's own fixture data produced — exactly the shape PostgREST would have received as column names.) After `9bd15fa` (Task 2's fix), all three pass; full file: 3/3.

## Files Created/Modified

- `test/data/database/outbox_payload_shape_test.dart` (created) — table-driven invariant test over the three synced entities; hand-maintained column-name literals sourced from `supabase/migrations/0001_accounts_sync.sql`'s create-table blocks
- `lib/data/repositories/availability_repository.dart` — both `save()` and `enqueueCurrentState()` now wrap the enqueued payload as `{'user_id': userId, 'recurring': toRecurringRow(hours)}`; class doc comment updated to explain the fixed shape and point at the new invariant test
- `test/data/repositories/availability_repository_test.dart` — updated the pre-existing assertion at (formerly) line 152 to expect the wrapped row shape, with a comment recording that the previous assertion encoded the defect
- `lib/services/sync_outbox_service.dart` — added `kMaxSendAttempts = 5` (documented as deliberately not a backoff schedule), a `debugPrint` on every failed send, and a second `debugPrint` + `dropRow()` call when a row crosses the ceiling
- `lib/data/database/daos/sync_outbox_dao.dart` — added `dropRow(int id)`, a hard delete distinct from `markSent()`/`markFailed()` only in intent/naming
- `test/services/sync_outbox_service_test.dart` — added a `failure logging + attempt ceiling (Task 3, plan 21-12)` group with 5 new tests (failure logs exactly once, success logs nothing, ceiling drops + logs, a row below the ceiling still behaves per 21-10, `watchPendingCount` reaches 0 after a drop); also fixed one pre-existing trailing-comma lint in the same file to satisfy this plan's "flutter analyze clean on touched files" criterion
- `.planning/phases/21-sync-migration/REGRESSION-CHECKLIST-21.md` — §5a heading now credits plan 21-12; added an availability-specific device-verification bullet (change an hour, confirm `public.availability.recurring` updates) and a wedged-row-clears bullet describing the expected drop/replace behaviour if the pre-existing broken row from the 2026-08-04 session doesn't clear within a few foreground cycles

## Decisions Made

- **Attempt ceiling = 5.** Chosen because `drain()` runs on every foreground cycle and right after sign-in — a small number means a wedged device recovers visibly within a handful of app-switches, not "forever" (the actual defect this plan fixes), while still being high enough to not mistake two genuinely transient network blips for a permanently-broken payload. Documented in-code with an explicit "this is not a backoff schedule" comment per the plan's instruction, since REQUIREMENTS.md puts scheduled/backoff retry out of scope for this phase.
- **Hard delete over a new "dropped" column.** A new boolean column would have required a Drift schema migration and a filter added to both `pendingRows()` and `watchPendingCount()`. Reusing the existing delete path (as a distinctly-named `dropRow()`, for log/intent clarity) gets the same "not counted, not retried" outcome for free, since both selects were already unfiltered over the whole table.
- **Task 1's test drives the real repository methods, not the row-building helpers directly.** `toRow()`/`toRecurringRow()` were never wrong — the defect was entirely in which map each repository's `save()`/`add()` call actually enqueued. A test that called `toRecurringRow()` and asserted properties about its own output would have proven nothing about the bug; driving `AvailabilityRepository.save()` end-to-end through a real `SyncOutboxDao` is what reproduced the failure.
- **Left `toRecurringRow()`, `entityKey` (still `userId`), and `profiles`/`planned_rides`' already-correct `toRow()` calls untouched**, exactly as the plan instructed — confirmed via the Task 1 test that both were already legal before this plan and remain legal after.

## Deviations from Plan

**1. [Rule 3 - blocking, minor] Fixed a pre-existing trailing-comma lint in `test/services/sync_outbox_service_test.dart`.** The plan's own acceptance criteria require `flutter analyze` clean on all touched files. `flutter analyze` on the touched file surfaced one pre-existing `require_trailing_commas` info-level lint at what was then line 62 (inside the file's first, untouched test, predating this plan). Since the file is touched by this plan and the criterion is explicit, reformatted that one `expect(...)` call to add the trailing comma. No behavioural change; verified via `git diff` that the only lines touched were formatting.

No other deviations — plan executed exactly as written, including the explicit "do not touch `toRecurringRow()`/`entityKey`" and "do not add a backoff schedule" constraints.

## Issues Encountered

None. Both TDD cycles (Task 1→2 RED/GREEN, Task 3's logging+ceiling tests) passed on the first implementation attempt; no debugging iterations were needed.

## User Setup Required

None — no external service configuration required. Device verification (the newly added §5a bullets in `REGRESSION-CHECKLIST-21.md`) is a manual step for the user, not performed by this executor. In particular: confirming the pre-existing wedged availability row from the 2026-08-04 device session actually clears (either by a fresh correctly-shaped write superseding it via coalescing, or by the attempt-ceiling drop) is real-device work this plan cannot verify itself.

## Next Phase Readiness

- SYNC-02/SYNC-05/SYNC-06 are now genuinely complete end-to-end in code for all three synced entities: the drain trigger (21-10), the provider lifetime that lets it run (21-11), and — this plan — a payload shape that PostgREST can actually accept, plus visible failure logging and a bounded ceiling so a broken payload cannot wedge a device silently forever.
- `flutter test` full suite: 431 passed / 0 failed (up from 21-11's 423 baseline: +3 payload-shape tests, +5 failure/ceiling tests). `flutter analyze`: 0 issues on every file touched by this plan (161 pre-existing info-level lints remain elsewhere in the repo, all outside this plan's `files_modified` list and outside its scope boundary).
- The known pre-existing flake (`test/services/notification_service_test.dart`, fails after 19:00 UTC) did not trigger during this session's test runs (run before 19:00 UTC) — not exercised, not fixed, not a regression, consistent with the executor prompt's note.
- Remaining device verification (`REGRESSION-CHECKLIST-21.md` §5a's now-updated availability-specific bullets, plus the rest of the checklist) is still outstanding and must be run on a real device before Phase 21 is considered fully closed. This is the fourth plan in a row where the code fix and the device proof are separate steps — the checklist bullets added here are written so that proof is unambiguous (dashboard row content check, plus an explicit fallback interpretation if the pre-existing wedged row needs a drop-and-replace cycle rather than clearing on the very next foreground).
- No new Postgres schema, RLS, grant, or endpoint changes — this plan is a pure Dart-side payload-shape and outbox-service fix. `supabase/migrations/0001_accounts_sync.sql` was read as the source of truth but not modified.

## Threat Flags

None. No new network endpoint, auth path, file access pattern, or schema surface. The `debugPrint` calls added to `SyncOutboxService` include entity name, entity key (a `userId`, or `userId:rideId` for planned rides), attempt count, and the caught exception's `.toString()` — no payload contents (weather tolerances, availability hours, ride times) are logged, only the entity/key/error already visible in the pre-existing `lastError` database column this plan makes audible via logcat.

## Self-Check: PASSED

Verified all 6 referenced files exist on disk and all 3 commit hashes (`502c5ec`, `9bd15fa`, `203eac5`) are present in `git log --oneline`. No missing items.

---
*Phase: 21-sync-migration*
*Completed: 2026-08-04*
