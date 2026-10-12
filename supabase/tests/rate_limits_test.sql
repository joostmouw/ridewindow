-- ---------------------------------------------------------------------------
-- rate_limits_test.sql -- het bewijs voor 0016_rate_limits.sql
-- (v4.3 "Dicht huis", fase 38, RATE-01 t/m RATE-04)
--
-- VERSIE 4. Staat deze regel niet bovenaan in de SQL Editor, dan draait de
-- tab nog oude tekst: hele tab selecteren en het klembord opnieuw plakken.
-- (v1 miste het id op app_events; v2 en v3 bewaarden de checks in een
-- tijdelijke tabel, en die vindt de slotselect in de SQL Editor niet.)
--
-- WAT HET BEWIJST
--   1. De grantgrens in de catalogus: geen clientrol leest of schrijft
--      rate_limit_counts, geen clientrol voert enforce_insert_rate_limit()
--      uit, en de gewone inserts op feedback en app_events zijn nog net zo
--      toegestaan als daarvoor (de deur is begrensd, niet op slot).
--   2. Een uitgelogde tester (rol anon, met gesimuleerde PostgREST-header)
--      kan nog steeds feedback sturen, en de trigger telt zijn afzender
--      dan ook echt (security definer schrijft de teller).
--   3. De rijgroottegrenzen: comment > 2000, context > 8000 en rating
--      buiten 1-5 worden geweigerd (23514); een normale rij met volledige
--      scorecontext en een lang maar echt commentaar gaat erdoor.
--   4. Het dagplafond per toestel: 20 feedbackrijen mogen, de 21e niet
--      (rw_rate_limited:feedback:device), en de teller staat netjes op 20.
--   5. Het dagplafond per account: 30 feedbackrijen mogen, de 31e niet
--      (rw_rate_limited:feedback:account), ook als er vandaag al telling
--      stond (de test werkt het resterende deel af).
--   6. Het dagplafond per afzender: 20 rijen van verscheidende toestellen
--      vanaf hetzelfde IP, de 21e geweigerd (rw_rate_limited:feedback:sender)
--      en een 22e met weer een ander toestel helpt niet: roteren van
--      device_id is precies wat deze telling onmogelijk maakt.
--   7. app_events: 120 rijen mogen, de 121e niet, per toestel én per
--      afzender (rw_rate_limited:app_events:device / :sender).
--   8. De serverklok: 20 rijen met created_at van twee dagen geleden vullen
--      de teller van VANDAAG, en de volgende rij met created_at van nu wordt
--      geweigerd. Terugdateren verplaatst geen quota.
--   9. De opruiming: tellerrijen van gisteren zijn na de eerstvolgende
--      insert weg; de afzenderhash blijft nooit langer dan een dag bestaan.
--  10. Een ongeldig request.headers (geen JSON) breekt de insert niet en
--      telt geen afzender mee.
--  11. usage_daily_counts (0014) werkt onaangetast: nog steeds 10 bronnen.
--
-- HOE TE DRAAIEN
--   Supabase Dashboard -> SQL Editor -> New query. Plak dit hele bestand en
--   draai het in één keer, NA 0016_rate_limits.sql. Alles zit in één
--   transactie die met `rollback` eindigt, geslaagd of niet: er blijft niets
--   achter -- geen testrijen, geen tellers, geen rolrecht. Veilig om zo vaak
--   te draaien als je wilt. Draai het vóór de PostgREST-probe uit plan
--   38-03: dit script verbruikt zelf ook afzenderquota (rollback maakt dat
--   ongedaan, de echte probe niet).
--
-- HOE HET RESULTAAT TE LEZEN
--   De SQL Editor toont geen notices (alleen fouten). Daarom komt elke check
--   als JSON in een transactie-lokale instelling (rw_test.results), en het
--   script eindigt met een gewone select die die instelling uitpakt:
--
--     seq | check_name | want | got | ok
--
--   Verwacht: 27 rijen, en in elke rij ok = true. Het getal 27 is precies het
--   aantal aanroepen van pg_temp.expect hieronder.
--
--   Mislukt er één check, dan zie je de tabel niet maar een fout:
--     RATE-TEST FAILED: 4.1 ... (want rw_rate_limited:feedback:device, got 23514); ...
--   met de naam, het verwachte en het werkelijke antwoord van elke mislukte
--   check. De naam begint met het nummer uit dit bestand. Een fout die NIET
--   met "RATE-TEST FAILED" begint, is een fout in het script zelf (of 0016
--   is nog niet toegepast), en zegt nog niets over de grens.
--
-- GEEN PRODUCTIETOTALEN (D-19)
--   `got` is een ja/nee, een SQLSTATE, een foutmelding, of een telling van
--   toestel-id's en IP-adressen die dit script zelf net heeft verzonnen. De
--   enige echte waarde die het script leest is de bestaande accountteller
--   van check 5 (hoeveel rijen dat account vandaag al had), en die blijft in
--   een variabele en verlaat het script nooit: de check zegt alleen hoe de
--   weigering luidt.
--
-- TECHNIEK
--   - Rol nadoen: `set local role anon` binnen een do-blok, met een
--     gesimuleerde PostgREST-header via `set local request.headers`. De
--     trigger leest die header precies zoals PostgREST hem aanbiedt. De
--     check wordt pas weggeschreven na `reset role`.
--   - Handelingen die mogen mislukken lopen via pg_temp.try_exec, die 'ok'
--     teruggeeft, of bij een fout de SQLSTATE, dan wel de P0001-melding
--     (zoals rw_rate_limited:feedback:device).
--   - De plafondchecks vullen de teller eerst tot nét aan het plafond met
--     gewone inserts (mislukt er daar één, dan is dat een scriptfout die
--     het hele do-blok stilzet), en bieden daarna precies één rij te veel
--     aan.
-- ---------------------------------------------------------------------------

