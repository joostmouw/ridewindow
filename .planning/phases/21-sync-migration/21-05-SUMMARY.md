---
phase: 21-sync-migration
plan: 05
subsystem: sync
tags: [supabase, drift, outbox, riverpod, offline-sync]

# Dependency graph
requires:
  - phase: 21-sync-migration
    provides: "21-02: public.planned_rides Postgres schema (user_id, ride_id, start_at, end_at, planned_score, no updated_at); 21-03: SyncOutboxDao.enqueueOrCoalesce()/supabase_tables.dart; 21-04: CloudReconcileService/CloudSyncReconciler scaffolding + repository outbox seam pattern (ProfileRepository/AvailabilityRepository)"
provides:
  - "PlannedRide.rideId (deterministic, sanitized ISO8601 of start) + toRow(userId)/fromRow() — public.planned_rides row conversion"
  - "PlannedRidesRepository.add()/remove() moved down from the notifier — each enqueues exactly one per-ride outbox row (upsert/delete), never a whole-list payload"
  - "PlannedRidesRepository.enqueueUpsert() — used only by the foreground reconciler to push a local-only ride without re-running add()'s dedup"
  - "CloudReconcileService.parsePlannedRidesRows() + mergePlannedRides() — pure, unit-tested union-merge algorithm (no SupabaseClient/outbox dependency)"
  - "CloudSyncReconciler.readCloudPlannedRides()/reconcilePlannedRides() — third domain wired into reconcileOnForeground(), alongside profile/availability from 21-04"
affects: [21-06, 21-07, 21-08, 21-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-row outbox entity key for growable-list domains: '<userId>:<rideId>' — one outbox row per ride add/remove, never a whole-list payload, contrasting with ProfileRepository/AvailabilityRepository's single-blob '<userId>' key"
    - "Union merge for additive list domains: CloudReconcileService.mergePlannedRides() is a pure function (local, cloud) -> (merged, localOnly), kept separate from the timestamp-comparison path profile/availability use — deliberately not run through resolveAccountSync's conflict-prompt machinery"
    - "Pure-function extraction for hard-to-mock network seams: the merge algorithm itself lives in CloudReconcileService (unit-testable directly against fake local/cloud inputs), while the actual .from(...).select() call lives in CloudSyncReconciler — same split 21-04 established for parseProfileRow/parseAvailabilityRow vs. the real network read"

key-files:
  created:
    - test/domain/models/planned_ride_row_test.dart
  modified:
    - lib/domain/models/planned_ride.dart
    - lib/data/repositories/planned_rides_repository.dart
    - lib/providers/planned_rides_notifier.dart
    - lib/services/cloud_reconcile_service.dart
    - lib/providers/cloud_sync_reconciler_provider.dart
    - test/data/repositories/planned_rides_repository_test.dart
    - test/providers/planned_rides_notifier_test.dart
    - test/services/cloud_reconcile_service_test.dart

key-decisions:
  - "readCloudPlannedRides() (the actual .from(kPlannedRidesTable).select().eq() network call) lives on CloudSyncReconciler, not CloudReconcileService — matching plan 21-04's own decision to keep CloudReconcileService free of a SupabaseClient dependency (mocking Postgrest's fluent builder was judged impractical there too). CloudReconcileService instead gained two plain methods: parsePlannedRidesRows() (row-list -> List<PlannedRide>) and mergePlannedRides() (pure union-merge algorithm), both fully unit-tested without touching Supabase."
  - "Union merge keeps the LOCAL copy when the same rideId exists on both sides (Map.putIfAbsent semantics) rather than overwriting with the cloud copy — rides have no mutable state to diverge on (same start/end/score always produces the same rideId), so this only matters in the theoretical case of a hash collision, and local-wins is the safer default given D-11's broader 'local wins' policy for first-login migration."

requirements-completed: [SYNC-03, SYNC-05, SYNC-06]

# Metrics
duration: ~35min
completed: 2026-08-03
---

# Phase 21 Plan 05: Planned rides sync — per-ride outbox + union-merge reconcile Summary

**Wired `planned_rides` to the cloud via a per-ride outbox (one row per add/remove, never a whole-list payload) and a pure, unit-tested union-merge foreground reconciler — the one sync domain that deliberately does not go through the timestamp-comparison/conflict-prompt path profile and availability use.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-08-03
- **Tasks:** 2/2 completed
- **Files modified:** 8 (5 lib files, 3 test files existing + 1 new test file), plus 1 riverpod `.g.dart` regeneration

## Accomplishments

- `PlannedRide.rideId`/`toRow(userId)`/`fromRow(row)` match `public.planned_rides`' exact 5-column shape (SYNC-03), round-trip-tested against the plan's own literal proof value
- `PlannedRidesRepository.add()`/`remove()` moved down from `PlannedRidesNotifier` — each enqueues exactly one per-ride outbox row (`upsert`/`delete`) via `kOutboxEntityPlannedRide` when signed in, silently no-ops otherwise; `enqueueUpsert()` added for the reconciler's use
- `PlannedRidesNotifier.clearAll()` verified untouched — D-11's "start fresh, local-only" guarantee still holds, proven by a new test that constructs the notifier with a signed-in outbox+userId and asserts the outbox stays empty after `clearAll()`
- `CloudReconcileService.parsePlannedRidesRows()` + `mergePlannedRides()` — a pure union-merge algorithm, unit-tested directly against fake local/cloud `PlannedRide` lists (9 new tests) without mocking Postgrest's fluent builder
- `CloudSyncReconciler.readCloudPlannedRides()`/`reconcilePlannedRides()` — third domain wired into `reconcileOnForeground()`, pushing local-only rides to the outbox and pulling cloud-only rides into local storage, never deleting a ride from either side
- Full `flutter test` suite: 401/402 passing (up from 388/389 baseline after plan 21-04; +13 net new tests from Task 1/2), the 1 failure is the documented pre-existing date-boundary bug in `notification_service_test.dart` (fails only on the last day of the month, unrelated to this plan)
- `flutter analyze` clean on every file this plan touched; `test/structure/background_task_no_supabase_test.dart` (REG-05) still green

## Task Commits

1. **Task 1: PlannedRide row shape + repository-owned add()/remove() with per-ride outbox** — `ba95ab7` (feat)
2. **Task 2: Cloud read + union-merge foreground reconcile for planned rides** — `a3131fa` (feat)

_No separate plan-metadata commit — SUMMARY.md and STATE.md are committed by the orchestrator after all worktree agents in this wave complete, per this plan's parallel-execution instructions._

## Files Created/Modified

- `lib/domain/models/planned_ride.dart` — `rideId`/`toRow()`/`fromRow()` factory
- `lib/data/repositories/planned_rides_repository.dart` — optional outbox/userId constructor params, `add()`/`remove()`/`enqueueUpsert()`
- `lib/providers/planned_rides_notifier.dart` — `plannedRidesRepositoryProvider` watches `currentUserIdProvider`/`appDatabaseProvider`; `add()`/`remove()` delegate to the repository
- `lib/services/cloud_reconcile_service.dart` — `parsePlannedRidesRows()` + `mergePlannedRides()`
- `lib/providers/cloud_sync_reconciler_provider.dart` — `readCloudPlannedRides()` + `reconcilePlannedRides()`, called from `reconcileOnForeground()`
- Test files: new `planned_ride_row_test.dart`; extended `planned_rides_repository_test.dart`, `planned_rides_notifier_test.dart`, `cloud_reconcile_service_test.dart`

## Decisions Made

- **`readCloudPlannedRides()` placement:** lives on `CloudSyncReconciler`, not `CloudReconcileService` — the plan's own `<interfaces>` sketch put it on `CloudReconcileService` holding a `SupabaseClient`, but plan 21-04 already established that `CloudReconcileService` stays free of the SDK dependency (mocking `PostgrestFilterBuilder`'s fluent chain was judged impractical there). Kept the same split here: the actual network call is the unverified-by-automated-test seam in `CloudSyncReconciler`, while `CloudReconcileService.parsePlannedRidesRows()`/`mergePlannedRides()` carry the fully-tested logic.
- **Union merge keeps the local copy on rideId collision** (`Map.putIfAbsent`, not overwrite) — proven by an explicit test where cloud carries a different `plannedScore` for the same `rideId` and the merged result keeps the local score. This only matters in the theoretical case of two devices independently producing the same deterministic id (same start/end/score), and local-wins matches D-11's broader migration policy.

