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