begin;

-- ---------------------------------------------------------------------------
-- Raamwerk
-- ---------------------------------------------------------------------------

-- Geen tijdelijke tabel: in de SQL Editor gaf de slotselect op een
-- temp-tabel uit hetzelfde script altijd 42P01, ook in een kaal script van
-- vijf regels (2026-10-12), terwijl een transactie-lokale instelling daar
-- wél zichtbaar bleek. De rollback ruimt die net zo grondig op.

-- Legt een check vast. Stopt nooit: de eindcontrole beslist.
create function pg_temp.expect (p_name text, p_want text, p_got text)
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
       'want', p_want,
       'got', p_got,
       'ok', p_want is not distinct from p_got)))::text,
    true);
end;
$$;

-- Leest de checks terug, voor de eindcontrole.
create function pg_temp.results()
returns table (seq int, check_name text, want text, got text, ok boolean)
language sql
as $$
  select r.seq, r.check_name, r.want, r.got, r.ok
    from jsonb_to_recordset(
           coalesce(nullif(current_setting('rw_test.results', true), ''),
                    '[]')::jsonb)
         as r(seq int, check_name text, want text, got text, ok boolean)
$$;

-- Eén handeling. Bij succes 'ok'; bij een fout de SQLSTATE, of de
-- P0001-melding (de weigering van de trigger is een raise exception).
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

-- ---------------------------------------------------------------------------
-- 1. Grantgrens in de catalogus
-- ---------------------------------------------------------------------------

do $$
begin
  perform pg_temp.expect('1.1 anon heeft geen enkel recht op rate_limit_counts', 'false',
    has_table_privilege('anon', 'public.rate_limit_counts',
                        'insert,select,update,delete')::text);
  perform pg_temp.expect('1.2 authenticated heeft geen enkel recht op rate_limit_counts', 'false',
    has_table_privilege('authenticated', 'public.rate_limit_counts',
                        'insert,select,update,delete')::text);
  perform pg_temp.expect('1.3 anon mag de trigger-functie niet uitvoeren', 'false',
    has_function_privilege('anon', 'public.enforce_insert_rate_limit()', 'execute')::text);
  perform pg_temp.expect('1.4 authenticated mag de trigger-functie niet uitvoeren', 'false',
    has_function_privilege('authenticated', 'public.enforce_insert_rate_limit()', 'execute')::text);
  perform pg_temp.expect('1.5 authenticated heeft nog insert op feedback', 'true',
    has_table_privilege('authenticated', 'public.feedback', 'insert')::text);
  perform pg_temp.expect('1.6 anon heeft nog insert op feedback (anonieme route open)', 'true',
    has_table_privilege('anon', 'public.feedback', 'insert')::text);
