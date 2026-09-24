# Phase 35: Groepsritten - Context

**Gathered:** 2026-09-24
**Status:** Ready for planning
**Source:** PRD Express Path — schets 016 (gekozen door Joost 2026-09-24) + `.planning/workstreams/clubs/REQUIREMENTS.md`

<domain>
## Phase Boundary

Een lid zet een rit uit voor de hele groep; ieder huidig lid ziet, beantwoordt en stemt; de
groepsnaam staat op de rit; een teller laat zien waar nog een antwoord op wacht; en de Ritten-tab
filtert op groep. Requirements: CLUB-12, 13, 14, 15, 16, 25, 26.

Het schema staat live (0012 + 0013, deny-tests 81/83/62 groen): `group_rides.group_id`,
`is_ride_member()` telt huidige groepsleden mee, een lid mag zijn **eigen** participant-rij
invoegen op een groepsrit (`group_ride_participants_insert_self_group`), stemmen werkt via
`is_ride_member`. **Geen migratie verwacht**; blijkt er toch iets te ontbreken, dan stoppen en
melden (0014 met checkpoint voor Joost), niet stil SQL toevoegen.

Buiten deze fase: meldingen (branch `meldingen`, backlog #77B/#74 — loopt parallel in een andere
worktree; raak `lib/platform/background_task.dart` en `notification_service.dart` niet aan),
regressielijst en tweeaccountstest (fase 36).

</domain>

<decisions>
## Implementation Decisions (locked)

### Uitnodigen (CLUB-12) — schets 016, vast
- In het bestaande uitnodigscherm (`invite_buddies_sheet.dart`) staat bovenaan een sectie
  **"Een groep"** met je groepen (kenteken, naam, "N leden"), kiesbaar met één keuze (radio).
  Daaronder **"Of losse maatjes"** zoals nu.
- Een groep kiezen **schakelt de losse maatjes uit** (grijs, niet aan te vinken), en omgekeerd.
  Reden: op een groepsrit geeft een participant-rij van een niet-lid géén toegang (0012), dus
  buitenstaanders erbij is geen optie.
- Daarna het bestaande vensterscherm: één venster of meerdere om op te stemmen.
- Ieder lid mag dit (niet alleen beheerders). Aanmaken: `group_rides` met `group_id`; er worden
  **geen** participant-rijen voor de leden aangemaakt (geen momentopname) — alleen de eigenaar
  krijgt wat de bestaande flow hem nu geeft.
- Wie in geen groep zit, ziet het scherm precies zoals nu.

### Zichtbaarheid en antwoorden (CLUB-13, CLUB-14)
- Een groepsrit verschijnt bij ieder huidig lid zoals een openstaande uitnodiging nu: dezelfde
  knoppen **"Ik ga mee" / "Kan niet"** op de kaart en in het detail; stemmen per venster zoals nu.
- Antwoorden = eigen participant-rij invoegen (eerste keer) of bijwerken (daarna).
- Wie de groep verlaat, ziet de rit niet meer (de database regelt dat; de app ververst na
  verlaten — dat gebeurt al sinds 34-06).
- Afzeggen/ongedaan maken volgt het bestaande patroon (`peloton_withdraw_test.dart`).

### Wie komt (CLUB-15)
- Ritdetail van een groepsrit: lijst per lid met **gaat mee / kan niet / nog niet geantwoord**
  ("nog niet geantwoord" = huidige leden zonder participant-rij), plus een telregel
  "2 gaan mee · 1 kan niet · 2 nog niet". Bij meerdere vensters per venster wie kan, zoals nu.

### Groepsnaam (CLUB-16) — schets 016, vraag 2: **B**
- Op ritkaarten (Home onder PLANNED, Ritten-tab, Peloton) staat de groepsnaam **vooraan in de
  bestaande rolregel** (`RideRoleLine` / `ride_role_style.dart`, schets 014): "On the Roll · Anna
  organiseert · 2 gaan mee". **Geen extra regel; de kaart wordt niet hoger dan nu.**
- Joost: *"Het moet passen op het scherm, dat is het belangrijkste."* Lange groepsnamen worden
  afgekapt met ellips; de regel blijft één regel. Test op **360 dp** breed en met grote
  tekstschaal: geen overflow, kaarthoogte gelijk aan een gewone gedeelde rit.
- Op het **ritdetail** staat de groepsnaam wél als chip bovenaan (daar is ruimte).

