# Phase 21 — Manual Verification Log

This file records the outcomes of every `checkpoint:human-action` step in Phase 21 that
requires a human to operate the Supabase Dashboard SQL Editor (no Supabase CLI is installed
in this environment). Later plans in this phase (21-08, 21-09) append further sections here
rather than creating new files.

Project: `hcdrydlgqpnmumfupgcx` (`https://hcdrydlgqpnmumfupgcx.supabase.co`)

---

## 21-02 — Apply the accounts sync schema migration + RLS deny-case test

**Date:** 2026-08-03
**Performed by:** Joost (orchestrator-run checkpoint, Task 3 of 21-02-PLAN.md)

### 1. Migration state at time of check

The migration (`supabase/migrations/0001_accounts_sync.sql`) was found to be **already
applied** before this checkpoint session began. All four tables existed
(`profiles`, `availability`, `planned_rides`, `feedback`), RLS was enabled on all four, all
4 policies existed, both `plpgsql` functions (`migrate_account_data`, `delete_own_account`)
existed, and both `set_updated_at` triggers existed. A column-by-column inventory was checked
against the migration file and matched exactly for all four tables.

Re-running the migration file (as the plan's Task 3 instructs) failed immediately, as
expected for a schema with no `if not exists` guards:

```
ERROR: 42P07: relation "profiles" already exists
```

The transaction rolled back at that first statement — no partial re-application, no schema
drift from the re-run attempt itself.

### 2. BLOCKING DEFECT FOUND — missing grants on `authenticated`

Running `supabase/tests/rls_deny_test.sql` (the version that existed at checkpoint time,
before this plan's Task 2 rewrite) failed with:

```
ERROR: 42501: permission denied for table profiles
HINT:  Grant the required privileges to the current role with: GRANT SELECT ON public.profiles TO authenticated;
CONTEXT:  SQL statement "select count(*)                    from public.profiles
  where user_id = '11111111-1111-1111-1111-111111111111'"
PL/pgSQL function inline_code_block line 6 at SQL statement
```

A privilege inventory was run against `information_schema.role_table_grants` for all four
tables, confirming the root cause. Grants at the time of the failure:

| Role | Privileges held |
|------|------------------|
| `postgres` | DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE |
| `authenticated` | REFERENCES, TRIGGER, TRUNCATE — **no DML** |
| `anon` | REFERENCES, TRIGGER, TRUNCATE |
| `service_role` | REFERENCES, TRIGGER, TRUNCATE |

Postgres checks table-level privileges **before** it evaluates any RLS policy. The
`authenticated` role is exactly what the app's signed-in Supabase client connects as, and it
was being rejected before any "own row only" policy ever ran. As deployed, a signed-in user
could not read or write even their own rows — this broke SYNC-01/SYNC-02 in practice, not
just the RLS test script. The RLS policies themselves were correct; they were simply
unreachable.

### 3. Fix applied to the live database

The following was run directly in the SQL Editor and returned `Success. No rows returned`:

```sql
grant select, insert, update, delete on public.profiles      to authenticated;
grant select, insert, update, delete on public.availability  to authenticated;
grant select, insert, update, delete on public.planned_rides to authenticated;
grant insert                          on public.feedback     to authenticated;
```

`feedback` is deliberately insert-only — this preserves FB-05 ("can write, can never read
back"). `anon` deliberately received nothing: signed-out users never touch the cloud tables.

This same fix was subsequently added to `supabase/migrations/0001_accounts_sync.sql` itself
(commit `581cd73`, this plan's file-fix task) so that a fresh deploy of the migration produces
a working schema on the first pass, without needing this checkpoint's manual patch again.

### 4. SYNC-08 re-proven, with visible evidence

The original `rls_deny_test.sql` asserted via `raise notice`, but the Supabase SQL Editor does
not surface `NOTICE` lines anywhere in its results panel — a passing run and a silently-skipped
run looked identical. An equivalent transaction that instead **returns** the counts as a result
set was run in its place (the technique later formalized into this plan's Task 2 rewrite of the
test file). Exact result, all inside `begin;`/`rollback;`, nothing persisted:

```
check_name                      | rows_seen
---------------------------------+----------
B select of A row (want 0)      | 0
B update of A row (want 0)      | 0
B delete of A row (want 0)      | 0
A select of own row (want 1)    | 1
```

The first three rows are SYNC-08's deny case (a second, different authenticated user cannot
select, update, or delete the first user's row). The fourth row is the positive case — proof
that the fix actually restored access for the row's own owner, not just that the deny case
still (trivially) held. The original test script never covered this positive case, and the
grants defect would have silently passed every deny-case assertion while still leaving the
app completely broken for its own users.

### Outcome

- Migration schema: **confirmed present and correct** (was already applied; re-run correctly
  rejected as a no-op-by-design).
- Grants defect: **found and fixed**, both live (Dashboard) and in version control
  (`0001_accounts_sync.sql`, commit `581cd73`).
- SYNC-08 deny case: **PASS** (0/0/0 rows affected for the attacking user).
- Positive case (new, not in the original plan's test): **PASS** (1 row visible to the owner).
- Test script itself improved for future re-runs: `supabase/tests/rls_deny_test.sql` now
  returns a visible result table instead of relying on invisible `NOTICE` output (commit
  `01fa355`).

Wave 2/3's outbox and cloud-sink code can now write against this schema with confidence that
both halves of the access story — RLS policies and table grants — are correct and proven
against the real deployed project.

---
