-- 0006_tighten_grants_schema_wide.sql
--
-- Wat 0005 voor één tabel deed, nu voor het hele schema -- plus de oorzaak.
--
-- Aanleiding
-- ----------
-- 0005 haalde TRUNCATE, REFERENCES en TRIGGER weg bij `public.feedback`. Joost
-- draaide daarna de schemabrede query en die liet zien dat het patroon overal
-- staat: `profiles`, `availability`, `planned_rides`, `friendships`,
-- `friend_invites`, `group_rides` en `group_ride_participants` geven `anon` en
-- `authenticated` alle drie, bovenop de DML-rechten die onze migraties bewust
-- wél granten.
--
-- Die drie komen niet uit dit project. Geen enkele migratie grant ze; ze komen
-- uit Supabase's standaardrechten op het `public`-schema en worden bij het
-- aanmaken van elke tabel meegeërfd.
--
-- Waarom dit ertoe doet
-- ---------------------
-- `TRUNCATE` leegt een tabel en **negeert row-level security volledig** --
-- policies gelden alleen voor SELECT/INSERT/UPDATE/DELETE. Elke RLS-regel in
-- 0001 en 0002 staat dus naast een recht dat er dwars doorheen gaat.
--
-- Vandaag is dat niet bereikbaar: PostgREST vertaalt HTTP-werkwoorden naar
-- SELECT/INSERT/UPDATE/DELETE en RPC naar functies, en kent geen TRUNCATE. Dit
-- is dus geen gat maar een klaarliggend recht. Opruimen terwijl het niets kost.
--
-- `REFERENCES` (foreign keys naar de tabel mogen leggen) en `TRIGGER` (triggers
-- erop mogen zetten) horen om dezelfde reden niet bij een clientrol.
--
-- Waarom een lus en geen lijstje
-- ------------------------------
-- Een handgeschreven lijst vergeet de tabel die je volgende week toevoegt, en
-- hij struikelt over `"Test table"` -- een tabel met een spatie in de naam die
-- in geen enkele migratie voorkomt (zie de noot onderaan). `format(%I)` citeert
-- zulke namen correct; met stringplakwerk zou dit een syntaxfout zijn.
--
-- Wat hier NIET gebeurt
-- ---------------------
-- **Niets aan `service_role`.** Die rol is server-side, komt nooit in een app
-- terecht, en Supabase's eigen gereedschap leunt erop. Rechten daar weghalen
-- repareert niets en kan wél iets breken.
--
-- **Niets aan DML.** Geen SELECT, INSERT, UPDATE of DELETE wordt aangeraakt.
-- Dit is puur het weghalen van rechten die nooit bewust zijn toegekend; de
-- werkende paden van de app veranderen niet.

begin;

-- 1. De bestaande tabellen.
do $$
declare
  t record;
begin
  for t in
    select tablename from pg_tables where schemaname = 'public'
  loop
    execute format(
      'revoke truncate, references, trigger on public.%I from anon, authenticated',
      t.tablename
    );
  end loop;
end;
$$;

-- 2. De oorzaak: zonder dit erft de volgende tabel die je aanmaakt ze weer.
--
-- `alter default privileges` geldt voor objecten die de *huidige* rol aanmaakt.
-- In de SQL-editor en in migraties is dat `postgres`, dezelfde rol waarvoor
-- Supabase zijn standaardrechten heeft gezet -- dus dit dekt het pad waarlangs
-- deze tabellen zijn ontstaan.
alter default privileges in schema public
  revoke truncate, references, trigger on tables from anon, authenticated;

commit;

-- ---------------------------------------------------------------------------
-- Controle
-- ---------------------------------------------------------------------------
-- select table_name, grantee, string_agg(privilege_type, ', ' order by
--        privilege_type) as rechten
--   from information_schema.role_table_grants
--  where table_schema = 'public'
--    and grantee in ('anon', 'authenticated')
--  group by table_name, grantee
--  order by table_name, grantee;
--
-- Verwacht na deze migratie:
--
--   anon           op elke tabel : niets, behalve INSERT op `feedback`
--   authenticated  op feedback   : INSERT
--                  op friendships: DELETE, SELECT
--                  op de rest    : DELETE, INSERT, SELECT, UPDATE
--
-- Tabellen waar `anon` nu helemaal uit de lijst verdwijnt zijn in orde: die
-- had hij ook nooit nodig. Alleen `feedback` heeft een anonieme route (FB-03).
--
-- ---------------------------------------------------------------------------
-- Nog open: `"Test table"`
-- ---------------------------------------------------------------------------
-- Staat in `public` maar in geen enkele migratie -- vermoedelijk overgebleven
-- uit de dashboard-editor. Hij is nu inert: clients hebben er geen DML op, dus
-- PostgREST kan hem niet lezen of schrijven.
--
-- Bewust niet hier verwijderd: een tabel weggooien is onomkeerbaar en het is
-- Joost's data, niet die van deze migratie. Controleer eerst of er iets in zit
-- en of RLS aan staat:
--
--   select relrowsecurity from pg_class
--    where oid = 'public."Test table"'::regclass;
--   select count(*) from public."Test table";
--
-- Is hij leeg en van niemand, dan is `drop table public."Test table";` de
-- opruiming -- als aparte migratie, met die uitkomst erin genoteerd.
