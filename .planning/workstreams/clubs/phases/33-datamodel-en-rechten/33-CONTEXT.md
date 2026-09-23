# Phase 33: Datamodel en rechten - Context

**Gathered:** 2026-09-23
**Status:** Ready for planning
**Source:** PRD Express Path — Joosts besluiten van 2026-09-23 (ontwerp https://claude.ai/artifact/VLK7ktJhi4a75SALjRMN7W) + `.planning/workstreams/clubs/REQUIREMENTS.md`

<domain>
## Phase Boundary

Alleen de database: één migratie `supabase/migrations/0012_groups.sql` plus een deny-test in
`supabase/tests/`, en de "No backend"-alinea in `CLAUDE.md` en `AGENTS.md`. **Geen Dart-code,
geen UI** — dat is fase 34/35. Na deze fase kan een client via PostgREST/rpc alles wat fase 34
en 35 nodig hebben, en kan hij niets wat hij niet mag.

Requirements: CLUB-10, CLUB-17, CLUB-18, CLUB-19, CLUB-20. Maar het schema moet ook de
rechten dragen van CLUB-01..09, 11..16 (de UI-fases voegen geen migratie meer toe tenzij het
echt niet anders kan).

</domain>

<decisions>
## Implementation Decisions (locked — Joost, 2026-09-23)

### Lidmaatschap
- Een groep heeft een naam, leden en een rol per lid: `admin` of `member` (tekst + check, geen
  enum — zelfde reden als `group_ride_participants.status` in 0002).
- De maker wordt bij het aanmaken meteen lid met rol `admin`. Dat moet atomair: groep + eerste
  lidmaatschap in één stap (rpc `create_group(p_name)` óf een `after insert`-trigger op `groups`).
  Kies wat het minst nieuwe functies oplevert en niet op de `insert ... returning`-valkuil
  stukloopt (zie PELOTON.md / 0003).
- Lid worden kan op precies twee manieren:
  1. **Groepslink**: `group_invites` (code, group_id, created_by, expires_at), naar het model van
     `friend_invites`. Inwisselen via rpc `redeem_group_invite(p_code)` — security definer, want
     de genodigde kan de groep nog niet lezen. Code uit dezelfde bron/lengte als de maatjescode.
  2. **Beheerder voegt een bestaand maatje toe**: insert in `group_members` mag alleen als de
     aanroeper `admin` van die groep is én de nieuwe user een maatje van de aanroeper is
     (`friendships`).
- **Alleen beheerders** maken/trekken groepslinks in en voegen leden toe.

### Beheer
- Meerdere beheerders. Een admin kan een lid admin maken en een admin weer `member` maken.
- Een admin kan een lid verwijderen, de naam wijzigen, en de groep opheffen.
- Een lid kan zichzelf verwijderen (verlaten).
- **Altijd minstens één admin (CLUB-10):** verliest een groep zijn laatste admin (verlaten,
  gedegradeerd, verwijderd, of account weg via cascade), dan wordt het langst zittende lid
  (`joined_at` oudst) admin. Verliest de groep zijn laatste lid, dan wordt de groep verwijderd.
  Afdwingen in de database (trigger), niet in de app. Let op: een admin die zichzelf als enige
  admin wil degraderen terwijl er andere leden zijn — óf weigeren, óf opvolging laten gelden;
  kies één en leg het vast.
- **Opheffen (CLUB-11):** de groep verdwijnt; groepsritten blijven bestaan voor de eigenaar en
  wie al een participant-rij heeft, maar zonder groep (`group_rides.group_id` → `on delete set null`).

### Groepsritten
- `group_rides.group_id uuid null references groups(id) on delete set null`. Een rit met
  `group_id` hoort bij de groep; **geen momentopname** van leden.
- `is_ride_member(ride_id)` wordt uitgebreid: eigenaar, óf participant, óf **huidig lid van de
  groep van de rit**. Daarmee erven `group_rides`, `group_ride_participants`,
  `group_ride_options` en `group_ride_option_votes` de zichtbaarheid automatisch. Ex-lid ziet
  de rit niet meer, tenzij eigenaar (CLUB-13). Een ex-lid met een oude participant-rij: moet hij
  de rit nog zien? **Nee** voor groepsritten — de rij blijft bestaan maar geeft geen toegang
  meer. Leg dat expliciet vast in de helper.
- Ieder lid mag een groepsrit aanmaken (`group_rides` insert met `group_id` alleen als de
  aanroeper lid is van die groep).
- **Antwoorden:** een lid krijgt pas een participant-rij als hij antwoordt. Er is dus een nieuwe
  insert-policy nodig op `group_ride_participants`: je mag een rij voor **jezelf** invoegen op
  een groepsrit van een groep waar je lid bent. De bestaande owner-nodigt-maatje-uit-policy
  blijft ongewijzigd.
- Stemmen op vensters werkt vanzelf via `is_ride_member` (0010-policy).

### Zichtbaarheid
- Ieder lid leest de groep en de volledige ledenlijst (user_id, rol, joined_at, **naam**).
  Namen: denormaliseer `display_name` op `group_members` (zoals `group_ride_participants.display_name`
  en `group_rides.owner_name`) — `profiles` blijft dicht (keuze 2 uit 0002).
- Een buitenstaander ziet niets: geen groep, geen ledenlijst, geen groepsrit, geen link.
- Beschikbaarheidsrooster blijft privé; niets in deze fase raakt `availability`.

### Grenzen (CLUB-18)
- Max **30 leden** per groep, max **10 groepen** per account (lidmaatschappen, niet alleen
  gemaakte groepen). Afgedwongen in de database (trigger op `group_members` insert), met een
  herkenbare foutcode/-tekst (bv. `raise exception using errcode = 'P0001', message = 'group_full'`
  / `'too_many_groups'`) zodat fase 34 er een nette NL/EN-melding van kan maken.
- Race: twee gelijktijdige joins op lid 30 — lock de groepsrij (`select ... for update`) in de
  trigger of rpc.

### Account verwijderen (CLUB-19)
- `delete_own_account` verwijdert `auth.users`; `group_members.user_id ... on delete cascade`
  ruimt het lidmaatschap op en de opvolgingstrigger uit CLUB-10 moet dan ook vuren (controleer
  dat een `after delete`-trigger op cascade-deletes afgaat — dat doet hij in Postgres).
  `groups.created_by` mag niet cascaden tot het verwijderen van de hele groep: `on delete set null`.

### Server-functies (CLUB-20)
- Nieuw: `redeem_group_invite` (rpc) en `is_group_member` (security definer helper, nodig tegen
  de policy-recursie op `group_members` — zelfde reden als `is_ride_member`, zie keuze 4 in 0002).
- Als er meer functies nodig blijken (`create_group`, triggerfuncties voor opvolging/grenzen),
  dan wordt elke functie in de migratie verantwoord en de telling in `CLAUDE.md` + `AGENTS.md`
  klopt met de werkelijkheid (nu zes: migrate_account_data, delete_own_account, friend_profiles,
  redeem_friend_invite, is_ride_member, set_updated_at). **De telling volgt het schema, niet de
  roadmap** — "acht" in CLUB-20 is de verwachting, geen doel.

### Claude's Discretion
- Tabel- en kolomnamen, indexen, precieze triggervorm.
- Of `create_group` een rpc of een trigger wordt.
- Structuur van de deny-test (volg `supabase/tests/rls_deny_test.sql`: rollback-transactie,
  resultaten als `select`, `raise exception` op falen, `session_replication_role = replica` om
  auth.users-rijen te omzeilen).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Bestaand schema
- `supabase/migrations/0001_accounts_sync.sql` — `delete_own_account`, grant-patroon, `set_updated_at`
- `supabase/migrations/0002_peloton.sql` — friendships, friend_invites, group_rides, participants, `is_ride_member`, `redeem_friend_invite`, `friend_profiles`; de vier keuzes bovenaan
- `supabase/migrations/0003_group_rides_select_own_row.sql` — de `insert ... returning`-valkuil en waarom `owner_id = auth.uid()` vóór de helper staat
- `supabase/migrations/0005_tighten_table_grants.sql`, `0006_tighten_grants_schema_wide.sql` — grants zijn krap; een nieuwe tabel krijgt niets vanzelf (ook `service_role` niet, zie 0009/0011)
- `supabase/migrations/0010_group_ride_options.sql` — opties + stemmen, policies via `is_ride_member`

### Tests en valkuilen
- `supabase/tests/rls_deny_test.sql` — het bestaande deny-testpatroon (SQL Editor, rollback, resultaat als select)
- `.planning/PELOTON.md` — valkuilen: RLS-recursie, insert-returning, PWA-cache

### Constraints
- `CLAUDE.md` en `AGENTS.md` — "No backend (revised in v3.0)": telling en verantwoording van server-functies
- `.planning/workstreams/clubs/REQUIREMENTS.md` — CLUB-01..24

</canonical_refs>

<specifics>
## Specific Ideas

- Migratienummer is **0012**; 0011 is `feedback_service_role_select` (live toegepast 2026-09-23).
- Joost past de migratie zelf toe via de Supabase SQL Editor (checkpoint). De deny-test draait
  daar ook, en het resultaat moet als tabel zichtbaar zijn (geen `raise notice`).
- Denk aan grants voor `authenticated` op de nieuwe tabellen en `execute` op de nieuwe functies
  (revoke van `public, anon`), en aan `service_role` select als de rapportage ooit mee moet kijken.
- Dezelfde commentaarstijl als 0002/0010: Nederlands, waarom-gericht.

</specifics>

<deferred>
## Deferred Ideas

- Terugkerende groepsrit, nieuwe leden melden bij lopende ritten, QR voor de groepslink,
  meerdere groepen tegelijk uitnodigen (Future Requirements).
- Melding bij uitnodiging — backlog #77.
- Rate limiting op `redeem_group_invite` — hoort bij epic #75 punt 3, net als bij `redeem_friend_invite`.

</deferred>

---

*Phase: 33-datamodel-en-rechten*
*Context gathered: 2026-09-23 via PRD Express Path (Joosts besluiten)*
