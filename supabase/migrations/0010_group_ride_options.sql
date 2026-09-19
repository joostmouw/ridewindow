-- 0010_group_ride_options.sql
--
-- Slice 2 van epic #65: nodig niet uit voor één moment, maar leg de beste
-- vensters van de week voor en laat de deelnemers kiezen.
--
-- Waarom dit het eerste stuk van de epic is
-- -----------------------------------------
-- Partiful, Komoot, Howbout en Strava plannen allemaal *een moment*. Geen van
-- vier weet of dat moment goed weer is om te fietsen. Dit is het stuk dat
-- alleen deze app kan: de keuze gaat over vensters die elk hun eigen score
-- dragen, en de groep kiest tussen weersvooruitzichten -- niet tussen lege
-- tijdvakken in een agenda.
--
-- Het model
-- ---------
-- Een `group_rides`-rij houdt zijn `start_at`/`end_at`: dat blijft de tijd die
-- vandaag geldt. De opties eromheen zijn de alternatieven die voorliggen.
-- Kiest de eigenaar er een, dan schuift `start_at`/`end_at` daarheen en is de
-- rit weer een gewone gedeelde rit.
--
-- **Waarom de rit altijd een tijd houdt** in plaats van "nog niet besloten" te
-- zijn: Home, de Agenda, de widget en de sortering draaien allemaal op die twee
-- kolommen. Een rit zonder tijd zou door alle vier heen moeten worden geleid --
-- dat is een verbouwing van de hele app voor een toestand die hoogstens een
-- paar dagen duurt. Nu is de tijd het huidige voorstel, en verschuift hij als
-- de groep dat wil. Dat is precies wat slice 4 later ook doet.
--
-- Wie wat mag
-- -----------
-- Lezen: iedereen die bij de rit hoort -- `is_ride_member`, dezelfde helper als
-- in 0002, die de policy-recursie breekt. Het hele punt van samen fietsen is
-- dat je elkaars antwoord ziet.
-- Opties zetten of weghalen: alleen de eigenaar. Stemmen: alleen namens jezelf,
-- afgedwongen in de policy en niet alleen in de app -- dezelfde regel als bij
-- het antwoorden op een uitnodiging.

begin;

-- ---------------------------------------------------------------------------
-- 1. De voorgelegde vensters
-- ---------------------------------------------------------------------------

create table if not exists public.group_ride_options (
  id            uuid primary key default gen_random_uuid(),
  ride_id       uuid not null references public.group_rides(id) on delete cascade,
  start_at      timestamptz not null,
  end_at        timestamptz not null,
  -- De score die de app op het moment van voorleggen berekende. Bewust
  -- vastgelegd en niet later herberekend: het weerbericht verandert, en dan
  -- zou achteraf niet meer te zien zijn waarop iemand zijn stem baseerde.
  planned_score real not null,
  created_at    timestamptz not null default now(),
  constraint group_ride_options_order check (end_at > start_at),
  -- Twee keer hetzelfde venster voorleggen is geen keuze maar een fout.
  constraint group_ride_options_unique unique (ride_id, start_at, end_at)
);

create index if not exists group_ride_options_ride_idx
  on public.group_ride_options (ride_id, start_at);

comment on table public.group_ride_options is
  'Slice 2 van epic #65: de vensters die voorliggen bij een gedeelde rit. '
  'De gekozen optie verhuist naar group_rides.start_at/end_at.';

-- ---------------------------------------------------------------------------
-- 2. De stemmen
-- ---------------------------------------------------------------------------

create table if not exists public.group_ride_option_votes (
  option_id  uuid not null references public.group_ride_options(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  -- Twee standen, geen drie. "Misschien" is slice 6 en verdient zijn eigen
  -- beslissing: het is de moeilijkste van de drie om goed te tonen, want het
  -- telt half mee in elk overzicht dat je erop bouwt.
  can_ride   boolean not null,
  voted_at   timestamptz not null default now(),
  primary key (option_id, user_id)
);

create index if not exists group_ride_option_votes_user_idx
  on public.group_ride_option_votes (user_id);

comment on table public.group_ride_option_votes is
  'Wie kan wanneer. Een rij per persoon per optie; geen rij = nog niet '
  'geantwoord, en dat is iets anders dan "nee".';

-- ---------------------------------------------------------------------------
-- 3. RLS
-- ---------------------------------------------------------------------------

alter table public.group_ride_options      enable row level security;
alter table public.group_ride_option_votes enable row level security;

create policy group_ride_options_select_member on public.group_ride_options
  for select using (public.is_ride_member(ride_id));

create policy group_ride_options_write_owner on public.group_ride_options
  for all
  using (
    exists (
      select 1 from public.group_rides r
      where r.id = ride_id and r.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.group_rides r
      where r.id = ride_id and r.owner_id = auth.uid()
    )
  );

-- Stemmen zijn zichtbaar voor iedereen die bij de rit hoort. De omweg via
-- `group_ride_options` is nodig omdat de stem zelf geen ride_id draagt; de
-- helper is `security definer`, dus dit kan geen recursie geven.
create policy group_ride_option_votes_select_member
  on public.group_ride_option_votes
  for select using (
    exists (
      select 1 from public.group_ride_options o
      where o.id = option_id and public.is_ride_member(o.ride_id)
    )
  );

-- Je stemt alleen namens jezelf, en alleen op een rit waar je bij hoort. De
-- eerste voorwaarde is dezelfde regel als bij het antwoorden op een
-- uitnodiging; de tweede houdt een vreemde buiten een stemming waar hij niets
-- te zoeken heeft.
create policy group_ride_option_votes_write_own
  on public.group_ride_option_votes
  for all
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.group_ride_options o
      where o.id = option_id and public.is_ride_member(o.ride_id)
    )
  );

-- ---------------------------------------------------------------------------
-- 4. Grants
--
-- Postgres controleert tabelrechten VOOR RLS -- zonder deze regels faalt alles,
-- ook met correcte policies. Dezelfde les als in 0001 en 0004. `anon` krijgt
-- niets: Peloton vraagt een account, en meekijken zonder account is op
-- 2026-09-19 bewust afgewezen.
-- ---------------------------------------------------------------------------

grant select, insert, update, delete on public.group_ride_options      to authenticated;
grant select, insert, update, delete on public.group_ride_option_votes to authenticated;

commit;

-- ---------------------------------------------------------------------------
-- Controle
-- ---------------------------------------------------------------------------
-- select tablename, rowsecurity from pg_tables
--  where schemaname = 'public'
--    and tablename in ('group_ride_options', 'group_ride_option_votes');
--
-- select tablename, policyname, cmd from pg_policies
--  where schemaname = 'public'
--    and tablename in ('group_ride_options', 'group_ride_option_votes')
--  order by tablename, policyname;
--
-- Verwacht: twee tabellen met rowsecurity = true, en vier policies --
-- options select/all, votes select/all.
-- ---------------------------------------------------------------------------
