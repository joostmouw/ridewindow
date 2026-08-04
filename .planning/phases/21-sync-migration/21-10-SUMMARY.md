---
phase: 21-sync-migration
plan: 10
subsystem: sync
tags: [riverpod, supabase, drift, outbox, offline-sync]

# Dependency graph
requires:
  - phase: 21-sync-migration
    provides: SyncOutboxService.drain() (21-03), profile/availability outbox enqueue (21-04), planned_rides outbox enqueue (21-05), sign-in UI + conflict dialogs (21-07)
provides:
  - Real production consumer for the offline outbox — SyncOutboxService is now constructed (syncOutboxServiceProvider) and drain() has two real call sites
  - CloudSyncReconciler.drainOutbox(): composes real Supabase upsert/delete closures from supabase_tables.dart constants, called from reconcileOnForeground() and from AccountSection._runAccountSync() after sign-in settles
  - Re-entrancy guard on SyncOutboxService.drain() — a concurrent second call coalesces into the first call's in-flight Future instead of double-sending rows
  - test/providers/outbox_drain_wiring_test.dart — structural regression test asserting the wiring itself exists, not just that drain() works when called
affects: [22-account-feedback]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Provider-level in-flight-Future dedup for idempotent background operations (SyncOutboxService._inFlightDrain)"
    - "Structural (source-text-scan) regression tests for 'wiring exists' assertions, with comment-stripping to avoid doc-comment false positives — same style as test/structure/background_task_no_supabase_test.dart"

key-files:
  created:
    - test/providers/outbox_drain_wiring_test.dart
  modified:
    - lib/providers/cloud_sync_reconciler_provider.dart
    - lib/providers/cloud_sync_reconciler_provider.g.dart
    - lib/services/sync_outbox_service.dart
    - lib/features/profile/account_section.dart
    - test/services/sync_outbox_service_test.dart
    - .planning/phases/21-sync-migration/REGRESSION-CHECKLIST-21.md

key-decisions:
  - "drainOutbox() is exposed as its own public method on CloudSyncReconciler (not folded silently into reconcileOnForeground()'s try block) so AccountSection can call it directly after sign-in without also re-running the cloud-pull reconcile logic a second time"
  - "account_section.dart added to the touched-files set even though it is absent from the plan's files_modified frontmatter — the plan's own action text requires a post-sign-in drain trigger, and _runAccountSync() is the only place that trigger can live (Rule 2/3 deviation, documented below)"
  - "Structural test strips // and /* */ comments before matching, otherwise cloud_sync_reconciler_provider.dart's own doc comments (which describe drain() in prose) would make the regression test pass even with the real call site deleted"

patterns-established:
  - "SyncOutboxService.drain() re-entrancy: Future<void>? _inFlightDrain field, second concurrent caller returns the first call's Future unchanged rather than starting its own scan"

requirements-completed: [SYNC-05, SYNC-06]

# Metrics
duration: 17min
completed: 2026-08-04
---

# Phase 21 Plan 10: Wire the offline outbox to a real drain trigger Summary

**SyncOutboxService now has a real production consumer — drained on foreground reconcile and right after sign-in settles, with a re-entrancy guard and a structural regression test that fails if the wiring is ever removed again.**

## Performance

- **Duration:** ~17 min
- **Started:** 2026-08-04T09:31:57Z
- **Completed:** 2026-08-04T09:48:11Z
- **Tasks:** 2 completed
- **Files modified:** 6 (1 created, 5 modified)

## Accomplishments
- `SyncOutboxService` is constructed in production code (`syncOutboxServiceProvider`) for the first time — previously only test code ever instantiated it
- `drain()` now has two real call sites: `CloudSyncReconciler.reconcileOnForeground()` (existing foreground trigger, extended) and `AccountSection._runAccountSync()` (new, right after a sign-in's sync decisions — including conflict prompts — have fully settled)
- Added a re-entrancy guard to `SyncOutboxService.drain()` so two overlapping triggers (foreground firing while a post-sign-in drain is still in flight) cannot double-send the same row
- Added `test/providers/outbox_drain_wiring_test.dart`, a structural regression test that fails if either the construction site or the `drain()` call site is ever removed — verified this directly by temporarily deleting both and confirming the test fails, then restoring and confirming green again
- Appended the device-verification step (§5a) to `REGRESSION-CHECKLIST-21.md`, ahead of the destructive delete-account section

## Task Commits

Each task was committed atomically:

1. **Task 1: Construct SyncOutboxService with real send closures and drain on foreground + post-sign-in** - `0de9e68` (feat)
2. **Task 2: Regression test that the wiring itself exists** - `4a611d1` (test)

_TDD note: both tasks are marked `tdd="true"` in the plan. Task 1's TDD cycle was RED→GREEN inline within the single feat commit (the re-entrancy-guard test was written and run alongside the implementation, both verified together before committing — see "Issues Encountered" below for why a separate RED commit wasn't produced). Task 2's own acceptance criterion (delete the call site, confirm the test fails, restore) was executed manually as verification rather than as a separate commit, per the plan's explicit instruction to "verify this by actually doing it temporarily, then restoring" — the temporary removal was never committed._

