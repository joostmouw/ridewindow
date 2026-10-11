-- 0016 — dagplafonds en rijgroottegrenzen op de open deuren.
--
-- Aanleiding
-- ----------
-- Fase 38 van epic "Dicht huis" (v4.3), na de nulmeting van fase 37
-- (37-NULMETING.md). Iedereen met de app heeft de publieke sleutel; tot
-- vandaag kon die onbeperkt rijen in `feedback` en `app_events` blijven
-- insturen. Meten ging voor (fase 37); nu volgt het begrenzen.
--
-- De plafonds (uit de nulmeting, D-18: 10x het drukste echte toestel,
-- naar boven afgerond)
-- --------------------------------------------------------------------
--   feedback    account   30 per dag   (drukste account gemeten: 3)
--   feedback    toestel   20 per dag   (drukste anonieme toestel: ~2)
--   feedback    afzender  20 per dag   (zelfde orde als toestel)
--   app_events  toestel  120 per dag   (drukste toestel gemeten: 12)
--   app_events  afzender 120 per dag
--
-- Een gewone gebruiker merkt hier niets van: de nulmeting liet geen enkel
-- toestel boven de 12 rijen per dag komen, op een bewust zware sessie na.
--
-- Waarom de afzender apart telt
-- ------------------------------
-- Een aanvaller die de publieke sleutel heeft, kiest zelf een device_id per
-- rij en wint zo van elke telling per toestel. Daarom telt de database ook
-- de afzender: het eerste IP-adres uit x-forwarded-for, zoals PostgREST het
-- doorgeeft in de custom-GUC request.headers. Bewaard wordt alléén een hash:
-- md5(dag || ip). Het dagzout maakt koppeling van dezelfde afzender over
-- dagen onmogelijk, en de tellerrijen worden bij elke insert opgeruimd zodra
-- ze ouder zijn dan één dag: geen cron, geen taak van buiten. Het
-- privacybeleid beschrijft deze bewaartermijn in fase 40 (AFR-01).
--
-- Ontbreekt of beschadigt de header (SQL Editor, Supavisor-pooler, lege
-- string, ongeldig JSON), dan valt de afzendertelling netjes weg en blijven
-- toestel en account over; een insert mag nooit aan de headerlezing kapot
-- gaan.
--
-- Waarom de serverklok
-- --------------------
-- De insert-grant staat een client toe zelf `created_at` mee te sturen
-- (opgemerkt in de kop van 0014). De teller loopt daarom op de serverklok
-- (Europe/Amsterdam), niet op de rij: terugdateren verplaatst geen quota.
--
-- Rijgrootte (RATE-03)
-- --------------------
-- `feedback` had geen enkele lengtegrens. Nieuw: comment maximaal 2000
-- tekens (het invoerveld is vier regels), context als tekst maximaal 8000
-- tekens (een volledige scorecontext meet ~1-2 KB, dus 5x marge), rating
-- null of 1 t/m 5. De constraints komen er als NOT VALID bij: bestaande rijen
-- worden niet geherwaardeerd (die hoorden bij de meting), nieuwe en
-- gewijzigde wel gecontroleerd.
-- `app_events` krijgt geen nieuwe checks: 0008 begrenst die tabel al
-- volledig (naam 1-40, props <= 500 tekens, app_version <= 20, platform enum).
--
-- Wat dit níet is
-- ---------------
-- Geen captcha en geen App Check: pas als de metingen erom vragen (leidend
-- principe van deze milestone). De anonieme feedbackroute blijft open
-- (FB-03): begrenzen mag, blokkeren niet; het bewijs dat een uitgelogde
-- tester er nog steeds doorheen komt staat in rate_limits_test.sql, check 2.
-- `usage_daily_counts` (0014) blijft ongemoeid: geen bron of kolom van de
-- telling verandert, en de nieuwe `device_id`-kolom raakt de splitsing op
-- `user_id` niet.
--
-- Verantwoording (CLAUDE.md-regel)
-- --------------------------------
-- Dit is server-functie nummer 15: public.enforce_insert_rate_limit(). De
-- client kan dit aantoonbaar niet vervangen, want de grens moet ook gelden
-- voor builds die al bij testers en in productie staan en dus nooit een
-- update krijgen (RATE-04). CLAUDE.md en AGENTS.md worden pas in fase 40
-- (AFR-02) bijgewerkt; dit hoofdstuk is de verantwoording zolang.
--
-- Toepassen: Supabase SQL Editor (zoals 0010-0015), na bevestiging van de
-- plafondgetallen door Joost. Daarna rate_limits_test.sql draaien.

