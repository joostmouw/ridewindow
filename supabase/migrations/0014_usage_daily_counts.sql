-- ---------------------------------------------------------------------------
-- 0014_usage_daily_counts.sql — milestone v4.3 "Dicht huis" (fase 37, MEET-01)
--
-- Eerst meten, dan begrenzen.
--
-- Aanleiding
-- ----------
-- Epic #75 "Dicht huis" sluit de open deuren in de database: wie de publieke
-- app-sleutel heeft (en die zit in elke build), kan feedback, gebruiks-
-- gebeurtenissen, uitnodigingen en groepsritten aanmaken zo vaak hij wil. Een
-- plafond zetten zonder te weten wat normaal is, raakt vroeg of laat een echte
-- tester. Fase 37 meet daarom eerst: per dag hoeveel rijen er bijkwamen, en van
-- hoeveel verschillende afzenders. Fase 38 en 39 kiezen hun plafonds op basis
-- van die nulmeting.
--
-- Verantwoording (de regel uit CLAUDE.md, "No backend")
-- ------------------------------------------------------
-- Dit is server-functie nummer 14. Hij bestaat omdat de client het aantoonbaar
-- niet kan, en ook het lokale rapport met de service-role-sleutel niet:
--   - hij leest `auth.users` (nieuwe accounts per provider), en
--   - hij leest `friend_invites`, `group_invites` en `group_ride_options`,
--     waarop zelfs `service_role` geen select heeft (0005/0006/0012).
-- Die select alsnog geven zou betekenen dat de sleutel op Joosts machine ruwe
-- uitnodigingscodes kan lezen -- en een code is de capability (keuze 1 uit
-- 0002). Een dagtotaal geeft veel minder prijs dan dat. De functie geeft
-- daarom nooit een rij, een id, een code, een e-mailadres of tekst terug;
-- alleen getallen per dag per bron.
--
-- De telling in CLAUDE.md en AGENTS.md ("thirteen of them today") wordt bewust
-- pas in fase 40 (AFR-02) bijgewerkt naar veertien, samen met wat fase 38 en
-- 39 nog toevoegen. Tot dan is deze kop de verantwoording.
--
-- Wat dit wel en niet verandert
-- -----------------------------
-- Wel: één functie, één login-rol (`usage_monitor`), en de grants daarvoor.
-- Niet: geen nieuwe tabel, geen kolom, geen leesrecht voor `anon` of
-- `authenticated`, en geen extra tabelrecht voor `service_role`.
-- Mislukte inwisselpogingen (`redeem_friend_invite`, `redeem_group_invite` met
-- een verkeerde code) worden niet geteld: ze schrijven niets weg, dus er is
-- niets om te tellen. Dat komt met de teller van fase 39.
--
-- Ondergrens
-- ----------
-- Er worden rijen geteld die nu nog bestaan. Waar rijen verdwijnen, is de
-- telling van een vroegere dag dus een ondergrens van wat er die dag
-- werkelijk aangemaakt werd:
--   - `friend_invites`: intrekken door de maker; cascade bij het verwijderen
--     van zijn account.
--   - `group_invites`: intrekken door een beheerder; cascade bij het opheffen
--     van de groep.
--   - `group_rides`: verwijderen door de eigenaar; cascade bij het verwijderen
--     van zijn account.
--   - `group_ride_options`: de app wist alle opties van een rit zodra er een
--     venster gekozen of de rit bewerkt wordt (peloton_gateway.dart,
--     `.delete().eq('ride_id', ...)`), plus cascade met de rit. Dit is de
--     zwakste ondergrens: een rustige dag kan achteraf veel drukker geweest
--     zijn.
--   - nieuwe accounts (`accounts_*`): `delete_own_account` haalt de rij uit
--     `auth.users` weg.
-- `feedback` en `app_events` verdwijnen niet. Wel schuift feedback van een
-- verwijderd account van `feedback_account` naar `feedback_anoniem`
-- (`user_id ... on delete set null`).
--
-- Afzender per bron
-- -----------------
--   feedback_account     user_id
--   feedback_anoniem     geen (feedback heeft geen device_id; alleen rijen)
--   app_events           device_id
--   friend_invites       inviter_id
--   group_invites        created_by (null na accountverwijdering: telt als
--                        rij, niet als afzender)
--   group_rides          owner_id
--   group_ride_options   group_rides.owner_id via ride_id -- de opties hebben
--                        geen eigen aanmaker-kolom, en alleen de eigenaar mag
--                        ze schrijven (policy group_ride_options_write_owner)
--   accounts_google / accounts_email / accounts_overig
--                        geen; `raw_app_meta_data->>'provider'`
--
-- Dag
-- ---
-- Kalenderdagen in Europe/Amsterdam, op `created_at` (server-default now()),
-- niet op `app_events.occurred_at` (die zet de client, en de outbox kan dagen
-- achterlopen). Kanttekening: de huidige insert-grant laat een client zelf een
-- `created_at` meesturen en zo rijen terugdateren. Voor meten is dat
-- geaccepteerd; fase 38 begrenst de inserts en kan dat dichtzetten.
--
-- Het rooster is dicht: elke dag in het venster krijgt voor elk van de tien
-- bronnen een regel, ook zonder rijen (rows = 0). Zo tellen lege dagen mee
-- als 0 in de mediaan van de uitschieterregel.
--
-- Rol usage_monitor
-- -----------------
-- Een login-rol voor de dagelijkse GitHub Action (MEET-02). Die verbindt met
-- psql via de Supavisor-pooler: gebruikersnaam
-- `usage_monitor.hcdrydlgqpnmumfupgcx`, sessiemodus op poort 5432, IPv4
-- (GitHub-runners hebben geen IPv6). Supabase-docs: "If you connect as a
-- custom role through the shared pooler, the username is
-- [ROLE].[PROJECT-REF]".
--
-- De rol mag precies één ding: deze functie uitvoeren. Geen tabelrecht, geen
-- `auth`-schema, alleen-lezen transacties, hooguit drie verbindingen en 30
-- seconden per statement. De service-role-sleutel blijft daarmee buiten
-- GitHub (zie .github/workflows/supabase-keep-warm.yml).
--
-- Het wachtwoord staat NIET in deze migratie: een wachtwoord hoort nooit in
-- de repo, en deze repo is publiek. Joost zet het eenmalig in de SQL Editor
-- met de waarde uit `~/.config/ridewindow/usage-monitor.pw` (plan 37-04).
-- Tot dan kan de rol niet inloggen.
-- ---------------------------------------------------------------------------