### Teller (CLUB-25) — schets 016, vraag 1: **A**
- Aantal ritten waarop jij nog niet geantwoord hebt: openstaande losse uitnodigingen (status
  `invited`) + groepsritten van je groepen zonder jouw participant-rij, alleen in de toekomst.
- Getoond als **rood bolletje met getal op "Ritten" in de onderbalk** (`scaffold_with_nav.dart`,
  M3 `Badge`) **én** als getal bij de tab **Peloton** in Mijn Ritten. Bij 0: niets.
- Voor een beheerder telt het aantal open **aanvragen** (34-05, al op de groepskaart) hier niet
  mee — dat blijft op de groepskaart. (Aanname; vraag Joost als dit in de plan-review wringt.)

### Filter (CLUB-26) — schets 015 variant C
- Ritten-tab: rij chips **"Alles" + één per groep** (kenteken + naam) boven de rittenlijst,
  **alleen als je in minstens één groep zit**. Zonder groepen staat de rij er niet.
- Een chip filtert de lijst op ritten van die groep; "Alles" toont alles. Lang indrukken opent het
  groepsscherm. Horizontaal scrollbaar; past op 360 dp.

### Algemeen
- Teksten NL + EN via ARB; kleuren via theme-tokens (licht én donker); iconen via AppIcons.
- Fouten via `groupErrorTextOf` waar het een groepsfout is.
- Analytics zonder namen of id's (zoals 34).

### Claude's Discretion
- Hoe groepsritten in `RideEntry` / `peloton_providers.dart` samenkomen (nieuwe categorie of
  bestaande `joinedGroupRides`/`pendingRideInvites` uitbreiden), zolang Home, Ritten, Agenda en
  widget ze consistent tonen en niets dubbel verschijnt.
- Widgetopsplitsing en providernamen.

</decisions>

<canonical_refs>
## Canonical References

- `.planning/sketches/016-groepsritten/index.html` + `README.md` — gekozen schermen
- `.planning/sketches/014-peloton-rij/` — de rolregel waarin de groepsnaam komt
- `.planning/sketches/015-clubs-groepen/README.md` — variant C (filter)
- `supabase/migrations/0012_groups.sql`, `0013_group_join_requests.sql` — policies voor groepsritten
- `supabase/tests/clubs_deny_test.sql` — checks 2.14–2.18, 4.4, 4.9–4.13, 7.x (wat mag op groepsritten)
- `lib/features/peloton/invite_buddies_sheet.dart`, `lib/features/detail/ride_detail_screen.dart`,
  `lib/features/planned/planned_rides_screen.dart`, `lib/features/home/home_screen.dart`,
  `lib/features/shared/ride_role_style.dart`, `peloton_counter.dart`, `lib/app/scaffold_with_nav.dart`
- `lib/providers/peloton_providers.dart`, `ride_entries_provider.dart`, `lib/domain/models/peloton.dart`,
  `ride_entry.dart`, `lib/services/peloton_gateway.dart`
- `.planning/workstreams/clubs/phases/34-groep-maken-en-beheren/34-03-SUMMARY.md` — groepsmodellen/providers
- `.planning/PELOTON.md` — valkuilen (insert-returning; accepted rit nergens zichtbaar — de fout
  van 2026-09-07 mag hier niet terugkomen)
- Tests: `test/features/peloton_options_test.dart`, `peloton_withdraw_test.dart`, `rides_roles_test.dart`,
  `test/helpers/fake_group_gateway.dart`

</canonical_refs>

<specifics>
- Joosts regels: consistentie-sweep (overal waar een gedeelde rit staat, staat een groepsrit
  hetzelfde), contrast in licht én donker, toestelcheck via adb op de Oppo (build via Play internal,
  zoals 34-08 — Joost koos daar option-b).
- De live webapp draait sinds 2026-09-24 build 1.0.43-lijn met groepen; een nieuwe webdeploy of
  Play-upload in deze fase alleen met Joosts akkoord in de checkpoint.
</specifics>

<deferred>
- Meldingen bij een nieuwe groepsrit — backlog #77B/#74 (branch `meldingen`)
- Terugkerende groepsrit, nieuwe leden seinen — Future Requirements
</deferred>

---
*Phase: 35-groepsritten · Context gathered: 2026-09-24 via PRD Express Path (schets 016)*
