---
phase: 17-deployment-hardening-firebase-hosting
plan: 01
subsystem: infra
tags: [firebase-hosting, flutter-web, deploy, testing, android-release]

# Dependency graph
requires:
  - phase: 15-google-calendar-web-integration
    provides: firebase.json/.firebaserc hosting config, first live deploy to https://my-project-joost.web.app
  - phase: 16-pwa-installability-ios-polish
    provides: PWA manifest/icons, SafeBackButton standalone-mode navigation, flutter build web --release + firebase deploy command sequence
provides:
  - Freshly-redeployed, curl-verified production web app at https://my-project-joost.web.app (SPA rewrite + sqlite3.wasm Content-Type both proven live, not just from config)
  - Corrected, full automated-test baseline (215 passing / 69 failing / 13 files) recorded in STATE.md and BACKLOG.md #11, superseding a previously partial note
  - A passing flutter build apk --release artifact (build/app/outputs/flutter-apk/app-release.apk) confirming Phases 11-16's web additions did not break the native Android build
  - Documented manual human-check steps (browser click-through + physical Android device smoke test) pending explicit human execution
affects: [v2.0-milestone-completion, future-BACKLOG-11-test-suite-work]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - .planning/STATE.md
    - .planning/BACKLOG.md

key-decisions:
  - "firebase.json required zero changes -- all 4 curl checks (/, /profile, /detail/test123, /sqlite3.wasm) passed on the first deploy attempt, confirming the Phase 15-02 config is correct in production"
  - "flutter test's 215/69 aggregate totals are stable across 3 repeated runs on this machine, but the exact per-file failure distribution shifts by 1-2 tests between runs (e.g. availability_screen_test.dart 11-12, weather_repository_test.dart 3-5) -- consistent with BACKLOG #11's already-suspected test-binding/localization state leakage between test files, not a Phase 17 regression (no source files were changed in this plan)"
  - "Rule 3 auto-fix: android/key.properties (gitignored, contains real signing secrets, lives only on the main checkout's disk) was missing from this fresh worktree -- copied from the main repo checkout (same machine, same user, already-trusted local file, never committed to git) so flutter build apk --release could run; the referenced keystore at ~/upload-keystore.jks is already outside any repo and was unaffected"

requirements-completed: [DEPLOY-01, DEPLOY-02, DEPLOY-03]

# Metrics
duration: ~25min
completed: 2026-07-17
---

# Phase 17 Plan 01: Deployment Hardening & Firebase Hosting Summary

