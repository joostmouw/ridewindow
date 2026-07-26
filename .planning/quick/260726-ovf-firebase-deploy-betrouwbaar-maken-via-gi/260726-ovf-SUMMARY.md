---
phase: quick-260726-ovf
plan: 01
subsystem: infra
tags: [github-actions, firebase-hosting, ci-cd, deploy-script, bash]

# Dependency graph
requires:
  - phase: none
    provides: n/a (standalone infra quick task)
provides:
  - "Path-filtered GitHub Actions workflow (.github/workflows/deploy-web.yml) that builds and deploys build/web to Firebase Hosting from a GitHub-hosted runner, bypassing the ~17 KB/s home uplink"
  - "Hash-verified local deploy script (scripts/deploy_web.sh) that never masks firebase deploy's exit status behind a pipe and only reports SUCCESS after confirming the live main.dart.js hash matches the local build"
affects: [firebase-hosting, ci, release-process]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SHA-pinned third-party GitHub Actions (not mutable tags) for any workflow holding a production-capable credential"
    - "Guard step that checks secret presence and fails fast with an actionable message, before any build/deploy work runs"
    - "Local deploy scripts verify success independently (content hash) rather than trusting a wrapped CLI's exit code alone"

key-files:
  created:
    - .github/workflows/deploy-web.yml
    - scripts/deploy_web.sh
  modified: []

key-decisions:
  - "Content for both files was fully drafted and pre-validated during planning (ruby -ryaml + bash -n) -- executor created them verbatim, no re-derivation"
  - "Task 3 (creating the FIREBASE_SERVICE_ACCOUNT GitHub secret) intentionally not executed -- requires the user's own browser/Google session; left as an open blocking checkpoint"

patterns-established:
  - "CI deploy workflows for this repo pin third-party Actions to commit SHA with the version tag kept as a trailing comment"

requirements-completed: [OVF-01, OVF-02]

# Metrics
duration: 12min
completed: 2026-07-26
---

# Phase quick-260726-ovf: Firebase deploy betrouwbaar maken via GitHub Actions Summary

**Path-filtered GitHub Actions CI workflow (SHA-pinned actions/checkout, subosito/flutter-action, FirebaseExtended/action-hosting-deploy) plus a hash-verified local `scripts/deploy_web.sh` that never pipes `firebase deploy`'s exit status away.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-26T16:00:00Z (approx, first Read call)
- **Completed:** 2026-07-26T16:12:32Z
- **Tasks:** 2 of 3 (Task 3 is a blocking human-action checkpoint, intentionally not executed)
- **Files modified:** 2 (both newly created)

## Accomplishments

