# Requirements — Milestone v4.1 Zo snel mogelijk live in de store

**Defined:** 2026-09-10
**Core Value:** Accurate cyclist-specific weather scoring translated into concrete bookable time slots.
**Milestone goal:** Ridewindow staat in productie op Google Play, via een gesloten test met testers die de app werkelijk gebruiken.
**Neemt op:** epic #71 "Twaalf testers" (`.planning/TESTERS.md`).
**Vorige requirements:** v3.0 staat in `.planning/milestones/v3.0-REQUIREMENTS.md`.

**Leidend principe:** de klok van veertien dagen start pas bij twaalf aangemelde testers, en pauzeert of reset als het aantal daaronder zakt. Wat de werving vervroegt gaat vóór; wat haar niet raakt mag parallel lopen, maar nooit ervoor in de weg staan.

**Wat Google meet (stand 2026):** sinds april 2026 worden aanvragen afgewezen op gebrek aan gebruik door testers — aanmelden en installeren is niet genoeg. Alleen aanmelden via de Play-link telt; een gesideloade APK telt niet. De aanvraag stelt ongeveer negen vragen (werving, feedback, wat je veranderde, waarom de app klaar is) en vage antwoorden worden afgewezen.

---

## v4.1 Requirements

### Console (CON)

- [ ] **CON-01**: Elke build gaat eerst naar internal testing, wordt vanaf een Play-installatie op de Oppo getest, en pas daarna gepromoot naar de gesloten test — nooit rechtstreeks
- [ ] **CON-02**: Een tester in elk land waar Google Play beschikbaar is kan zich aanmelden voor de gesloten test
- [ ] **CON-03**: Een tester ziet in Play een feedback-adres dat bij Ridewindow hoort
- [ ] **CON-04**: Een tester meldt zich aan via één vaste link — een Google Group is gekoppeld aan de gesloten test
- [ ] **CON-05**: Een bezoeker met Nederlands als Play-taal ziet de winkelpagina in het Nederlands (nl-NL)
- [ ] **CON-06**: PWA, gepubliceerd privacybeleid en GitHub `main` tonen dezelfde versie en naam (Ridewindow) als de laatste Play-build

### Werving (WERV)

- [ ] **WERV-01**: Voor elk kandidaat-kanaal — eigen LinkedIn-post, LinkedIn-vacature "vrijwillige tester", Strava-clubs, NTFU-toerclubs, fiets-Facebookgroepen, collega's, r/AndroidClosedTesting — is vastgelegd: bereik, doorlooptijd, doelgroepgehalte, inspanning voor Joost, en wat ervaringen van anderen laten zien; de uitkomst is een gemotiveerde keuze voor 2–3 kanalen
- [ ] **WERV-02**: Per gekozen kanaal ligt een verzendklare tekst (NL en/of EN) die de veertien dagen, het regelmatig openen, en het waarom uitlegt
- [ ] **WERV-03**: Zes testers uit de eigen kring zijn persoonlijk uitgenodigd en staan als aangemeld in Google's eigen teller
- [ ] **WERV-04**: Google's teller toont minstens 15 aangemelde testers (12 plus buffer)
- [ ] **WERV-05**: Een testerslijst houdt per tester bij: bron, aanmelddatum en laatste teken van gebruik; een afhaker wordt binnen twee dagen opgemerkt en vervangen

### Feedback (FEED)

- [ ] **FEED-01**: Alle feedback — in-app, Play-testerfeedback, WhatsApp, mail — komt in één register met vaste velden: bron, tester, app-versie, scherm, soort (fout / verwarring / wens / lof), ernst en status
- [ ] **FEED-02**: Het in-app feedbackformulier vraagt gestructureerd (soort, en wat de tester verwachtte) en voegt app-versie en scherm automatisch toe
- [ ] **FEED-03**: De app vraagt een tester op een natuurlijk moment om feedback — niet tijdens de eerste minuut, en niet vaker dan een vaste grens — in plaats van alleen via Profiel → Over
- [ ] **FEED-04**: Een vaste beoordelingsronde geeft elke open melding een uitkomst: nieuw backlog-item met prioriteit, duplicaat van een bestaand item, of bewust niet met reden — geen melding blijft zonder uitkomst
- [ ] **FEED-05**: Een tester hoort terug wat er met zijn melding is gebeurd en in welke versie het is opgelost; die koppeling voedt de changelog (PROOF-01)

