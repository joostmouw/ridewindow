---
phase: 21-sync-migration
plan: 02
subsystem: database
tags: [postgres, supabase, rls, sql, grants, migration]

# Dependency graph
requires:
  - phase: 21-sync-migration
    provides: "21-01's resolveAccountSync pure decision function (the client-side logic this schema's data will feed)"
  - phase: 18-preconditions
    provides: "Live Supabase project (hcdrydlgqpnmumfupgcx), console-only apply pattern (no CLI in this environment)"
provides:
  - "profiles/availability/planned_rides/feedback tables in Postgres, RLS-enabled, with same-shape 'own row only' policies on the first three"
  - "feedback insert-only policy (no select) — FB-05's schema half"
  - "migrate_account_data() and delete_own_account() security definer plpgsql functions, both deriving the acting user only from auth.uid()"
  - "Table-level grants for authenticated (SELECT/INSERT/UPDATE/DELETE on profiles/availability/planned_rides, INSERT-only on feedback) — the missing half of the access story that RLS alone cannot provide"
  - "SYNC-08 proven against the real deployed database: a second authenticated user cannot select/update/delete a first user's row, AND the row's own owner CAN select it (both cases, not just the deny case)"
  - "MANUAL-VERIFICATION-21.md — the running log for all Phase 21 human-action checkpoints"
