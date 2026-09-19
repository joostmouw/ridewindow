-- 0008 — gebruiksstatistiek, en alleen na toestemming.
--
-- Aanleiding
-- ----------
-- Voor de wervingsfase moet zichtbaar worden hoe de app werkelijk gebruikt
-- wordt: haken testers af op de eerste minuut, of pas na een week? Gebruiken ze
-- Peloton? Play Console beantwoordt dat alleen voor Android, en zwijgt over de
-- PWA -- waar juist de iOS-testers zitten.
--
-- De constraint die hiervoor herschreven is
-- -----------------------------------------
-- CLAUDE.md beloofde: "een uitgelogde gebruiker zijn data verlaat het toestel
-- nooit". Die belofte blijft staan, met één bewust toegevoegde voorwaarde: na
-- een expliciete "ja" van de gebruiker. Geen toestemming, geen rij. De app
-- vraagt het één keer en de schakelaar staat in Profiel.
--
-- Dit is dezelfde afweging als 0004 voor anonieme feedback, maar strenger:
-- daar is de verzendknop zelf de toestemming, hier is er geen knop en moet de
-- toestemming dus apart en vooraf gegeven worden.
--
-- Wat een rij WEL draagt
-- ----------------------
--   device_id   willekeurige uuid v4, lokaal gemaakt, weg zodra de gebruiker
--               de toestemming intrekt. Nodig om "drie sessies van één tester"
--               te onderscheiden van "drie testers".
--   user_id     bestaat, maar de app vult hem NOOIT. De kolom is er zodat de
--               policy hieronder een uitgelogde insert kan toestaan met
--               `user_id is null`. Of iemand ingelogd was, zegt de prop
--               `signed_in` -- dat beantwoordt dezelfde vraag zonder de rij
--               aan een persoon te knopen.
--   name        een vaste, korte lijst gebeurtenisnamen uit de app zelf.
--   props       jsonb, maar bewust smal: getallen en korte codes.
--   platform    'android' | 'web'
--   app_version het versienummer uit lib/core/app_version.dart
--
-- Wat een rij NOOIT draagt
-- ------------------------
-- Geen coordinaten, geen stadsnaam, geen vrije tekst, geen e-mailadres. Voor
-- vrije tekst bestaat `public.feedback` en daar hoort de gebruiker bewust op te
-- drukken. Een `check` hieronder houdt `props` klein zodat er niet per ongeluk
-- een zin in glijdt.
--
-- Geen select, voor niemand
-- -------------------------
-- Net als bij feedback (0004): de client schrijft en leest nooit terug. Er is
-- dus geen select-policy en geen select-grant. De rapportage draait met de
-- service-role sleutel vanaf Joosts eigen machine, buiten de app om.
--
-- Geen update, om dezelfde reden als 0004: PostgREST's upsert vraagt om
-- UPDATE-rechten, en die weg hoort fysiek dicht te zitten.

begin;

create table if not exists public.app_events (
  id           uuid primary key,
  device_id    uuid not null,
  user_id      uuid references auth.users(id) on delete set null,
  name         text not null check (char_length(name) between 1 and 40),
  props        jsonb not null default '{}'::jsonb
                 check (char_length(props::text) <= 500),
  platform     text not null check (platform in ('android', 'web')),
  app_version  text not null check (char_length(app_version) <= 20),
  occurred_at  timestamptz not null,
  created_at   timestamptz not null default now()
);

comment on table public.app_events is
  'Anonieme gebruiksstatistiek, alleen geschreven na expliciete toestemming '
  '(zie CLAUDE.md, constraint Privacy, herzien in v4.1). Insert-only: geen '
  'select- of update-rechten voor anon of authenticated.';

comment on column public.app_events.device_id is
  'Willekeurige uuid v4, lokaal gemaakt. Wordt weggegooid zodra de gebruiker '
  'zijn toestemming intrekt, en is dus geen blijvende identificator.';

comment on column public.app_events.occurred_at is
  'Wanneer de gebeurtenis plaatsvond op het toestel. Kan ver voor created_at '
  'liggen: de outbox bewaart rijen tot er weer verbinding is.';

-- Vragen die dit moet beantwoorden gaan altijd over een periode en een naam.
create index if not exists app_events_name_occurred_idx
  on public.app_events (name, occurred_at desc);

-- "Hoeveel toestellen waren er vorige week actief" is de kernvraag van de
-- wervingsfase, en die loopt over device_id.
create index if not exists app_events_device_occurred_idx
  on public.app_events (device_id, occurred_at desc);

alter table public.app_events enable row level security;

-- De enige policy. `user_id is null` is de uitgelogde tak, precies zoals bij
-- feedback: die moet werken, want de meeste webtesters zijn niet ingelogd.
create policy "insert own events" on public.app_events
  for insert with check (user_id is null or auth.uid() = user_id);

-- Postgres controleert tabelrechten VOOR het policies evalueert (zie 0004:
-- daar strandde de anonieme tak precies hierop). Dus beide rollen expliciet.
grant insert on public.app_events to anon;
grant insert on public.app_events to authenticated;

commit;
