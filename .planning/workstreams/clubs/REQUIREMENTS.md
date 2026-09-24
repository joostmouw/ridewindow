# Requirements — v4.2 Clubs

**Milestone:** v4.2 Clubs (workstream `clubs`, parallel aan v4.1)
**Bron:** besluiten van Joost op 2026-09-23 — ontwerp in https://claude.ai/artifact/VLK7ktJhi4a75SALjRMN7W
**Epic:** slice 7 ("clubs") van #65 Peloton v2, `.planning/BACKLOG.md`

Groepen zijn, net als de rest van Peloton, alleen voor ingelogde gebruikers. Uitgelogd verandert er niets.

## v4.2 Requirements

### Groep en lidmaatschap (CLUB-01 … 06)

- [x] **CLUB-01**: Een ingelogde gebruiker kan een groep aanmaken met een naam, en is daarmee lid én beheerder
- [ ] **CLUB-02**: Ieder lid kan de groepslink delen (tekst + link via het deelmenu); wie de link opent en inlogt, dient daarmee een **aanvraag** in en ziet "wacht op goedkeuring" tot een beheerder beslist *(herzien 2026-09-23: was "een beheerder deelt, wie opent wordt lid")*
- [x] **CLUB-03**: Ieder lid kan een bestaand maatje **voordragen**; een beheerder die een maatje voordraagt, maakt hem direct lid *(herzien 2026-09-23: was "een beheerder voegt direct toe")*
- [x] **CLUB-04**: Ieder lid ziet de groepen waar hij in zit op de Peloton-tab, met naam en aantal leden
- [x] **CLUB-05**: Ieder lid ziet de ledenlijst van de groep, met naam en wie beheerder is — en niets anders van een ander lid (geen e-mail, instellingen of rooster)
- [x] **CLUB-06**: Een lid kan de groep zelf verlaten

### Beheer (CLUB-07 … 11, 27, 28)

- [x] **CLUB-27**: Een beheerder ziet de openstaande aanvragen van zijn groep (via link of voorgedragen, met wie voordroeg) en kan elke aanvraag **accepteren** (wordt lid, binnen de grens van 30) of **afwijzen**; een gewoon lid kan niemand zelf lid maken — afgedwongen in de database, bewezen met deny-tests (besluit Joost 2026-09-23)
- [x] **CLUB-28**: Bij de groepen staat een info-knop, zoals de bestaande info-knoppen in de app, die de regels van een groep uitlegt: wie mag voordragen en wie accepteert, maximaal 30 leden per groep en 10 groepen per persoon, wat leden van elkaar zien, wie groepsritten ziet, wat er gebeurt bij verlaten en bij de laatste beheerder, en opheffen (besluit Joost 2026-09-23)
- [x] **CLUB-07**: Een beheerder kan een ander lid beheerder maken, en een beheerder die rol weer afnemen
- [x] **CLUB-08**: Een beheerder kan een lid uit de groep halen
- [x] **CLUB-09**: Een beheerder kan de groepsnaam wijzigen, en de groepslink intrekken en vervangen door een nieuwe
- [x] **CLUB-10**: Een groep heeft altijd minstens één beheerder: vertrekt de laatste beheerder (verlaten of account verwijderd), dan wordt het langst zittende lid beheerder; vertrekt het laatste lid, dan verdwijnt de groep
- [x] **CLUB-11**: Een beheerder kan de groep opheffen; groepsritten die er al antwoorden op hebben blijven bestaan voor de eigenaar en wie geantwoord heeft, zonder groepslabel

### Groepsritten (CLUB-12 … 16, 25, 26)

- [ ] **CLUB-12**: Ieder lid kan een rit voor de hele groep uitzetten vanuit het bestaande uitnodigscherm, waar groepen boven de losse maatjes staan — met één venster of met meerdere vensters om op te stemmen
- [ ] **CLUB-13**: Een groepsrit is zichtbaar voor ieder huidig lid, ook wie na het uitzetten lid werd; wie de groep verlaat of eruit gehaald wordt, ziet de rit niet meer (tenzij hij zelf eigenaar is)
- [ ] **CLUB-14**: Ieder lid kan op een groepsrit antwoorden (ga / kan niet) en op de vensters stemmen, net als bij een gewone gedeelde rit
- [ ] **CLUB-15**: Per groepsrit ziet ieder lid wie komt, wie niet komt, wie nog niet geantwoord heeft, en wie op welk venster kan
- [ ] **CLUB-16**: Een groepsrit draagt de groepsnaam als label op Home, de Peloton-tab en het ritdetail
- [ ] **CLUB-25**: De Peloton-tab toont een teller met het aantal ritten waarop je nog niet geantwoord hebt (losse uitnodigingen én groepsritten), zodat een uitnodiging opvalt zonder dat je de tab opent — optie A uit backlog #77, gekozen door Joost op 2026-09-23
- [ ] **CLUB-26**: Wie in minstens één groep zit, ziet op de Ritten-tab een rij groepschips ("Alles" + één per groep) waarmee hij de lijst op één groep filtert; lang indrukken opent de groep. Zonder groepen staat de rij er niet — schets 015 variant C, gekozen door Joost op 2026-09-23

