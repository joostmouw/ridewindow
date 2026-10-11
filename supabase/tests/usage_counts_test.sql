-- ---------------------------------------------------------------------------
-- usage_counts_test.sql -- het bewijs voor 0014_usage_daily_counts.sql
-- (v4.3 "Dicht huis", fase 37, MEET-01)
--
-- WAT HET BEWIJST
--   1. De grantgrens in de catalogus: anon en authenticated mogen de
--      telfunctie niet uitvoeren, service_role en usage_monitor wel.
--   2. usage_monitor heeft geen enkel tabelrecht in public en geen toegang tot
--      het auth-schema.
--   3. usage_monitor kan geen andere security definer-functie in public
--      uitvoeren.
--   4. Een echte aanroep als anon of als ingelogde gebruiker wordt geweigerd
--      (42501).
--   5. Een echte aanroep als usage_monitor werkt en geeft een dicht rooster:
--      7 dagen x 10 bronnen = 70 regels.
--   6. De vorm: tien bronnen, nooit een negatief aantal, en bronnen zonder
--      afzenderbegrip (feedback_anoniem, accounts_*) geven geen
--      afzendertelling.
--   7. De invoergrens: p_days buiten 1..3660 geeft 22023.
--   8. De telling klopt: vier verse app_events-rijen van twee toestellen
--      verhogen rows met 4 en distinct_senders met 2; één anonieme
--      feedbackrij verhoogt feedback_anoniem met 1.
--
-- HOE TE DRAAIEN
--   Supabase Dashboard -> SQL Editor -> New query. Plak dit hele bestand en
--   draai het in één keer, NA 0014_usage_daily_counts.sql. Alles zit in één
--   transactie die met `rollback` eindigt, geslaagd of niet: er blijft niets
--   achter -- geen testrijen, geen extra rolrecht. Veilig om zo vaak te
--   draaien als je wilt.
--
-- HOE HET RESULTAAT TE LEZEN
--   De SQL Editor toont geen notices (alleen fouten). Daarom komt elke check
--   als rij in een tijdelijke tabel, en het script eindigt met een gewone
--   select:
--
--     seq | check_name | want | got | ok
--
--   Verwacht: 19 rijen, en in elke rij ok = true. Het getal 19 is precies het
--   aantal aanroepen van pg_temp.expect hieronder.
--
--   Mislukt er één check, dan zie je de tabel niet maar een fout:
--     USAGE-TEST FAILED: 4.1 ... (want 42501, got 20); ...
--   met de naam, het verwachte en het werkelijke antwoord van elke mislukte
--   check. De naam begint met het nummer uit dit bestand. Een fout die NIET
--   met "USAGE-TEST FAILED" begint, is een fout in het script zelf (of 0014
--   is nog niet toegepast), en zegt nog niets over de grens.
--
-- GEEN PRODUCTIETOTALEN (D-19)
--   Het lokale rapport toont totalen; dit script toont zelfs die niet. `got`
--   is een ja/nee, een SQLSTATE, een vast rooster-aantal, of -- in check 8 --
--   het VERSCHIL tussen voor en na de eigen testrijen. De echte dagtotalen
--   blijven in variabelen en verlaten het script nooit.
--
-- TECHNIEK
--   - Rol nadoen: `set local role ...` binnen een do-blok; voor authenticated
--     ook `request.jwt.claims` met een willekeurige uuid. Handelingen die
--     mogen mislukken lopen via pg_temp.try_value, die de SQLSTATE teruggeeft.
--     De check zelf wordt pas weggeschreven na `reset role`.
--   - `set role usage_monitor` vraagt lidmaatschap. De SQL Editor draait als
--     postgres, die usage_monitor maakte maar er (sinds Postgres 16) geen lid
--     van is. Het script geeft dat lidmaatschap daarom tijdelijk; de rollback
--     aan het eind haalt het weer weg.
-- ---------------------------------------------------------------------------

begin;

-- ---------------------------------------------------------------------------
-- Raamwerk
-- ---------------------------------------------------------------------------

create temporary table usage_test_results (
  seq        serial,
  check_name text,
  want       text,
  got        text,
  ok         boolean
) on commit drop;

