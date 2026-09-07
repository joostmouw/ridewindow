---
sketch: 003
name: kledingadvies-zonder-plaatje
question: "Als het kledingadvies geen plaatje meer is — hoeveel grafiek verdient het dan wél?"
winner: "A — Gevoelsbalk"
tags: [iconografie, kleding, weerbalken, fase-24]
---

# Sketch 003: Kledingadvies zonder plaatje

> **Gewonnen: variant A — Gevoelsbalk.** Gekozen door Joost op 2026-09-07 en
> diezelfde dag uitgevoerd, zie
> [`.planning/quick/260907-wgz-fase-24-kledingadvies-gevoelsbalk/`](../../quick/260907-wgz-fase-24-kledingadvies-gevoelsbalk/).
> Het uitvoeren bracht iets aan het licht dat in de schets niet zichtbaar was:
> de weerlijst op ditzelfde scherm toont Open-Meteo's `apparentTemperatureC` al
> als "feels like 16°C", terwijl deze balk op 14° uitkomt. Twee getallen onder
> dezelfde woorden. Het label heet daarom "On the bike" / "Op de fiets".

## Design Question

Schets 002 tekende eigen pictogrammen voor het kledingadvies. Joost wees die af op **2026-09-07**:
niet de uitvoering maar de aanpak. Het advies gaat niet over textiel, het gaat over hoe koud het
aanvoelt — dus hoort er informatie te staan, geen illustratie. Dat is dezelfde beweging die fase 23
met de weerbalken maakte.

De vraag wordt daarmee: **hoeveel grafiek verdient dat oordeel?** Een volwaardige balk in de familie
van `WeatherIndicatorBar`, een stapjesschaal, of alleen typografie.

## How to View

```bash
python3 -m http.server 8765     # vanuit de repo-root, anders laadt Outfit niet
open http://localhost:8765/.planning/sketches/003-kledingadvies-zonder-plaatje/index.html
```

## Variants

- **A — Gevoelsbalk** — exact de anatomie van `weather_indicator_bar.dart`: label, waarde,
  oordeelswoord, ingezoomde schaal (−5…25°) met de vier kledingbanden als tint en een markering op
  de gevoelstemperatuur. Wordt visueel een vierde weerbalk.
- **B — Vier stappen** — geen continue schaal maar vier vakjes, waarvan er één gevuld is. Rijmt op
  de dagstrip, die sinds `026699f` ook alle vier de niveaus toont in plaats van drie.
- **C — Alleen woorden** — geen grafiek. Het oordeel als kop ("Long sleeves, long legs"), de reden
  klein eronder, dan de kledinglijst.

Alle drie tonen drie echte gevallen: 15 °C met 28 km/u wind, 2 °C, en 24 °C met regen. De buurkaart
(regen- en windbalk) staat eronder zodat je ziet of het in de kolom past of ermee gaat concurreren.

## Wat dit sowieso oplost, welke variant je ook kiest

`recommendClothing()` rekent al met **gevoelstemperatuur** — `temp − (wind + 15) × 0,05`, waarbij die
15 km/u de eigen snelheid is. Dat getal stond nergens in de app. Daardoor adviseerde RideWindow bij
een gemeten 15 °C "lange mouw" zonder ooit te zeggen waarom, en zag dat eruit als een fout. Alle drie
de varianten zetten dat getal in beeld. Dat is de eigenlijke winst van deze schets; de vorm eromheen
is de smaakvraag.

## What to Look For

1. **Concurreert het met de weerbalken eronder?** In A staat er straks een vierde balk vlak boven
   drie andere. Dat kan als één rustige familie lezen — of als vier streepjes waarvan je er geen
   meer leest, precies de val waar fase 23 uit klom.
2. **Zegt de schaal nog iets bij 1 °C en bij 23 °C?** Scroll naar de tweede en derde casus. Een
   schaal die alleen in het midden werkt, werkt niet.
3. **Mist er iets zonder plaatje?** De pil was klein maar hij was wel het enige vrolijke element op
   Ride Detail. Als C te kaal aanvoelt, is dat een geldig argument voor A of B.

## Nog te beslissen

- **De kleurband in A.** Koud is nu lichtblauw (`lightCalendarBusy`), warm oranje (`lightWarning`) —
  beide bestaan al als token, dus er komt geen nieuw palet bij. Maar het is wel de eerste keer dat
  kleur in deze app *temperatuur* betekent in plaats van *kwaliteit*. Dat is een uitbreiding van de
  kleurtaal en verdient een bewuste ja.
- **De 17 andere emoji.** Deze schets gaat alleen over kleding. Thermometer, druppel, wind, fiets,
  vlag en de acht rider-types staan nog steeds als systeememoji in de app — zie de tabel in
  `../002-iconografie/README.md`. Voor die groep is de vraag niet "eigen tekening of niet" maar
  waarschijnlijk gewoon: Material Symbols, want die zitten al in Flutter en zijn op elk platform
  identiek.
