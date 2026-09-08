---
sketch: 010
name: hoeveel-fiets
question: "Hoeveel fietstaal verdraagt de app, en op welke plekken?"
winner: null
tags: [merk, toon, naamgeving, peloton, l10n]
---

# Schets 010: Hoeveel fiets zit er in de taal?

## Design Question

Joost: *"ik vind Peloton een beetje uit het niets komen maar vind van die fietsnamen door de app
heen juist wel leuk ook! (…) daarom is de term peloton voor een social wel goed maar snap dat dit
het misschien ook weer niet helemaal is. maar ik vind wat fiets namen items erin sterk. weet alleen
nog niet goed hoe precies"* (2026-09-08).

## Het onderscheid dat de schets maakt

**"Uit het niets" en "verkeerd woord" zijn niet hetzelfde, en ze hebben een andere reparatie.**
"Peloton" stond op een tabblad — een wegwijzer, iets wat je moet kunnen volgen zonder het geleerd
te hebben — en nergens stond wat het betekende. Dát voelde koud, niet het woord zelf. Een term die
de app één keer uitlegt is daarna geen jargon meer maar van jou. Zeven woorden op de lege staat
doen dat werk, en die staat er nu niet.

Dit is dezelfde vorm als twee eerdere lessen in dit project: *een klacht is een waarneming, geen
diagnose.* "Font lastig te lezen" bleek een animatie, "de app ziet er hetzelfde uit" bleek
contrast, en "Peloton komt uit het niets" blijkt een ontbrekende introductie.

## How to View

```bash
python3 -m http.server 8765          # vanuit de repo-root, anders laadt het lettertype niet
open http://localhost:8765/.planning/sketches/010-hoeveel-fiets/index.html
```

## Variants

Eén knop met drie standen, alle drie op dezelfde vier oppervlakken (Home-kop, ritkaart,
navigatiebalk, tweede tabblad, de vier oordelen, een melding):

- **Stand 1 — Fiets in de toon.** Wegwijzers en oordelen in gewone taal; het fietsen zit in je
  type, je meldingen en je lege staten. Tab heet *Maatjes*, oordelen blijven *Perfect / Goed /
  Acceptabel / Slecht*.
- **Stand 2 — Fiets ook in de oordelen.** Wegwijzers blijven gewoon, maar de vier oordelen worden
  *Toprit / Fijne rit / Te doen / Binnenblijver*. Die staan op élke kaart, elke dag.
- **Stand 3 — Fiets ook in de wegwijzers.** Stand 2, plus het sociale tabblad heet weer *Peloton* —
  mét de introductie, dus het komt niet meer koud binnen.

Alle drie hebben **het fietserstype op Home** ("Vroege vogel · 29 fietsmomenten deze week"). Dat is
geen variabele: het zit al in de app, wordt berekend uit het beschikbaarheidsrooster, en staat nu
alleen op `/profile/availability` — het scherm dat je één keer bezoekt.

## What to Look For

- Lees de drie ritkaarten naast elkaar. Zegt **Perfect** of **Toprit** meer over wat je te wachten
  staat? En zegt **Slecht** of **Binnenblijver** meer over wat je moet dóen?
- Kijk of "Peloton" in stand 3 nog steeds koud aankomt nu de lege staat het uitlegt.
- De onderste navigatiebalk is in alle drie de standen identiek, met opzet. Daar is niets te winnen
  en veel te verliezen.
