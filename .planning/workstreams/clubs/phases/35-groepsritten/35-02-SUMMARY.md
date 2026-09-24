---
phase: 35-groepsritten
plan: 02
subsystem: peloton-ui
tags: [clubs, groepsritten, uitnodigen, l10n]
requires:
  - 35-01 (createGroupRide(groupId:), GroupRide.groupId, FakeGroupGateway.rides)
  - 34-03 (myGroupsProvider, GroupCrest, groupErrorTextOf)
provides:
  - "_InviteTargetPicker: 'Met wie rijd je?', groep of losse maatjes, nooit allebei"
  - "groepspad in showInviteBuddiesSheet: createGroupRide(groupId:), geen participant-rijen, geen tweede groepsrit op hetzelfde tijdvak"
  - "maatjespad hergebruikt alleen een eigen gewone rit"
  - "detailknop 'Nodig je groep of maatjes uit' bij minstens één groep"
  - "FakeGroupGateway.inviteToRide"
affects:
  - 35-03 t/m 35-05 (groepsritten die hier ontstaan, verschijnen daar)
tech-stack:
  added: []
  patterns:
    - "RadioGroup<String> als voorouder met toggleable RadioListTile (Flutter 3.32+ API)"
    - "sealed _InviteTarget als uitkomst van een bottom sheet"
key-files:
  created:
    - test/features/invite_group_ride_test.dart
  modified:
    - lib/features/peloton/invite_buddies_sheet.dart
    - lib/features/detail/ride_detail_screen.dart
    - lib/l10n/app_nl.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_nl.dart
    - lib/l10n/app_localizations_en.dart
    - test/helpers/fake_group_gateway.dart
decisions:
  - "35-02: dubbelcheck groepsrit vóór het vensterscherm, niet erna"
  - "35-02: maatjespad hergebruikt alleen eigen rit zonder group_id"
  - "35-02: groepenfout bij openen = oud scherm, geen melding"
metrics:
  duration: 15min
  completed: 2026-09-24
  tasks: 2
  files: 9
---

# Phase 35 Plan 02: Uitnodigen voor de hele groep Summary

Een lid zet nu vanuit het bestaande uitnodigscherm een rit uit voor de hele groep. Zit je in een groep, dan heet het scherm "Met wie rijd je?". Bovenaan staat "Een groep" met het kenteken, de naam en het aantal leden, daaronder "Of losse maatjes". Een groep kiezen zet de maatjes uit, en andersom. Wie in geen groep zit, ziet het scherm zoals het was.

## Wat er gebouwd is

**Task 1: doelkeuze en groepsrit (commits 2c5010d RED, 0db15dd GREEN)**
- `_FriendPicker` is vervangen door `_InviteTargetPicker`. Die geeft een sealed `_InviteTarget` terug: `_GroupTarget` of `_FriendsTarget`. Zonder groepen is hij gelijk aan de oude kiezer: dezelfde titel, dezelfde vinkjes en de knop "Uitnodigen".
- Met groepen staat er een `RadioGroup<String>` met `RadioListTile(toggleable: true)`. Nog een keer tikken maakt de keuze ongedaan. Is er een groep gekozen, dan kun je geen maatjes meer aanvinken (`onChanged: null`). Is er een maatje aangevinkt, dan zijn de groepen uitgeschakeld (`enabled: false`). Bij de gekozen groep staat "2 leden · ieder lid ziet de rit". De knop heet "Verder: kies vensters".
- **Groepspad.** Eerst controleert de app of er al een rit van die groep op exact dit tijdvak staat, ook als een ander lid hem uitzette. Zo ja, dan komt de melding "Er staat al een groepsrit van ... op dit tijdstip" en opent het vensterscherm niet. Zo nee, dan volgen het vensterscherm, `createGroupRide(groupId: group.id)` en `proposeOptions` als je meer dan één venster kiest. Er gaat geen `inviteToRide` per lid uit. De analytics krijgen alleen `{'kind': 'group_ride', 'windows': n}`, zonder naam of id. Een fout van het type `GroupException` krijgt de zin van `groupErrorTextOf`, elke andere fout `pelotonInviteFailed`.
- **Maatjespad.** Dit werkt zoals voorheen, met één verschil: de app hergebruikt alleen een eigen rit zonder `group_id` (`r.isOwnedBy(me) && r.groupId == null`). Tot nu werd elke rit op dat tijdvak hergebruikt, dus ook een groepsrit of de rit van iemand anders.
- Zijn er geen maatjes maar wel groepen, dan opent de kiezer. Zijn er geen maatjes en geen groepen, dan komt de oude melding. Als het ophalen van de groepen faalt, geldt dat als een lege lijst: je ziet het oude scherm en kunt nog steeds maatjes uitnodigen.
- Er zijn 7 ARB-sleutels bijgekomen, in het NL en EN.