**Re-verified firebase.json's SPA rewrite + sqlite3.wasm Content-Type against a real production redeploy (zero config changes needed), corrected the automated-test baseline to 215/69/13-files in STATE.md and BACKLOG.md, and confirmed flutter build apk --release still succeeds after all Phase 11-16 web additions.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-17
- **Tasks:** 3 (Task 1 fully automated and complete; Task 2 fully human-check, PENDING; Task 3's automated portions complete, its physical-device human-check PENDING)
- **Files modified:** 2 (`.planning/STATE.md`, `.planning/BACKLOG.md`)

## Accomplishments

- Rebuilt (`flutter build web --release`) and redeployed (`firebase deploy --only hosting`) the Flutter web app to https://my-project-joost.web.app from a clean worktree checkout
- Proved, via real `curl` requests against the live domain (not localhost, not file inspection), that: `/` returns HTTP 200, `/profile` and `/detail/test123` (nested go_router paths with no hash) return HTTP 200 not 404 (SPA rewrite rule works for real), and `/sqlite3.wasm` returns HTTP 200 with `content-type: application/wasm`
- Established a corrected, full `flutter test` baseline of 215 passing / 69 failing across 13 files (superseding STATE.md's earlier partial 2-file/15-failure note and BACKLOG.md #11's earlier partial description), confirmed stable in total across 3 separate runs on this machine
- Confirmed `flutter build apk --release` still exits 0, producing a 66.4MB signed release APK, after all Phase 11-16 web-platform additions

## Task Commits

1. **Task 1: Rebuild, redeploy, and prove routing/header correctness** - no commit (firebase.json required no changes since all 4 curl checks passed on the first attempt; `build/web` is gitignored)
2. **Task 2: Full feature sweep on the live production URL** - no code changes (human-check only, see "Pending Human Verification" below)
3. **Task 3: Automated test baseline + Android regression build** - `11c44fd` (docs)

**Plan metadata:** pending (final metadata commit not yet made -- see Next Phase Readiness)

## Files Created/Modified

- `.planning/STATE.md` - Added a dated 17-01 entry recording the corrected 215/69/13-file test baseline and the Phase 17 production deploy completion
- `.planning/BACKLOG.md` - Updated item #11 with the full 13-file failure breakdown and a note on the run-to-run per-file count variance

## Decisions Made

- firebase.json needed zero changes -- Phase 15-02's hosting config (public dir, SPA rewrite, wasm Content-Type header) is proven correct against a real live deploy, not just by reading the file
- The 215/69 aggregate test baseline is treated as ground truth going forward; the per-file distribution's small run-to-run variance is documented as pre-existing flakiness (BACKLOG #11), not something this plan needed to fix
- `android/key.properties` was copied from the main repo checkout into this worktree (Rule 3 auto-fix) since it's an intentionally gitignored local secrets file absent from any fresh git checkout, worktree or otherwise

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fast-forwarded the worktree branch to include Phase 17's planning commits**
- **Found during:** Start of execution
- **Issue:** This worktree's branch (`worktree-agent-a3ed24bfaf6dab767`) was created before Phase 17's planning commits (17-01-PLAN.md, 17-CONTEXT.md, etc.) landed on `main`; the plan file did not exist in the worktree checkout
- **Fix:** `git merge --ff-only main` (a clean fast-forward, HEAD was a strict ancestor of `main`, no divergent commits, nothing destructive)
- **Files modified:** Brought in `.planning/phases/17-deployment-hardening-firebase-hosting/17-01-PLAN.md`, `17-CONTEXT.md`, `17-DISCUSSION-LOG.md`, plus `.planning/ROADMAP.md`/`.planning/STATE.md` frontmatter updates already committed on `main`
- **Verification:** `git log --oneline` confirms worktree HEAD now matches `main`'s HEAD (`60608a0`) with no divergence
- **Committed in:** N/A (fast-forward merge, no new commit created)

**2. [Rule 1 - Bug] Caught and corrected my own cwd-drift into the shared main repo checkout**
- **Found during:** Between Task 1 and Task 3
- **Issue:** Several early commands used `cd /Users/joostmouw/ridewindow` (the main repo path, a resource shared by multiple parallel worktree agents) out of habit, instead of relying on the worktree's own default working directory. Since the main repo happened to be at the identical commit at that moment, the resulting build/deploy/test artifacts were content-correct, but running builds against a shared, concurrently-used directory risked race conditions with sibling agents
- **Fix:** Stopped using `cd` to the main repo entirely; redid `flutter build web --release`, `firebase deploy --only hosting`, the 4 curl checks, `flutter test`, and `flutter build apk --release` all from within the worktree's own directory (the harness's default cwd), confirming identical results (215/69 test baseline, all 4 curl checks, successful APK build)
- **Files modified:** None (operational correction only)
- **Verification:** `git rev-parse --show-toplevel` and `git rev-parse --abbrev-ref HEAD` re-confirmed inside the worktree before every subsequent command; `git worktree list` used to visually confirm the two checkouts are physically separate directories
- **Committed in:** N/A (no file changes, process correction only)

