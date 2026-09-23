-- ---------------------------------------------------------------------------
-- 0013_group_join_requests.sql — milestone v4.2 "Clubs" (fase 34)
--
-- Na de schets besloot Joost (2026-09-23, 34-CONTEXT "HERZIENING"): **ieder
-- lid draagt voor, alleen beheerders maken lid.** 0012 kende dat niet: daar
-- maakte de groepslink je direct lid, en alleen een beheerder mocht de link
-- zien en maken. Deze migratie legt het nieuwe besluit in de database vast,
-- zoals 0012 dat voor de rest deed: de app bewaakt niets.
--
-- Wat er t.o.v. 0012 verandert:
--   - nieuwe tabel `group_join_requests`: openstaande aanvragen per groep;
--   - `redeem_group_invite` maakt voortaan een aanvraag, geen lidmaatschap;
--   - nieuwe rpc's `propose_group_member` (lid draagt een maatje voor;
--     beheerder maakt hem direct lid) en `accept_group_request` (beheerder
--     accepteert); afwijzen en intrekken is een gewone delete;
--   - een aanvrager ziet de groepsrij (de naam) van de groep waar hij een open
--     aanvraag voor heeft;
--   - ieder lid ziet en maakt groepslinks; intrekken blijft beheerderswerk.
-- De insert-policy op group_members uit 0012 blijft ongewijzigd, net als de
-- triggers guard_group_member_insert en ensure_group_admin.
--
-- KEUZES
--
-- a. **Aanvragen worden alleen via security definer-functies geschreven.**
--    authenticated krijgt op group_join_requests alleen select en delete. De
--    naam van de aanvrager en die van de voordrager moeten uit de database
--    komen (keuze b uit 0012): anders kan een lid een maatje onder een
--    verzonnen naam voordragen, en accepteert een beheerder de verkeerde
--    persoon.
--
-- b. **redeem_group_invite maakt voortaan een aanvraag.** Wie al lid is krijgt
--    status 'member' terug (idempotent, zoals in 0012); wie al een open
--    aanvraag heeft krijgt 'requested'. Het returntype wordt
--    table(group_id uuid, group_name text, status text). Een returntype
--    wijzigen kan niet met `create or replace`, dus eerst `drop function`.
--
-- c. **Een aanvrager ziet de groepsrij**, niet de leden, niet de ritten, niet
--    de links. De link is de capability (keuze a uit 0012): wie hem had, kreeg
--    de naam toch al terug van redeem. Wie voorgedragen is, is een maatje van
--    een lid, en mag weten door welke groep.
--
-- d. **Ieder lid ziet en maakt groepslinks** (delen). Intrekken en vervangen
--    blijft beheerderswerk: dat is een beheerbeslissing over wie er nog
--    binnen kan komen. Omdat de link nu een aanvraag oplevert en geen
--    lidmaatschap, verliest de beheerder er geen zeggenschap mee.
--
-- e. **Een beheerder die voordraagt maakt direct lid**, in dezelfde rpc -- er
--    is geen tweede goedkeuring nodig van de persoon die zelf goedkeurt. Een
--    open aanvraag voor die persoon in die groep wordt daarbij opgeruimd.
--
-- f. **Accepteren gaat via een rpc, niet via een client-insert.** De
--    aanvrager hoeft geen maatje van de beheerder te zijn, en de insert-policy
--    op group_members uit 0012 eist juist dat. Lid worden gaat altijd via een
--    insert in group_members, zodat de 30/10-grens uit
--    guard_group_member_insert de enige echte grens blijft. De vroege
--    controles in redeem en propose zijn er voor een duidelijke melding op het
--    moment van aanvragen, niet als slot.
--
-- g. **FUNCTIETELLING.** 0013 voegt propose_group_member en
--    accept_group_request toe en vervangt redeem_group_invite. Het totaal
--    wordt dertien, niet de twaalf die 34-CONTEXT verwachtte: voordragen moet
--    de namen van aanvrager en voordrager uit de database halen, en dat kan
--    alleen een definer-functie (of een extra triggerfunctie op
--    group_join_requests, wat ook dertien geeft). Een client-insert met een
--    door de client gezette naam is precies het spoofing-gat uit keuze b van
--    0012. De dertien, in drie soorten:
--
--    rpc (door de app aangeroepen):
--      migrate_account_data, delete_own_account, friend_profiles,
--      redeem_friend_invite, create_group, redeem_group_invite,
--      propose_group_member, accept_group_request
--    security definer helpers die policies aanroepen:
--      is_ride_member, is_group_member
--    triggerfuncties:
--      set_updated_at, guard_group_member_insert, ensure_group_admin
--
--    Nog steeds geen Edge Functions en geen andere server-side code.
--
-- LOCKVOLGORDE. Overal groep -> aanvraag -> persoon: redeem en propose locken
-- eerst de groepsrij en voegen dan een aanvraag in; accept lockt de groep en
-- pas daarna de aanvraag; een beheerder die voordraagt lockt de groep via de
-- guard-trigger en verwijdert daarna de aanvraag. De advisory lock per
-- persoon uit de guard komt steeds als laatste. Zo kunnen twee beheerders die
-- tegelijk dezelfde persoon accepteren en toevoegen elkaar niet vastzetten.
--
-- Veilig opnieuw te draaien na een halve mislukking: `if not exists`,
-- `create or replace`, en een `drop ... if exists` vóór elke policy en
-- herdefinitie.
-- ---------------------------------------------------------------------------

