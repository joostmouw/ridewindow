---
sketch: 009
name: nederlandse-teksten
question: "Welk Nederlands spreekt deze app — en welk woord gebruikt hij voor zijn eigen kernbegrip?"
winner: "A + beperkt 2 + heel 3"
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

## Wat Joost koos (2026-09-08)

| Blok | Keuze |
|---|---|
| 1 — kernwoord | **A, "fietsmoment"**. 22 strings omgezet; *rijvenster*, *rijmoment*, *rijtijd*, *venster* en *slot* zijn allemaal weg uit de Nederlandse interface. |
| 2 — kleding | **Alleen de kniewarmers.** Tussen 10 en 14 graden staat er nu niets extra, en `clothingLegWarmers` heet "Lange broek" in plaats van "Beenwarmers" (ook in het Engels: *Long trousers* — anders adviseren de twee talen andere kleding). De rest van de wielrennerstaal blijft. |
| 3 — fouten | **Alle achttien**, plus twee dode sleutels die erbij bleken te liggen (`clothingKneeWarmers` en `clothingLightShirt`). |
| 4 — toon | **Niets.** Nachtuil, Weekendstrijder, TOLERANTIES en RIJLENGTE blijven staan. |

Zes tests wezen op de oude teksten en zijn meegegaan: `Annuleer`, `Begrijpen`, `NOTIFICATIES`,
`rijvensters`, `Rijvenster toegevoegd` en `perfecte rijmoment`.
