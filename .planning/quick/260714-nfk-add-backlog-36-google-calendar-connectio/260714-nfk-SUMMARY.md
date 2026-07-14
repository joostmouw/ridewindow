---
phase: quick-260714-nfk
plan: 01
subsystem: ui
tags: [google_sign_in, calendar, riverpod, l10n, flutter]

requires: []
provides:
  - CalendarService.isCalendarConnected() (check-only, never prompts)
  - CalendarService.disconnectCalendar() (revokes authorization)
  - Google Calendar status row in ProfileScreen OVER section
affects: [profile-screen, calendar-integration]

tech-stack:
  added: []
  patterns:
    - "Check-only Google Sign-In status via authorizationForScopes (returns null instead of prompting), distinct from authorizeScopes which prompts"
    - "Fire-and-forget async status check from initState(), guarded by mounted checks, degrading to a safe default on any exception"

key-files:
  created:
    - test/features/profile_screen_calendar_test.dart
  modified:
    - lib/services/calendar_service.dart
    - lib/features/profile/profile_screen.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_nl.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_en.dart
    - lib/l10n/app_localizations_nl.dart

key-decisions:
  - "Boolean-only status shown (Connected/Not connected) — no account email/identity, matching GoogleSignInClientAuthorization's actual API surface in this app's scope-only flow"
  - "isCalendarConnected() uses authorizationForScopes (never prompts) — distinct from the existing authorizeScopes calls in addRideSlotToCalendar()/getEvents()"
  - "Test viewport enlarged via tester.view.physicalSize instead of scrollUntilVisible — the OVER section row sits deep in a lazy sliver ListView and isn't mounted at default test viewport size, even with skipOffstage:false"

patterns-established:
  - "Widget tests for deep-in-list ListTile rows should enlarge tester.view.physicalSize rather than rely on skipOffstage:false or scrollUntilVisible (the latter is flaky in this project's current Flutter/test-runner combination — see deferred-items.md)"

requirements-completed: [NFK-01]

duration: 45min
completed: 2026-07-14
---

# Phase quick-260714-nfk: Google Calendar Connection Visibility Summary

**CalendarService gains a non-prompting `isCalendarConnected()` check and a `disconnectCalendar()` revoke method, surfaced as a new "Google Calendar" status row (Connected/Not connected + Disconnect action) in the Profile screen's OVER section, backed by new EN/NL l10n strings and a TDD-driven widget test.**

## Performance

- **Duration:** 45min
- **Started:** 2026-07-14T14:28:00Z (approx, per task start)
- **Completed:** 2026-07-14T15:13:04Z
- **Tasks:** 2 completed
- **Files modified:** 8 (1 new test file, 7 modified)

## Accomplishments
- `CalendarService.isCalendarConnected()` added — checks Google Calendar authorization status using `authorizationForScopes` (never prompts the user), sharing the existing lazy `_ensureInitialized()` guard
- `CalendarService.disconnectCalendar()` added — revokes authorization via `GoogleSignIn.instance.disconnect()`
- Profile screen's OVER section now shows a "Google Calendar" row between "Send feedback" and "Privacy policy", displaying live Checking/Connected/Not connected status with a Disconnect action when connected
- Full TDD RED→GREEN cycle followed: failing test committed first (compile-error RED state), then l10n + UI wiring made it pass (GREEN)
- EN/NL ARB strings added for all six new Google Calendar strings; `flutter gen-l10n` regenerated cleanly

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend CalendarService with connection-status check and disconnect** - `ce0afd7` (feat)
2. **Task 2 (RED): Add failing test for Google Calendar status row** - `1937da1` (test)
2. **Task 2 (GREEN): Wire Google Calendar status row into Profile screen** - `98f1f3b` (feat)

**Plan metadata:** (this commit, following SUMMARY/STATE update)

## TDD Gate Compliance

Task 2 (`tdd="true"`) followed the mandatory RED→GREEN sequence:
- RED: `1937da1` — `test(quick-260714-nfk): add failing test for Google Calendar status row`. Confirmed the test failed for the right reason (compile error: `S.googleCalendarLabel`/`calendarStatusNotConnected`/`calendarDisconnectButton` getters did not exist yet), not for an unrelated reason.
- GREEN: `98f1f3b` — `feat(quick-260714-nfk): wire Google Calendar status row into Profile screen`. Implementation added, `flutter gen-l10n` regenerated, both new tests pass standalone.
- No separate REFACTOR commit was needed — the implementation matched the plan's interface spec on the first GREEN pass.

## Files Created/Modified
- `lib/services/calendar_service.dart` - Added `isCalendarConnected()` (check-only, never prompts) and `disconnectCalendar()`; updated header doc comment to document the new CAL-02 exception
- `lib/features/profile/profile_screen.dart` - Added `_calendarConnected` field, `_checkCalendarConnection()`/`_disconnectCalendar()`/`_calendarStatusText()` methods, and the new "Google Calendar" `ListTile` in the OVER section
- `lib/l10n/app_en.arb` / `lib/l10n/app_nl.arb` - Added `googleCalendarLabel`, `calendarStatusChecking`, `calendarStatusConnected`, `calendarStatusNotConnected`, `calendarDisconnectButton`, `calendarDisconnectedSnackbar`
- `lib/l10n/app_localizations.dart` / `app_localizations_en.dart` / `app_localizations_nl.dart` - Regenerated via `flutter gen-l10n`
- `test/features/profile_screen_calendar_test.dart` - New widget test covering the graceful-degradation status-check path and absence of the Disconnect button when not connected