begin;

-- 1. Feedback krijgt een toestel. Builds vóór deze migratie sturen hem niet
--    en vallen onder de afzendertelling; nieuwe builds (plan 38-02) wel.
alter table public.feedback add column if not exists device_id uuid;

comment on column public.feedback.device_id is
  'Willekeurige uuid per toestel, aangemaakt door de app bij het eerste '
  'feedbackbericht. Doel: dagplafond per toestel (0016). Los van de '
  'statistiek-toestemming, want die verdwijnt bij intrekken en feedback '
  'moet ook daarna begrensd kunnen worden.';

-- 2. Rijgroottegrenzen op feedback, NOT VALID: nieuwe rijen gecontroleerd,
--    bestaande met rust gelaten.
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'feedback_comment_max_len') then
    alter table public.feedback add constraint feedback_comment_max_len
      check (comment is null or char_length(comment) <= 2000) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'feedback_context_max_len') then
    alter table public.feedback add constraint feedback_context_max_len
      check (context is null or char_length(context::text) <= 8000) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'feedback_rating_range') then
    alter table public.feedback add constraint feedback_rating_range
      check (rating is null or rating between 1 and 5) not valid;
  end if;
end
$$;

-- 3. De teller. Geen grants aan anon of authenticated: na 0006 erft een
--    nieuwe tabel geen clientrechten, en de trigger schrijft als eigenaar.
--    RLS aan zonder policies is de tweede, onnodige maar goedkope deur.
create table if not exists public.rate_limit_counts (
  kind    text not null,
  day     date not null,
  subject text not null,
  n       bigint not null default 0,
  primary key (kind, day, subject)
);

comment on table public.rate_limit_counts is
  'Dagtellers voor de insertgrenzen (0016). Subjecten zijn gehashte '
  'afzenders of toestel-/account-uuid''s; rijen ouder dan één dag ruimt de '
  'trigger zelf op. Alleen de eigenaar leest en schrijft hier.';

alter table public.rate_limit_counts enable row level security;

-- 4. Eén trigger-functie voor beide tabellen. Eén functie, geen helpers:
--    de tellen-en-weigeren-logica hoort bij elkaar en de functietelling in
--    CLAUDE.md gaat er niet dubbel van groeien.
create or replace function public.enforce_insert_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  l_kind    text := tg_table_name;
  l_today   date := (now() at time zone 'Europe/Amsterdam')::date;
  l_headers text;
  l_ip      text;
  l_sender  text;
  l_entries text[] := array[]::text[];
  l_entry    text;
  l_subject text;
  l_ceiling int;
  l_n       bigint;
