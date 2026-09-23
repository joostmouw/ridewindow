-- 0011_feedback_service_role_select.sql
--
-- De feedback kwam binnen, maar niemand kon hem lezen.
--
-- Aanleiding
-- ----------
-- Op 2026-09-23 gaf een leesvraag met de service-role sleutel:
--
--   42501 permission denied for table feedback
--
-- Hetzelfde gat als 0009 bij `app_events`: 0001 gaf `feedback` bewust alleen
-- INSERT voor de app, en 0005 liet zien dat `service_role` op deze tabel geen
-- SELECT heeft. Alles wat testers via de app stuurden, stond dus in de
-- database zonder dat iemand het kon lezen. Fase 28 (feedbackstroom) en de
-- samenvatting in de productie-aanvraag hebben dat lezen nodig.
--
-- Wat dit wel en niet verandert
-- -----------------------------
-- Alleen SELECT, alleen voor `service_role`. Die sleutel staat in
-- `~/.config/ridewindow/`, buiten de repo, en komt nooit in een build. `anon`
-- en `authenticated` blijven insert-only: de app schrijft feedback en leest
-- hem nooit terug. Geen update, geen delete.

begin;

grant select on public.feedback to service_role;

commit;
