-- 0003_peloton_policy_repair.sql
--
-- Waarom dit bestand bestaat
-- --------------------------
-- Op 2026-09-06 faalde het uitnodigen van een maatje voor een gedeelde rit op:
--
--   PostgrestException(message: new row violates row-level security policy
--   for table "group_rides", code: 42501)
--
-- Postgres geeft die fout in twee gevallen: de WITH CHECK van de insertpolicy
-- is onwaar, óf er geldt helemaal geen insertpolicy voor deze rol. Het eerste
-- kan hier niet: de app schrijft `owner_id` letterlijk uit
-- `auth.currentSession.user.id`, dezelfde claim die `auth.uid()` teruggeeft, en
-- in dezelfde sessie slaagden `friend_profiles()` en `redeem_friend_invite()`
-- gewoon. Blijft over: de policies uit `0002_peloton.sql` staan niet (volledig)
-- op de live database, terwijl RLS er wél aan staat. Dat verklaart ook waarom
-- alles wat via SECURITY DEFINER loopt werkte en alles wat op een policy leunt
-- niet -- die functies slaan RLS over.
--
-- Dit script maakt de policies van `group_rides` en `group_ride_participants`
-- opnieuw aan, letterlijk zoals ze in 0002 staan. `drop policy if exists` maakt
-- het herhaalbaar: draaien terwijl ze al goed staan is een no-op met hetzelfde
-- eindresultaat. Het raakt geen data, alleen policies.
--
-- Draai vóór en ná dit script de controlequery onderaan, en bewaar de uitkomst
-- -- pas dan weten we of de diagnose klopte in plaats van dat we het vermoeden.

begin;

-- group_rides: eigenaar of deelnemer leest; alleen de eigenaar schrijft.
drop policy if exists group_rides_select_member on public.group_rides;
create policy group_rides_select_member on public.group_rides
  for select using (public.is_ride_member(id));

drop policy if exists group_rides_insert_own on public.group_rides;
create policy group_rides_insert_own on public.group_rides
  for insert with check (owner_id = auth.uid());

drop policy if exists group_rides_update_own on public.group_rides;
create policy group_rides_update_own on public.group_rides
  for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists group_rides_delete_own on public.group_rides;
create policy group_rides_delete_own on public.group_rides
  for delete using (owner_id = auth.uid());

-- participants: iedereen die bij de rit hoort ziet de hele deelnemerslijst.
drop policy if exists group_ride_participants_select_member
  on public.group_ride_participants;
create policy group_ride_participants_select_member
  on public.group_ride_participants
  for select using (public.is_ride_member(ride_id));

-- Uitnodigen mag alleen de eigenaar, en alleen voor een maatje.
drop policy if exists group_ride_participants_insert_owner
  on public.group_ride_participants;
create policy group_ride_participants_insert_owner
  on public.group_ride_participants
  for insert with check (
    exists (
      select 1 from public.group_rides r
      where r.id = ride_id and r.owner_id = auth.uid()
    )
    and exists (
      select 1 from public.friendships f
      where (f.user_a = auth.uid() and f.user_b = group_ride_participants.user_id)
         or (f.user_b = auth.uid() and f.user_a = group_ride_participants.user_id)
    )
  );

-- Je antwoordt alleen namens jezelf.
drop policy if exists group_ride_participants_update_own
  on public.group_ride_participants;
create policy group_ride_participants_update_own
  on public.group_ride_participants
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Afmelden mag jezelf; de eigenaar mag iemand van zijn rit halen.
drop policy if exists group_ride_participants_delete
  on public.group_ride_participants;
create policy group_ride_participants_delete on public.group_ride_participants
  for delete using (
    user_id = auth.uid()
    or exists (
      select 1 from public.group_rides r
      where r.id = ride_id and r.owner_id = auth.uid()
    )
  );

-- RLS en grants zijn in 0002 al gezet; hier alleen herbevestigd omdat een
-- policy zonder grant nog steeds niets doet, en andersom.
alter table public.group_rides             enable row level security;
alter table public.group_ride_participants enable row level security;

grant select, insert, update, delete on public.group_rides             to authenticated;
grant select, insert, update, delete on public.group_ride_participants to authenticated;

commit;

-- ---------------------------------------------------------------------------
-- Controlequery -- draai deze apart, vóór en na
-- ---------------------------------------------------------------------------
-- select tablename, policyname, cmd, roles, qual, with_check
--   from pg_policies
--  where schemaname = 'public'
--    and tablename in ('group_rides', 'group_ride_participants')
--  order by tablename, policyname;
--
-- Verwacht ná dit script: vier regels voor group_rides (select/insert/update/
-- delete) en vier voor group_ride_participants. Stonden ze er vóóraf al
-- allemaal, dan was de diagnose fout en moet de zoektocht verder -- noteer dat
-- dan in .planning/PELOTON.md in plaats van dit script nog eens te draaien.
