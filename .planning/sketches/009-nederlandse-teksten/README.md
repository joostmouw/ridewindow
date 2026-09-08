---
sketch: 009
name: nederlandse-teksten
question: "Welk Nederlands spreekt deze app — en welk woord gebruikt hij voor zijn eigen kernbegrip?"
winner: null
tags: [l10n, nederlands, toon, kleding, jargon]
---

# Schets 009: De Nederlandse teksten

## Design Question

Joost: *"ik vind de Nederlandse vertalingen ook niet zo goed. en met fietskleding staat er
kniebeschermers maar dat is niet een item die mensen vaak aan doen dus korte of lange broek
genoeg"* (2026-09-08).

Alle 505 Nederlandse strings zijn doorgelezen. De klacht valt uiteen in vier blokken, waarvan er
twee een keuze zijn en twee niet.

## Wat eruit kwam

1. **Het kernwoord.** De app noemt hetzelfde ding *rijvenster*, *rijmoment*, *rijtijd*, *venster*
   én *slot* — soms twee ervan op één scherm. "Rijvenster" is een letterlijke vertaling van *ride
   window*. Drie kandidaten, in situ getoond op Home, in een melding, in de uitleg en in de
   deeltekst.
2. **Het kledingadvies.** Joost's punt over de kniewarmers geldt voor de hele lijst: *jersey,
   armwarmers, beenwarmers, kniewarmers, overschoenen, thermobroek, windvest* komen allemaal uit de
   wielrenkast, terwijl CLAUDE.md de app voor de **gewone fietser** bestemt. Vier temperatuurbanden
   naast elkaar, oud tegen nieuw.
3. **Achttien fouten.** Geen keuze. Vier daarvan zeggen iets anders dan bedoeld — het scherpst
   `hourlyFeelsLike`, dat de gevoelstemperatuur afdrukt als "v.a. 12°C", wat leest als *vanaf*.
   Verder Engels dat is blijven staan (*windows*, *slot*, *sweet spot*, *swipe*, *override*), een
   spelfout (*geimporteerd*), een verkeerde werkwoordsvorm op een knop (*Begrijpen*), en één niveau
   dat op twee schermen twee namen heeft (*Goed* versus *Geweldig*).
4. **Toon.** Acht plekken die niet fout zijn maar niet klinken als iemand die Nederlands praat.

## How to View

```bash
python3 -m http.server 8765          # vanuit de repo-root, anders laadt het lettertype niet
open http://localhost:8765/.planning/sketches/009-nederlandse-teksten/index.html
```

## What to Look For

- **Blok 1:** lees de vier fragmenten per kandidaat hardop. Welke zou je tegen een fietsmaatje
  zeggen?
- **Blok 2:** de rechterkolom is wat iemand met een gewone kledingkast in huis heeft. Klopt dat, of
  gaat er iets nuttigs verloren?
- **Blok 4:** streep door wat je wilt houden.
