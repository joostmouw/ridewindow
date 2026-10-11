-- 0015: de twee security definer-functies uit 0001 alleen nog voor `authenticated`
--
-- Gevonden in fase 37 (v4.3 "Dicht huis"), toen check 3.1 van
-- `supabase/tests/usage_counts_test.sql` faalde: `usage_monitor` kon twee andere
-- security definer-functies in `public` uitvoeren. Dat waren
-- `migrate_account_data` en `delete_own_account`.
--
-- Oorzaak: Postgres geeft EXECUTE op een nieuwe functie standaard aan PUBLIC.
-- 0001 gaf wel `grant execute ... to authenticated`, maar nam het recht van
-- PUBLIC nooit af. Elke functie sinds 0002 doet dat wel
-- (`revoke all ... from public, anon`). Omdat elke rol lid is van PUBLIC, konden
-- ook `anon` en `usage_monitor` deze twee aanroepen.
--
-- Niet misbruikbaar: beide functies stoppen met een fout als `auth.uid()` leeg is,
-- dus zonder inlog kom je niet verder dan die fout. Dit is een deur dichtzetten,
-- geen lek dichten.
--
-- Deze migratie voegt geen functie en geen recht toe; ze neemt alleen rechten
-- af. Het aantal server-functies in CLAUDE.md blijft gelijk.
--
-- Toepassen: Supabase SQL Editor (zoals 0010-0014). Daarna
-- `supabase/tests/usage_counts_test.sql` opnieuw draaien: check 3.1 moet dan
-- `0` geven.

revoke all on function public.migrate_account_data(
  real, real, real, real, int[], text, text, text, text, boolean, boolean, boolean, jsonb, jsonb
) from public, anon;
grant execute on function public.migrate_account_data(
  real, real, real, real, int[], text, text, text, text, boolean, boolean, boolean, jsonb, jsonb
) to authenticated;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
