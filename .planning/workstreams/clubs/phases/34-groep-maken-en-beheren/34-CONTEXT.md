# Phase 34: Groep maken en beheren - Context

**Gathered:** 2026-09-23
**Status:** Ready for planning
**Source:** PRD Express Path — schets 015 (gekozen door Joost 2026-09-23) + `.planning/workstreams/clubs/REQUIREMENTS.md`

<domain>
## Phase Boundary

De eerste UI-fase van Clubs: een ingelogde gebruiker maakt een groep, deelt de groepslink, wordt
lid via `/group/:code`, ziet zijn groepen op de Peloton-tab, en een beheerder beheert leden,
beheerders, naam, link en opheffen. **Geen groepsritten** (uitnodigen voor een rit, groepslabel op
ritkaarten, het groepsfilter op de Ritten-tab, de teller) — dat is fase 35.

Requirements: CLUB-01..09, CLUB-11. Het schema staat live (migratie 0012, fase 33) en is bewezen
met 81/81 deny-checks; **deze fase voegt in principe geen migratie toe**. Blijkt er toch iets te
ontbreken, dan is dat een aparte, verantwoorde migratie 0013 met een checkpoint voor Joost.

</domain>

<decisions>

## HERZIENING 2026-09-23 (Joost, ná de schets) — gaat vóór alles hieronder

### Aanvragen en goedkeuring (CLUB-02, CLUB-03 herzien; CLUB-27 nieuw)
- **Ieder lid** mag mensen aandragen; **alleen beheerders** maken iemand daadwerkelijk lid.
- **Groepslink:** ieder lid mag hem delen (niet meer alleen beheerders). Wie de link opent en
  inlogt, wordt **geen lid** maar dient een **aanvraag** in en ziet op de landing / het groepsscherm
  "Je aanvraag ligt bij de beheerders".
- **Maatje voordragen:** ieder lid kan een maatje van zichzelf voordragen → aanvraag. Draagt een
  **beheerder** een maatje voor, dan wordt dat maatje **direct lid** (geen tweede goedkeuring).
- **Beheerder** ziet op het groepsscherm een sectie "Aanvragen" (bovenaan, alleen voor beheerders)
  met naam, "via link" of "voorgedragen door X", en per aanvraag **Accepteren** / **Afwijzen**.
  Accepteren respecteert de 30-grens en de 10-groepengrens van de aanvrager (bestaande triggers
  op `group_members`).
- **Dit vraagt een migratie `0013_group_join_requests.sql`** (schema in 33 kent dit niet):
  tabel `group_join_requests` (group_id, user_id, proposed_by null=via link, display_name,
  created_at; uniek (group_id, user_id)); `redeem_group_invite` maakt voortaan een aanvraag i.p.v.
  een lidmaatschap (en geeft terug dat het een aanvraag is; al lid → gewoon lid-status);
  insert-policy: lid mag een aanvraag doen voor een eigen maatje; beheerder die voordraagt → direct
  `group_members` (bestaande policy); rpc `accept_group_request(p_request_id)` (security definer:
  alleen beheerder van die groep; insert member + delete request in één transactie — nodig omdat de
  aanvrager geen maatje van de beheerder hoeft te zijn); afwijzen = delete door beheerder;
  aanvrager mag zijn eigen aanvraag zien en intrekken; voordrager ziet zijn voordrachten.
  Grens op openstaande aanvragen per groep (bv. 30) tegen spam. Wijzig de insert-policy op
  `group_members` niet anders dan nodig. **De functietelling wordt twaalf** (accept_group_request);
  bijwerken in CLAUDE.md/AGENTS.md. **Deny-test uitbreiden** (`clubs_deny_test.sql` of een nieuwe
  `clubs_requests_deny_test.sql`): gewoon lid kan niemand lid maken, niet accepteren/afwijzen,
  buitenstaander ziet geen aanvragen, link maakt aanvraag i.p.v. lid, accept respecteert grenzen.
  Checkpoint voor Joost: 0013 + test in de SQL Editor, vóór de UI tegen echte data draait.

