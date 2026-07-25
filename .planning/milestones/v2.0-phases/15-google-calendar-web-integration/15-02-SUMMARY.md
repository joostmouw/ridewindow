---
phase: 15-google-calendar-web-integration
plan: 02
subsystem: infra
tags: [firebase-hosting, firebase-cli, google-oauth, flutter-web, deployment]

# Dependency graph
requires:
  - phase: 15-google-calendar-web-integration (Plan 01)
    provides: "CalendarService.warmUpForWeb() eager OAuth warmup, Web OAuth Client ID (300023366326-ddo399qf5lavv48njbfpm7rg0mc8cnno.apps.googleusercontent.com) wired into web/index.html, manually verified against localhost:5000"
provides:
  - "Live Firebase Hosting deployment at https://my-project-joost.web.app serving the built Flutter web app"
  - "firebase.json: preliminary/non-hardened hosting config (build/web public dir, SPA rewrite for go_router, *.wasm Content-Type header) -- Phase 17 (DEPLOY-01/02) extends this file, does not replace it"
  - ".firebaserc: default project pointer to my-project-joost, the same GCP project as the Web OAuth client"
  - "Production origin (https://my-project-joost.web.app) registered on the Web OAuth client's Authorized JavaScript origins"
  - "Manually-verified proof (desktop browser + two independent real-iPhone-Safari testers) that the full 'Add to calendar' OAuth + event-creation flow works end-to-end against the real production domain, not just localhost"
affects: [17-deployment-hardening, calendar-service, firebase-hosting]

# Tech tracking
tech-stack:
  added: ["firebase-tools 15.23.0 (global npm CLI, already present on the developer's machine)"]
  patterns:
    - "Preliminary/non-hardened firebase.json as an intentional carry-forward artifact for a later hardening phase, rather than either skipping deployment entirely or over-building config ahead of Phase 17's formal DEPLOY-01/02 requirements"

key-files:
  created:
    - firebase.json
    - .firebaserc
  modified:
    - .gitignore

key-decisions:
  - "Reused the SAME Google Cloud project (my-project-joost, project number 300023366326) as the Web OAuth client from Plan 15-01, via `firebase projects:addfirebase` -- keeps the OAuth client's Authorized JavaScript origins as a single-client, single-project story rather than splitting across projects."
  - "firebase.json intentionally minimal (hosting.public + SPA rewrite + one wasm header rule) -- Phase 17 (DEPLOY-01/02) is the formally-scoped phase for hardening (security headers, caching policy, etc.); this plan does not attempt to anticipate that work."
  - "PERS-07 (sqlite3.wasm Content-Type header) sign-off remains Phase 17's to formally confirm per the Phase 12 SUMMARY's explicit carry-forward scoping, even though this plan's firebase.json already includes the header rule needed for the app to boot on the deployed domain."

patterns-established:
  - "Package Legitimacy Gate applied to an npm-level CLI tool (firebase-tools), not just pub.dev packages -- user confirmed the npmjs.com listing before any install was attempted."

requirements-completed: [CAL-07]

# Metrics
duration: ~50min active execution across three checkpoint round-trips (package legitimacy + login + project ID; a mid-Task-2 GCP permission/account-mismatch blocker; and the final production-origin + real-iPhone-Safari verification)
completed: 2026-07-14
---

# Phase 15 Plan 02: Production Firebase Hosting deploy + real iPhone Safari verification Summary

**Flutter web app deployed live to Firebase Hosting at https://my-project-joost.web.app, with the Plan 15-01 OAuth "Add to calendar" flow manually verified end-to-end in a desktop browser and independently confirmed on real iPhone Safari by two separate testers (first-tap success, no retry needed) -- satisfying CAL-07's "not just localhost" and mandatory real-device hard gates.**

## Performance

- **Duration:** ~50min active execution, spread across three human checkpoint round-trips
- **Started:** 2026-07-14 (Task 1 checkpoint)
- **Completed:** 2026-07-14
- **Tasks:** 3/3 complete
- **Files modified:** 2 created (`firebase.json`, `.firebaserc`), 1 modified (`.gitignore`)

