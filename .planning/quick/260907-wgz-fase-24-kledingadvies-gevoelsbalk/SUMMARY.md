---
quick_id: 260907-wgz
slug: fase-24-kledingadvies-gevoelsbalk
date: 2026-09-07
status: complete
---

# Fase 24 — het kledingadvies is de gevoelsbalk geworden

Schets 003 variant A, uitgevoerd. De emoji-pil is weg; op Ride Detail staat nu
een balk met de gevoelstemperatuur, de vier kledingbanden als schaal, en de
kledinglijst eronder.

## Wat er is gebeurd

| Bestand | Wat |
|---|---|
| `lib/features/shared/clothing_tip.dart` | `ClothingCombo` draagt zijn eigen bandgrenzen plus `forFeelsLike()`; `recommendClothing` leest daaruit. De emoji-widget is verwijderd. |
| `lib/features/shared/feels_like_bar.dart` | Nieuw. De balk, in de anatomie van `weather_indicator_bar.dart`, met infovenster. |
| `lib/features/detail/ride_detail_screen.dart` | De kledingkaart is een kolom: kop, balk, lijst. |
| `lib/l10n/app_{nl,en}.arb` | Zes nieuwe strings. NL is de template — daar staan de placeholder-types. |
| `test/features/clothing_bands_test.dart` | Nieuw, 8 tests op de grenzen en de rekenregel. |
| `test/features/ride_detail_screen_test.dart` | Twee finders aangescherpt, zie hieronder. |

## Drie dingen die het uitvoeren opleverde

**1. De app sprak zichzelf tegen, en dat was zonder de balk niet te zien.** De
weerlijst toont `apparentTemperatureC` van Open-Meteo als "feels like 16°C". De
balk rekent iets anders — dezelfde meting minus de wind die je zelf maakt — en
kwam op 14°. Twee getallen onder dezelfde woorden, vier centimeter uit elkaar.
Het label heet daarom **"On the bike" / "Op de fiets"** en niet "feels like",
en het infovenster benoemt het verschil met zoveel woorden. Pas toen de balk
er stond viel dit op; de emoji-pil verborg het.

**Open vraag voor Joost:** moet `recommendClothing()` niet gewoon van
`apparentTemperatureC` uitgaan in plaats van de kale temperatuur? Dan is het
één keten (16 gevoeld, min fietswind, is 14) in plaats van twee losse
berekeningen. Het verandert wél wat de app adviseert, en dat raakt de
kernwaarde — vandaar niet stilzwijgend gedaan.

**2. `find.byIcon` was te grof geworden.** Twee tests zochten de "i"-knop in de
score-banner met `find.byIcon(Icons.info_outline)`. De gevoelsbalk heeft er ook
een, dus die finder vond er twee. Nu `find.widgetWithIcon(IconButton, ...)` —
de banner-knop is de enige `IconButton` met dat icoon, en de test zegt daarmee
ook preciezer wat hij bedoelt.

**3. De bandgrenzen zijn nu één bron.** De drempels 20/14/5 stonden als losse
getallen in een if-keten. De balk tekent diezelfde grenzen; zouden ze uit elkaar
lopen, dan staat de markering in de ene band terwijl de tekst een andere noemt.
Een test bewaakt nu dat de banden zonder gat of overlap op elkaar aansluiten.

## Getoetst

- `flutter analyze` op de gewijzigde bestanden: schoon.
- Volledige suite: alleen de bekende flaky notificatietest faalt (die faalt na
  19:00 UTC en staat los van dit werk).
- **Release web-build, met het oog:** het advies staat er, het infovenster
  opent, en `Icons.thermostat` overleeft `--tree-shake-icons` — dat laatste is
  precies waar `9bf1e38` op stukliep, dus in debug testen zou niets bewezen
  hebben.

## Wat blijft liggen

De zestien andere systeememoji (🌡 🌧 💨 🚴 🏔 🚩 en de acht rider-types). Joost
wil die persóónlijk maken, niet Material. Voorstel: een karaktervolle open
familie (Lucide, Phosphor) naast elkaar renderen in de échte schermen en kiezen
— schets 004.
