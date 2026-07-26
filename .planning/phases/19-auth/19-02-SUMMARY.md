---
phase: 19-auth
plan: 02
subsystem: auth
tags: [google_sign_in, supabase, oauth, calendar]

# Dependency graph
requires:
  - phase: 09-google-calendar-integration
    provides: CalendarService's memoized GoogleSignIn init gate (_sharedInitialize/_initFuture), CAL-06 web warmup pattern
provides:
  - "_sharedInitialize() passes serverClientId to GoogleSignIn.instance.initialize(), so Supabase's signInWithIdToken can verify the ID token's audience claim (PITFALLS.md #3)"
  - "Public static CalendarService.ensureGoogleSignInReady() entry point to the shared init gate, for use by future auth UI (Plan 19-03) and mismatch checks (Plan 19-05) without a second initialize() call site"
affects: [19-03, 19-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single memoized static init gate (_sharedInitialize/_initFuture) shared across unrelated features (Calendar + Auth) via one private implementation and multiple public entry points (warmUpForWeb, ensureGoogleSignInReady) — never call GoogleSignIn.instance.initialize() from anywhere else"

key-files:
  created: []
  modified:
    - lib/services/calendar_service.dart

key-decisions:
  - "_kGoogleWebClientId defined as a private static const near the file's other static state (not inlined), matching the file's existing style of named static fields for shared singleton state"
  - "ensureGoogleSignInReady() is a one-line delegate to the still-private _sharedInitialize() -- keeps _initFuture/_initialized private while giving other files a public, safe entry point"

patterns-established:
  - "Shared init gate pattern: when two unrelated features (Calendar OAuth, Supabase Auth) both need the same underlying singleton initialized exactly once, expose one memoized private gate and multiple public named wrappers rather than duplicating init logic or relaxing the private/public boundary"

requirements-completed: [AUTH-05, REG-04]

# Metrics
duration: ~15min
completed: 2026-07-26
---

# Phase 19 Plan 02: Shared GoogleSignIn Init Gate Carries serverClientId Summary

**`_sharedInitialize()` now passes `serverClientId` to `GoogleSignIn.instance.initialize()` so Supabase can verify Google ID token audience, plus a new public `CalendarService.ensureGoogleSignInReady()` wrapper for auth code to share the same memoized gate.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-07-26T07:50:47Z
- **Tasks:** 2 completed
- **Files modified:** 1

## Accomplishments
- Added `serverClientId: _kGoogleWebClientId` to the single existing `GoogleSignIn.instance.initialize()` call in `_sharedInitialize()`, using the exact web OAuth client ID already embedded in `web/index.html`'s `google-signin-client_id` meta tag (byte-for-byte verified via `grep -o` comparison)
- Introduced a new public static `CalendarService.ensureGoogleSignInReady()` method as the sanctioned entry point for other files (Plan 19-03's account UI, Plan 19-05's mismatch check) to trigger the shared init without duplicating or bypassing the memoized gate
- Verified zero regression: both existing Calendar test files pass, the full 306-test suite remains 306/306 green, and `flutter analyze` reports no new issues

## Task Commits

Each task was committed atomically:

1. **Task 1: Add serverClientId to _sharedInitialize() and expose a public entry point** - `11a1845` (feat)
2. **Task 2: Confirm no regression in existing Calendar tests and coverage** - no commit (verification-only, zero file changes as anticipated by the plan)

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified
- `lib/services/calendar_service.dart` - Added `_kGoogleWebClientId` private const, added `serverClientId:` to the `GoogleSignIn.instance.initialize()` call inside `_sharedInitialize()`, added public `ensureGoogleSignInReady()` wrapper, updated the file header comment to note AUTH-05. `addRideSlotToCalendar`, `getEvents`, `isCalendarConnected`, `disconnectCalendar` are textually unchanged (confirmed via `git diff`).

## Decisions Made
- Kept `_kGoogleWebClientId` as a single named constant (not inlined) next to the file's other static shared-init state, per the plan's explicit style guidance.
- `ensureGoogleSignInReady()` is intentionally a thin one-line delegate — no new logic, no new error handling — since `_sharedInitialize()`'s existing memoization/error-reset behavior already covers every caller correctly.

## Deviations from Plan

### Auto-fixed / Adjusted

**1. [Documentation correction, no code impact] Acceptance criterion's literal `grep -c` command does not isolate real call sites**
- **Found during:** Task 1 verification
- **Issue:** The plan's acceptance criterion states `grep -c "GoogleSignIn.instance.initialize(" lib/services/calendar_service.dart` should return exactly `1`. Verified against the pre-existing file (before any change in this plan) that this literal grep already returned `3` — two of the three matches are inside pre-existing doc comments (lines discussing the "Bad state: init() has already been called" bug and the CAL-06 warmup doc-comment), not real invocations. This is a pre-existing property of the file, not something this plan introduced.
- **Verification performed instead:** Confirmed the semantic invariant the criterion is actually protecting — there is exactly **one** real invocation of `GoogleSignIn.instance.initialize(...)` in the entire codebase, inside `_sharedInitialize()` (now `GoogleSignIn.instance.initialize(serverClientId: _kGoogleWebClientId)`). No other file, and no other location in this file, calls `GoogleSignIn.instance.initialize()` directly. `ensureGoogleSignInReady()` delegates to `_sharedInitialize()` rather than duplicating the call.
- **Files modified:** None (verification-only finding)
- **Impact:** None on correctness — the hard constraint (single call site) holds; only the literal grep command in the plan's acceptance criteria was imprecise given pre-existing doc-comment text.

---

**Total deviations:** 1 (documentation-only, no behavior or scope change)
**Impact on plan:** None on functionality. The underlying invariant (exactly one real `GoogleSignIn.instance.initialize()` call site) is verified and holds.

## Issues Encountered
None beyond the acceptance-criteria note above.

## User Setup Required
None - no external service configuration required. (The Supabase project itself and its OAuth client wiring are handled in Plan 19-01, which is separately paused at a human-action credential checkpoint and out of scope for this plan.)

## Next Phase Readiness
- `CalendarService.ensureGoogleSignInReady()` is ready for Plan 19-03 (account sign-in UI) and Plan 19-05 (client ID mismatch check) to call directly — neither needs to touch `calendar_service.dart` again.
- The shared init gate carries `serverClientId` end-to-end now, so once Plan 19-01's Supabase bootstrap is unblocked, `signInWithIdToken` on the resulting Google ID token will present the correct `aud` claim.
- No blockers identified for downstream plans in this phase.

---
*Phase: 19-auth*
*Completed: 2026-07-26*

## Self-Check: PASSED

- FOUND: lib/services/calendar_service.dart
- FOUND: .planning/phases/19-auth/19-02-SUMMARY.md
- FOUND: commit 11a1845 (Task 1)
- FOUND: commit f5bd818 (metadata)
