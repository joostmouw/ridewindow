---
phase: 21-sync-migration
plan: 11
subsystem: sync
tags: [riverpod, riverpod3, autodispose, keepalive, supabase, outbox]

# Dependency graph
requires:
  - phase: 21-sync-migration
    provides: SyncOutboxService.drain() + its two production call sites (21-10), CloudSyncReconciler.drainOutbox()/reconcileOnForeground() (21-04, 21-10)
provides:
  - cloudSyncReconciler and syncOutboxService providers now survive beyond a bare ref.read() (both @Riverpod(keepAlive: true)) — the actual fix for SYNC-04/SYNC-05's "drain never runs on device" defect
  - drainOutbox()'s Supabase.instance.client lookup moved out of the method body into the upsert/delete closures, so the method is testable (and runs) without an initialised Supabase
  - test/providers/outbox_drain_wiring_test.dart gained three behavioural tests (in addition to the existing structural scan) that fail if either provider is ever disposed between a bare read and its later Ref usage
affects: [22-account-feedback]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Riverpod 3 gap: a bare @riverpod (autoDispose default) combined with a bare ref.read() and a Ref stored across await boundaries is disposed via the ProviderScheduler's Timer(Duration.zero) before the stored Ref is used again — fix is @Riverpod(keepAlive: true) on any provider whose instance is read-and-discarded but whose returned object keeps using ref internally after an await"
    - "Testing autoDispose-vs-keepAlive behaviour deterministically: insert an explicit `await Future<void>.delayed(Duration.zero)` between the bare container.read() and the later Ref-touching call — this lets the scheduler's real Timer(Duration.zero) fire, reproducing the exact real-world gap that genuine I/O produces on a device, without needing real I/O in the test"
    - "Capturing debugPrint output in a test via a temporary reassignment of the global debugPrint function (flutter/foundation.dart) to observe an error that is caught-and-logged internally by production code rather than rethrown"

key-files:
  created: []
  modified:
    - lib/providers/cloud_sync_reconciler_provider.dart
    - lib/providers/cloud_sync_reconciler_provider.g.dart
    - test/providers/outbox_drain_wiring_test.dart
    - .planning/phases/21-sync-migration/REGRESSION-CHECKLIST-21.md

key-decisions:
  - "The RED test's actual failure mode differs across its three assertions. drainOutbox()'s own test fails via the Supabase-not-initialised masking bug (Supabase.instance.client throws before syncOutboxServiceProvider is even read), not literally naming 'disposed Ref' in its own assertion message. The reconcileOnForeground() test is the one that captures the literal disposed-Ref text, via a debugPrint interceptor, since that method's first _ref access happens before any Supabase touch. Both are genuine RED failures against pre-fix code; together they satisfy the plan's 'the failure names a disposed Ref' criterion at the file level."
  - "Left reconcileOnForeground()'s own Supabase.instance.client lookup where it was (plan explicitly said to) — only drainOutbox()'s lookup moved into the closures, since drainOutbox() is the one method the RED test needed to exercise without Supabase initialised."
  - "Did not touch either production call site (home_screen.dart:98, account_section.dart:317) — confirmed via grep after the fix that both are byte-identical to before this plan."

patterns-established:
  - "Riverpod 3 autoDispose scheduling test pattern: `container.read(provider); await Future<void>.delayed(Duration.zero); /* now use the result */` to deterministically force the ProviderScheduler's dispose Timer to fire between two operations in a test, reproducing production's disposed-Ref timing without real network/DB I/O."

requirements-completed: [SYNC-04, SYNC-05, SYNC-06]

# Metrics
duration: ~25min
completed: 2026-08-04
---

# Phase 21 Plan 11: Fix the disposed-Ref bug masking the outbox drain Summary

