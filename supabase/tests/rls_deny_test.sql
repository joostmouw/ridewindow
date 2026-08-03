-- RideWindow SYNC-08 proof: one signed-in user cannot read or write another
-- user's rows in public.profiles, via RLS alone — plus the positive case,
-- that a user CAN read their own row (grants + RLS together, not just RLS).
--
-- Self-contained and rollback-safe: everything runs inside a single
-- transaction that is rolled back at the end, pass or fail, so nothing —
-- not even the fabricated seed row — ever persists in the real project.
-- Safe to re-run at any time.
--
-- Apply mechanism: Supabase Dashboard -> SQL Editor -> New query (same as
-- the migration file).
--
-- IMPORTANT: the Supabase SQL Editor does NOT display `raise notice` output
-- anywhere in its results panel (only `raise exception` surfaces, as an
-- error). An earlier version of this script relied solely on `raise notice
-- 'PASS: ...'` lines, which meant a passing run looked identical to a run
-- that silently did nothing — there was no way to see the individual
-- check results, only "no error occurred". This version instead collects
-- each check into a temp table and ends with a plain `select`, so
-- the four rows below are the actual query result you see in the Editor,
-- not something you have to dig for in a logs panel. `raise exception` on
-- FAILED is still kept as a hard stop for automation/CI use.
--
-- Expected result (4 rows):
--   check_name                      | rows_seen
--   ---------------------------------+-----------
--   B select of A row (want 0)      | 0
--   B update of A row (want 0)      | 0
--   B delete of A row (want 0)      | 0
--   A select of own row (want 1)    | 1
--
-- Technique:
--  1. `set local session_replication_role = replica;` seeds one
--     public.profiles row for a fabricated "user A" UUID without needing a
--     matching real auth.users row — this sidesteps guessing GoTrue's
--     auth.users NOT NULL columns by hand. This is a standard, documented
--     Postgres/Supabase technique for seeding FK-constrained data outside
--     normal trigger/FK enforcement.
--  2. `set local role authenticated; set local request.jwt.claims = ...;`
--     simulates a specific signed-in user — Supabase's own documented
--     SQL-Editor RLS testing technique. auth.uid() reads
--     request.jwt.claims->>'sub', and `set role authenticated` makes RLS
--     actually apply, since the SQL Editor's own connecting role is a
--     superuser that bypasses RLS (and grants) by default.
--  3. Assert, via a temp results table plus `raise exception` with the
--     literal message prefix `RLS DENY-CASE FAILED:` on any unexpected
--     result, that: user B's select/update/delete against user A's row
--     all affect zero rows (the deny case), and user A's select of their
--     own row returns exactly one row (the positive case).

begin;

create temporary table rls_test_results (
  seq        serial,
  check_name text,
  rows_seen  int
) on commit drop;

-- Seed user A's row, bypassing the auth.users FK check.
set local session_replication_role = replica;

insert into public.profiles (
  user_id, temp_min_ideal_c, temp_max_ideal_c, wind_max_ideal_kmh, rain_max_ideal_mm,
  allowed_durations, theme, locale, location_override, user_name,
  notif_evening_before, notif_morning_of, notif_weekly_digest
) values (
  '11111111-1111-1111-1111-111111111111',
  12, 26, 15, 0.5,
  '{2,3}', 'system', 'nl', null, 'User A',
  false, false, false
);

-- Reset replication role before simulating either user below, so RLS is
-- actually enforced for the assertions (replica bypasses RLS too).
reset session_replication_role;

-- Simulate user B: a second, different authenticated user attacking user A's row.
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

do $$
declare
  seen_rows int;
  affected_rows int;
begin
  -- SELECT: user B must see zero rows of user A's profile.
  select count(*) into seen_rows
  from public.profiles
  where user_id = '11111111-1111-1111-1111-111111111111';

  insert into rls_test_results (check_name, rows_seen) values ('B select of A row (want 0)', seen_rows);
  if seen_rows <> 0 then
    raise exception 'RLS DENY-CASE FAILED: user B selected % row(s) of user A''s profile', seen_rows;
  end if;

  -- UPDATE: user B must affect zero rows when attempting to update user A's row.
  update public.profiles
  set user_name = 'Hijacked by B'
  where user_id = '11111111-1111-1111-1111-111111111111';

  get diagnostics affected_rows = row_count;
  insert into rls_test_results (check_name, rows_seen) values ('B update of A row (want 0)', affected_rows);
  if affected_rows <> 0 then
    raise exception 'RLS DENY-CASE FAILED: user B updated % row(s) of user A''s profile', affected_rows;
  end if;

  -- DELETE: user B must affect zero rows when attempting to delete user A's row.
  delete from public.profiles
  where user_id = '11111111-1111-1111-1111-111111111111';

  get diagnostics affected_rows = row_count;
  insert into rls_test_results (check_name, rows_seen) values ('B delete of A row (want 0)', affected_rows);
  if affected_rows <> 0 then
    raise exception 'RLS DENY-CASE FAILED: user B deleted % row(s) of user A''s profile', affected_rows;
  end if;
end $$;

-- Simulate user A: the row's own owner, positive case. This proves the
-- grants + RLS combination actually lets an authenticated user read their
-- own data, not just that strangers are denied — a grants-only defect
-- (missing `grant select ... to authenticated`) would fail this exact
-- check while the deny-case checks above would still pass, since a missing
-- grant blocks everyone, owner included.
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

do $$
declare
  seen_rows int;
begin
  select count(*) into seen_rows
  from public.profiles
  where user_id = '11111111-1111-1111-1111-111111111111';

  insert into rls_test_results (check_name, rows_seen) values ('A select of own row (want 1)', seen_rows);
  if seen_rows <> 1 then
    raise exception 'RLS DENY-CASE FAILED: user A selected % row(s) of their own profile (want 1)', seen_rows;
  end if;
end $$;

select check_name, rows_seen from rls_test_results order by seq;

rollback;
