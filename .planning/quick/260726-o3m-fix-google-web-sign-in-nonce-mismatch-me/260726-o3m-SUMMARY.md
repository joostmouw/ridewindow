---
phase: quick-260726-o3m
plan: 01
subsystem: auth
tags: [google-sign-in, supabase, nonce, oidc, crypto, sha256]

# Dependency graph
requires:
  - phase: 19-auth
    provides: CalendarService's gememoized _sharedInitialize() gate (AUTH-05), account_section.dart's _handleSignInSuccess() shared completion path
provides:
  - CalendarService.authNonce (raw, per-app-run CSPRNG nonce) + CalendarService.hashNonce() (SHA-256 hex, testable)
  - signInWithIdToken(nonce:) wired so Supabase's nonce-mismatch 400 is fixed on web
  - Web sign-in no longer attempts a doomed authorizeScopes() popup outside a user gesture
affects: [phase-19-auth remaining plans, any future OIDC provider wiring]

# Tech tracking
tech-stack:
  added: ["crypto ^3.0.7 (promoted from transitive to direct dependency)"]
  patterns: ["Static-final CSPRNG nonce generated once per app run, shared between Google's initialize(nonce: hash) and Supabase's signInWithIdToken(nonce: raw)"]

key-files:
  created: []
  modified:
    - pubspec.yaml
    - lib/services/calendar_service.dart
    - test/services/calendar_service_test.dart
    - lib/features/profile/account_section.dart

key-decisions:
  - "Raw nonce goes to Supabase signInWithIdToken(nonce:); SHA-256 hex of that same raw value goes to Google's initialize(nonce:) -- verified against gotrue 2.26.0 and google_sign_in 7.2.0 source, and cross-checked both hash vectors with `shasum -a 256` before committing"
  - "Nonce generated exactly once per app run via static final field (Dart's static-final semantics give lazy, one-time init) -- required because _sharedInitialize() is itself memoized and only calls Google's initialize() once per run"
  - "Web-only gating of authorizeScopes() prompting fallback uses the widget's existing _supportsNativeAuthenticate field (D-06's signal) rather than a new kIsWeb check, per the plan's interfaces block"

patterns-established:
  - "OIDC nonce pairing: raw value to the token-verifying party (Supabase), hash of that raw value to the token-issuing party (Google) -- documented in calendar_service.dart's file header for future OAuth providers"

requirements-completed: [O3M-01, O3M-02]

# Metrics
duration: 20min
completed: 2026-07-26
---

# Phase quick-260726-o3m Plan 01: Fix Google web sign-in nonce mismatch Summary

**CalendarService now generates one CSPRNG nonce per app run, feeding its raw value to Supabase's `signInWithIdToken(nonce:)` and its SHA-256 hash to Google's `initialize(nonce:)`, while the web sign-in path no longer attempts a browser-blocked `authorizeScopes()` popup outside a user gesture.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-26T15:09:00Z (approx)
- **Completed:** 2026-07-26T15:29:56Z
- **Tasks:** 2 of 3 (Task 3 is an open blocking human-verify checkpoint, see below)
- **Files modified:** 4

## Accomplishments
- `CalendarService.authNonce` (public, raw) and `CalendarService.hashNonce()` (public, testable, pure) added; `_sharedInitialize()` now passes `nonce: hashNonce(_rawNonce)` to `GoogleSignIn.instance.initialize()` -- still the only call site in the codebase (AUTH-05 verified via repo-wide grep)
- `crypto` promoted from a transitive to a direct `pubspec.yaml` dependency, mirroring the existing `google_sign_in_web` precedent
- `account_section.dart`'s `_handleSignInSuccess()` now passes `nonce: CalendarService.authNonce` to `Supabase.instance.client.auth.signInWithIdToken(...)` -- this is the actual fix for the reported 400 (O3M-01)
- The prompting `authorizeScopes(['email'])` fallback is now gated to the native/Android branch only (`_supportsNativeAuthenticate == true`); on web, when `authorizationForScopes` returns `null`, `accessToken` stays `null` and the doomed popup call is skipped (O3M-02)
- 4 new unit tests added for `hashNonce()`/`authNonce`, using known SHA-256 vectors independently verified via `shasum -a 256` on this machine before committing

## Task Commits

Each task was committed atomically:

1. **Task 1: Genereer en ontsluit een stabiele auth-nonce in CalendarService** - `6572e82` (fix)
2. **Task 2: Wire de nonce door signInWithIdToken en onderdruk de web-popup** - `a9d90a9` (fix)

**Plan metadata:** _(to be committed after this SUMMARY)_

Task 3 (`checkpoint:human-verify`, `gate="blocking"`) was **not executed** -- see "Open Blocking Checkpoint" below.