**`cloudSyncReconciler`/`syncOutboxService` are now `@Riverpod(keepAlive: true)` — the actual root cause of "outbox drains write-only" (Riverpod 3's autoDispose-by-default disposing the provider between a bare `ref.read()` and its later `_ref` use across an `await`), with three new behavioural tests that fail if either provider is ever disposed like that again.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-08-04T13:57:41Z
- **Tasks:** 2 completed
- **Files modified:** 4 (0 created, 4 modified)

## Accomplishments
- Root-caused and fixed the exact defect from the plan's `<objective>`: `cloudSyncReconciler` and `syncOutboxService` were bare `@riverpod` (autoDispose is Riverpod 3's default per CLAUDE.md), and both call sites (`home_screen.dart`, `account_section.dart`) use a bare `ref.read()` that establishes no listener — the provider is disposed via the scheduler's `Timer(Duration.zero)` shortly after the read returns, and `CloudSyncReconciler` keeps using the stored `Ref` across `await` boundaries, throwing "Cannot use the Ref of cloudSyncReconcilerProvider after it has been disposed." on the next access. Both methods (`reconcileOnForeground()` and `drainOutbox()`, the latter called both directly from `account_section.dart` and again from inside `reconcileOnForeground()` itself) hit this, matching the two-line logcat in the plan's `<objective>` exactly.
- Marked both providers `@Riverpod(keepAlive: true)` and regenerated `cloud_sync_reconciler_provider.g.dart` via `build_runner`, confirming `isAutoDispose: false` for both in the diff.
- Fixed the second, quieter bug the plan called out: `drainOutbox()`'s first statement was `Supabase.instance.client`, which throws in any Supabase-free test environment and was silently caught by the same try/catch — this masked the disposed-Ref bug in every existing test (the "eight lines" the plan's `<context>` references) and made the method untestable without either live/mocked Supabase. Moved the lookup into the `upsertFn`/`deleteFn` closures, where it is only touched once there is a row to actually send.
- Wrote and empirically verified three new behavioural tests in `test/providers/outbox_drain_wiring_test.dart` (kept the existing structural scan from 21-10 unchanged), each driving the real providers through a `ProviderContainer` with a bare read exactly matching the production call sites, with an explicit `await Future<void>.delayed(Duration.zero)` inserted between the read and the later use to force the scheduler's real dispose `Timer` to fire — deterministically reproducing the production timing without needing real network/DB I/O.
- Appended the logcat evidence line to `REGRESSION-CHECKLIST-21.md` §5a so the device verification step names the exact substring to grep for.

## Task Commits

Each task was committed atomically (TDD RED then GREEN, plus a documentation follow-up):

1. **Task 1: Behavioural test that fails on the current code** - `8455a59` (test)
2. **Task 2: Keep the providers alive and stop touching Supabase before there is work** - `91b7409` (feat)