begin;

-- ---------------------------------------------------------------------------
-- 1. De rol
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'usage_monitor') then
    create role usage_monitor
      login noinherit nocreatedb nocreaterole nosuperuser
      connection limit 3;
  end if;
end
$$;

-- Buiten het if-blok, zodat opnieuw draaien de instellingen herstelt.
alter role usage_monitor set statement_timeout = '30s';
alter role usage_monitor set default_transaction_read_only = on;

-- Nodig om public.usage_daily_counts te kunnen vinden. Verder niets.
grant usage on schema public to usage_monitor;

-- ---------------------------------------------------------------------------
-- 2. De telfunctie
--
-- `set search_path = ''`: een security definer-functie met een zoekpad dat de
-- aanroeper kan beïnvloeden, is een bekende ontsnapping. Alle namen zijn
-- daarom volledig gekwalificeerd (`public.`, `auth.`).
--
-- `#variable_conflict use_column`: de uitvoerkolommen (day, source, rows, ...)
-- zijn in plpgsql ook variabelen. Intern gebruiken we daarom andere namen
-- (d, src, n_*), en deze regel beslist een eventuele botsing voor de kolom.
-- ---------------------------------------------------------------------------

create or replace function public.usage_daily_counts(p_days int)
returns table (
  day                 date,
  source              text,
  rows                bigint,
  distinct_senders    bigint,
  max_rows_one_sender bigint,
  p95_rows_one_sender numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_today date;
  v_first date;
  v_start timestamptz;
begin
  if p_days is null or p_days < 1 or p_days > 3660 then
    raise exception using errcode = '22023', message = 'p_days_out_of_range';
  end if;

  v_today := (now() at time zone 'Europe/Amsterdam')::date;
  v_first := v_today - (p_days - 1);
  v_start := (v_first::timestamp at time zone 'Europe/Amsterdam');

  return query
  with ev (src, sender, d) as (
    select 'feedback_account'::text, f.user_id,
           (f.created_at at time zone 'Europe/Amsterdam')::date
      from public.feedback f
     where f.user_id is not null and f.created_at >= v_start
    union all
    select 'feedback_anoniem'::text, null::uuid,
           (f.created_at at time zone 'Europe/Amsterdam')::date
      from public.feedback f
     where f.user_id is null and f.created_at >= v_start
    union all
    select 'app_events'::text, e.device_id,
           (e.created_at at time zone 'Europe/Amsterdam')::date
      from public.app_events e
     where e.created_at >= v_start
    union all
    select 'friend_invites'::text, fi.inviter_id,
           (fi.created_at at time zone 'Europe/Amsterdam')::date
      from public.friend_invites fi
     where fi.created_at >= v_start
    union all
    select 'group_invites'::text, gi.created_by,
           (gi.created_at at time zone 'Europe/Amsterdam')::date
      from public.group_invites gi
     where gi.created_at >= v_start
    union all
    select 'group_rides'::text, gr.owner_id,
           (gr.created_at at time zone 'Europe/Amsterdam')::date
      from public.group_rides gr
     where gr.created_at >= v_start
    union all
    select 'group_ride_options'::text, r.owner_id,
           (o.created_at at time zone 'Europe/Amsterdam')::date
      from public.group_ride_options o
      join public.group_rides r on r.id = o.ride_id
     where o.created_at >= v_start
    union all
    select case u.raw_app_meta_data->>'provider'
             when 'google' then 'accounts_google'
             when 'email'  then 'accounts_email'
             else 'accounts_overig'
           end::text,
           null::uuid,
           (u.created_at at time zone 'Europe/Amsterdam')::date
      from auth.users u
     where u.created_at >= v_start
  ),
  per_sender as (
    select ev.src, ev.d, ev.sender, count(*) as n
      from ev
     group by ev.src, ev.d, ev.sender
  ),
  per_day as (
    select ps.src,
           ps.d,
           sum(ps.n)::bigint as n_rows,
           count(ps.sender)  as n_senders,
           max(ps.n) filter (where ps.sender is not null) as n_max,
           round((percentile_cont(0.95) within group (order by ps.n)
                    filter (where ps.sender is not null))::numeric, 2) as n_p95
      from per_sender ps
     group by ps.src, ps.d
  ),
  sources (src, has_sender) as (
    values ('feedback_account',   true),
           ('feedback_anoniem',   false),
           ('app_events',         true),
           ('friend_invites',     true),
           ('group_invites',      true),
           ('group_rides',        true),
           ('group_ride_options', true),
           ('accounts_google',    false),
           ('accounts_email',     false),
           ('accounts_overig',    false)
  ),
  days (d) as (
    select g::date
      from generate_series(v_first::timestamp, v_today::timestamp,
                           interval '1 day') as g
  )
  select days.d,
         s.src::text,
         coalesce(pd.n_rows, 0)::bigint,
         (case when s.has_sender then coalesce(pd.n_senders, 0) end)::bigint,
         (case when s.has_sender then pd.n_max end)::bigint,
         (case when s.has_sender then pd.n_p95 end)::numeric
    from days
   cross join sources s
    left join per_day pd on pd.src = s.src and pd.d = days.d
   order by days.d, s.src;
end;
$$;

comment on function public.usage_daily_counts(int) is
  'Dicht huis, fase 37: alleen totalen per Amsterdamse dag en per bron, nooit '
  'rijen; lezers zijn het lokale rapport (tool/usage_report.dart) en de '
  'dagelijkse wacht (GitHub Action als usage_monitor).';

-- ---------------------------------------------------------------------------
-- 3. Wie mag hem aanroepen
-- ---------------------------------------------------------------------------

revoke all on function public.usage_daily_counts(int) from public, anon, authenticated;
grant execute on function public.usage_daily_counts(int) to service_role, usage_monitor;

commit;

-- ---------------------------------------------------------------------------
-- Controle
-- ---------------------------------------------------------------------------
-- select grantee, privilege_type
--   from information_schema.routine_privileges
--  where routine_schema = 'public' and routine_name = 'usage_daily_counts'
--  order by grantee;
--
-- Verwacht: postgres, service_role en usage_monitor, elk EXECUTE. Staat anon,
-- authenticated of PUBLIC erbij, dan kan iedereen met de app-sleutel tellen.
--
-- select c.relname, has_table_privilege('usage_monitor', c.oid,
--          'select, insert, update, delete') as mag
--   from pg_class c
--   join pg_namespace n on n.oid = c.relnamespace
--  where n.nspname = 'public' and c.relkind in ('r', 'p', 'v', 'm')
--  order by c.relname;
--
-- Verwacht: in elke rij mag = false.
--
-- select count(*) from public.usage_daily_counts(2);
--
-- Verwacht: 20 (2 dagen x 10 bronnen).
--
-- Het volledige bewijs staat in supabase/tests/usage_counts_test.sql.
-- ---------------------------------------------------------------------------
