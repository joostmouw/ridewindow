-- RideWindow v3.0 accounts + sync schema (Phase 21, plan 21-02).
--
-- Apply mechanism: Supabase Dashboard -> SQL Editor -> New query. There is no
-- Supabase CLI installed in this environment (verified: `command -v supabase`
-- fails), so this file is pasted and run manually against the live project
-- (https://hcdrydlgqpnmumfupgcx.supabase.co), the same console-only pattern
-- already used in Phase 18.
--
-- Re-run safety: the `create table` / `create policy` statements below have
-- NO `if not exists` guard, by design. A second accidental run must fail
-- loudly (Postgres will raise "already exists" errors), not silently no-op
-- over a schema someone may have hand-edited in the dashboard.
--
-- Order: (1) tables, (2) RLS + policies, (3) grants, (4) updated_at triggers,
-- (5) migrate_account_data(), (6) delete_own_account().

-- ---------------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------------

create table public.profiles (
  user_id            uuid primary key references auth.users(id) on delete cascade,
  temp_min_ideal_c   real not null,
  temp_max_ideal_c   real not null,
  wind_max_ideal_kmh real not null,
  rain_max_ideal_mm  real not null,
  allowed_durations  int[] not null default '{}',
  theme              text not null default 'system',
  locale             text,
  location_override  text,
  user_name          text,
  notif_evening_before boolean not null default false,
  notif_morning_of     boolean not null default false,
  notif_weekly_digest  boolean not null default false,
  updated_at         timestamptz not null default now(),
  created_at         timestamptz not null default now()
);

create table public.availability (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  recurring  jsonb not null default '{}'::jsonb,  -- {"1-9":"work","6-14":"custom"}
  version    int not null default 1,
  updated_at timestamptz not null default now()
);

create table public.planned_rides (
  user_id       uuid not null references auth.users(id) on delete cascade,
  ride_id       text not null,
  start_at      timestamptz not null,
  end_at        timestamptz not null,
  planned_score real not null,
  created_at    timestamptz not null default now(),
  primary key (user_id, ride_id)
);

create table public.feedback (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete set null,
  rating      int,
  comment     text,
  context     jsonb,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 2. Row-level security + policies
-- ---------------------------------------------------------------------------

alter table public.profiles      enable row level security;
alter table public.availability  enable row level security;
alter table public.planned_rides enable row level security;
alter table public.feedback      enable row level security;

create policy "own profile" on public.profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own availability" on public.availability
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own planned rides" on public.planned_rides
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "insert own feedback" on public.feedback
  for insert with check (user_id is null or auth.uid() = user_id);
-- deliberately NO select policy on feedback: a client can create feedback
-- rows but can never read them back (FB-05, schema half — UI is Phase 22).

-- ---------------------------------------------------------------------------
-- 3. Table grants — necessary but easy to miss: RLS policies alone are NOT
--    sufficient. Postgres checks table-level privileges BEFORE it evaluates
--    any RLS policy, and Supabase's default privileges for the
--    `authenticated` role on newly created tables do NOT include SELECT /
--    INSERT / UPDATE / DELETE — only REFERENCES / TRIGGER / TRUNCATE. Without
--    these grants, a signed-in client using the `authenticated` role is
--    rejected with `permission denied for table ...` before the "own row
--    only" policies above ever run, which would silently break SYNC-01/
--    SYNC-02 (a user could not read or write even their own rows) despite
--    every policy being correct. Discovered by running
--    supabase/tests/rls_deny_test.sql against the live project (see
--    .planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md).
--
--    `feedback` deliberately gets INSERT only, never SELECT/UPDATE/DELETE —
--    this is the grants-level half of FB-05 ("can write, can never read
--    back"), matching the RLS policy above which has no select policy either.
--    `anon` deliberately gets nothing on any of these tables: signed-out
--    users never touch the cloud tables at all.
-- ---------------------------------------------------------------------------

grant select, insert, update, delete on public.profiles      to authenticated;
grant select, insert, update, delete on public.availability  to authenticated;
grant select, insert, update, delete on public.planned_rides to authenticated;
grant insert                          on public.feedback     to authenticated;

-- ---------------------------------------------------------------------------
-- 4. updated_at auto-stamp triggers (profiles, availability only —
--    planned_rides has no updated_at column by design, since
--    resolveAccountSync only ever compares profile/availability timestamps
--    per MIG-04's exact wording)
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger availability_set_updated_at
  before update on public.availability
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 5. migrate_account_data() — MIG-05/06's single rpc()-invoked transaction.
--    Upserts profiles/availability/planned_rides atomically. Derives
--    user_id ONLY from auth.uid(), never from a client-supplied parameter —
--    the elevated-privilege mode below means this runs with elevated
--    privilege, so a parameterised user id would let a signed-in user
--    overwrite anyone's data.
-- ---------------------------------------------------------------------------

create or replace function public.migrate_account_data(
  p_temp_min_ideal_c real,
  p_temp_max_ideal_c real,
  p_wind_max_ideal_kmh real,
  p_rain_max_ideal_mm real,
  p_allowed_durations int[],
  p_theme text,
  p_locale text,
  p_location_override text,
  p_user_name text,
  p_notif_evening_before boolean,
  p_notif_morning_of boolean,
  p_notif_weekly_digest boolean,
  p_availability_recurring jsonb,
  p_planned_rides jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  ride jsonb;
begin
  if uid is null then
    raise exception 'migrate_account_data: not authenticated';
  end if;

  insert into public.profiles (
    user_id, temp_min_ideal_c, temp_max_ideal_c, wind_max_ideal_kmh, rain_max_ideal_mm,
    allowed_durations, theme, locale, location_override, user_name,
    notif_evening_before, notif_morning_of, notif_weekly_digest
  ) values (
    uid, p_temp_min_ideal_c, p_temp_max_ideal_c, p_wind_max_ideal_kmh, p_rain_max_ideal_mm,
    p_allowed_durations, p_theme, p_locale, p_location_override, p_user_name,
    p_notif_evening_before, p_notif_morning_of, p_notif_weekly_digest
  )
  on conflict (user_id) do update set
    temp_min_ideal_c = excluded.temp_min_ideal_c,
    temp_max_ideal_c = excluded.temp_max_ideal_c,
    wind_max_ideal_kmh = excluded.wind_max_ideal_kmh,
    rain_max_ideal_mm = excluded.rain_max_ideal_mm,
    allowed_durations = excluded.allowed_durations,
    theme = excluded.theme,
    locale = excluded.locale,
    location_override = excluded.location_override,
    user_name = excluded.user_name,
    notif_evening_before = excluded.notif_evening_before,
    notif_morning_of = excluded.notif_morning_of,
    notif_weekly_digest = excluded.notif_weekly_digest;

  insert into public.availability (user_id, recurring)
  values (uid, p_availability_recurring)
  on conflict (user_id) do update set
    recurring = excluded.recurring;

  for ride in select * from jsonb_array_elements(coalesce(p_planned_rides, '[]'::jsonb))
  loop
    insert into public.planned_rides (user_id, ride_id, start_at, end_at, planned_score)
    values (
      uid,
      ride->>'rideId',
      (ride->>'startAt')::timestamptz,
      (ride->>'endAt')::timestamptz,
      (ride->>'plannedScore')::real
    )
    on conflict (user_id, ride_id) do update set
      start_at = excluded.start_at,
      end_at = excluded.end_at,
      planned_score = excluded.planned_score;
  end loop;
end;
$$;

-- Note: the on conflict do update clauses on profiles/availability
-- deliberately omit updated_at — the triggers above stamp it automatically
-- on every insert ... on conflict do update (Postgres fires BEFORE UPDATE
-- triggers for the DO UPDATE branch of an upsert), so this function body
-- never needs to set it itself.

grant execute on function public.migrate_account_data(
  real, real, real, real, int[], text, text, text, text, boolean, boolean, boolean, jsonb, jsonb
) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. delete_own_account() — AUTH-09's actual deletion trigger. A bare
--    anon-key client cannot call auth.admin.deleteUser() (needs the
--    service-role key), so this elevated-privilege function is the client's
--    only path to remove their own auth.users row. The foreign-key rules
--    defined on the four tables above then do the rest, structurally, once
--    auth.users loses the row. Derives the target row only from auth.uid(),
--    same reasoning as above.
-- ---------------------------------------------------------------------------

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'delete_own_account: not authenticated';
  end if;
  delete from auth.users where id = uid;
end;
$$;

grant execute on function public.delete_own_account() to authenticated;