**Plan metadata:** `204a5cf` (docs: append §5a logcat evidence line — required by this plan's `<output>` block, not part of the two numbered tasks)

_TDD note: this is a strict RED→GREEN pair. `8455a59` was committed and independently verified failing (see "RED evidence" below) before `91b7409`'s fix was written._

## RED evidence (Task 1, before Task 2's fix)

Ran `flutter test test/providers/outbox_drain_wiring_test.dart` against the code as of `8455a59` (before `91b7409`). All three new tests failed:

1. **`drainOutbox() reaches SyncOutboxService.drain()`** — `Expected: true, Actual: <false>`. Proximate cause (visible in the swallowed `debugPrint` captured by the test framework's own stdout, not by our interceptor since this particular test didn't need one): `CloudSyncReconciler.drainOutbox failed: 'package:supabase_flutter/src/supabase.dart': Failed assertion: ... You must initialize the supabase instance before calling Supabase.instance` — the masking bug fixed alongside the keepAlive change; `drain()` was never reached.
2. **`reconcileOnForeground() ... never lets a disposed-Ref error reach the caller`** — failed with the debugPrint interceptor capturing the literal message:
   ```
   CloudSyncReconciler.reconcileOnForeground failed: Cannot use the Ref of cloudSyncReconcilerProvider after it has been disposed. This typically happens if:
   - A provider rebuilt, but the previous "build" was still pending and is still performing operations. ...
   ```
   This is the exact error text from the plan's `<critical_context>`, confirmed reproduced.
3. **`two syncOutboxServiceProvider reads ... return the identical instance`** — `Expected: true, Actual: <false>`: the second read, taken after a real event-loop gap, returned a freshly-rebuilt instance rather than the same one, since the pre-fix provider had already been disposed and rebuilt.

After `91b7409` (Task 2's fix), all three pass; full file: 4/4.

## Files Created/Modified
- `lib/providers/cloud_sync_reconciler_provider.dart` - `cloudSyncReconciler` and `syncOutboxService` changed to `@Riverpod(keepAlive: true)` with an explanatory doc comment on each naming the disposed-Ref failure and the 2026-08-04 device date; `drainOutbox()`'s `Supabase.instance.client` lookup moved from the method body into the `upsertFn`/`deleteFn` closures
- `lib/providers/cloud_sync_reconciler_provider.g.dart` - Regenerated via `dart run build_runner build --delete-conflicting-outputs`; both providers now show `isAutoDispose: false`
- `test/providers/outbox_drain_wiring_test.dart` - Kept the existing 21-10 structural scan unchanged; added a `_RecordingSyncOutboxService` fake and three new behavioural tests under a `Behavioural wiring (21-11)` group
- `.planning/phases/21-sync-migration/REGRESSION-CHECKLIST-21.md` - Appended a logcat-evidence checklist item to §5a naming the exact substring (`cloudSyncReconcilerProvider after it has been disposed`) to grep for during the device verification pass, and a short note explaining the second defect found in the same device session

## Decisions Made
- Did not initialize a fake/mock Supabase client in the test file, per the plan's own acceptance criterion ("The test file contains no `Supabase.instance` usage and needs no Supabase initialisation"). This meant `drainOutbox()`'s own RED failure is masked by the Supabase-not-initialised exception rather than literally naming "disposed Ref" in its own assertion — the `reconcileOnForeground()` test is the one that surfaces the literal text, via a `debugPrint` interceptor. Both are genuine, deterministic RED failures against the pre-fix code.
- Used an explicit `await Future<void>.delayed(Duration.zero)` between each bare `container.read(...)` and the later Ref-touching call in all three new tests, rather than relying on incidental timing. Riverpod's `ProviderScheduler` disposes an unlistened autoDispose provider via `Timer(Duration.zero, ...)` (a macrotask), which does not fire mid-synchronous-execution or across a single microtask-resolved `await` — without a real event-loop gap, two back-to-back reads of the same bare provider trivially return the same not-yet-disposed instance and none of the three tests would ever have failed pre-fix, defeating the entire purpose of this plan.
- Left `reconcileOnForeground()`'s own `Supabase.instance.client` lookup in place (the plan explicitly said to) — only `drainOutbox()`'s lookup moved, since that was the specific method the RED test needed to exercise without a live Supabase.

## Deviations from Plan

None - plan executed exactly as written. The `<critical_context>`'s explicit warning not to change either call site was followed (verified via `grep` post-fix that both lines are unchanged); `build_runner` was used to regenerate the `.g.dart` rather than hand-editing it.

## Issues Encountered
- Initial understanding that `drainOutbox()`'s own bare-read test would surface the literal "disposed Ref" text was wrong — `Supabase.instance.client` is the method's first statement and throws (Supabase-not-initialised) before `_ref.read(syncOutboxServiceProvider)` is ever reached in a Supabase-free test, regardless of the Ref's disposal state. Resolved by reading Riverpod 3.3.2's actual scheduler source (`ProviderScheduler.scheduleProviderDispose`/`_DefaultVsync.scheduleDispose`, both `Timer(Duration.zero, ...)`) and `Ref._throwIfInvalidUsage`/`UnmountedRefException` to confirm exactly which line throws when, then targeting the `reconcileOnForeground()` test (whose first `_ref` access precedes any Supabase touch) to reproduce the literal message via a `debugPrint` interceptor instead.

## User Setup Required

None - no external service configuration required. Device verification of this fix (the new §5a logcat-evidence checklist item) is a manual step for the user, not performed by this executor.

## Next Phase Readiness
- SYNC-04/SYNC-05/SYNC-06 are now genuinely delivered end-to-end in code: both the drain trigger (21-10) and the provider lifetime that lets the trigger actually run (21-11) are in place. `flutter test` full suite: 423 passed / 0 failed (up from 21-10's 420; +3 new behavioural tests, structural test unchanged).
- `flutter test test/structure/background_task_no_supabase_test.dart` (REG-05): PASS — the touched file remains outside `lib/platform/background_task.dart`'s import graph.
- The eight `drainOutbox failed: You must initialize the supabase instance` lines are confirmed gone from full-suite output (`grep -c` returned 0). Two unrelated occurrences of the underlying "You must initialize the supabase instance" text remain elsewhere in the suite (the pre-existing `account_section_test.dart` Test 12 delete-account path and `reconcileOnForeground()`'s own untouched client lookup) — expected and out of this plan's scope.
- Remaining device verification (§5a's now-updated checklist, plus the rest of `REGRESSION-CHECKLIST-21.md`) is still outstanding and must be run on a real device before Phase 21 is considered fully closed.
- No new Postgres schema, RLS, grant, or endpoint changes — this plan is a pure Dart-side provider-lifetime fix.

## Threat Flags

None. No new network endpoint, auth path, file access pattern, or schema surface — this plan changes only a Riverpod provider's disposal lifetime and where an existing `Supabase.instance.client` lookup sits within an existing method body.

## Self-Check: PASSED

All 4 referenced files confirmed present on disk; all three commit hashes (`8455a59`, `91b7409`, `204a5cf`) confirmed present in `git log --oneline -5`. No missing items.

---
*Phase: 21-sync-migration*
*Completed: 2026-08-04*
