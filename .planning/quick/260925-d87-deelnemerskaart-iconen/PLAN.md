---
quick_id: 260925-d87-deelnemerskaart-iconen
date: 2026-09-25
backlog: "87"
status: planned
---

# #87: dubbele deelnemerssamenvatting weg, status als icoon

## Doel

De tester (screenshot 25 sept) wees twee dingen aan op de groepsritkaart in
het detail: de telling staat er dubbel in ("2 gaan mee · 2 wachten nog" van
de teller, eronder "2 gaan mee · 2 nog niet" van de telregel), en de status
per persoon is pure tekst. Gevraagd: de dubbele tekst weg en meer iconen.

## Vaststelling (in de code nagekeken)

- De dubbeling zit alléén op het detailscherm: daar staat
  `PelotonCounter` (fietsjes + zin, schets 014) direct boven de telregel
  van CLUB-16 (schets 016). Op Home en de Ritten-tab staat alleen de
  teller; daar is niets dubbel.
- De telregel is de rijkere zin: hij noemt ook "1 kan niet", die de
  teller weglaat. De telregel blijft dus staan en de teller houdt op het
  detail de fietsjes zonder zin.
- De statuswoorden ("gaat mee", "kan niet", "nog geen antwoord") worden
  nergens anders zichtbaar gebruikt dan in `_buildPersonRow`.

## Stappen

1. `PelotonCounter` krijgt een vlag `showText` (standaard aan). Op het
   detail staat hij op `pelotonGroup == null`: bij een groepsrit alleen
   fietsjes, bij een gewone gedeelde rit de zin, want daar is geen
   telregel.
2. `_buildPersonRow`: het statuswoord wordt een icoon in de bestaande
   statuskleur — check, prohibit, hourglass — met het woord als
   `Semantics`-label. Drie verschillende vormen, dus de status hangt niet
   alléén aan kleur; de ARB-sleutels blijven in gebruik en in beide
   talen.
3. Tests: `group_ride_detail_test.dart` rijverwachtingen op icoon i.p.v.
   tekst, statuskleuren via het icoon, plus een test dat de telzin van de
   teller op een groepsrit weg is en bij een gewone gedeelde rit blijft.
   `peloton_counter_test.dart` +1 test voor `showText: false`.
4. `flutter test` en `flutter analyze` op de bestaande baseline.

## Grenzen

- Home en de Ritten-tab blijven zoals ze zijn.
- Geen nieuwe ARB-sleutels, geen sleutels weg: de statuswoorden blijven
  bestaan voor het Semantics-label.
- Geen versiebump en geen release: het bouwen is de taak, het goedkeuren
  op de Oppo is Joost's ronde.
- Geen toestelwerk in deze taak.

## Aanvulling onderweg (Joost, zelfde ronde, 25 sept)

Joost stuurde tijdens de bouw bij: ook de "Toprit"-tekst op de
plankaartjes onder GEPLAND op Home kan weg -- die pil at de breedte van
het vakje op -- en daar mag de score klein voor in de plaats. Dat
past in deze taak (zelfde principe: minder tekst, het getal en de kleur
dragen de betekenis), als tweede commit:

- `ScoreBadge` krijgt een optionele `score`: met die vlag toont de pil
  het getal in de tierkleur in plaats van het woord. Het detail
  (AppBar) houdt het woord.
- Op de plankaart wordt de score-getalpil gezet; de Ritten-tab laat zijn
  eigen pil ("100 Toprit") zoals hij is, die kaart heeft de breedte.
- Het Semantics-label combineert woord en getal ("Toprit, 88"), zodat
  het oordeel voor een screenreader niet tot een getal verzandt.
