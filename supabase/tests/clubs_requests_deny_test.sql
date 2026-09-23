-- ---------------------------------------------------------------------------
-- clubs_requests_deny_test.sql -- het bewijs voor 0013_group_join_requests.sql
-- (fase 34, Clubs)
--
-- WAT HET BEWIJST
--   CLUB-27  "Ieder lid draagt voor, alleen beheerders maken lid", afgedwongen
--            in de database:
--            - een gewoon lid kan niemand lid maken: niet via een insert in
--              group_members, niet door een aanvraag te accepteren, niet door
--              zelf een aanvraag te schrijven of te wijzigen;
--            - een gewoon lid draagt alleen een eigen maatje voor, en dat
--              levert een aanvraag op, geen lid; de namen in die aanvraag
--              komen uit de database;
--            - een gewoon lid ziet de aanvragen van anderen niet en kan ze
--              niet afwijzen; een buitenstaander ziet er geen enkele;
--            - de groepslink levert een aanvraag op, geen lid; de aanvrager
--              ziet de groepsrij, maar geen leden, ritten of links;
--            - een beheerder accepteert en wijst af, en wie hij zelf voordraagt
--              is meteen lid;
--            - intrekken door aanvrager of voordrager; opheffen ruimt op.
--   CLUB-02/ Ieder lid ziet en maakt groepslinks; intrekken blijft
--   CLUB-03  beheerderswerk.
--   CLUB-18  Accepteren respecteert 30 leden en 10 groepen (de aanvraag blijft
--            dan staan); de link meldt group_full en too_many_groups al bij het
--            aanvragen; een 31e open aanvraag wordt geweigerd
--            (too_many_requests).
--
-- HOE TE DRAAIEN
--   Supabase Dashboard -> SQL Editor -> New query. Plak dit hele bestand en
--   draai het in één keer, NA 0012_groups.sql en 0013_group_join_requests.sql.
--   Alles zit in één transactie die met `rollback` eindigt, geslaagd of niet:
--   er blijft niets achter in de live database -- geen testgebruikers, geen
--   groepen, geen aanvragen. Veilig om zo vaak te draaien als je wilt.
--
-- HOE HET RESULTAAT TE LEZEN
--   De SQL Editor toont geen notices (alleen fouten). Daarom komt elke check
--   als rij in een tijdelijke tabel, en het script eindigt met een gewone
--   select:
--
--     seq | check_name | want | got | ok
--
--   Verwacht: 62 rijen, en in elke rij ok = true. Het getal 62 is precies het
--   aantal aanroepen van pg_temp.expect hieronder.
--
--   Mislukt er één check, dan zie je de tabel niet maar een fout:
--     CLUBS REQUESTS DENY-TEST FAILED: 2.11 ... (want not_allowed, got ok); ...
--   met de naam, het verwachte en het werkelijke antwoord van elke mislukte
--   check. De naam begint met het nummer uit dit bestand. Een fout die NIET
--   met "CLUBS REQUESTS DENY-TEST FAILED" begint, is een fout in het script
--   zelf of in de seed, en zegt nog niets over 0013.
--
--   `got` is een aantal rijen, 'ok' als een handeling slaagde, de status uit
--   redeem_group_invite of propose_group_member ('member' / 'requested'), de
--   sleutel uit 0012/0013 (not_allowed, group_full, ...) bij een P0001-fout,
--   en anders de SQLSTATE: 42501 = geweigerd door RLS of tabelrecht.
--
-- TECHNIEK
--   Dezelfde als in clubs_deny_test.sql:
--   1. De hoofdpersonen krijgen ECHTE rijen in auth.users, met triggers aan,
--      zodat foreign keys en de guard-trigger echt afgaan.
--   2. `session_replication_role = replica` alleen voor bulk-seed waar
--      triggers NIET mogen lopen: vaste joined_at, de volle groep GF, de tien
--      groepen van T, de 30 open aanvragen van H (opvulgebruikers zonder
--      auth.users-rij) en de aanvragen die we klaarzetten om te laten stuiten.
--   3. Een gebruiker nadoen: `set local role authenticated` plus
--      `set local request.jwt.claims = '{"sub":"<uuid>",...}'`. `reset role`
--      gaat terug naar postgres, voor seed en voor controles die door RLS
--      heen moeten kijken (bijv. "X is GEEN lid": X zelf ziet de ledenlijst
--      niet, dus alleen postgres kan dat echt vaststellen).
--   4. Elke check roept pg_temp.expect aan, die een rij schrijft en NIET
--      stopt. Handelingen lopen via pg_temp.try_value / try_exec / try_rows in
--      een eigen subtransactie: een geweigerde handeling laat niets na. Pas
--      helemaal aan het eind beslist één blok: iets mislukt -> exception.
--
-- DE CAST (eigen prefixen d1.../d2.../d3.../d5..., botst niet met c1... uit
-- clubs_deny_test.sql; e-mails op @clubs-req-test.invalid)
--   Gebruikers (d1...):  A ..0a beheerder van G      B ..0b lid van G
--                        C ..0c buitenstaander, profielnaam 'Cees'
--                        X ..0d maatje van B, profielnaam 'Xander'
--                        Y ..0e maatje van A en van B
--                        T ..0f zit al in tien groepen
--                        F ..01 beheerder van GF    K ..02 los account
--   Maatjes:             B-X, A-Y, B-Y
--   Groepen (d2...):     G ..01 'Aanvraaggroep' (A beheerder, B lid)
--                        GF ..03 vol: F + 29 opvulleden
--                        H ..04 één opvulbeheerder, 30 open aanvragen
--                        ..10 t/m ..19: de tien groepen van T
--   Rit (d3...):         RG ..01 groepsrit van G, eigenaar A
--   Aanvragen (d5...):   RT ..01 T in G (klaargezet, stuit in 5.5 op
--                                too_many_groups)
--                        RK ..02 K in GF (klaargezet na 5.1, stuit in 5.2 op
--                                group_full)
--   Links:               REQGGGG2 (G, geldig)   REQXPRD2 (G, verlopen)
--                        REQBBBB2 (maakt lid B in 2.2)
--                        REQFFFF3 (GF)          REQHHHH4 (H)
-- ---------------------------------------------------------------------------

