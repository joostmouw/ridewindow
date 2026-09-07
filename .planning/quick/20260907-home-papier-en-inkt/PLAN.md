---
task: home-papier-en-inkt
milestone: v4.0
phase: 23
created: 2026-09-07
status: in-progress
---

# Fase 23, stap 1+2 — "Papier en inkt"

Uitvoering van variant **B** uit `.planning/sketches/001-home-hierarchie/`. Joost heeft op
2026-09-07 gekozen voor stap 1+2 eerst, om de onzekere ingreep (de slagschaduw) bewezen te hebben
vóór er vijf schermen op gebouwd worden. Stap 3 t/m 6 blijven expliciet buiten deze taak.

## Wat en waarom

Groen is nu behang: `AppColors.lightSurface == brandLight` (`#C5D4B6`). Dat kost twee dingen. De
oppervlakkenladder heeft geen bereik meer — kaart en achtergrond schelen minder dan 8% helderheid —
en, belangrijker, **een slagschaduw leest niet op een middentoon.** Schaduw is juist het gereedschap
waarmee je één ding vóór de rest zet. Vandaar dat de kaart vandaag op `elevation: 0` staat en het
onderscheid volledig uit kleur moet komen, wat niet lukt.

Na deze taak is de grond papier en doen schaduw en rand het werk.

## Taken

### 1. Kleurrollen omkeren

`lib/theme/app_colors.dart` + `lib/main.dart`

- `lightSurface` van `brandLight` naar `lightSurfaceContainerLowest` (`#FCFDF8`).
- `brandLight` blijft bestaan en blijft accent (chips, tonale knoppen) én achtergrond van de twee
  merkschermen. De constante verdwijnt dus niet, alleen zijn rol als app-achtergrond.

### 2. De twee merkschermen houden hun groen

`welcome_screen.dart`, `onboarding_screen.dart` — expliciete keuze van Joost: daar is het grote
groene vlak een merkmoment, geen behang. Beide zetten nu `colorScheme.surface` als achtergrond en
zouden dus meeliften met de omkering; ze moeten `AppColors.brandLight` expliciet zetten.

Let op de tegel in Onboarding: `_PresetTile` gebruikt óók `colorScheme.surface` als
achtergrond van een niet-geselecteerde tegel. Zonder ingrijpen wordt die wit op groen — een
verandering aan een scherm dat juist ongewijzigd moet blijven.

### 3. Tekstkleuren: de gemeten marge gebruiken

Op papier krijgt elke tekstkleur meer ruimte. Belangrijker dan de winst zelf is wát de meting
blootlegt: `lightTextTertiary` (6,94:1) en `lightTextHint` (6,89:1) zijn op papier **praktisch niet
te onderscheiden**. Twee tokens, één visueel gewicht — dat is letterlijk de vlakheid waar deze
epic over gaat.

Ze worden uit elkaar getrokken:

| Token | Nu | Wordt | Op papier |
|---|---|---|---|
| `lightTextTertiary` | `#4C5C52` | `#5A6B60` | 6,94 → **5,54:1** |
| `lightTextHint` | `#4E5C54` | `#66756B` | 6,89 → **4,75:1** |

Beide blijven boven de AA-drempel van 4,5. Ze halen die drempel echter **niet** meer op
`brandLight` (3,63 en 3,12), dus de twee merkschermen krijgen de oude waarden als
`brandScreenTextTertiary` / `brandScreenTextHint`. Het werk uit backlog #9 wordt daarmee bewaard
waar het nog nodig is in plaats van weggegooid.

### 4. De beste ritkaart laten domineren

`lib/features/home/home_screen.dart` — `_buildRideCard`

- Beide kaarten wit (`surfaceContainerLowest`).
- Beste kaart: slagschaduw + 5px linkerrand in `brandDark`, radius links 8 / rechts 24.
- Overige kaarten: vlak, haarlijn in `surfaceContainerHigh`, géén schaduw.

**De onzekere ingreep.** De kaart zit in een `ClipRRect` zodat de `Dismissible` als afgeronde vorm
wegschuift bij swipe-to-schedule. Die clip snijdt elke `elevation` af — daarom staat de kaart nu op
`elevation: 0`, het codecommentaar waarschuwt er al voor. Oplossing: een `Container` mét
`boxShadow` **om de `ClipRRect` heen**. De schaduw wordt dan door de ouder getekend en valt buiten
het cliprechthoek, terwijl de swipe intact blijft.

Lukt dat niet zonder de swipe te breken: **stoppen en beide opties voorleggen**, niet zelf tussen
schaduw en gesture kiezen.

## Buiten scope

Stap 3 (typografische schaal), 4 (weerbalken herschalen + oordeelwoord), 5 (dagstrip en
periodefilter), 6 (sweep over Rides, Ride Detail, Peloton, Profiel, Beschikbaarheid en de twee
overlays). Die schermen gaan er tijdelijk anders uitzien dan Home — dat is de prijs van eerst
kijken, en bewust.

## Afronding

`flutter analyze`, volledige testsuite, en `flutter build web --release` zodat het resultaat in
Chrome te zien is. De bekende post-19:00-UTC-notificatietest mag falen (geen regressie).