### Info-knop met de groepsregels (CLUB-28)
- Een info-knop (zelfde patroon en icoon als de bestaande info-knoppen in de app — zie
  `planned_rides_screen.dart`, `profile_screen.dart`, `ride_detail_screen.dart`) in de sectiekop
  "Groepen" op de Peloton-tab én op het groepsscherm. Opent een uitleg met de regels:
  ieder lid draagt voor, beheerders accepteren of wijzen af; max 30 leden per groep, max 10
  groepen per persoon; leden zien elkaars naam en antwoorden op groepsritten, niet je rooster of
  instellingen; groepsritten zien alle huidige leden, wie vertrekt niet meer; verlaten; de laatste
  beheerder (langst zittende lid neemt over); opheffen (ritten met antwoorden blijven zonder label).
  NL + EN.

### Wat daardoor verandert t.o.v. de tekst hieronder
- "Alleen beheerders zien de knop Deel de groepslink" → **ieder lid** ziet hem.
- "+ Maatje toevoegen" (alleen beheerders) → **"+ Maatje voordragen"** voor ieder lid; bij een
  beheerder heet het "+ Maatje toevoegen" en is het direct.
- Een gewoon lid ziet nog steeds geen ⋮ per lid en geen Aanvragen-sectie.

## Implementation Decisions (locked)

### Plek — schets 015, vraag 1, variant A
- Op de **Peloton-tab** (`BuddiesTab`, tweede tab van "Mijn Ritten" in `planned_rides_screen.dart`)
  komt een sectie **Groepen** boven de sectie **Maatjes**, met "+ Nieuwe groep" in de sectiekop.
- Groepskaart: kenteken (initialen, `brandLight`-vlak), naam, "N leden", en een chip "beheerder"
  als jij beheerder bent. Tik opent het groepsscherm.
- Zonder groepen: één uitnodigende kaart ("Fiets je met een vaste club?" + knop "Groep maken") in
  plaats van een lege kop.
- Variant C (groepschips op de Ritten-tab) is óók gekozen maar hoort bij fase 35 (CLUB-26).

### Groepsscherm en beheer — schets 015, vraag 2, variant A
- Eigen route (bijv. `/peloton/group/:groupId`), appbar met terug, naam, en ⋮-menu.
- Kop ("hero"): kenteken, naam, "N leden". **Alleen beheerders** zien de knop "Deel de groepslink".
- Ledenlijst: naam, "(jij)" bij jezelf, chip "beheerder". **Alleen beheerders** zien ⋮ achter
  andere leden met: "Beheerder maken" / "Beheerder af" en "Uit de groep halen".
- Sectiekop Leden heeft voor beheerders "+ Maatje toevoegen" (CLUB-03): lijst van je maatjes;
  wie al lid is staat erbij maar is niet aan te tikken.
- Appbar-⋮ voor beheerders: Naam wijzigen, Link vervangen, Groep verlaten, Groep opheffen.
  Voor een gewoon lid: alleen Groep verlaten.
- Een gewoon lid ziet een rustig scherm: geen link-knop, geen ⋮ per lid.

### Vaste schermen (in schets 015 onderaan)
- **Groep maken** (CLUB-01): bottom sheet, veld Naam (max 40 tekens, teller), knop "Groep maken" →
  rpc `create_group(p_name)`; daarna naar het groepsscherm. Server trimt de naam en weigert leeg
  (`group_name_invalid`).
- **Groepslink** (CLUB-02): beheerder maakt een `group_invites`-rij (code 8 tekens uit dezelfde
  bron als de maatjescode, patroon `^[A-HJKMNP-TW-Z2-9]{8}$`) en deelt tekst + link via het
  deelmenu, zoals de maatjescode nu (`Share.share` in `buddies_tab.dart`). "Link vervangen"
  (CLUB-09) = oude rij(en) verwijderen + nieuwe maken.
- **Landing `/group/:code`** (CLUB-02): naar het model van `/invite/:code`
  (`invite_landing_screen.dart`, `pending_invite_store.dart`): niet ingelogd → "Log in en doe mee",
  code bewaren tot na inloggen; ingelogd → rpc `redeem_group_invite`, dan naar het groepsscherm.
  Wie al lid is, komt gewoon op het groepsscherm (de rpc is idempotent).
- **Grenzen** (CLUB-18, gebouwd in 33): `group_full`, `too_many_groups`, `invite_invalid`,
  `last_admin`, `group_name_invalid` worden gewone NL/EN-zinnen met wat je kunt doen — nooit een
  foutcode.