begin;

-- ---------------------------------------------------------------------------
-- 1. Aanvragen
-- ---------------------------------------------------------------------------

-- Eén open aanvraag per persoon per groep. Een geaccepteerde aanvraag wordt
-- verwijderd (hij is dan een lidmaatschap), een afgewezen of ingetrokken ook:
-- er is geen status-kolom, een rij bestaat alleen zolang de aanvraag openstaat.
create table if not exists public.group_join_requests (
  id               uuid primary key default gen_random_uuid(),
  group_id         uuid not null references public.groups(id) on delete cascade,
  -- Cascade: verdwijnt het account, dan verdwijnt de aanvraag (CLUB-19).
  user_id          uuid not null references auth.users(id) on delete cascade,
  -- null = binnengekomen via de groepslink. Verdwijnt het account van de
  -- voordrager, dan blijft de aanvraag staan; proposed_by_name vertelt nog
  -- wie het was.
  proposed_by      uuid null references auth.users(id) on delete set null,
  -- Beide namen komen uit de database, nooit van de client (keuze a).
  display_name     text,
  proposed_by_name text,
  created_at       timestamptz not null default now(),
  constraint group_join_requests_group_user_key unique (group_id, user_id)
);

-- "Mijn aanvragen" zoekt per user_id; per group_id dekt de unique-index al.
create index if not exists group_join_requests_user_idx
  on public.group_join_requests (user_id);

comment on table public.group_join_requests is
  'Clubs (v4.2, fase 34): openstaande aanvragen om lid te worden, via de '
  'groepslink of voorgedragen door een lid. Schrijven alleen via '
  'redeem_group_invite() en propose_group_member(); accepteren via '
  'accept_group_request(); afwijzen of intrekken is een delete. Max 30 open '
  'aanvragen per groep.';

-- ---------------------------------------------------------------------------
-- 2. RLS + policies op group_join_requests
--
-- Zien en verwijderen: de aanvrager zelf (intrekken), de voordrager (zijn
-- voordracht intrekken) en elke beheerder van de groep (afwijzen). Een gewoon
-- lid ziet de aanvragen van anderen niet. Geen insert- en geen update-policy:
-- schrijven gaat uitsluitend via de definer-functies hieronder (keuze a).
--
-- is_group_member is security definer en leest group_members, niet deze
-- tabel of groups -- dus geen recursie.
-- ---------------------------------------------------------------------------

