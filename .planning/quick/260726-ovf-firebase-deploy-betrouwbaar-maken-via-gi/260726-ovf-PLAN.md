---
phase: quick-260726-ovf
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [.github/workflows/deploy-web.yml, scripts/deploy_web.sh]
autonomous: false
requirements: [OVF-01, OVF-02]

must_haves:
  truths:
    - "Pushing to main with changes under lib/**, web/**, pubspec.yaml, pubspec.lock, or firebase.json triggers an automatic CI build+deploy that does not use the home uplink for the upload"
    - "Pushing only .planning/** documentation commits (the common case for this repo) does NOT trigger a CI build"
    - "A deploy can be forced by hand from the GitHub Actions tab (workflow_dispatch) without needing a matching push"
    - "If FIREBASE_SERVICE_ACCOUNT is missing, the CI workflow fails fast at a guard step with a message naming the exact secret and where to set it, instead of an opaque auth error"
    - "Running scripts/deploy_web.sh only prints a SUCCESS line after confirming the live main.dart.js hash equals the freshly built local main.dart.js hash -- a firebase deploy exit code of 0 alone is never sufficient"
    - "scripts/deploy_web.sh never pipes `firebase deploy` into anything that could mask its exit status (the mistake that caused a stale production deploy to be reported as successful on 2026-07-26)"
    - "scripts/deploy_web.sh bounds its outer retry loop (3 attempts) instead of retrying indefinitely against a genuinely broken connection"
  artifacts:
    - path: ".github/workflows/deploy-web.yml"
      provides: "Path-filtered CI deploy: push to main (lib/**, web/**, pubspec.yaml, pubspec.lock, firebase.json, or the workflow file itself) or workflow_dispatch triggers a Flutter web build and a deploy to Firebase Hosting's live channel via a SHA-pinned FirebaseExtended/action-hosting-deploy, gated by a secret-presence guard step"
      contains: "FIREBASE_SERVICE_ACCOUNT"
    - path: "scripts/deploy_web.sh"
      provides: "Local deploy script: flutter build web --release, up to 3 retried firebase deploy attempts (never piped), then hash-verification of the live main.dart.js against the local build before reporting success"
      contains: "hash_file"
  key_links:
    - from: ".github/workflows/deploy-web.yml deploy step"
      to: "secrets.FIREBASE_SERVICE_ACCOUNT"
      via: "firebaseServiceAccount input to FirebaseExtended/action-hosting-deploy"
      pattern: "firebaseServiceAccount:\\s*\\$\\{\\{\\s*secrets\\.FIREBASE_SERVICE_ACCOUNT"
    - from: "scripts/deploy_web.sh deploy loop"
      to: "firebase deploy --only hosting"
      via: "direct `if firebase deploy ...; then` exit-code check, never piped"
      pattern: "if firebase deploy --only hosting; then"
    - from: "scripts/deploy_web.sh verification step"
      to: "https://my-project-joost.web.app/main.dart.js"
      via: "curl -o tmpfile, then hash_file() compared against the local build/web/main.dart.js hash"
      pattern: "LIVE_URL.*main\\.dart\\.js"
---

<objective>
Make Firebase Hosting deploys for RideWindow's web build reliable, by shipping two independent deliverables:

1. `.github/workflows/deploy-web.yml` -- a path-filtered GitHub Actions workflow that builds and deploys `build/web` to Firebase Hosting on a GitHub-hosted runner, so the deploy upload never has to cross the developer's ~17 KB/s home uplink.
2. `scripts/deploy_web.sh` -- a local deploy script for the times the developer does want to deploy from the Mac, which retries sensibly, never masks `firebase deploy`'s exit status behind a pipe, and only reports success after independently verifying (via content hash) that the live site actually serves the new build.

