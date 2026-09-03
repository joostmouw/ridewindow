-- ---------------------------------------------------------------------------
-- 0002_peloton.sql — epic "Peloton" (BACKLOG.md #62)
--
-- Dit is de eerste keer in dit project dat gebruiker A data van gebruiker B
-- ziet. Alles in 0001 zegt "alleen je eigen rijen" — dat is wat SYNC-08
-- bewijst — en die regel wordt hier niet versoepeld maar uitgebreid met
-- precies twee relaties: je bent elkaars maatje, of je bent deelnemer aan
-- dezelfde rit. Buiten die twee verandert er niets.
--
-- VIER KEUZES DIE DE REST BEPALEN
--
-- 1. **Vriend worden gaat via een deellink, niet via zoeken op e-mail.** Een
--    zoekfunctie op adres laat je uitproberen wélke adressen een account
--    hebben, en dat lek is achteraf niet te dichten. De code in de link is de
--    capability: wie hem heeft mag binnen, wie hem niet heeft ziet niet eens
--    dat de rij bestaat.
--
-- 2. **`profiles` blijft dicht, ook voor vrienden.** Namen komen uit
--    `friend_profiles()`, die alléén (user_id, user_name) teruggeeft. Zou je in
--    plaats daarvan een select-policy "vrienden mogen elkaars profiel lezen"
--    toevoegen, dan krijgt een vriend de hele rij: tolerantie-instellingen,
--    notificatievoorkeuren, locatie-override. Grants in Postgres gelden per rol
--    en niet per policy, dus dat is niet per kolom terug te schroeven.
--
-- 3. **Eén gedeelde rit met deelnemers**, geen kopie per persoon. De eigenaar
--    verzet de tijd en dat schuift bij iedereen mee. Dat is Joost's keuze
--    (2026-09-03) en het is de reden dat `group_rides` bestaat naast het
--    bestaande `planned_rides` — dat laatste blijft strikt persoonlijk en
--    ongewijzigd.
--
-- 4. **`is_ride_member()` is geen gemak maar noodzaak.** Een policy op
--    `group_ride_participants` die zelf `group_ride_participants` bevraagt,
--    geeft in Postgres "infinite recursion detected in policy". De security
--    definer functie breekt die lus omdat hij RLS omzeilt. Haal hem niet weg
--    "omdat het ook inline kan" — dat is precies wat niet kan.
--
-- AFWIJKING VAN CLAUDE.md, BEWUST: daar staat dat er precies één server-side
-- functie is (`migrate_account_data`). Dit worden er vijf. De reden is per
-- functie dezelfde: zonder is het niet veilig te doen. Nog steeds geen Edge
-- Functions en geen andere server-side code.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 1. Vriendschappen
-- ---------------------------------------------------------------------------

-- Eén rij per paar, met een canonieke volgorde (user_a < user_b) zodat
-- (A,B) en (B,A) niet allebei kunnen bestaan. De check dwingt dat af in de
-- database in plaats van in de client.
create table public.friendships (
  user_a     uuid not null references auth.users(id) on delete cascade,
  user_b     uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_a, user_b),
  constraint friendships_canonical_order check (user_a < user_b)
);

create index friendships_user_b_idx on public.friendships (user_b);

