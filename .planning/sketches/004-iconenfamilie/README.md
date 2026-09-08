---
sketch: 004
name: iconenfamilie
question: "Welke iconenfamilie deelt de hand van het RW-logo en van Outfit?"
winner: null
tags: [iconografie, fase-24, merk, weerbalken, rider-types]
---

# Sketch 004: Iconenfamilie

## Design Question

Na de gevoelsbalk (schets 003) blijven er **zestien plekken** over die een systeememoji tekenen — en
die tekent het besturingssysteem, dus ze zien er per platform anders uit. In de release web-build van
2026-09-07 waren 🌧 en 💨 in de uurtabel zelfs even een leeg blokje.

Joost wil ze **persoonlijk** maken, niet Material. De eerste formulering daarvan was "een beetje
handgetekend", maar de scherpere versie kwam er in het gesprek uit: *iconen die iets weghebben van
het gekozen lettertype en het app-logo*. Dat is een toetsbaar criterium, en daarom staan de families
in deze schets **naast het merk** in plaats van naast elkaar.

## De hand die al vastligt

Het app-icoon is een RW-monogram, met een stift geschreven in één vloeiende haal. `app_typography.dart`
beschrijft het al: *"overal dezelfde lijndikte, ronde uiteinden, bijna cirkelvormige bochten, nergens
een scherpe hoek."* Daaruit volgen vier dingen om op te vergelijken:

1. **Ronde uiteinden** — elke lijn eindigt rond, nergens vlak afgesneden.
2. **Gulle bochten, geen scherpe hoek** — waar de lijn keert, keert hij in een boog.
3. **Eén doorlopende lijn van gelijke dikte** — licht verloop, geen dik/dun-contrast.
4. **De geometrie van Outfit** — bijna cirkelvormig, grote binnenruimte, open vormen.

**De spanning die er al in zit:** het monogram heeft *ronde* uiteinden, Outfit *vlakke*. Dat is een
bewuste keuze (zie `app_typography.dart`). De iconen mogen dus kiezen bij welk van de twee ze
aansluiten — de knop **Ronde uiteinden** in de schets laat het verschil zien.

## Twee doodlopende wegen, en waarom ze dat zijn

**Een kant-en-klaar handgetekend icoonpakket bestaat niet voor dit domein.** Nagekeken via de
Iconify-catalogus (238 collecties): er zijn er precies drie in een handgetekende stijl, en geen
enkele dekt wat RideWindow nodig heeft.

| Set | Iconen | Mist |
|---|---|---|
| Pepicons Pencil | 1275 | thermometer, wind, berg, zonsopgang, zonsondergang, kracht |
| Streamline Freehand (gratis deel) | 1000 | vrijwel alles uit dit domein |
| Streamline Freehand Color | 1000 | idem |

Zes van de twaalf begrippen ontbreken bij de beste kandidaat, en juist de weer-iconen — de kern van
deze app. Beide zijn bovendien CC BY 4.0, dus attributie in de app verplicht.

**Een schone familie door een schetsfilter halen werkt ook niet.** Geprobeerd met RoughJS (elke lijn
twee keer, licht wiebelend, vaste seed). Bij 80 px oogde het aardig, maar het is het verkeerde soort
"handgemaakt": het logo is *zelfverzekerd* handschrift, geen krasserige schets. Het filter maakte de
vormen juist onzeker, en bij 13 px werd het ruis. Afgevoerd na één ronde — de code staat niet meer in
de schets, alleen hier als vastgelegde doodlopende weg.

## Varianten

Zeven families, alle als SVG in te sluiten of via een pub-pakket beschikbaar:

| Familie | Hand | Dekking van de 12 begrippen |
|---|---|---|
| **Hugeicons** | ronde uiteinden, gulle bochten, vol | **12/12** |
| **Mynaui** | zachter en ronder dan Lucide, iets lichter | 11/12 (mist kracht) |
| **Lucide** | monoline, ronde uiteinden én ronde hoeken, 24-raster | 12/12 |
| **Solar · linear** | zeer rond en open, cirkelvormige constructie | 9/12 (mist fiets, berg) |
| **Phosphor · regular** | 256-raster, dunne elegante lijn, zes gewichten | 10/12 |
| **Phosphor · duotone** | zelfde tekening plus een tweede vlak op 20% | 10/12 |
| **Tabler** | monoline maar hoekiger geconstrueerd | 12/12 |

De twee knoppen bovenin sturen **lijndikte** (1,5 / 2 / 2,5) en **uiteinden** (rond / vlak) voor álle
families tegelijk — ook voor de sets die hun eigen gewicht meeleveren, want anders vergelijk je
diktes in plaats van handschriften.

## How to View

```bash
python3 -m http.server 8765     # vanuit de repo-root, anders laadt Outfit niet
open http://localhost:8765/.planning/sketches/004-iconenfamilie/index.html
```

De iconen zitten ingesloten in `icons.js`, opgehaald van de officiële pakketten. De schets werkt dus
offline en verandert niet meer mee met nieuwe pakketversies.

## What to Look For

1. **De merktoets bovenaan.** Logo, Outfit en de zeven families in één oogopslag. Als een familie
   hier al vloekt, hoeft de rest niet.
2. **80 px op Welcome** is de scherpste vergelijking met het logo — daar zie je de hand.
3. **13 px in de weerbalken** is de harde ondergrens. Een familie die daar uit elkaar valt, valt af,
   hoe mooi hij op 80 px ook is.
4. **De rode streepjes** in sectie 4 zijn de echte kosten: elk streepje is een icoon dat in dezelfde
   hand bijgetekend moet worden.

## Aanbeveling

**Hugeicons.** Het is de enige familie die alle twaalf begrippen dekt én de rondste, volste hand
heeft van de zeven — ronde uiteinden, gulle bochten, geen scherpe hoek. Op 80 px staat hij het
dichtst bij het monogram; op 13 px houdt hij zich staande omdat de vormen vol zijn in plaats van
fijn. Met lijndikte 2 tot 2,5 nadert hij het stiftgewicht van het logo.

Tabler is de tegenpool: het meest technische en hoekigste van de zeven. Als geometrische strakheid
het doel was zou dat de keuze zijn, maar dat is het hier niet.

## Ná de keuze

1. **Het pub-pakket van de familie** — `IconData`-set die werkt als `Icons.*`, dus `Icon(...)`,
   `size:` en `color:` blijven ongewijzigd. Minste werk, één afhankelijkheid.
2. **`flutter_svg` met de SVG's uit deze schets** — meer controle, parsen bij elke build.
3. **De gebruikte glyphs als `CustomPainter`-paden** — nul afhankelijkheden, ~16 vormen met de hand
   overzetten.

Voorkeur: **1**, met één waarschuwing uit dit project zelf. `--tree-shake-icons` snijdt een glyph weg
die alleen in een ternaire voorkomt en nergens als constante — dat kostte in `9bf1e38` een
onzichtbare knop in een release-build. Wat er ook gekozen wordt: **verifiëren in een release-build op
het toestel, niet in debug.**