## Accomplishments
- Deployed the Flutter web app to a real, stable HTTPS Firebase Hosting domain (`https://my-project-joost.web.app`) for the first time in this repo's history -- no `firebase.json`/`.firebaserc`/Firebase project existed before this plan.
- Registered the production origin on the same Web OAuth client created in Plan 15-01, extending its Authorized JavaScript origins from `http://localhost:5000`-only to include the real production domain.
- Fully satisfied CAL-07's hard gate: the complete "Add to calendar" OAuth + Google Calendar event-creation flow was manually verified against the real production URL in a desktop browser AND independently confirmed by two separate real-iPhone-Safari testers (Jacco and Bas), with the critical detail that the OAuth popup opened successfully on the **first tap** with no retry needed -- directly validating Plan 15-01's eager `warmUpForWeb()` fix under real Safari conditions, not just desktop Chrome or a simulator.
- `flutter build apk --release` confirmed exit 0 -- native Android and its Phase 9 Calendar flow remain completely unaffected by adding a Firebase Hosting deployment to the repo.

## Task Commits

Each task/gate was committed atomically:

1. **Task 1: Package legitimacy check for firebase-tools + install + firebase login (CAL-07 setup)** -- human-verify checkpoint (`gate="blocking-human"`), no commit (external CLI install/auth only, no repo changes)
2. **Task 2: Preliminary firebase.json + deploy to a real Firebase Hosting domain (CAL-07)** -- `d11e651` (feat)
3. **Task 3: Register production OAuth origin + full end-to-end verification including real iPhone Safari (CAL-07)** -- human-action checkpoint (`gate="blocking"`), no commit (external Google Cloud Console config + manual device verification only); `flutter build apk --release`'s automated half also produced no commit (verification-only, exit 0)

**Plan metadata:** this commit (docs: complete plan)

_Note: No TDD tasks in this plan -- infra/deployment plan with two mandatory human checkpoints and one fully-automatable middle task._

## Files Created/Modified
- `firebase.json` -- Hosting config: `build/web` as public dir, SPA rewrite (`"source": "**"` → `/index.html`) so go_router's client-side routes (e.g. `/detail/:rideId`) resolve on direct load/refresh, and an explicit `Content-Type: application/wasm` header rule for `*.wasm` (proactively addresses the boot-blocking half of PERS-07; formal PERS-07 sign-off remains Phase 17's per the Phase 12 SUMMARY's carry-forward scoping). Intentionally minimal -- Phase 17 (DEPLOY-01/02) extends, not replaces, this file.
- `.firebaserc` -- `{"projects": {"default": "my-project-joost"}}`, pointing at the same GCP project (number `300023366326`) as the Web OAuth client created in Plan 15-01.
- `.gitignore` -- Added `.firebase/` (CLI's local hosting cache directory) and `firebase-debug.log` (CLI's own debug log); both are also incidentally covered by the pre-existing `*.log` glob, but added explicitly per the plan's interface spec for clarity.

## Decisions Made
- **Reused Plan 15-01's Google Cloud project rather than creating a new one.** `firebase projects:addfirebase my-project-joost` targets the exact same project (number `300023366326`) that already hosts the Web OAuth client, keeping a single-project, single-client story for CAL-06/CAL-07 together (matches RESEARCH.md Open Question 3's default recommendation).
- **firebase.json kept deliberately minimal.** No caching headers, no security headers, no multi-site config -- Phase 17 (DEPLOY-01/02) is the formally-scoped hardening phase; this plan only adds what's structurally required (SPA rewrite) or boot-blocking (wasm Content-Type) for its own verification to succeed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking, environment-only] Missing `android/key.properties` in the git worktree**
- **Found during:** Task 3's automated half (`flutter build apk --release`)
- **Issue:** `android/key.properties` is gitignored and was never copied into this git worktree by `git worktree add` (which only checks out tracked files), causing a Gradle `null cannot be cast to non-null type kotlin.String` failure at `android/app/build.gradle.kts:29`. This is the exact same environment-only gap already documented in Plan 15-01's SUMMARY.
- **Fix:** Copied the existing, already-present-on-the-machine `key.properties` from the main checkout (`/Users/joostmouw/ridewindow/android/key.properties`) into the worktree's `android/` directory.
- **Files modified:** None git-tracked -- `android/key.properties` remains gitignored in the worktree; no commit involved.
- **Verification:** `flutter build apk --release` re-run afterward, exited 0, produced `app-release.apk` (66.3MB).
- **Committed in:** N/A (gitignored file, not a repo change)

---

**Total deviations:** 1 auto-fixed (1 Rule 3 environment-only blocking issue, matching a known precedent from Plan 15-01)
**Impact on plan:** No scope creep -- purely a local git-worktree environment gap with an already-documented fix. No code or committed config was affected.

## Issues Encountered

