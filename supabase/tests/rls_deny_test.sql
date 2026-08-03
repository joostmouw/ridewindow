-- RideWindow SYNC-08 proof: one signed-in user cannot read or write another
-- user's rows in public.profiles, via RLS alone.
--
-- Self-contained and rollback-safe: everything runs inside a single
-- transaction that is rolled back at the end, pass or fail, so nothing —
-- not even the fabricated seed row — ever persists in the real project.
-- Safe to re-run at any time.
--
-- Apply mechanism: Supabase Dashboard -> SQL Editor -> New query (same as
-- the migration file). Expect three `NOTICE: PASS: ...` lines in the
-- Editor's output/logs panel and no ERROR.
--
-- Technique:
--  1. `set local session_replication_role = replica;` seeds one
--     public.profiles row for a fabricated "user A" UUID without needing a
--     matching real auth.users row — this sidesteps guessing GoTrue's
--     auth.users NOT NULL columns by hand. This is a standard, documented
--     Postgres/Supabase technique for seeding FK-constrained data outside
--     normal trigger/FK enforcement.
--  2. `set local role authenticated; set local request.jwt.claims = ...;`
--     simulates "user B", a second, different signed-in user — Supabase's
--     own documented SQL-Editor RLS testing technique. auth.uid() reads
--     request.jwt.claims->>'sub', and `set role authenticated` makes RLS
--     actually apply, since the SQL Editor's own connecting role is a
--     superuser that bypasses RLS by default.
--  3. Assert, inside a `do $$ ... end $$` block, that user B's select,
--     update, and delete against user A's row all affect zero rows.

begin;

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

-- Reset replication role before simulating the attacking user, so RLS is
-- actually enforced for the assertions below (replica bypasses RLS too).
reset session_replication_role;

-- Simulate user B: a second, different authenticated user.
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

  if seen_rows <> 0 then
    raise exception 'RLS DENY-CASE FAILED: user B selected % row(s) of user A''s profile', seen_rows;
  end if;
  raise notice 'PASS: user B cannot select user A''s profile row';

  -- UPDATE: user B must affect zero rows when attempting to update user A's row.
  update public.profiles
  set user_name = 'Hijacked by B'
  where user_id = '11111111-1111-1111-1111-111111111111';

  get diagnostics affected_rows = row_count;
  if affected_rows <> 0 then
    raise exception 'RLS DENY-CASE FAILED: user B updated % row(s) of user A''s profile', affected_rows;
  end if;
  raise notice 'PASS: user B cannot update user A''s profile row';

  -- DELETE: user B must affect zero rows when attempting to delete user A's row.
  delete from public.profiles
  where user_id = '11111111-1111-1111-1111-111111111111';

  get diagnostics affected_rows = row_count;
  if affected_rows <> 0 then
    raise exception 'RLS DENY-CASE FAILED: user B deleted % row(s) of user A''s profile', affected_rows;
  end if;
  raise notice 'PASS: user B cannot delete user A''s profile row';
end $$;

rollback;
