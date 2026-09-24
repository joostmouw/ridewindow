---
phase: 35-groepsritten
plan: 05
subsystem: navigatie en rittenlijst
tags: [clubs, groepsritten, badge, filter, 360dp]
requires:
  - 35-01 (unansweredRideCountProvider, RideEntry.group?.groupId, myGroupsProvider)
  - 35-04 (groupRideOpenGroup-tekst)
provides:
  - rood bolletje met het aantal op Ritten in de onderbalk (ScaffoldWithNav is nu een ConsumerWidget)
  - hetzelfde getal bij de tab Peloton in Mijn Ritten
  - unansweredBadgeLabel (9+ boven negen), gedeeld door beide plekken
  - _GroupFilterRow: Alles plus een chip per groep boven de rittenlijst
affects:
  - 35-06 (toestelcheck: bolletje en groepschips in licht en donker, 360 dp)
tech-stack:
  added: []
  patterns:
    - "Rijhoogte groeit met de tekstschaal: max(vast, textScaler.scale(20) + marge)"
    - "Lang indrukken op een chip: GestureDetector plus Semantics.onLongPressHint, geen Tooltip"
key-files:
  created:
    - test/app/nav_unanswered_badge_test.dart
    - test/features/rides_group_filter_test.dart
  modified:
    - lib/app/scaffold_with_nav.dart
    - lib/features/planned/planned_rides_screen.dart
    - lib/l10n/app_nl.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_nl.dart
    - lib/l10n/app_localizations_en.dart
    - test/features/group_ride_cards_test.dart
decisions:
  - "35-05: bolletje en tab delen provider en label (9+)"
  - "35-05: groepschips in scrollende Row, geen ListView"
  - "35-05: lang indrukken zonder Tooltip; hint via Semantics"
metrics:
  duration: 35min
  completed: 2026-09-24
  tasks: 2
  files: 10
---

# Phase 35 Plan 05: Teller en groepschips Summary

Wacht er een rit op je antwoord, dan staat er nu een rood bolletje met het aantal op "Ritten" in de onderbalk. In Mijn Ritten staat hetzelfde getal naast de tab "Peloton". Bij 0 staat er op beide plekken niets. Boven de 9 staat er "9+".

Wie in minstens één groep zit, ziet boven de rittenlijst een rij chips: "Alles" en dan per groep het kenteken met de naam. Een groepschip filtert de lijst op de ritten van die groep. Lang indrukken opent het groepsscherm. Zonder groepen verandert er niets aan de lijst.

## Wat er gebouwd is

**Task 1: teller op de onderbalk en bij de tab Peloton (RED cc63b12, GREEN c7e5ce4)**
- `ScaffoldWithNav` is nu een `ConsumerWidget` en leest `ref.watch(unansweredRideCountProvider)`. Het getal komt uit `rideEntriesProvider`, dus er komt geen extra netwerkaanroep bij (T-35-12). scaffold_with_nav.dart importeert geen gateway.
- `_UnansweredBadge` zet een M3-`Badge` om `icon` en `selectedIcon` van Ritten. Er zijn geen eigen kleuren, dus het bolletje krijgt `error`/`onError` uit het thema, in licht en donker. Bij 0 is er geen Badge.
- Een schermlezer leest "Ritten" en "2 wachten op je antwoord" (`navRidesUnanswered`, met meervoud, in NL en EN). Het cijfer zelf zit in een `ExcludeSemantics`, zodat het niet dubbel wordt voorgelezen.
- In de tab Peloton staat het label in een `Flexible` met ellips, met daarachter hetzelfde bolletje. Getest op 360 dp met tekstschaal 2.0.
- `unansweredBadgeLabel` staat in scaffold_with_nav.dart en planned_rides_screen.dart gebruikt hem ook. Zo tonen beide plekken altijd hetzelfde.

**Task 2: groepschips boven de rittenlijst (RED 7667f5e, GREEN fea2a28)**
- `_RidesTabState._groupFilter`. Het groepsfilter werkt vóór `actief`, `countByRole` en het rolfilter, dus de rolchips tellen binnen de gekozen groep. Staat de gekozen groep niet meer in `myGroups` (je verliet hem), dan valt het filter terug op Alles.
- De bestaande lege staat (helemaal geen ritten) gaat nog steeds voor. Een groep zonder ritten toont "Nog geen ritten van {groep}" (`groupFilterEmpty`) in bodyMedium/onSurfaceVariant. De chips blijven dan staan.
- `_GroupFilterRow` is een horizontaal scrollende rij `ChoiceChip`s. "Alles" komt eerst, daarna per groep `GroupCrest(size: 24)` met de naam (hooguit 120 breed, één regel, ellips). De volgorde is die van myGroups (op naam). Er zijn geen eigen kleuren: gekozen is `secondaryContainer`, en het thema zet het vinkje uit.
- Lang indrukken doet `context.push('/peloton/group/<id>')`.
- Een falende groepenlijst geeft geen chips en geen fout.