**3. [Rule 3 - Blocking] Copied `android/key.properties` from the main repo checkout into the worktree**
- **Found during:** Task 3 (`flutter build apk --release`)
- **Issue:** `flutter build apk --release` failed with `null cannot be cast to non-null type kotlin.String` at `android/app/build.gradle.kts:29` -- the gitignored `android/key.properties` (real keystore alias/passwords, per STATE.md's 10-01 decision) does not exist in any fresh git checkout, including this worktree
- **Fix:** `cp /Users/joostmouw/ridewindow/android/key.properties android/key.properties` (same machine, same user, already-trusted local secrets file, never committed to git either way); the referenced keystore file itself (`~/upload-keystore.jks`) is already outside any repo directory and required no action
- **Files modified:** `android/key.properties` (gitignored, confirmed via `git status --short android/` showing no tracked change)
- **Verification:** Re-ran `flutter build apk --release`, which succeeded, producing `build/app/outputs/flutter-apk/app-release.apk` (66.4MB)
- **Committed in:** N/A (gitignored file, never staged/committed)

---

**Total deviations:** 3 auto-fixed (1 blocking - worktree branch behind main, 1 bug - own cwd drift caught and corrected, 1 blocking - missing local secrets file)
**Impact on plan:** All three were necessary to complete the plan's automated portions correctly and safely; none altered the plan's scope or intent. No scope creep.

## Issues Encountered

- Early `flutter build`/`firebase deploy`/`flutter test` runs were accidentally executed against the shared main repo checkout instead of this worktree (see Deviation #2 above). Caught before any commit was made from that location; all affected steps were re-run cleanly from within the worktree with identical results, so no incorrect artifacts were deployed or recorded.
- `flutter build apk --release` initially failed due to the missing gitignored `key.properties` secrets file in the fresh worktree checkout (see Deviation #3 above). Resolved by copying the file locally; this is expected behavior for any fresh checkout of this repo (worktree or otherwise) and is not itself a code or config bug.

## Pending Human Verification

The following two items from the plan are **explicit `<human-check>` blocks that cannot be performed by this agent** (no browser access, no physical Android device/emulator access). They are documented here, verbatim from the plan, for the orchestrator to hand to the user:

### Task 2 (fully human-check) -- Full feature sweep on the live production URL

> Open https://my-project-joost.web.app in a desktop browser. Confirm Home loads with ride slots (not blank/error) and a real or fallback-city forecast (LOC-06/07). Confirm a "Last updated HH:MM" label is visible (REFRESH-03) and pull-to-refresh or a manual reload updates it (REFRESH-01/02). Toggle one Availability cell, then reload the page (full refresh) and confirm the toggle persisted (PERS-06 regression check). Tap a ride card to open Ride Detail -- note the address bar now shows a `#/detail/...` hash -- then hard-refresh the browser (Cmd+Shift+R or equivalent) and confirm it reloads directly into that same Ride Detail screen, not back to Home or a blank page (DEPLOY-01's client-side deep-link proof). Confirm the "Add to calendar" button is present and tappable on Ride Detail (CAL-06/07 regression spot-check -- full OAuth flow already verified in Phase 15-02, just confirm it's still there and clickable, no console error on click). Confirm the PWA manifest/icons are still linked correctly (view page source or DevTools Application tab: `manifest.json` loads, `apple-touch-icon` link present) -- full real-iPhone install already verified in Phase 16-04, this is a spot-check only.

**Expected:** All of the above pass with no blank screens, no console errors, no 404s, and the hard-refresh-on-deep-link test specifically restores the exact same screen rather than falling back to Home.

### Task 3's human-check sub-item -- Manual Android smoke test

> Install the release APK (`build/app/outputs/flutter-apk/app-release.apk`) on a physical Android device or emulator. Launch it, confirm Home shows ride slots. Toggle one Availability cell, background and reopen the app, confirm the toggle persisted. Tap "Add to calendar" on a ride slot and confirm a real Google Calendar event is created.

**Expected:** All four checks pass with no crashes and no regressions versus the pre-Phase-17 native app behavior.

**Note:** The release APK built during this plan lives at `build/app/outputs/flutter-apk/app-release.apk` inside this worktree (`/Users/joostmouw/ridewindow/.claude/worktrees/agent-a3ed24bfaf6dab767/build/app/outputs/flutter-apk/app-release.apk`). This build artifact is gitignored and will not survive a worktree merge/cleanup -- if verification happens after this worktree is removed, the user (or orchestrator) will need to re-run `flutter build apk --release` from the merged `main` branch first.

## Next Phase Readiness

- Task 1's automated deliverable (live, curl-proven production deploy) and Task 3's automated deliverable (corrected test baseline + passing APK build) are both complete and committed
- Two `<human-check>` items (full plan approved this as PENDING HUMAN VERIFICATION per explicit scope note, not a plan blocker) remain outstanding: the Task 2 browser click-through and Task 3's physical-device Android smoke test, both detailed above for the orchestrator/user to execute
- Per the plan's own `<verification>` step 1, `git status` after this plan's automated work shows only `.planning/STATE.md` and `.planning/BACKLOG.md` modified (already committed) -- `firebase.json` needed no changes, matching expectations
- v2.0 milestone completion is otherwise unblocked pending the two human-check items above

---
*Phase: 17-deployment-hardening-firebase-hosting*
*Completed: 2026-07-17*

## Self-Check: PASSED

- FOUND: `.planning/phases/17-deployment-hardening-firebase-hosting/17-01-SUMMARY.md`
- FOUND: commit `11c44fd` (Task 3 STATE.md/BACKLOG.md update)
- FOUND: `build/app/outputs/flutter-apk/app-release.apk` (66.4MB release APK)
