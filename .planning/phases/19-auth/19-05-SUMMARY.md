---
phase: 19-auth
plan: 05
subsystem: auth
tags: [google_sign_in, supabase, flutter_riverpod, calendar, profile-screen]

# Dependency graph
requires:
  - phase: 19-auth (19-02)
    provides: CalendarService.ensureGoogleSignInReady() shared init gate, isCalendarConnected()/disconnectCalendar()
  - phase: 19-auth (19-03)
    provides: authStateProvider (Supabase auth stream), calendarMismatchWarning l10n key
provides:
  - "CalendarService.currentGoogleEmail() — non-prompting getter for the Google account currently backing Calendar authorization"
  - "Profile screen's Calendar row now shows a passive warning when the Calendar-authorized Google account differs from the signed-in Supabase account"
affects: [20-repository-refactor, 21-sync-migration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Non-prompting identity checks use GoogleSignIn.instance.attemptLightweightAuthentication()/authorizationForScopes() as siblings — never authorizeScopes()/authenticate() outside an explicit user tap"
    - "Passive drift checks (Calendar-account vs. signed-in-account) compare .email fields directly, never the Supabase UUID"

key-files:
  created: []
  modified:
    - lib/services/calendar_service.dart
    - lib/features/profile/profile_screen.dart
    - test/features/profile_screen_calendar_test.dart

key-decisions:
  - "currentGoogleEmail() placed directly after isCalendarConnected() as one pure addition — verified via git show that no other method's bytes changed"
  - "Mismatch check (_checkCalendarMismatch) only fires after _calendarConnected == true, gating it behind the existing non-prompting isCalendarConnected() result (D-11)"
  - "Disconnect also clears _calendarMismatchEmail — prevents a stale warning surviving past a successful disconnect (Rule 2 addition, not in original plan text but required for correctness)"
  - "Task 3's comparison logic stayed inlined in the private State class rather than extracted to a top-level pure helper, since Dart privacy is per-file and an extracted `_`-prefixed function would still be invisible to the external test file; tests instead prove the reachable contract (mismatch absent whenever Calendar can't resolve connected in the test env, which is always, per the file's pre-existing platform-channel-gap note)"

patterns-established:
  - "AUTH-07-style mismatch warnings: passive, additive-only Column subtitle, gated behind an already-non-prompting connection check, comparing account emails not internal user ids"

requirements-completed: [AUTH-07]

# Metrics
duration: ~20min
completed: 2026-07-26
---

# Phase 19 Plan 05: Calendar Account Mismatch Warning Summary

**Profile's existing Calendar row now warns (icon + `calendarMismatchWarning(email)` line, additive to the existing status text) when the Google account backing Calendar authorization differs from the signed-in Supabase account — using a new non-prompting `CalendarService.currentGoogleEmail()` getter, with zero changes to the "Add to calendar" flow itself.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-26T12:05:00+02:00 (approx.)
- **Completed:** 2026-07-26T12:28:00+02:00
- **Tasks:** 3/3 completed
- **Files modified:** 3

## Accomplishments
- `CalendarService.currentGoogleEmail()` added — non-prompting, mirrors `isCalendarConnected()`'s contract via `attemptLightweightAuthentication()`
- Profile screen's Calendar `ListTile` subtitle now conditionally renders a warning line (icon + ICU-parameterized text) when a mismatch is detected, without altering the unchanged-case rendering
- 2 new widget tests added (315 → 317 passing, 0 failing across the full suite) proving the mismatch warning stays absent in every reachable test-environment state

## Task Commits

Each task was committed atomically:

1. **Task 1: Add CalendarService.currentGoogleEmail() — non-prompting** - `c795718` (feat)
2. **Task 2: Show the mismatch warning on the existing Calendar row** - `1176acc` (feat)
3. **Task 3: Widget tests for the mismatch warning** - `84fc539` (test)

**Plan metadata:** (pending — orchestrator commits STATE.md/ROADMAP.md updates after wave merge)

## Files Created/Modified
- `lib/services/calendar_service.dart` — new `currentGoogleEmail()` method, one pure addition after `isCalendarConnected()`
- `lib/features/profile/profile_screen.dart` — new `_calendarMismatchEmail` field, `_checkCalendarMismatch()` method (called from `_checkCalendarConnection()` only when already connected), mismatch-aware subtitle rendering in the Calendar `ListTile`, mismatch state cleared on disconnect
- `test/features/profile_screen_calendar_test.dart` — `authStateProvider` override added to `_pumpProfileScreen`, 2 new tests (Test 3: signed-out, Test 4: signed-in but Calendar not connected)

## Decisions Made
- Compared `.email` fields (Calendar-authorized vs. Supabase-signed-in), never the Supabase UUID — per the plan's interfaces section, these are unrelated identity spaces
- Added a Rule 2 correctness fix not explicitly spelled out in the plan text: `_disconnectCalendar()` now also clears `_calendarMismatchEmail` alongside `_calendarConnected`, so a stale mismatch warning cannot survive a successful disconnect
- Task 3's testability constraint (documented inline in the test file and here): the mismatch-check is only reachable after `isCalendarConnected()` resolves `true`, which never happens in the Flutter test environment (no `google_sign_in` platform-channel handler, same pre-existing constraint documented at the top of the test file for Test 1/2). Rather than force an artificial `true` state, the two new tests prove the always-degraded-to-safe contract directly: no warning icon/text appears regardless of `authStateProvider` state, and the unchanged single-`Text` subtitle renders when there's no mismatch

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Cleared `_calendarMismatchEmail` on disconnect**
- **Found during:** Task 2
- **Issue:** The plan's action text for Task 2 didn't mention resetting the mismatch state in `_disconnectCalendar()`. Without this, a user who disconnects Calendar after seeing a mismatch warning would still see the stale warning icon/text until the next full screen re-check (there is none — `_checkCalendarConnection()` only runs in `initState()`), which is misleading: the row would say "Disconnect" is no longer available (Calendar not connected) while still showing a mismatch line referencing an account that's no longer relevant.
- **Fix:** `_disconnectCalendar()` now sets both `_calendarConnected = false` and `_calendarMismatchEmail = null` in the same `setState()` call.
- **Files modified:** `lib/features/profile/profile_screen.dart`
- **Verification:** `flutter analyze` clean; existing Test 1/2 still pass unmodified (they don't reach this code path since `_calendarConnected` starts null → false, disconnect is never tapped in those tests)
- **Committed in:** `1176acc` (part of Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Necessary for correctness — prevents a misleading stale warning after the user takes the exact corrective action (Disconnect) the plan says the warning should point them to. No scope creep; still zero changes to the "Add to calendar" flow.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- AUTH-07 closed. Phase 19's auth-adjacent Calendar-drift concern is now surfaced to the user with zero added friction on the working Calendar flow (REG-04 preserved).
- Full automated suite: 317 passing / 0 failing (grew from the 315/0 baseline recorded at this plan's base commit — no regression).
- No blockers for later phases; `currentGoogleEmail()` is a small, self-contained addition that later phases (20/21, repository refactor + sync) do not need to touch.

---
*Phase: 19-auth*
*Completed: 2026-07-26*

## Self-Check: PASSED

- FOUND: lib/services/calendar_service.dart
- FOUND: lib/features/profile/profile_screen.dart
- FOUND: test/features/profile_screen_calendar_test.dart
- FOUND: .planning/phases/19-auth/19-05-SUMMARY.md
- FOUND commit: c795718 (Task 1)
- FOUND commit: 1176acc (Task 2)
- FOUND commit: 84fc539 (Task 3)
