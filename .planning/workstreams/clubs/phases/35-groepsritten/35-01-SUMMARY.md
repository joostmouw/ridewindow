---
phase: 35-groepsritten
plan: 01
subsystem: peloton-datalaag
tags: [clubs, groepsritten, riverpod, supabase, rls]
requires:
  - 34-03 (PelotonGroup, myGroupsProvider, FakeGroupGateway)
  - 0012_groups.sql (group_rides.group_id, is_ride_member, insert_self_group)
provides:
  - GroupRide.groupId / isGroupRide
  - RideEntry.pelotonGroup / groupName / isGroupRide / declinedCount, sleutel per rit-id
  - buildRideEntries(groups:), ontdubbelen per rit-id
  - PelotonGateway.createGroupRide(groupId:), respondToGroupRide (upsert)
  - respondToSharedRide (lib/features/peloton/ride_response.dart)
  - unansweredRideCountProvider
  - FakeGroupGateway met groepsritten (rides, groupRide-helper, is_ride_member-filter)
affects:
  - 35-02 t/m 35-05 (alle schermen lezen hun groepsritten uit rideEntriesProvider)
tech-stack:
  added: []
  patterns:
    - "Antwoorden via top-level helper die update of upsert kiest, zodat bestaande fakes geldig blijven"
    - "Tellingen op een groepsrit over de huidige leden, niet over de rijen"
key-files:
  created:
    - lib/features/peloton/ride_response.dart
    - test/providers/group_rides_providers_test.dart
  modified:
    - lib/domain/models/peloton.dart
    - lib/domain/models/ride_entry.dart
    - lib/services/peloton_gateway.dart
    - lib/providers/peloton_providers.dart
    - lib/providers/peloton_providers.g.dart
    - lib/providers/ride_entries_provider.dart
    - lib/providers/ride_entries_provider.g.dart
    - test/helpers/fake_group_gateway.dart
    - test/domain/models/ride_entry_test.dart
decisions:
  - "35-01: gedeelde ritten ontdubbelen per rit-id; RideEntry.key = ride_<id>, solo blijft op tijdvak"
  - "35-01: persoonlijke rit hangt aan jouw organiser-regel op dat tijdvak, anders aan de hoogste voorrang"
  - "35-01: op een groepsrit telt de organisator als 'gaat mee'; ex-leden tellen nergens"
  - "35-01: respondToGroupRide = upsert zonder select; respondToRide blijft update"
metrics:
  duration: 25min
  completed: 2026-09-24
  tasks: 2
  files: 11
---

# Phase 35 Plan 01: Datalaag groepsritten Summary

Groepsritten lopen nu door de hele datalaag. `GroupRide` leest `group_id`. Een groepsrit waarop je nog geen rij hebt staat als "wacht op jou" in `rideEntriesProvider`. Antwoorden gaat via een upsert zonder select. `unansweredRideCountProvider` geeft het getal voor de teller (CLUB-25 optie A).

## Wat er gebouwd is

**Task 1: model (commits 89b960f RED, cbf2a55 GREEN)**
- `GroupRide.groupId` en `isGroupRide`, gelezen uit `row['group_id']`. De doccomment noemt de toegangsregel uit 0012.
- `buildRideEntries` ontdubbelt gedeelde ritten per rit-id, en de lagere rolindex wint. Twee verschillende gedeelde ritten op hetzelfde tijdvak blijven allebei staan. `RideEntry.key` is `ride_<id>`, dus `ValueKey(entry.key)` blijft uniek.
- Een persoonlijke rit hangt aan de organiser-regel op dat tijdvak. Is die er niet, dan aan de regel met de laagste rolindex. De regel "afgezegd + eigen plan wordt solo" geldt nog steeds.
- `RideEntry.pelotonGroup`, `groupName`, `isGroupRide` en `declinedCount`. Op een groepsrit waarvan de groep bekend is, wordt geteld over de huidige leden. De organisator telt dan mee als "gaat mee". Een lid zonder rij, of met een rij `invited`, telt als "nog niet". Rijen van ex-leden tellen niet mee. In alle andere gevallen blijven de tellingen zoals ze waren.

