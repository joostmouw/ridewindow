# Roadmap: Clubs (v4.2, workstream `clubs`)

## Overview

Clubs is slice 7 van epic #65 "Peloton v2" en bouwt voort op de bestaande Peloton-schema's (`0002_peloton.sql` — vriendschappen, gedeelde ritten; `0010_group_ride_options.sql` — vensters en stemmen). Net als de rest van de app wordt dit van binnen naar buiten gebouwd: eerst het datamodel en de rechten in de database (migratie 0012, RLS, twee nieuwe `plpgsql`-functies), dan het scherm waarmee een groep ontstaat en beheerd wordt, dan de groepsrit zelf bovenop het bestaande uitnodig-/stemmechanisme, en tot slot de afronding (privacybeleid, i18n, regressie, twee-accountstest) die nodig is voordat de build bij de testers staat.

Deze workstream loopt **parallel** aan v4.1 ("Zo snel mogelijk live in de store"), dat op de veertien-dagenklok wacht. Fasenummering gaat door na v4.1's laatste fase (32) — Clubs begint bij fase 33.

## Milestones

- 🚧 **v4.2 Clubs** — Phases 33–36 (in progress, gestart 2026-09-23) — zie `.planning/PROJECT.md` sectie "Parallel Milestone: v4.2 Clubs" en `.planning/workstreams/clubs/REQUIREMENTS.md`.

## Phases

**Phase Numbering:** Gaat door na v4.1 fase 32; deze workstream gebruikt 33–36.

- [x] **Phase 33: Datamodel en rechten** - Migratie 0012 legt groepen, lidmaatschap en rechten vast in de database, afgedwongen door RLS en twee nieuwe functies — niets hoeft de app zelf te controleren (completed 2026-09-23)
- [ ] **Phase 34: Groep maken en beheren** - Een ingelogde gebruiker maakt een groep, deelt de link, beheert leden en beheerders, en ziet zijn groepen op de Peloton-tab
- [ ] **Phase 35: Groepsritten** - Een lid zet een rit uit voor de hele groep; ieder lid ziet en beantwoordt hem, met een groepslabel overal waar de rit verschijnt
- [ ] **Phase 36: Afronden** - Privacybeleid, NL/EN, regressie en een tweeaccountstest op toestel en PWA voordat de build bij de testers staat

## Phase Details

### Phase 33: Datamodel en rechten

