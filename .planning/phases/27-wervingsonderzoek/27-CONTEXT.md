# Phase 27: Wervingsonderzoek - Context

**Gathered:** 2026-09-20
**Status:** Ready for planning
**Source:** Vragen opgevangen tijdens /gsd:plan-phase 27 (de twee Open Questions uit 27-RESEARCH.md die alleen Joost kon beantwoorden, plus een koerswijziging die hij tijdens dezelfde ronde meegaf)

<domain>
## Phase Boundary

Deze fase levert papier, geen aanmeldingen. Drie dingen: (1) een onderbouwde vergelijking van minstens zeven kandidaat-kanalen op bereik, doorlooptijd, doelgroepgehalte en inspanning, (2) een gemotiveerde keuze voor 2-3 kanalen, en (3) per gekozen kanaal een verzendklare tekst die eerst als HTML aan Joost is getoond.

Het daadwerkelijk versturen, het uitnodigen van de eigen kring, en het bijhouden van aanmeldingen horen bij fase 30 (WERV-03 t/m WERV-05) — niet hier.

`27-RESEARCH.md` (2026-09-17) bevat de vergelijkingsmatrix, de mechanismen per platform en de bronnen. Die blijven geldig. De **aanbevolen kanaalmix** in dat document is deels achterhaald door D-01 hieronder; de planner moet de mix opnieuw afleiden uit de matrix, niet de aanbeveling overnemen.

</domain>

<decisions>
## Implementation Decisions

### Kanaalkeuze

- **D-01:** LinkedIn valt af als wervingskanaal voor de gesloten test — zowel de persoonlijke post als de vacature. Joost wil pas over de app posten wanneer die daadwerkelijk in de store staat, en dat is per definitie ná productie-toegang, dus ná de gesloten test. De post kan de werving dus niet helpen. Gevolg: de eigen LinkedIn-post verhuist naar een **lanceerpost achteraf** (backlog, zie `<deferred>`). De LinkedIn-vacature valt sowieso af op mechaniek: die vereist een geverifieerde Company Page die RideWindow niet heeft [VERIFIED in 27-RESEARCH.md, linkedin.com/help]. Beide moeten in de vergelijking blijven staan mét deze motivatie — WERV-01 vraagt om een beoordeling van deze kanalen, en "beoordeeld en bewust niet nu" is een geldige uitkomst.

- **D-02:** Er is geen warm contact bij een fietsclub of fiets-Facebookgroep. Elk fietsgericht kanaal is een koude benadering via een beheerder of bestuur. Gevolg: de doelgroepfit blijft het hoogst van alle kanalen, maar doorlooptijd en slagingskans zijn onzeker en mogen niet als volumegarantie worden ingeboekt. Dit weerlegt de aanname in 27-RESEARCH.md §Recommended Channel Mix dat dit kanaal "snel" kan worden via een bestaand contact.

- **D-03 (herzien 2026-09-20, vervangt de eerdere lezing):** Het zwaartepunt ligt **niet** bij wederkerig testen. Joost heeft tien mensen die hij persoonlijk kan activeren; Google's teller staat op **2 aangemeld** ("2 testers currently opted in", afgelezen in de Play Console op 2026-09-20). Het gat is dus acht *conversies* binnen de eigen kring plus ongeveer vijf van buiten voor de buffer die WERV-04 al op vijftien zet — geen twintig tot vijfendertig opt-ins uit een volumekanaal. De eerdere eis van twee onafhankelijke wederkerige kanalen is daarmee vervallen; die volgde uit een gat van tien dat niet bestaat.

