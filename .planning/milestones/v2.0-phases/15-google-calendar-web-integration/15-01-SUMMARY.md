---
phase: 15-google-calendar-web-integration
plan: 01
subsystem: auth
tags: [google_sign_in, google_sign_in_web, oauth, flutter-web, calendar, riverpod-none]

# Dependency graph
requires:
  - phase: 09-google-calendar-integration
    provides: "CalendarService (Android-shaped OAuth call chain: bare GoogleSignIn.instance.authorizationClient.authorizeScopes(), no authenticate()/renderButton()) and its lazy _ensureInitialized() pattern (CAL-02), reused unmodified on web"
provides:
  - "CalendarService.warmUpForWeb(): idempotent, concurrency-safe eager GoogleSignIn.instance warmup for web, memoized behind a shared static Future<void>? _initFuture"
  - "main.dart: kIsWeb-gated eager warmup call after runApp(), removing the async gap before authorizeScopes() that Safari's popup blocker rejects"
  - "web/index.html: real Web OAuth Client ID wired into a google-signin-client_id meta tag (google_sign_in_web's runtime bootstrap mechanism)"
  - "Manually-verified proof that the existing scope-only authorizeScopes() flow opens a real Chrome popup and creates a real Google Calendar event on http://localhost:5000"
affects: [15-02-google-calendar-web-integration-production-deploy, calendar-service, main-dart]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared static Future<void>? memoization for a singleton's async init() call, to make two independent call sites (eager web warmup + lazy on-tap init) safely concurrency-compatible instead of racing to call a non-reentrant native init() twice"
    - "kIsWeb-gated inverse-guard block in main.dart, placed after runApp(), mirroring the existing !kIsWeb WorkManager guard"

key-files:
  created:
    - test/web/index_html_meta_tag_test.dart
  modified:
    - lib/services/calendar_service.dart
    - lib/main.dart
    - web/index.html
    - test/services/calendar_service_test.dart

key-decisions:
  - "Web OAuth Client ID created in a NEW Google Cloud project, not the Phase 9 Android project as originally planned — Phase 9's Android OAuth client was never actually registered/completed, so there was no existing project to reuse. Android and Web OAuth clients now live in separate GCP projects; flag for any future Android Calendar OAuth work."
  - "GoogleSignIn.instance.initialize() calls memoized behind a shared static Future<void>? _initFuture (not the plain _initialized boolean alone) so warmUpForWeb() and _ensureInitialized() can safely run concurrently without both invoking the plugin's non-reentrant initialize() at once."
  - "OAuth consent screen left in Testing publish status with only the developer as a test user — publishing/verifying for other users is explicitly out of this plan's scope (tracked as backlog item #31)."

patterns-established:
  - "Memoized in-flight Future<void>? guard pattern for any future singleton-init race between an eager warmup path and a lazy on-demand path."

requirements-completed: [CAL-06]

# Metrics
duration: ~35min active execution across 2 sessions (paused at Task 1's human-action checkpoint and Task 3's human-verify checkpoint, including one bugfix round-trip after manual verification surfaced a race condition)
completed: 2026-07-14
---

# Phase 15 Plan 01: Web-only Google Calendar OAuth warmup + first Chrome popup proof Summary

**CalendarService.warmUpForWeb() eagerly and safely warms GoogleSignIn.instance on web (memoized against a real concurrency race found during manual testing), wired via a real Web OAuth Client ID in web/index.html — manually verified end-to-end against a real Google account creating a real Calendar event on http://localhost:5000.**

## Performance

- **Duration:** ~35min active execution, spread across two sessions separated by two human checkpoints (Task 1's Google Cloud Console setup, Task 3's Chrome manual verification — including one round of bugfix-and-reverify after the first manual verification attempt surfaced a real race condition)
- **Started:** 2026-07-13 (Task 1 checkpoint)
- **Completed:** 2026-07-14
- **Tasks:** 3/3 complete
- **Files modified:** 4 modified, 1 created

## Accomplishments
- Resolved RESEARCH.md's single biggest open question (Assumption A1): the existing Android-shaped, scope-only `authorizeScopes()` OAuth flow does open a real Chrome popup on web and does create a real Google Calendar event — no FedCM-specific code, no `authenticate()`/`renderButton()` rework needed.
- Fixed the one already-diagnosed Safari-breaking bug at the source: `CalendarService.warmUpForWeb()` eagerly initializes `GoogleSignIn.instance` on web (called from `main.dart` after `runApp()`), so by the time a user taps "Add to calendar," `_ensureInitialized()` is a no-op and `authorizeScopes()` is the first and only awaited call in the tap's call chain.
- Found and fixed a genuine concurrency bug during manual verification: a fast tap could race the eager warmup and trigger two simultaneous `GoogleSignIn.instance.initialize()` calls, which the plugin rejects with "Bad state: init() has already been called." Fixed by memoizing the init call behind a shared `Future<void>? _initFuture` so both call sites await the same underlying call.
- Native Android's Phase 9 `CalendarService` behavior (`addRideSlotToCalendar()`, `getEvents()`, `_ensureInitialized()`'s always-lazy CAL-02 timing) is unchanged; `flutter build apk --release` still exits 0.

