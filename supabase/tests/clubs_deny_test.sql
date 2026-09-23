-- ---------------------------------------------------------------------------
-- clubs_deny_test.sql -- het bewijs voor 0012_groups.sql (fase 33, Clubs)
--
-- WAT HET BEWIJST
--   CLUB-17  Een buitenstaander en een ex-lid lezen niets van een groep: geen
--            groep, geen ledenlijst, geen link, geen groepsrit, geen
--            deelnemers, geen opties, geen stemmen. Een gewoon lid kan geen
--            beheerdershandeling doen; een beheerder wel. Een lid kan wel een
--            groepsrit maken (ook met RETURNING, de valkuil uit 0003) en zijn
--            eigen antwoord geven.
--   CLUB-18  Lid 31 krijgt group_full, groep 11 geeft too_many_groups, en
--            create_group is atomisch: er blijft geen groep zonder beheerder
--            achter.
--   CLUB-10  Opvolging: vertrekt de laatste beheerder, dan wordt het langst
--            zittende lid beheerder. De enige beheerder kan zichzelf niet
--            degraderen (last_admin). Vertrekt het laatste lid, dan verdwijnt
--            de groep.
--   CLUB-19  Hetzelfde via het echte pad: delete_own_account(), aangeroepen
--            als de gebruiker zelf, niet als postgres.
--   CLUB-11  Een opgeheven groep laat zijn ritten staan met group_id = null, en
--            wie op zo'n rit geantwoord had ziet hem weer als gewone gedeelde
--            rit.
--
-- HOE TE DRAAIEN
--   Supabase Dashboard -> SQL Editor -> New query. Plak dit hele bestand en
--   draai het in één keer, NA 0012_groups.sql. Alles zit in één transactie
--   die met `rollback` eindigt, geslaagd of niet: er blijft niets achter in de
--   live database -- geen testgebruikers, geen groepen, geen ritten. Veilig om
--   zo vaak te draaien als je wilt.
--
-- HOE HET RESULTAAT TE LEZEN
--   De SQL Editor toont geen notices (alleen fouten). Daarom komt elke check als rij in
--   een tijdelijke tabel, en het script eindigt met een gewone select:
--
--     seq | check_name | want | got | ok
--
--   Verwacht: 81 rijen, en in elke rij ok = true. Het getal 81 is precies het
--   aantal aanroepen van pg_temp.expect hieronder.
--
--   Mislukt er één check, dan zie je de tabel niet maar een fout:
--     CLUBS DENY-TEST FAILED: 2.8 ... (want 42501, got ok); ...
--   met de naam, het verwachte en het werkelijke antwoord van elke mislukte
--   check. De naam begint met het nummer uit dit bestand. Een fout die NIET met
--   "CLUBS DENY-TEST FAILED" begint, is een fout in het script zelf of in de
--   seed, en zegt nog niets over 0012.
--
--   `got` is een aantal rijen, 'ok' als een handeling slaagde, de sleutel uit
--   0012 (group_full, last_admin, ...) bij een P0001-fout, en anders de
--   SQLSTATE: 42501 = geweigerd door RLS of kolomrecht, 23514 = check-
--   constraint.
--
-- TECHNIEK
--   1. De hoofdpersonen (A t/m E, P, Q, R) krijgen ECHTE rijen in auth.users,
--      met triggers aan. Dat moet: de foreign keys, de guard- en
--      opvolgingstriggers en delete_own_account moeten echt afgaan, en
--      `session_replication_role = replica` schakelt precies die uit (FK's
--      zijn in Postgres ook triggers). Alleen id, aud, role en email worden
--      gezet; de rest van auth.users heeft defaults of mag null zijn.
--   2. Replica gebruiken we alleen voor bulk-seed waar triggers juist NIET
--      mogen lopen: vaste joined_at-waarden (de guard zou ze op now() zetten,
--      en opvolging draait op joined_at), de 30 opvulleden van een volle groep
--      (die zelf geen auth.users-rij hebben) en de negen extra groepen van B.
--   3. Een gebruiker nadoen: `set local role authenticated` plus
--      `set local request.jwt.claims = '{"sub":"<uuid>",...}'`. auth.uid() leest
--      de sub; de rol zorgt dat RLS en grants echt gelden (de editor zelf
--      draait als postgres en omzeilt die). `reset role` gaat terug naar
--      postgres, voor seed en voor controles die door RLS heen moeten kijken.
--   4. Elke check roept pg_temp.expect aan, die een rij schrijft en NIET
--      stopt, zodat alle resultaten zichtbaar worden. Handelingen die mogen
--      mislukken lopen via pg_temp.try_value / try_exec / try_rows: die
--      draaien de SQL in een eigen subtransactie, vangen de fout en geven de
--      sleutel of SQLSTATE terug. Een geweigerde handeling laat dus niets na.
--      Pas helemaal aan het eind beslist één blok: iets mislukt -> exception.
--
-- DE CAST
--   Gebruikers (c1...):  A ..0a beheerder van G   B ..0b lid van G
--                        C ..0c buitenstaander     D ..0d maatje van A, geen lid
--                        E ..0e lid van G, vertrekt
--                        P ..01 beheerder van S    Q ..02 lid van S   R ..03 lid van S
--   Groepen (c2...):     G ..01 'Testgroep'   S ..02 opvolging   GF ..03 vol (30)
--                        ..10 t/m ..18: de negen extra groepen van B
--   Ritten (c3...):      R0 ..01 eigenaar A, groep G    RS ..02 eigenaar R, groep S
--                        R1 ..03 eigenaar B, groep G (maakt B zelf in 2.14)
--   Optie (c4...):       O0 ..01 op R0
--   Links:               GRPTESTA (G, geldig)   GRPXPRD2 (G, verlopen)
--                        GRPNEWA2 (maakt A in 3.2)   GRPMBRA2 (probeert B in 2.6)
--                        GRPFZZZ3 (GF)
-- ---------------------------------------------------------------------------

