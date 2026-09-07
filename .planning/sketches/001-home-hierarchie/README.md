---
sketch: 001
name: home-hierarchie
question: "Waar komt de hiërarchie op Home vandaan — uit een dominante held, uit een neutraal papier, of uit het weer zelf?"
winner: "B"
tags: [home, hierarchie, typografie, weerbalken, v4.0, fase-23]
---

# Sketch 001: Home-hiërarchie

> **Gekozen: variant B — "Papier en inkt"** (Joost, 2026-09-07).

Hoort bij milestone **v4.0 "Eigen gezicht"**, fase 23. Startpunt van de epic:
`.planning/EIGEN-GEZICHT.md`.

## Design Question

De diagnose in EIGEN-GEZICHT.md luidt: *"de app is een muur van dezelfde groentint zonder
hiërarchie."* Deze schets zoekt uit **waar de hiërarchie vandaan moet komen**, en legt daarvoor
drie fundamenteel verschillende antwoorden naast het scherm van vandaag.

De diagnose is onderweg in de code bevestigd, en dat scherpt de vraag:

- `AppColors.lightSurface == brandLight` (`#C5D4B6`). De achtergrond *is* de merkkleur. De
  ritkaarten staan op `surfaceContainerHigh` (`#E4EAD7`) — dat is nog geen 8% helderheidsverschil,
  dus de oppervlakkenladder heeft in de praktijk geen bereik om iets mee te onderscheiden.
- De regenbalk tekent een groene ideaalzone van `≤0,5 mm` op een schaal van `0–10 mm`. Die zone is
  **5% van de balkbreedte**, en de stip staat er bij droog weer bovenop. Dat is niet slordig
  getekend, het is onleesbaar per constructie — precies wat "versiering in plaats van informatie"
  betekent.

## How to View

```bash
python3 -m http.server 8765            # vanuit de repo-root, zodat Outfit.ttf laadt
open http://localhost:8765/.planning/sketches/001-home-hierarchie/index.html
```

Of direct: `open .planning/sketches/001-home-hierarchie/index.html`.

De werkbalk bovenaan schakelt tussen **Naast elkaar** (alle vier op 70%) en één variant op ware
grootte. Alle vier de kolommen tekenen dezelfde dag, dezelfde drie ritten en dezelfde weerwaarden
uit één `DATA`-object — wat je ziet verschillen is dus uitsluitend hiërarchie, niet inhoud.

## Variants

- **Nu** — het scherm van vandaag, zo getrouw mogelijk nagebouwd (incl. de `3u`/`4u`-doorslag uit
  fase 25). Dit is het ijkpunt, geen kandidaat.
- **A: Held bovenaan** — de beste rit wordt een donkergroen paneel over de volle breedte, met de
  score op 64px en de actieknop erin. De rest wordt een rustige lijst zónder kaarten. Groen
  verandert van behang in anker.
- **B: Papier en inkt** — de achtergrond wordt papier (`surfaceContainerLowest`), groen wordt inkt.
  De beste kaart licht op met schaduw en een donkere linkerrand; de rest is vlak. De balken zijn
  herschaald naar het bereik dat de gebruiker zelf heeft ingesteld, met een woord ernaast
  (Dry / Calm / Ideal).
- **C: Weerbaan** — het weer wórdt het beeld: per uur een gekleurde cel met de temperatuur erin,
  met regen en wind als dunne banen eronder. De weekstrip spreekt dezelfde taal (ochtend /
  middag / avond per dag) en máákt daarmee het periodefilter overbodig.

## What to Look For

1. **Trekt je oog meteen naar de beste rit?** Kijk met samengeknepen ogen; dat is de eerlijkste test.
2. **Zeggen de weerbalken je iets zonder dat je ze bestudeert?** Vergelijk vooral de regenregel
   tussen de vier kolommen.
3. **Zijn de dagstrip en het periodefilter rustig genoeg** om het oog dóór te laten lopen naar de
   inhoud — of vechten ze nog om aandacht?
4. **Voelt het nog als RideWindow?** A en B halen het groen weg uit de achtergrond. Dat is de
   grootste breuk met vandaag en de belangrijkste vraag om bewust ja of nee tegen te zeggen.

## Bouwbaarheid in Flutter

| Variant | Wat het kost |
|---|---|
| B | **Het minste.** Grotendeels een herverdeling van kleurrollen in `app_colors.dart` (surface wordt `surfaceContainerLowest`, brandLight wordt accent), plus `WeatherIndicatorBar` een `zoom`-bereik geven. De widgetstructuur van Home blijft staan. |
| A | **Middel.** Nieuwe hero-sliver bovenaan; de niet-beste kaarten worden `ListTile`-achtige rijen in plaats van `Card`. `_buildWeekStrip` en `_buildPeriodFilter` worden lichter, niet anders van soort. |
| C | **Het meeste.** Vraagt uurdata per slot in de kaart (die is er al: `slotForecasts` wordt in `_buildRideCard` al berekend) plus een nieuwe band-widget, en `_buildPeriodFilter` verdwijnt in de weekstrip. Grootste sprong, ook de grootste winst op doel 2. |

## De uitkomst — wat B concreet betekent