-- Legt een check vast. Stopt nooit: de eindcontrole beslist.
create function pg_temp.expect (p_name text, p_want text, p_got text)
returns void
language plpgsql
as $$
begin
  insert into pg_temp.usage_test_results (check_name, want, got, ok)
  values (p_name, p_want, p_got, p_want is not distinct from p_got);
end;
$$;

-- Eén waarde. Bij een fout: de SQLSTATE (of de sleutel bij P0001).
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

-- Tijdelijk lidmaatschap, zodat `set role usage_monitor` mag (zie TECHNIEK).
grant usage_monitor to postgres;

-- ---------------------------------------------------------------------------
-- 1. Grantgrens in de catalogus
-- ---------------------------------------------------------------------------

do $$
begin
  perform pg_temp.expect('1.1 anon mag usage_daily_counts niet uitvoeren', 'false',
    has_function_privilege('anon', 'public.usage_daily_counts(int)', 'execute')::text);
  perform pg_temp.expect('1.2 authenticated mag usage_daily_counts niet uitvoeren', 'false',
    has_function_privilege('authenticated', 'public.usage_daily_counts(int)', 'execute')::text);
  perform pg_temp.expect('1.3 service_role mag usage_daily_counts uitvoeren', 'true',
    has_function_privilege('service_role', 'public.usage_daily_counts(int)', 'execute')::text);
  perform pg_temp.expect('1.4 usage_monitor mag usage_daily_counts uitvoeren', 'true',
    has_function_privilege('usage_monitor', 'public.usage_daily_counts(int)', 'execute')::text);
end $$;

-- ---------------------------------------------------------------------------
-- 2. usage_monitor heeft geen tabelrechten en geen auth-schema
-- ---------------------------------------------------------------------------

do $$
begin
  perform pg_temp.expect('2.1 usage_monitor heeft op geen enkele tabel in public een recht', '0',
    (select count(*)::text
       from pg_class c
       join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relkind in ('r', 'p', 'v', 'm', 'f')
        and (has_table_privilege('usage_monitor', c.oid, 'select')
          or has_table_privilege('usage_monitor', c.oid, 'insert')
          or has_table_privilege('usage_monitor', c.oid, 'update')
          or has_table_privilege('usage_monitor', c.oid, 'delete'))));
  perform pg_temp.expect('2.2 usage_monitor heeft geen usage op schema auth', 'false',
    has_schema_privilege('usage_monitor', 'auth', 'usage')::text);
end $$;

-- ---------------------------------------------------------------------------
-- 3. Geen andere security definer-functie voor usage_monitor
-- ---------------------------------------------------------------------------

do $$
begin
  perform pg_temp.expect('3.1 usage_monitor voert geen andere security definer-functie in public uit', '0',
    (select count(*)::text
       from pg_proc p
       join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.prosecdef
        and p.proname <> 'usage_daily_counts'
        and has_function_privilege('usage_monitor', p.oid, 'execute')));
end $$;

-- ---------------------------------------------------------------------------
-- 4. Echte aanroep als anon en als ingelogde gebruiker: geweigerd
-- ---------------------------------------------------------------------------

do $$
declare
  v text;
begin
  set local role anon;
  v := pg_temp.try_value('select count(*)::text from public.usage_daily_counts(1)');
  reset role;
  perform pg_temp.expect('4.1 anon roept usage_daily_counts aan', '42501', v);
end $$;

do $$
declare
  v text;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid()::text, 'role', 'authenticated')::text, true);
  set local role authenticated;
  v := pg_temp.try_value('select count(*)::text from public.usage_daily_counts(1)');
  reset role;
  perform set_config('request.jwt.claims', '', true);
  perform pg_temp.expect('4.2 ingelogde gebruiker roept usage_daily_counts aan', '42501', v);
end $$;

reset role;

-- ---------------------------------------------------------------------------
-- 5. Echte aanroep als usage_monitor: dicht rooster
-- ---------------------------------------------------------------------------

do $$
declare
  v text;
begin
  set local role usage_monitor;
  v := pg_temp.try_value('select count(*)::text from public.usage_daily_counts(7)');
  reset role;
  perform pg_temp.expect('5.1 usage_monitor krijgt 7 dagen x 10 bronnen', '70', v);
end $$;

reset role;

-- ---------------------------------------------------------------------------
-- 6. Vorm van de uitvoer
-- ---------------------------------------------------------------------------