- **Opheffen** (CLUB-11): enige handeling met een bevestigingsdialoog (onomkeerbaar; tekst noemt
  aantal leden en dat ritten met antwoorden blijven zonder label). **Verlaten** en **eruit halen**
  krijgen een snackbar met "Ongedaan maken", net als afzeggen nu (`peloton_withdraw_test.dart`).
  Ongedaan maken van verlaten = opnieuw lid worden kan alleen via een link of beheerder; dus bij
  verlaten een **bevestiging** i.p.v. undo als er geen weg terug is — kies en leg vast.
- **Laatste beheerder** (CLUB-10): wie zichzelf als enige beheerder wil degraderen, krijgt
  `last_admin` als uitleg ("Maak eerst iemand anders beheerder"). Verlaten mag wel; de bevestiging
  zegt vooraf dat het langst zittende lid beheerder wordt.

### Data en state
- Uitbreiding van `PelotonGateway` (`lib/services/peloton_gateway.dart`) met groepsmethoden, en
  providers in `lib/providers/peloton_providers.dart` (Riverpod 3 codegen, zoals de bestaande).
- Tabellen/kolommen/rpc's exact zoals in `supabase/migrations/0012_groups.sql` en
  `lib/data/remote/supabase_tables.dart`. Let op de column grants: insert op `group_members` alleen
  `(group_id, user_id)`, update alleen `role`; update op `groups` alleen `name`.
- Uitgelogd: Peloton-tab toont zoals nu "Log in om samen te fietsen"; niets van groepen.
- Alle teksten via `lib/l10n/app_nl.arb` + `app_en.arb` (CLUB-22 dekt de volledigheid in 36, maar
  nieuwe teksten gaan meteen in beide).

### Claude's Discretion
- Exacte route-namen, widgetopsplitsing, providernamen.
- Of "Maatje toevoegen" een sheet of een eigen scherm is.
- Testopzet: widgettests met een fake gateway, zoals `peloton_options_test.dart`.

</decisions>

<canonical_refs>
## Canonical References

- `.planning/sketches/015-clubs-groepen/index.html` + `README.md` — de gekozen schermen
- `supabase/migrations/0012_groups.sql` — schema, rpc's, foutsleutels (kop + FUNCTIETELLING)
- `supabase/tests/clubs_deny_test.sql` — wat wel en niet mag, per rol
- `lib/features/peloton/buddies_tab.dart`, `invite_buddies_sheet.dart`, `invite_landing_screen.dart`
- `lib/features/planned/planned_rides_screen.dart` — het scherm met de tabs Ritten/Peloton
- `lib/services/peloton_gateway.dart`, `lib/services/pending_invite_store.dart`, `lib/providers/peloton_providers.dart`
- `lib/app/router.dart` — `/invite/:code` als voorbeeld voor `/group/:code`
- `lib/theme/app_colors.dart`, `app_icons` (Phosphor) — tokens en iconen, niets hardcoded
- `.planning/PELOTON.md` — valkuilen (PWA serveert oude build; insert-returning)
- `test/features/peloton_options_test.dart`, `peloton_withdraw_test.dart` — testpatroon

</canonical_refs>

<specifics>
- Memory-regels van Joost die hier gelden: consistentie-sweep (zelfde patroon app-breed), iPhone-PWA
  heeft geen terug-gebaar (elk nieuw scherm heeft een terugknop), contrast in licht én donker meten,
  toestelverificatie via adb op de Oppo voor aanraakgedrag.
- Web/PWA: `/group/:code` moet ook als diepe link op de PWA werken (Firebase Hosting rewrite
  bestaat al voor `/invite/:code` — controleer dat dezelfde regel `/group/**` dekt).

</specifics>

<deferred>
- Groepsritten, groepslabel, groepsfilter op Ritten (CLUB-26), teller op de Peloton-tab (CLUB-25) — fase 35
- Privacybeleid, regressielijst, tweeaccountstest — fase 36
- QR voor de groepslink — Future Requirements
</deferred>

---
*Phase: 34-groep-maken-en-beheren · Context gathered: 2026-09-23 via PRD Express Path (schets 015)*