### Veiligheid en grenzen (CLUB-17 … 20)

- [x] **CLUB-17**: Alle rechten hierboven worden in de database afgedwongen (RLS + plpgsql), niet alleen in de app; deny-tests bewijzen dat een buitenstaander en een ex-lid geen groep, ledenlijst of groepsrit kunnen lezen, en dat een gewoon lid geen beheerdershandeling kan doen
- [x] **CLUB-18**: Een groep heeft maximaal 30 leden en een account zit in maximaal 10 groepen, afgedwongen in de database; de app zegt in gewone taal waarom toetreden of toevoegen niet lukt
- [x] **CLUB-19**: Een account verwijderen (`delete_own_account`) ruimt het lidmaatschap op en laat CLUB-10 gelden, zonder dat een groep zonder beheerder achterblijft
- [x] **CLUB-20**: De twee nieuwe server-functies (`redeem_group_invite`, `is_group_member`) zijn in hun migratie verantwoord, en de "No backend"-constraint in `CLAUDE.md` en `AGENTS.md` telt er acht (bijgesteld 2026-09-23 per 33-CONTEXT 'De telling volgt het schema': 0012 voegt vijf functies toe — ook create_group en de triggerfuncties guard_group_member_insert en ensure_group_admin — en de telling wordt elf; zie de kop van 0012)

### Afronding (CLUB-21 … 24)

- [ ] **CLUB-21**: Het privacybeleid vermeldt dat groepsleden elkaars naam en elkaars antwoord op groepsritten zien
- [ ] **CLUB-22**: Alle nieuwe teksten bestaan in NL en EN
- [ ] **CLUB-23**: De bestaande Peloton-stromen (maatje worden via code, losse gedeelde rit, stemmen) werken ongewijzigd — vastgelegd in een regressielijst, volledige suite groen
- [ ] **CLUB-24**: Twee echte accounts doorlopen de hele keten op toestel en PWA (groep maken, lid worden via link, beheerder maken, groepsrit uitzetten, antwoorden, verlaten), en de build staat bij de testers

## Future Requirements

- Terugkerende groepsrit ("elke dinsdag 07:00") — eigen backlogpunt, logische volgende stap
- Nieuwe leden automatisch melden bij lopende groepsritten (nu zien ze de rit wel, maar krijgen geen seintje)
- QR-code voor de groepslink (slice 5 van #65)
- Meerdere groepen tegelijk uitnodigen voor één rit

## Out of Scope

| Wat | Waarom |
|-----|--------|
| Chat per groep | WhatsApp heeft dat gewonnen; de deelknop gaat daarheen |
| Pushmeldingen naar leden | Vraagt een betaalde dienst of server-code; botst met €0/maand en "alleen plpgsql" |
| Gedeelde beschikbaarheid (rooster) binnen de groep | Slice 3 van #65; het rooster uit Profiel blijft privé |
| Groep zoeken of openbare groepen | Zelfde lek als zoeken op e-mail ([[62]]): de link is de capability |
| Groepen voor uitgelogde gebruikers | Peloton vereist een account (besluit 2026-09-19) |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CLUB-01 | Phase 34 | Complete |
| CLUB-02 | Phase 34 | Pending |
| CLUB-03 | Phase 34 | Complete |
| CLUB-04 | Phase 34 | Complete |
| CLUB-05 | Phase 34 | Complete |
| CLUB-06 | Phase 34 | Complete |
| CLUB-07 | Phase 34 | Complete |
| CLUB-08 | Phase 34 | Complete |
| CLUB-09 | Phase 34 | Complete |
| CLUB-10 | Phase 33 | Complete |
| CLUB-11 | Phase 34 | Complete |
| CLUB-12 | Phase 35 | Pending |
| CLUB-13 | Phase 35 | Pending |
| CLUB-14 | Phase 35 | Pending |
| CLUB-15 | Phase 35 | Pending |
| CLUB-16 | Phase 35 | Pending |
| CLUB-17 | Phase 33 | Complete |
| CLUB-18 | Phase 33 | Complete |
| CLUB-19 | Phase 33 | Complete |
| CLUB-20 | Phase 33 | Complete |
| CLUB-21 | Phase 36 | Pending |
| CLUB-22 | Phase 36 | Pending |
| CLUB-23 | Phase 36 | Pending |
| CLUB-24 | Phase 36 | Pending |
| CLUB-25 | Phase 35 | Pending |
| CLUB-26 | Phase 35 | Pending |
| CLUB-27 | Phase 34 | Complete |
| CLUB-28 | Phase 34 | Complete |
