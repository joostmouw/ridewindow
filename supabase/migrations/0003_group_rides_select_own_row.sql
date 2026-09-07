-- 0003_group_rides_select_own_row.sql
--
-- Het uitnodigen van een maatje faalde op:
--
--   PostgrestException(message: new row violates row-level security policy
--   for table "group_rides", code: 42501)
--
-- Wat er werkelijk aan de hand is
-- -------------------------------
-- `createGroupRide` in `peloton_gateway.dart` doet
-- `.insert({...}).select().single()`. Dat is `INSERT ... RETURNING`, en bij
-- RETURNING past Postgres naast de WITH CHECK van de insertpolicy óók de
-- SELECT-policy toe op de zojuist ingevoegde rij.
--
-- Die SELECT-policy was `public.is_ride_member(id)`. Die functie is `stable`
-- en zoekt de rit op in `group_rides` zelf. Een `stable` functie werkt met de
-- snapshot van het begin van de statement, en daarin bestaat de rij die déze
-- statement invoegt nog niet. De functie geeft dus `false` terug voor de rij
-- die net is aangemaakt, en de policy weigert hem.
--
-- De insert zelf was nooit het probleem: `owner_id = auth.uid()` slaagt. Het is
-- het teruglezen dat faalde -- wat verklaart waarom álles wat via SECURITY
-- DEFINER loopt (`friend_profiles`, `redeem_friend_invite`) gewoon werkte, en
-- waarom alle acht policies wel degelijk aanwezig waren (gecontroleerd tegen
-- pg_policies op 2026-09-07). De eerste diagnose -- "de policies ontbreken" --
-- was fout en is verworpen.
--
-- De oplossing
-- ------------
-- Zet er een tak vóór die de rij zelf leest in plaats van hem op te zoeken.
-- `owner_id = auth.uid()` wordt geëvalueerd op de kolom van de rij die
-- voorligt, zonder snapshot en zonder tabellookup, en is voor precies het
-- RETURNING-geval (jij maakt je eigen rit aan) meteen waar. De helper blijft
-- staan voor deelnemers, want die rijen bestaan al lang en met hun eigen
-- transactie -- daar is de snapshot geen probleem, en de helper blijft nodig
-- om de policy-recursie tussen `group_rides` en `group_ride_participants` te
-- breken.
--
-- `group_ride_participants` heeft dit probleem niet: `inviteToRide` doet een
-- kale `.insert(...)` zonder `.select()`, dus zonder RETURNING, dus zonder dat
-- de SELECT-policy eraan te pas komt.

begin;

drop policy if exists group_rides_select_member on public.group_rides;

create policy group_rides_select_member on public.group_rides
  for select using (
    -- Eerst de goedkope, snapshot-vrije tak. Deze moet vóór de helper staan:
    -- hij is niet alleen sneller, hij is de enige die werkt op een rij die in
    -- dezelfde statement wordt aangemaakt.
    owner_id = auth.uid()
    or public.is_ride_member(id)
  );

commit;

-- ---------------------------------------------------------------------------
-- Controle achteraf
-- ---------------------------------------------------------------------------
-- select policyname, cmd, qual
--   from pg_policies
--  where schemaname = 'public'
--    and tablename  = 'group_rides'
--    and policyname = 'group_rides_select_member';
--
-- `qual` hoort nu met (owner_id = auth.uid()) te beginnen. Het echte bewijs is
-- niet deze query maar de app: uitnodigen vanaf een geplande rit moet slagen.