**Task 2: detailknop (commit faab89a)**
- In `_buildSecondaryActions` heet de knop "Nodig je groep of maatjes uit" als `myGroupsProvider` niet leeg is. Anders blijft het "Nodig een maatje uit". Het icoon en het gedrag zijn niet veranderd.
- `groupRideInviteButton` staat in het NL en EN; in het EN met een beschrijving.

## Verificatie

- `invite_group_ride_test.dart`: 14 tests, allemaal geslaagd. Het zijn 12 tests voor het uitnodigscherm, waaronder 360 dp met textScaler 1.3 en een groepsnaam van 40 tekens, plus 2 voor de detailknop.
- `peloton_options_test.dart` is niet aangepast en slaagt nog steeds.
- Volledige `flutter test`: **901 geslaagd** (887 + 14).
- `flutter analyze`: 0 errors, 0 warnings en 198 infos (was 199). In de bestanden van dit plan komt er geen info bij. De twee `trackEvent`-aanroepen hebben nu een trailing comma, en daardoor is er één oude info verdwenen. In `ride_detail_screen.dart` staan er vóór en na 19.
- `git diff --stat lib/platform/` is leeg. Er is geen build_runner nodig geweest.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `FakeGroupGateway.inviteToRide` ontbrak**
- **Found during:** Task 1 (tests voor het maatjespad)
- **Issue:** De fake viel voor `inviteToRide` terug op `noSuchMethod`. Het maatjespad was daardoor niet te testen.
- **Fix:** `inviteToRide` schrijft nu naar het logboek (`inviteToRide:<rit>:<maatje>`) en voegt een rij `invited` toe. Op de rit van iemand anders weigert hij, net als de insert-policy.
- **Files modified:** test/helpers/fake_group_gateway.dart
- **Commit:** 2c5010d

**2. Een fout bij het ophalen van groepsritten in het groepspad**
- De dubbelcheck heeft een eigen try/catch die `pelotonInviteFailed` toont. Zonder die try/catch zou een netwerkfout de knop stil niets laten doen, en dat is de sweep "stille takken" van 2026-09-21.

## TDD Gate Compliance

Task 1 heeft een aparte RED-commit (2c5010d: 2 geslaagd, 10 gefaald) en een GREEN-commit (0db15dd). Task 2 had geen tdd-vlag. De tests en het label zitten daar in één commit.

## Requirements

CLUB-12 werkt nu in de code: het uitnodigscherm, de groepsrit met één of meer vensters en de detailknop. Het vinkje blijft nog open tot de toestelcheck met een echte groepsrit in 35-06, net als bij CLUB-13, -14 en -25 na 35-01.

## Known Stubs

Geen.

## Threat Flags

Geen nieuw oppervlak. T-35-04: de kiezer toont alleen `myGroups`, en de database eist `is_group_member`. T-35-05: in de props zitten alleen `kind` en `windows`; er is geen analytics-fake, dus dat is met grep gecontroleerd. T-35-06: groep en maatjes sluiten elkaar uit, en het maatjespad hergebruikt nooit een groepsrit.

## Self-Check: PASSED