## Task Commits

Each task/gate was committed atomically:

1. **Task 1: Create the Web OAuth Client ID in Google Cloud Console (CAL-06)** — human-action checkpoint, no commit (external Google Cloud Console configuration only)
2. **Task 2 (RED): Failing tests for `warmUpForWeb()` + index.html meta tag** — `a18f7f4` (test)
3. **Task 2 (GREEN): `CalendarService.warmUpForWeb()` + `main.dart` wiring + real client ID in `web/index.html`** — `2bfe4d5` (feat)
4. **Task 2 bugfix (deviation): Memoized `_initFuture` fixes concurrent "Bad state" crash** — `909d108` (fix)
5. **Task 3: Chrome dev-server spike (automated half: `flutter build apk --release`)** — no commit (verification-only, exit 0)
6. **Task 3: Chrome dev-server spike (manual half)** — user-confirmed "approved" after two Google Cloud Console gaps were resolved (see Deviations); no code commit (verification-only)

**Plan metadata:** this commit (docs: complete plan)

_TDD note: Task 2 followed the full RED → GREEN cycle (`a18f7f4` → `2bfe4d5`); the bugfix (`909d108`) is a Rule 1 bugfix found post-verification, itself following the same test-then-fix discipline (regression test added alongside the fix, both committed together)._

## Files Created/Modified
- `lib/services/calendar_service.dart` — Added `CalendarService.warmUpForWeb()` (web-only eager warmup, CAL-06) and a shared, memoized `_sharedInitialize()` helper (`static Future<void>? _initFuture`) used by both `warmUpForWeb()` and `_ensureInitialized()` to prevent concurrent double-init crashes. `addRideSlotToCalendar()`/`getEvents()` bodies unchanged.
- `lib/main.dart` — Added `import 'package:ridewindow/services/calendar_service.dart';` and a `kIsWeb`-gated `await CalendarService.warmUpForWeb();` call after `runApp()`, structural inverse of the existing `!kIsWeb` WorkManager guard.
- `web/index.html` — Added `<meta name="google-signin-client_id" content="300023366326-ddo399qf5lavv48njbfpm7rg0mc8cnno.apps.googleusercontent.com">`, the real Web OAuth Client ID created in Task 1.
- `test/services/calendar_service_test.dart` — Added `group('CalendarService.warmUpForWeb (CAL-06)')` with 3 tests: completes-without-throwing, idempotent double-call, and a concurrency regression test proving two un-awaited concurrent calls never surface a "Bad state" double-init exception.
- `test/web/index_html_meta_tag_test.dart` (new) — Asserts `web/index.html` contains a real `google-signin-client_id` meta tag with a `.apps.googleusercontent.com` value and no unreplaced placeholder string.

