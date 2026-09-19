-- 0009_app_events_service_role_select.sql
--
-- De rapportage mocht lezen, maar had het recht niet.
--
-- Aanleiding
-- ----------
-- `tool/analytics_report.dart` draaide op 2026-09-19 voor het eerst met een
-- geldige service-role sleutel, en kreeg 403:
--
--   42501 permission denied for table app_events
--
-- Dat is geen sleutelprobleem -- bij een verkeerde sleutel geeft PostgREST 401.
-- Het is een gat tussen wat 0008 in woorden vastlegde en wat het in SQL deed.
--
-- Wat 0008 wel en niet zei
-- ------------------------
-- 0008 schreef bewust op: geen select-grant voor `anon` of `authenticated`, en
-- "de rapportage draait met de service-role sleutel vanaf Joosts eigen machine".
-- Die tweede helft is nooit een `grant` geworden. De aanname eronder was dat
-- `service_role` in Supabase standaard alles op `public` heeft -- maar 0005
-- bewees in dit project het tegendeel: op `public.feedback` had `service_role`
-- alleen TRUNCATE, REFERENCES en TRIGGER, geen SELECT. Dezelfde standaardrechten
-- gelden voor een nieuwe tabel, dus `app_events` erfde precies dat: geen select.
--
-- Wat dit wel en niet verandert
-- -----------------------------
-- Alleen SELECT, alleen voor `service_role`. Die rol komt nooit in een build:
-- de sleutel staat in `~/.config/ridewindow/`, buiten de repo (zie de kop van
-- `tool/analytics_report.dart`). `anon` en `authenticated` blijven insert-only
-- -- de regel uit 0004 en 0008 dat een client schrijft en nooit terugleest,
-- blijft onaangeroerd.
--
-- Geen update, geen delete, geen truncate. Rapporteren is lezen; opruimen is
-- een aparte beslissing die dan ook een aparte migratie verdient.

begin;

grant select on public.app_events to service_role;

commit;

-- ---------------------------------------------------------------------------
-- Controle
-- ---------------------------------------------------------------------------
-- select grantee, string_agg(privilege_type, ', ' order by privilege_type)
--   from information_schema.role_table_grants
--  where table_schema = 'public' and table_name = 'app_events'
--    and grantee in ('anon', 'authenticated', 'service_role')
--  group by grantee
--  order by grantee;
--
-- Verwacht: anon INSERT, authenticated INSERT, service_role SELECT (plus de
-- TRUNCATE/REFERENCES/TRIGGER die Supabase zelf op `service_role` zet -- die
-- zijn niet van ons en zijn hier bewust niet aangeraakt, zie 0006).
--
-- Staat er SELECT bij `anon` of `authenticated`, dan is de regel uit 0008
-- gebroken.
-- ---------------------------------------------------------------------------
