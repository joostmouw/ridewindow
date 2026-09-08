---
sketch: 005
name: hugeicons-volledig
question: "Hoe ziet élk icoon in RideWindow eruit in Hugeicons, en zijn er gaten?"
winner: "Hugeicons"
tags: [iconografie, fase-24, mapping, implementatie]
---

# Sketch 005: De hele set in Hugeicons

Joost koos **Hugeicons** op 2026-09-08 (schets 004) en vroeg de volledige set te zien. Dit is die
set: geen keuzeschets meer maar de **werktekening voor de implementatie**.

## Waarom álle iconen en niet alleen de emoji

Fase 24 begon bij de zestien systeememoji. Maar de app tekent daarnaast **71 Material-iconen**, en
die dragen de Google-hand net zo goed. Alleen de emoji vervangen levert een app op die half
Hugeicons en half Material is — en twee handen op één scherm lezen onrustiger dan één vreemde hand.
Daarom staat hier de volledige inventaris.

## De cijfers

| | Aantal |
|---|---|
| Material-iconen in `lib/` | **71** |
| Daarvan gemapt op Hugeicons | **71** — geen gat |
| Emoji-plekken | **12** |
| Unieke Hugeicons-vormen die dit vraagt | **63** |
| Vormen die niet bestaan in Hugeicons | **0** |

De mapping is machinaal getoetst tegen de codebase: elk `Icons.*` in `lib/` komt in de tabel voor, en
er staat niets in de tabel dat de app niet gebruikt.

## How to View

```bash
python3 -m http.server 8765     # vanuit de repo-root
open http://localhost:8765/.planning/sketches/005-hugeicons-volledig/index.html
```

Drie knoppen: **maat** (24 / 13 / 20 px — 13 is de weerbalk, 20 de kleinste tekstregel), **lijndikte**
(2 / 2,5 / 1,5) en **donker**. Elke cel toont het huidige icoon links, de vervanger rechts, en
daaronder de bestanden waar hij staat.

## Een paar keuzes die het bekijken waard zijn

- **`Icons.air` → `wind`** en **`Icons.grain` → `rain`.** Material koos hier abstracte namen voor
  weerbegrippen; Hugeicons noemt ze gewoon wat ze zijn. Dat maakt de code ook leesbaarder.
- **`Icons.thermostat` → `thermometer`.** Dit is het icoon dat sinds `2bcca2a` in de gevoelsbalk
  staat, dus die verandert mee.
- **`Icons.block` → `unavailable`.** De enige waar ik twijfelde: `block` staat bij een geblokkeerd
  tijdvak, en `unavailable` zegt dat directer dan een verbodsbord.
- **Drie sterren, één vorm.** `star`, `star_rounded` en `star_border` worden alle drie `star`; het
  verschil tussen gevuld en open moet dan uit kleur komen, niet uit een tweede glyph.
- **`home` en `home_outlined` worden hetzelfde icoon.** Dat geldt voor meer paren. Material gebruikt
  gevuld-versus-omlijnd om selectie in de navigatiebalk aan te geven; Hugeicons heeft die tweedeling
  niet in de stroke-variant. **Dit is het enige echte ontwerpgat van de hele overstap:** de
  navigatiebalk moet zijn geselecteerde tab op een andere manier aanwijzen — kleur, gewicht of een
  indicator. Dat is een beslissing, geen vertaling.

## Wat het kost om te bouwen

Met het pub-pakket houdt de aanroep dezelfde vorm:

```dart
Icon(Icons.directions_bike, size: 24)        // nu
Icon(HugeIcons.strokeRoundedBicycle01, size: 24)   // straks
```

Dus 71 regels vervangen, geen herbouw. De twaalf emoji-plekken zijn meer werk: daar staat nu een
`Text` met een string, en die moet een `Icon` worden met kleur en uitlijning — plus in
`availability_screen.dart` verandert het record-type van `({String icon, ...})` naar
`({IconData icon, ...})`.

**Verifiëren in een release-build op het toestel, niet in debug.** `--tree-shake-icons` snijdt een
glyph weg die alleen in een ternaire voorkomt en nergens als constante; dat kostte in `9bf1e38` een
onzichtbare knop. Bij 71 nieuwe iconen tegelijk is dat risico navenant groter.