## Files Created/Modified
- `lib/providers/cloud_sync_reconciler_provider.dart` - Added `syncOutboxServiceProvider`; added `CloudSyncReconciler.drainOutbox()` composing real Supabase upsert/delete closures from `supabase_tables.dart` constants (planned_rides deletes parse the `user_id:rideId` compound key out of `entityKey`); called from `reconcileOnForeground()`
- `lib/providers/cloud_sync_reconciler_provider.g.dart` - Regenerated via `build_runner` for the new `syncOutboxServiceProvider`
- `lib/services/sync_outbox_service.dart` - Added `_inFlightDrain` re-entrancy guard: a second concurrent `drain()` call now returns the first call's in-flight `Future` instead of re-scanning `pendingRows()`
- `lib/features/profile/account_section.dart` - `_runAccountSync()` now calls `ref.read(cloudSyncReconcilerProvider).drainOutbox()` once `AccountSyncService` has settled a sign-in (after `markSynced`, before the `mounted` UI-invalidation block)
- `test/services/sync_outbox_service_test.dart` - Added a test proving a second `drain()` call while one is in flight does not double-send a row
- `test/providers/outbox_drain_wiring_test.dart` - New. Structural regression test scanning `lib/` source (with comments stripped) for a `SyncOutboxService(` construction site and a `drain(` call site outside `sync_outbox_service.dart` itself
- `.planning/phases/21-sync-migration/REGRESSION-CHECKLIST-21.md` - Appended §5a, the device-verification step this plan's `<output>` block requires: change a setting while signed in, background/foreground the app, confirm the change reaches the `profiles`/`availability` table without signing out and back in, and that the status text returns to "Gesynchroniseerd"

