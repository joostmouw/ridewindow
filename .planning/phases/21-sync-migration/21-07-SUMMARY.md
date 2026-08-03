---
phase: 21-sync-migration
plan: 07
subsystem: sync
tags: [riverpod, supabase, drift, sync, account-section, l10n]

# Dependency graph
requires:
  - phase: 21-sync-migration
    provides: "21-06: AccountSyncService.onSignIn()/resolvePrompt()/markSynced(), PendingSyncPrompt, SyncDomain, buildMigrationRpcParams() -- this plan's production dependency graph"
provides:
  - "AccountSection._runAccountSync() -- wires AccountSyncService.onSignIn() into the sign-in flow, appended to the end of _checkAccountSwitch() using its pre-write lastSyncedUid snapshot"
  - "Two sequential D-04/D-05 AlertDialogs for PendingSyncPrompt (profile before availability), resolved via AccountSyncService.resolvePrompt()/markSynced()"
  - "accountSyncServiceProvider (cloud_sync_reconciler_provider.dart) -- constructs AccountSyncService with production dependencies (repositories, cloud-read closures, migrate RPC, lastSyncedUid writer); the testable seam widget tests override instead of needing a live Supabase client"
  - "outboxPendingCountProvider -- Stream<int> of SyncOutboxDao.watchPendingCount(), drives D-06/D-07's two-state sync status text"
  - "AccountSection's signed-in row shows 'Gesynchroniseerd'/'Wordt gesynchroniseerd...' below the email"