alter table public.group_join_requests enable row level security;

drop policy if exists group_join_requests_select on public.group_join_requests;
create policy group_join_requests_select on public.group_join_requests
  for select using (
    user_id = auth.uid()
    or proposed_by = auth.uid()
    or public.is_group_member(group_id, true)
  );

drop policy if exists group_join_requests_delete on public.group_join_requests;
create policy group_join_requests_delete on public.group_join_requests
  for delete using (
    user_id = auth.uid()
    or proposed_by = auth.uid()
    or public.is_group_member(group_id, true)
  );

-- ---------------------------------------------------------------------------
-- 3. Grants op group_join_requests
--
-- Eerst alles weg (zie 0006 en sectie 8 van 0012), dan alleen lezen en
-- verwijderen. anon krijgt niets. Bewust geen service_role-grant: aanvragen
-- zijn kortlevend en horen niet in de rapportage; is dat later wel nodig, dan
-- is het één regel in een eigen migratie.
-- ---------------------------------------------------------------------------

revoke all on public.group_join_requests from anon, authenticated;
grant select, delete on public.group_join_requests to authenticated;

-- ---------------------------------------------------------------------------
-- 4. groups: een aanvrager ziet de groepsrij (keuze c)
--
-- Vervangt groups_select_member uit 0012. De subquery op group_join_requests
-- loopt onder de RLS van de aanroeper; zijn eigen aanvraag valt onder
-- `user_id = auth.uid()`. Geen recursie: de policies op group_join_requests
-- raken groups niet (alleen is_group_member, die group_members leest).
-- update- en delete-policies op groups blijven beheerderswerk (0012).
-- ---------------------------------------------------------------------------

