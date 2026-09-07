---
task: weerbalken
milestone: v4.0
phase: 23
completed: 2026-09-07
status: complete
commits: [c7b7a32]
---

# Stap 4 — weerbalken van versiering naar informatie

Vooraf uitgetekend als HTML-preview (`scratchpad/stap-4-weerbalken.html`) en op twee punten door
Joost bijgestuurd: de Engelse woorden bleven zoals voorgesteld, **"Vlagerig" werd "Winderig"**
("zegt mij niks"), en het ingezoomde bereik is bevestigd boven de volle schaal.

## Wat er is veranderd

| | Was | Is |
|---|---|---|
| Regenschaal | 0–10 mm, ideaalzone 5% breed | 0–3 mm, zone ~17% |
| Windschaal | 0–60 km/u | 0–40 km/u |
| Tempschaal | −10–45° | 0–35° |
| Oordeel | geen | Dry/Light/Showers/Wet · Calm/Breezy/Gusty · Chilly/Ideal/Warm |
| Andere kaarten | drie volle balken | één regel: `13° · Dry · 7 km/h` |

De grenzen volgen de tolerantie uit Profiel, niet vaste getallen — dat is expliciet getest.

## Twee dingen die niet in het plan stonden

**De eerste build was stuk, en de fout is leerzaam.** De `CustomPaint` zat in een `SizedBox` met
alleen een hoogte. In een `Column` krijgt die een *losse* breedte-constraint en valt zonder kind
terug op 0. De painter kreeg dus `size.width == 0`, en `(...).clamp(left + 4, w)` gooide daar een
`RangeError` omdat de ondergrens boven de bovengrens uitkwam. Een exceptie tijdens `paint` neemt de
héle kaart mee, niet alleen de balk — vandaar dat er alleen een temperatuurregel en een groot gat
overbleef. In de vorige versie kwam de breedte uit een `Expanded` in een `Row`, dus het probleem
bestond daar niet.

Gedicht op drie plekken, want één ervan is niet genoeg: `width: double.infinity`, een
`if (w <= 0) return;` bovenin de painter, en de twee `clamp`-aanroepen vervangen door expliciete
grenzen die niet kunnen omklappen.

**De waarde toonde valse precisie.** `13.9°` op een kaart die verder alleen hele graden toont, en
de balk staat er juist om te laten zien dat het niet op de tiende aankomt. Graden en km/u worden nu
afgerond; regen houdt zijn decimaal, want daar zit het verschil tussen droog en nat in de tienden.

## Gecorrigeerd t.o.v. een eerdere aanname

Ride Detail gebruikt `WeatherIndicatorBar` **niet** — het heeft een eigen `_buildWeatherRow`. Deze
stap raakt dus alleen Home. Eerder is hier het tegenovergestelde beweerd.

## Nog open in fase 23

Stap 3 (typografische schaal), stap 5 (dagstrip en periodefilter rustiger) en stap 6 (de sweep over
Rides, Ride Detail, Peloton, Profiel, Beschikbaarheid en de twee overlays met hardcoded kleuren).
