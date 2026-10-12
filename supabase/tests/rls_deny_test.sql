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
-- each check as JSON in a transaction-local setting (rw_test.results) and
-- ends with a plain `select` that unpacks it, so
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
--  3. Assert, via the rw_test.results setting plus `raise exception` with the
--     literal message prefix `RLS DENY-CASE FAILED:` on any unexpected
--     result, that: user B's select/update/delete against user A's row
--     all affect zero rows (the deny case), and user A's select of their
--     own row returns exactly one row (the positive case).

begin;

-- Geen tijdelijke tabel: in de SQL Editor gaf de slotselect op een
-- temp-tabel uit hetzelfde script altijd 42P01, ook in een kaal script van
-- vijf regels (2026-10-12), terwijl een transactie-lokale instelling daar
-- wél zichtbaar bleek. De rollback ruimt die net zo grondig op, en de
-- helper werkt ook als authenticated: een eigen instelling mag elke rol
-- zetten.
create function pg_temp.record(p_name text, p_rows int)
returns void
language plpgsql
as $$
declare
  l_all jsonb := coalesce(nullif(current_setting('rw_test.results', true), ''),
                          '[]')::jsonb;
begin
  perform set_config('rw_test.results',
    (l_all || jsonb_build_array(jsonb_build_object(
       'seq', jsonb_array_length(l_all) + 1,
       'check_name', p_name,
       'rows_seen', p_rows)))::text,
    true);
end;
$$;

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

  perform pg_temp.record('B select of A row (want 0)', seen_rows);
  if seen_rows <> 0 then
    raise exception 'RLS DENY-CASE FAILED: user B selected % row(s) of user A''s profile', seen_rows;
  end if;

  -- UPDATE: user B must affect zero rows when attempting to update user A's row.
  update public.profiles
  set user_name = 'Hijacked by B'
  where user_id = '11111111-1111-1111-1111-111111111111';

  get diagnostics affected_rows = row_count;
  perform pg_temp.record('B update of A row (want 0)', affected_rows);
  if affected_rows <> 0 then
    raise exception 'RLS DENY-CASE FAILED: user B updated % row(s) of user A''s profile', affected_rows;
  end if;

  -- DELETE: user B must affect zero rows when attempting to delete user A's row.
  delete from public.profiles
  where user_id = '11111111-1111-1111-1111-111111111111';

  get diagnostics affected_rows = row_count;
  perform pg_temp.record('B delete of A row (want 0)', affected_rows);
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

  perform pg_temp.record('A select of own row (want 1)', seen_rows);
  if seen_rows <> 1 then
    raise exception 'RLS DENY-CASE FAILED: user A selected % row(s) of their own profile (want 1)', seen_rows;
  end if;
end $$;

-- Bewust zonder pg_temp-functie en met een lege terugval: als de editor
-- deze select ook buiten de sessie van het script uitvoert, levert dat een
-- lege set op in plaats van een fout die het echte resultaat verdringt.
select r.check_name, r.rows_seen
  from jsonb_to_recordset(
         coalesce(nullif(current_setting('rw_test.results', true), ''),
                  '[]')::jsonb)
       as r(seq int, check_name text, rows_seen int)
 order by r.seq;

rollback;
