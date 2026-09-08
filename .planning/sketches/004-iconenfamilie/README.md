---
sketch: 004
name: iconenfamilie
question: "Welke hand tekent de zestien plekken waar RideWindow nu een systeememoji zet?"
winner: null
tags: [iconografie, fase-24, weerbalken, rider-types]
---

# Sketch 004: Iconenfamilie

## Design Question

Fase 24 begon met "iconografie" en leverde tot nu toe één ding op: het kledingadvies is geen plaatje
meer maar een balk (schets 003, uitgevoerd). Wat blijft staan zijn **zestien plekken die nog steeds
een systeememoji tekenen** — en die tekent het besturingssysteem, dus ze zien er op Android, iOS en
het web verschillend uit. In de release web-build van 2026-09-07 waren 🌧 en 💨 in de uurtabel zelfs
even leeg blokje voor de emoji-font geladen was.

Joost wil ze **persoonlijk** maken, niet Material. De vraag is daarmee niet *of* ze weg moeten, maar
**welke hand ze vervangt**.

## Waarom geen eigen tekenwerk, en geen Material

- **Zelf tekenen is geprobeerd en afgewezen** (schets 002). Iconen tekenen is ambacht; een taalmodel
  dat SVG-paden intikt levert werk op dat bij 20 px uit elkaar valt. Een beeldmodel als Gemini levert
  pixels, geen vectoren.
- **Material Symbols zou het technische probleem oplossen** — zit al in Flutter, op elk platform
  identiek — maar het is de Google-huisstijl en leest als "standaard app". Dat is precies het
  tegenovergestelde van wat deze milestone wil. Daarom staat het bewust niet in de vergelijking.

Wat overblijft: een karaktervolle, MIT-gelicenseerde familie die professioneel getekend is. Eigen
gezicht zonder amateurwerk.

## How to View

```bash
python3 -m http.server 8765     # vanuit de repo-root, anders laadt Outfit niet
open http://localhost:8765/.planning/sketches/004-iconenfamilie/index.html
```

De iconen zitten in `icons.js`, opgehaald van de officiële pakketten en ingesloten — de schets werkt
dus ook offline en verandert niet meer als de families een nieuwe versie uitbrengen.

## Varianten

| Familie | Karakter | Licentie |
|---|---|---|
| **Lucide** | monoline, ronde uiteinden, lijndikte 2 op een 24-raster | ISC |
| **Phosphor · regular** | dunne lijn op een 256-raster, zes gewichten beschikbaar | MIT |
| **Phosphor · duotone** | dezelfde tekening plus een tweede vlak op 20% dekking | MIT |
| **Tabler** | monoline, iets hoekiger, ruim 5000 iconen | MIT |

De werkbalk bovenin wisselt de lijndikte (2 → 2,5 → 1,5) voor de twee lijnfamilies, zodat je kunt
zien of het probleem de tekening is of het gewicht.

## What to Look For

1. **13 px is de scherpste toets.** Dat is de maat in de weerbalken, het kleinste formaat in de app.
   Een te fijne tekening wordt daar grijze soep.
2. **Acht rider-types onder elkaar** laten zien of een familie samenhang heeft of los zand is — dat
   zie je pas als er meerdere iconen tegelijk staan.
3. **Op donker.** De app heeft een donker thema. Een gevulde familie gedraagt zich daar anders dan
   een lijnfamilie; de onderste strook in sectie 4 is daarvoor.
4. **Past het bij Outfit?** Die letter heeft *vlakke* uiteinden. Een set met ronde uiteinden (Lucide)
   zet daar contrast tegenover; een hoekiger set (Tabler) versterkt het juist. Dat is een keuze, geen
   fout — dezelfde afweging als bij het lettertype zelf, zie `app_typography.dart`.

## Eén verschil dat de vergelijking niet gelijk trekt

Welcome toont nu 🚴 — een *mens op een fiets*. Phosphor heeft daar `person-simple-bike` voor;
Lucide en Tabler hebben alleen `bike`, een fiets zonder berijder. Op 80 px is dat een echt verschil
in wat het plaatje zegt. Als Lucide of Tabler wint, is dat de ene plek waar iets bijgetekend moet
worden — en dan door een bestaande glyph aan te passen, zodat lijndikte en proporties van de familie
geërfd worden in plaats van geraden.

## Ná de keuze

Hoe de set in Flutter komt, oplopend in gewicht:

1. **Alleen de gebruikte glyphs als `CustomPainter`-paden** — nul afhankelijkheden, maar ~16 vormen
   met de hand overzetten.
2. **Het pub-pakket van de familie** (`lucide_icons`, `phosphor_flutter`) — een `IconData`-set die
   werkt als `Icons.*`, dus `Icon(...)`, `size:`, `color:` blijven hetzelfde. Verreweg het minste
   werk, één afhankelijkheid.
3. **`flutter_svg` met de SVG's uit deze schets** — meer controle, maar SVG's parsen bij elke build.

Voorkeur: **2**, met één waarschuwing uit dit project zelf. `--tree-shake-icons` snijdt een glyph
weg die alleen in een ternaire voorkomt en nergens als constante — dat kostte in `9bf1e38` een
onzichtbare knop in een release-build. Wat er ook gekozen wordt: **verifiëren in een release-build op
het toestel, niet in debug.**