-- Een uitnodiging om maatjes te worden. Blijft geldig tot hij verloopt of
-- ingetrokken wordt; meerdere mensen mogen dezelfde link gebruiken, want een
-- link die je in een groepsapp plakt is nu eenmaal voor iedereen daarin.
create table public.friend_invites (
  code       text primary key,
  inviter_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

create index friend_invites_inviter_idx on public.friend_invites (inviter_id);

-- ---------------------------------------------------------------------------
-- 2. Gedeelde ritten
-- ---------------------------------------------------------------------------

create table public.group_rides (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null references auth.users(id) on delete cascade,
  start_at      timestamptz not null,
  end_at        timestamptz not null,
  planned_score real not null,
  -- Denormaliseerd zodat een deelnemer de naam van de eigenaar ziet zonder dat
  -- `profiles` open hoeft (keuze 2).
  owner_name    text,
  note          text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index group_rides_owner_idx on public.group_rides (owner_id);

create table public.group_ride_participants (
  ride_id      uuid not null references public.group_rides(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  -- invited -> accepted | declined. Geen enum: een tekstkolom met check is
  -- makkelijker uit te breiden dan een Postgres-enum, die een migratie vergt
  -- voor elke nieuwe waarde.
  status       text not null default 'invited'
                 check (status in ('invited', 'accepted', 'declined')),
  display_name text,
  invited_at   timestamptz not null default now(),
  responded_at timestamptz,
  primary key (ride_id, user_id)
);

create index group_ride_participants_user_idx
  on public.group_ride_participants (user_id);

-- ---------------------------------------------------------------------------
-- 3. Helper die de policy-recursie breekt (keuze 4)
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
    where r.id = p_ride_id and r.owner_id = auth.uid()
  ) or exists (
    select 1 from public.group_ride_participants p
    where p.ride_id = p_ride_id and p.user_id = auth.uid()
  );
$$;

revoke all on function public.is_ride_member(uuid) from public, anon;
grant execute on function public.is_ride_member(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. RLS + policies
-- ---------------------------------------------------------------------------

alter table public.friendships             enable row level security;
alter table public.friend_invites          enable row level security;
alter table public.group_rides             enable row level security;
alter table public.group_ride_participants enable row level security;

-- friendships: je ziet en verwijdert alleen paren waar je zelf in zit. Insert
-- loopt uitsluitend via redeem_friend_invite() — anders zou je jezelf aan
-- willekeurige mensen kunnen toevoegen.
create policy friendships_select_own on public.friendships
  for select using (auth.uid() in (user_a, user_b));

create policy friendships_delete_own on public.friendships
  for delete using (auth.uid() in (user_a, user_b));

-- friend_invites: alleen de maker. De genodigde komt binnen via
-- redeem_friend_invite() en heeft dus geen select nodig (keuze 1).
create policy friend_invites_own on public.friend_invites
  for all using (inviter_id = auth.uid()) with check (inviter_id = auth.uid());

-- group_rides: eigenaar of deelnemer leest; alleen de eigenaar schrijft.
create policy group_rides_select_member on public.group_rides
  for select using (public.is_ride_member(id));

create policy group_rides_insert_own on public.group_rides
  for insert with check (owner_id = auth.uid());

create policy group_rides_update_own on public.group_rides
  for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy group_rides_delete_own on public.group_rides
  for delete using (owner_id = auth.uid());

-- participants: iedereen die bij de rit hoort ziet de hele deelnemerslijst —
-- dat is het punt van samen fietsen. De helper voorkomt de recursie.
create policy group_ride_participants_select_member
  on public.group_ride_participants
  for select using (public.is_ride_member(ride_id));

-- Uitnodigen mag alleen de eigenaar, en alleen voor een maatje. Zonder die
-- tweede voorwaarde kan iedereen wildvreemden aan een rit hangen.
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

-- Je antwoordt alleen namens jezelf. De eigenaar kan dus niet "ja" zeggen voor
-- een ander.
create policy group_ride_participants_update_own
  on public.group_ride_participants
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Afmelden mag jezelf; de eigenaar mag iemand van zijn rit halen.
create policy group_ride_participants_delete on public.group_ride_participants
  for delete using (
    user_id = auth.uid()
    or exists (
      select 1 from public.group_rides r
      where r.id = ride_id and r.owner_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- 5. Grants
--
-- Zonder deze regels faalt alles, ook met correcte policies: Postgres
-- controleert tabelrechten VOOR RLS. Dat heeft in 21-02 een checkpoint gekost;
-- zie de toelichting in 0001. `anon` krijgt niets.
-- ---------------------------------------------------------------------------

grant select, delete                 on public.friendships             to authenticated;
grant select, insert, update, delete on public.friend_invites          to authenticated;
grant select, insert, update, delete on public.group_rides             to authenticated;
grant select, insert, update, delete on public.group_ride_participants to authenticated;
-- friendships krijgt bewust geen insert: dat pad loopt via de functie.

-- ---------------------------------------------------------------------------
-- 6. redeem_friend_invite(p_code) — de enige weg naar een vriendschap
-- ---------------------------------------------------------------------------

create or replace function public.redeem_friend_invite(p_code text)
returns table (friend_id uuid, friend_name text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_inviter uuid;
  v_me      uuid := auth.uid();
  v_a       uuid;
  v_b       uuid;
  v_name    text;
begin
  if v_me is null then
    raise exception 'niet ingelogd';
  end if;

  select inviter_id into v_inviter
  from public.friend_invites
  where code = p_code and expires_at > now();

  if not found then
    raise exception 'uitnodiging bestaat niet of is verlopen';
  end if;

  if v_inviter = v_me then
    raise exception 'je kunt niet je eigen maatje worden';
  end if;

  -- Canonieke volgorde, zodat de check-constraint klopt en (A,B) en (B,A) niet
  -- allebei kunnen ontstaan.
  v_a := least(v_inviter, v_me);
  v_b := greatest(v_inviter, v_me);

  insert into public.friendships (user_a, user_b)
  values (v_a, v_b)
  on conflict do nothing;

  select p.user_name into v_name
  from public.profiles p where p.user_id = v_inviter;

  return query select v_inviter, v_name;
end;
$$;

revoke all on function public.redeem_friend_invite(text) from public, anon;
grant execute on function public.redeem_friend_invite(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 7. friend_profiles() — namen zonder `profiles` open te zetten (keuze 2)
-- ---------------------------------------------------------------------------

create or replace function public.friend_profiles()
returns table (user_id uuid, user_name text)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select p.user_id, p.user_name
  from public.profiles p
  where p.user_id in (
    select case when f.user_a = auth.uid() then f.user_b else f.user_a end
    from public.friendships f
    where auth.uid() in (f.user_a, f.user_b)
  );
$$;

revoke all on function public.friend_profiles() from public, anon;
grant execute on function public.friend_profiles() to authenticated;

-- ---------------------------------------------------------------------------
-- 8. updated_at op group_rides — hergebruikt de trigger-functie uit 0001
--
-- Let op (backlog #57): deze trigger maakt élke schrijving tot "een
-- wijziging", ook een echo van de client. Bij `profiles` heeft dat een lus
-- opgeleverd die zichzelf voedde. Hier is dat risico kleiner omdat alleen de
-- eigenaar schrijft en deelnemers nooit terugschrijven — maar wie hier ooit
-- een reconcile op bouwt die de rit lokaal overneemt, moet die rij níét
-- opnieuw enqueuen.
-- ---------------------------------------------------------------------------

create trigger group_rides_set_updated_at
  before update on public.group_rides
  for each row execute function public.set_updated_at();