### Eerste minuut (EERST)

- [ ] **EERST-01**: Een nieuwe gebruiker die zijn week niet invult, ziet toch een bruikbaar scherm dat hem naar het invullen leidt in plaats van een lege app
- [ ] **EERST-02**: Een nieuwe gebruiker krijgt niet meer dan één uitlegoverlay voordat hij zelf iets in de app heeft gedaan
- [ ] **EERST-03**: Notificaties verschijnen in de taal van de app (backlog #67)

### Vensters (WIN)

- [ ] **WIN-01**: Per dag ziet de gebruiker het aaneengesloten goede blok, met het beste venster daarin gemarkeerd (backlog #69)
- [ ] **WIN-02**: De gebruiker kan zien waarom dit venster is gekozen en niet het venster ernaast, inclusief de score van dat alternatief (backlog #70)

### Bewijs (PROOF)

- [ ] **PROOF-01**: Een changelog per build, vanaf build 41, legt vast: versie, datum, track, inhoud, en welke tester-feedback ermee is opgelost
- [ ] **PROOF-02**: Tijdens de veertien dagen gaan minstens drie builds naar de gesloten test
- [ ] **PROOF-03**: De productie-aanvraag is ingediend; elk antwoord is minstens 250 tekens en noemt concrete versies en fixes uit de changelog
- [ ] **PROOF-04**: Ridewindow is installeerbaar uit de Play Store in productie

## Future Requirements (deferred)

- **Peloton v2** (#65) — meekijken zonder account, gedeelde beschikbaarheid, maatjes via gebruikersnaam
- **iPhone-tester komt niet terug uit beschikbaarheid** (#63) — vraagt een iPhone
- **Afgezegde ritten onbereikbaar** (#66)
- **Lanceringsmarketing** — een eigen epic na productie
- **Radii als systeem, `ScoreBadge` naast `ScoreDisplay`** — losse einden uit v4.0

## Out of Scope

| Feature | Reason |
|---------|--------|
| Betaalde testdiensten (BetaTesting e.d.) | Breekt de expliciete €0/maand-grens uit `CLAUDE.md`; pas heroverwegen als de gratis route na twee weken vastloopt |
| Testers via ruilnetwerken als hoofdroute | Levert aanmeldingen zonder gebruik — precies waar Google sinds april 2026 op afwijst; hooguit opvulling |
| Analytics of tracking om gebruik te meten | "Geen tracking" is een belofte in de winkeltekst en het privacybeleid; gebruik volgen gaat via de testerslijst en Google's eigen teller |
| Feedback lezen via een service-role-sleutel in een script | Sleutels met volledige rechten horen niet op een laptop in een side-project; het register leest uit het dashboard of een export |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CON-01 | Phase 26 | Pending |
| CON-02 | Phase 26 | Pending |
| CON-03 | Phase 26 | Pending |
| CON-04 | Phase 26 | Pending |
| CON-05 | Phase 26 | Pending |
| CON-06 | Phase 26 | Pending |
| PROOF-01 | Phase 26 | Pending |
| WERV-01 | Phase 27 | Pending |
| WERV-02 | Phase 27 | Pending |
| FEED-01 | Phase 28 | Pending |
| FEED-02 | Phase 28 | Pending |
| FEED-03 | Phase 28 | Pending |
| FEED-04 | Phase 28 | Pending |
| FEED-05 | Phase 28 | Pending |
| EERST-01 | Phase 29 | Pending |
| EERST-02 | Phase 29 | Pending |
| EERST-03 | Phase 29 | Pending |
| WERV-03 | Phase 30 | Pending |
| WERV-04 | Phase 30 | Pending |
| WERV-05 | Phase 30 | Pending |
| WIN-01 | Phase 31 | Pending |
| WIN-02 | Phase 31 | Pending |
| PROOF-02 | Phase 31 | Pending |
| PROOF-03 | Phase 32 | Pending |
| PROOF-04 | Phase 32 | Pending |

**Coverage:**
- v4.1 requirements: 25 total
- Mapped to phases: 25
- Unmapped: 0

---
*Requirements defined: 2026-09-10*
*Last updated: 2026-09-10 after milestone v4.1 start*
