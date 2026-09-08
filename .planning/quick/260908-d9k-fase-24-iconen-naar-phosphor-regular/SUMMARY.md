---
quick_id: 260908-d9k
slug: fase-24-iconen-naar-phosphor-regular
date: 2026-09-08
status: complete
---

# Fase 24 is af — geen systeememoji meer in RideWindow

Phosphor Regular, gekozen door Joost op de volledige set (schets 006).

| | |
|---|---|
| `Icons.*` vervangen | 71, in 18 bestanden (126 verwijzingen) |
| Emoji-plekken vervangen | 12 |
| Unieke glyphs | 66 regular + 4 fill |
| Emoji over in `lib/` en de ARB's | **nul** — machinaal nagelopen |

## Het pub-pakket is onderweg afgevallen, en niet op smaak

`phosphor_flutter` 2.1.0 (mei 2024) doet `class PhosphorIconData extends IconData`,
en Flutter heeft `IconData` sindsdien `final` gemaakt. Het venijn zit in de
volgorde waarin dat opvalt: `pub get` slaagt, `flutter analyze` zwijgt, en dan
faalt **elke** test met

    Error: The class 'IconData' can't be extended outside of its library
           because it's a final class.

Precies de veroudering waarom dit project Isar afwees — alleen merk je het hier
pas bij compileren. Dus dragen we het font zelf, zoals `Outfit.ttf` er al staat:
`Phosphor.ttf` en `Phosphor-Fill.ttf` in `assets/fonts/` plus de codepunten in
`lib/theme/app_icons.dart`. Nul afhankelijkheden, niets dat met Flutter mee moet
bewegen, en de uitwijk was goedkoop omdat het pakket toch alleen een fontwikkel
is.

## Het ontwerpgat uit schets 006 bestond hier niet

Ik meldde dat geen enkele lijnfamilie Materials gevuld-versus-omlijnd heeft voor
de geselecteerde tab, en dat de navigatiebalk dus iets anders moest verzinnen.
Phosphor heeft zes gewichten. `NavigationDestination` houdt gewoon zijn `icon`
(Regular) en `selectedIcon` (Fill); het gedrag is één op één gelijk gebleven.

## Getoetst

- Volledige testsuite groen, inclusief de flaky notificatietest.
- **Release**-APK op de Oppo en een **release**-webbuild. In debug is het font
  compleet en bewijst een test niets: `--tree-shake-icons` snijdt een glyph weg
  die alleen in een ternaire voorkomt (`9bf1e38`). `Phosphor.ttf` houdt 18.144
  bytes over van 488.636 — de 66 glyphs die we gebruiken, en niets ontbreekt.

## Waar de emoji zaten, en wat het werd

| Plek | Was | Werd |
|---|---|---|
| Uurtabel Ride Detail | 🌧 💨 ☀️ ⛅ vooraan een string geplakt | `Icon` naast de tekst |
| Weervenster | 🌡 🌧 💨 als `String emoji`-parameter | `IconData icon` |
| Rider-types Beschikbaarheid | 8 emoji in een recordveld van type `String` | `IconData` |
| Profiel-windvaan | 🚩 met `fontSize` | `Icon` met `size` |
| Welcome | 🚴 op 80 px | de geanimeerde intro (zie `02328fd`) |
| Score-banner | 🟢 🟡 ⚪ | was al dood sinds fase 25, verwijderd |