drop policy if exists groups_select_member on public.groups;
drop policy if exists groups_select_member_or_requester on public.groups;
create policy groups_select_member_or_requester on public.groups
  for select using (
    public.is_group_member(id)
    or exists (
      select 1 from public.group_join_requests r
      where r.group_id = groups.id
        and r.user_id  = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- 5. group_invites: ieder lid ziet en maakt links (keuze d)
--
-- Vervangt group_invites_select_admin en group_invites_insert_admin uit 0012.
-- group_invites_delete_admin blijft: intrekken is beheerderswerk. De
-- kolomgrants uit 0012 blijven gelden (insert alleen code, group_id,
-- created_by, expires_at; geen update).
-- ---------------------------------------------------------------------------

drop policy if exists group_invites_select_admin on public.group_invites;
drop policy if exists group_invites_select_member on public.group_invites;
create policy group_invites_select_member on public.group_invites
  for select using (public.is_group_member(group_id));

drop policy if exists group_invites_insert_admin on public.group_invites;
drop policy if exists group_invites_insert_member on public.group_invites;
create policy group_invites_insert_member on public.group_invites
  for insert with check (
    created_by = auth.uid()
    and public.is_group_member(group_id)
  );

-- ---------------------------------------------------------------------------
-- Foutmeldingen
--
-- Altijd `errcode = 'P0001'` met een vaste Engelse sleutel als message, zodat
-- de app ze kan herkennen en naar een nette NL/EN-melding kan vertalen.
-- Uit 0012:
--   not_authenticated, group_name_invalid, invite_invalid, group_full,
--   too_many_groups, last_admin
-- Nieuw in 0013:
--   not_member        -- voordragen voor een groep waar je geen lid van bent
--   not_friend        -- voordragen van iemand die geen maatje van je is
--   not_allowed       -- accepteren zonder beheerder te zijn, of van een
--                        aanvraag die niet (meer) bestaat; bewust dezelfde
--                        sleutel, zodat hij niet verklapt of een id bestaat
--   too_many_requests -- de groep heeft al 30 open aanvragen
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 6. redeem_group_invite(p_code) -- de link levert een aanvraag op (keuze b)
--
-- Security definer, want de genodigde kan de groep en de link nog niet lezen
-- (keuze a uit 0012). Rate limiting op het raden van codes hoort bij epic #75.
--
-- Volgorde van de controles: eerst de idempotente antwoorden (al lid, al
-- aangevraagd), dan de grenzen in dezelfde volgorde als de guard-trigger
-- (group_full vóór too_many_groups), dan de aanvraaggrens. De groepsrij wordt
-- gelockt vóór die controles, zodat twee aanvragen op plek 30 niet allebei
-- door de telling komen, en een lid dat net geaccepteerd wordt niet ook nog
-- een aanvraag krijgt.
--
-- `#variable_conflict use_column`: de out-kolommen group_id en status heten
-- als tabelkolommen; alle kolommen zijn daarom met een alias gekwalificeerd.
-- ---------------------------------------------------------------------------

drop function if exists public.redeem_group_invite(text);

create function public.redeem_group_invite(p_code text)
returns table (group_id uuid, group_name text, status text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_me    uuid := auth.uid();
  v_code  text := upper(btrim(p_code));
  v_group uuid;
  v_name  text;
  v_count integer;
begin
  if v_me is null then
    raise exception using errcode = 'P0001', message = 'not_authenticated';
  end if;

  select i.group_id into v_group
  from public.group_invites i
  where i.code = v_code and i.expires_at > now();

  if not found then
    raise exception using errcode = 'P0001', message = 'invite_invalid';
  end if;

  -- Lock de groep en lees meteen de naam. Is hij net opgeheven, dan cascadet
  -- de link mee en is de code ongeldig.
  select g.name into v_name
  from public.groups g
  where g.id = v_group
  for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'invite_invalid';
  end if;

  -- Al lid: niets te doen (idempotent, zoals in 0012).
  if exists (
    select 1 from public.group_members m
    where m.group_id = v_group and m.user_id = v_me
  ) then
    return query select v_group, v_name, 'member'::text;
    return;
  end if;

  -- Al een open aanvraag (via de link of voorgedragen): niets te doen.
  if exists (
    select 1 from public.group_join_requests r
    where r.group_id = v_group and r.user_id = v_me
  ) then
    return query select v_group, v_name, 'requested'::text;
    return;
  end if;

  -- Vroege grenzen, voor een duidelijke melding nu in plaats van pas bij het
  -- accepteren. Het echte slot blijft de guard-trigger (keuze f).
  select count(*) into v_count
  from public.group_members m
  where m.group_id = v_group;

  if v_count >= 30 then
    raise exception using errcode = 'P0001', message = 'group_full';
  end if;

  select count(*) into v_count
  from public.group_members m
  where m.user_id = v_me;

  if v_count >= 10 then
    raise exception using errcode = 'P0001', message = 'too_many_groups';
  end if;

  -- Max 30 open aanvragen per groep, tegen spam met een gelekte link.
  select count(*) into v_count
  from public.group_join_requests r
  where r.group_id = v_group;

  if v_count >= 30 then
    raise exception using errcode = 'P0001', message = 'too_many_requests';
  end if;

  begin
    insert into public.group_join_requests
      (group_id, user_id, proposed_by, display_name, proposed_by_name)
    values (
      v_group,
      v_me,
      null,
      (select p.user_name from public.profiles p where p.user_id = v_me),
      null
    );
  exception
    when unique_violation then
      null;  -- tegelijk al aangevraagd door hetzelfde account.
  end;

  return query select v_group, v_name, 'requested'::text;
end;
$$;

revoke all on function public.redeem_group_invite(text) from public, anon;
grant execute on function public.redeem_group_invite(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 7. propose_group_member(p_group_id, p_user_id) -- een maatje voordragen
--
-- Ieder lid mag een eigen maatje voordragen; dat wordt een aanvraag. Is de
-- aanroeper beheerder, dan wordt het maatje direct lid (keuze e). Geeft
-- 'member' of 'requested' terug.
--
-- Security definer: de namen komen uit profiles en group_members (keuze a),
-- de telling van de groepen van het maatje moet volledig zijn (de aanroeper
-- ziet die lidmaatschappen niet), en een gewoon lid kan niet in
-- group_join_requests schrijven.
-- ---------------------------------------------------------------------------

create or replace function public.propose_group_member(
  p_group_id uuid,
  p_user_id  uuid
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_me      uuid := auth.uid();
  v_my_name text;
  v_count   integer;
begin
  if v_me is null then
    raise exception using errcode = 'P0001', message = 'not_authenticated';
  end if;

  if not public.is_group_member(p_group_id) then
    raise exception using errcode = 'P0001', message = 'not_member';
  end if;

  -- Alleen een eigen maatje (friendships staat in canonieke volgorde, zie
  -- 0002; beide richtingen toetsen is dan hetzelfde als least/greatest).
  if not exists (
    select 1 from public.friendships f
    where (f.user_a = v_me and f.user_b = p_user_id)
       or (f.user_b = v_me and f.user_a = p_user_id)
  ) then
    raise exception using errcode = 'P0001', message = 'not_friend';
  end if;

  if exists (
    select 1 from public.group_members m
    where m.group_id = p_group_id and m.user_id = p_user_id
  ) then
    return 'member';
  end if;

  -- Beheerder: direct lid (keuze e). De insert loopt door de guard-trigger,
  -- die de groep lockt, de 30/10-grens bewaakt en de naam invult (keuze f).
  if public.is_group_member(p_group_id, true) then
    begin
      insert into public.group_members (group_id, user_id, role)
      values (p_group_id, p_user_id, 'member');
    exception
      when unique_violation then
        null;  -- tegelijk al toegevoegd of geaccepteerd: hij is lid.
    end;

    delete from public.group_join_requests r
    where r.group_id = p_group_id and r.user_id = p_user_id;

    return 'member';
  end if;

  -- Gewoon lid: een aanvraag.
  if exists (
    select 1 from public.group_join_requests r
    where r.group_id = p_group_id and r.user_id = p_user_id
  ) then
    return 'requested';
  end if;

  perform 1 from public.groups g where g.id = p_group_id for update;

  select count(*) into v_count
  from public.group_members m
  where m.group_id = p_group_id;

  if v_count >= 30 then
    raise exception using errcode = 'P0001', message = 'group_full';
  end if;

  select count(*) into v_count
  from public.group_members m
  where m.user_id = p_user_id;

  if v_count >= 10 then
    raise exception using errcode = 'P0001', message = 'too_many_groups';
  end if;

  select count(*) into v_count
  from public.group_join_requests r
  where r.group_id = p_group_id;

  if v_count >= 30 then
    raise exception using errcode = 'P0001', message = 'too_many_requests';
  end if;

  select m.display_name into v_my_name
  from public.group_members m
  where m.group_id = p_group_id and m.user_id = v_me;

  begin
    insert into public.group_join_requests
      (group_id, user_id, proposed_by, display_name, proposed_by_name)
    values (
      p_group_id,
      p_user_id,
      v_me,
      (select p.user_name from public.profiles p where p.user_id = p_user_id),
      v_my_name
    );
  exception
    when unique_violation then
      null;  -- tegelijk al aangevraagd of voorgedragen: er ligt een aanvraag.
  end;

  return 'requested';
end;
$$;

revoke all on function public.propose_group_member(uuid, uuid) from public, anon;
grant execute on function public.propose_group_member(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 8. accept_group_request(p_request_id) -- beheerder maakt lid (keuze f)
--
-- Alleen een beheerder van de groep van de aanvraag. Bestaat de aanvraag niet
-- of is de aanroeper geen beheerder, dan in beide gevallen not_allowed.
--
-- Eerst de groep locken, dan de aanvraag opnieuw lezen met `for update`
-- (lockvolgorde uit de kop). Is hij in de tussentijd ingetrokken, afgewezen
-- of door een andere beheerder geaccepteerd, dan ook not_allowed: de app
-- ververst de lijst.
--
-- Gooit de guard-trigger group_full of too_many_groups, dan rolt de hele
-- aanroep terug en blijft de aanvraag staan: de beheerder kan hem afwijzen of
-- het later opnieuw proberen.
-- ---------------------------------------------------------------------------

create or replace function public.accept_group_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_me    uuid := auth.uid();
  v_group uuid;
  v_user  uuid;
begin
  if v_me is null then
    raise exception using errcode = 'P0001', message = 'not_authenticated';
  end if;

  select r.group_id into v_group
  from public.group_join_requests r
  where r.id = p_request_id;

  if not found or not public.is_group_member(v_group, true) then
    raise exception using errcode = 'P0001', message = 'not_allowed';
  end if;

  perform 1 from public.groups g where g.id = v_group for update;

  select r.user_id into v_user
  from public.group_join_requests r
  where r.id = p_request_id and r.group_id = v_group
  for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'not_allowed';
  end if;

  -- Al lid (bijv. intussen door een beheerder toegevoegd): alleen opruimen.
  if not exists (
    select 1 from public.group_members m
    where m.group_id = v_group and m.user_id = v_user
  ) then
    insert into public.group_members (group_id, user_id, role)
    values (v_group, v_user, 'member');
  end if;

  delete from public.group_join_requests r
  where r.id = p_request_id;
end;
$$;

revoke all on function public.accept_group_request(uuid) from public, anon;
grant execute on function public.accept_group_request(uuid) to authenticated;

commit;

-- ---------------------------------------------------------------------------
-- Controle
-- ---------------------------------------------------------------------------
-- select tablename, rowsecurity from pg_tables
--  where schemaname = 'public' and tablename = 'group_join_requests';
--
-- Verwacht: één rij, rowsecurity = true.
--
-- select tablename, policyname, cmd from pg_policies
--  where schemaname = 'public'
--    and tablename in ('groups', 'group_members', 'group_invites',
--                      'group_join_requests')
--  order by tablename, policyname;
--
-- Verwacht: groups 3 (select_member_or_requester, update_admin,
-- delete_admin), group_members 4 (ongewijzigd uit 0012), group_invites 3
-- (select_member, insert_member, delete_admin), group_join_requests 2
-- (select, delete).
--
-- select table_name, grantee, privilege_type
--   from information_schema.role_table_grants
--  where table_schema = 'public'
--    and table_name = 'group_join_requests'
--  order by grantee, privilege_type;
--
-- Verwacht: authenticated alleen SELECT en DELETE; anon niets; geen
-- service_role (bewust, zie sectie 3).
--
-- select proname, pg_get_function_result(oid) from pg_proc
--  where pronamespace = 'public'::regnamespace
--    and proname in ('migrate_account_data', 'delete_own_account',
--                    'friend_profiles', 'redeem_friend_invite', 'create_group',
--                    'redeem_group_invite', 'propose_group_member',
--                    'accept_group_request', 'is_ride_member',
--                    'is_group_member', 'set_updated_at',
--                    'guard_group_member_insert', 'ensure_group_admin')
--  order by proname;
--
-- Verwacht: 13 rijen -- de telling uit de kop (keuze g). redeem_group_invite
-- geeft TABLE(group_id uuid, group_name text, status text).
--
-- Deze queries bewijzen alleen dat alles bestaat. Het echte bewijs dat een
-- gewoon lid niemand lid kan maken en een buitenstaander geen aanvragen ziet,
-- is supabase/tests/clubs_requests_deny_test.sql, samen met de bijgewerkte
-- supabase/tests/clubs_deny_test.sql (plan 34-02).
-- ---------------------------------------------------------------------------
