---
task_id: 260907-kqr
slug: fase-23-stap-3-typografische-schaal-echt
date: 2026-09-07
milestone: v4.0
phase: 23
status: complete
---

# Fase 23 stap 3 — de typografische schaal echt gebruiken

Punt 3 van de implementatielijst in `.planning/sketches/001-home-hierarchie/README.md`,
letterlijk: *"de dagnaam op de beste kaart naar `headlineSmall` (24px), op de
andere kaarten `titleMedium` (16px), en de score van 36px naar 46px op de beste
en 26px op de rest. Nu staat alles op dezelfde maat en dat is de helft van de
vlakheid."*

**Dit weegt zwaarder dan toen het werd opgeschreven.** De schets ging ervan uit
dat de beste kaart óók een slagschaduw en een accentstaaf zou dragen; die zijn
er sinds vanmiddag uit (Joost's keuze). De pil zegt nu *dat* het de beste is en
de maat moet het láten zien — typografie is daarmee van extra signaal het
voornaamste geworden.

## Taken

- [x] T1 — `ScoreDisplay` krijgt een `ScoreEmphasis` (hero/normal) in plaats van
      één vaste maat voor elke score.
- [x] T2 — De dagnaam op de ritkaart volgt `isBest`.
- [x] T3 — `flutter analyze` + `flutter test` schoon, geverifieerd op de Oppo.

## Rollen, geen puntgroottes

De schets noemt 46 en 26. Die staan niet in de schaal, en Material 3 zegt
expliciet dat je vormen en maten uit tokens haalt in plaats van uit losse
getallen. Vertaald naar de dichtstbijzijnde rollen in `app_typography.dart`:

| | Beste kaart | Overige kaarten |
|---|---|---|
| Dagnaam | `headlineSmall` (24) | `titleMedium` (16) |
| Score | `displayMedium` (45) | `headlineMedium` (28) |
| Oordeel | `titleMedium` (16) | `titleSmall` (14) |

## Buiten Home

Rides (`planned_rides_screen.dart`) gebruikt `ScoreBadge` en `titleMedium` voor
élke regel. Daar bestaat geen "beste" — het zijn ritten die je al hebt
ingepland — dus daar hoort geen maatverschil. Bewust ongewijzigd gelaten.