**Task 2: gateway, providers, antwoordhulp, fake (commit 65805ad)**
- `createGroupRide(groupId:)`: `group_id` gaat alleen mee als hij gezet is.
- `respondToGroupRide`: een upsert op `ride_id,user_id` met je eigen `display_name`. Er zit bewust geen select achter, vanwege de insert-returning-valkuil uit 0003.
- `respondToSharedRide(gateway, ride, accepted:, myName:)` kiest zelf tussen upsert en update.
- `pendingRideInvites` neemt nu ook groepsritten van anderen mee waarop je nog geen rij hebt.
- `rideEntries` leest `myGroupsProvider` met `.value ?? const []`. Als de groepenlijst faalt, blijven de ritten staan; alleen de groepsnaam ontbreekt dan.
- `unansweredRideCountProvider` telt alleen pending-regels die nog niet voorbij zijn.
- `FakeGroupGateway` heeft nu:
  - een tabel `rides` en de helper `groupRide(...)`, standaard morgen 09:00-13:00;
  - `listGroupRides`, dat filtert zoals is_ride_member, dus na `leaveGroup` is de rit weg;
  - `createGroupRide`, dat een vreemde groep weigert;
  - `respondToGroupRide`, dat een niet-lid weigert;
  - `respondToRide`, dat niets doet als er geen eigen rij is, net als de echte update;
  - `proposeOptions` en `voteOnOption`.

## Verificatie

- Volledige `flutter test`: **887 geslaagd** (basis 864 + 23 nieuw: 10 in ride_entry_test, 13 in group_rides_providers_test).
- `flutter analyze`: 0 errors, 0 warnings. De 199 infos stonden er al; in de nieuwe en gewijzigde code van dit plan komt er geen bij.
- In de commits zitten alleen `peloton_providers.g.dart` en `ride_entries_provider.g.dart`. De door build_runner herschreven `router.g.dart` en `analytics_provider.g.dart` zijn teruggezet.
- Geen wijzigingen in `supabase/`, `lib/platform/background_task.dart` of `lib/platform/notification_service.dart`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Voorrang organiser boven pending bij het ophangen van een persoonlijke rit**
- **Found during:** Task 1
- **Issue:** "Laagste rolindex" alleen zou een pending-regel (index 0) laten winnen van jouw organiser-regel (index 1). Het plan wil dat de organiser-regel eerst komt.
- **Fix:** eerst expliciet `firstWhere(role == organiser)`, daarna pas de laagste index.
- **Commit:** cbf2a55

**2. [Rule 3 - Blocking] Riverpod 3 retry in de providertest**
- **Found during:** Task 2
- **Issue:** Als `listGroups` faalt, blijft de `.future` van `myGroupsProvider` openstaan door de automatische retry, en de test liep in een timeout.
- **Fix:** de testcontainer draait met `retry: (_, __) => null`. De productiecode is niet aangepast.
- **Commit:** 65805ad

**3. Formatter teruggezet in peloton_gateway.dart**
- `dart format` herschreef `proposeOptions` en `chooseOption`, die niet door dit plan geraakt worden. Die wijziging is teruggedraaid (les uit 34-03). Het commentaar in `respondToGroupRide` noemt `.select()` niet letterlijk, zodat de grep uit de acceptatiecriteria niet vals afgaat.

## TDD Gate Compliance

Task 1 heeft een aparte RED-commit (89b960f) en GREEN-commit (cbf2a55). Bij Task 2 zitten de tests en de implementatie in één feat-commit (65805ad), zonder aparte RED-commit. Voor die taak ontbreekt de RED-gate dus in de git-log.

## Requirements

CLUB-13, CLUB-14 en CLUB-25 zijn in de datalaag geregeld, maar nog niet afgevinkt. Antwoorden vanuit de UI (03/04), de teller in beeld (05) en de toestelcheck (06) volgen nog.

## Known Stubs

Geen.

## Self-Check: PASSED
