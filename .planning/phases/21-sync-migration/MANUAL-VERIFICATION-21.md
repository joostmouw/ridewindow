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

## Device session — 2026-08-04, Oppo Find X9 Pro (PLG110), app 1.0.14+15

Executed on a real device installed from the Play Store **Internal testing** track
(`installer=com.android.vending`), against the live project `hcdrydlgqpnmumfupgcx`.
Everything below is an observed result, not an expectation.

### False start worth recording

The first attempt appeared to fail completely: no sync status text, and all four tables
empty. Roughly forty minutes went into diagnosing the server side — RPC signature, table
grants, PostgREST schema cache — before checking what was actually installed:

```
versionCode=13  versionName=1.0.12  installer=com.android.vending
```

The device was running the **26 July build**, which contains no Phase 20 or 21 code at all.
Google Play had served it because the device's account was opted into the pre-existing
**closed test** track (still on +13) and not into internal testing (+15). The symptoms were
entirely explained by testing the wrong binary.

**Lesson for future device sessions: assert the installed `versionCode` BEFORE interpreting
any behaviour.** One `adb shell dumpsys package <id> | grep version` would have replaced the
entire investigation. This step is now item 0 of the device checklist.

The server-side checks made during that detour were not wasted, and are recorded here as
genuine results:

- `migrate_account_data` invoked at SQL level as the `authenticated` role with a real
  `auth.users` id and all 14 named arguments: wrote **profiles 1 / availability 1 /
  planned_rides 1**, inside a rolled-back transaction. The 14-argument signature resolves
  correctly — this was the phase's single highest-rated risk and it is now retired.
- `has_function_privilege('authenticated', ...)` is `true` for both `migrate_account_data`
  and `delete_own_account`.
- PostgREST schema cache reloaded via `notify pgrst, 'reload schema'` (precautionary; it was
  not the cause).

### MIG-05/06 — first-login migration: PASS

After updating to 1.0.14+15 and signing in with genuine, non-default local data present:

| table | rows | content |
|-------|------|---------|
| `profiles` | 1 | `Joost \| temp 12-26 \| wind 15 \| regen 0.5 \| duur {2,3,5}` |
| `availability` | 1 | **120 hour blocks**, `{"1-0":"work","1-1":"work",…}` |
| `planned_rides` | 2 | 9 Aug 06:00→08:00 and 9 Aug 11:00→13:00 |

All three carry the identical timestamp `2026-08-04 09:14:46.68055+00` — one atomic RPC, three
tables, at the moment of sign-in. The payload is unambiguously real user data (120 availability
blocks cannot be a default), so this is not an empty push that succeeded by coincidence.
No errors in `adb logcat` (`AccountSection`, `migrate_account_data`, `Postgrest` filters).

### SYNC-05 — outbox drain: FAIL (blocking defect, see plan 21-10)

After signing out and back in, the account row showed **"Wordt gesynchroniseerd..."** and
stayed there. That status text is not cosmetic — it is `outboxPendingCountProvider` accurately
reporting a queue that never empties.

Cause, confirmed by source inspection: **`SyncOutboxService` is never constructed anywhere in
`lib/`, and `drain()` is never called.** The only production consumer of the outbox is
`watchPendingCount()`, which feeds the status text. Repositories enqueue; nothing dequeues.

Impact confirmed against the live database — all three tables still read
`2026-08-04 09:14:46`, unchanged by the second sign-in:

- First-login migration works, because it calls the RPC directly and bypasses the outbox.
- **Every local change after that never reaches the cloud.** Profile edits, availability
  changes and newly planned rides enqueue and stay enqueued.

How it was missed: responsibility for wiring the drain was deferred from plan to plan and then
dropped. `21-03` states *"wave 3 (plans 21-04/21-05) is what actually wires ... the real
Supabase calls into drain()'s callbacks"*; `21-04` states *"the drain step in plan 21-06/21-07
adds user_id when it actually calls .upsert()"*; plans `21-06` and `21-07` do not mention
`drain` at all. No executor deviated from its plan — the plan set never assigned this work.
The full suite is green because `drain()` itself is well tested; only its caller is absent.

This defect was found by the device session and by nothing else.

### Correction to REGRESSION-CHECKLIST-21.md

Section 2 instructed the tester to treat the status text reaching "Gesynchroniseerd" as proof
that the first-login migration succeeded. **That instruction is wrong and has been corrected.**
The status text counts outbox rows, and the first-login migration does not use the outbox — so
on a genuine first login the queue is empty and the text reads "Gesynchroniseerd" whether the
RPC succeeded or failed. The only valid proof is rows in the dashboard.

### Still outstanding from this session

- "Voeg toe aan agenda", sign-out, and restart-persistence (checklist §2, not reached)
- iPhone PWA (§3) — **blocked**: the `deploy-web.yml` workflow has never succeeded since it was
  added on 2026-07-26 (repository secret `FIREBASE_SERVICE_ACCOUNT` was never created), so the
  deployed PWA does not contain Phase 20 or 21 code
- Cold-start measurement (§4), SYNC-11 multi-tab (§5)
- AUTH-09 delete-account (§6, plan 21-08 Task 2) — deliberately left last, destructive

> **Update 2026-08-04 14:58 — de §3-blokkade hierboven is opgelost.** De regel blijft staan als
> historisch verslag van wat er tijdens die sessie waar was. `deploy-web.yml` verwees naar een
> secret dat nooit is aangemaakt; `firebase init hosting:github` heeft er een gemaakt onder de
> naam `FIREBASE_SERVICE_ACCOUNT_MY_PROJECT_JOOST` en de workflow wijst daar nu naartoe (commit
> `4e3957e`, run #3 groen). De PWA serveert sindsdien 1.0.15+16 in plaats van 1.0.12+13.
> §3, §4 en §5 zijn daarmee weer uitvoerbaar; zie het kopblok van `REGRESSION-CHECKLIST-21.md`.

---