begin;

-- ---------------------------------------------------------------------------
-- Raamwerk
-- ---------------------------------------------------------------------------

create temporary table club_request_results (
  seq        serial,
  check_name text,
  want       text,
  got        text,
  ok         boolean
) on commit drop;

-- De checks draaien als authenticated, dus die rol moet in de tabel kunnen
-- schrijven. Het temp-schema van deze sessie is voor elke rol bruikbaar.
grant select, insert on club_request_results to authenticated;
grant usage on sequence club_request_results_seq_seq to authenticated;

-- Legt een check vast. Stopt nooit: de eindcontrole beslist.
create function pg_temp.expect(p_name text, p_want text, p_got text)
returns void
language plpgsql
as $$
begin
  insert into pg_temp.club_request_results (check_name, want, got, ok)
  values (p_name, p_want, p_got, p_want is not distinct from p_got);
end;
$$;

-- Eén waarde (een telling, een naam, een status). Bij een fout: de sleutel of
-- de SQLSTATE.
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
  ('d1000000-0000-0000-0000-00000000000a', 'authenticated', 'authenticated', 'a@clubs-req-test.invalid'),
  ('d1000000-0000-0000-0000-00000000000b', 'authenticated', 'authenticated', 'b@clubs-req-test.invalid'),
  ('d1000000-0000-0000-0000-00000000000c', 'authenticated', 'authenticated', 'c@clubs-req-test.invalid'),
  ('d1000000-0000-0000-0000-00000000000d', 'authenticated', 'authenticated', 'x@clubs-req-test.invalid'),
  ('d1000000-0000-0000-0000-00000000000e', 'authenticated', 'authenticated', 'y@clubs-req-test.invalid'),
  ('d1000000-0000-0000-0000-00000000000f', 'authenticated', 'authenticated', 't@clubs-req-test.invalid'),
  ('d1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'f@clubs-req-test.invalid'),
  ('d1000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'k@clubs-req-test.invalid');

-- X en C hebben een naam, zodat 2.7, 3.4 en 4.3 kunnen zien dat de naam uit
-- profiles komt en niet van de client. Kolommen als in clubs_deny_test.sql.
insert into public.profiles (
  user_id, temp_min_ideal_c, temp_max_ideal_c, wind_max_ideal_kmh, rain_max_ideal_mm,
  allowed_durations, theme, locale, location_override, user_name,
  notif_evening_before, notif_morning_of, notif_weekly_digest
) values
  ('d1000000-0000-0000-0000-00000000000d',
   12, 26, 15, 0.5, '{2,3}', 'system', 'nl', null, 'Xander', false, false, false),
  ('d1000000-0000-0000-0000-00000000000c',
   12, 26, 15, 0.5, '{2,3}', 'system', 'nl', null, 'Cees', false, false, false);

-- Maatjes B-X, A-Y en B-Y (canonieke volgorde uit 0002).
insert into public.friendships (user_a, user_b)
select least(p.a, p.b), greatest(p.a, p.b)
from (values
  ('d1000000-0000-0000-0000-00000000000b'::uuid, 'd1000000-0000-0000-0000-00000000000d'::uuid),
  ('d1000000-0000-0000-0000-00000000000a'::uuid, 'd1000000-0000-0000-0000-00000000000e'::uuid),
  ('d1000000-0000-0000-0000-00000000000b'::uuid, 'd1000000-0000-0000-0000-00000000000e'::uuid)
) as p(a, b);

-- ---------------------------------------------------------------------------
-- Seed, deel 2 -- onder replica: vaste joined_at, geen guard, geen FK-controle
-- ---------------------------------------------------------------------------

set local session_replication_role = replica;

insert into public.groups (id, name, created_by) values
  ('d2000000-0000-0000-0000-000000000001', 'Aanvraaggroep', 'd1000000-0000-0000-0000-00000000000a'),
  ('d2000000-0000-0000-0000-000000000003', 'Volle groep',   'd1000000-0000-0000-0000-000000000001'),
  ('d2000000-0000-0000-0000-000000000004', 'Drukke groep',  null);

insert into public.group_members (group_id, user_id, role, display_name, joined_at) values
  ('d2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000a', 'admin',  'A', now() - interval '3 days'),
  ('d2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000b', 'member', 'B', now() - interval '2 days'),
  ('d2000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000001', 'admin',  'F', now() - interval '50 days'),
  ('d2000000-0000-0000-0000-000000000004', gen_random_uuid(),                      'admin',  'H-beheer', now() - interval '5 days');

-- GF: F plus 29 opvulleden = 30.
insert into public.group_members (group_id, user_id, role, display_name, joined_at)
select 'd2000000-0000-0000-0000-000000000003',
       gen_random_uuid(),
       'member',
       'Vuller ' || i,
       now() - make_interval(days => 40 - i)
from generate_series(1, 29) as i;

-- H: 30 open aanvragen van opvulgebruikers (zonder auth.users-rij).
insert into public.group_join_requests (group_id, user_id, proposed_by, display_name)
select 'd2000000-0000-0000-0000-000000000004', gen_random_uuid(), null, 'Aanvrager ' || i
from generate_series(1, 30) as i;

-- T zit in tien groepen.
insert into public.groups (id, name, created_by)
select ('d2000000-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid,
       'T-groep ' || i,
       'd1000000-0000-0000-0000-00000000000f'
from generate_series(10, 19) as i;

insert into public.group_members (group_id, user_id, role, display_name, joined_at)
select ('d2000000-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid,
       'd1000000-0000-0000-0000-00000000000f',
       'admin', 'T', now() - interval '1 day'
from generate_series(10, 19) as i;

-- RT: een open aanvraag van T in G. Maakt sectie 1 en 2.4 zinvol (er IS een
-- aanvraag die ze niet mogen zien) en stuit in 5.5 op too_many_groups.
insert into public.group_join_requests (id, group_id, user_id, proposed_by, display_name) values
  ('d5000000-0000-0000-0000-000000000001', 'd2000000-0000-0000-0000-000000000001',
   'd1000000-0000-0000-0000-00000000000f', null, 'T');

insert into public.group_invites (code, group_id, created_by, created_at, expires_at) values
  ('REQGGGG2', 'd2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000a',
   now(), now() + interval '7 days'),
  ('REQXPRD2', 'd2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000a',
   now() - interval '10 days', now() - interval '1 day'),
  ('REQFFFF3', 'd2000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000001',
   now(), now() + interval '7 days'),
  ('REQHHHH4', 'd2000000-0000-0000-0000-000000000004', null,
   now(), now() + interval '7 days');

insert into public.group_rides (id, owner_id, group_id, start_at, end_at, planned_score, owner_name) values
  ('d3000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000a',
   'd2000000-0000-0000-0000-000000000001',
   now() + interval '2 days', now() + interval '2 days 3 hours', 80, 'A');

reset session_replication_role;

-- ---------------------------------------------------------------------------
-- 1. Buitenstaander C: geen aanvragen zien, niets voordragen of accepteren
-- ---------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000c","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('1.1 buitenstaander ziet geen aanvragen van G (RT bestaat wel)', '0',
    pg_temp.try_value($q$select count(*) from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('1.2 buitenstaander draagt niemand voor in G', 'not_member',
    pg_temp.try_value($q$select public.propose_group_member(
      'd2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000e')$q$));
  perform pg_temp.expect('1.3 buitenstaander accepteert RT niet', 'not_allowed',
    pg_temp.try_exec($q$select public.accept_group_request('d5000000-0000-0000-0000-000000000001')$q$));
  -- Dezelfde sleutel voor een id dat niet bestaat: accept verklapt niets.
  perform pg_temp.expect('1.4 accepteren van een onbekend id geeft dezelfde sleutel', 'not_allowed',
    pg_temp.try_exec($q$select public.accept_group_request('d5000000-0000-0000-0000-0000000000ff')$q$));
  perform pg_temp.expect('1.5 buitenstaander schrijft zelf geen aanvraag', '42501',
    pg_temp.try_exec($q$insert into public.group_join_requests (group_id, user_id)
      values ('d2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000c')$q$));
  perform pg_temp.expect('1.6 buitenstaander wijst RT niet af (rijen)', '0',
    pg_temp.try_rows($q$delete from public.group_join_requests
      where id = 'd5000000-0000-0000-0000-000000000001'$q$));
end $$;

-- ---------------------------------------------------------------------------
-- 2. Gewoon lid B: deelt links, draagt voor, maakt niemand lid (CLUB-27)
-- ---------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000b","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('2.1 lid ziet de links van G (geldig en verlopen; 0013: ieder lid)', '2',
    pg_temp.try_value($q$select count(*) from public.group_invites
      where group_id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('2.2 lid maakt link REQBBBB2 (0013: ieder lid)', 'ok',
    pg_temp.try_exec($q$insert into public.group_invites (code, group_id, created_by, expires_at)
      values ('REQBBBB2', 'd2000000-0000-0000-0000-000000000001',
              'd1000000-0000-0000-0000-00000000000b', now() + interval '7 days')$q$));
  perform pg_temp.expect('2.3 lid trekt de link van A niet in (rijen)', '0',
    pg_temp.try_rows($q$delete from public.group_invites where code = 'REQGGGG2'$q$));
  perform pg_temp.expect('2.4 lid ziet de aanvraag van T niet', '0',
    pg_temp.try_value($q$select count(*) from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('2.5 lid draagt maatje X voor: aanvraag, geen lid', 'requested',
    pg_temp.try_value($q$select public.propose_group_member(
      'd2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000d')$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('2.6 X is na de voordracht geen lid van G', '0',
    pg_temp.try_value($q$select count(*) from public.group_members
      where group_id = 'd2000000-0000-0000-0000-000000000001'
        and user_id  = 'd1000000-0000-0000-0000-00000000000d'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000b","role":"authenticated"}';

do $$
begin
  -- Als B zelf: de voordrager ziet zijn voordracht, met namen uit de database
  -- (profiel van X, lidmaatschap van B in G).
  perform pg_temp.expect('2.7 voordracht draagt naam uit profiel en naam voordrager (naam|voordrager)', 'Xander|B',
    pg_temp.try_value($q$select display_name || '|' || proposed_by_name
      from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000001'
        and user_id  = 'd1000000-0000-0000-0000-00000000000d'$q$));
  perform pg_temp.expect('2.8 lid draagt X nog eens voor', 'requested',
    pg_temp.try_value($q$select public.propose_group_member(
      'd2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000d')$q$));
  -- 1 = alleen de eigen voordracht van B, niet dubbel, en RT blijft onzichtbaar.
  perform pg_temp.expect('2.9 lid ziet in G precies zijn ene voordracht', '1',
    pg_temp.try_value($q$select count(*) from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('2.10 lid draagt geen niet-maatje C voor', 'not_friend',
    pg_temp.try_value($q$select public.propose_group_member(
      'd2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000c')$q$));
  perform pg_temp.expect('2.11 lid accepteert de voordracht van X niet', 'not_allowed',
    pg_temp.try_exec($q$select public.accept_group_request((
      select r.id from public.group_join_requests r
      where r.group_id = 'd2000000-0000-0000-0000-000000000001'
        and r.user_id  = 'd1000000-0000-0000-0000-00000000000d'))$q$));
  perform pg_temp.expect('2.12 lid voegt X niet direct toe', '42501',
    pg_temp.try_exec($q$insert into public.group_members (group_id, user_id)
      values ('d2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000d')$q$));
  perform pg_temp.expect('2.13 lid wijzigt een aanvraag niet', '42501',
    pg_temp.try_rows($q$update public.group_join_requests set display_name = 'Gekaapt'
      where group_id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('2.14 lid schrijft zelf geen aanvraag', '42501',
    pg_temp.try_exec($q$insert into public.group_join_requests (group_id, user_id)
      values ('d2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000e')$q$));
end $$;

-- ---------------------------------------------------------------------------
-- 3. De link levert een aanvraag op, geen lid (CLUB-27)
-- ---------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000c","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('3.1 C wisselt de link van G in: aanvraag', 'requested',
    pg_temp.try_value($q$select status from public.redeem_group_invite('REQGGGG2')$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('3.2 C is na inwisselen geen lid van G', '0',
    pg_temp.try_value($q$select count(*) from public.group_members
      where group_id = 'd2000000-0000-0000-0000-000000000001'
        and user_id  = 'd1000000-0000-0000-0000-00000000000c'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000c","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('3.3 C ziet zijn eigen aanvraag', '1',
    pg_temp.try_value($q$select count(*) from public.group_join_requests
      where user_id = 'd1000000-0000-0000-0000-00000000000c'$q$));
  perform pg_temp.expect('3.4 aanvraag via link: naam uit profiel, geen voordrager (naam|zonder voordrager)', 'Cees|true',
    pg_temp.try_value($q$select display_name || '|' || (proposed_by is null and proposed_by_name is null)::text
      from public.group_join_requests
      where user_id = 'd1000000-0000-0000-0000-00000000000c'$q$));
  perform pg_temp.expect('3.5 aanvrager C ziet de groepsrij van G', '1',
    pg_temp.try_value($q$select count(*) from public.groups where id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('3.6 aanvrager C ziet geen leden van G', '0',
    pg_temp.try_value($q$select count(*) from public.group_members where group_id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('3.7 aanvrager C ziet geen groepsritten van G', '0',
    pg_temp.try_value($q$select count(*) from public.group_rides where group_id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('3.8 aanvrager C ziet geen links van G', '0',
    pg_temp.try_value($q$select count(*) from public.group_invites where group_id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('3.9 C wisselt nog eens in', 'requested',
    pg_temp.try_value($q$select status from public.redeem_group_invite('  reqgggg2  ')$q$));
  perform pg_temp.expect('3.10 C heeft nog steeds precies een aanvraag', '1',
    pg_temp.try_value($q$select count(*) from public.group_join_requests
      where user_id = 'd1000000-0000-0000-0000-00000000000c'$q$));
  perform pg_temp.expect('3.11 verlopen link wordt geweigerd', 'invite_invalid',
    pg_temp.try_value($q$select status from public.redeem_group_invite('REQXPRD2')$q$));
end $$;

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000b","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('3.12 lid B wijst de aanvraag van C niet af (rijen)', '0',
    pg_temp.try_rows($q$delete from public.group_join_requests
      where user_id = 'd1000000-0000-0000-0000-00000000000c'$q$));
end $$;

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000d","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('3.13 voorgedragen X ziet de groepsrij van G', '1',
    pg_temp.try_value($q$select count(*) from public.groups where id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('3.14 voorgedragen X ziet zijn aanvraag', '1',
    pg_temp.try_value($q$select count(*) from public.group_join_requests
      where user_id = 'd1000000-0000-0000-0000-00000000000d'$q$));
end $$;

-- ---------------------------------------------------------------------------
-- 4. Beheerder A: accepteert, wijst af, en draagt zelf voor (CLUB-27)
-- ---------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000a","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('4.1 beheerder ziet alle aanvragen van G (X, C en RT)', '3',
    pg_temp.try_value($q$select count(*) from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('4.2 beheerder accepteert C', 'ok',
    pg_temp.try_exec($q$select public.accept_group_request((
      select r.id from public.group_join_requests r
      where r.group_id = 'd2000000-0000-0000-0000-000000000001'
        and r.user_id  = 'd1000000-0000-0000-0000-00000000000c'))$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('4.3 C is lid, met naam uit profiel (rol|naam)', 'member|Cees',
    pg_temp.try_value($q$select role || '|' || display_name from public.group_members
      where group_id = 'd2000000-0000-0000-0000-000000000001'
        and user_id  = 'd1000000-0000-0000-0000-00000000000c'$q$));
  perform pg_temp.expect('4.4 de aanvraag van C is weg', '0',
    pg_temp.try_value($q$select count(*) from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000001'
        and user_id  = 'd1000000-0000-0000-0000-00000000000c'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000c","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('4.5 lid C wisselt de link nog eens in', 'member',
    pg_temp.try_value($q$select status from public.redeem_group_invite('REQGGGG2')$q$));
end $$;

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000a","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('4.6 beheerder wijst X af (rijen)', '1',
    pg_temp.try_rows($q$delete from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000001'
        and user_id  = 'd1000000-0000-0000-0000-00000000000d'$q$));
end $$;

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000d","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('4.7 afgewezen X ziet geen aanvragen meer', '0',
    pg_temp.try_value($q$select count(*) from public.group_join_requests$q$));
  perform pg_temp.expect('4.8 afgewezen X ziet geen groepen', '0',
    pg_temp.try_value($q$select count(*) from public.groups$q$));
end $$;

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000a","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('4.9 beheerder draagt maatje Y voor: direct lid', 'member',
    pg_temp.try_value($q$select public.propose_group_member(
      'd2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000e')$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('4.10 Y is lid van G met rol member', 'member',
    pg_temp.try_value($q$select role from public.group_members
      where group_id = 'd2000000-0000-0000-0000-000000000001'
        and user_id  = 'd1000000-0000-0000-0000-00000000000e'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000b","role":"authenticated"}';

do $$
begin
  -- Y is ook maatje van B; voordragen van een lid is idempotent.
  perform pg_temp.expect('4.11 lid B draagt het lid Y voor: al lid', 'member',
    pg_temp.try_value($q$select public.propose_group_member(
      'd2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000e')$q$));
end $$;

-- ---------------------------------------------------------------------------
-- 5. Grenzen: 30 leden, 10 groepen, 30 open aanvragen (CLUB-18)
-- ---------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000002","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('5.1 K vraagt via de link de volle GF aan', 'group_full',
    pg_temp.try_value($q$select status from public.redeem_group_invite('REQFFFF3')$q$));
end $$;

reset role;

-- RK: een aanvraag die er al lag toen GF volliep (onder replica, want de link
-- weigert hem terecht). Accepteren moet op de guard-trigger stuiten.
set local session_replication_role = replica;

insert into public.group_join_requests (id, group_id, user_id, proposed_by, display_name) values
  ('d5000000-0000-0000-0000-000000000002', 'd2000000-0000-0000-0000-000000000003',
   'd1000000-0000-0000-0000-000000000002', null, 'K');

reset session_replication_role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000001","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('5.2 beheerder F accepteert RK in volle GF', 'group_full',
    pg_temp.try_exec($q$select public.accept_group_request('d5000000-0000-0000-0000-000000000002')$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('5.3 RK blijft staan en GF heeft 30 leden (aanvragen|leden)', '1|30',
    pg_temp.try_value($q$select
        (select count(*) from public.group_join_requests where id = 'd5000000-0000-0000-0000-000000000002')
        || '|' ||
        (select count(*) from public.group_members where group_id = 'd2000000-0000-0000-0000-000000000003')$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000f","role":"authenticated"}';

do $$
begin
  -- H heeft ook al 30 aanvragen: too_many_groups komt eerst.
  perform pg_temp.expect('5.4 T (tien groepen) vraagt via de link H aan', 'too_many_groups',
    pg_temp.try_value($q$select status from public.redeem_group_invite('REQHHHH4')$q$));
end $$;

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000a","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('5.5 beheerder A accepteert RT van T (tien groepen)', 'too_many_groups',
    pg_temp.try_exec($q$select public.accept_group_request('d5000000-0000-0000-0000-000000000001')$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('5.6 RT blijft staan en T zit in tien groepen (aanvragen|groepen)', '1|10',
    pg_temp.try_value($q$select
        (select count(*) from public.group_join_requests where id = 'd5000000-0000-0000-0000-000000000001')
        || '|' ||
        (select count(*) from public.group_members where user_id = 'd1000000-0000-0000-0000-00000000000f')$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000002","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('5.7 een 31e aanvraag voor H wordt geweigerd', 'too_many_requests',
    pg_temp.try_value($q$select status from public.redeem_group_invite('REQHHHH4')$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('5.8 H heeft nog steeds 30 aanvragen', '30',
    pg_temp.try_value($q$select count(*) from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000004'$q$));
end $$;

-- ---------------------------------------------------------------------------
-- 6. Intrekken en opruimen
-- ---------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000002","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('6.1 K vraagt via de link G aan', 'requested',
    pg_temp.try_value($q$select status from public.redeem_group_invite('REQGGGG2')$q$));
  perform pg_temp.expect('6.2 aanvrager K ziet de groepsrij van G', '1',
    pg_temp.try_value($q$select count(*) from public.groups where id = 'd2000000-0000-0000-0000-000000000001'$q$));
  perform pg_temp.expect('6.3 K trekt zijn aanvraag in (rijen)', '1',
    pg_temp.try_rows($q$delete from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000001'
        and user_id  = 'd1000000-0000-0000-0000-000000000002'$q$));
  perform pg_temp.expect('6.4 K ziet G daarna niet meer', '0',
    pg_temp.try_value($q$select count(*) from public.groups where id = 'd2000000-0000-0000-0000-000000000001'$q$));
end $$;

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000b","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('6.5 lid B draagt X opnieuw voor', 'requested',
    pg_temp.try_value($q$select public.propose_group_member(
      'd2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-00000000000d')$q$));
  perform pg_temp.expect('6.6 voordrager B trekt zijn voordracht in (rijen)', '1',
    pg_temp.try_rows($q$delete from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000001'
        and user_id  = 'd1000000-0000-0000-0000-00000000000d'$q$));
end $$;

reset role;

do $$
begin
  -- Anders bewijst 6.9 niets: er moet iets zijn om op te ruimen.
  perform pg_temp.expect('6.7 voor opheffen staat RT nog in G', '1',
    pg_temp.try_value($q$select count(*) from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000001'$q$));
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-00000000000a","role":"authenticated"}';

do $$
begin
  perform pg_temp.expect('6.8 beheerder A heft G op (rijen)', '1',
    pg_temp.try_rows($q$delete from public.groups where id = 'd2000000-0000-0000-0000-000000000001'$q$));
end $$;

reset role;

do $$
begin
  perform pg_temp.expect('6.9 aanvragen van G zijn mee verdwenen', '0',
    pg_temp.try_value($q$select count(*) from public.group_join_requests
      where group_id = 'd2000000-0000-0000-0000-000000000001'$q$));
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
  from pg_temp.club_request_results
  where not ok;

  if v_failed is not null then
    raise exception 'CLUBS REQUESTS DENY-TEST FAILED: %', v_failed;
  end if;

  select count(*) into v_total from pg_temp.club_request_results;
  if v_total <> 62 then
    raise exception 'CLUBS REQUESTS DENY-TEST FAILED: % checks geschreven, 62 verwacht', v_total;
  end if;
end $$;

select seq, check_name, want, got, ok from club_request_results order by seq;

rollback;
