---
phase: 35-groepsritten
plan: 03
subsystem: ritkaarten
tags: [clubs, groepsritten, rolregel, 360dp, peloton]
requires:
  - 35-01 (RideEntry.groupName, respondToSharedRide, FakeGroupGateway met ritten)
provides:
  - RideRoleLine met groepsnaam vooraan (hooguit 45 procent, ellips, één semantics-label)
  - antwoorden op een groepsrit vanaf de ritkaart via respondToSharedRide
  - antwoordknoppen op RideCard in een Wrap (geen overflow op 360 dp met grote tekst)
affects:
  - Home (PLANNED) en de Ritten-tab: beide gebruiken RideRoleLine
  - 35-04 (detail) kan dezelfde antwoordroute gebruiken
tech-stack:
  added: []
  patterns:
    - "Niet-flexibele ConstrainedBox + Expanded: de korte naam neemt zijn eigen breedte, de rol de rest"
    - "Overflowtest met FlutterError.onError en de RenderFlex uit informationCollector, zodat een testletter-artefact elders niet maskeert"
key-files:
  created:
    - test/features/group_ride_cards_test.dart
  modified:
    - lib/features/shared/ride_role_style.dart
    - lib/features/planned/planned_rides_screen.dart
    - test/features/home_screen_test.dart
decisions:
  - "35-03: groepsnaam hooguit 45% van de rolregel, zonder Flexible"
  - "35-03: antwoordknoppen op de ritkaart in een Wrap, rechts uitgelijnd"
  - "35-03: scheidingsteken is een punt met vaste lucht, geen spaties"
metrics:
  duration: 35min
  completed: 2026-09-24
  tasks: 2
  files: 4
---

# Phase 35 Plan 03: Groepsnaam op de ritkaart en antwoorden Summary

Op Home en in de Ritten-tab staat de groepsnaam nu vooraan in de rolregel die er al was, bijvoorbeeld "On the Roll · Anna vraagt of je meegaat". Er komt geen extra regel bij en de kaart wordt niet hoger. Tik je op een groepsrit "Ik ga mee" of "Kan niet", dan wordt je eigen rij aangemaakt via `respondToSharedRide`. Voorheen deed die tik stil niets.

## Wat er gebouwd is

**Task 1: groepsnaam in de rolregel (RED 76d7f95, GREEN 03246ab)**
- `RideRoleLine`: zonder groepsnaam blijft de widgetboom zoals hij was. Met groepsnaam staan er binnen een `LayoutBuilder` achter elkaar:
  - het rol-icoon, als de rol er een heeft;
  - de naam in w700 en de rolkleur, begrensd op `maxWidth * 0.45` en bij te veel tekst afgekapt met een ellips;
  - een punt met 4 dp lucht aan weerszijden;
  - de rolzin in een `Expanded`, zoals eerst.
- De hele regel heeft één semantics-label: "On the Roll, Anna vraagt of je meegaat". Het doccomment legt uit waarom de naam in de regel staat en niet als chip, en waarom de grens op 45 procent ligt.
- Bij de organisator staat de megafoon nog steeds vooraan, gevolgd door "On the Roll · Jij organiseert".

**Task 2: antwoorden vanaf de kaart (RED 9dc2584, GREEN cd800db)**
- `_RidesTabState.respond` roept nu `respondToSharedRide(gateway, group, accepted:, myName:)` aan. De gateway en je profielnaam worden vóór de await opgehaald. `_run`/`_busy`, de foutmelding, de invalidate en `withdraw` (afzeggen plus ongedaan maken) zijn niet veranderd. Groepsritten volgen dus hetzelfde pad als gewone ritten.
- `.respondToRide(` komt niet meer voor in planned_rides_screen.dart. Een gewone rit loopt nog wel via `respondToRide`, maar dan binnen `respondToSharedRide`.

## Verificatie

