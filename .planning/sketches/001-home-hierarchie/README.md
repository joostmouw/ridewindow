---
sketch: 001
name: home-hierarchie
question: "Waar komt de hiërarchie op Home vandaan — uit een dominante held, uit een neutraal papier, of uit het weer zelf?"
winner: null
tags: [home, hierarchie, typografie, weerbalken, v4.0, fase-23]
---

# Sketch 001: Home-hiërarchie

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
