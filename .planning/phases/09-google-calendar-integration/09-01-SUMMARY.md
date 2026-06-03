---
phase: 09-google-calendar-integration
plan: "01"
subsystem: calendar-integration
tags: [google-calendar, oauth, google-sign-in, flutter]
dependency_graph:
  requires: []
  provides: [CalendarService, calendar-button-wired]
  affects: [lib/features/detail/ride_detail_screen.dart]
tech_stack:
  added:
    - google_sign_in ^7.2.0
    - extension_google_sign_in_as_googleapis_auth ^3.0.0
    - googleapis ^16.0.0
  patterns:
    - GoogleSignIn 7.x singleton with lazy initialize()
    - authorizationClient.authorizeScopes() + authClient() extension
    - StatefulWidget with _isLoading guard for async button
key_files:
  created:
    - lib/services/calendar_service.dart
  modified:
    - pubspec.yaml
    - android/app/src/main/AndroidManifest.xml
    - lib/features/detail/ride_detail_screen.dart
decisions:
  - "GoogleSignIn 7.x uses singleton GoogleSignIn.instance (no constructor) — lazy-initialized via static _initialized flag"
  - "extension_google_sign_in_as_googleapis_auth 3.0.0 extension is now on GoogleSignInClientAuthorization (not GoogleSignIn) — authClient(scopes:) method"
  - "authorizeScopes() replaces old signIn() flow; GoogleSignInException.canceled covers user-cancel case"
  - "CalendarService instantiated per button-tap in onPressed (not in initState or build) — satisfies CAL-02"
metrics:
  duration: ~20min
  completed_date: "2026-06-03"
  tasks_completed: 2
  files_modified: 4
---

# Phase 9 Plan 01: Google Calendar Integration Summary

**One-liner:** Google Calendar integration via GoogleSignIn 7.x singleton with on-demand OAuth scope authorization and googleapis CalendarApi event insert.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Google Cloud setup (checkpoint — skipped by user) | — | — |
| 2 | Add three Google Calendar deps + INTERNET permission | b9f4ceb | pubspec.yaml, pubspec.lock, AndroidManifest.xml |
| 3 | Write CalendarService + wire RideDetailScreen | 123801b | lib/services/calendar_service.dart, lib/features/detail/ride_detail_screen.dart |

## What Was Built

**lib/services/calendar_service.dart** — CalendarService class with:
- `addRideSlotToCalendar(RideSlot, List<HourlyForecast>)` method
- Lazy `GoogleSignIn.instance.initialize()` via static `_initialized` flag (CAL-02)
- `authorizeScopes([CalendarApi.calendarEventsScope])` — minimal scope (CAL-04)
- `authClient(scopes:)` extension for authenticated HTTP client (T-09-01-01: closed in finally)
- Weather summary built from avg temp, total precip, avg wind (CAL-03)
- Event title: "Fietsrit HH:MM–HH:MM"; inserts into 'primary' calendar (CAL-01, CAL-05)

**lib/features/detail/ride_detail_screen.dart** — Converted to StatefulWidget:
- `_isLoading` state variable guards concurrent taps
- Button shows `CircularProgressIndicator` during loading, disabled until complete
- `CalendarService()` instantiated only in `onPressed` callback (CAL-02)
- Success/error SnackBar messages in Dutch

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] google_sign_in 7.x API is completely different from plan specification**
- **Found during:** Task 3 — `dart analyze` after first implementation
- **Issue:** Plan specified `GoogleSignIn(scopes: [...])` constructor, `signIn()` method, and `authenticatedClient()` on GoogleSignIn. In google_sign_in 7.x the constructor is private (`GoogleSignIn._()`) — only `GoogleSignIn.instance` works. `signIn()` and `authenticatedClient()` no longer exist. The extension method `authClient()` is now on `GoogleSignInClientAuthorization`, not on `GoogleSignIn`.
- **Fix:** Used `GoogleSignIn.instance` singleton, lazy `initialize()` with static flag, `authorizationClient.authorizeScopes([scope])` returning `GoogleSignInClientAuthorization`, then `authorization.authClient(scopes: [scope])` for the HTTP client. `GoogleSignInException.canceled` covers user-cancel path.
- **Files modified:** lib/services/calendar_service.dart
- **Commit:** 123801b

## Pending: Google Cloud Setup Required

**Task 1 was skipped by user ("overslaan").** The code is complete and will compile, but the OAuth flow will NOT work until the Google Cloud setup is completed:

1. Create a Google Cloud project at console.cloud.google.com
2. Enable the Google Calendar API (APIs & Services → Library)
3. Configure OAuth consent screen (External, test mode, add test users)
4. Add scope: `https://www.googleapis.com/auth/calendar.events`
5. Create Android OAuth 2.0 client ID (package name from AndroidManifest + SHA-1 fingerprint)
   - SHA-1: `cd /Users/joostmouw/ridewindow/android && ./gradlew signingReport | grep SHA1`
   - No JSON download needed for Android OAuth — client ID is embedded via package name + SHA-1

## Known Stubs

None. The calendar button is fully wired. Feature is end-to-end complete pending Google Cloud setup.

## Threat Flags

No new threat surface beyond what was documented in the plan's threat model. All mitigations applied:
- T-09-01-01: `client.close()` in finally block
- T-09-01-02: Only `CalendarApi.calendarEventsScope` requested
- T-09-01-04: Standard Google Sign-In consent screen used

## Self-Check: PASSED

- [x] lib/services/calendar_service.dart exists
- [x] lib/features/detail/ride_detail_screen.dart modified (StatefulWidget)
- [x] pubspec.yaml has three new deps
- [x] AndroidManifest.xml has INTERNET permission
- [x] Commit b9f4ceb exists (Task 2)
- [x] Commit 123801b exists (Task 3)
- [x] dart analyze lib/: No issues found