begin;

-- ---------------------------------------------------------------------------
-- Raamwerk
-- ---------------------------------------------------------------------------

create temporary table club_test_results (
  seq        serial,
  check_name text,
  want       text,
  got        text,
  ok         boolean
) on commit drop;

-- De checks draaien als authenticated, dus die rol moet in de tabel kunnen
-- schrijven. Het temp-schema van deze sessie is voor elke rol bruikbaar.
grant select, insert on club_test_results to authenticated;
grant usage on sequence club_test_results_seq_seq to authenticated;

-- Legt een check vast. Stopt nooit: de eindcontrole beslist.
create function pg_temp.expect(p_name text, p_want text, p_got text)
returns void
language plpgsql
as $$
begin
  insert into pg_temp.club_test_results (check_name, want, got, ok)
  values (p_name, p_want, p_got, p_want is not distinct from p_got);
end;
$$;

-- Eén waarde (een telling, een naam). Bij een fout: de sleutel of de SQLSTATE.
create function pg_temp.try_value(p_sql text)
returns text
language plpgsql
as $$
declare
  v text;
begin
  execute p_sql into v;
  return coalesce(v, 'null');
exception
  when others then
    return case when sqlstate = 'P0001' then sqlerrm else sqlstate end;
end;
$$;

-- Een handeling die moet slagen of mislukken: 'ok', of de sleutel/SQLSTATE.
create function pg_temp.try_exec(p_sql text)
returns text
language plpgsql
as $$
begin
  execute p_sql;
  return 'ok';
exception
  when others then
    return case when sqlstate = 'P0001' then sqlerrm else sqlstate end;
end;
$$;

-- Een update of delete: het aantal geraakte rijen, of de sleutel/SQLSTATE.
-- RLS weigert update/delete meestal stil (0 rijen) in plaats van met een fout.
create function pg_temp.try_rows(p_sql text)
returns text
language plpgsql
as $$
declare
  n bigint;
begin
  execute p_sql;
  get diagnostics n = row_count;
  return n::text;
exception
  when others then
    return case when sqlstate = 'P0001' then sqlerrm else sqlstate end;
end;
$$;