affects: [21-03, 21-04, 21-05, 21-06, 21-07, 21-08, 21-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Table-level GRANT statements are a required, separate step alongside RLS policies — Postgres checks privileges before policies, and Supabase does not grant DML to `authenticated` by default on new tables"
    - "RLS test scripts must return a visible result set (temp table + select), not rely on raise notice — the Supabase SQL Editor does not surface NOTICE output"
    - "RLS test coverage needs both a deny case (stranger denied) and a positive case (owner allowed) — a missing-grants defect passes every deny case while still breaking the app for its own users"

key-files:
  created:
    - .planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md
  modified:
    - supabase/migrations/0001_accounts_sync.sql
    - supabase/tests/rls_deny_test.sql
    - docs/ACCOUNTS-OPERATIONS.md

key-decisions:
  - "Amended migration 0001 in place with the missing grants, rather than adding a 0002 file — safe here because there is no migration-tracking table and no data in the schema yet; explicit user decision."
  - "feedback table receives INSERT-only grant for authenticated (no SELECT/UPDATE/DELETE), matching its existing insert-only RLS policy — FB-05 enforced at both the grants and policy layer."
  - "anon receives no grants on any of the four tables — signed-out users never touch the cloud schema, by design."
  - "rls_deny_test.sql rewritten to collect check results in a temp table and return them via select, because raise notice output is invisible in the Supabase SQL Editor — a passing run and a silently-skipped run were indistinguishable before this change."
  - "Added a positive-case assertion (owner CAN select their own row) to rls_deny_test.sql — the original script only tested the deny case, which a missing-grants defect would pass while leaving the app broken for everyone."

requirements-completed: [SYNC-01, SYNC-02, SYNC-03, SYNC-08, SYNC-09, SYNC-10, SYNC-12, MIG-05, MIG-06, MIG-07, AUTH-09]

# Metrics
duration: ~23min (active work; excludes the wait for the human-action checkpoint itself)
completed: 2026-08-03
---

# Phase 21 Plan 02: Accounts Sync Schema, RLS + Grants Migration Summary

**Deployed the Postgres schema (4 tables, RLS, 2 security-definer RPC functions) for accounts sync, then found and fixed a missing-grants defect live against the deployed project that would have silently blocked every signed-in user from reading or writing their own data despite fully correct RLS policies.**

## Performance

- **Duration:** ~23 min active work across Tasks 1, 2, and this continuation (Task 3's checkpoint itself was performed by the orchestrator directly in the Supabase Dashboard, outside agent execution time)
- **Started:** 2026-08-03T19:44:43+02:00
- **Completed:** 2026-08-03T20:07:09+02:00
- **Tasks:** 3 (2 `auto` + 1 `checkpoint:human-action`), plus this continuation's fix/test/docs/summary work
- **Files modified:** 4 (`supabase/migrations/0001_accounts_sync.sql`, `supabase/tests/rls_deny_test.sql`, `docs/ACCOUNTS-OPERATIONS.md`, `.planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md` created)

## Accomplishments

- Authored and applied the full accounts-sync schema to the live Supabase project: `profiles`, `availability`, `planned_rides`, `feedback` tables, RLS enabled on all four, 4 policies, 2 `updated_at` triggers, and the two `security definer` `plpgsql` functions (`migrate_account_data`, `delete_own_account`) that MIG-05/06 and AUTH-09 require.
- Found and fixed a real, blocking production defect during the live checkpoint: the `authenticated` role had no table-level DML grants on any of the four tables (Supabase's default for newly created tables), which meant a signed-in client was rejected with `permission denied for table` before any RLS policy ever ran — SYNC-01/SYNC-02 were broken in practice, not just the test script.
- Proved SYNC-08 against the real deployed database, both directions: a second authenticated user cannot select/update/delete a first user's row (the deny case), and that same first user CAN select their own row (the positive case, added specifically because the grants defect would have passed every deny-case check while leaving the app unusable for its own users).
- Made the RLS test script's results actually visible in the Supabase SQL Editor by replacing `raise notice`-only output (which the Editor's results panel never displays) with a temp-table-backed `select` that returns a 4-row result table.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author the schema + RLS + functions migration** - `797656b` (feat)
2. **Task 2: Author the RLS deny-case test SQL** - `7902567` (test)
   - Follow-up doc update: `073171c` (docs — names `delete_own_account()` in ACCOUNTS-OPERATIONS.md §4)
3. **Task 3: Apply migration + run RLS test against the live project** - performed by the orchestrator directly in the Supabase Dashboard (checkpoint:human-action, no direct commit — see MANUAL-VERIFICATION-21.md)

**Post-checkpoint fix work (this continuation):**
4. **Grants fix applied to migration file** - `581cd73` (fix)
5. **RLS test rewritten for visible output + positive case** - `01fa355` (test)
6. **MANUAL-VERIFICATION-21.md recorded** - `8a3f027` (docs)

**Plan metadata:** (this commit, following SUMMARY)

## Files Created/Modified

- `supabase/migrations/0001_accounts_sync.sql` - 4 tables, RLS + policies, table grants for `authenticated`, 2 triggers, 2 `security definer` RPC functions
- `supabase/tests/rls_deny_test.sql` - Self-contained, rollback-safe SYNC-08 proof; now returns a visible result table (deny case + positive case) instead of relying on invisible `NOTICE` output
- `docs/ACCOUNTS-OPERATIONS.md` - §4 names `delete_own_account()` as AUTH-09's actual client-facing trigger
- `.planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md` - New. Running log for Phase 21's human-action checkpoints; records this plan's checkpoint outcome verbatim including the defect found and fixed

## Decisions Made

- Amended migration `0001` in place with the missing grants rather than creating a `0002` file — explicitly decided by the user, safe because there is no migration-tracking table and no data exists yet in the live schema.
- `feedback` grants are INSERT-only for `authenticated` (no SELECT/UPDATE/DELETE), mirroring its existing insert-only RLS policy — FB-05 ("can write, can never read back") is now enforced at both the grants layer and the policy layer.
- `anon` receives zero grants on all four tables — signed-out users never touch the cloud schema at all, by design.
- The RLS test's temp results table uses a `serial` sequence column purely for guaranteed row ordering in the final `select`, not as durable state (it is dropped with the transaction rollback either way).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Missing table-level grants for `authenticated` on all four sync tables**
- **Found during:** Task 3's live checkpoint (running `rls_deny_test.sql` against the real deployed project)
- **Issue:** The plan's migration SQL (`<interfaces>` block, reproduced verbatim from `ARCHITECTURE.md` §3) specified RLS policies but never specified table-level `GRANT` statements. Postgres checks table-level privileges before evaluating any RLS policy, and Supabase's default privileges for `authenticated` on newly created tables are `REFERENCES, TRIGGER, TRUNCATE` only — no `SELECT`/`INSERT`/`UPDATE`/`DELETE`. As deployed, every RLS policy was correct but unreachable: a signed-in client was rejected with `ERROR: 42501: permission denied for table profiles` before RLS ever ran. This is a real production defect — SYNC-01 and SYNC-02 (a user reading/writing their own data) were broken, not just the test script.
- **Fix:** Applied `grant select, insert, update, delete on public.profiles/availability/planned_rides to authenticated;` and `grant insert on public.feedback to authenticated;` live in the Supabase Dashboard (orchestrator-run, confirmed `Success. No rows returned`), then added the same statements to `supabase/migrations/0001_accounts_sync.sql` with a why-comment so a fresh deploy is correct on the first pass.
- **Files modified:** `supabase/migrations/0001_accounts_sync.sql` (live DB fix applied out-of-band by the orchestrator; version-controlled fix committed separately)
- **Verification:** Re-ran the RLS proof (equivalent to the eventual `rls_deny_test.sql` rewrite) after the grant, live against the project — 4-row result confirmed: the three deny-case checks at 0 rows, plus a new positive-case check confirming the row's owner could now select 1 row (previously would also have failed with `42501`, proving the grants — not just the policies — were the actual gate).
- **Committed in:** `581cd73`

**2. [Rule 1 - Bug] `rls_deny_test.sql`'s pass/fail output was invisible in the tool used to run it**
- **Found during:** Task 3's live checkpoint — the original `raise notice 'PASS: ...'` lines never appeared anywhere in the Supabase SQL Editor's results or logs panel, so a genuinely passing run and a silently no-op run were indistinguishable by inspection; the only signal available was "no `ERROR` occurred."
- **Fix:** Rewrote the script to insert each check's result into a temporary table and end with a `select`, so the actual query result returned to the Editor is the 4-row proof table (three deny-case rows + the new positive-case row), leaving `raise exception` in place as a hard stop for automation/CI use.
- **Files modified:** `supabase/tests/rls_deny_test.sql`
- **Verification:** Re-read the full file; confirmed the original acceptance criteria (`session_replication_role = replica` present, `request.jwt.claims` present, `RLS DENY-CASE FAILED` present ≥3 times, `rollback;` is the last non-comment line) still hold after the rewrite.
- **Committed in:** `01fa355`

---

**Total deviations:** 2 auto-fixed (1 missing-critical-functionality, 1 bug)
**Impact on plan:** Both fixes are correctness-and-security-essential, not scope creep — the grants defect would have shipped a schema that is provably unusable by its own users despite passing code review of the RLS policies alone, and the invisible-output bug would have let that defect (or a future regression of it) go undetected by anyone actually running the test as documented.

## Issues Encountered

None beyond the deviations above — no unresolved problems.

## User Setup Required

None beyond what Task 3's checkpoint already covered (already performed): the migration and the RLS deny-case test were both run against the live Supabase Dashboard SQL Editor for project `hcdrydlgqpnmumfupgcx`. See `.planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md` for the full transcript of that session, including the defect found and the fix applied.

## Next Phase Readiness

- The real, deployed Postgres schema — tables, RLS, grants, and both RPC functions — is confirmed correct and ready for Wave 2/3's outbox and cloud-sink client code (plans 21-03 onward) to write against.
- `MANUAL-VERIFICATION-21.md` is established as the shared running log; 21-08 and 21-09 should append their own checkpoint sections to this same file rather than creating new ones.
- No blockers for the next plan.

---
*Phase: 21-sync-migration*
*Completed: 2026-08-03*

## Self-Check: PASSED

All created/modified files confirmed present on disk: `supabase/migrations/0001_accounts_sync.sql`, `supabase/tests/rls_deny_test.sql`, `docs/ACCOUNTS-OPERATIONS.md`, `.planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md`, `.planning/phases/21-sync-migration/21-02-SUMMARY.md`.

All cited commits confirmed present in `git log --oneline --all`: `797656b`, `7902567`, `073171c`, `581cd73`, `01fa355`, `8a3f027`.
