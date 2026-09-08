---
quick_id: 260908-d9k
slug: fase-24-iconen-naar-phosphor-regular
date: 2026-09-08
status: in-progress
---

# Fase 24 afmaken — alle iconen naar Phosphor Regular

Joost koos **Phosphor** (schets 006, 2026-09-08) en **Regular** als gewicht.

## Wat er verandert

| | Aantal |
|---|---|
| `Icons.*` in `lib/` | 71 → `PhosphorIconsRegular.*` |
| Emoji-plekken (`Text` met een string) | 12 → `Icon` |
| Unieke Phosphor-glyphs | 65, alle 65 aanwezig in het pakket |

## Twee dingen die vooraf zijn nagekeken

**Het pakket is twee jaar oud.** `phosphor_flutter` 2.1.0 is van mei 2024. Dit project wees Isar af
omdat de laatste release drie jaar oud was, dus dat weegt hier mee. Het verschil: dit pakket is een
**fontwikkel** — vijf `.ttf`-bestanden plus gegenereerde `IconData`-constanten, zonder platformcode
en zonder API die met Flutter mee moet bewegen. Het lost op tegen de gelockte deps en het compileert.
Valt het ooit om, dan is de uitwijk goedkoop: het font in `assets/` zetten en de constanten zelf
genereren, precies zoals `Outfit.ttf` er nu al staat.

**Het ontwerpgat uit schets 006 bestaat hier niet.** Ik meldde dat geen enkele lijnfamilie Materials
gevuld-versus-omlijnd heeft voor de geselecteerde tab. Phosphor heeft zes gewichten, waaronder
**Fill**. `NavigationDestination` houdt dus gewoon zijn `icon` (Regular) en `selectedIcon` (Fill), en
het gedrag blijft één op één gelijk.

## Volgorde

1. Pakket toevoegen. **Gedaan** — lost op tegen de lockfile.
2. De 71 `Icons.*` mechanisch vervangen, per bestand de import erbij. Compileren, testen, committen.
3. De 12 emoji-plekken. Die zijn stuk voor stuk anders: een `Text` in een `Row`, een recordveld van
   type `String`, een string die met tekst wordt samengeplakt. Eén voor één, niet met een regex.
4. Release-**web**-build en release-**APK** met het oog nakijken. `--tree-shake-icons` snijdt een
   glyph weg die alleen in een ternaire staat en nergens als constante — dat kostte in `9bf1e38` een
   onzichtbare knop. Bij 83 nieuwe iconen tegelijk is dat risico navenant groter, en in debug zie je
   er niets van.

## Wat hier níét in zit

De vraag of `recommendClothing()` van de gevoelstemperatuur moet uitgaan in plaats van de kale
meting. Dat verandert wat de app adviseert en ligt bij Joost.