## Decisions Made
- **New Google Cloud project instead of reusing Phase 9's Android project.** The plan assumed Phase 9's Android `google_sign_in` OAuth client already existed in a registered project to reuse. During Task 1, the user discovered that setup was never actually completed/registered — there was no existing project to reuse. A fresh project was created instead, with the Calendar API enabled, an OAuth consent screen configured (External, developer added as test user, `calendar.events` scope), and the Web OAuth Client ID created there. Android's and Web's OAuth clients now live in separate GCP projects — worth flagging before any future Android Calendar OAuth maintenance work, though it does not affect this plan's correctness (the client ID is a public, non-secret identifier scoped by Google's own Authorized JavaScript origins allowlist).
- **Memoized `Future<void>?` guard over a plain boolean for singleton init.** `_initialized` alone was insufficient once there were two independent call sites (eager web warmup, lazy on-tap init) that could both observe `_initialized == false` and both call the non-reentrant `GoogleSignIn.instance.initialize()`. Introduced `static Future<void>? _initFuture` so all callers share and await the exact same underlying init call; cleared to `null` on failure so a later attempt can still retry, preserving the pre-existing "a failed init/warmup is not fatal" semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 4-adjacent, user-directed re-scope] New Google Cloud project instead of reusing Phase 9's Android project**
- **Found during:** Task 1 (Google Cloud Console OAuth client creation)
- **Issue:** Plan's Task 1 assumed an existing, registered Google Cloud project from Phase 9's Android `google_sign_in` setup to reuse (per RESEARCH.md's "one client ID with multiple authorized origins" recommendation). That setup was never actually completed/registered.
- **Resolution:** User created a new project, enabled the Google Calendar API, configured the OAuth consent screen (External, developer as test user, `calendar.events` scope), and created the Web OAuth Client ID there. This is a scope/assumption correction directed by the user during the checkpoint, not an autonomous code fix — no code changes resulted from this, only the client ID value used in `web/index.html`.
- **Files modified:** `web/index.html` (client ID value only — same file/line the plan specified)
- **Verification:** Client ID confirmed to match the `*.apps.googleusercontent.com` pattern; `http://localhost:5000` confirmed registered as an Authorized JavaScript origin.
- **Committed in:** `2bfe4d5`

**2. [Rule 1 - Bug] Concurrent GoogleSignIn.initialize() calls crash with "Bad state"**
- **Found during:** Task 3 (first manual verification attempt)
- **Issue:** `warmUpForWeb()` and `_ensureInitialized()` both guarded only on the `_initialized` boolean, not the in-flight `initialize()` call. A fast tap on "Add to calendar" (before the eager web warmup's `await` resolved) caused both code paths to see `_initialized == false` and both call `GoogleSignIn.instance.initialize()` concurrently. The plugin throws `Bad state: init() has already been called. Calling init() more than once results in undefined behavior.` on the second concurrent call, surfaced to the user as "Could not add: Bad state: ...".
- **Fix:** Introduced a shared, memoized `static Future<void>? _initFuture` via a new private `_sharedInitialize()` helper. Both `warmUpForWeb()` and `_ensureInitialized()` now await the same underlying future instead of each starting their own. The future is cleared to `null` on failure so a later call can still retry (preserving the existing non-fatal-failure semantics).
- **Files modified:** `lib/services/calendar_service.dart`, `test/services/calendar_service_test.dart` (added a concurrency regression test)
- **Verification:** `flutter test test/services/calendar_service_test.dart test/web/index_html_meta_tag_test.dart` — 10/10 pass, including the new regression test proving two un-awaited concurrent `warmUpForWeb()` calls never surface a double-init exception. `flutter analyze` on touched files reports zero new errors. User re-ran the manual Chrome verification afterward and confirmed the popup opens and the flow completes correctly on a fast tap.
- **Committed in:** `909d108`

---

**Total deviations:** 2 (1 user-directed scope correction during a checkpoint, 1 Rule 1 auto-fixed bug found during manual verification)
**Impact on plan:** Both were necessary corrections discovered exactly where the plan intended to surface them (Task 1's real-world setup, Task 3's real-world manual verification). No scope creep — no code beyond what CAL-06 required was touched.

## Issues Encountered
- **Two Google Cloud Console configuration gaps hit during the first manual verification attempt (not code issues):** (1) the Google Calendar API was not yet enabled on the new project and had to be manually enabled, and (2) the developer's own Google account had to be explicitly added as an OAuth consent screen test user, since the consent screen is in "Testing" publish status (not yet public/verified). Both were resolved directly in the Google Cloud Console by the user; no code changes were needed. **Carry-forward:** the OAuth consent screen still needs to be published or fully verified before any user other than the developer can use the Calendar feature on web — this is explicitly out of this plan's scope and has been logged as **backlog item #31** for a future phase/plan to address (likely alongside 15-02's production deployment work, since Google's verification review typically requires a live production domain).
- **`android/key.properties` missing in the worktree** (environment-only, no code deviation): this file is gitignored and was never copied into the git worktree by `git worktree add` (which only checks out tracked files). It blocked `flutter build apk --release` with a Gradle Kotlin-cast error until the existing, already-present-on-machine `key.properties` was copied in from the main checkout. No git-tracked files were touched; the copy remains gitignored in the worktree.

## User Setup Required

None further for this plan — the Web OAuth Client ID is created and wired in, and the flow has been manually verified end-to-end by the developer. See "Issues Encountered" above for the carried-forward OAuth consent screen publish/verification work (backlog item #31), which is out of this plan's scope.

## Next Phase Readiness
- Plan 15-02 (production deployment to the real Firebase Hosting domain, real iPhone Safari, CAL-07) can proceed — this plan de-risked the core mechanism (scope-only `authorizeScopes()` does open a popup and create events on web) and fixed the one real Safari-breaking async-gap bug plus the concurrency bug it exposed.
- Carry forward to Plan 15-02 or a later phase: the Authorized JavaScript origins list on the Web OAuth Client ID currently only contains `http://localhost:5000` — the real production Firebase Hosting origin will need to be added once that domain exists (out of this plan's scope per the plan's own framing note).
- Carry forward: OAuth consent screen publish/verification (backlog item #31) — needed before any user besides the developer can use the Calendar feature.

---
*Phase: 15-google-calendar-web-integration*
*Completed: 2026-07-14*

## Self-Check: PASSED

All created/modified files confirmed present (`lib/services/calendar_service.dart`, `lib/main.dart`, `web/index.html`, `test/services/calendar_service_test.dart`, `test/web/index_html_meta_tag_test.dart`, this SUMMARY.md). All referenced commit hashes confirmed in `git log` (`a18f7f4`, `2bfe4d5`, `909d108`).