Variant B is gekozen. De kern ervan is één omkering: **groen is nu behang en wordt accent.** Alles
daaronder volgt daaruit. Dit is de lijst zoals hij uit de schets volgt, niet een plan — dat komt in
fase 23 zelf.

1. **`lightSurface` van `brandLight` naar `surfaceContainerLowest` (`#FCFDF8`).** Dit is de
   ingreep waar de hele variant op rust, en het is belangrijk om de reden goed te hebben. Het gaat
   niet alleen om bereik in de oppervlakkenladder — de eigenlijke breker is dat **een slagschaduw
   niet leest op een middentoon.** Schaduw is het gereedschap waarmee je één ding vóór de rest
   zet, en juist dat gereedschap werkt niet op `#C5D4B6`. In B zijn beide kaarten wit; het
   onderscheid komt uit schaduw en rand, en dat kan alleen op een lichte, neutrale grond.
   `brandLight` blijft in gebruik als accent (chips, tonale knoppen), dus de waarde verdwijnt niet
   uit het thema.

   **Contrast gemeten (2026-09-07, WCAG 2.1, tekst op de achtergrond — de slechtste plek):** de
   verwachte keerzijde blijkt een meevaller. Elke tekstkleur krijgt op papier méér ruimte, en de
   twee die destijds speciaal voor brandLight zijn aangescherpt het meest.

   | Token | op `#C5D4B6` | op `#FCFDF8` |
   |---|---|---|
   | `lightTextPrimary` `#1A2A20` | 9,65:1 | 14,72:1 |
   | `lightTextSecondary` `#3A4A40` | 6,03:1 | 9,20:1 |
   | `lightOnSurfaceVariant` `#414F45` | 5,54:1 | 8,46:1 |
   | `lightTextTertiary` `#4C5C52` | 4,55:1 | 6,94:1 |
   | `lightTextHint` `#4E5C54` | 4,51:1 | 6,89:1 |

   De twee onderste zaten met de hakken over de sloot van 4,5 en hebben nu ruim twee punten lucht.
   Dat is geen bijvangst maar bruikbaar materiaal: ze **mogen weer lichter**, en dat is precies de
   marge die hiërarchie nodig heeft — blijft alle tekst even donker, dan is de vlakheid alleen van
   kleur naar typografie verplaatst. Kanttekening: dit is berekend, niet gezien. Backlog #9 is op
   Roboto gemeten en Outfit oogt lichter; controleer 11–12 punt op de Oppo vóór je iets lichter
   zet.
2. **De beste kaart krijgt echt gewicht:** wit, slagschaduw, en een 5px linkerrand in `brandDark`.
   De overige kaarten worden vlak met een haarlijn — géén tweede schaduw, anders is er weer geen
   eerste plek. Let op: `_buildRideCard` wikkelt de kaart nu in een `ClipRRect` voor de
   `Dismissible`, en die snijdt een `elevation` weg. De schaduw moet dus buiten die clip komen te
   staan (of via een `Container`-decoratie eromheen), precies zoals het commentaar in de code al
   waarschuwt.
3. **De typografische stap wordt echt gezet:** de dagnaam op de beste kaart naar `headlineSmall`
   (24px), op de andere kaarten `titleMedium` (16px), en de score van 36px naar 46px op de beste
   en 26px op de rest. Nu staat alles op dezelfde maat en dat is de helft van de vlakheid.
4. **`WeatherIndicatorBar` krijgt een `zoom`-bereik** naast zijn absolute `min`/`max`. Temp toont
   0–35°, regen 0–3 mm, wind 0–40 km/u. Daarmee is de ideaalzone een leesbare band in plaats van
   een streepje van 5%, en de as blijft eerlijk omdat de grenzen erbij staan. Er komt een
   uitgeschreven oordeel naast de waarde (`Dry` / `Light` / `Showers` / `Wet`,
   `Calm` / `Breezy` / `Gusty`, `Chilly` / `Ideal` / `Warm`) — dat is wat de balk van versiering
   naar informatie tilt, en het is nieuwe tekst, dus EN+NL in de ARB's.
5. **Dagstrip en periodefilter worden rustiger.** De dagchips verliezen hun gekleurde achtergrond;
   de kwaliteit van een dag wordt een 3px onderstreping in de tierkleur. Het `SegmentedButton`
   wordt een tekstrij met onderstreping. Beide houden op om met de inhoud te concurreren.
6. **De niet-beste kaarten verliezen hun balken** en krijgen één compacte regel
   (`18° · Dry · 11 km/h`). Drie volle balken per kaart is de reden dat de lijst als één massa
   leest.

**Buiten Home nalopen** (vaste werkafspraak: dezelfde wijziging overal doorvoeren) — de
oppervlakomkering uit punt 1 raakt élk scherm, niet alleen Home. Expliciet langs: Rides, Ride
Detail (waar ook de laatste handmatige `BoxShadow` nog staat), Peloton, Profiel, Beschikbaarheid,
en de twee overlays met hardcoded kleuren (`screen_hint_overlay.dart`, `app_tour_overlay.dart`).
`WeatherIndicatorBar` wordt behalve op Home ook op Ride Detail gebruikt, dus punt 4 landt daar
vanzelf mee.
