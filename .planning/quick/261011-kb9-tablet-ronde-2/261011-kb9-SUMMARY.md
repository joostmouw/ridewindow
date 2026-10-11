---
phase: quick-261011-kb9
plan: 01
status: complete
subsystem: layout / tablet
tags: [tablet, adaptive, keyboard, hover, backlog-93]
requirements: [QUICK-261011-kb9, BACKLOG-93]
key-files:
  created:
    - test/features/home_test_harness.dart
    - test/features/home_hover_test.dart
    - test/features/home_three_column_test.dart
  modified:
    - lib/app/window_size.dart
    - lib/app/scaffold_with_nav.dart
    - lib/theme/app_colors.dart
    - lib/features/home/home_screen.dart
    - lib/features/agenda/week_agenda_screen.dart
    - lib/features/detail/ride_detail_screen.dart
    - lib/features/planned/planned_rides_screen.dart
    - test/app/adaptive_layout_test.dart
    - test/features/home_two_pane_test.dart
decisions:
  - "Rail verticaal gecentreerd (groupAlignment 0.0) voor duimbereik"
  - "Ritdetail in het Home-paneel is RideDetailScreen(embedded: true); na Inplannen blijft de rit staan (geen Gmail-auto-advance)"
  - "Derde kolom met RidesTab vanaf 1440 dp; de geplande-sectie op Home verdwijnt dan"
  - "WindowSizeClass.large vanaf 1200 met isAtLeast; nergens nog een gelijkheidstest op expanded"
completed: 2026-10-11
---

# Quick 261011-kb9: tablet ronde 2 (backlog #93), samenvatting

Vanaf 840 dp opent het volledige ritdetail in het rechterpaneel van Home, zonder routewissel en zonder terugknop. Je kunt de lijst met pijltjes, Enter en Esc bedienen. Vanaf 1440 dp staat er een derde kolom met je ritten. De rail staat verticaal gecentreerd, en dagchips en agendavakjes geven bij muis of trackpad een klikcursor en een hover-laag. De telefoon is ongewijzigd.

## Commits

| Taak | Commit | Wat |
|---|---|---|
| 1 | `a0a6d2a` | Rail gecentreerd, `hoverOverlay(cs)`, dagchip als InkWell met klikcursor, agendavakje met `_HoverCell`, begroeting met klikcursor alleen als die tikbaar is |
| 2 | `2979a5b` | `WindowSizeClass.large` en `isAtLeast` (taak 3A naar voren gehaald), `RideDetailScreen` met `embedded` en `onPlanned`, ritdetail in het paneel, rit blijft staan na Inplannen, toetsenbord, `_displayedSlots` |
| 3 | `c477b2e` | `PaneColumn` en `LabelWithBadge` openbaar, derde kolom met `RidesTab` vanaf 1440, geplande-sectie verborgen op die breedte |

## Controle

- `flutter test`: **1133 geslaagd, 0 mislukt.** Dat is 1120 plus 13 nieuwe: 3 in adaptive_layout, 2 hover, 3 extra in two_pane en 5 in three_column.
- `flutter analyze`: **0 errors, 0 warnings, 214 infos.** Dat is gelijk aan de nulmeting.
- `grep -rn '[=!]= WindowSizeClass.expanded' lib`: geen treffers.
- Er is niet gepusht, er is geen build gemaakt en de versie is niet gewijzigd. Aan de ARB-bestanden is niets veranderd.

## Afwijkingen van het plan

1. **[Rule 3] Gedeelde testopzet `test/features/home_test_harness.dart`.** Het plan vroeg om de `_pumpHome`-opzet te kopiëren naar drie bestanden. In plaats daarvan staat hij nu één keer in een helper, die two_pane, hover en three_column gebruiken. Daarin staan ook de overrides die het ritdetail en RidesTab nodig hebben: location, currentUserId (null) en de attention-tellers. `rideEntriesProvider` wordt bewust niet overschreven, zodat de geplande-sectie uit `plannedRidesProvider` volgt. `pumpHome` geeft de router terug, zodat een test kan controleren dat er niet gepusht of gepopt is.
2. **[Rule 1] Expliciet `mouseCursor: SystemMouseCursors.click` op de dagchip-InkWell.** In deze Flutter-versie kiest InkWell standaard `adaptiveClickable`, en dat is buiten het web de pijl. Zonder die regel was er geen klikcursor geweest.
3. **Toetsen in de lijst via `Focus(onKeyEvent:)` in plaats van `CallbackShortcuts`.** Enter en Esc tellen alleen als de lijst zelf de focus heeft. Zo bedient Enter op een met Tab gekozen dagchip of filter gewoon die knop. In het paneel is het wel `CallbackShortcuts({Escape})`, zoals het plan voorschrijft.
4. **De toetsen lezen geen providers buiten build.** `_withDetailPane` legt tijdens build de getoonde volgorde (`_keyboardOrder`) en het venster dat rechts staat (`_paneShownStart`) vast. `_displayedSlots` is de enige bron voor de sortering en de aftopping.
5. **Een ingeplande rit die rechts blijft staan krijgt een terugval.** Als het venster na de tijdschuif niet meer in `state.slots` staat, wordt de rit gescoord met `rideWindowScorerProvider.score(start, end)`, op dezelfde manier als `_openPlannedRideDetail`. Na inplannen met een verschoven begintijd blijft dan ook de rit zoals hij is ingepland rechts staan.
6. **Taak 3A is in de commit van taak 2 opgenomen.** Het plan stond dat toe. Ook de `isAtLeast`-regel in planned_rides_screen.dart zit daarom in `2979a5b`.

## Restpunten

- **Scrollen naar een kaart die buiten beeld valt.** Met de pijltjes scrolt alleen de eerste kaart terug in beeld (`_firstCardKey`). Kies je met het toetsenbord een kaart die buiten beeld ligt, dan wisselt het paneel wel, maar de lijst scrolt niet mee.
- **GestureDetectors die nog geen hover hebben:** weather_indicator_bar, daylight_bar, feels_like_bar, availability, welcome, onboarding en screen_hint_overlay. Dat zijn sleep- of info-doelen, of schermen buiten de lijst. Ze blijven kandidaten voor later.
- **Geen widgettest voor de hover-laag op het agendavakje.** De dagchip is wel getest, in licht en donker. Het vakje gebruikt dezelfde `hoverOverlay(cs)`.
- **Visuele controle in Chrome is niet gedaan.** `flutter run -d chrome` op ~1300 en ~1550 breed, in licht en donker, staat nog open.
- **Geneste Scaffold.** Een SnackBar uit het paneel (bijvoorbeeld "Rit ingepland") verschijnt via de gedeelde ScaffoldMessenger. Waar hij precies verschijnt op een tablet is niet visueel gecontroleerd.

## Threat flags

Geen. Er zijn geen nieuwe netwerk-, opslag- of auth-paden. T-kb9-01 en T-kb9-03 zijn met tests gedekt (Inplannen in het paneel, en pijltjes bij nul vensters en aan de randen).

## Self-Check: PASSED

- De bestanden bestaan: home_test_harness.dart, home_hover_test.dart, home_three_column_test.dart.
- De commits bestaan: a0a6d2a, 2979a5b, c477b2e.