- `.github/workflows/deploy-web.yml` created: triggers on `workflow_dispatch` or a push to `main` touching `lib/**`, `web/**`, `pubspec.yaml`, `pubspec.lock`, `firebase.json`, or the workflow file itself. Fails fast at a guard step if `FIREBASE_SERVICE_ACCOUNT` is unset, before any build/deploy work. All three third-party Actions pinned to a commit SHA (not a mutable tag).
- `scripts/deploy_web.sh` created and made executable: builds the Flutter web release, retries `firebase deploy --only hosting` up to 3 times without ever piping it into another command (so its exit code cannot be masked), then independently verifies the live `main.dart.js` content hash against the local build before printing a line starting `SUCCESS:`.
- Root cause this addresses (documented in both files' header comments): a 2026-07-26 deploy attempt from the ~17 KB/s home uplink failed after ~11 minutes on firebase-tools' own per-file upload timeout, and a second, independent bug (`firebase deploy ... | tail -12`) caused a failed deploy to be reported as successful, leaving the live site silently stale.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the GitHub Actions CI deploy workflow** - `246d459` (feat)
2. **Task 2: Create the local hash-verified deploy script** - `0f975f8` (feat)

Task 3 (checkpoint:human-action, `gate="blocking"`) was **not executed** by design — see "Next Phase Readiness" below.

_No TDD tasks in this plan; both are `type="auto"` infra file creations._

## Files Created/Modified

- `.github/workflows/deploy-web.yml` - Path-filtered CI workflow: builds `flutter build web --release` and deploys `build/web` to Firebase Hosting's live channel for `my-project-joost` on a GitHub-hosted runner, gated by a `FIREBASE_SERVICE_ACCOUNT` secret-presence guard step.
- `scripts/deploy_web.sh` - Local deploy script (executable): build -> up to 3 retried `firebase deploy` attempts (never piped) -> hash-verification of the live `main.dart.js` against the freshly built local file before reporting success.

## Decisions Made

- Both files were used verbatim from the plan's pre-validated `<interfaces>` block — no re-derivation, no changes to the header comment blocks (kept the full "why this exists / what it does not do / setup required" style already established by `.github/workflows/supabase-keep-warm.yml`, per plan instruction).
- Confirmed the plan's syntax-validation-tool claim directly rather than trusting it: `yq` is not installed on this machine, `python3 -c 'import yaml'` fails with `ModuleNotFoundError: No module named 'yaml'`, and `ruby -ryaml` (Ruby 2.6.10) is the working path — matches what the plan stated.
- `shellcheck` is not installed on this machine; per the plan's own verify block, this is a non-blocking skip (`bash -n` is the baseline gate) and the verify command's `||` fallback printed the expected message rather than failing.
- Did not run `firebase deploy`, did not push to `origin`, did not create the `FIREBASE_SERVICE_ACCOUNT` secret, and did not trigger any CI run — per explicit executor-context instruction, given the ~17 KB/s home uplink that is the entire reason this plan exists.

## Deviations from Plan

None - plan executed exactly as written. Both files match the `<interfaces>` block content verbatim; verification commands from each task's `<verify>` block were run as specified (not modified), with real command output confirming pass in both cases.

## Issues Encountered

None.

## User Setup Required

**External action requires manual configuration.** Task 3 of the plan (`checkpoint:human-action`, `gate="blocking"`) was deliberately not executed by this executor run — it requires the user's own browser session and Google/GCP account and cannot be automated:

1. Run `firebase init hosting:github` from the repo root (recommended path), or use the manual GCP Console -> IAM & Admin -> Service Accounts route (see the full instructions embedded in the workflow file's header comment and in the plan's Task 3 `<human-action>` block).
2. If using the wizard, rename the secret it creates (`FIREBASE_SERVICE_ACCOUNT_MY_PROJECT_JOOST`) to exactly `FIREBASE_SERVICE_ACCOUNT` under GitHub repo Settings -> Secrets and variables -> Actions.
3. Optionally exercise the workflow via GitHub -> Actions -> "Deploy web to Firebase Hosting" -> Run workflow (the `workflow_dispatch` trigger), before relying on it for a real deploy.
4. This repo currently has unpushed local commits (`.planning/STATE.md` notes 46 as of 2026-07-17; more have accumulated since, including this plan's own 2 commits). Nothing in this plan pushes them — pushing to `origin/main` remains the user's call, separate from this setup.

## Next Phase Readiness

- `.github/workflows/deploy-web.yml` and `scripts/deploy_web.sh` are both committed, syntax-valid, and ready to use as soon as the `FIREBASE_SERVICE_ACCOUNT` secret exists (Task 3, blocked on the user).
- Until the secret is created, the CI workflow will fail immediately and cleanly at its guard step if it ever runs (rather than deep inside the deploy action) — no risk of a silent partial deploy from CI in the meantime.
- `scripts/deploy_web.sh` is usable locally right now for any deploy attempt from this Mac and is a strict improvement over the previous ad hoc `firebase deploy | tail -12` pattern, independent of whether the CI secret is ever configured.
- This SUMMARY intentionally does NOT advance STATE.md's plan/phase counters or requirement completion state via the normal `state.advance-plan` / `requirements.mark-complete` flow in the same way a full milestone-phase plan would, because Task 3 remains an open blocking checkpoint — see the executor-context instruction to stop cleanly after Task 2 and record Task 3 as open. Requirements OVF-01/OVF-02 cover the two artifacts delivered here (Tasks 1+2); they are recorded as complete in this SUMMARY's frontmatter since both artifacts fully exist and pass their own automated verification, but the plan's overall workflow does not become end-to-end functional until Task 3 is done by the user.

---
*Phase: quick-260726-ovf*
*Completed: 2026-07-26*

## Self-Check: PASSED

- FOUND: .github/workflows/deploy-web.yml
- FOUND: scripts/deploy_web.sh
- FOUND: .planning/quick/260726-ovf-firebase-deploy-betrouwbaar-maken-via-gi/260726-ovf-SUMMARY.md
- FOUND: 246d459 (git log --oneline --all)
- FOUND: 0f975f8 (git log --oneline --all)