end $$;

-- ---------------------------------------------------------------------------
-- 2. De anonieme route: als anon, met PostgREST-header, werkt de insert
--    nog steeds en wordt de afzender wél geteld.
-- ---------------------------------------------------------------------------

do $$
declare
  l_got   text;
  l_today date := (now() at time zone 'Europe/Amsterdam')::date;
begin
  set local request.headers = '{"x-forwarded-for":"203.0.113.5"}';
  set local role anon;
  l_got := pg_temp.try_exec('insert into public.feedback (rating) values (5)');
  reset role;

  perform pg_temp.expect('2.1 anon kan nog steeds feedback insturen', 'ok', l_got);
  -- Alleen de hash van het gesimuleerde IP: echte productietraffiek van
  -- vandaag mag deze telling niet kunnen beïnvloeden.
  perform pg_temp.expect('2.2 de afzender is geteld (security definer schrijft de teller)', '1',
    (select count(*)::text
       from public.rate_limit_counts
      where kind = 'feedback'
        and day = l_today
        and subject = 'sender:' || md5(l_today::text || ':203.0.113.5'))::text);
end $$;

-- ---------------------------------------------------------------------------
-- 3. Rijgrootte op feedback (RATE-03)
-- ---------------------------------------------------------------------------

do $$
begin
  set local request.headers = '';

  perform pg_temp.expect('3.1 comment van 2001 tekens geweigerd', '23514',
    pg_temp.try_exec('insert into public.feedback (rating, comment) '
                     'values (5, repeat(''x'', 2001))'));
  perform pg_temp.expect('3.2 context boven 8000 tekens geweigerd', '23514',
    pg_temp.try_exec('insert into public.feedback (rating, context) '
                     'values (5, jsonb_build_object(''pad'', repeat(''x'', 9000)))'));
  perform pg_temp.expect('3.3 rating 6 geweigerd', '23514',
    pg_temp.try_exec('insert into public.feedback (rating) values (6)'));
  perform pg_temp.expect('3.4 normale rij met context en lang comment gaat erdoor', 'ok',
    pg_temp.try_exec('insert into public.feedback (rating, comment, context) '
                     'values (5, repeat(''z'', 1000), '
                             'jsonb_build_object(''pad'', repeat(''y'', 1200)))'));
end $$;

-- ---------------------------------------------------------------------------
-- 4. Feedback: dagplafond per toestel (20)
-- ---------------------------------------------------------------------------

do $$
declare
  l_dev uuid := gen_random_uuid();
  l_i   integer;
  l_got text;