## Deviations from Plan

None — plan executed as written. The one adaptation (`readCloudPlannedRides()` seam placement) was explicitly anticipated by the plan's own instruction ("matching whatever SupabaseClient-vs-pre-fetched-row shape plan 21-04 settled on... state this explicitly in the SUMMARY if it required a different seam"), not a deviation from a specified behavior.

## Issues Encountered

- Same Rule-3-class issue plan 21-04 documented: making `plannedRidesRepositoryProvider` watch `appDatabaseProvider` (a real disk-backed Drift database) broke the two pre-existing `ProviderContainer`-based D-10 tests in `planned_rides_notifier_test.dart`, which had never previously constructed `appDatabaseProvider`. Fixed by overriding `appDatabaseProvider` with an in-memory `AppDatabase(NativeDatabase.memory())` in both tests, matching 21-04's established fix pattern. No corresponding fix needed in `test/features/*` widget tests — they all override `plannedRidesProvider` directly with a fake notifier and never reach `plannedRidesRepositoryProvider`.
- `dart run build_runner build` regenerated the same unrelated stale-doc-comment reformatting diff in `lib/providers/auth_notifier.g.dart` noted in plan 21-04's SUMMARY — reverted via `git checkout -- lib/providers/auth_notifier.g.dart` to keep the diff scoped to this plan's actual changes.

## User Setup Required

None — no external service configuration required. This plan only wires existing Supabase infrastructure (schema from 21-02, outbox from 21-03, reconciler scaffolding from 21-04) into the planned-rides repository/provider layer.

## Next Phase Readiness

- All three sync domains (profile, availability, planned rides) now independently contribute pending/synced state to the same outbox — ready for plan 21-06/21-07's drain step and sync-status indicator (SYNC-06)
- `CloudReconcileService`'s row-parsing and merge-algorithm seams are proven correct by Task 1/2's tests; the actual Supabase `.from().select()` calls in `CloudSyncReconciler` remain unverified by automated test and should be exercised on-device as part of the phase's manual regression checklist (`MANUAL-VERIFICATION-21.md`), same caveat plan 21-04 documented for profile/availability
- This plan explicitly did NOT write a `migrate_account_data` call site (per the plan's own scope note) — that remains plan 21-06's responsibility
- No blockers for downstream plans in this phase

---
*Phase: 21-sync-migration*
*Completed: 2026-08-03*

## Self-Check: PASSED

All created/modified files verified present on disk (lib/domain/models/planned_ride.dart, lib/data/repositories/planned_rides_repository.dart, lib/providers/planned_rides_notifier.dart, lib/services/cloud_reconcile_service.dart, lib/providers/cloud_sync_reconciler_provider.dart, test/domain/models/planned_ride_row_test.dart, this SUMMARY.md). Both task commits (`ba95ab7`, `a3131fa`) verified present in `git log`.
