---
task: peloton-systeem-uit-schets-014
date: 2026-09-21
status: complete
commits: [6a76c57, 0b6c735, 84e0240, 4801ab7]
---

# Peloton-systeem gebouwd (schets 014)

## Wat er nu staat

| Plek | Voor | Na |
|---|---|---|
| Home, links op de kaart | het rol-icoon (vlag/koppen/fietser) in blauw | **het peloton-lint** bij een groepsrit, **één fietser** als je alleen gaat |
| Rolregel, jij organiseert | vlag | **megafoon** (`megaphone-simple`, 0xe642) |
| Rolregel, je gaat mee / alleen jij | drie koppen / fietser | **geen icoon**, de zin begint links |
| Onder de rit | "3 gaan mee · 1 wacht nog", alleen bij je eigen rit | **teller**: een fietsje per persoon, wachtenden doorzichtig, bij élke gedeelde rit |
| Rittenlijst | — | teller erbij, **geen kolom links** (bewust, 2026-09-21) |
| Detail | rolregel | lint in de kop, teller boven de namen |

## Beslissingen tijdens het bouwen

- **Geen icoonfont, maar één pad in Dart** (`lib/theme/ride_mark.dart`). `Icon` legt zijn glyph
  altijd in een vierkant van `size × size`; het lint is 2,3× zo breed als hoog en zou over de
  tekst ernaast heen lopen terwijl de lay-out 20px breed denkt te zijn. Het pad is diffbaar,
  heeft geen binair bestand nodig en deelt zijn grondlijn met de enkele fietser.
- **De uitsparing snijdt met het dichte silhouet**, niet met de omlijning: in de eerste render
  schemerden door de wielgaten van de voorste fietser stukjes van de fietser erachter.
- **Afgezegde ritten krijgen geen teller.** Een afzegging is te vinden maar vraagt geen aandacht.
- `acceptedCount` telt de organisator niet mee (die staat niet in zijn eigen deelnemerslijst),
  dus bij je eigen rit zijn de fietsjes je maatjes en bij andermans rit tel jij mee. De fietsjes
  volgen de zin ernaast exact — dat is de afspraak die de test bewaakt.

## Bewijs

- Merkteken uit Flutter zelf naar PNG gerenderd en bekeken op 14/16/20/64 px: identiek aan de schets.
- `flutter analyze`: geen enkele error of warning in `lib/` en `test/`.
- `flutter test`: **719 tests groen** (5 nieuw: teller-semantiek, de +n-grens, geen teller bij
  afgezegd of solo, en dat alleen de organisator nog een icoon draagt).
- De rittenlijst tijdelijk op telefoonbreedte (392dp) gedraaid: geen overflow.

## Nog open

- **Op glas bekijken.** Er hing geen toestel aan de Mac; het lint bij 14 en 16 px op de Oppo
  beoordelen staat nog. Web-build draait op `http://localhost:8123`.
- Home met een échte groepsrit is alleen ingelogd te zien; de losse widgets zijn wel getest.
