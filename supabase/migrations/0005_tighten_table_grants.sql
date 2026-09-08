-- 0005_tighten_table_grants.sql
--
-- Rechten opruimen die niemand heeft gezet en niemand nodig heeft.
--
-- Aanleiding
-- ----------
-- Joost draaide op 2026-09-08 de controlequery uit `0004`, en er kwam meer
-- terug dan verwacht:
--
--   anon          | INSERT, TRUNCATE, REFERENCES, TRIGGER
--   authenticated | INSERT, TRUNCATE, REFERENCES, TRIGGER
--   service_role  |         TRUNCATE, REFERENCES, TRIGGER
--
-- De INSERT-regels zijn van ons (0001 en 0004). De andere drie zijn dat niet:
-- geen enkele migratie in dit project grant TRUNCATE, REFERENCES of TRIGGER.
-- Ze komen uit de standaardrechten die Supabase op het `public`-schema zet en
-- zijn bij het aanmaken van de tabel meegeërfd.
--
-- Waarom dit ertoe doet
-- ---------------------
-- `TRUNCATE` leegt de hele tabel en **negeert row-level security volledig** --
-- policies gelden alleen voor SELECT/INSERT/UPDATE/DELETE. Een rol met
-- TRUNCATE kan dus alles wissen, hoe streng de policies ook zijn.
--
-- Vandaag is dat niet bereikbaar: PostgREST vertaalt HTTP-werkwoorden naar
-- SELECT/INSERT/UPDATE/DELETE en RPC naar functies, en kent geen TRUNCATE. Dit
-- is dus geen gat maar een klaarliggend recht -- één `security definer`-functie
-- of één misplaatste RPC ervandaan om wél te tellen. Dat is precies het soort
-- ding dat je opruimt terwijl het nog niets kost.
--
-- `REFERENCES` (foreign keys naar deze tabel mogen leggen) en `TRIGGER`
-- (triggers erop mogen zetten) horen om dezelfde reden niet bij een clientrol.
--
-- Wat hier NIET gebeurt
-- ---------------------
-- Geen `select` erbij voor `anon` of `authenticated`. FB-05 eist dat een client
-- feedback kan schrijven en nooit terug kan lezen; dat is nu zo en dat blijft
-- zo. De INSERT-grants blijven onaangeroerd -- die zijn de anonieme route van
-- FB-03 en het werkende pad van vandaag.

begin;

revoke truncate, references, trigger on public.feedback
  from anon, authenticated;

commit;

-- ---------------------------------------------------------------------------
-- Controle
-- ---------------------------------------------------------------------------
-- select grantee, privilege_type
--   from information_schema.role_table_grants
--  where table_schema = 'public' and table_name = 'feedback'
--    and grantee in ('anon', 'authenticated')
--  order by grantee, privilege_type;
--
-- Verwacht: precies twee regels, INSERT voor `anon` en INSERT voor
-- `authenticated`. Staat er SELECT bij, dan is FB-05 gebroken.
--
-- ---------------------------------------------------------------------------
-- Staat dit ook op de andere tabellen?
-- ---------------------------------------------------------------------------
-- Ja. Joost draaide de query op 2026-09-08 en het patroon stond op elke tabel.
-- Daar gaat `0006_tighten_grants_schema_wide.sql` over; die pakt ook de
-- oorzaak aan, zodat een nieuwe tabel ze niet opnieuw erft. Deze migratie is
-- uitgevoerd en blijft staan zoals hij was.
--
--   select table_name, grantee, string_agg(privilege_type, ', ' order by
--          privilege_type) as rechten
--     from information_schema.role_table_grants
--    where table_schema = 'public'
--      and grantee in ('anon', 'authenticated')
--    group by table_name, grantee
--    order by table_name, grantee;
--
-- Let op `profiles`, `availability`, `planned_rides`, `friendships`,
-- `friend_invites`, `group_rides` en `group_ride_participants`. Overal waar
-- TRUNCATE opduikt geldt hetzelfde verhaal: RLS beschermt die tabel niet tegen
-- een truncate.
