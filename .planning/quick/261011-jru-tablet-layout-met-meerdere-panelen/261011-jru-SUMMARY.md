---
phase: quick-261011-jru
plan: 01
status: complete
subsystem: ui/adaptive-layout
tags: [tablet, material3, navigation-rail, two-pane]
requires: []
provides:
  - "lib/app/window_size.dart: WindowSizeClass (600/840), windowSizeClassOf, ReadableWidth (640)"
  - "NavigationRail vanaf medium in de shell"
  - "Home lijst-plus-detail vanaf expanded"
  - "Ritten en Peloton naast elkaar vanaf expanded"
affects: [shell, home, rides, welcome, onboarding, profile]
key-files:
  created:
    - lib/app/window_size.dart
    - test/app/adaptive_layout_test.dart
    - test/features/home_two_pane_test.dart
    - test/features/rides_two_pane_test.dart
  modified:
    - lib/app/scaffold_with_nav.dart
    - lib/features/welcome/welcome_screen.dart
    - lib/features/onboarding/onboarding_screen.dart
    - lib/features/profile/profile_screen.dart
    - lib/features/home/home_screen.dart
    - lib/features/planned/planned_rides_screen.dart
    - test/features/profile_screen_test.dart
decisions:
  - "De breedteklasse volgt uit de vensterbreedte (MediaQuery.sizeOf), niet uit de breedte naast de rail: één regel voor de hele app"
  - "Home: de RefreshIndicator-boom blijft op zijn plek; _withDetailPane(slotsState, list) zet hem vanaf expanded in een Row, zodat de telefoontak letterlijk dezelfde boom is en de diff klein blijft"
  - "Filterlogica van RIDE TIMES naar _listedSlots, gedeeld door lijst en detailpaneel; geen tweede kopie van filters of beste-venster-regel"
  - "_LabelWithBadge gedeeld door tab en kolomkop op Ritten (CLUB-25)"
metrics:
  completed: 2026-10-11
  tasks: 3
  commits: 3
---

# Quick 261011-jru: tabletweergave met meerdere panelen

Op tabletbreedte toont Ridewindow nu een navigatierail vanaf 600 dp, en vanaf 840 dp staan op Home de lijst en het gekozen venster naast elkaar, en op Ritten de tabbladen Ritten en Peloton. Welcome, Onboarding en Profiel zijn vanaf 600 dp hooguit 640 breed. Op een telefoon (< 600) is alles hetzelfde gebleven.

## Commits

| Task | Commit | Wat |
|------|--------|-----|
| 1 | a1bf690 | window_size.dart, rail in de shell, ReadableWidth op Welcome/Onboarding/Profiel, tests |
| 2 | 5a0c8b1 | Home lijst-plus-detail vanaf expanded, test |
| 3 | 719df86 | Ritten en Peloton naast elkaar vanaf expanded, test; trailing comma in profieltest-helper |

## Verificatie

- `flutter test`: **1120 geslaagd, 0 mislukt** (1104 bestaand + 16 nieuw: 7 adaptive_layout, 2 profiel, 4 home_two_pane, 3 rides_two_pane)
- `flutter analyze`: **0 errors, 0 warnings, 214 infos** (gelijk aan de nulmeting van 214)
- `windowSizeClassOf` wordt gebruikt in scaffold_with_nav, home_screen en planned_rides_screen; breakpoints 600/840 staan alleen in `lib/app/window_size.dart`
- Op compact: `ReadableWidth` geeft het kind ongewijzigd terug, de shell bouwt dezelfde `Scaffold` met `NavigationBar`, `_withDetailPane` geeft de lijst ongewijzigd terug, Ritten neemt de bestaande TabBar-tak

## Afwijkingen van het plan

1. **[Rule 3 - Blocking] De Home-test filtert alleen meldingen over RenderFlex-overloop.** Op 400 breed loopt de weergaverij met de vierkante testletter (Ahem) over, net als bij de bestaande noot in `home_screen_test.dart` op 360 dp. Met een echte letter gebeurt dat niet. Een helper laat alleen die meldingen weg, elke andere fout laat de test nog steeds falen. Bij een tik op de telefoon is eerst `ensureVisible` nodig, omdat de kaart onder de vouw staat. Verder `pump` met een vaste duur in plaats van `pumpAndSettle`, want Home heeft een animatie die blijft lopen.
2. **Home-opbouw:** het plan noemde de RefreshIndicator naar een lokale variabele halen. Daarvoor moest de hele build-boom opnieuw ingesprongen worden. Ik heb in plaats daarvan een `_withDetailPane(slotsState, RefreshIndicator(...))`-omhulling gebruikt. Het gedrag is hetzelfde en de diff veel kleiner.
3. **Profieltest:** de helper `pumpProfileScreen` kreeg een optionele parameter `size`. Er zijn twee tests bij gekomen, op 1280x800 (≤ 640 en gecentreerd) en op 400 (volle breedte). `ReadableWidth` wordt daarnaast ook los getest in `adaptive_layout_test.dart`.

## Niet gedaan (bewust)

- Er is niets visueel gecontroleerd op een echte tablet of in Chrome; alleen widgettests. Een optionele controle staat in het plan (`flutter run -d chrome` op ~700 en ~1300 px).
- Geen versieverhoging, geen release-build, niet gepusht.

## Known Stubs

Geen. Het lege detailpaneel (`SizedBox.shrink`) bij nul vensters is bedoeld (T-jru-02) en getest.

## Self-Check: PASSED

- lib/app/window_size.dart, test/app/adaptive_layout_test.dart, test/features/home_two_pane_test.dart, test/features/rides_two_pane_test.dart: FOUND
- commits a1bf690, 5a0c8b1, 719df86: FOUND