Purpose: tonight's home-network deploy failed after ~11 minutes with a Firebase upload-timeout error that exactly matches firebase-tools' own per-file timeout formula at this connection's measured speed, and a second, independent bug (`firebase deploy ... | tail -12`) made a failed deploy report as "succeeded," leaving the live site silently stale. Both root causes are structural, not one-off flukes, and both need to be designed away, not retried around.
Output: a working, path-filtered CI deploy pipeline (needs a one-time human secret-setup step to actually run) and a locally runnable, hash-verified deploy script.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md
@.github/workflows/supabase-keep-warm.yml
@firebase.json
@.firebaserc
@pubspec.yaml

<interfaces>
<!-- Both files below have already been fully drafted and validated in this planning
pass: the YAML was parsed successfully with `ruby -ryaml` (this repo has no `python3
yaml` module and no `yq`; `ruby -ryaml` is the available, working syntax-validation
path -- note that Ruby's YAML parser reads the `on:` key as boolean `true`, not the
string "on" -- this is a known YAML 1.1 quirk, GitHub's own workflow parser handles it
correctly, and the pre-existing supabase-keep-warm.yml exhibits the identical quirk
under the same check, so it is not a sign of a problem). The bash script passed
`bash -n`. Create both files with EXACTLY this content -- no re-derivation needed.
Version pins below (SHAs + trailing version comments) were confirmed live against each
action's GitHub Releases API on 2026-07-26 -- do not "helpfully" swap them for a mutable
tag. -->