## Decisions Made
- No account email or Google identity shown — boolean status only, per locked decision and confirmed API limitation (`GoogleSignInClientAuthorization` carries only an `accessToken` in this app's scope-only flow)
- `isCalendarConnected()` uses `authorizationForScopes` (never prompts), distinct from the existing `authorizeScopes` calls elsewhere in `CalendarService` (which do prompt)
- Test viewport enlarged via `tester.view.physicalSize = const Size(800, 3000)` rather than `scrollUntilVisible` — discovered during verification that the new ListTile sits deep enough in the Profile screen's lazy sliver `ListView` that it isn't mounted at the default 600px test viewport height, even with `skipOffstage: false` (which only finds already-mounted offstage widgets, not widgets outside the sliver's layout extent entirely)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test file's own lint issues fixed during authoring**
- **Found during:** Task 2 (writing `profile_screen_calendar_test.dart`)
- **Issue:** New test file initially had a dangling library doc comment (missing `library;` directive) and redundant `const` keywords flagged by `prefer_const_constructors`/`unnecessary_const`
- **Fix:** Added `library;` directive after the doc comment; hoisted `const` to the outer `UserProfile(...)` constructor and removed now-redundant inner `const` keywords
- **Files modified:** `test/features/profile_screen_calendar_test.dart`
- **Verification:** `flutter analyze test/features/profile_screen_calendar_test.dart` reports "No issues found!"
- **Committed in:** `98f1f3b` (Task 2 GREEN commit)

**2. [Rule 1 - Bug] Test viewport too small to mount the new ListTile**
- **Found during:** Task 2 verification — `flutter test test/features/profile_screen_calendar_test.dart` failed with "Found 0 widgets with text 'Google Agenda'" even with `skipOffstage: false`
- **Issue:** `debugDumpApp()` investigation showed the Element tree stopped mounting children partway through the OVER section — the default 600px-tall test viewport combined with the sliver `ListView`'s viewport-based lazy mounting meant the new row (positioned after RIJLENGTE, the availability-calendar link, and NAAM sections) was never built, regardless of `skipOffstage`
- **Fix:** Set `tester.view.physicalSize = const Size(800, 3000)` (with `devicePixelRatio = 1.0` and `addTearDown(tester.view.reset)`) before pumping, so the entire ListView content fits within the viewport and gets mounted
- **Files modified:** `test/features/profile_screen_calendar_test.dart`
- **Verification:** Both new tests pass standalone (`flutter test test/features/profile_screen_calendar_test.dart` → "All tests passed!")
- **Committed in:** `98f1f3b` (Task 2 GREEN commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs in the new test file itself, not the plan's production code)
**Impact on plan:** No scope creep. Both fixes were necessary for the plan's own new test to correctly exercise the behavior it was written to prove; production code (`CalendarService`, `ProfileScreen`, l10n) was implemented exactly per the plan's interface spec.

## Issues Encountered

**Pre-existing test-suite failures unrelated to this plan** (logged to `deferred-items.md`, not fixed — out of scope per SCOPE BOUNDARY):
- `test/features/profile_screen_notif_test.dart` fails on its own (Test 5: `Bad state: No element` inside `scrollUntilVisible`), and fails further (Tests 1-4: `Null check operator used on a null value` in `S.of(context)`) when run in the same `flutter test` invocation as other Profile screen test files.
- Confirmed via `git stash` bisection that these failures are 100% pre-existing: they reproduce identically on the codebase state *before* any of this plan's changes to `profile_screen.dart` or the l10n files.
- `test/features/ride_detail_screen_test.dart` also shows 13 pre-existing failures standalone, further indicating a project-wide test-suite health issue (likely Flutter SDK drift since these tests were authored) unrelated to backlog #36.
- Per the plan's verify command, `flutter test test/features/profile_screen_calendar_test.dart test/features/profile_screen_location_test.dart test/features/profile_screen_notif_test.dart` was run exactly as specified: the 2 new calendar tests pass, all 9 pre-existing location tests pass, and only the 5 pre-existing (confirmed unrelated) notif tests fail — proving no regression from the new `initState()` call.

## User Setup Required

None - no external service configuration required. `CalendarService`'s Google Sign-In OAuth client setup was already completed in Phase 9.

## Next Phase Readiness

Backlog #36 is complete. The Google Calendar connection is now visible and manageable from the Profile screen. No blockers for future work. Recommend a separate quick task or phase to investigate the pre-existing Profile screen test-suite flakiness noted in `deferred-items.md` before it accumulates further.

---
*Phase: quick-260714-nfk*
*Completed: 2026-07-14*

## Self-Check: PASSED

All created files verified present; all task commit hashes (`ce0afd7`, `1937da1`, `98f1f3b`) verified present in `git log`.