begin
  -- Afzenderhash hooguit één dag bewaren: elke insert ruimt eerdere dagen
  -- van zijn eigen tabel op. Zonder cron.
  delete from public.rate_limit_counts
   where kind = l_kind
     and day < l_today;

  -- De header bestaat in vier toestanden: afwezig (SQL Editor, pooler),
  -- lege string, ongeldig JSON, of goed. Alleen de laatste levert een
  -- afzender, en geen enkele toestand mag de insert breken.
  l_headers := nullif(btrim(current_setting('request.headers', true)), '');
  l_ip := null;
  if l_headers is not null then
    begin
      l_ip := nullif(btrim(split_part(
        coalesce(l_headers::json ->> 'x-forwarded-for', ''), ',', 1)), '');
    exception when others then
      l_ip := null;
    end;
  end if;

  l_sender := null;
  if l_ip is not null then
    -- Dagzout: dezelfde hash is morgen onbruikbaar voor koppeling.
    l_sender := 'sender:' || md5(l_today::text || ':' || l_ip);
  end if;

  -- Onderwerpen en plafonds, als subject|plafond per tabel. Toestel en
  -- account worden alleen geteld als de kolom gevuld is; de afzender
  -- altijd, juist om roterende device_id's zinloos te maken.
  if l_kind = 'feedback' then
    if l_sender is not null then
      l_entries := l_entries || (l_sender || '|20');
    end if;
    if new.user_id is not null then
      l_entries := l_entries || ('account:' || new.user_id::text || '|30');
    end if;
    if new.device_id is not null then
      l_entries := l_entries || ('device:' || new.device_id::text || '|20');
    end if;
  elsif l_kind = 'app_events' then
    if l_sender is not null then
      l_entries := l_entries || (l_sender || '|120');
    end if;
    l_entries := l_entries || ('device:' || new.device_id::text || '|120');
  else
    -- Verdedigingsregel: de trigger hangt alleen aan deze twee tabellen.
    raise exception 'rw_rate_limit:unknown_table:%', l_kind;
  end if;

  foreach l_entry in array l_entries loop
    l_subject := split_part(l_entry, '|', 1);
    l_ceiling := split_part(l_entry, '|', 2)::int;

    insert into public.rate_limit_counts (kind, day, subject, n)
      values (l_kind, l_today, l_subject, 1)
      on conflict (kind, day, subject)
      do update set n = public.rate_limit_counts.n + 1
      returning n into l_n;

    if l_n > l_ceiling then
      -- De client herkent de prefix en laat de rij in de outbox staan
      -- (plan 38-02). Doordat de hele insert-instructie terugrolt, gaan
      -- ook de tellerverhogingen die al gelukt waren mee terug: geen
      -- halve telling.
      raise exception 'rw_rate_limited:%:%', l_kind, split_part(l_subject, ':', 1);
    end if;
  end loop;

  return new;
end;
$$;

comment on function public.enforce_insert_rate_limit() is
  'Weigert inserts op feedback/app_events boven het dagplafond per toestel, '
  'per account (feedback) en per afzender (gehasht IP, max één dag bewaard); '
  'telt op de serverklok (0016, fase 38).';

-- 5. Triggers aan beide deuren. drop-if-exists zodat de migratie opnieuw
--    geplakt kan worden.
drop trigger if exists rate_limit on public.feedback;
create trigger rate_limit
  before insert on public.feedback
  for each row execute function public.enforce_insert_rate_limit();

drop trigger if exists rate_limit on public.app_events;
create trigger rate_limit
  before insert on public.app_events
  for each row execute function public.enforce_insert_rate_limit();

-- 6. Les uit 0015: een nieuwe functie krijgt standaard PUBLIC-execute, en
--    elke rol is lid van PUBLIC. Alleen de eigenaar, via de triggers.
revoke all on function public.enforce_insert_rate_limit() from public, anon, authenticated;

commit;

-- ---------------------------------------------------------------------------
-- Controle (in de SQL Editor, na de commit)
-- ---------------------------------------------------------------------------
-- 1. Geen clientrechten op de teller (verwacht: geen rijen voor anon of
--    authenticated):
--   select grantee, privilege_type
--     from information_schema.role_table_grants
--    where table_schema = 'public' and table_name = 'rate_limit_counts';
--
-- 2. De trigger-functie is niet aanroepbaar door de client (verwacht: false):
--   select has_function_privilege('anon', 'public.enforce_insert_rate_limit()', 'execute'),
--          has_function_privilege('authenticated', 'public.enforce_insert_rate_limit()', 'execute');
--
-- 3. Een te lange opmerking wordt geweigerd (verwacht: foutmelding over
--    feedback_comment_max_len):
--   insert into public.feedback (rating, comment) values (5, repeat('x', 2001));
--   rollback;
--
-- 4. Het volledige bewijs staat in supabase/tests/rate_limits_test.sql.
-- ---------------------------------------------------------------------------
