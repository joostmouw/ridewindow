---
phase: 21-sync-migration
plan: 01
subsystem: domain
tags: [dart, pure-function, tdd, sync, migration]

# Dependency graph
requires:
  - phase: 19-auth
    provides: "account_switch_resolver.dart — the local-only, scaled-down half of the decision logic this plan extends into a cloud-aware superset"
  - phase: 20-repository-refactor-local-only
    provides: "plain-Dart repositories (ProfileRepository, AvailabilityRepository) whose readUpdatedAt() timestamps are the localUpdatedAt input this resolver consumes"
provides:
  - "resolveAccountSync(): pure, SDK-free decision function (SyncDecision enum: pushLocalToCloud/pullCloudToLocal/promptUser/noop) implementing MIG-01/02/03 exactly per ARCHITECTURE.md §5"
  - "Full branch-coverage unit test suite (11 tests) including the exact 5-second noop-boundary case in both directions"
affects: [21-06-account-sync-service, 21-07-conflict-dialogs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure, zero-import decision functions in lib/domain/services/ — no Supabase/SharedPreferences dependency, fully unit-testable in isolation"

key-files:
  created:
    - lib/domain/services/account_sync_resolver.dart
    - test/domain/services/account_sync_resolver_test.dart
  modified: []

key-decisions:
  - "Implemented the exact signature, branch order, and 5-second threshold given verbatim in the plan's <interfaces> block — no redesign"
  - "Test file uses package:test/test.dart (not flutter_test) matching the sibling account_switch_resolver_test.dart style, since this is a pure Dart file with no widget/Flutter dependency"

patterns-established:
  - "Domain-agnostic sync resolvers: generic DateTime? timestamps in, SyncDecision out — called once per domain (profile, availability) by a future orchestrating service, not embedded with domain-specific types"

requirements-completed: [MIG-01, MIG-02, MIG-03, MIG-04]

# Metrics
duration: ~15min
completed: 2026-08-03
---

# Phase 21 Plan 01: Cloud-aware sync/migration decision function Summary

**Pure `resolveAccountSync()` function (zero imports, zero SDK) that turns local vs. cloud data state into one of four decisions — push/pull/prompt/noop — with full branch coverage including the exact 5-second boundary.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-08-03T17:30:00Z (approx)
- **Completed:** 2026-08-03T17:43:50Z
- **Tasks:** 1 (TDD: RED + GREEN, no REFACTOR needed)
- **Files modified:** 2 (both new)

## Accomplishments
- `resolveAccountSync()` implemented verbatim per ARCHITECTURE.md §5's pseudocode — the "cloud-aware superset" of Phase 19's `resolveAccountSwitch()`, composed with it rather than replacing it
- Every MIG-01/02/03 branch unit-tested, including the deliberately tricky exact-5-second boundary (both directions: local-later push, cloud-later pull)
- `account_switch_resolver.dart` (Phase 19) confirmed byte-identical — untouched, per plan constraint
- Full `flutter test` suite: 361 passed, 0 failed (no regressions; this machine's run today did not hit the pre-existing `notification_service_test.dart` month-boundary bug since today is not the last day of the month)

## Task Commits

TDD task, two commits (test → feat; no refactor needed — implementation was already minimal and matched the spec verbatim):

1. **Task 1 (RED): failing tests for resolveAccountSync** - `cba98f1` (test)
2. **Task 1 (GREEN): implement resolveAccountSync** - `9ecf9ff` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified
- `lib/domain/services/account_sync_resolver.dart` - `SyncDecision` enum + `resolveAccountSync()`, zero imports, implements MIG-01/02/03
- `test/domain/services/account_sync_resolver_test.dart` - 11 tests grouped by MIG requirement (MIG-01 empty cloud, MIG-02 different/no local record, MIG-03 same-account divergence including the 5s boundary)

## Decisions Made
- Followed the plan's `<interfaces>` block verbatim — same parameter names, same branch order, same 5-second threshold, no redesign
- Test file style matches `account_switch_resolver_test.dart` (`package:test/test.dart`, plain `test()`/`group()`, no widget pumping, no mocks) since this is pure Dart with no Flutter dependency

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. This is a pure, SDK-free Dart function with no infrastructure dependency.

## Next Phase Readiness

- `resolveAccountSync()` is ready to be called by the not-yet-built `AccountSyncService` (plan 21-06) once per domain (profile, availability)
- Conflict dialogs (plan 21-07) can build directly on the `SyncDecision.promptUser` outcome
- No blockers for downstream plans in this wave/phase

---
*Phase: 21-sync-migration*
*Completed: 2026-08-03*

## Self-Check: PASSED

- FOUND: lib/domain/services/account_sync_resolver.dart
- FOUND: test/domain/services/account_sync_resolver_test.dart
- FOUND: .planning/phases/21-sync-migration/21-01-SUMMARY.md
- FOUND: cba98f1 (RED commit)
- FOUND: 9ecf9ff (GREEN commit)
- FOUND: 6330725 (SUMMARY commit)