do $$
begin
  perform pg_temp.expect('6.1 tien verschillende bronnen', '10',
    pg_temp.try_value('select count(distinct source)::text from public.usage_daily_counts(3)'));
  perform pg_temp.expect('6.2 geen negatief aantal rijen', '0',
    pg_temp.try_value('select count(*)::text from public.usage_daily_counts(3) where rows < 0'));
  perform pg_temp.expect('6.3 feedback_anoniem en accounts_* geven geen afzendertelling', '0',
    pg_temp.try_value($q$select count(*)::text from public.usage_daily_counts(3)
                         where (source = 'feedback_anoniem' or source like 'accounts\_%')
                           and distinct_senders is not null$q$));
end $$;

-- ---------------------------------------------------------------------------
-- 7. Invoergrens
-- ---------------------------------------------------------------------------

do $$
begin
  perform pg_temp.expect('7.1 p_days = 0 wordt geweigerd', '22023',
    pg_temp.try_value('select count(*)::text from public.usage_daily_counts(0)'));
  perform pg_temp.expect('7.2 p_days = 4000 wordt geweigerd', '22023',
    pg_temp.try_value('select count(*)::text from public.usage_daily_counts(4000)'));
end $$;

-- ---------------------------------------------------------------------------
-- 8. De telling klopt op verse data
--
-- Alleen verschillen verlaten dit blok. De voor- en na-waarden zelf zijn
-- productietotalen van vandaag en blijven in de variabelen.
-- ---------------------------------------------------------------------------

do $$
declare
  v_dev1        uuid := gen_random_uuid();
  v_dev2        uuid := gen_random_uuid();
  v_rows_0      bigint;
  v_senders_0   bigint;
  v_rows_1      bigint;
  v_senders_1   bigint;
  v_max_1       bigint;
  v_anon_0      bigint;
  v_anon_1      bigint;
  v_today       date := (now() at time zone 'Europe/Amsterdam')::date;
begin
  select u.rows, coalesce(u.distinct_senders, 0)
    into v_rows_0, v_senders_0
    from public.usage_daily_counts(1) u
   where u.day = v_today and u.source = 'app_events';

  select u.rows into v_anon_0
    from public.usage_daily_counts(1) u
   where u.day = v_today and u.source = 'feedback_anoniem';

  insert into public.app_events (id, device_id, name, platform, app_version, occurred_at) values
    (gen_random_uuid(), v_dev1, 'test', 'android', '0', now()),
    (gen_random_uuid(), v_dev1, 'test', 'android', '0', now()),
    (gen_random_uuid(), v_dev1, 'test', 'android', '0', now()),
    (gen_random_uuid(), v_dev2, 'test', 'android', '0', now());

  insert into public.feedback (user_id, rating, comment) values (null, null, null);

  select u.rows, coalesce(u.distinct_senders, 0), u.max_rows_one_sender
    into v_rows_1, v_senders_1, v_max_1
    from public.usage_daily_counts(1) u
   where u.day = v_today and u.source = 'app_events';

  select u.rows into v_anon_1
    from public.usage_daily_counts(1) u
   where u.day = v_today and u.source = 'feedback_anoniem';

  perform pg_temp.expect('8.1 app_events: rows stijgt met 4', '4',
    (v_rows_1 - v_rows_0)::text);
  perform pg_temp.expect('8.2 app_events: distinct_senders stijgt met 2', '2',
    (v_senders_1 - v_senders_0)::text);
  perform pg_temp.expect('8.3 app_events: max_rows_one_sender is minstens 3', 'true',
    coalesce(v_max_1 >= 3, false)::text);
  perform pg_temp.expect('8.4 feedback_anoniem: rows stijgt met 1', '1',
    (v_anon_1 - v_anon_0)::text);
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
  from pg_temp.usage_test_results
  where not ok;

  if v_failed is not null then
    raise exception 'USAGE-TEST FAILED: %', v_failed;
  end if;

  select count(*) into v_total from pg_temp.usage_test_results;
  if v_total <> 19 then
    raise exception 'USAGE-TEST FAILED: % checks geschreven, 19 verwacht', v_total;
  end if;
end $$;

select seq, check_name, want, got, ok from usage_test_results order by seq;

rollback;