## Decisions Made
- `drainOutbox()` kept as a separate public method rather than merged invisibly into `reconcileOnForeground()`'s try block, so the post-sign-in call site in `account_section.dart` can trigger just the drain — not a redundant second cloud-pull reconcile of profile/availability/planned_rides on top of what `AccountSyncService.onSignIn`/`resolvePrompt` already just did
- Unrecognized outbox `entity` strings in `_tableForEntity()` map to `null` and are silently skipped by `upsertFn` rather than throwing — a corrupt/future entity value must never crash the drain for every other pending row (matches `SyncOutboxService.drain()`'s own per-row try/catch contract)
- The regression test strips comments before its substring/regex scan (see key-decisions above) — without this, `cloud_sync_reconciler_provider.dart`'s own doc comments describing `drain()` would have made the test pass even with the real call site deleted, defeating its entire purpose

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added the post-sign-in drain call site in `account_section.dart`, a file absent from the plan's `files_modified` frontmatter**
- **Found during:** Task 1
- **Issue:** The plan's `files_modified` list only names `cloud_sync_reconciler_provider.dart`/`.g.dart`, `sync_outbox_service.dart`, and the two test files. But the plan's own `<action>` text is explicit: drain must be called "after a successful sign-in once AccountSyncService has finished (including after prompts are resolved)". `AccountSyncService.onSignIn`/`resolvePrompt`/`markSynced` (in `account_sync_service.dart`) never call each other in a single unbroken chain that reaches "finished" — the loop that resolves each prompt and then calls `markSynced` lives in `AccountSection._runAccountSync()`, in the UI file. There is no other place in the codebase where "AccountSyncService has finished, including after prompts are resolved" is representable as a single call site.
- **Fix:** Added `await ref.read(cloudSyncReconcilerProvider).drainOutbox();` at the end of `_runAccountSync()`'s try block, after `markSynced` and before the `mounted` UI-invalidation check. `drainOutbox()` has its own try/catch (never throws), so this cannot turn a background sync problem into an `_runAccountSync()` crash.
- **Files modified:** `lib/features/profile/account_section.dart`
- **Verification:** `flutter test test/features/profile_account_section_test.dart` — all 12 existing widget tests still pass (the new `drainOutbox()` call surfaces its uninitialized-`Supabase.instance` error via `debugPrint` only, exactly like the pre-existing `delete_own_account` RPC call in the same file's Test 12); full suite green (420/0) after this change
- **Committed in:** `0de9e68` (Task 1 commit)

**2. [Rule 1 - Bug] Re-entrancy guard added to `SyncOutboxService.drain()`**
- **Found during:** Task 1 — this was an explicit `<behavior>` requirement in the plan itself ("Draining is safe to invoke concurrently or repeatedly... if the existing drain() offers no re-entrancy guard, add one here and cover it"), not an independently-discovered bug, but recorded here since it required modifying `sync_outbox_service.dart` beyond a pure pass-through
- **Issue:** With two real call sites now wired in (foreground reconcile and post-sign-in), a foreground event firing while a post-sign-in drain is still awaiting network calls could re-fetch `pendingRows()` before the first call's `markSent()` removed them, sending the same row to `upsertFn`/`deleteFn` twice
- **Fix:** Added a `Future<void>? _inFlightDrain` field; a `drain()` call while one is already running returns the existing Future unchanged instead of starting a second scan. The second caller's own `upsertFn`/`deleteFn` closures are never invoked.
- **Files modified:** `lib/services/sync_outbox_service.dart`, `test/services/sync_outbox_service_test.dart`
- **Verification:** New test drives two concurrent `drain()` calls with a `Completer`-blocked first call; asserts the second call's `upsertFn` never runs and the row is sent exactly once
- **Committed in:** `0de9e68` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 missing critical functionality, 1 bug/robustness requirement explicitly called for by the plan)
**Impact on plan:** Both were necessary for the plan's own stated success criteria (SYNC-05 actually delivered, re-entrancy safety). No scope creep beyond what the plan's `<action>`/`<behavior>` text already specified.

## Issues Encountered
- The initial draft of `test/providers/outbox_drain_wiring_test.dart` matched `drain(` as a raw substring across full file contents, which meant `cloud_sync_reconciler_provider.dart`'s own doc comments (e.g. "`drain()` was thoroughly unit-tested but had no production caller") satisfied the regex on their own — the test would have "passed" even with the real call site deleted, exactly reproducing the kind of blind spot this plan exists to close. Fixed by stripping `//`/`///` line comments and `/* */` block comments from each file's source before scanning. Verified the fix by temporarily deleting the real `SyncOutboxService(...)` construction and `outbox.drain(...)` call, confirming the test failed (`Found construction sites: []`), then restoring both files and confirming the diff against the prior commit was empty and the test passed again.
- Task 1's re-entrancy-guard test was written and verified together with the implementation in a single pass rather than as a strict separate RED-then-GREEN commit pair — both the guard and its test landed in the same `feat` commit. This matches the plan's `tdd="true"` behavior-first intent (test coverage exists and was run before commit) but does not produce two separate git commits for that sub-behavior the way a stricter RED/GREEN split would.

## TDD Gate Compliance

Both tasks are marked `tdd="true"`. Git log shows:
- Task 1 (`0de9e68`): `feat(21-10): construct SyncOutboxService...` — implementation and its new re-entrancy test landed together (see "Issues Encountered" above); the other three behaviors in Task 1's `<behavior>` block (per-row upsert/delete, per-row failure isolation, empty-queue no-op) were already covered by pre-existing tests in `test/services/sync_outbox_service_test.dart` from plan 21-03, which continued to pass unmodified.
- Task 2 (`4a611d1`): `test(21-10): add regression test...` — a pure `test` commit, no accompanying `feat`, because Task 2's job is the test itself (the "GREEN" already exists from Task 1).

No separate `test(...)` commit precedes `0de9e68` for the re-entrancy behavior specifically. Flagged here per the TDD Gate Compliance convention rather than silently omitted — the behavior is covered and passing, but the strict RED-commit-then-GREEN-commit sequence was not produced for this one sub-behavior.

## User Setup Required

None - no external service configuration required. (Device verification of the fix itself is a manual step, appended to `REGRESSION-CHECKLIST-21.md` §5a per this plan's `<output>` block — not performed by this executor.)

## Next Phase Readiness
- SYNC-05/SYNC-06 are now genuinely delivered in code (previously only enqueue-side was wired; drain-side was entirely missing). `flutter test` full suite: 420 passed / 0 failed at time of this plan's completion (run well before the documented pre-existing `notification_service_test.dart` 19:00 UTC time-dependency window).
- `flutter test test/structure/background_task_no_supabase_test.dart` (REG-05): PASS — `cloud_sync_reconciler_provider.dart` (where all the new Supabase-touching code lives) remains unreachable from `lib/platform/background_task.dart`'s import graph.
- Remaining device verification (§5a of `REGRESSION-CHECKLIST-21.md`, plus everything else in that checklist) is still outstanding and must be run on a real device before Phase 21 is considered fully closed — this plan only closes the code-level gap.
- No new Postgres schema, RLS, or grant changes — this plan reused 21-02's existing `profiles`/`availability`/`planned_rides` grants and table structure unchanged.

## Threat Flags

None. `drainOutbox()`'s closures reuse the exact `.from(table).upsert(payload)` / `.from(table).delete().eq(...)` calls already present elsewhere in this codebase (`accountSyncServiceProvider`, `CloudSyncReconciler`'s existing reconcile methods) against the same three tables already covered by 21-02's RLS policies and grants. No new endpoint, no new auth path, no new schema.

## Self-Check: PASSED

All 9 referenced files confirmed present on disk; both task commit hashes (`0de9e68`, `4a611d1`) confirmed present in `git log --all`. No missing items.

---
*Phase: 21-sync-migration*
*Completed: 2026-08-04*
