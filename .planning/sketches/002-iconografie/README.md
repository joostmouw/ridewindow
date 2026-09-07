---
sketch: 002
name: iconografie
question: "Waar komt het kledingadvies vandaan als het geen systeememoji meer is — uit twee losse kledingstukken, uit één tenue, of uit een gekleed figuur?"
winner: "geen — aanpak afgewezen 2026-09-07"
tags: [iconografie, kleding, weer, fase-24]
---

# Sketch 002: Iconografie

> **Afgewezen op 2026-09-07.** Joost: "ik vind je voorgestelde icons niet echt goed." Niet de
> uitvoering maar de aanpak: het kledingadvies hoort geen illustratie te zijn. Het vervolg staat in
> [`003-kledingadvies-zonder-plaatje`](../003-kledingadvies-zonder-plaatje/) — daar wordt het advies
> informatie, in de familie van de weerbalken uit fase 23.
>
> Deze schets blijft staan om twee redenen: de emoji-inventaris hieronder geldt nog steeds voor de
> zestien niet-kleding-plekken, en de tekenlessen onderaan gelden voor elk pictogram dat dit project
> nog maakt.

## Design Question

Fase 24 uit `EIGEN-GEZICHT.md`: het kledingadvies tekent nu losse Unicode-emoji
(`\u{1F455}` t-shirt, `\u{1FA73}` korte broek, `\u{1F9E5}` jas) in een `Text` op fontSize 20. Die
worden door het besturingssysteem getekend, dus Android, iOS en het web laten elk iets anders zien.

De vraag is niet "welke stijl is mooi" maar: **waaruit leest de gebruiker het advies af bij 20 px?**
De eis staat er al: een eigen pictogram voor "lange mouw" moet zonder tekst herkenbaar zijn, anders
is een systeememoji die iedereen kent beter.

## How to View

```bash
python3 -m http.server 8765     # vanuit de repo-root, anders laadt Outfit niet
open http://localhost:8765/.planning/sketches/002-iconografie/index.html
```

## Variants

- **A — Lijn** — twee losse kledingstukken naast elkaar, monoline met ronde uiteinden. Precies de
  structuur van vandaag; sluit aan op het RW-app-icoon. Laagste risico, kleinste verschil tussen de
  vier adviezen.
- **B — Vlak** — één massief silhouet van het complete tenue per combo. De vier adviezen worden vier
  verschillende *vormen*, niet vier mouwlengtes. Pil wordt smaller en ~6 px hoger.
- **C — Renner** — een gekleed figuurtje, duotone (merkgroen vulling, inktcontour). Lange mouw is
  hier "geen blote onderarm". Het duurste om te tekenen en te onderhouden.

## What to Look For

1. **Sectie 1 is de echte toets.** Daar staan de pictogrammen op ware grootte in de échte pil
   (`padding 10/6`, radius 12, `surfaceContainerHigh`, glyph 20 px, label 11 px), naast de emoji
   zoals hij nu op dit scherm getekend wordt.
2. **Sectie 2 is de eis uit de epic.** Vier ongelabelde iconen op 20 px, door elkaar. Wijs "lange
   mouw + lange broek" aan vóór je op *Toon antwoorden* drukt. Lukt dat niet, dan valt die variant af
   — dan is een systeememoji die iedereen kent nog steeds beter.
3. **Sectie 4 toetst of de stijl doorloopt.** Kleding is maar één van de zeventien plekken waar de
   app nu een systeememoji tekent (zie hieronder). Als thermometer, druppel, wind en fiets niet uit
   dezelfde hand komen, klopt de keuze niet.

## Wat er verder nog aan emoji in de app staat

| Bestand | Emoji nu |
|---|---|
| `lib/features/shared/clothing_tip.dart` | 👕🩳 / 🧥🩳 / 🧥👖 / 🧥🧥 |
| `lib/features/welcome/welcome_screen.dart` | 🚴 |
| `lib/features/detail/ride_detail_screen.dart` | 🟢 🟡 🌧 💨 |
| `lib/features/detail/insights_sheet.dart` | 🌡 🌧 💨 |
| `lib/features/availability/availability_screen.dart` | 😮 🚴 🏔 🌅 🌇 ☀️ 💪 🚲 (8 rider-types) |
| `lib/features/profile/profile_screen.dart` | 🚩 |

## Wat tijdens het tekenen bleek

- **Een verschil in omtrek overleeft het verkleinen, een extra lijntje niet.** De eerste jas kreeg
  een rits over de volle hoogte; die hakte het silhouet doormidden en verdween tegelijk bij 20 px.
  Nu verschilt de jas van het lange shirt in de *omtrek* — een opstaande kraag die boven de schouder
  uitsteekt — en dat zie je nog op duimnagelformaat.
- **Een broek zonder tailleband leest als een emmer.** Eén snede op 6,2 maakt er kleding van. Bij de
  massieve variant is die snede papierkleur, bij de lijnvariant gewoon inkt — dezelfde vorm, andere
  behandeling.
- **Wind blijft lijnwerk, ook in de vlakke variant.** Dat is in elke iconenset zo; een massieve
  windvlaag bestaat niet.
- Alle vijf de kledingstukken zijn één gesloten pad. Daardoor is dezelfde tekening bruikbaar als
  lijn (`fill:none`), als vlak (`fill`) én als duotone — de stijlkeuze zit niet vast aan het
  tekenwerk. Dat maakt de implementatiekeuze in Dart later goedkoper.

## Nog te beslissen ná de variantkeuze

Hoe de gekozen tekening in Flutter terechtkomt. Drie routes, oplopend in gewicht:

1. **`CustomPainter` met de paden hard in Dart** — nul afhankelijkheden, past bij de lijn die dit
   project trekt (geen Dio voor één GET). Elke vorm is met de hand overgezet.
2. **`flutter_svg`** — één extra afhankelijkheid, de SVG's uit deze schets gaan er ongewijzigd in.
3. **Eigen icoonfont** — het lichtst op de GPU, maar het genereren vraagt gereedschap buiten de repo
   én we weten uit `9bf1e38` dat `--tree-shake-icons` een glyph wegsnijdt die alleen in een ternaire
   staat. Een eigen font zou die val eerder groter dan kleiner maken.

Voorkeur: **1**, tenzij de gekozen variant zoveel paden heeft dat het overzetten niet meer loont.