**Goal**: De database kent groepen en lidmaatschap, en dwingt zelf af wie een groep, ledenlijst of groepsrit mag lezen en wie een beheerdershandeling mag doen — de app hoeft hier niets zelf te bewaken.
**Depends on**: Nothing (bouwt voort op de bestaande Peloton-schema's `0002_peloton.sql` en `0010_group_ride_options.sql`)
**Requirements**: CLUB-10, CLUB-17, CLUB-18, CLUB-19, CLUB-20
**Success Criteria** (what must be TRUE):

  1. Migratie 0012 (groepen, lidmaatschap, RLS, `redeem_group_invite()`, `is_group_member()`, en `is_ride_member()` uitgebreid met groepsleden) is toegepast op de live database — checkpoint, door Joost
  2. Geautomatiseerde deny-tests bewijzen dat een buitenstaander en een ex-lid geen groep, ledenlijst of groepsrit kunnen lezen, en dat een gewoon lid geen beheerdershandeling kan uitvoeren (CLUB-17)
  3. De database weigert een 31e lid in een groep en een 11e groep voor een account, met een foutmelding die de app in gewone taal kan tonen (CLUB-18)
  4. Verliest een groep zijn laatste beheerder (verlaten, verwijderd of account weg), dan wordt automatisch het langst zittende lid beheerder; verliest een groep zijn laatste lid, dan verdwijnt de groep (CLUB-10)
  5. `delete_own_account` ruimt lidmaatschappen op zonder een groep zonder beheerder achter te laten, en de twee nieuwe functies zijn in de migratie verantwoord met `CLAUDE.md`/`AGENTS.md` bijgewerkt naar acht server-functies (CLUB-19, CLUB-20) (bijgesteld 2026-09-23 per 33-CONTEXT 'De telling volgt het schema': 0012 voegt vijf functies toe — ook create_group en de triggerfuncties guard_group_member_insert en ensure_group_admin — en de telling wordt elf; zie de kop van 0012)

**Plans**: 3 plans
- [x] 33-01-PLAN.md — migratie 0012_groups.sql: tabellen, RLS, grants, vijf nieuwe functies (grenzen, opvolging, create_group, redeem_group_invite, is_group_member)
- [x] 33-02-PLAN.md — deny-test supabase/tests/clubs_deny_test.sql (buitenstaander, lid, beheerder, ex-lid, 30/10, opvolging, account weg, opheffen)
- [x] 33-03-PLAN.md — functietelling in CLAUDE.md/AGENTS.md + [BLOCKING] Joost draait 0012 en de deny-test live
**Manual steps**: migratie 0012 moet door Joost op de live database worden toegepast (checkpoint, criterium 1) voordat fase 34 tegen echte data kan draaien.

### Phase 34: Groep maken en beheren

**Goal**: Een ingelogde gebruiker maakt een groep aan, deelt hem, beheert leden en beheerders, en ziet zijn groepen terug op de Peloton-tab — de hele levenscyclus van een groep, los van groepsritten.
**Depends on**: Phase 33
**Requirements**: CLUB-01, CLUB-02, CLUB-03, CLUB-04, CLUB-05, CLUB-06, CLUB-07, CLUB-08, CLUB-09, CLUB-11, CLUB-27, CLUB-28
**Success Criteria** (what must be TRUE):

  1. Een ingelogde gebruiker maakt een groep met een naam aan en is daarmee meteen lid en beheerder; de groep verschijnt op de Peloton-tab met naam en aantal leden (CLUB-01, CLUB-04)
  2. Ieder lid deelt een groepslink via het bestaande deelmenu; wie de link opent (`/group/:code`) en inlogt dient een aanvraag in en ziet dat die bij de beheerders ligt; na acceptatie ziet hij de ledenlijst met naam en wie beheerder is, en verder niets van een ander lid (CLUB-02, CLUB-05) (bijgesteld 2026-09-23 per 34-CONTEXT HERZIENING)
  3. Ieder lid draagt een bestaand maatje voor; een beheerder die voordraagt maakt hem direct lid (CLUB-03) (bijgesteld 2026-09-23 per 34-CONTEXT HERZIENING)
  4. Een lid verlaat de groep zelf; een beheerder maakt een ander lid beheerder of neemt die rol weer af, en kan een lid uit de groep verwijderen (CLUB-06, CLUB-07, CLUB-08)
  5. Een beheerder wijzigt de groepsnaam, trekt de groepslink in voor een nieuwe, of heft de groep op — groepsritten die al antwoorden hebben blijven bestaan voor de eigenaar en wie geantwoord heeft, maar zonder groepslabel (CLUB-09, CLUB-11)
  6. Een beheerder ziet de open aanvragen (via link of voorgedragen door wie) en accepteert of wijst af; een gewoon lid kan niemand lid maken, afgedwongen door migratie 0013 en bewezen met deny-tests die Joost live draait (CLUB-27)
  7. Een info-knop bij Groepen op de Peloton-tab en op het groepsscherm legt de groepsregels uit in NL en EN (CLUB-28)

**Plans**: 8 plans
- [x] 34-01-PLAN.md — migratie 0013_group_join_requests.sql (aanvragen, voordragen, accepteren, links voor leden) + functietelling naar dertien
- [x] 34-02-PLAN.md — deny-tests (nieuw + 0012-test bijgewerkt) + [BLOCKING] Joost past 0013 toe en draait beide live
- [x] 34-03-PLAN.md — datalaag: modellen, gateway, providers, foutsleutels als gewone zinnen
- [x] 34-04-PLAN.md — Groepen op de Peloton-tab, groep maken, groepsscherm (leesstand, aanvraagstaat), regelsheet
- [x] 34-05-PLAN.md — ⋮ per lid, eruit halen met ongedaan maken, aanvragen accepteren/afwijzen, maatje voordragen
- [x] 34-06-PLAN.md — groepslink delen, appbar-menu: naam, link vervangen, verlaten, opheffen
- [ ] 34-07-PLAN.md — landing /group/:code, code bewaren tot na inloggen en onboarding, code in het codeveld
- [ ] 34-08-PLAN.md — toestel + web met twee accounts (keuze testroute, checkpoint Joost)
**Manual steps**: 0013 en de deny-tests draait Joost in de SQL Editor (34-02); de doorloop met twee accounts doet Joost (34-08).
**UI hint**: yes

### Phase 35: Groepsritten

**Goal**: Een lid zet een rit uit voor de hele groep in plaats van losse maatjes, en ieder lid ziet en beantwoordt die rit net als een gewone gedeelde rit — met de groep zichtbaar als label waar de rit ook verschijnt.
**Depends on**: Phase 34
**Requirements**: CLUB-12, CLUB-13, CLUB-14, CLUB-15, CLUB-16, CLUB-25, CLUB-26
**Success Criteria** (what must be TRUE):

  1. Ieder lid zet vanuit het bestaande uitnodigscherm een rit uit voor de hele groep — groepen staan daar boven de losse maatjes — met één venster of meerdere vensters om op te stemmen (CLUB-12)
  2. De groepsrit is zichtbaar voor ieder huidig lid, ook wie er later lid van werd; wie de groep verlaat of eruit gehaald wordt ziet de rit niet meer, tenzij hij zelf eigenaar is (CLUB-13)
  3. Ieder lid antwoordt op de groepsrit (ga / kan niet) en stemt op de vensters, net als bij een gewone gedeelde rit (CLUB-14)
  4. Per groepsrit ziet ieder lid wie komt, wie niet komt, wie nog niet geantwoord heeft, en wie op welk venster kan (CLUB-15)
  5. De groepsrit draagt de groepsnaam als label op Home, de Peloton-tab en het ritdetail (CLUB-16)
  6. De Peloton-tab toont een teller met het aantal ritten waarop je nog niet geantwoord hebt, losse uitnodigingen én groepsritten samen (CLUB-25)
  7. Wie in een groep zit, filtert de Ritten-tab met groepschips; zonder groepen staat die rij er niet (CLUB-26)

**Plans**: TBD
**UI hint**: yes

### Phase 36: Afronden

**Goal**: Clubs is juridisch, taalkundig en functioneel af — het privacybeleid klopt, alle teksten bestaan in twee talen, de bestaande Peloton-stromen zijn aantoonbaar ongebroken, en twee echte accounts hebben de hele keten doorlopen — voordat de build bij de testers staat.
**Depends on**: Phase 35
**Requirements**: CLUB-21, CLUB-22, CLUB-23, CLUB-24
**Success Criteria** (what must be TRUE):

  1. Het privacybeleid vermeldt in NL en EN dat groepsleden elkaars naam en hun antwoord op groepsritten zien (CLUB-21)
  2. Alle nieuwe teksten (groepenscherm, foutmeldingen, labels) bestaan in NL en EN (CLUB-22)
  3. Een regressielijst legt de bestaande Peloton-stromen vast (maatje worden via code, losse gedeelde rit, stemmen); de volledige geautomatiseerde testsuite is groen (CLUB-23)
  4. Twee echte accounts doorlopen de hele keten op toestel én PWA — groep maken, lid worden via link, beheerder maken, groepsrit uitzetten, antwoorden, verlaten — en de build staat bij de testers (CLUB-24)

**Plans**: TBD
**Manual steps**: de tweeaccountstest (criterium 4) is een handmatige verificatie op een echt toestel en de live PWA, door Joost, net als de eerdere Peloton-tweeaccountstest (zie `.planning/PELOTON.md`).

## Progress

**Execution Order:** Phases execute in numeric order: 33 → 34 → 35 → 36 (parallel aan v4.1's 26 → 32)

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 33. Datamodel en rechten | 3/3 | Complete    | 2026-09-23 |
| 34. Groep maken en beheren | 6/8 | In Progress|  |
| 35. Groepsritten | 0/TBD | Not started | - |
| 36. Afronden | 0/TBD | Not started | - |
