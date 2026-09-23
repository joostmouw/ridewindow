-- ---------------------------------------------------------------------------
-- 0012_groups.sql — milestone v4.2 "Clubs" (fase 33)
--
-- 0002 opende de database voor precies twee relaties: je bent elkaars maatje,
-- of je bent deelnemer aan dezelfde rit. Clubs voegt er een derde aan toe:
-- **je bent lid van dezelfde groep**. Een groep is een vaste ploeg (de
-- zaterdagclub, de collega's) met een naam, leden en per lid een rol. Leden
-- zien elkaar en elkaars groepsritten; een buitenstaander ziet niets -- geen
-- groep, geen ledenlijst, geen groepsrit, geen link.
--
-- Dit ene bestand draagt het hele datamodel én de hele rechtenlaag, zodat de
-- UI-fases (34, 35) geen migratie meer nodig hebben en de app niets zelf hoeft
-- te bewaken. Wat hier niet in de database staat, is niet afgedwongen.
--
-- KEUZES DIE DE REST BEPALEN
--
-- a. **De groepslink volgt keuze 1 uit 0002.** De code in de link is de
--    capability: wie hem heeft komt binnen via `redeem_group_invite`, wie hem
--    niet heeft ziet niet eens dat de groep bestaat. Codes hebben dezelfde bron
--    en lengte als de maatjescode (8 tekens uit 29), en de database weigert
--    alles wat korter of zwakker is.
--
-- b. **Namen staan gedenormaliseerd op `group_members.display_name`**, net als
--    `group_rides.owner_name` en `group_ride_participants.display_name`.
--    `profiles` blijft dicht (keuze 2 uit 0002): een lid ziet de naam van een
--    ander lid, niet diens tolerantie-instellingen of locatie. De naam wordt
--    door de database ingevuld, niet door de client -- anders kan een beheerder
--    een maatje onder een verzonnen naam toevoegen.
--
-- c. **`is_group_member()` breekt de policy-recursie op `group_members`.** Een
--    select-policy op `group_members` die zelf `group_members` bevraagt geeft
--    "infinite recursion detected in policy" -- dezelfde reden als keuze 4 in
--    0002. De security definer helper omzeilt RLS en breekt zo de lus.
--
-- d. **Aanmaken loopt via de rpc `create_group`, niet via een after-insert-
--    trigger op `groups`.** Met een trigger zou de app `.insert().select()` op
--    `groups` doen, en dat is `INSERT ... RETURNING` -- precies de valkuil uit
--    0003 (zie ook .planning/PELOTON.md): bij RETURNING geldt de select-policy
--    op de zojuist ingevoegde rij, en een `stable` helper ziet het lidmaatschap
--    uit dezelfde statement niet. De uitweg uit 0003 (een `created_by =
--    auth.uid()`-tak vóór de helper) werkt hier niet: dan blijft een maker die
--    de groep verliet de groep eeuwig zien. De rpc geeft alleen het id terug en
--    doet groep + eerste lidmaatschap atomisch in één aanroep.
--
-- e. **De enige beheerder die zichzelf wil degraderen wordt geweigerd
--    (`last_admin`)**, in plaats van dat opvolging het oplost. Opvolging kiest
--    het langst zittende lid -- vaak dezelfde persoon, want de maker zit er het
--    langst -- en zou de degradatie dan stil ongedaan maken. Weigeren geeft de
--    app een duidelijke melding: "maak eerst iemand anders beheerder".
--    Opvolging geldt wél bij vertrek, verwijdering door een beheerder en het
--    verdwijnen van een account (cascade): daar is er niemand meer om het te
--    vragen, en een groep zonder beheerder is niet meer te beheren (CLUB-10).
--
-- f. **Een groepsrit heeft geen momentopname van leden.** Zichtbaarheid volgt
--    het huidige lidmaatschap: wie nu lid is ziet de rit, wie vertrok niet meer
--    (tenzij hij de eigenaar is). Een ex-lid met een oude participant-rij ziet
--    de rit dus ook níét meer -- die rij blijft bestaan maar geeft op een
--    groepsrit geen toegang. Wordt de groep opgeheven (`group_id` -> null), dan
--    is het weer een gewone gedeelde rit en telt de participant-rij weer
--    (CLUB-11, CLUB-13).
--
-- g. **FUNCTIETELLING (CLUB-20).** Na deze migratie staan er elf server-
--    functies, in drie soorten:
--
--    rpc (door de app aangeroepen):
--      migrate_account_data, delete_own_account, friend_profiles,
--      redeem_friend_invite, create_group, redeem_group_invite
--    security definer helpers die policies aanroepen:
--      is_ride_member, is_group_member
--    triggerfuncties:
--      set_updated_at, guard_group_member_insert, ensure_group_admin
--
--    De vijf nieuwe, elk met wat de client aantoonbaar niet kan:
--    - `create_group`: groep + eerste beheerder in één transactie, zonder op
--      de insert-returning-valkuil te lopen (keuze d); twee losse client-
--      inserts kunnen een groep zonder beheerder achterlaten.
--    - `redeem_group_invite`: de genodigde kan de groep en de link nog niet
--      lezen, dus alleen een definer-functie kan de code controleren en hem
--      binnenlaten (keuze a).
--    - `is_group_member`: zonder helper is een ledenpolicy op `group_members`
--      oneindig recursief (keuze c).
--    - `guard_group_member_insert`: de grenzen van 30 leden en 10 groepen
--      (CLUB-18) moeten race-vrij in de database; de client ziet de andere
--      lidmaatschappen van een maatje niet eens, dus kan niet tellen.
--    - `ensure_group_admin`: opvolging en het opruimen van een lege groep
--      (CLUB-10, CLUB-19) moeten ook gebeuren als het account weg is -- dan is
--      er geen client meer die iets kan doen.
--
--    CLUB-20 verwachtte er "acht" (zes + redeem_group_invite + is_group_member).
--    Het worden er elf, omdat de telling het schema volgt en niet de roadmap:
--    grenzen en opvolging moeten in de database (CLUB-10/18) en dat kan alleen
--    met triggers, en atomisch aanmaken vraagt `create_group`.
--    `is_ride_member` wordt vervangen, niet toegevoegd. `delete_own_account`
--    blijft ongewijzigd: de FK-cascade op `group_members.user_id` plus de
--    after-delete-trigger doen het werk. Nog steeds geen Edge Functions en
--    geen andere server-side code.
--
-- Veilig opnieuw te draaien na een halve mislukking: `if not exists`,
-- `create or replace`, en een `drop ... if exists` vóór elke policy en trigger.
-- ---------------------------------------------------------------------------

begin;

-- ---------------------------------------------------------------------------
-- 1. Groepen
-- ---------------------------------------------------------------------------

-- `created_by` is alleen geschiedenis, geen recht: rechten lopen via
-- `group_members.role`. Daarom `on delete set null` -- een maker die zijn
-- account verwijdert mag de groep niet meenemen (CLUB-19).
create table if not exists public.groups (
  id         uuid primary key default gen_random_uuid(),
  name       text not null
               check (char_length(btrim(name)) between 1 and 60),
  created_by uuid null references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.groups is
  'Clubs (v4.2): een vaste ploeg met een naam. Rechten lopen via '
  'group_members.role, niet via created_by. Aanmaken alleen via create_group().';

-- Hergebruikt de triggerfunctie uit 0001. Dezelfde kanttekening als bij
-- group_rides in 0002 (backlog #57): elke schrijving telt als wijziging.
drop trigger if exists groups_set_updated_at on public.groups;
create trigger groups_set_updated_at
  before update on public.groups
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 2. Lidmaatschap
-- ---------------------------------------------------------------------------

create table if not exists public.group_members (
  group_id     uuid not null references public.groups(id) on delete cascade,
  -- Cascade: verdwijnt het account, dan verdwijnt het lidmaatschap, en de
  -- after-delete-trigger uit sectie 10 regelt opvolging (CLUB-19).
  user_id      uuid not null references auth.users(id) on delete cascade,
  -- Tekst met check, geen enum: zelfde reden als `status` in 0002 -- een
  -- nieuwe rol toevoegen is dan een check wijzigen, geen enum-migratie.
  role         text not null default 'member'
                 check (role in ('admin', 'member')),
  -- Ingevuld door de guard-trigger uit profiles.user_name (keuze b).
  display_name text,
  -- Opvolging draait op deze kolom; hij komt dus nooit van de client (zie de
  -- kolomgrants in sectie 8 en de guard-trigger in sectie 9).
  joined_at    timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- "In welke groepen zit ik" en de 10-grens tellen per user_id.
create index if not exists group_members_user_idx
  on public.group_members (user_id);

comment on table public.group_members is
  'Clubs (v4.2): wie lid is van welke groep, met rol admin/member. Max 30 '
  'leden per groep en 10 groepen per account (CLUB-18), altijd minstens een '
  'admin (CLUB-10) -- beide afgedwongen door triggers.';

-- ---------------------------------------------------------------------------
-- 3. Groepslinks
-- ---------------------------------------------------------------------------

-- Naar het model van friend_invites, met twee verschillen. De code heeft een
-- check: dezelfde 8 tekens uit het alfabet van invite_code.dart
-- (ABCDEFGHJKMNPQRSTWXYZ23456789), zodat er geen kortere of zwakkere code
-- dan de maatjescode kan bestaan. En `created_by` is `set null`: een link hoort
-- bij de groep, niet bij de persoon, en blijft werken als de beheerder die hem
-- maakte vertrekt. Intrekken is de link verwijderen.
create table if not exists public.group_invites (
  code       text primary key
               check (code ~ '^[A-HJKMNP-TW-Z2-9]{8}$'),
  group_id   uuid not null references public.groups(id) on delete cascade,
  created_by uuid null references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  check (expires_at > created_at)
);

create index if not exists group_invites_group_idx
  on public.group_invites (group_id);

comment on table public.group_invites is
  'Clubs (v4.2): deellinks naar een groep. De code is de capability; alleen '
  'beheerders zien, maken en trekken ze in. Inwisselen via redeem_group_invite().';

-- ---------------------------------------------------------------------------
-- 4. Groepsritten
-- ---------------------------------------------------------------------------

-- Een rit met group_id hoort bij de groep: elk huidig lid ziet hem (keuze f).
-- `on delete set null`: heft een beheerder de groep op, dan blijft de rit
-- bestaan als gewone gedeelde rit voor de eigenaar en wie al een
-- participant-rij heeft (CLUB-11).
alter table public.group_rides
  add column if not exists group_id uuid
    references public.groups(id) on delete set null;

create index if not exists group_rides_group_idx
  on public.group_rides (group_id);

-- ---------------------------------------------------------------------------
-- 5. is_group_member() -- breekt de recursie op group_members (keuze c)
--
-- Waar als de aanroeper lid is van de groep; met p_admin_only alleen als hij
-- daar beheerder is. `stable` en dus met de snapshot van het begin van de
-- statement -- zie keuze d voor waarom dat bij RETURNING telt.
-- ---------------------------------------------------------------------------

create or replace function public.is_group_member(
  p_group_id   uuid,
  p_admin_only boolean default false
)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.group_members m
    where m.group_id = p_group_id
      and m.user_id  = auth.uid()
      and (not p_admin_only or m.role = 'admin')
  );
$$;

revoke all on function public.is_group_member(uuid, boolean) from public, anon;
grant execute on function public.is_group_member(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. is_ride_member() -- vervangen, niet toegevoegd
--
-- Zelfde signatuur en attributen als in 0002, dus elke policy die hem al
-- gebruikt (group_rides en group_ride_participants uit 0002/0003, opties en
-- stemmen uit 0010) erft de groepsregel automatisch. Drie takken:
--
--   - eigenaar: ziet zijn rit altijd, ook als hij de groep verliet;
--   - gewone gedeelde rit (group_id is null): een participant-rij geeft
--     toegang, zoals in 0002;
--   - groepsrit (group_id is not null): alleen huidig lidmaatschap geeft
--     toegang. Een participant-rij geeft hier BEWUST GEEN toegang: een ex-lid
--     met een oude rij ziet de rit niet meer (keuze f, CLUB-13). Na opheffen
--     is group_id null en telt die rij weer.
-- ---------------------------------------------------------------------------

create or replace function public.is_ride_member(p_ride_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.group_rides r
    where r.id = p_ride_id
      and (
        r.owner_id = auth.uid()
        or (
          r.group_id is null
          and exists (
            select 1 from public.group_ride_participants p
            where p.ride_id = r.id and p.user_id = auth.uid()
          )
        )
        or (
          r.group_id is not null
          and exists (
            select 1 from public.group_members m
            where m.group_id = r.group_id and m.user_id = auth.uid()
          )
        )
      )
  );
$$;

revoke all on function public.is_ride_member(uuid) from public, anon;
grant execute on function public.is_ride_member(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 7. RLS + policies
-- ---------------------------------------------------------------------------

alter table public.groups        enable row level security;
alter table public.group_members enable row level security;
alter table public.group_invites enable row level security;

-- groups: leden lezen; beheerders hernoemen en heffen op. Geen insert-policy:
-- aanmaken loopt uitsluitend via create_group() (keuze d).
drop policy if exists groups_select_member on public.groups;
create policy groups_select_member on public.groups
  for select using (public.is_group_member(id));

drop policy if exists groups_update_admin on public.groups;
create policy groups_update_admin on public.groups
  for update
  using (public.is_group_member(id, true))
  with check (public.is_group_member(id, true));

drop policy if exists groups_delete_admin on public.groups;
create policy groups_delete_admin on public.groups
  for delete using (public.is_group_member(id, true));

-- group_members: ieder lid ziet de hele ledenlijst, met naam en rol.
drop policy if exists group_members_select_member on public.group_members;
create policy group_members_select_member on public.group_members
  for select using (public.is_group_member(group_id));

-- Een beheerder voegt een bestaand maatje toe, als gewoon lid. De friendships-
-- voorwaarde is dezelfde vorm als group_ride_participants_insert_owner in
-- 0002: zonder die voorwaarde kan een beheerder wildvreemden in zijn groep
-- hangen. De andere weg naar binnen is de groepslink (redeem_group_invite).
drop policy if exists group_members_insert_admin_friend on public.group_members;
create policy group_members_insert_admin_friend on public.group_members
  for insert with check (
    public.is_group_member(group_id, true)
    and role = 'member'
    and exists (
      select 1 from public.friendships f
      where (f.user_a = auth.uid() and f.user_b = group_members.user_id)
         or (f.user_b = auth.uid() and f.user_a = group_members.user_id)
    )
  );

-- Rollen wijzigen: alleen beheerders. De laatste beheerder kan zichzelf niet
-- degraderen -- dat weigert de trigger uit sectie 10 (keuze e).
drop policy if exists group_members_update_admin on public.group_members;
create policy group_members_update_admin on public.group_members
  for update
  using (public.is_group_member(group_id, true))
  with check (public.is_group_member(group_id, true));

-- Verlaten mag iedereen (zichzelf); een beheerder mag een ander verwijderen.
drop policy if exists group_members_delete_self_or_admin on public.group_members;
create policy group_members_delete_self_or_admin on public.group_members
  for delete using (
    user_id = auth.uid()
    or public.is_group_member(group_id, true)
  );

-- group_invites: alleen beheerders zien, maken en trekken links in. Een gewoon
-- lid deelt de groep dus niet zelf door -- dat is Joosts besluit (CONTEXT:
-- Lidmaatschap), en het houdt de beheerder baas over wie er binnenkomt.
drop policy if exists group_invites_select_admin on public.group_invites;
create policy group_invites_select_admin on public.group_invites
  for select using (public.is_group_member(group_id, true));

drop policy if exists group_invites_insert_admin on public.group_invites;
create policy group_invites_insert_admin on public.group_invites
  for insert with check (
    created_by = auth.uid()
    and public.is_group_member(group_id, true)
  );

drop policy if exists group_invites_delete_admin on public.group_invites;
create policy group_invites_delete_admin on public.group_invites
  for delete using (public.is_group_member(group_id, true));

-- group_rides: insert en update krijgen de groepsvoorwaarde erbij. Zonder die
-- with check kan een eigenaar zijn rit aan een vreemde groep hangen en zo in
-- de lijst van wildvreemden verschijnen. Gevolg, bewust: een eigenaar die de
-- groep verliet kan zijn rit nog lezen en verwijderen, en alleen wijzigen als
-- hij group_id op null zet. group_rides_select_member uit 0003 blijft
-- ongemoeid: de owner-tak staat daar al vóór de helper.
drop policy if exists group_rides_insert_own on public.group_rides;
create policy group_rides_insert_own on public.group_rides
  for insert with check (
    owner_id = auth.uid()
    and (group_id is null or public.is_group_member(group_id))
  );

drop policy if exists group_rides_update_own on public.group_rides;
create policy group_rides_update_own on public.group_rides
  for update
  using (owner_id = auth.uid())
  with check (
    owner_id = auth.uid()
    and (group_id is null or public.is_group_member(group_id))
  );

-- group_ride_participants: op een groepsrit krijgt een lid pas een rij als hij
-- antwoordt, en die rij zet hij zelf. Alleen voor zichzelf, alleen op een rit
-- van een groep waar hij nu lid is. De bestaande _insert_owner (eigenaar
-- nodigt maatje uit) blijft ongewijzigd.
drop policy if exists group_ride_participants_insert_self_group
  on public.group_ride_participants;
create policy group_ride_participants_insert_self_group
  on public.group_ride_participants
  for insert with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.group_rides r
      where r.id = ride_id
        and r.group_id is not null
        and public.is_group_member(r.group_id)
    )
  );

-- ---------------------------------------------------------------------------
-- 8. Grants
--
-- Postgres controleert tabelrechten VOOR RLS -- zonder deze regels faalt alles,
-- ook met correcte policies (de les uit 0001). Hier zijn kolomrechten bovendien
-- een tweede slot naast de policies en triggers: een client kan joined_at
-- (waar opvolging op draait), role bij insert en display_name niet zelf zetten,
-- en group_id van een lidmaatschap niet verhangen.
--
-- Eerst alles weg: Supabase's standaardrechten op `public` geven een nieuwe
-- tabel meer dan we willen (zie 0006). `anon` krijgt niets -- Clubs vraagt een
-- account.
-- ---------------------------------------------------------------------------

revoke all on public.groups        from anon, authenticated;
revoke all on public.group_members from anon, authenticated;
revoke all on public.group_invites from anon, authenticated;

-- groups: geen insert (create_group), alleen de naam is te wijzigen.
grant select, delete   on public.groups to authenticated;
grant update (name)    on public.groups to authenticated;

-- group_members: insert alleen (group_id, user_id), update alleen de rol.
grant select, delete            on public.group_members to authenticated;
grant insert (group_id, user_id) on public.group_members to authenticated;
grant update (role)             on public.group_members to authenticated;

-- group_invites: geen update -- een link wijzig je niet, je trekt hem in en
-- maakt een nieuwe.
grant select, delete on public.group_invites to authenticated;
grant insert (code, group_id, created_by, expires_at)
  on public.group_invites to authenticated;

-- service_role: lezen voor de rapportage (zelfde gat als 0009/0011 -- een
-- nieuwe tabel geeft service_role geen select vanzelf). Niet op group_invites:
-- codes zijn capabilities en horen in geen rapport.
grant select on public.groups        to service_role;
grant select on public.group_members to service_role;

-- ---------------------------------------------------------------------------
-- Foutmeldingen in de functies hieronder
--
-- Altijd `errcode = 'P0001'` met een vaste Engelse sleutel als message, zodat
-- fase 34 ze kan herkennen en naar een nette NL/EN-melding kan vertalen:
--   not_authenticated, group_name_invalid, invite_invalid, group_full,
--   too_many_groups, last_admin
--
-- Triggerfuncties krijgen geen execute-grant: Postgres controleert EXECUTE bij
-- het aanmaken van de trigger (door de eigenaar van deze migratie), niet bij
-- het afgaan. Een client die ze direct aanroept krijgt dus niets.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 9. guard_group_member_insert() -- grenzen (CLUB-18), naam en joined_at
--
-- Vuurt voor elk nieuw lidmaatschap, langs welke weg dan ook: create_group,
-- redeem_group_invite of een beheerder die een maatje toevoegt.
--
-- Security definer, om twee redenen. De aanroeper -- bijvoorbeeld een beheerder
-- die een maatje toevoegt -- ziet de andere lidmaatschappen van dat maatje niet
-- (RLS), dus zonder definer valt de 10-telling te laag uit en is de grens een
-- zeef. En de naam komt uit `profiles`, die voor iedereen dicht is (keuze b).
--
-- Race: twee mensen die tegelijk op plek 30 binnenkomen zien allebei 29 leden.
-- De rijlock op de groep serialiseert ze; de tweede telt pas als de eerste
-- klaar is, en ziet dan 30. Hetzelfde gat bestaat per persoon over groepen
-- heen (twee joins van één account in twee groepen tegelijk op plek 10) --
-- daar is geen gedeelde rij om te locken, dus een advisory lock per user_id.
-- Beide locks gelden tot het einde van de transactie. De volgorde is altijd
-- groep -> persoon, dus twee joins kunnen elkaar niet in een deadlock houden.
-- ---------------------------------------------------------------------------

create or replace function public.guard_group_member_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count integer;
begin
  -- (1) Serialiseer joins op dezelfde groep.
  perform 1 from public.groups g where g.id = new.group_id for update;

  -- (2) Serialiseer joins van dezelfde persoon, over groepen heen.
  perform pg_advisory_xact_lock(hashtext(new.user_id::text));

  -- (3) Max 30 leden per groep (CLUB-18).
  select count(*) into v_count
  from public.group_members m
  where m.group_id = new.group_id;

  if v_count >= 30 then
    raise exception using errcode = 'P0001', message = 'group_full';
  end if;

  -- (4) Max 10 groepen per account -- lidmaatschappen, niet alleen gemaakte
  -- groepen (CLUB-18).
  select count(*) into v_count
  from public.group_members m
  where m.user_id = new.user_id;

  if v_count >= 10 then
    raise exception using errcode = 'P0001', message = 'too_many_groups';
  end if;

  -- (5) De naam komt uit het profiel, niet van de client (keuze b). Kan null
  -- zijn als iemand nog geen naam heeft ingevuld; de app toont dan een
  -- terugvaltekst.
  new.display_name := (
    select p.user_name from public.profiles p where p.user_id = new.user_id
  );

  -- (6) Opvolging draait op joined_at, dus die mag nooit van de client komen.
  -- Dubbel slot naast de kolomgrant uit sectie 8.
  new.joined_at := now();

  return new;
end;
$$;

revoke all on function public.guard_group_member_insert() from public, anon, authenticated;

drop trigger if exists group_members_guard_insert on public.group_members;
create trigger group_members_guard_insert
  before insert on public.group_members
  for each row execute function public.guard_group_member_insert();

-- ---------------------------------------------------------------------------
-- 10. ensure_group_admin() -- altijd een beheerder, lege groep weg (CLUB-10)
--
-- Dekt alle manieren waarop een groep een beheerder of een lid kwijtraakt:
-- verlaten, verwijderd worden door een beheerder, en het account dat
-- verdwijnt. Dat laatste is CLUB-19: `delete_own_account` verwijdert de rij in
-- auth.users, de FK-cascade op group_members.user_id verwijdert het
-- lidmaatschap, en een after-delete-trigger vuurt in Postgres ook voor rijen
-- die door een cascade verdwijnen -- per rij.
--
-- Security definer, want wie vertrekt heeft geen recht een ander te
-- promoveren, en na een account-cascade is er niemand meer die dat recht heeft.
--
-- De rijlock op de groep voorkomt dat twee beheerders die tegelijk vertrekken
-- (of elkaar tegelijk degraderen) elk de ander nog als beheerder zien.
--
-- De promotie hieronder is zelf een update van role en vuurt deze trigger
-- opnieuw -- maar met old.role = 'member', en dan doet hij niets.
-- ---------------------------------------------------------------------------

create or replace function public.ensure_group_admin()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_group uuid := old.group_id;
begin
  -- (1) Lock de groep. Is hij er niet meer, dan wordt hij net opgeheven en
  -- ruimt de cascade zijn leden op; dan valt er niets te bewaken.
  perform 1 from public.groups g where g.id = v_group for update;
  if not found then
    return null;
  end if;

  -- (2) Degraderen: de laatste beheerder mag zichzelf (of een beheerder een
  -- andere laatste beheerder) niet degraderen -- keuze e in de kop. Opvolging
  -- zou hier vaak dezelfde persoon terugzetten en de degradatie stil
  -- ongedaan maken.
  if tg_op = 'UPDATE' then
    if old.role = 'admin'
       and new.role <> 'admin'
       and not exists (
         select 1 from public.group_members m
         where m.group_id = v_group and m.role = 'admin'
       )
    then
      raise exception using errcode = 'P0001', message = 'last_admin';
    end if;
    return null;
  end if;

  -- (3) Verwijderd lidmaatschap. Geen lid meer: de groep verdwijnt. Links
  -- cascaden mee; groepsritten blijven bestaan met group_id = null (CLUB-11).
  if not exists (
    select 1 from public.group_members m where m.group_id = v_group
  ) then
    delete from public.groups g where g.id = v_group;
    return null;
  end if;

  -- Wel leden maar geen beheerder meer: het langst zittende lid wordt het.
  -- Bij gelijke joined_at beslist user_id, zodat de uitkomst vastligt.
  if not exists (
    select 1 from public.group_members m
    where m.group_id = v_group and m.role = 'admin'
  ) then
    update public.group_members m
       set role = 'admin'
     where m.group_id = v_group
       and m.user_id = (
         select m2.user_id
         from public.group_members m2
         where m2.group_id = v_group
         order by m2.joined_at, m2.user_id
         limit 1
       );
  end if;

  return null;
end;
$$;

revoke all on function public.ensure_group_admin() from public, anon, authenticated;

drop trigger if exists group_members_ensure_admin on public.group_members;
create trigger group_members_ensure_admin
  after delete or update of role on public.group_members
  for each row execute function public.ensure_group_admin();

-- ---------------------------------------------------------------------------
-- 11. create_group(p_name) -- groep + eerste beheerder, atomisch (keuze d)
--
-- Eén aanroep is één transactie. De guard-trigger telt mee bij het
-- lidmaatschap, dus een 11e groep faalt met too_many_groups en de groepsrij
-- rolt mee terug -- er blijft nooit een groep zonder beheerder achter
-- (CLUB-01, CLUB-18). De app krijgt alleen het id terug en leest de groep
-- daarna gewoon via de select-policy; dan bestaat het lidmaatschap al.
-- ---------------------------------------------------------------------------

create or replace function public.create_group(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_me   uuid := auth.uid();
  v_name text := btrim(p_name);
  v_id   uuid;
begin
  if v_me is null then
    raise exception using errcode = 'P0001', message = 'not_authenticated';
  end if;

  -- Dezelfde grens als de check op groups.name, maar met een melding die de
  -- app kan vertalen in plaats van een kale check-violation.
  if v_name is null or char_length(v_name) < 1 or char_length(v_name) > 60 then
    raise exception using errcode = 'P0001', message = 'group_name_invalid';
  end if;

  insert into public.groups (name, created_by)
  values (v_name, v_me)
  returning id into v_id;

  insert into public.group_members (group_id, user_id, role)
  values (v_id, v_me, 'admin');

  return v_id;
end;
$$;

revoke all on function public.create_group(text) from public, anon;
grant execute on function public.create_group(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 12. redeem_group_invite(p_code) -- binnenkomen via de groepslink (keuze a)
--
-- Security definer, want de genodigde kan de groep en de link nog niet lezen
-- (keuze 1 uit 0002). Rate limiting op het raden van codes hoort bij epic #75,
-- net als bij redeem_friend_invite -- bewust nog niet hier.
--
-- Wie al lid is, wordt niet opnieuw ingevoegd, en dat is een expliciete check
-- en geen "on conflict do nothing": een before-insert-trigger vuurt ook bij een
-- insert die daarna op een conflict stukloopt, en zou een bestaand lid dat
-- zijn link nog eens opent in een volle groep dan group_full geven. De
-- exception-tak vangt alleen het smalle geval dat hetzelfde account de link
-- twee keer tegelijk inwisselt: dan is het tweede resultaat gewoon "je bent
-- lid".
--
-- `#variable_conflict use_column`: de out-kolom group_id heet hetzelfde als
-- group_members.group_id. Alle kolommen zijn daarom ook met een alias
-- gekwalificeerd.
-- ---------------------------------------------------------------------------

create or replace function public.redeem_group_invite(p_code text)
returns table (group_id uuid, group_name text)
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

  if not exists (
    select 1 from public.group_members m
    where m.group_id = v_group and m.user_id = v_me
  ) then
    begin
      insert into public.group_members (group_id, user_id, role)
      values (v_group, v_me, 'member');
    exception
      when unique_violation then
        null;  -- tegelijk al ingewisseld door hetzelfde account: al lid.
    end;
  end if;

  select g.name into v_name
  from public.groups g
  where g.id = v_group;

  return query select v_group, v_name;
end;
$$;

revoke all on function public.redeem_group_invite(text) from public, anon;
grant execute on function public.redeem_group_invite(text) to authenticated;

commit;

-- ---------------------------------------------------------------------------
-- Controle
-- ---------------------------------------------------------------------------
-- select tablename, rowsecurity from pg_tables
--  where schemaname = 'public'
--    and tablename in ('groups', 'group_members', 'group_invites');
--
-- Verwacht: drie rijen, rowsecurity = true.
--
-- select tablename, count(*) from pg_policies
--  where schemaname = 'public'
--    and tablename in ('groups', 'group_members', 'group_invites',
--                      'group_rides', 'group_ride_participants')
--  group by tablename order by tablename;
--
-- Verwacht: groups 3, group_members 4, group_invites 3, group_rides 4
-- (select uit 0003, insert/update uit deze migratie, delete uit 0002),
-- group_ride_participants 5 (0002's vier plus insert_self_group).
--
-- select table_name, grantee, privilege_type
--   from information_schema.role_table_grants
--  where table_schema = 'public'
--    and table_name in ('groups', 'group_members', 'group_invites')
--  order by table_name, grantee, privilege_type;
--
-- select table_name, column_name, grantee, privilege_type
--   from information_schema.column_privileges
--  where table_schema = 'public'
--    and table_name in ('groups', 'group_members', 'group_invites')
--    and grantee in ('anon', 'authenticated')
--  order by table_name, privilege_type, column_name;
--
-- Verwacht: anon nergens. authenticated op tabelniveau alleen SELECT/DELETE;
-- op kolomniveau UPDATE(name) op groups, INSERT(group_id, user_id) en
-- UPDATE(role) op group_members, INSERT(code, group_id, created_by,
-- expires_at) op group_invites. service_role SELECT op groups en
-- group_members, niet op group_invites.
--
-- select proname from pg_proc
--  where pronamespace = 'public'::regnamespace
--    and proname in ('migrate_account_data', 'delete_own_account',
--                    'friend_profiles', 'redeem_friend_invite', 'create_group',
--                    'redeem_group_invite', 'is_ride_member', 'is_group_member',
--                    'set_updated_at', 'guard_group_member_insert',
--                    'ensure_group_admin')
--  order by proname;
--
-- Verwacht: 11 rijen -- de telling uit de kop (keuze g).
--
-- Deze queries bewijzen alleen dat alles bestaat. Het echte bewijs dat een
-- buitenstaander niets ziet en een gewoon lid niets mag, is
-- supabase/tests/clubs_deny_test.sql.
-- ---------------------------------------------------------------------------