begin
  set local request.headers = '';

  for l_i in 1..20 loop
    insert into public.feedback (device_id, rating) values (l_dev, 5);
  end loop;

  l_got := pg_temp.try_exec('insert into public.feedback (device_id, rating) '
                            'values (''' || l_dev || ''', 5)');

  perform pg_temp.expect('4.1 de 21e feedbackrij van hetzelfde toestel geweigerd',
    'rw_rate_limited:feedback:device', l_got);
  perform pg_temp.expect('4.2 de toestelteller staat op 20 (de geweigerde rij telde niet mee)',
    '20',
    (select n::text from public.rate_limit_counts
      where kind = 'feedback' and subject = 'device:' || l_dev)::text);
end $$;

-- ---------------------------------------------------------------------------
-- 5. Feedback: dagplafond per account (30). Eerst het restant van een
--    eventueel bestaande telling van vandaag opvullen, dan één te veel.
-- ---------------------------------------------------------------------------

do $$
declare
  l_uid   uuid;
  l_stond integer;
  l_i     integer;
  l_got   text;
begin
  set local request.headers = '';

  select id into l_uid from auth.users order by created_at limit 1;
  if l_uid is null then
    raise exception 'RATE-TEST FAILED: geen account gevonden voor check 5';
  end if;

  select coalesce(n, 0) into l_stond
    from public.rate_limit_counts
   where kind = 'feedback'
     and day = (now() at time zone 'Europe/Amsterdam')::date
     and subject = 'account:' || l_uid;

  -- Geen tellerrij betekent nul, maar select into laat de variabele null;
  -- een null bovengrens zou de lus stilletjes overslaan.
  l_stond := coalesce(l_stond, 0);

  for l_i in 1..(30 - l_stond) loop
    insert into public.feedback (user_id, rating) values (l_uid, 5);
  end loop;

  l_got := pg_temp.try_exec('insert into public.feedback (user_id, rating) '
                            'values (''' || l_uid || ''', 5)');

  perform pg_temp.expect('5.1 de 31e feedbackrij van hetzelfde account geweigerd',
    'rw_rate_limited:feedback:account', l_got);
end $$;

-- ---------------------------------------------------------------------------
-- 6. Feedback: dagplafond per afzender (20). Elke rij een nieuw toestel,
--    dus alleen de afzender kan tellen: roteren helpt niet.
-- ---------------------------------------------------------------------------

do $$
declare
  l_i   integer;
  l_got text;
begin
  set local request.headers = '{"x-forwarded-for":"198.51.100.77"}';

  for l_i in 1..20 loop
    insert into public.feedback (device_id, rating) values (gen_random_uuid(), 5);
  end loop;

  l_got := pg_temp.try_exec('insert into public.feedback (device_id, rating) '
                            'values (gen_random_uuid(), 5)');
  perform pg_temp.expect('6.1 de 21e rij vanaf hetzelfde IP, met nieuw toestel, geweigerd',
    'rw_rate_limited:feedback:sender', l_got);

  l_got := pg_temp.try_exec('insert into public.feedback (device_id, rating) '
                            'values (gen_random_uuid(), 5)');
  perform pg_temp.expect('6.2 nóg een toestel draaien helpt niet',
    'rw_rate_limited:feedback:sender', l_got);
end $$;

-- ---------------------------------------------------------------------------
-- 7. app_events: dagplafond per toestel en per afzender (120)
-- ---------------------------------------------------------------------------

do $$
declare
  l_dev uuid := gen_random_uuid();
  l_i   integer;
  l_got text;
begin
  set local request.headers = '';

  -- app_events.id heeft geen default (0008: de app maakt de uuid op het
  -- toestel, anders dan feedback). De test geeft hem dus zelf mee.
  for l_i in 1..120 loop
    insert into public.app_events (id, device_id, name, platform, app_version, occurred_at)
      values (gen_random_uuid(), l_dev, 'test', 'android', '0', now());
  end loop;

  l_got := pg_temp.try_exec('insert into public.app_events '
    '(id, device_id, name, platform, app_version, occurred_at) '
    'values (gen_random_uuid(), ''' || l_dev || ''', ''test'', ''android'', ''0'', now())');
  perform pg_temp.expect('7.1 de 121e app_event van hetzelfde toestel geweigerd',
    'rw_rate_limited:app_events:device', l_got);
  perform pg_temp.expect('7.2 de toestelteller staat op 120',
    '120',
    (select n::text from public.rate_limit_counts
      where kind = 'app_events' and subject = 'device:' || l_dev)::text);

  set local request.headers = '{"x-forwarded-for":"198.51.100.78"}';
  for l_i in 1..120 loop
    insert into public.app_events (id, device_id, name, platform, app_version, occurred_at)
      values (gen_random_uuid(), gen_random_uuid(), 'test', 'android', '0', now());
  end loop;

  l_got := pg_temp.try_exec('insert into public.app_events '
    '(id, device_id, name, platform, app_version, occurred_at) '
    'values (gen_random_uuid(), gen_random_uuid(), ''test'', ''android'', ''0'', now())');
  perform pg_temp.expect('7.3 de 121e app_event vanaf hetzelfde IP geweigerd',
    'rw_rate_limited:app_events:sender', l_got);
end $$;

-- ---------------------------------------------------------------------------
-- 8. De serverklok (de insert-grant laat created_at meegeven, 0014-kop):
--    20 rijen van twee dagen geleden vullen de teller van vandaag.
-- ---------------------------------------------------------------------------

do $$
declare
  l_dev uuid := gen_random_uuid();
  l_i   integer;
  l_got text;
begin
  set local request.headers = '';

  for l_i in 1..20 loop
    insert into public.feedback (device_id, rating, created_at)
      values (l_dev, 5, now() - interval '2 days');
  end loop;

  l_got := pg_temp.try_exec('insert into public.feedback (device_id, rating) '
                            'values (''' || l_dev || ''', 5)');
  perform pg_temp.expect('8.1 rij met created_at van nu geweigerd: terugdateren verplaatst geen quota',
    'rw_rate_limited:feedback:device', l_got);
  perform pg_temp.expect('8.2 alle 20 teruggedateerde rijen telden op de serverdag van vandaag',
    '20',
    (select n::text from public.rate_limit_counts
      where kind = 'feedback'
        and day = (now() at time zone 'Europe/Amsterdam')::date
        and subject = 'device:' || l_dev)::text);
end $$;

-- ---------------------------------------------------------------------------
-- 9. Opruiming: tellerrijen van gisteren verdwijnen bij de eerstvolgende
--    insert van hetzelfde soort. Zo blijft de afzenderhash nooit langer
--    dan een dag bestaan.
-- ---------------------------------------------------------------------------

do $$
declare
  l_got text;
begin
  set local request.headers = '';

  insert into public.rate_limit_counts (kind, day, subject, n)
    values ('feedback', (now() at time zone 'Europe/Amsterdam')::date - 1, 'device:oud', 7);

  l_got := pg_temp.try_exec('insert into public.feedback (device_id, rating) '
                            'values (gen_random_uuid(), 5)');
  perform pg_temp.expect('9.1 de eerstvolgende insert na de zaaiing slaagt', 'ok', l_got);
  perform pg_temp.expect('9.2 de zaaiing van gisteren is opgeruimd (en de afzenderhash weg)',
    '0',
    (select count(*)::text from public.rate_limit_counts
      where kind = 'feedback'
        and day < (now() at time zone 'Europe/Amsterdam')::date)::text);
end $$;

-- ---------------------------------------------------------------------------
-- 10. Ongeldig request.headers (geen JSON): de insert breekt er niet op
--     en telt geen afzender mee. Gemeten als verschil: hoeveel afzenders
--     er ook al mochten staan door echte traffic, de ongeldige header
--     voegt er nul toe.
-- ---------------------------------------------------------------------------

do $$
declare
  l_before integer;
begin
  set local request.headers = 'geen-json';

  select count(*) into l_before
    from public.rate_limit_counts
   where kind = 'feedback'
     and day = (now() at time zone 'Europe/Amsterdam')::date
     and subject like 'sender:%';

  perform pg_temp.expect('10.1 ongeldige header breekt de insert niet', 'ok',
    pg_temp.try_exec('insert into public.feedback (device_id, rating) '
                     'values (gen_random_uuid(), 5)'));
  perform pg_temp.expect('10.2 bij een ongeldige header is geen afzender geteld',
    '0',
    (select (count(*) - l_before)::text
       from public.rate_limit_counts
      where kind = 'feedback'
        and day = (now() at time zone 'Europe/Amsterdam')::date
        and subject like 'sender:%')::text);
end $$;

-- ---------------------------------------------------------------------------
-- 11. Geen regressie: usage_daily_counts (0014) nog onaangetast
-- ---------------------------------------------------------------------------

do $$
begin
  perform pg_temp.expect('11.1 usage_daily_counts(1) geeft nog steeds 10 bronnen', '10',
    (select count(*)::text from public.usage_daily_counts(1)));
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
  from pg_temp.results()
  where not ok;

  if v_failed is not null then
    raise exception 'RATE-TEST FAILED: %', v_failed;
  end if;

  select count(*) into v_total from pg_temp.results();
  if v_total <> 27 then
    raise exception 'RATE-TEST FAILED: % checks geschreven, 27 verwacht', v_total;
  end if;
end $$;

-- Bewust zonder pg_temp-functie en met een lege terugval: als de editor
-- deze select ook buiten de sessie van het script uitvoert, levert dat een
-- lege set op in plaats van een fout die het echte resultaat verdringt.
select r.seq, r.check_name, r.want, r.got, r.ok
  from jsonb_to_recordset(
         coalesce(nullif(current_setting('rw_test.results', true), ''),
                  '[]')::jsonb)
       as r(seq int, check_name text, want text, got text, ok boolean)
 order by r.seq;

rollback;
