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

## Wat de web-ronde opleverde (2026-09-21)

Joost keek mee op `localhost:8123` (de web-client kreeg daarvoor `http://localhost:8123` als
toegestane JavaScript-origin; alleen `:5000` stond er, en die poort is op de Mac bezet door
AirPlay). Daar bleek de tellerzin op het Home-kaartje af te kappen: *"Nobody has answered yet ·
1 still to a..."*. Twee commits verder:

- Home krijgt een korte lezing (`1 wacht` / `3 mee · 1 wacht`), met twee nieuwe l10n-sleutels.
- En belangrijker: de teller **meet zelf** hoeveel ruimte er over is en kiest pas dan. Het was
  namelijk geen Home-probleem -- op een smalle telefoon viel dezelfde Engelse zin ook in de
  rittenlijst buiten de kaart, en die is niet `dense`. Nu geldt overal: past de hele zin, dan
  staat hij er; anders de korte. Ongeacht scherm, taal of ingestelde tekstgrootte.

## Uitgerold

`1.0.38+49` staat op **internal** en als dezelfde bytes op **alpha** (gaat daar langs Google's
review). Release-notities 311 (nl) en 293 (en) tekens, ruim onder de grens waarboven de winkel
een zin afkapt. Versie gebumpt in `pubspec.yaml` én `lib/core/app_version.dart`; blok 49 staat
in `docs/testers/changelog.md`.

## Nog open

- ~~Op glas bekijken.~~ **Gedaan (Joost, 2026-09-21):** het lint is op het toestel bekeken en
  goedgekeurd -- het slibt niet dicht op de maat waarop het in de app staat. De afstelling
  (schaal 0,82, afstand 420, tussenruimte 86, halve dikte-correctie) staat daarmee vast.
- **Het detailscherm** is niet met eigen ogen gezien: tikken lukte niet in de browsersessie
  (muis-events liepen vast) en `/detail` is niet via een URL te bereiken -- die route krijgt
  zijn rit als `extra` mee.
- `main` loopt ver voor op `origin`; pushen wacht op Joosts sein.
