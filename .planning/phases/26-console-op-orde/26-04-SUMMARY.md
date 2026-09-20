---
phase: 26-console-op-orde
plan: 04
subsystem: docs
tags: [play-console, store-listing, nl-nl, con-05]

requires: []
provides:
  - "Geverifieerde plakte-tekst: de NL korte omschrijving is exact 73 tekens en de volledige NL-beschrijving bevat de vier oordeelnamen"
  - "Twee extra Console-punten gevonden in de eigen 'Nog open'-sectie van docs/store-listing.md: het icoon is nog een plaatsaanduiding en de feature-graphic is van 21 juni"
affects: [30-werving, 32-aanvraag-en-productie]

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/phases/26-console-op-orde/26-04-SUMMARY.md
  modified: []

key-decisions:
  - "De copy is niet opnieuw geschreven en niet verbeterd: docs/store-listing.md is de bron van waarheid en wordt woordelijk geplakt"
  - "De twee open Console-punten uit de store-listing zelf zijn meegenomen in het stappenplan, want ze wonen in hetzelfde scherm"

requirements-completed: []

duration: "~10 min"
completed: 2026-09-20
---

# Fase 26 Plan 04: CON-05 Summary

**De nl-NL-plakte-tekst is geverifieerd tegen de bron (73 tekens, vier oordeelnamen), en de sweep vond nog twee open Console-punten in de winkelpagina zelf.**

## Performance

- **Duration:** ~10 min
- **Tasks:** 2 (plak-stappen klaargezet, verificatie-stappen klaargezet)
- **Files modified:** 1 (deze SUMMARY)

## Wat er uitgevoerd is

**De plakte-tekst gecontroleerd tegen de bron**, want Pitfall 2 geldt:
managed publishing staat uit, dus opslaan gaat direct de review in. Er is
geen concept-buffer om een plakfout achteraf af te vangen.

| Controle | Resultaat |
|---|---|
| NL korte omschrijving | exact **73 tekens** (de doc zegt ook 73; Play staat 80 toe) |
| EN korte omschrijving | **76 tekens** gemeten — de doc zegt 75. Eén teken verschil in de aantekening, geen verschil voor de plak: 76 van 80 |
| Volledige NL-beschrijving | aanwezig onder "### Nederlands", van "Stop met drie apps openen..." tot "...kies je moment, fiets." |
| De vier oordeelnamen | Toprit, Fijne rit, Te doen en Binnenblijver staan er alle vier in |

**Sweep-vondst.** `docs/store-listing.md` heeft zelf een sectie "Nog open
in de Play Console", en die telt twee punten die in hetzelfde scherm
wonen en dus in dezelfde Console-sessie mee kunnen:

1. **Het app-icoon in de listing is een plaatsaanduiding** (een kalender
   met potlood). Het echte icoon ligt klaar in
   `docs/play-store-icon-512.png` en moet nog geüpload worden. De app zelf
   gebruikt het al.
2. **`docs/feature-graphic.png` is van 21 juni** en toont de verouderde
   app — de screenshots zijn van 2026-09-10 ververst, maar de banner erboven
   is dat nooit geworden.

## Wat Joost doet (resume-signals)

**Taak 1 — de vertaling erin zetten:**

1. Play Console → Store presence → Main store listing → Manage
   translations → Add language → Dutch (Nederlands, nl-NL).
2. De korte omschrijving woordelijk uit `docs/store-listing.md` (de regel
   achter **NL:**): "Wanneer kun je deze week het best fietsen? Weer,
   daglicht en jouw agenda."
3. De volledige beschrijving woordelijk uit de sectie "### Nederlands":
   het hele blok van "Stop met drie apps openen..." tot en met
   "...kies je moment, fiets."
4. **Vóór Opslaan** beide blokken naast `docs/store-listing.md` nalezen.
   Managed publishing staat uit: opslaan gaat direct live de review in.
5. Opslaan.

**Taak 2 — bevestigen dat het klopt:**

1. De listing in het Nederlands bekijken (apparaat op Nederlands, of de
   nl-NL-preview in de Console) en short + full naast de doc leggen,
   inclusief de vier oordeelnamen.
2. De en-GB-listing nakijken dat die onveranderd is.

**Meenemen in dezelfde sessie, want hetzelfde scherm:**

3. `docs/play-store-icon-512.png` uploaden als app-icoon (nu nog een
   plaatsaanduiding).
4. Een verse feature-graphic maken of de oude laten staan mét het besef
   dat hij de app van juni toont.

## Wat nog open is (de waarheden van dit plan)

- Er bestaat nog geen nl-NL-rij op de Main store listing
- De verificate-stap (nl-NL toont de Nederlands-copy, en-GB onveranderd)
  kan pas nadat Joost geplakt en opgeslagen heeft

## Deviations from Plan

Eén toevoeging: de twee open punten uit de "Nog open"-sectie van
`docs/store-listing.md` zijn in het stappenplan opgenomen. Het plan noemde
ze niet, maar het zijn winkelpagina-werk en de fase heet Console op orde;
het zou nalatig zijn ze te zien en niet te melden. De plakstappen zelf zijn
ongewijzigd.

## Self-Check: PASSED

- Tekenaantallen gemeten, niet overgenomen uit de doc (73 klopt, 75 bleek 76)
- De vier oordeelnamen staan alle vier in de NL-beschrijving, woordelijk
- requirements-completed bewust leeg: CON-05 woont in de Console, niet in de repo
