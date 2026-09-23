# Requirements — v4.2 Clubs

**Milestone:** v4.2 Clubs (workstream `clubs`, parallel aan v4.1)
**Bron:** besluiten van Joost op 2026-09-23 — ontwerp in https://claude.ai/artifact/VLK7ktJhi4a75SALjRMN7W
**Epic:** slice 7 ("clubs") van #65 Peloton v2, `.planning/BACKLOG.md`

Groepen zijn, net als de rest van Peloton, alleen voor ingelogde gebruikers. Uitgelogd verandert er niets.

## v4.2 Requirements

### Groep en lidmaatschap (CLUB-01 … 06)

- [ ] **CLUB-01**: Een ingelogde gebruiker kan een groep aanmaken met een naam, en is daarmee lid én beheerder
- [ ] **CLUB-02**: Een beheerder kan een groepslink delen (tekst + link via het deelmenu); wie de link opent en inlogt, wordt lid
- [ ] **CLUB-03**: Een beheerder kan een bestaand maatje direct aan de groep toevoegen
- [ ] **CLUB-04**: Ieder lid ziet de groepen waar hij in zit op de Peloton-tab, met naam en aantal leden
- [ ] **CLUB-05**: Ieder lid ziet de ledenlijst van de groep, met naam en wie beheerder is — en niets anders van een ander lid (geen e-mail, instellingen of rooster)
- [ ] **CLUB-06**: Een lid kan de groep zelf verlaten

### Beheer (CLUB-07 … 11)

- [ ] **CLUB-07**: Een beheerder kan een ander lid beheerder maken, en een beheerder die rol weer afnemen
- [ ] **CLUB-08**: Een beheerder kan een lid uit de groep halen
- [ ] **CLUB-09**: Een beheerder kan de groepsnaam wijzigen, en de groepslink intrekken en vervangen door een nieuwe
- [ ] **CLUB-10**: Een groep heeft altijd minstens één beheerder: vertrekt de laatste beheerder (verlaten of account verwijderd), dan wordt het langst zittende lid beheerder; vertrekt het laatste lid, dan verdwijnt de groep
- [ ] **CLUB-11**: Een beheerder kan de groep opheffen; groepsritten die er al antwoorden op hebben blijven bestaan voor de eigenaar en wie geantwoord heeft, zonder groepslabel

### Groepsritten (CLUB-12 … 16)

- [ ] **CLUB-12**: Ieder lid kan een rit voor de hele groep uitzetten vanuit het bestaande uitnodigscherm, waar groepen boven de losse maatjes staan — met één venster of met meerdere vensters om op te stemmen
- [ ] **CLUB-13**: Een groepsrit is zichtbaar voor ieder huidig lid, ook wie na het uitzetten lid werd; wie de groep verlaat of eruit gehaald wordt, ziet de rit niet meer (tenzij hij zelf eigenaar is)
- [ ] **CLUB-14**: Ieder lid kan op een groepsrit antwoorden (ga / kan niet) en op de vensters stemmen, net als bij een gewone gedeelde rit
- [ ] **CLUB-15**: Per groepsrit ziet ieder lid wie komt, wie niet komt, wie nog niet geantwoord heeft, en wie op welk venster kan
- [ ] **CLUB-16**: Een groepsrit draagt de groepsnaam als label op Home, de Peloton-tab en het ritdetail

### Veiligheid en grenzen (CLUB-17 … 20)

- [ ] **CLUB-17**: Alle rechten hierboven worden in de database afgedwongen (RLS + plpgsql), niet alleen in de app; deny-tests bewijzen dat een buitenstaander en een ex-lid geen groep, ledenlijst of groepsrit kunnen lezen, en dat een gewoon lid geen beheerdershandeling kan doen
- [ ] **CLUB-18**: Een groep heeft maximaal 30 leden en een account zit in maximaal 10 groepen, afgedwongen in de database; de app zegt in gewone taal waarom toetreden of toevoegen niet lukt
- [ ] **CLUB-19**: Een account verwijderen (`delete_own_account`) ruimt het lidmaatschap op en laat CLUB-10 gelden, zonder dat een groep zonder beheerder achterblijft
- [ ] **CLUB-20**: De twee nieuwe server-functies (`redeem_group_invite`, `is_group_member`) zijn in hun migratie verantwoord, en de "No backend"-constraint in `CLAUDE.md` en `AGENTS.md` telt er acht

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
