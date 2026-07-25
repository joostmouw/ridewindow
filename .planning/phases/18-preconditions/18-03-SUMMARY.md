---
phase: 18-preconditions
plan: 03
subsystem: infra
tags: [github-actions, supabase, cron, keep-warm]

# Dependency graph
requires:
  - phase: 18-preconditions (plan 02)
    provides: Provisioned Supabase project (eu-west-3, hcdrydlgqpnmumfupgcx.supabase.co)
provides:
  - Scheduled GitHub Actions workflow that pings the Supabase project every 3 days so the free-tier 7-day inactivity pause never triggers
  - Hand-triggerable workflow_dispatch entry point to wake the project on demand
  - A guard step that fails with a clear "not configured" message before the secrets are set, instead of an opaque curl error
affects: [19-auth, 21-sync-migration]

# Tech tracking
tech-stack:
  added: [GitHub Actions (first workflow in this repository)]
  patterns: ["Guard step before external-call steps: fail loudly with an actionable message when required repo vars/secrets are unset, rather than letting the real step fail opaquely"]

key-files:
  created: [.github/workflows/supabase-keep-warm.yml]
  modified: []

key-decisions:
  - "Cron schedule '0 6 */3 * *' (day-of-month modulo 3) keeps the gap between runs at 3 days or fewer year-round, including month boundaries, while never running more than once a day"
  - "Endpoint chosen: /rest/v1/ (PostgREST root) — answers an authenticated request without any table existing, so the job works through Phases 18-20 before the Phase 21 schema lands"
  - "curl --fail-with-body (not plain --fail) so a non-2xx response still prints its body for diagnosis, combined with --write-out to echo the HTTP status into the job log"
  - "Anon key stored as a repository secret (secrets.SUPABASE_ANON_KEY) even though it is designed to be public by Supabase's own model — tidiness/readability rather than actual secrecy, per plan interfaces guidance"

patterns-established:
  - "Guard-step-before-payload-step: verify required repository vars/secrets are non-empty and fail with an explicit human-readable message before attempting the real network call"

requirements-completed: [PRE-08]

# Metrics
duration: ~10min
completed: 2026-07-25
---

# Phase 18 Plan 03: Supabase keep-warm workflow Summary

**GitHub Actions cron job (every 3 days) that pings the Supabase project's `/rest/v1/` REST root with the anon key, failing loudly on any non-2xx response so the free-tier 7-day inactivity pause never silently triggers.**

## Performance

- **Duration:** ~10min
- **Tasks:** 1 completed
- **Files modified:** 1 created

## Accomplishments
- `.github/workflows/supabase-keep-warm.yml` created — the first workflow in the `joostmouw/ridewindow` repository
- `schedule` (cron, every 3 days) + `workflow_dispatch` (hand-trigger from the Actions tab) triggers both present
- Guard step fails with an explicit "not configured" message if `SUPABASE_URL` (repo variable) or `SUPABASE_ANON_KEY` (repo secret) is empty, so the first-run failure is diagnosable at a glance rather than an opaque curl error
- Curl invocation uses `--fail-with-body` (fails loudly on non-2xx, still shows body) and `--max-time 15` (a hung connection cannot pin the runner), and echoes the HTTP status via `--write-out` into the job log
- Comment block at the top of the file explains the 7-day pause mechanism, that this job only prevents the pause (does not monitor health), and the 60-day repository-inactivity caveat for scheduled workflows
- No literal Supabase project ref or JWT string appears in the file — both values are read from `vars.SUPABASE_URL` / `secrets.SUPABASE_ANON_KEY`
- Confirmed `.github/workflows/` contains exactly this one file — no CI pipeline introduced, per the plan's explicit scope fence

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the scheduled keep-warm workflow (PRE-08)** - `732ee16` (feat)

## Files Created/Modified
- `.github/workflows/supabase-keep-warm.yml` - Scheduled + hand-triggerable GitHub Actions workflow that pings the Supabase project's REST root to prevent the free-tier 7-day inactivity pause

## Decisions Made
- Cron expression `0 6 */3 * *` (day-of-month divisible-by-3 pattern) chosen over a fixed weekday list — verified the maximum gap between runs is always ≤ 3 days, including across month boundaries (e.g. day 28 → day 1 of a 28-day February is a 1-day gap; day 31 → day 1 of a 31-day month is a 1-day gap; the largest gap, day 28 → day 31 in a 31-day month, is exactly 3 days).
- `/rest/v1/` (PostgREST root) chosen over `/auth/v1/health` as the ping target — it is the endpoint the plan's interfaces section named first, and it does not require any table to exist, matching the requirement that this job keeps working before the Phase 21 schema lands.
- No architectural deviations — this task matched the plan's `<action>` and `<acceptance_criteria>` closely enough that no Rule 1-4 fixes were needed.

## Deviations from Plan

None — plan executed exactly as written. All nine acceptance criteria verified directly against the committed file (YAML parses via Ruby's `YAML.load_file` since this sandbox's `python3` lacked `PyYAML` and no package install was warranted for a one-off validation; `schedule:`/`workflow_dispatch:` present; cron interval ≤ 3 days; `secrets.SUPABASE_ANON_KEY`/`vars.SUPABASE_URL` present; no literal project ref or JWT; `--fail-with-body` and `--max-time` present; guard step present; 7-day and 60-day comments present).

## Issues Encountered

The Python interpreter available in this environment does not have `PyYAML` installed, so the plan's literal verification command (`python3 -c "import yaml..."`) could not run as written. Used Ruby's built-in `YAML.load_file` instead, which is an equivalent structural check (both are standard YAML 1.1 parsers) and avoided installing a new package purely for a one-off local check. Not logged as a Rule 3 fix since it did not touch the deliverable itself, only the verification method.

## User Setup Required

**External service configuration required before this workflow can run successfully.** In the GitHub repository (`joostmouw/ridewindow`) settings, under **Settings → Secrets and variables → Actions**, add:
- **Repository variable** `SUPABASE_URL` = `https://hcdrydlgqpnmumfupgcx.supabase.co`
- **Repository secret** `SUPABASE_ANON_KEY` = the project's anon/public key (found in the Supabase dashboard under Project Settings → API)

Until both are set, every run (scheduled or manual) will fail at the guard step with an explicit "not configured" message — this is intentional per the plan's acceptance criteria, not a bug. After adding both, a manual `workflow_dispatch` run from the Actions tab should complete green; this has not yet been verified live since it requires the user's own GitHub session and the actual anon key.

## Next Phase Readiness

PRE-08 is satisfied: the keep-warm workflow exists, is scheduled comfortably inside the 7-day pause window, is hand-triggerable, fails loudly on error, needs no schema, and introduces no CI. No blockers for Phase 19 (Auth) or Phase 21 (Sync). One open item for the user (not Claude): add the two repository secrets/variables listed above, and once added, do one manual `workflow_dispatch` run to confirm it goes green — this closes the loop the plan's own `<verification>` section calls for.

---
*Phase: 18-preconditions*
*Completed: 2026-07-25*