affects: [21-08, 21-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Provider-wrapped service construction for widget testability: rather than constructing AccountSyncService inline inside _runAccountSync() (as the plan's illustrative <interfaces> sketch showed), construction lives behind accountSyncServiceProvider (a @riverpod Future function). Widget tests override the provider with a fake AccountSyncService subclass instead of needing a live SupabaseClient -- same seam-over-inline-construction reasoning as plan 21-06's own readCloudProfile/readCloudAvailability closures."
    - "Defensive try/catch around _runAccountSync(): a sync failure (network error, RLS denial, uninitialized Supabase in tests) must never block a sign-in that already succeeded, matching CloudSyncReconciler.reconcileOnForeground's existing error-swallowing pattern in this same file."

key-files:
  created: []
  modified:
    - lib/features/profile/account_section.dart
    - lib/providers/cloud_sync_reconciler_provider.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_nl.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_en.dart
    - lib/l10n/app_localizations_nl.dart
    - test/features/profile_account_section_test.dart
    - test/features/profile_screen_calendar_test.dart

key-decisions:
  - "AccountSyncService construction moved behind a new accountSyncServiceProvider rather than built inline in _runAccountSync() as the plan's <interfaces> sketch showed -- the plan's own behavior bullet anticipated 'the equivalent seam plan 21-06 exposes for testing' as an open implementation choice; a provider seam lets widget tests override with a fake service instead of requiring a live Supabase client, and keeps AccountSection's own code focused on dialog sequencing rather than dependency wiring."
  - "_runAccountSync() wrapped in try/catch, swallowing and debugPrint-ing any error -- not in the plan's <interfaces> sketch, but required so a sync failure never blocks a sign-in that already succeeded (matching CloudSyncReconciler's own established pattern in the same file). This also transparently protects any pre-existing signed-in widget test that doesn't override accountSyncServiceProvider."
  - "outboxPendingCountProvider always overridden by default in profile_account_section_test.dart's test helper (with a direct Stream.value(0), not a real in-memory Drift database) -- a live .watchSingle() stream schedules a zero-duration Timer on widget teardown that trips flutter_test's 'A Timer is still pending' invariant check; none of this file's tests need the real database."

requirements-completed: [SYNC-06, MIG-01, MIG-02, MIG-03]

# Metrics
duration: ~55min
completed: 2026-08-03
---

# Phase 21 Plan 07: Sign-in flow wiring + sync status text Summary

**Wired plan 21-06's `AccountSyncService` into `AccountSection`'s real sign-in flow via a new testable `accountSyncServiceProvider` seam, added the two sequential D-04/D-05 conflict `AlertDialog`s, and added the D-06/D-07 "Gesynchroniseerd"/"Wordt gesynchroniseerd..." sync-status text driven by a new `outboxPendingCountProvider`.**

## Performance

- **Duration:** ~55 min
- **Completed:** 2026-08-03
- **Tasks:** 2/2 completed
- **Files modified:** 9 (2 lib providers/widgets + 5 generated l10n files + 2 test files)

## Accomplishments

- `_checkAccountSwitch()` now calls `_runAccountSync()` as its final step, after both firstSignIn/sameAccount/differentAccount branches have settled local storage — reusing the method's own already-captured pre-write `lastSyncedUid` local variable (no second `prefs.getString` read), exactly per the plan's ordering requirement
- `_runAccountSync()` shows at most two sequential `AlertDialog`s for any `PendingSyncPrompt`s returned by `AccountSyncService.onSignIn()` — profile before availability, never simultaneous — verified by a widget test that taps through both dialogs and asserts `resolvedDomains == [profile, availability]`
- New `accountSyncServiceProvider` (`cloud_sync_reconciler_provider.dart`) constructs the real `AccountSyncService` with production dependencies: the three repositories, `readCloudProfile`/`readCloudAvailability` closures composed from `CloudReconcileService`'s pure row parsers plus real `.from(...).select()...` calls, the `migrate_account_data` RPC closure, and the `account.lastSyncedUid` writer
- New `outboxPendingCountProvider` streams `SyncOutboxDao.watchPendingCount()`; `AccountSection`'s signed-in row renders exactly two possible strings ("Gesynchroniseerd" at 0 pending, "Wordt gesynchroniseerd..." above 0) with loading/error states rendering nothing — never a fabricated third status
- `accountSyncPromise`'s "Binnenkort"/"Coming soon" prefix removed now that sync is real, per 19-CONTEXT.md's own deferred note — verified by a source grep across both ARB files
- Full `flutter test` suite: 414 passed / 1 failed — the failure is the documented pre-existing `notification_service_test.dart` time-dependency bug (fails after 19:00 UTC), not a regression; `test/structure/background_task_no_supabase_test.dart` (REG-05) still green; `lib/domain/services/account_switch_resolver.dart` unmodified (`git diff --stat` empty)

## Task Commits

1. **Task 1: Wire AccountSyncService into the sign-in flow, sequential conflict dialogs, l10n** — `5307bb8` (feat)
2. **Task 2: Sync status text (D-06/D-07)** — `30e3516` (feat)
3. **Follow-up: name outboxPendingCountProvider in its own doc comment** — `9e8f1e7` (docs)

_No separate plan-metadata commit — SUMMARY.md and STATE.md are committed by the orchestrator after all worktree agents in this wave complete, per this plan's parallel-execution instructions._

## Files Created/Modified

- `lib/features/profile/account_section.dart` — `_runAccountSync()` added, appended to `_checkAccountSwitch()`; `_buildSignedInRow()` renders the sync-status text
- `lib/providers/cloud_sync_reconciler_provider.dart` — `accountSyncServiceProvider`, `outboxPendingCountProvider` added
- `lib/l10n/app_en.arb` / `app_nl.arb` — `accountConflict*` (6 keys), `accountSyncStatus*` (2 keys) added; `accountSyncPromise` reworded
- `lib/l10n/app_localizations*.dart` — regenerated via `flutter gen-l10n`
- `test/features/profile_account_section_test.dart` — `FakeAccountSyncService`, 4 new widget tests (sequential dialogs, two sync-status states, signed-out row never shows sync status)
- `test/features/profile_screen_calendar_test.dart` — collateral fix: `outboxPendingCountProvider` override added to its signed-in test

## Decisions Made

See `key-decisions` in frontmatter — summarized: `accountSyncServiceProvider` as a testable seam (deviating from the plan's illustrative inline-construction sketch, which the plan's own text anticipated as an open choice), a defensive try/catch around `_runAccountSync()`, and always-overridden `outboxPendingCountProvider` in the account-section test file's default helper to avoid a real Drift database in widget tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] `_runAccountSync()` wrapped in try/catch**
- **Found during:** Task 1, while verifying `profile_screen_calendar_test.dart`'s pre-existing signed-in test (Test 4) still passed
- **Issue:** Without a try/catch, any `_runAccountSync()` failure (e.g. an uninitialized Supabase client, a network error) would propagate as an uncaught exception from `_checkAccountSwitch()`, which is called from `build()`'s `ref.listen` on every auth-state change — turning a background-sync problem into a crash of the entire sign-in flow.
- **Fix:** Wrapped the whole body of `_runAccountSync()` in try/catch, `debugPrint`-ing the error and returning silently, matching `CloudSyncReconciler.reconcileOnForeground`'s existing pattern in this same file.
- **Files modified:** `lib/features/profile/account_section.dart`
- **Verification:** `profile_screen_calendar_test.dart` Test 4 passes with the caught-and-logged Supabase-not-initialized error visible in test output, no test failure.
- **Committed in:** `5307bb8` (Task 1 commit)

**2. [Rule 1 - Bug] `outboxPendingCountProvider` override added to `profile_screen_calendar_test.dart`'s signed-in test**
- **Found during:** Task 2, running the full `flutter test` suite
- **Issue:** `_buildSignedInRow()`'s new `ref.watch(outboxPendingCountProvider)` call is unconditional whenever a signed-in user renders. `profile_screen_calendar_test.dart`'s pre-existing Test 4 (signed-in, outside this plan's `files_modified` list) had no override for it, so it fell through to the real provider, which opens a disk-backed Drift database via `path_provider` — unstable/unavailable in this plain widget-test environment, failing with "A Timer is still pending even after the widget tree was disposed."
- **Fix:** Added `outboxPendingCountProvider.overrideWith((ref) => Stream<int>.value(0))` to that test's `_pumpProfileScreen` overrides, matching this codebase's own established `appDatabaseProvider` fake-vs-real-database pattern (see `profile_notifier_test.dart`'s own doc comment on the identical problem).
- **Files modified:** `test/features/profile_screen_calendar_test.dart`
- **Verification:** `flutter test test/features/profile_screen_calendar_test.dart` — all 4 tests pass; full suite confirms no other collateral test files affected (only files rendering a signed-in `AccountSection` are exposed to this, and this was the only one found).
- **Committed in:** `30e3516` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 missing critical error handling, 1 bug — collateral test breakage caused directly by this plan's new unconditional `ref.watch` call)
**Impact on plan:** Both auto-fixes were necessary for correctness (a sync failure must not crash sign-in) and to keep the pre-existing test suite green. No scope creep — both fixes are narrowly targeted at the exact new code paths this plan introduced.

## Known Stubs

None. No hardcoded empty values, placeholder text, or unwired data sources were introduced by this plan.

## Threat Flags

None. This plan's only new surface is a UI-layer wiring of plan 21-06's already-reviewed `AccountSyncService` and a read-only outbox-count stream; no new network endpoints, auth paths, or schema changes.

## Issues Encountered

- During execution, a `git stash` command was run in error (prohibited operation in a worktree context) while inspecting baseline `dart format` compliance. It was immediately identified (the stash was created moments earlier in the same session, unambiguously mine, visible at the top of `git stash list`) and reverted via `git stash pop` before any further commands ran. No work was lost; `git status`/`git diff --stat` were used afterward to confirm all files were restored to their pre-stash state exactly. No stash operations were used going forward.
- `dart format --set-exit-if-changed` reported this plan's new/modified files as unformatted, but the same check against an untouched pre-existing file (`profile_screen.dart`) showed the same result — confirming `dart format` is not an enforced convention in this codebase already, so no reformatting was applied (would have created unrelated diff noise).

## User Setup Required

None — no external service configuration required. This plan only wires existing Supabase/Drift infrastructure (already provisioned in earlier phases) into the UI layer.

## Next Phase Readiness

- SYNC-06 and MIG-01/02/03 are now user-visible: a tester can sign in, see at most two ordered conflict prompts if their data genuinely diverged, and see "Gesynchroniseerd"/"Wordt gesynchroniseerd..." reflecting real outbox state
- The actual Supabase network calls inside `accountSyncServiceProvider`'s `readCloudProfile`/`readCloudAvailability`/`migrateFn` closures remain unverified by automated test (consistent with plan 21-04/21-05/21-06's own documented caveat) and should be exercised on-device as part of the phase's manual regression checklist
- No blockers for downstream plans in this phase

---
*Phase: 21-sync-migration*
*Completed: 2026-08-03*

## Self-Check: PASSED

All modified files verified present on disk (lib/features/profile/account_section.dart, lib/providers/cloud_sync_reconciler_provider.dart, lib/l10n/app_en.arb, lib/l10n/app_nl.arb, test/features/profile_account_section_test.dart, test/features/profile_screen_calendar_test.dart, this SUMMARY.md). All three commits (`5307bb8`, `30e3516`, `9e8f1e7`) verified present in `git log`.
