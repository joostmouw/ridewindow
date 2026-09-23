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
-- BIJGEWERKT VOOR 0013 (fase 34)
--   0013 wijzigt twee dingen bewust; alleen daar zijn verwachtingen aangepast,
--   de rest van het fase-33-bewijs staat ongewijzigd:
--   - Ieder lid ziet en maakt groepslinks (intrekken blijft beheerderswerk):
--     2.5 (lid ziet de links: 2) en 2.6 (lid maakt GRPMBRA2: ok) zijn
--     omgedraaid; 2.7 (lid trekt niet in) blijft. Daardoor ziet A in 3.1 drie
--     links in plaats van twee.
--   - Inwisselen van de link maakt een aanvraag, geen lid: nieuw zijn 4.2b
--     (C is na inwisselen nog geen lid) en 4.2c (beheerder A accepteert de
--     aanvraag van C), zodat alle latere checks die C als lid veronderstellen
--     blijven kloppen.
--   Het bewijs voor de nieuwe rechten zelf staat in
--   clubs_requests_deny_test.sql.
--
-- HOE TE DRAAIEN
--   Supabase Dashboard -> SQL Editor -> New query. Plak dit hele bestand en
--   draai het in één keer, NA 0012_groups.sql en 0013_group_join_requests.sql. Alles zit in één transactie
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
--   Verwacht: 83 rijen, en in elke rij ok = true. Het getal 83 is precies het
--   aantal aanroepen van pg_temp.expect hieronder (alle fase-33-checks, plus 4.2b
--   en 4.2c voor 0013).
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
--                        GRPNEWA2 (maakt A in 3.2)   GRPMBRA2 (maakt lid B in 2.6)
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
  -- 0013: ieder lid ziet en maakt groepslinks (GRPTESTA en de verlopen GRPXPRD2).
  perform pg_temp.expect('2.5 lid ziet de links van G (0013: ieder lid)', '2',
    pg_temp.try_value($q$select count(*) from public.group_invites where group_id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('2.6 lid maakt link GRPMBRA2 (0013: ieder lid)', 'ok',
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
  -- Keuze: GRPMBRA2 van B uit 2.6 blijft bestaan (opruimen zou alleen een
  -- postgres-delete zijn); hij telt hier dus mee, en in 7.2 verdwijnt hij met
  -- de groep. Geen andere check telt links van G.
  perform pg_temp.expect('3.1 beheerder ziet alle drie links van G (ook die van B uit 2.6)', '3',
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

-- ---------------------------------------------------------------------------
-- 4. Inwisselen via de link, en het ex-lid (CLUB-17, CLUB-13)
-- ---------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000c","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('4.1 verlopen link wordt geweigerd', 'invite_invalid',
    pg_temp.try_value($q$select group_name from public.redeem_group_invite('GRPXPRD2')$q$));
  -- Kleine letters en spaties: een geplakte code is zelden netjes.
  perform pg_temp.expect('4.2 C wisselt ''  grptesta  '' in en krijgt de groepsnaam', 'Testgroep 2',
    pg_temp.try_value($q$select group_name from public.redeem_group_invite('  grptesta  ')$q$));
end $$;

-- 0013: de link levert een aanvraag op, geen lid. Als postgres vaststellen
-- dat C nog geen lid is, dan laat beheerder A hem toe, en daarna gaat het
-- verder als C.
reset role;

do $$
begin
  perform pg_temp.expect('4.2b C is na inwisselen nog geen lid van G (0013: aanvraag)', '0',
    pg_temp.try_value($q$select count(*) from public.group_members
      where group_id = 'c2000000-0000-0000-0000-000000000001'
        and user_id  = 'c1000000-0000-0000-0000-00000000000c'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000a","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('4.2c beheerder A accepteert de aanvraag van C', 'ok',
    pg_temp.try_exec($q$select public.accept_group_request((
      select r.id from public.group_join_requests r
      where r.group_id = 'c2000000-0000-0000-0000-000000000001'
        and r.user_id  = 'c1000000-0000-0000-0000-00000000000c'))$q$));
end $$;

set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000c","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('4.3 nieuw lid C ziet G', '1',
    pg_temp.try_value($q$select count(*) from public.groups where id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('4.4 nieuw lid C ziet een rit van voor zijn lidmaatschap', '1',
    pg_temp.try_value($q$select count(*) from public.group_rides where id = 'c3000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('4.5 C wisselt dezelfde link nog eens in', 'ok',
    pg_temp.try_exec($q$select * from public.redeem_group_invite('GRPTESTA')$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('4.5b C staat daarna een keer in G, niet twee keer', '1',
    pg_temp.try_value($q$select count(*) from public.group_members
      where group_id = 'c2000000-0000-0000-0000-000000000001'
        and user_id  = 'c1000000-0000-0000-0000-00000000000c'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000e","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('4.6 E verlaat G (rijen)', '1',
    pg_temp.try_rows($q$delete from public.group_members
      where group_id = 'c2000000-0000-0000-0000-000000000001'
        and user_id  = 'c1000000-0000-0000-0000-00000000000e'$q$));
  -- E heeft nog zijn participant-rij op R0, maar die geeft op een groepsrit
  -- geen toegang meer (keuze f in 0012).
  perform pg_temp.expect('4.7 ex-lid E ziet G niet meer', '0',
    pg_temp.try_value($q$select count(*) from public.groups where id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('4.8 ex-lid E ziet ledenlijst G niet meer', '0',
    pg_temp.try_value($q$select count(*) from public.group_members where group_id = 'c2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('4.9 ex-lid E ziet R0 niet meer, ondanks zijn participant-rij', '0',
    pg_temp.try_value($q$select count(*) from public.group_rides where id = 'c3000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('4.10 ex-lid E ziet deelnemers R0 niet meer, ook zijn eigen rij niet', '0',
    pg_temp.try_value($q$select count(*) from public.group_ride_participants where ride_id = 'c3000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('4.11 ex-lid E ziet opties R0 niet meer', '0',
    pg_temp.try_value($q$select count(*) from public.group_ride_options where ride_id = 'c3000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('4.12 ex-lid E ziet stemmen O0 niet meer', '0',
    pg_temp.try_value($q$select count(*) from public.group_ride_option_votes where option_id = 'c4000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('4.13 ex-lid E antwoordt niet op groepsrit R1', '42501',
    pg_temp.try_exec($q$insert into public.group_ride_participants (ride_id, user_id, status)
      values ('c3000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-00000000000e', 'accepted')$q$));
end $$;

-- ---------------------------------------------------------------------------
-- 5. Grenzen: 30 leden, 10 groepen, atomisch aanmaken (CLUB-18)
-- ---------------------------------------------------------------------------

reset role;

-- Seed onder replica: de guard mag hier NIET lopen, anders kunnen we geen
-- volle groep neerzetten. De opvulleden hebben geen auth.users-rij; replica
-- schakelt ook de FK-controle uit.
set local session_replication_role = replica;

insert into public.groups (id, name, created_by) values
  ('c2000000-0000-0000-0000-000000000003', 'Volle groep', null);

insert into public.group_members (group_id, user_id, role, display_name, joined_at)
select 'c2000000-0000-0000-0000-000000000003',
       gen_random_uuid(),
       case when i = 1 then 'admin' else 'member' end,
       'Vuller ' || i,
       now() - make_interval(days => 40 - i)
from generate_series(1, 30) as i;

insert into public.group_invites (code, group_id, created_by, created_at, expires_at) values
  ('GRPFZZZ3', 'c2000000-0000-0000-0000-000000000003', null, now(), now() + interval '7 days');

-- B zit al in G; met deze negen erbij zit hij in tien groepen.
insert into public.groups (id, name, created_by)
select ('c2000000-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid,
       'Vulgroep ' || i,
       'c1000000-0000-0000-0000-00000000000b'
from generate_series(10, 18) as i;

insert into public.group_members (group_id, user_id, role, display_name, joined_at)
select ('c2000000-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid,
       'c1000000-0000-0000-0000-00000000000b',
       'admin', 'B', now() - interval '1 day'
from generate_series(10, 18) as i;

reset session_replication_role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000c","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('5.1 lid 31 komt er niet in', 'group_full',
    pg_temp.try_value($q$select group_name from public.redeem_group_invite('GRPFZZZ3')$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('5.2 volle groep heeft nog steeds 30 leden', '30',
    pg_temp.try_value($q$select count(*) from public.group_members
      where group_id = 'c2000000-0000-0000-0000-000000000003'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000b","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('5.3 elfde groep wordt geweigerd', 'too_many_groups',
    pg_temp.try_value($q$select public.create_group('Elfde')::text$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('5.4 geweigerde create_group laat geen groep achter', '0',
    pg_temp.try_value($q$select count(*) from public.groups where name = 'Elfde'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000c","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('5.5 C maakt groep ''  Clubtest  ''', 'ok',
    pg_temp.try_exec($q$select public.create_group('  Clubtest  ')$q$));
  -- Als C zelf, via de select-policy: precies wat de app na create_group doet.
  perform pg_temp.expect('5.6 C is beheerder van de nieuwe groep, naam getrimd (rol|naam)', 'admin|Clubtest',
    pg_temp.try_value($q$select string_agg(m.role || '|' || g.name, ',')
      from public.groups g
      join public.group_members m on m.group_id = g.id
      where g.created_by = 'c1000000-0000-0000-0000-00000000000c'$q$));
  perform pg_temp.expect('5.7 lege naam wordt geweigerd', 'group_name_invalid',
    pg_temp.try_value($q$select public.create_group('   ')::text$q$));
end $$;

-- ---------------------------------------------------------------------------
-- 6. Opvolging, en account verwijderen via het echte pad (CLUB-10, CLUB-19)
--
-- Groep S: P beheerder (-3d), Q lid (-2d), R lid (-1d).
-- ---------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000001","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('6.1 beheerder P verlaat S (rijen)', '1',
    pg_temp.try_rows($q$delete from public.group_members
      where group_id = 'c2000000-0000-0000-0000-000000000002'
        and user_id  = 'c1000000-0000-0000-0000-000000000001'$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('6.2 langst zittende Q is nu beheerder van S', 'admin',
    pg_temp.try_value($q$select role from public.group_members
      where group_id = 'c2000000-0000-0000-0000-000000000002'
        and user_id  = 'c1000000-0000-0000-0000-000000000002'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000001","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('6.3 ex-lid P ziet RS niet meer, ondanks zijn participant-rij', '0',
    pg_temp.try_value($q$select count(*) from public.group_rides where id = 'c3000000-0000-0000-0000-000000000002'$q$));
end $$;

-- Q verwijdert zijn account zoals de app dat doet: als Q, via de rpc. De
-- FK-cascade haalt zijn lidmaatschap weg en de after-delete-trigger moet dan
-- R beheerder maken; groups.created_by gaat naar null.
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000002","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('6.4 Q verwijdert zijn account met delete_own_account()', 'ok',
    pg_temp.try_exec($q$select public.delete_own_account()$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('6.5 auth.users-rij van Q is weg', '0',
    pg_temp.try_value($q$select count(*) from auth.users where id = 'c1000000-0000-0000-0000-000000000002'$q$));
  perform pg_temp.expect('6.6 R is nu beheerder van S', 'admin',
    pg_temp.try_value($q$select role from public.group_members
      where group_id = 'c2000000-0000-0000-0000-000000000002'
        and user_id  = 'c1000000-0000-0000-0000-000000000003'$q$));
  perform pg_temp.expect('6.7 S bestaat nog en created_by is null', 'true',
    pg_temp.try_value($q$select (count(*) = 1 and bool_and(created_by is null))::text
      from public.groups where id = 'c2000000-0000-0000-0000-000000000002'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000003","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('6.8 enige beheerder R degradeert zichzelf niet', 'last_admin',
    pg_temp.try_rows($q$update public.group_members set role = 'member'
      where group_id = 'c2000000-0000-0000-0000-000000000002'
        and user_id  = 'c1000000-0000-0000-0000-000000000003'$q$));
  perform pg_temp.expect('6.9 laatste lid R verlaat S (rijen)', '1',
    pg_temp.try_rows($q$delete from public.group_members
      where group_id = 'c2000000-0000-0000-0000-000000000002'
        and user_id  = 'c1000000-0000-0000-0000-000000000003'$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('6.10 lege groep S is verdwenen', '0',
    pg_temp.try_value($q$select count(*) from public.groups where id = 'c2000000-0000-0000-0000-000000000002'$q$));
  perform pg_temp.expect('6.11 RS bestaat nog, met group_id null', 'true',
    pg_temp.try_value($q$select (count(*) = 1 and bool_and(group_id is null))::text
      from public.group_rides where id = 'c3000000-0000-0000-0000-000000000002'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000001","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('6.12 P ziet RS weer als gewone gedeelde rit', '1',
    pg_temp.try_value($q$select count(*) from public.group_rides where id = 'c3000000-0000-0000-0000-000000000002'$q$));
end $$;

-- ---------------------------------------------------------------------------
-- 7. Beheerder heft de groep op (CLUB-11)
-- ---------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000a","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('7.1 beheerder A heft G op (rijen)', '1',
    pg_temp.try_rows($q$delete from public.groups where id = 'c2000000-0000-0000-0000-000000000001'$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('7.2 leden en links van G zijn weg (leden|links)', '0|0',
    pg_temp.try_value($q$select
        (select count(*) from public.group_members where group_id = 'c2000000-0000-0000-0000-000000000001')
        || '|' ||
        (select count(*) from public.group_invites where group_id = 'c2000000-0000-0000-0000-000000000001')$q$));
  perform pg_temp.expect('7.3 R0 en R1 bestaan nog, met group_id null', '2',
    pg_temp.try_value($q$select count(*) from public.group_rides
      where id in ('c3000000-0000-0000-0000-000000000001', 'c3000000-0000-0000-0000-000000000003')
        and group_id is null$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000b","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('7.4 B antwoordde in 2.15 en ziet R0 nog', '1',
    pg_temp.try_value($q$select count(*) from public.group_rides where id = 'c3000000-0000-0000-0000-000000000001'$q$));
end $$;

set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-00000000000c","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('7.5 C was lid maar antwoordde niet, en ziet R0 niet meer', '0',
    pg_temp.try_value($q$select count(*) from public.group_rides where id = 'c3000000-0000-0000-0000-000000000001'$q$));
end $$;

-- ---------------------------------------------------------------------------
-- Eindcontrole
--
-- Eén mislukte check is genoeg om te stoppen, met de namen erbij. Het tweede
-- slot vangt een check die om welke reden dan ook nooit geschreven werd.
-- ---------------------------------------------------------------------------

reset role;

do $$
declare
  v_failed text;
  v_total  integer;
begin
  select string_agg(format('%s (want %s, got %s)', check_name,
                           coalesce(want, 'null'), coalesce(got, 'null')),
                    '; ' order by seq)
    into v_failed
  from pg_temp.club_test_results
  where not ok;

  if v_failed is not null then
    raise exception 'CLUBS DENY-TEST FAILED: %', v_failed;
  end if;

  select count(*) into v_total from pg_temp.club_test_results;
  if v_total <> 83 then
    raise exception 'CLUBS DENY-TEST FAILED: % checks geschreven, 83 verwacht', v_total;
  end if;
end $$;

select seq, check_name, want, got, ok from club_test_results order by seq;

rollback;