**Full content for `.github/workflows/deploy-web.yml`:**
```yaml
# Deploy web to Firebase Hosting (CI)
#
# Why this exists:
# The developer's home uplink measures ~17 KB/s (0.14 Mbit/s) -- confirmed
# on 2026-07-26 by curl-uploading 1 MiB of random data to httpbin.org
# (speed_upload 17228 bytes/s). firebase-tools (15.23.0) computes a per-file
# upload timeout of max(round(size_in_KB) * 20ms, 30s), capped at 2h -- see
# lib/deploy/hosting/uploader.js:201-204 in the installed firebase-tools
# package. For build/web/main.dart.js (~1.3 MB gzipped) that is a ~109s
# budget per attempt, and the upload queue retries a failed file 6 times
# total (uploader.js:51). At 17 KB/s that single file needs ~80s to
# transfer -- it fits the budget, but with almost no margin, so any wifi
# hiccup can burn through all 6 attempts. A deploy from home tonight ran
# ~11 minutes and then failed outright with "retries exhausted after 6
# attempts ... Timeout reached making request to
# https://upload-firebasehosting.googleapis.com/...". Moving the upload to
# a GitHub-hosted runner removes the slow link from the deploy path
# entirely -- the only thing that still has to cross the home connection is
# `git push` (source, kilobytes), not the ~5 MB compiled build/web output.
#
# What this job does, and does not, do:
# On a push to main that touches files able to change the web build (see
# the path filter below), or on manual dispatch, it runs
# `flutter build web --release` and deploys build/web to the Firebase
# Hosting *live* channel for the my-project-joost project. It does NOT run
# `flutter test` or `flutter analyze` as a deploy gate -- that was
# considered and rejected for now: the suite's known baseline
# (.planning/STATE.md, 17-01) is 215 passing / 69 pre-existing failures
# unrelated to hosting (tracked in BACKLOG.md #11), so gating every deploy
# on a fully green suite would block all deploys until that separate
# test-health backlog item is resolved. If the suite becomes green, add a
# `flutter test` step before the build step -- do not silently reintroduce
# this gate without updating this comment.
#
# Why path filters matter here specifically: this repo's GSD planning
# workflow produces a large volume of `.planning/**` documentation commits
# (46 unpushed at the time this workflow was written) that cannot possibly
# change the compiled web output. Without a path filter, every one of those
# commits would trigger a full Flutter web build + deploy for nothing. This
# repository is public, so GitHub Actions minutes on ubuntu-latest runners
# are free/unmetered regardless -- the EUR 0/month ceiling in CLAUDE.md is
# not actually at risk here even without the filter -- but a multi-minute
# build on every doc-only commit is still wasted time and wasted feedback
# loop, so the filter stays.
#
# Why the Firebase Hosting GitHub Action instead of a raw `firebase deploy`
# CLI call: FirebaseExtended/action-hosting-deploy takes the service
# account JSON directly as an input (firebaseServiceAccount) and writes it
# to a credentials file itself -- no manual base64-decode-to-file step in
# this workflow. The alternative (`npx firebase-tools deploy --only
# hosting` with GOOGLE_APPLICATION_CREDENTIALS pointed at a hand-written
# temp file, or the older `firebase login:ci` token flow) adds manual
# credential-file plumbing for no benefit here, since this workflow only
# ever deploys to the live channel and never needs preview channels or PR
# comments. `firebase init hosting:github` -- Google's own setup wizard --
# specifically pairs with this action, which is why this choice was made.
#
# All third-party Actions below are pinned to a commit SHA, not a mutable
# tag: this job authenticates with a service account key capable of
# publishing to production hosting, so a tag that could be silently
# repointed (by accident or via a compromised upstream account) is treated
# as a real risk. The version tag is kept as a trailing comment so bumping
# is a deliberate, reviewable diff, not a silent drift.
#
# Setup required before this workflow can succeed (one-time, by the repo
# owner):
#   Repository secret FIREBASE_SERVICE_ACCOUNT -- a Firebase/GCP service
#   account JSON key with the Firebase Hosting Admin role on the
#   my-project-joost project.
#
#   Recommended: run `firebase init hosting:github` from the repo root on
#   your machine. It is interactive (opens a browser / asks you to
#   authorize against GitHub) so this is necessarily something you run
#   yourself, not something this workflow or an agent can do for you. It
#   creates the service account with the right role AND creates a GitHub
#   secret for you -- but it names that secret
#   FIREBASE_SERVICE_ACCOUNT_MY_PROJECT_JOOST (derived from the project
#   ID), not FIREBASE_SERVICE_ACCOUNT. After running it, rename the secret
#   it created to exactly FIREBASE_SERVICE_ACCOUNT (repo -> Settings ->
#   Secrets and variables -> Actions), or the guard step below will fail
#   with a message telling you so. Decline the wizard's offer to write its
#   own workflow YAML files -- this file replaces that output and already
#   matches this repo's conventions.
#
#   Manual alternative (no wizard): GCP Console -> IAM & Admin -> Service
#   Accounts -> create one with the "Firebase Hosting Admin" role on
#   my-project-joost -> Keys -> Add key -> JSON -> download it -> paste its
#   full contents as the FIREBASE_SERVICE_ACCOUNT secret in GitHub.
#
# Until that secret exists, the guard step below fails with a clear message
# instead of an opaque auth error inside the deploy action.

name: Deploy web to Firebase Hosting

on:
  push:
    branches:
      - main
    paths:
      - "lib/**"
      - "web/**"
      - "pubspec.yaml"
      - "pubspec.lock"
      - "firebase.json"
      - ".github/workflows/deploy-web.yml"
  workflow_dispatch:
    # Lets a deploy be forced by hand from the Actions tab -- e.g. after
    # rotating the service account key, or re-running after a transient
    # runner problem -- without needing an empty commit.

jobs:
  deploy:
    name: Build and deploy build/web
    runs-on: ubuntu-latest
    steps:
      - name: Verify FIREBASE_SERVICE_ACCOUNT is configured
        run: |
          if [ -z "${{ secrets.FIREBASE_SERVICE_ACCOUNT }}" ]; then
            echo "::error::FIREBASE_SERVICE_ACCOUNT (repository secret) is not set. Add it under Settings > Secrets and variables > Actions before this workflow can deploy -- see the comment block at the top of this file for the recommended 'firebase init hosting:github' setup and the exact secret name it expects."
            exit 1
          fi

      - name: Checkout repository
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      - name: Set up Flutter
        uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0
        with:
          channel: stable
          flutter-version: 3.44.1 # pinned to match this app's local dev/test Flutter version (`flutter --version`) -- avoids CI silently building against a newer Flutter that behaves differently

      - name: flutter pub get
        run: flutter pub get

      - name: flutter build web --release
        run: flutter build web --release

      - name: Deploy to Firebase Hosting (live channel)
        uses: FirebaseExtended/action-hosting-deploy@500ac625ca2dd40cbd15f7659af953801858032a # v0.11.0
        with:
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          projectId: my-project-joost
          channelId: live
          firebaseToolsVersion: 15.23.0 # pinned to the version already verified locally (the uploader.js timeout formula referenced above was read from this exact version)
```

**Full content for `scripts/deploy_web.sh`:**
```bash
#!/usr/bin/env bash
#
# Reliable Firebase Hosting deploy, run from this Mac.
#
# Why this exists:
# The home uplink here measures ~17 KB/s (0.14 Mbit/s, measured 2026-07-26).
# firebase-tools already retries slow/failed uploads internally (6 attempts
# per file, see .github/workflows/deploy-web.yml's header comment for the
# measured timeout math) -- this script does NOT try to out-engineer that.
# What it adds on top:
#   1. A bounded OUTER retry around the whole `firebase deploy` command, for
#      the case where the deploy command itself fails (not just one file).
#   2. A hash-based verification step: `firebase deploy` exiting 0 is
#      necessary but was proven NOT sufficient on this machine -- on
#      2026-07-26 a deploy was run as `firebase deploy --only hosting 2>&1
#      | tail -12`, which made the shell report `tail`'s exit code, not
#      firebase's. A failed deploy looked like a success and the live site
#      stayed on the old build for hours before anyone noticed. This script
#      never pipes `firebase deploy` into anything (see `set -euo pipefail`
#      below and the deploy step itself), and it does not print "SUCCESS"
#      based on firebase's exit code alone -- only after independently
#      confirming the live main.dart.js has the same content hash as the
#      just-built local file, the same technique used to catch that
#      original bug (`curl ... | md5` vs the local file's `md5`).
#
# Retry policy, and why these specific numbers:
# firebase-tools already spends up to ~11 minutes retrying a single slow
# file internally before giving up (measured, see the workflow comment).
# MAX_DEPLOY_ATTEMPTS below wraps the WHOLE deploy command, so a bigger
# number here multiplies that worst case directly -- 3 attempts already
# means a worst-case wall time in the region of 30+ minutes if the link is
# truly broken, not just having one bad moment. That is deliberately not
# unbounded: 3 attempts is enough to ride out a single wifi hiccup or
# transient DNS blip, but if the link is broken on all 3 tries, that is a
# structural problem (not a "try again" problem) and the script says so and
# stops, pointing at the GitHub Actions path
# (.github/workflows/deploy-web.yml) as the reliable alternative instead of
# hanging indefinitely.
#
# Platform note (stated, not left implicit): this script is written for and
# only tested on macOS, which ships the `md5` command (`md5 -q` for a bare
# hash with no filename prefix). Linux ships `md5sum` instead, with
# different output formatting. `hash_file()` below tries `md5` first and
# falls back to `md5sum`, but the `md5sum` path has not been exercised --
# this script's actual, verified home is Joost's Mac.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT_ID="my-project-joost"
LIVE_URL="https://${PROJECT_ID}.web.app"
TARGET_FILE="build/web/main.dart.js"
MAX_DEPLOY_ATTEMPTS=3
HASH_VERIFY_ATTEMPTS=3
HASH_VERIFY_DELAY_SECONDS=5

hash_file() {
  if command -v md5 >/dev/null 2>&1; then
    md5 -q "$1"
  elif command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" | awk '{print $1}'
  else
    echo "ERROR: neither 'md5' (macOS) nor 'md5sum' (Linux) found on PATH -- cannot verify the deploy, refusing to report success blind." >&2
    exit 1
  fi
}

if ! command -v firebase >/dev/null 2>&1; then
  echo "ERROR: 'firebase' CLI not found on PATH. Install via 'npm install -g firebase-tools' (this machine already has 15.23.0 at the time this script was written)." >&2
  exit 1
fi

echo "== Step 1/3: flutter build web --release =="
flutter build web --release

if [ ! -f "$TARGET_FILE" ]; then
  echo "ERROR: $TARGET_FILE does not exist after the build. Either the build failed without a non-zero exit (unexpected) or firebase.json's hosting.public path no longer matches build/web -- check both before re-running." >&2
  exit 1
fi

LOCAL_HASH="$(hash_file "$TARGET_FILE")"
echo "Local build hash ($TARGET_FILE): $LOCAL_HASH"

echo "== Step 2/3: firebase deploy --only hosting (up to $MAX_DEPLOY_ATTEMPTS attempts) =="
# Deliberately NOT piped into tail/grep/head/anything -- see the header
# comment above for why that specific mistake is the one this script exists
# to make impossible. firebase's own stdout/stderr stream straight to this
# terminal, so progress is visible live even on a slow attempt; the exit
# code is checked directly via the `if` below (commands tested in an `if`
# condition are exempt from `set -e`, so this is safe under
# `set -euo pipefail`).
deploy_ok=0
for attempt in $(seq 1 "$MAX_DEPLOY_ATTEMPTS"); do
  echo "--- deploy attempt $attempt/$MAX_DEPLOY_ATTEMPTS ---"
  if firebase deploy --only hosting; then
    deploy_ok=1
    break
  fi
  echo "Attempt $attempt/$MAX_DEPLOY_ATTEMPTS failed (firebase deploy exited non-zero)." >&2
  if [ "$attempt" -lt "$MAX_DEPLOY_ATTEMPTS" ]; then
    echo "Retrying..." >&2
  fi
done

if [ "$deploy_ok" -ne 1 ]; then
  echo "ERROR: firebase deploy failed on all $MAX_DEPLOY_ATTEMPTS attempts. Not running the verification step -- there is nothing new on the server to verify. If this keeps happening, push to main and let GitHub Actions deploy instead (.github/workflows/deploy-web.yml) -- that path does not depend on this connection's upload speed at all." >&2
  exit 1
fi

echo "== Step 3/3: verifying the live site actually served the new build =="
# firebase exiting 0 is necessary but not sufficient (see header comment).
# Retries here are a safety margin for ordinary CDN propagation lag, not an
# attempt to paper over a real mismatch -- a mismatch that persists across
# all attempts is reported as a real failure, not silently accepted.
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

verified=0
REMOTE_HASH=""
for check in $(seq 1 "$HASH_VERIFY_ATTEMPTS"); do
  if curl -sf -o "$TMP_FILE" "${LIVE_URL}/main.dart.js"; then
    REMOTE_HASH="$(hash_file "$TMP_FILE")"
    echo "Live hash (check $check/$HASH_VERIFY_ATTEMPTS, ${LIVE_URL}/main.dart.js): $REMOTE_HASH"
    if [ "$REMOTE_HASH" = "$LOCAL_HASH" ]; then
      verified=1
      break
    fi
  else
    echo "Could not fetch ${LIVE_URL}/main.dart.js (check $check/$HASH_VERIFY_ATTEMPTS)." >&2
  fi
  if [ "$check" -lt "$HASH_VERIFY_ATTEMPTS" ]; then
    sleep "$HASH_VERIFY_DELAY_SECONDS"
  fi
done

if [ "$verified" -ne 1 ]; then
  echo "FAILED: firebase deploy reported success, but the live main.dart.js hash still does not match the local build after $HASH_VERIFY_ATTEMPTS checks." >&2
  echo "  local: $LOCAL_HASH" >&2
  echo "  live:  ${REMOTE_HASH:-<unreachable>}" >&2
  exit 1
fi

echo "SUCCESS: live main.dart.js hash matches the local build ($LOCAL_HASH). Verified at $LIVE_URL"
```

**Version pins used above (confirmed live via `curl https://api.github.com/repos/{owner}/{repo}/releases/latest` + `.../commits/{tag}` on 2026-07-26):**
| Action | Tag | Commit SHA pinned |
|---|---|---|
| `actions/checkout` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `subosito/flutter-action` | v2.23.0 | `1a449444c387b1966244ae4d4f8c696479add0b2` |
| `FirebaseExtended/action-hosting-deploy` | v0.11.0 | `500ac625ca2dd40cbd15f7659af953801858032a` |

If any of these need bumping later, re-resolve the SHA the same way -- do not switch to a mutable tag as a shortcut.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create the GitHub Actions CI deploy workflow</name>
  <files>.github/workflows/deploy-web.yml</files>
  <action>
  Create `.github/workflows/deploy-web.yml` with EXACTLY the content given in the `<interfaces>` block above (full header comment block, path-filtered `on.push.paths` trigger, `workflow_dispatch`, the `FIREBASE_SERVICE_ACCOUNT` guard step, and the three SHA-pinned steps: `actions/checkout`, `subosito/flutter-action`, `FirebaseExtended/action-hosting-deploy`). Match the English-language, "why this exists / what it does not do / setup required / known caveat" comment-block style already established by `.github/workflows/supabase-keep-warm.yml` -- do not shorten or paraphrase the header comment; it documents the measured root cause (17 KB/s uplink, firebase-tools' timeout formula) and the reasons the action/version choices were made. Do not modify `.github/workflows/supabase-keep-warm.yml` or `firebase.json` -- both are out of scope and already correct.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && ruby -ryaml -e "d = YAML.load_file('.github/workflows/deploy-web.yml'); raise 'missing jobs key' unless d.key?('jobs'); raise 'missing deploy job' unless d['jobs'].key?('deploy'); puts 'YAML OK'" && grep -v '^#' .github/workflows/deploy-web.yml | grep -c "FIREBASE_SERVICE_ACCOUNT" && grep -v '^#' .github/workflows/deploy-web.yml | grep -c "workflow_dispatch" && grep -c "3d3c42e5aac5ba805825da76410c181273ba90b1\|1a449444c387b1966244ae4d4f8c696479add0b2\|500ac625ca2dd40cbd15f7659af953801858032a" .github/workflows/deploy-web.yml</automated>
  </verify>
  <done>
  `.github/workflows/deploy-web.yml` exists, parses as valid YAML with `ruby -ryaml`, has a `jobs.deploy` job, contains the `FIREBASE_SERVICE_ACCOUNT` guard step and secret reference (outside comments), contains `workflow_dispatch` (outside comments), and pins all three third-party Actions to the exact commit SHAs listed in the interfaces table. `firebase.json` and `supabase-keep-warm.yml` are unchanged.
  </done>
</task>

<task type="auto">
  <name>Task 2: Create the local hash-verified deploy script</name>
  <files>scripts/deploy_web.sh</files>
  <action>
  Create the `scripts/` directory if it does not already exist, then create `scripts/deploy_web.sh` with EXACTLY the content given in the `<interfaces>` block above (full header comment explaining why the script exists and the specific `firebase deploy | tail` bug it makes impossible, `set -euo pipefail`, the `hash_file()` helper with macOS `md5`/Linux `md5sum` fallback, the bounded 3-attempt deploy retry loop that never pipes `firebase deploy`, and the hash-verification step against the live `main.dart.js`). After writing the file, make it executable: `chmod +x scripts/deploy_web.sh`.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && bash -n scripts/deploy_web.sh && test -x scripts/deploy_web.sh && (command -v shellcheck >/dev/null 2>&1 && shellcheck scripts/deploy_web.sh || echo "shellcheck not installed on this machine -- skipped, bash -n is the baseline gate") && grep -v '^#' scripts/deploy_web.sh | grep -c "if firebase deploy --only hosting; then" && grep -v '^#' scripts/deploy_web.sh | grep -c "hash_file"</automated>
  </verify>
  <done>
  `scripts/deploy_web.sh` exists, is executable, passes `bash -n` (and `shellcheck` if installed), never pipes `firebase deploy` into another command (checked via direct `if firebase deploy --only hosting; then`), defines and uses a `hash_file()` helper for both the local build and the live-fetched file, and only echoes a line beginning `SUCCESS:` after the local and live hashes match.
  </done>
</task>

<task type="checkpoint:human-action" gate="blocking">
  <name>Task 3: Configure the FIREBASE_SERVICE_ACCOUNT GitHub secret</name>
  <what-built>
  `.github/workflows/deploy-web.yml` is committed and will run on the next push to `main` that touches `lib/**`, `web/**`, `pubspec.yaml`, `pubspec.lock`, or `firebase.json` -- but it will fail immediately at its guard step until the `FIREBASE_SERVICE_ACCOUNT` repository secret exists. Creating that secret cannot be automated here: it requires either an interactive, browser-based GitHub authorization (the `firebase init hosting:github` wizard) or manual steps in two separate consoles (GCP IAM and GitHub repo settings), and neither `gcloud` nor `gh` CLI is installed on this machine -- even if they were, granting IAM roles and creating a GitHub secret both need your own authenticated session, not an agent's.
  </what-built>
  <human-action>
  Recommended path -- run from the repo root on your Mac:

    firebase init hosting:github

  Follow its prompts (repository: joostmouw/ridewindow, branch: main). It creates a GCP service account scoped to Hosting deploys and adds a GitHub secret for you. When it offers to write workflow YAML files, decline -- `.github/workflows/deploy-web.yml` already covers that and matches this repo's documented-comment conventions.

  The wizard names the secret it creates `FIREBASE_SERVICE_ACCOUNT_MY_PROJECT_JOOST` (derived from the `my-project-joost` project ID), not `FIREBASE_SERVICE_ACCOUNT`. After it finishes, go to GitHub -> repo -> Settings -> Secrets and variables -> Actions and rename that secret to exactly `FIREBASE_SERVICE_ACCOUNT` (or delete it and re-add its JSON value under the new name) -- the workflow's guard step checks for that exact name.

  Manual alternative (no wizard, if you'd rather not run an interactive CLI flow): GCP Console -> IAM & Admin -> Service Accounts -> Create service account -> grant it the "Firebase Hosting Admin" role on `my-project-joost` (least-privilege for this job -- do not grant Editor/Owner) -> Keys -> Add key -> JSON -> download -> paste the full JSON content as a new repository secret named `FIREBASE_SERVICE_ACCOUNT`.

  Once the secret exists, you can exercise the workflow without waiting for a matching push: GitHub -> repo -> Actions -> "Deploy web to Firebase Hosting" -> Run workflow -> Run workflow (this is the `workflow_dispatch` trigger). Watch the run -- the guard step should now pass and the build/deploy steps run on GitHub's connection instead of this machine's.

  Note: this repo currently has 46 local commits not yet pushed to `origin/main` (per STATE.md). Nothing in this plan pushes them -- that stays your call, separate from this setup.
  </human-action>
  <resume-signal>Type "secret configured" once FIREBASE_SERVICE_ACCOUNT exists in the repo's Actions secrets (a workflow_dispatch test run is optional but recommended before relying on this for a real deploy)</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| GitHub Actions runner -> Firebase Hosting | `deploy-web.yml` authenticates with a service account key capable of publishing to production hosting |
| GitHub secret store -> workflow run logs | `FIREBASE_SERVICE_ACCOUNT` value must never appear in plain text in Actions logs |
| Local Mac -> Firebase Hosting | `scripts/deploy_web.sh` uses the developer's own already-authenticated `firebase` CLI session, no new credential surface introduced |
| Local Mac -> live site (verification) | `scripts/deploy_web.sh` fetches `https://my-project-joost.web.app/main.dart.js` over plain HTTPS to compare hashes -- read-only, no credentials sent |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-quick260726ovf-01 | Tampering | Third-party GitHub Actions (`actions/checkout`, `subosito/flutter-action`, `FirebaseExtended/action-hosting-deploy`) | mitigate | All three pinned to a full commit SHA (not a mutable version tag), confirmed live against each repo's Releases API on 2026-07-26; a compromised or repointed tag cannot silently execute in a job holding a production-hosting-capable credential |
| T-quick260726ovf-02 | Information Disclosure | `FIREBASE_SERVICE_ACCOUNT` secret in workflow logs | mitigate | The guard step only tests the secret for emptiness (`[ -z ... ]`) and never echoes its value; GitHub additionally auto-redacts any registered secret value that does appear in log output |
| T-quick260726ovf-03 | Elevation of Privilege | Service account IAM role granted to the CI credential | mitigate | Task 3's human-action instructions specify the "Firebase Hosting Admin" role only (both the wizard and manual paths) -- explicitly not Editor/Owner -- so a leaked key is scoped to Hosting deploys, not full project control |
| T-quick260726ovf-04 | Repudiation / silent failure | Local script masking a failed deploy behind a piped exit code | mitigate | `scripts/deploy_web.sh` never pipes `firebase deploy` into another command; its exit code is checked directly via `if firebase deploy --only hosting; then`, closing the exact gap that let a failed deploy on 2026-07-26 be reported as a success |
| T-quick260726ovf-05 | Denial of Service (self-inflicted) | Local script's outer retry loop against a genuinely broken uplink | mitigate | Bounded at 3 outer attempts (reasoning documented in the script's header comment) rather than retrying indefinitely; on exhaustion the script fails loudly and points at the CI path as the alternative instead of hanging |
</threat_model>

<verification>
Run both files' automated checks (Task 1 and Task 2 `<verify>` blocks). Confirm `.github/workflows/deploy-web.yml` is not triggered by a hypothetical `.planning/**`-only commit (inspect the `paths` list -- no entry matches `.planning/`). Confirm `scripts/deploy_web.sh` is executable and its final success line is gated behind the hash comparison, not behind `firebase deploy`'s own exit code alone (both checked via the grep assertions in Task 2's verify). Task 3 (human-action) confirms the `FIREBASE_SERVICE_ACCOUNT` secret exists so the workflow can actually run end-to-end -- this plan does not push to `origin/main` or trigger a real deploy itself.
</verification>

<success_criteria>
- `.github/workflows/deploy-web.yml` exists, is valid YAML, triggers only on `workflow_dispatch` or a push to `main` touching `lib/**`, `web/**`, `pubspec.yaml`, `pubspec.lock`, `firebase.json`, or the workflow file itself
- The workflow fails fast with a named, actionable error if `FIREBASE_SERVICE_ACCOUNT` is unset, before attempting any build or deploy work
- All third-party Actions used are pinned to a commit SHA, not a mutable tag
- `scripts/deploy_web.sh` exists, is executable, passes `bash -n` (and `shellcheck` if available)
- `scripts/deploy_web.sh` never pipes `firebase deploy`'s output into a command that would swallow its exit status
- `scripts/deploy_web.sh` only reports success after an independent content-hash comparison between the local build and the live `main.dart.js`
- `firebase.json`'s existing rewrites/headers are untouched
- No `git push`, no secret creation, and no first CI run are performed automatically -- Task 3 hands those to the user explicitly
</success_criteria>

<output>
Create `.planning/quick/260726-ovf-firebase-deploy-betrouwbaar-maken-via-gi/260726-ovf-SUMMARY.md` when done
</output>
