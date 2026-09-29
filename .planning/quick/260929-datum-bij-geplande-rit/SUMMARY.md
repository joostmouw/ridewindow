---
quick_id: 260929-datum-bij-geplande-rit
date: 2026-09-29
status: complete (lokaal gecommit, nog niet in een build)
---

# De dag van een geplande rit: Vandaag, Morgen, en daarna met datum

## Wat er gebouwd is (cb0db64)

- `lib/core/ride_day_label.dart`: `rideDayLabel` (Vandaag / Morgen / "Zaterdag
  3 okt.") en `rideDayLabelAbsolute` (altijd weekdag + datum).
- Toegepast op het plankaartje onder PLANNED op Home, op de kop van een rit op
  de rittenlijst, en (absoluut) op de deeltekst van het ritdetail.
- Sleutels `dayToday` / `dayTomorrow` in beide ARB's.
- Unit-tests voor de formatter, plus een widget-test op Home met een rit
  morgen en een rit over tien dagen.

## Vondsten

1. **Eén rit, twee namen.** Home zei "Dinsdag", de rittenlijst "dinsdag 29
   sep.": intl schrijft Nederlandse weekdagen met een kleine letter, de
   ARB-sleutels `day*Full` met een hoofdletter. De formatter zet de eerste
   letter nu altijd hoofd.
2. **De deeltekst had hetzelfde gat.** "Fietsrit Zaterdag 10:00-12:00" in een
   WhatsApp-bericht zegt niet welke zaterdag. Een gedeeld bericht krijgt
   bewust geen "morgen": dat hangt af van wanneer de ander het leest.
3. **Het ritdetail toont helemaal geen dag.** De kopbalk zegt alleen de tijd
   en de score. Niet aangepast in deze ronde; staat open als vraag aan Joost.
4. **In widget-tests is `DateFormat('…', 'nl_NL')` bruikbaar zonder
   `initializeDateFormatting`:** de `GlobalMaterialLocalizations`-delegate in
   `S.localizationsDelegates` laadt de datumsymbolen al. In een kale unit-test
   niet; daar staat de init in `setUpAll`.
5. Analyze ging van 204 naar 202: de verwijderde `_dayName` in het ritdetail
   droeg twee trailing-comma-meldingen.

## Bewust niet aangeraakt

- De vensterkaarten op Home: altijd binnen de zeven dagen van de dagstrip
  erboven, die de datum al toont.
- De optiechips (`EEE d MMM`) en de widget: al met datum, bewust compact.

## Niet geverifieerd

- Op de Oppo: dat vraagt een release-build, en een lokale sideload breekt de
  Play-updates (`docs/RELEASE-ROUTE.md`). Komt mee met de volgende
  internal-build.