## Files Created/Modified
- `pubspec.yaml` - `crypto: ^3.0.7` added as a direct dependency with explanatory comment
- `lib/services/calendar_service.dart` - `authNonce`/`hashNonce()` added; `_sharedInitialize()` now passes `nonce: hashNonce(_rawNonce)` to Google's `initialize()`; file-header comment updated to explain the raw-to-Supabase / hash-to-Google direction
- `test/services/calendar_service_test.dart` - new `group('CalendarService.hashNonce (quick 260726-o3m nonce-fix)', ...)` with 4 tests (2 known-vector, 1 stability, 1 shape)
- `lib/features/profile/account_section.dart` - `signInWithIdToken(nonce: CalendarService.authNonce)`; `authorizeScopes` fallback now gated behind `_supportsNativeAuthenticate`

## Decisions Made
- Verified the nonce direction against the actual pub-cache source before writing any code: `gotrue-2.26.0/lib/src/gotrue_client.dart` sends `nonce` as-is in the token-exchange body (raw value expected), `google_sign_in-7.2.0/lib/google_sign_in.dart`'s `initialize(nonce:)` passes straight through to the platform `InitParameters` (expects the hash per Google's own OIDC nonce convention). Cross-checked both SHA-256 test vectors (`'test'` and `''`) with `shasum -a 256` locally before committing them into the test file, to rule out transposing raw/hash by accident -- this was called out explicitly as a correctness risk in the task instructions.
- No architectural changes were needed; both plumbing gaps (Google's `nonce` param, Supabase's `nonce` param) already existed in the installed package versions per the plan's `<interfaces>` block -- this plan was purely wiring.

## Deviations from Plan

None - plan executed exactly as written for Task 1 and Task 2.

## Issues Encountered

None. `flutter pub get`, both `flutter test` targets, and `flutter analyze` (both scoped and full-repo) all passed on the first attempt for both tasks.

## Open Blocking Checkpoint

**Task 3 was intentionally NOT executed** by this executor run, per explicit instruction. It is `type="checkpoint:human-verify"` with `gate="blocking"` and requires a real browser, a real Google OAuth popup, and a real Supabase auth server -- none of which are available in this automated execution context.

**What remains to close this plan:**

1. `flutter build web --release`
2. `firebase deploy --only hosting`
3. Open https://my-project-joost.web.app with DevTools console open (Network + Console tabs)
4. Click "Inloggen met Google", complete the Google sign-in popup
5. Confirm: no `400` on `POST .../auth/v1/token?grant_type=id_token`, no "Passed nonce and nonce in id_token should either both exist or not" console error, Account section switches to signed-in row
6. Confirm: no "[GSI_LOGGER]: Failed to open popup window" / `GoogleSignInExceptionCode.uiUnavailable` during the same sign-in
7. Refresh the page once, confirm the session persists

This plan's status is **NOT complete** until Task 3 is manually verified by Joost against the redeployed PWA. The code changes (Task 1 + Task 2) are committed and verified by the automated test suite, but the actual nonce-hash comparison only happens server-side at Supabase, and the popup-blocking behavior only manifests in a real browser -- neither can be proven by `flutter test`/`flutter analyze` alone.

## Threat Flags

None. Both bugs fixed (O3M-01, O3M-02) were already scoped in this plan's `<threat_model>` (O3M-T-01 spoofing/replay mitigation, O3M-T-03 DoS/noise mitigation); no new trust-boundary-crossing surface was introduced.

## User Setup Required

None - no external service configuration required for Tasks 1-2. Task 3 requires Joost to run the two deploy commands listed above (not scriptable from this environment per the plan's own note: "this repo has no scripted deploy target beyond the two standalone commands").

## Next Phase Readiness

- Task 1 + Task 2 are code-complete, committed, and pass all automated verification.
- **Blocker:** Task 3's human-verify checkpoint against the real deployed PWA is still open. Do not mark this quick task fully done, and do not build further work on top of "Google web sign-in works" until Task 3 is confirmed.
- Once Task 3 is confirmed (or reveals a remaining issue), a fresh continuation should be spawned to close out the plan (finalize STATE.md/ROADMAP.md, requirements O3M-01/O3M-02 mark-complete, final metadata commit).

---
*Phase: quick-260726-o3m*
*Completed (Tasks 1-2 only): 2026-07-26*

## Self-Check: PASSED

- FOUND: lib/services/calendar_service.dart
- FOUND: lib/features/profile/account_section.dart
- FOUND: test/services/calendar_service_test.dart
- FOUND: pubspec.yaml
- FOUND commit 6572e82 (Task 1)
- FOUND commit a9d90a9 (Task 2)