- **D-10 — wat "opted in" betekent, en waarom het gat er is.** Google telt uitsluitend de handeling van de tester zelf: ingelogd op het Google-account dat op de testerslijst staat, de opt-in-link openen en op *Word tester* drukken. Op de lijst gezet worden telt niet, en bij gebruik van een Google Groep moet de tester éérst het groepslidmaatschap accepteren, anders werkt de opt-in-link voor hem niet eens [VERIFIED in 27-RESEARCH.md uit support.google.com/googleplay/android-developer/answer/9845334]. Installeren is een aparte stap daarna en zit niet in dat getal. De acht die ontbreken stranden dus vrijwel zeker op een handeling, niet op overtuiging. Gevolg voor de teksten: de belangrijkste verzendklare tekst van deze fase is een **opt-in-instructie aan de eigen kring** die die stappen letterlijk benoemt — groep accepteren, link openen, knop indrukken — niet een wervende pitch.

- **D-11 — twee latten, niet één.** De teller in de Console meet alleen opt-ins (twaalf tegelijk, veertien aaneengesloten dagen; wie tussentijds uitstapt breekt de reeks en de klok begint opnieuw). De vragenlijst voor productie-toegang daarná vraagt of testers alle functies gebruikten en of het gebruik op echt productiegebruik leek — dáár telt activiteit [VERIFIED in 27-RESEARCH.md uit answer/14151465]. De kanaalkeuze moet aan beide latten worden gemotiveerd, niet alleen aan de teller.

- **D-12 — de mix.** Drie kanalen, in deze volgorde van prioriteit: (1) **de eigen kring van tien**, als conversiekanaal met een opt-in-instructie; (2) **één koude fiets-Facebookgroep** via een beheerder, voor de ongeveer vijf extra met echte doelgroepfit; (3) **r/AndroidClosedTesting uitsluitend als achtervang**, in te zetten met een expliciete drempel — pas als kanaal 1 en 2 na een week samen onder de vijftien aangemelde testers blijven. Wederkerig testen is nadrukkelijk niet de hoofdroute: tegen de ~17%-activatie-ondergrens uit 27-RESEARCH.md kost het twintig tot vijfendertig opt-ins voor een handvol actieve testers, en een tros aanmeldingen die binnen een uur na één post binnenkomt en nooit terugkeert is precies het patroon waar de beoordeling uit D-11 op let (27-RESEARCH.md, Pitfall 3). Een tweede wederkerig kanaal is daarmee overbodig geworden.

- **D-04:** Alles blijft binnen het €0/maand-plafond uit CLAUDE.md. Betaalde testersdiensten en credit-systemen die geld kosten vallen af; een gratis credit-systeem mag wel worden beoordeeld, met de commerciële herkomst expliciet benoemd.

### Teksten

- **D-05:** De verzendklare teksten worden **eerst als HTML aan Joost getoond** voordat om goedkeuring wordt gevraagd. Dit is success criterion 3 van de fase én een staande werkafspraak. Geen goedkeuringsvraag zonder dat het venster open heeft gestaan.

- **D-06:** Taal volgt het kanaal: Nederlands voor Nederlandse fietskanalen, Engels voor de wederkerige testers-kanalen. Niet beide talen voor elk kanaal — dat is werk zonder lezer.

- **D-07:** Elke tekst bevat de drie verplichte ingrediënten uit WERV-02: de veertien dagen, de vraag om regelmatig te openen, en het waarom. Daarbovenop, uit 27-RESEARCH.md §What Makes a Recruitment Message Convert: de belofte dat de tester terughoort als er iets verandert door zijn melding, en een vooraankondiging van de bekende eerste-minuut-frictie (taal van het toestel, lege beschikbaarheid) zolang fase 29 nog niet geleverd is.

### Verificatie

- **D-08:** De actuele zelfpromotie-regels van elk gekozen Reddit-kanaal worden handmatig geverifieerd vlak vóór het schrijven van de tekst, niet overgenomen uit het onderzoek. De onderzoeksomgeving kon Reddit niet bereiken en deze regels veranderen aantoonbaar (27-RESEARCH.md, Open Question 3). Dit hoort een expliciete taak te zijn, geen aanname.

### Vastgelegde feiten

