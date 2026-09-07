-- 0004_feedback_anonymous_insert.sql
--
-- FB-03: ook een uitgelogde gebruiker moet feedback kunnen sturen.
--
-- Waarom dit nodig is
-- -------------------
-- `0001_accounts_sync.sql` regelde de policy-kant al goed:
--
--   create policy "insert own feedback" on public.feedback
--     for insert with check (user_id is null or auth.uid() = user_id);
--
-- Die `user_id is null`-tak is er expliciet voor anonieme feedback. Maar de
-- grant eronder ging alleen naar `authenticated`:
--
--   grant insert on public.feedback to authenticated;
--
-- Postgres controleert tabelrechten **vóór** het policies evalueert, dus een
-- uitgelogde client (rol `anon`) strandt op de grant en komt nooit bij de
-- policy die hem juist toelaat. De helft die het schema wél had was daarmee
-- onbereikbaar. Dat is dezelfde soort fout als de RLS-weigering op
-- `group_rides` van 2026-09-07: de twee lagen moeten allebei kloppen, en de
-- ene laag repareren zonder de andere levert niets op.
--
-- Wat hier expliciet NIET gebeurt
-- -------------------------------
-- Geen `select`. Niet voor `anon`, niet voor `authenticated`. FB-05 eist dat
-- een client feedback kan schrijven en nooit terug kan lezen -- dat is de reden
-- dat er op deze tabel bewust geen select-policy bestaat, en de grants moeten
-- dat volgen. Ook geen `update`: dat is niet alleen overbodig maar schadelijk,
-- want PostgREST's upsert (`resolution=merge-duplicates`) vraagt om
-- UPDATE-rechten, en met alleen INSERT is een upsert dus onmogelijk. Dat is
-- opzet: de app schrijft feedback met een gewone `insert`, niet met een upsert.
-- Zie de `insertRow`-tak in `CloudSyncReconciler.drainOutbox`.

begin;

grant insert on public.feedback to anon;

commit;

-- ---------------------------------------------------------------------------
-- Controle
-- ---------------------------------------------------------------------------
-- select grantee, privilege_type
--   from information_schema.role_table_grants
--  where table_schema = 'public' and table_name = 'feedback'
--  order by grantee, privilege_type;
--
-- Verwacht: precies twee regels, INSERT voor `anon` en INSERT voor
-- `authenticated`. Staat er ergens SELECT bij, dan is FB-05 gebroken.