## Verificatie

- `nav_unanswered_badge_test.dart`: 9 tests.
  - Onderbalk: 0 geeft niets, 2 geeft "2" op de Ritten-bestemming, het bolletje blijft staan als Ritten gekozen is, 12 geeft "9+", de schermlezertekst klopt, en er zijn geen eigen kleuren (donker).
  - Tab: 0, 2, en 12 op 360 dp met tekstschaal 2.0.
- `rides_group_filter_test.dart`: 12 tests.
  - Groepen: zonder groepen, groepen met fout, volgorde en Alles gekozen, filteren en terug, rolchips binnen de groep, een verdwenen groep, een lege groep.
  - Lang indrukken opent het groepsscherm.
  - 360 dp met tekstschaal 1.3 en 2.0 en een naam van 40 tekens: geen overflow, de rij scrollt horizontaal, een chip is hooguit 180 breed (190 bij 2.0), en de laatste chip is bereikbaar.
  - Chipkleuren in licht en donker.
- rides_roles_test is ongewijzigd en groen.
- Volledige `flutter test`: **974 geslaagd, 0 gefaald**.
- `flutter analyze`: 0 errors en 0 warnings. Er zijn 198 infos, allemaal van eerder: trailing commas en de `dart:ui`-import in planned_rides_screen.dart op regels die dit plan niet raakt. De nieuwe testbestanden en scaffold_with_nav.dart zijn schoon.
- `git diff --stat lib/platform/ supabase/` is leeg.
- `dart format` is alleen op de eigen regels toegepast. De rest van planned_rides_screen.dart zou herformatteren (dat was al zo) en is niet aangeraakt.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rolfilterrij liep 8 px over bij tekstschaal 2.0**
- **Gevonden tijdens:** Task 2 (overflowtest op 360 dp met 2.0)
- **Probleem:** `_FilterRow` had een vaste hoogte van 46. Het label groeit mee met de tekst en de Column eronder liep 8 px over. Dit bestond al vóór dit plan.
- **Oplossing:** de hoogte is nu `max(46, textScaler.scale(20) + 26)`. Bij gewone tekst blijft dat 46. Aan de inhoud van de rij is niets veranderd.
- **Commit:** fea2a28

**2. [Rule 1 - Bug] Scrollende Row in plaats van een ListView voor de groepschips**
- **Probleem:** een horizontale `ListView` bouwt chips buiten beeld niet. Bij 360 dp en tekstschaal 1.3 bestond de vierde chip daardoor niet, ook niet voor een schermlezer die de rij afloopt.
- **Oplossing:** `SingleChildScrollView(scrollDirection: horizontal)` met een `Row`. Het zijn hooguit elf chips (tien groepen plus Alles). De test controleert nu met `Scrollable.axisDirection` dat de rij horizontaal scrollt.
- **Commit:** fea2a28

**3. [Rule 1 - Bug] Geen Tooltip om de groepschip**
- **Probleem:** een `Tooltip` reageert zelf op lang indrukken. Die zou met de navigatie naar het groepsscherm om hetzelfde gebaar strijden.
- **Oplossing:** `Semantics(onLongPressHint: groupRideOpenGroup)` om de `GestureDetector`. Een schermlezer leest de hint voor en lang indrukken navigeert zonder conflict.
- **Commit:** fea2a28

**4. [Rule 1 - Bug] Label hooguit 120 in plaats van 140**
- **Probleem:** met 140 was de chip bij tekstschaal 1.3 zo'n 198 dp breed, want de chipmarge groeit mee met de tekst. Het plan wil ongeveer 180.
- **Oplossing:** `maxWidth: 120`. De chip is nu 178 breed bij 1.3 en 186 bij 2.0.
- **Commit:** fea2a28

**5. [Rule 3 - Blocking] group_ride_cards_test zocht de groepsnaam in het hele scherm**
- **Probleem:** sinds de chips staat de groepsnaam twee keer in beeld, op de chip en op de kaart. Daardoor faalden drie tests met `findsOneWidget`/`findsNothing`.
- **Oplossing:** de helper `_onCard` zoekt de tekst alleen binnen `RideCard`. Wat de tests controleren is niet veranderd.
- **Commit:** fea2a28

## Known Stubs

Geen.

## Self-Check: PASSED

- FOUND: test/app/nav_unanswered_badge_test.dart
- FOUND: test/features/rides_group_filter_test.dart
- FOUND: cc63b12, c7e5ce4, 7667f5e, fea2a28
