---
quick_id: 260929-datum-bij-geplande-rit
date: 2026-09-29
status: planned
bron: vraag van Joost na de toestelcontrole van 62
---

# De dag van een geplande rit: Vandaag, Morgen, en daarna met datum

## Wat er mis is

- Het plankaartje onder PLANNED op Home toont alleen de weekdag
  (`_formatDayName`). PLANNED toont de eerstvolgende drie ritten, niet alleen
  die van deze week: een rit over tien dagen heet dan net zo "Saturday" als
  die van deze zaterdag.
- Dezelfde rit heet op de rittenlijst "Tuesday 29 Sep" (`EEEE d MMM`), en in
  het Nederlands "dinsdag 29 sep." met een kleine letter, terwijl Home
  "Dinsdag" zegt. Eén rit, twee namen.
- De deeltekst op het ritdetail ("Fietsrit Zaterdag 10:00-12:00") heeft
  evengoed alleen de weekdag, en wordt gelezen door iemand anders, op een
  ander moment.

## Hoe goedlopende apps dit doen

- **Google Calendar** (agenda): "Today" en "Tomorrow" voor de eerste twee
  dagen, daarna weekdag + datum.
- **WhatsApp, Gmail**: relatief voor dichtbij, een datum voor verder weg.
- **Strava, Komoot** (geplande ritten/evenementen): altijd weekdag + korte
  datum.
- **Wat een bericht draagt dat een ander leest**, is overal absoluut: een
  uitnodiging van Google Calendar zegt nooit "morgen", want morgen hangt af
  van wanneer je hem opent.

Overgenomen: Vandaag/Morgen, daarna weekdag + korte datum, in één vorm voor
Home en de rittenlijst. Bewust anders: de deeltekst krijgt geen relatief woord,
alleen weekdag + datum.

## Stappen

1. `lib/core/ride_day_label.dart`: `rideDayLabel(start, s, locale, now:)` en
   een absolute variant. Vergelijkt kalenderdagen (niet 24 uur), zodat 23:00
   en 01:00 niet dezelfde dag worden en de zomertijdwissel niets verschuift.
   Eerste letter hoofdletter, ook in het Nederlands.
2. Nieuwe sleutels `dayToday` / `dayTomorrow` in beide ARB's.
3. Toepassen: plankaartje op Home, de kop van een rit op de rittenlijst, de
   deeltekst op het ritdetail (absoluut).
4. Niet aangeraakt, met reden: de vensterkaarten op Home (altijd binnen de
   zeven dagen van de dagstrip erboven, die de datum al toont), de
   optiechips (`EEE d MMM`, bewust compact), de widget.
5. Unit-test voor de formatter (vandaag, morgen, overmorgen, over een week,
   over de jaargrens, zomertijd), widget-tests bijwerken, suite en analyze,
   bekijken op de Oppo.