- In `group_ride_cards_test.dart` staan 26 tests:
  - RideRoleLine op 180 en 328 dp, zowel dense als niet-dense, met tekstschaal 1.0, 1.3 en 2.0. Getoetst wordt: geen overflow, de naam is hooguit 45 procent breed, de rol begint direct na naam en punt en loopt door tot de rechterrand, en de regel is even hoog als dezelfde regel zonder groepsnaam.
  - RideCard op 360 dp, met tekstschaal 1.0 (licht en donker), 1.3 en 2.0: geen exception, en de kaart met de groepsrit is precies even hoog als die met een gewone gedeelde rit.
  - Antwoorden: accepteren maakt een rij met naam aan, weigeren zet de rit onder "Afgezegd", afzeggen met ongedaan maken werkt, een gewone uitnodiging gaat nog via respondToRide, twee snelle tikken leveren één aanroep op (met een vertraagde gateway), en wie de groep verlaat ziet de rit niet meer.
- `home_screen_test.dart` heeft een test erbij: Home op 360x800 met een groepsrit onder PLANNED. De rolregel toont de groepsnaam en de ritkaart geeft geen overflow.
- Volledige `flutter test`: **928 geslaagd** (dat waren er 901, 27 zijn nieuw).
- `flutter analyze`: 0 errors, 0 warnings en 198 infos, net als na 35-02. De nieuwe testbestanden en `ride_role_style.dart` geven geen infos.
- `dart format` herschreef drie stukken in planned_rides_screen.dart die dit plan niet raakt. Die zijn teruggezet. `git diff --stat lib/platform/` is leeg.
- peloton_withdraw_test, peloton_options_test en rides_roles_test zijn niet aangepast en slagen.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Antwoordknoppen liepen van de kaart op 360 dp**
- **Found during:** Task 1 (RideCard-hoogtetest)
- **Issue:** "Kan niet" en "Ik ga mee" stonden in een `Row`. Met tekstschaal 1.3 of 2.0 liep die rij over, met 77 en 238 px. Dat gebeurde ook bij gewone uitnodigingen.
- **Fix:** de knoppen staan nu in een `Wrap` met `alignment: end` en `spacing: 8`, binnen een `SizedBox(width: double.infinity)`. Past het, dan staan ze zoals eerst rechts naast elkaar. Past het niet, dan komt de tweede knop eronder, ook rechts uitgelijnd. Een test controleert dat de knop rechts staat.
- **Files modified:** lib/features/planned/planned_rides_screen.dart
- **Commit:** 03246ab

**2. Geen `Flexible` rond de groepsnaam (plan noemde `Flexible(fit: loose)`)**
- In een Row verdeelt `Flexible` de vrije ruimte naar rato van de flex-waarden. Een korte naam zou dan de helft van de regel reserveren, en de rolzin zou onnodig worden afgekapt. Een niet-flexibele `ConstrainedBox` neemt precies de eigen breedte, tot de grens van 45 procent, en de `Expanded` rolzin krijgt de rest. Dit is de bedoeling van het plan.

**3. Scheidingsteken: punt met vaste lucht in plaats van `' · '`**
- Spaties worden breder bij een hogere tekstschaal. Bij 2.0 op het Home-kaartje van 180 dp bleef er daardoor bijna niets over voor de rol. Met een punt en `Padding(horizontal: 4)` ziet het er hetzelfde uit en blijft de rolzin zichtbaar.

**4. De Home-test laat één fout door die buiten dit plan valt**
- De testletter geeft elke letter een volle em breedte. Daardoor loopt de weergaverij "Vensters / Blok / Beste eerst / Op tijd" op 360 dp over. Met echte letters gebeurt dat niet, en die rij heeft niets met ritkaarten te maken. De test vangt fouten via `FlutterError.onError` en laat alleen die ene overflow door, herkend aan zijn RenderFlex. Elke andere fout laat de test falen.

## TDD Gate Compliance

Beide taken hebben een aparte RED-commit (test) en GREEN-commit (feat): 76d7f95 → 03246ab en 9dc2584 → cd800db. Bij Task 2 slaagden twee tests al in RED, omdat dat gedrag al bestond: een gewone uitnodiging via respondToRide, en de rit verdwijnt na het verlaten van de groep. Die tests zijn regressievangers. De vier tests voor het nieuwe gedrag faalden in RED zoals verwacht.

## Requirements

CLUB-13, CLUB-14 en CLUB-16 zijn op de kaarten geregeld, maar nog niet afgevinkt. De chip op het detail (04), de teller (05) en de toestelcheck (06) volgen nog, net als bij 35-01 en 35-02.

## Known Stubs

Geen.

## Self-Check: PASSED
