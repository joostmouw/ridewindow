---
quick_id: 260921-p3d
slug: agenda-export-in-de-taal-van-de-app-en-de-eenheden
date: 2026-09-21
status: complete
---

# Agenda-export in de taal van de app, en in de eenheden

Wat naar Google Calendar ging (event-titel en -omschrijving) en wat de
deel-knop deelde, was altijd Nederlands en altijd km/u, ongeacht de gekozen
taal of eenheden. `CalendarService.buildWeatherSummary` bakte dat zelf, met
GoogleSignIn-code in dezelfde klasse. Dat is nu gescheiden: de service blijft
een pure datalaag (geen `S`, geen `BuildContext`, geen eenhedenkennis),
`ride_detail_screen.dart` bouwt de tekst.

## Wat er nu staat

- **`calendarWind` bakt geen eenheid meer in.** Was `"{speed}km/u wind"` /
  `"{speed}km/h wind"`; is nu `"{speed} wind"` in beide ARB's. De aanroeper
  geeft het volledige `"12 km/h"`-stuk mee, het patroon van de bestaande
  `windFrom`.
- **`CalendarService.addRideSlotToCalendar`** neemt nu `{required String
  title, required String description}` aan in plaats van een
  `forecasts`-lijst. `buildWeatherSummary` en de private `_fmtTime` zijn
  vervallen; de nu ongebruikte `hourly_forecast.dart`-import is mee weg.
- **Eén nieuwe bron in `ride_detail_screen.dart`:** `_weatherSummaryText()`
  bouwt de samenvatting via `S.of(context)` en `ref.read(unitsProvider)`
  (temp met `convertTemp`/`units.temp.suffix`, neerslag met `calendarDry`,
  wind met `convertWind`/`windSuffix`/`calendarWind`), `_calendarEventTitle()`
  bouwt de titel via `calendarEventTitle(timeRange)`. `_addToCalendar()` en
  `_shareSlot()` roepen beide dezelfde methode aan -- vóór deze taak riep
  `_shareSlot()` `CalendarService.buildWeatherSummary` rechtstreeks aan en
  lekte het Nederlands/km-u-probleem dus een tweede keer, los van de
  agenda-knop.
- **Tests:** de oude `CalendarService.buildWeatherSummary`-testgroep (5
  tests) is weg; een nieuwe `CapturingFakeCalendarService` legt title/
  description vast, en een regressiematrix van 7 widget-tests bewijst NL,
  EN, mph, Beaufort, Fahrenheit en de lege-forecast-val-terug in beide talen.
  `wrapInMaterial` accepteert nu `locale:` en `units:`.

## Testuitslag

`flutter test`: **744/744 groen** (was 742; -5 oude buildWeatherSummary-tests,
+7 nieuwe regressiematrix-tests via `ride_detail_screen_calendar_test.dart`).
`flutter analyze`: **200 infos**, exact de baseline, geen nieuwe.

## Commits

1. `fix(260921-p3d): calendarWind bakt niet langer km/u in de vertaling` --
   ARB-fix + CalendarService dom maken.
2. `fix(260921-p3d): agenda- en deel-tekst volgen nu de taal en eenheden van
   de app` -- de bedrading in `ride_detail_screen.dart`.
3. `test(260921-p3d): regressiematrix voor taal en eenheden in de
   agenda-tekst` -- fakes meetrekken, 7 nieuwe scenario's.

## Vondsten die niet in scope zaten (bewust laten liggen)

**1. De homescreen-widget schrijft nog vast Nederlands.**
`lib/services/widget_update_service.dart` zet de tier-labels ("Toprit",
"Fijne rit", "Te doen", "Binnenblijver"), de datum
(`DateFormat('EEE d MMM', 'nl_NL')`) en de duur-suffix ("4u") altijd in het
Nederlands -- ongeacht de apptaal. Het eigen commentaar op regel 32-35 zegt
dat dit bij #67 zou meeverhuizen; dat is niet gebeurd, en deze taak breidde
het plan bewust niet uit omdat het een ander subsysteem is (WorkManager-
isolate, geen `BuildContext`, heeft `S.delegate.load(Locale(...))` uit
`main.dart:157` nodig in plaats van het `BuildContext`-patroon van deze
taak). Kandidaat voor een eigen quick-taakje.

**2. Asymmetrische afvang van de geannuleerde OAuth-flow.**
`CalendarService` gooit op regel 176 en 234 een hardgecodeerde
`Exception('Aanmelden geannuleerd')`. In `_addToCalendar()`'s catch-blok komt
die rauwe Nederlandse tekst terecht in `s.couldNotAdd(e.toString())`, ongeacht
apptaal -- geen exportlek (verlaat het toestel niet), maar wel een interne
foutmelding die niet vertaalt. `availability_screen.dart` (regel 891-893)
herkent dezelfde string al met een `.contains('geannuleerd')`-check en toont
daarna wél de vertaalde `s.calendarSignInCanceled`; `ride_detail_screen.dart`
doet die stap niet. Kandidaat: een niet-vertaalde sentinel-Exception (of
typed exception) in plaats van string-matchen op Nederlandse tekst, en
dezelfde `.contains(...)`-aanpak ook in `_addToCalendar()`.

## Self-Check: PASSED

- `lib/services/calendar_service.dart` -- FOUND, `buildWeatherSummary`
  verwijderd, `grep` bevestigt geen `km/u`/`buildWeatherSummary` meer.
- `lib/features/detail/ride_detail_screen.dart` -- FOUND,
  `_weatherSummaryText`/`_calendarEventTitle` aanwezig, geen
  `buildWeatherSummary`-referentie meer.
- Commits `a108b08`, `2042624`, `e463a97` -- alle drie gevonden in
  `git log --oneline`.
- `flutter test`: 744/744. `flutter analyze`: 200 infos.