-- ---------------------------------------------------------------------------
-- Seed, deel 1 -- als postgres, triggers AAN
-- ---------------------------------------------------------------------------

insert into auth.users (id, aud, role, email) values
  ('c1000000-0000-0000-0000-00000000000a', 'authenticated', 'authenticated', 'a@clubs-test.invalid'),
  ('c1000000-0000-0000-0000-00000000000b', 'authenticated', 'authenticated', 'b@clubs-test.invalid'),
  ('c1000000-0000-0000-0000-00000000000c', 'authenticated', 'authenticated', 'c@clubs-test.invalid'),
  ('c1000000-0000-0000-0000-00000000000d', 'authenticated', 'authenticated', 'd@clubs-test.invalid'),
  ('c1000000-0000-0000-0000-00000000000e', 'authenticated', 'authenticated', 'e@clubs-test.invalid'),
  ('c1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'p@clubs-test.invalid'),
  ('c1000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'q@clubs-test.invalid'),
  ('c1000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'r@clubs-test.invalid');

-- D heeft een naam, zodat 3.7 kan zien dat de guard-trigger hem uit profiles
-- haalt. Kolommen als in rls_deny_test.sql.
insert into public.profiles (
  user_id, temp_min_ideal_c, temp_max_ideal_c, wind_max_ideal_kmh, rain_max_ideal_mm,
  allowed_durations, theme, locale, location_override, user_name,
  notif_evening_before, notif_morning_of, notif_weekly_digest
) values (
  'c1000000-0000-0000-0000-00000000000d',
  12, 26, 15, 0.5,
  '{2,3}', 'system', 'nl', null, 'Dirk',
  false, false, false
);

-- A en D zijn maatjes (canonieke volgorde uit 0002).
insert into public.friendships (user_a, user_b) values (
  least('c1000000-0000-0000-0000-00000000000a'::uuid, 'c1000000-0000-0000-0000-00000000000d'::uuid),
  greatest('c1000000-0000-0000-0000-00000000000a'::uuid, 'c1000000-0000-0000-0000-00000000000d'::uuid)
);

-- ---------------------------------------------------------------------------
-- Seed, deel 2 -- onder replica: vaste joined_at, geen guard
-- ---------------------------------------------------------------------------

set local session_replication_role = replica;

insert into public.groups (id, name, created_by) values
  ('c2000000-0000-0000-0000-000000000001', 'Testgroep', 'c1000000-0000-0000-0000-00000000000a'),
  ('c2000000-0000-0000-0000-000000000002', 'Opvolgers', 'c1000000-0000-0000-0000-000000000002');

insert into public.group_members (group_id, user_id, role, display_name, joined_at) values
  -- G: A beheerder, B en E lid.
  ('c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000a', 'admin',  'A', now() - interval '3 days'),
  ('c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000b', 'member', 'B', now() - interval '2 days'),
  ('c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000e', 'member', 'E', now() - interval '1 day'),
  -- S: P beheerder, dan Q (langst zittend na P), dan R.
  ('c2000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', 'admin',  'P', now() - interval '3 days'),
  ('c2000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000002', 'member', 'Q', now() - interval '2 days'),
  ('c2000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000003', 'member', 'R', now() - interval '1 day');

insert into public.group_invites (code, group_id, created_by, created_at, expires_at) values
  ('GRPTESTA', 'c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000a',
   now(), now() + interval '7 days'),
  ('GRPXPRD2', 'c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000a',
   now() - interval '10 days', now() - interval '1 day');

insert into public.group_rides (id, owner_id, group_id, start_at, end_at, planned_score, owner_name) values
  ('c3000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000a',
   'c2000000-0000-0000-0000-000000000001',
   now() + interval '2 days', now() + interval '2 days 3 hours', 80, 'A'),
  ('c3000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000003',
   'c2000000-0000-0000-0000-000000000002',
   now() + interval '4 days', now() + interval '4 days 2 hours', 70, 'R');

insert into public.group_ride_options (id, ride_id, start_at, end_at, planned_score) values
  ('c4000000-0000-0000-0000-000000000001', 'c3000000-0000-0000-0000-000000000001',
   now() + interval '2 days', now() + interval '2 days 3 hours', 80);

insert into public.group_ride_option_votes (option_id, user_id, can_ride) values
  ('c4000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000a', true);

insert into public.group_ride_participants (ride_id, user_id, status, display_name) values
  -- E antwoordde op R0; na zijn vertrek (4.6) mag die rij hem niets meer tonen.
  ('c3000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000e', 'accepted', 'E'),
  -- P antwoordde op RS; zie 6.3 en 6.12.
  ('c3000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', 'accepted', 'P');

reset session_replication_role;

-- ---------------------------------------------------------------------------
-- 1. Buitenstaander C ziet en mag niets (CLUB-17)
-- ---------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000c","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('1.1 buitenstaander ziet groep G niet', '0',
    pg_temp.try_value($q$select count(*) from public.groups where id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('1.2 buitenstaander ziet ledenlijst G niet', '0',
    pg_temp.try_value($q$select count(*) from public.group_members where group_id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('1.3 buitenstaander ziet links van G niet', '0',
    pg_temp.try_value($q$select count(*) from public.group_invites where group_id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('1.4 buitenstaander ziet groepsrit R0 niet', '0',
    pg_temp.try_value($q$select count(*) from public.group_rides where id = 'c3000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('1.5 buitenstaander ziet deelnemers R0 niet', '0',
    pg_temp.try_value($q$select count(*) from public.group_ride_participants where ride_id = 'c3000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('1.6 buitenstaander ziet opties R0 niet', '0',
    pg_temp.try_value($q$select count(*) from public.group_ride_options where ride_id = 'c3000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('1.7 buitenstaander ziet stemmen O0 niet', '0',
    pg_temp.try_value($q$select count(*) from public.group_ride_option_votes where option_id = 'c4000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('1.8 buitenstaander hangt geen rit aan groep G', '42501',
    pg_temp.try_exec($q$insert into public.group_rides (owner_id, group_id, start_at, end_at, planned_score)
      values ('c1000000-0000-0000-0000-00000000000c', 'c2000000-0000-0000-0000-000000000001',
              now() + interval '5 days', now() + interval '5 days 2 hours', 60)$q$));
  perform pg_temp.expect('1.9 buitenstaander antwoordt niet op R0', '42501',
    pg_temp.try_exec($q$insert into public.group_ride_participants (ride_id, user_id, status)
      values ('c3000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000c', 'accepted')$q$));
  perform pg_temp.expect('1.10 buitenstaander hernoemt G niet (rijen)', '0',
    pg_temp.try_rows($q$update public.groups set name = 'Gekaapt'
      where id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('1.11 buitenstaander heft G niet op (rijen)', '0',
    pg_temp.try_rows($q$delete from public.groups where id = 'c2000000-0000-0000-0000-000000000001'$q$));
end $$;

-- ---------------------------------------------------------------------------
-- 2. Gewoon lid B: ziet de groep, doet geen beheer, maakt wel ritten (CLUB-17)
-- ---------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000b","role":"authenticated"}';

do $$
declare
  v_id  uuid;
  v_got text;
begin
  perform pg_temp.expect('2.1 lid ziet groep G', '1',
    pg_temp.try_value($q$select count(*) from public.groups where id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('2.2 lid ziet alle leden van G', '3',
    pg_temp.try_value($q$select count(*) from public.group_members where group_id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('2.3 lid ziet groepsrit R0', '1',
    pg_temp.try_value($q$select count(*) from public.group_rides where id = 'c3000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('2.4 lid ziet stemmen op O0', '1',
    pg_temp.try_value($q$select count(*) from public.group_ride_option_votes where option_id = 'c4000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('2.5 lid ziet links van G niet', '0',
    pg_temp.try_value($q$select count(*) from public.group_invites where group_id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('2.6 lid maakt geen link', '42501',
    pg_temp.try_exec($q$insert into public.group_invites (code, group_id, created_by, expires_at)
      values ('GRPMBRA2', 'c2000000-0000-0000-0000-000000000001',
              'c1000000-0000-0000-0000-00000000000b', now() + interval '7 days')$q$));
  perform pg_temp.expect('2.7 lid trekt link niet in (rijen)', '0',
    pg_temp.try_rows($q$delete from public.group_invites where code = 'GRPTESTA'$q$));
  perform pg_temp.expect('2.8 lid voegt geen lid toe', '42501',
    pg_temp.try_exec($q$insert into public.group_members (group_id, user_id)
      values ('c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000d')$q$));
  perform pg_temp.expect('2.9 lid maakt ander lid geen beheerder (rijen)', '0',
    pg_temp.try_rows($q$update public.group_members set role = 'admin'
      where group_id = 'c2000000-0000-0000-0000-000000000001'
        and user_id  = 'c1000000-0000-0000-0000-00000000000e'$q$));
  perform pg_temp.expect('2.10 lid maakt zichzelf geen beheerder (rijen)', '0',
    pg_temp.try_rows($q$update public.group_members set role = 'admin'
      where group_id = 'c2000000-0000-0000-0000-000000000001'
        and user_id  = 'c1000000-0000-0000-0000-00000000000b'$q$));
  perform pg_temp.expect('2.11 lid verwijdert beheerder niet (rijen)', '0',
    pg_temp.try_rows($q$delete from public.group_members
      where group_id = 'c2000000-0000-0000-0000-000000000001'
        and user_id  = 'c1000000-0000-0000-0000-00000000000a'$q$));
  perform pg_temp.expect('2.12 lid hernoemt G niet (rijen)', '0',
    pg_temp.try_rows($q$update public.groups set name = 'Gekaapt'
      where id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('2.13 lid heft G niet op (rijen)', '0',
    pg_temp.try_rows($q$delete from public.groups where id = 'c2000000-0000-0000-0000-000000000001'$q$));

  -- 2.14: precies wat de app doet, `.insert().select()` = INSERT ... RETURNING.
  -- Bij RETURNING geldt de select-policy op de nieuwe rij (de valkuil uit 0003).
  begin
    insert into public.group_rides (id, owner_id, group_id, start_at, end_at, planned_score, owner_name)
    values ('c3000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-00000000000b',
            'c2000000-0000-0000-0000-000000000001',
            now() + interval '3 days', now() + interval '3 days 3 hours', 75, 'B')
    returning id into v_id;
    v_got := case when v_id = 'c3000000-0000-0000-0000-000000000003' then 'ok' else 'verkeerd id' end;
  exception
    when others then
      v_got := case when sqlstate = 'P0001' then sqlerrm else sqlstate end;
  end;
  perform pg_temp.expect('2.14 lid maakt groepsrit met returning', 'ok', v_got);

  perform pg_temp.expect('2.15 lid antwoordt zelf op groepsrit R0', 'ok',
    pg_temp.try_exec($q$insert into public.group_ride_participants (ride_id, user_id, status, display_name)
      values ('c3000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000b', 'accepted', 'B')$q$));
  perform pg_temp.expect('2.16 lid antwoordt niet namens een ander', '42501',
    pg_temp.try_exec($q$insert into public.group_ride_participants (ride_id, user_id, status)
      values ('c3000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000c', 'accepted')$q$));
  perform pg_temp.expect('2.17 lid stemt op O0', 'ok',
    pg_temp.try_exec($q$insert into public.group_ride_option_votes (option_id, user_id, can_ride)
      values ('c4000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000b', true)$q$));
  perform pg_temp.expect('2.18 lid hangt geen rit aan andermans groep S', '42501',
    pg_temp.try_exec($q$insert into public.group_rides (owner_id, group_id, start_at, end_at, planned_score)
      values ('c1000000-0000-0000-0000-00000000000b', 'c2000000-0000-0000-0000-000000000002',
              now() + interval '5 days', now() + interval '5 days 2 hours', 60)$q$));
end $$;

-- ---------------------------------------------------------------------------
-- 3. Beheerder A: links, leden, rollen, naam (CLUB-17, CLUB-10)
-- ---------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000a","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('3.1 beheerder ziet beide links van G', '2',
    pg_temp.try_value($q$select count(*) from public.group_invites where group_id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('3.2 beheerder maakt link GRPNEWA2', 'ok',
    pg_temp.try_exec($q$insert into public.group_invites (code, group_id, created_by, expires_at)
      values ('GRPNEWA2', 'c2000000-0000-0000-0000-000000000001',
              'c1000000-0000-0000-0000-00000000000a', now() + interval '7 days')$q$));
  perform pg_temp.expect('3.3 zwakke code wordt geweigerd', '23514',
    pg_temp.try_exec($q$insert into public.group_invites (code, group_id, created_by, expires_at)
      values ('ABC', 'c2000000-0000-0000-0000-000000000001',
              'c1000000-0000-0000-0000-00000000000a', now() + interval '7 days')$q$));
  perform pg_temp.expect('3.4 beheerder trekt GRPNEWA2 in (rijen)', '1',
    pg_temp.try_rows($q$delete from public.group_invites where code = 'GRPNEWA2'$q$));
  -- Opvolging draait op joined_at; een client die hem zelf zet (hier: jaren
  -- geleden) zou zich naar de kop van de rij kunnen schrijven. Kolomrecht.
  perform pg_temp.expect('3.5 joined_at is niet door de client te zetten', '42501',
    pg_temp.try_exec($q$insert into public.group_members (group_id, user_id, joined_at)
      values ('c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000d',
              '2000-01-01')$q$));
  perform pg_temp.expect('3.6 beheerder voegt maatje D toe', 'ok',
    pg_temp.try_exec($q$insert into public.group_members (group_id, user_id)
      values ('c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000d')$q$));
end $$;

reset role;

do $$
begin
  -- now() is het begin van deze transactie; de guard zet joined_at := now().
  perform pg_temp.expect('3.7 naam uit profiel en joined_at van de server (naam|joined_at>=start)', 'Dirk|true',
    pg_temp.try_value($q$select display_name || '|' || (joined_at >= now())::text
      from public.group_members
      where group_id = 'c2000000-0000-0000-0000-000000000001'
        and user_id  = 'c1000000-0000-0000-0000-00000000000d'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000a","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('3.8 beheerder voegt geen niet-maatje C toe', '42501',
    pg_temp.try_exec($q$insert into public.group_members (group_id, user_id)
      values ('c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000c')$q$));
  perform pg_temp.expect('3.9 beheerder maakt B beheerder (rijen)', '1',
    pg_temp.try_rows($q$update public.group_members set role = 'admin'
      where group_id = 'c2000000-0000-0000-0000-000000000001'
        and user_id  = 'c1000000-0000-0000-0000-00000000000b'$q$));
  perform pg_temp.expect('3.10 beheerder maakt B weer lid (rijen)', '1',
    pg_temp.try_rows($q$update public.group_members set role = 'member'
      where group_id = 'c2000000-0000-0000-0000-000000000001'
        and user_id  = 'c1000000-0000-0000-0000-00000000000b'$q$));
  perform pg_temp.expect('3.11 enige beheerder degradeert zichzelf niet', 'last_admin',
    pg_temp.try_rows($q$update public.group_members set role = 'member'
      where group_id = 'c2000000-0000-0000-0000-000000000001'
        and user_id  = 'c1000000-0000-0000-0000-00000000000a'$q$));
  perform pg_temp.expect('3.12 beheerder hernoemt G (rijen)', '1',
    pg_temp.try_rows($q$update public.groups set name = 'Testgroep 2'
      where id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('3.13 beheerder verwijdert lid D (rijen)', '1',
    pg_temp.try_rows($q$delete from public.group_members
      where group_id = 'c2000000-0000-0000-0000-000000000001'
        and user_id  = 'c1000000-0000-0000-0000-00000000000d'$q$));
end $$;

set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000d","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('3.14 verwijderd lid D ziet G niet meer', '0',
    pg_temp.try_value($q$select count(*) from public.groups where id = 'c2000000-0000-0000-0000-000000000001'$q$));
end $$;