- **D-09:** Joosts LinkedIn-netwerk telt 500-1000 connecties. Relevant voor de latere lanceerpost (D-01), niet voor de kanaalkeuze in deze fase.

- **D-13:** Stand op 2026-09-20: tien mensen binnen bereik die Joost persoonlijk kan activeren, twee daadwerkelijk aangemeld in Google's teller. `STATE.md` en `TESTERS.md` dateren van 10 september en zijn op dit punt verouderd; de Console is leidend.

### Claude's Discretion

- De exacte formulering van de teksten, de kolomindeling van de vergelijkingstabel, bestandsnamen en de vorm van het HTML-venster.
- Welke fiets-Facebookgroep wordt benaderd (D-12 stelt het kanaal vast, niet de specifieke groep).
- Of de vergelijking zeven of meer kanalen beslaat — zeven is de ondergrens uit het success criterion.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Onderzoek (primaire bron voor deze fase)
- `.planning/phases/27-wervingsonderzoek/27-RESEARCH.md` — vergelijkingsmatrix van de zeven kandidaat-kanalen, platformmechanismen (Google Play closed-testing regels, LinkedIn job-posting, Strava clubs, Reddit zelfpromotie), wat een wervingstekst laat converteren, concept-tekstskeletten, valkuilen, bronnen met betrouwbaarheidsniveau. **Let op:** §Recommended Channel Mix is achterhaald door D-01 en D-02 hierboven; de matrix en de bronnen eronder zijn dat niet.

### Testercontext
- `.planning/TESTERS.md` — de huidige testerstand, de eigen kring (~9 opt-ins, grotendeels de 7 die al in de Play-lijst staan), het gedocumenteerde ~17%-activatiecijfer voor wederkerig testen, en de drie bekende eerste-minuut-frictiepunten die D-07 in de tekst wil hebben.

### Requirements en doelen
- `.planning/REQUIREMENTS.md` — WERV-01 en WERV-02 (deze fase); WERV-03 t/m WERV-05 staan er ook maar horen bij fase 30.
- `.planning/ROADMAP.md` §Phase 27 — goal en de drie success criteria.

### Projectgrenzen
- `CLAUDE.md` — het €0/maand-plafond (D-04) en de privacygrenzen.

</canonical_refs>

<specifics>
## Specific Ideas

- De zeven kanalen die WERV-01 met naam noemt en die dus alle zeven in de vergelijking moeten terugkomen: eigen LinkedIn-post, LinkedIn-vacature "vrijwillige tester", Strava-clubs, NTFU-toerclubs, fiets-Facebookgroepen, collega's, en r/AndroidClosedTesting.
- Collega's zijn het enige warme kanaal dat overblijft nu LinkedIn is weggevallen — maar 27-RESEARCH.md stelt vast dat zij grotendeels al in de "9" van de eigen kring zitten en dus weinig incrementeel volume toevoegen. Dat moet in de vergelijking expliciet worden benoemd, niet stilzwijgend genegeerd.
- De tekstskeletten in 27-RESEARCH.md §Message Skeletons zijn een startpunt. De NL-versie is geschreven voor een persoonlijk netwerk; met D-01 moet die worden herschreven voor een koude fietsgroep, waar Joost geen bekende is.

</specifics>

<deferred>
## Deferred Ideas

- **LinkedIn-lanceerpost.** Zodra de app in productie staat, is een eigen LinkedIn-post naar een netwerk van 500-1000 connecties alsnog waardevol — dan als lancering, niet als werving. Hoort op `.planning/BACKLOG.md`, niet in deze fase.
- **Het daadwerkelijk versturen van de teksten, uitnodigen van de eigen kring, en het bijhouden van aanmeldingen en afhakers.** Dat is fase 30 (WERV-03, WERV-04, WERV-05).

</deferred>

---

*Phase: 27-wervingsonderzoek*
*Context gathered: 2026-09-20*