**1. GCP account/project mismatch during Task 2 (`firebase projects:addfirebase` initially failed with 403 PERMISSION_DENIED)**
- The Firebase CLI's first `firebase login` session (from Task 1) had authenticated the wrong Google account relative to the GCP project the user intended to target, and separately an accidental duplicate GCP project (`my-project-joost-becc7`, project number `899027188899`) had been created via the Firebase Console UI before the account mismatch was caught. Running `firebase projects:addfirebase my-project-joost` against the intended project ID returned `403 PERMISSION_DENIED` because the authenticated account lacked access to it at that point.
- **Resolution:** The user corrected the `firebase login` session to authenticate as `joostmouw@gmail.com` (confirmed Owner via IAM on `my-project-joost`, project number `300023366326` -- matching the Web OAuth client's project from Plan 15-01). Re-running `firebase projects:addfirebase my-project-joost` then returned `409 ALREADY_EXISTS` (the project was already Firebase-enabled), confirmed via `firebase projects:list` showing both `my-project-joost` (300023366326) and the accidental duplicate `my-project-joost-becc7` (899027188899).
- **Carry-forward:** The duplicate `my-project-joost-becc7` GCP project is being deleted separately by the user directly in the Cloud Console -- it was never referenced by any file in this repo and required no code or config changes here.

**2. OAuth consent screen "Access blocked" hit by both iPhone Safari testers**
- Both Jacco and Bas hit the expected Testing-mode "Access blocked: this app has not completed Google's verification process" screen on their first attempt, since the OAuth consent screen remains in Testing publish status (left that way intentionally in Plan 15-01, tracked as backlog item #31). Both were added as explicit OAuth consent screen test users, after which the flow worked correctly for each of them. This is expected behavior given the consent screen's current publish status, not a defect in this plan's deployment or the CalendarService code -- no code or config change was needed here beyond the Console-side test-user addition, which the user performed directly.

## User Setup Required

None further for this plan -- the Firebase Hosting deployment is live, the production OAuth origin is registered, and the full flow has been manually verified end-to-end by the developer plus two independent testers on real iPhone Safari. See "Carry-forward Notes" below for out-of-scope follow-up items already logged to the backlog.

## Carry-forward Notes

- **Backlog item #31** (carried forward from Plan 15-01, reconfirmed here): the OAuth consent screen still needs to be published or fully verified before any user besides explicitly-added test users can use the Calendar feature on web. Both Jacco and Bas had to be manually added as test users to complete Task 3's verification -- this remains out of this plan's scope.
- **Backlog item #38** (new, logged during Task 3's real-device verification): a Google Calendar event created via this flow does not automatically appear in the native iPhone Calendar app unless the user has linked their Google account via iOS Settings → Calendar → Accounts. This is expected iOS platform behavior, not a defect in this plan's implementation -- logged as a possible future in-app tip/onboarding hint, not addressed by this plan.
- **PERS-07** (carried forward from Phase 12's SUMMARY): this plan's `firebase.json` includes the `*.wasm` Content-Type header rule needed for the app to boot correctly on the deployed domain (which this plan's own verification depended on), but formal PERS-07 sign-off remains Phase 17's to confirm per the Phase 12 SUMMARY's explicit scoping. This plan does not claim that requirement.
- **DEPLOY-01/DEPLOY-02** (Phase 17): this plan's `firebase.json`/`.firebaserc` are intentionally preliminary/non-hardened. Phase 17 should extend this file (caching headers, security headers, etc.) rather than replace it, and must not re-register the Calendar OAuth origin (already done here).

## Next Phase Readiness
- CAL-07 is fully satisfied: production Firebase Hosting URL live, production OAuth origin registered, full "Add to calendar" flow verified end-to-end in both a desktop browser and real iPhone Safari (by two independent testers, both with first-tap success).
- Phase 15 (google-calendar-web-integration) is now complete across both CAL-06 (Plan 15-01) and CAL-07 (Plan 15-02).
- Phase 17 (deployment hardening, DEPLOY-01/02) can proceed directly from this plan's `firebase.json`/`.firebaserc` as a starting point -- no rework needed, only extension.
- Backlog items #31 and #38 remain open for a future phase/plan to address.

---
*Phase: 15-google-calendar-web-integration*
*Completed: 2026-07-14*

## Self-Check: PASSED

All created/modified files confirmed present (`firebase.json`, `.firebaserc`, `.gitignore`, this SUMMARY.md). Referenced commit hash confirmed in `git log` (`d11e651`).
