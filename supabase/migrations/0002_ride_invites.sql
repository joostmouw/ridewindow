-- ---------------------------------------------------------------------------
-- 0002_ride_invites.sql — epic "Peloton" (BACKLOG.md #62), eerste slice:
-- A deelt een link voor één concrete rit, B redeemt de code en accepteert.
--
-- Dit is de eerste keer in dit project dat gebruiker A iets van gebruiker B te
-- zien krijgt. Elke policy in 0001 zegt "alleen je eigen rijen" (dat is wat
-- SYNC-08 bewijst), en die regel blijft hier overeind — de uitzondering wordt
-- niet gemaakt met een bredere policy maar met twee `security definer`
-- functies, zodat de tabellen zelf dicht blijven.
--
-- DRIE ONTWERPKEUZES DIE JE MOET KENNEN VOOR JE HIER IETS AAN VERANDERT:
--
-- 1. **De code is de sleutel (capability), niet een lookup-recht.** Er is geen
--    `select`-policy op `ride_invites` voor de genodigde. Een policy als
--    `using (true)` zou werken, maar dan kan élke ingelogde gebruiker de hele
--    tabel uitlezen: alle ritten, alle tijdstippen, van iedereen. Wie de code
--    heeft, komt binnen via `redeem_ride_invite()`; wie hem niet heeft, ziet
--    niets — ook niet dat een rij bestaat.
--
-- 2. **`profiles` blijft volledig dicht.** De naam van wie accepteert wordt bij
--    het accepteren gekopieerd naar `ride_invite_accepts.display_name`, door de
--    functie zelf. Zou de uitnodiger in plaats daarvan `profiles` van de
--    genodigde mogen lezen, dan was daarvoor een cross-user select-policy op
--    profiles nodig — en dat is precies het soort verruiming waar dit soort
--    apps op omvalt. Denormalisatie is hier de goedkopere en veiligere keuze.
--
-- 3. **Accepteren schrijft nooit in andermans rijen.** `redeem_ride_invite()`
--    geeft de rit terug; de client schrijft hem daarna in zijn *eigen*
--    `planned_rides` via de bestaande outbox. Er is dus geen enkel pad waarop
--    A in B's data schrijft of andersom.
--
-- AFWIJKING VAN EEN PROJECTCONSTRAINT, BEWUST: CLAUDE.md legt vast dat er
-- precies één server-side functie is (`migrate_account_data`). Dit worden er
-- drie. De reden is dezelfde als daar: zonder server-side functie is dit niet
-- veilig te doen. Het alternatief is een select-policy die de hele tabel
-- opent. Nog steeds geen Edge Functions, geen andere server-side code.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 1. Tabellen
-- ---------------------------------------------------------------------------

create table public.ride_invites (
  id            uuid primary key default gen_random_uuid(),
  inviter_id    uuid not null references auth.users(id) on delete cascade,
  -- Korte, onraadbare code. Hoofdletterloos en zonder 0/O/1/l zodat hij ook
  -- voor te lezen is door de telefoon.
  code          text not null unique,
  -- De rit zelf wordt gekopieerd in plaats van naar `planned_rides` te
  -- verwijzen: de uitnodiger mag zijn eigen rit later verwijderen zonder dat
  -- de uitnodiging betekenisloos wordt, en de genodigde krijgt sowieso een
  -- eigen kopie in zijn eigen rij.
  start_at      timestamptz not null,
  end_at        timestamptz not null,
  planned_score real not null,
  -- Denormaliseerd om dezelfde reden als display_name hieronder: anders zou de
  -- genodigde `profiles` van de uitnodiger moeten kunnen lezen.
  inviter_name  text,
  created_at    timestamptz not null default now(),
  -- Een uitnodiging voor een rit die al voorbij is, is geen uitnodiging meer.
  expires_at    timestamptz not null
);

create index ride_invites_inviter_idx on public.ride_invites (inviter_id);

create table public.ride_invite_accepts (
  invite_id    uuid not null references public.ride_invites(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  -- Zie ontwerpkeuze 2 hierboven: gekopieerd bij het accepteren, zodat
  -- `profiles` dicht kan blijven.
  display_name text,
  accepted_at  timestamptz not null default now(),
  primary key (invite_id, user_id)
);

-- ---------------------------------------------------------------------------
-- 2. RLS + policies
-- ---------------------------------------------------------------------------

alter table public.ride_invites        enable row level security;
alter table public.ride_invite_accepts enable row level security;

-- ride_invites: alleen de uitnodiger raakt zijn eigen rijen aan. Er is
-- opzettelijk GEEN select-policy voor de genodigde -- die komt binnen via
-- redeem_ride_invite() (ontwerpkeuze 1).
create policy ride_invites_select_own on public.ride_invites
  for select using (inviter_id = auth.uid());

create policy ride_invites_insert_own on public.ride_invites
  for insert with check (inviter_id = auth.uid());

create policy ride_invites_delete_own on public.ride_invites
  for delete using (inviter_id = auth.uid());

-- Geen update-policy: een uitnodiging wijzig je niet, je maakt een nieuwe.

-- ride_invite_accepts: de uitnodiger ziet wie er meegaat op ZIJN uitnodigingen,
-- en de genodigde ziet zijn eigen acceptatie. Verder niemand.
create policy ride_invite_accepts_select_inviter on public.ride_invite_accepts
  for select using (
    exists (
      select 1 from public.ride_invites i
      where i.id = ride_invite_accepts.invite_id
        and i.inviter_id = auth.uid()
    )
  );

create policy ride_invite_accepts_select_own on public.ride_invite_accepts
  for select using (user_id = auth.uid());

-- Zelf je acceptatie intrekken mag; insert loopt uitsluitend via de functie.
create policy ride_invite_accepts_delete_own on public.ride_invite_accepts
  for delete using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 3. Grants
--
-- Zonder deze regels faalt alles, ook met correcte policies: Postgres
-- controleert tabelrechten VOOR RLS. Dat heeft in 21-02 een checkpoint gekost
-- -- zie de uitgebreide toelichting in 0001. `anon` krijgt niets.
-- ---------------------------------------------------------------------------

grant select, insert, delete on public.ride_invites        to authenticated;
grant select, delete         on public.ride_invite_accepts to authenticated;
-- Insert op accepts loopt via redeem_ride_invite() (security definer), dus de
-- rol heeft het recht zelf niet nodig.

-- ---------------------------------------------------------------------------
-- 4. redeem_ride_invite(p_code) -- de enige weg naar binnen voor een genodigde
--
-- security definer omdat de aanroeper per definitie geen select-recht heeft op
-- de uitnodiging: hij bewijst zijn recht met de code, niet met zijn identiteit.
-- Registreert meteen de acceptatie, zodat "bekijken" en "accepteren" niet twee
-- rondgangen zijn -- de genodigde heeft de link al bewust geopend.
--
-- `search_path` wordt vastgezet: een security definer functie zonder vaste
-- search_path is te kapen via een schema in het pad van de aanroeper.
-- ---------------------------------------------------------------------------

create or replace function public.redeem_ride_invite(p_code text)
returns table (
  invite_id     uuid,
  inviter_name  text,
  start_at      timestamptz,
  end_at        timestamptz,
  planned_score real
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_invite public.ride_invites%rowtype;
  v_name   text;
begin
  if auth.uid() is null then
    raise exception 'niet ingelogd';
  end if;

  select * into v_invite
  from public.ride_invites
  where code = p_code
    and expires_at > now();

  if not found then
    raise exception 'uitnodiging bestaat niet of is verlopen';
  end if;

  -- Jezelf uitnodigen is geen fout maar ook geen acceptatie: geef de rit terug
  -- zonder een accept-rij te schrijven, anders staat de uitnodiger als
  -- deelnemer op zijn eigen rit.
  if v_invite.inviter_id = auth.uid() then
    return query select v_invite.id, v_invite.inviter_name, v_invite.start_at,
                        v_invite.end_at, v_invite.planned_score;
    return;
  end if;

  select p.user_name into v_name
  from public.profiles p
  where p.user_id = auth.uid();

  insert into public.ride_invite_accepts (invite_id, user_id, display_name)
  values (v_invite.id, auth.uid(), v_name)
  on conflict (invite_id, user_id)
    do update set display_name = excluded.display_name;

  return query select v_invite.id, v_invite.inviter_name, v_invite.start_at,
                      v_invite.end_at, v_invite.planned_score;
end;
$$;

revoke all on function public.redeem_ride_invite(text) from public, anon;
grant execute on function public.redeem_ride_invite(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. peek_ride_invite(p_code) -- kijken zonder te accepteren
--
-- Aparte functie omdat de app de rit moet kunnen tonen voordat de gebruiker op
-- "meedoen" tikt. Zelfde capability-model, maar schrijft niets.
-- ---------------------------------------------------------------------------

create or replace function public.peek_ride_invite(p_code text)
returns table (
  invite_id     uuid,
  inviter_name  text,
  start_at      timestamptz,
  end_at        timestamptz,
  planned_score real,
  accepted      boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_invite public.ride_invites%rowtype;
begin
  if auth.uid() is null then
    raise exception 'niet ingelogd';
  end if;

  select * into v_invite
  from public.ride_invites
  where code = p_code
    and expires_at > now();

  if not found then
    raise exception 'uitnodiging bestaat niet of is verlopen';
  end if;

  return query
    select v_invite.id, v_invite.inviter_name, v_invite.start_at,
           v_invite.end_at, v_invite.planned_score,
           exists (
             select 1 from public.ride_invite_accepts a
             where a.invite_id = v_invite.id and a.user_id = auth.uid()
           );
end;
$$;

revoke all on function public.peek_ride_invite(text) from public, anon;
grant execute on function public.peek_ride_invite(text) to authenticated;
