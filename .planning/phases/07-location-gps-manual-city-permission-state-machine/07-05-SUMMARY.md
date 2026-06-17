---
phase: 07-location-gps-manual-city-permission-state-machine
plan: 05
subsystem: widget-tests-location
tags: [tests, widget-test, location, gps, profile-screen, home-screen, riverpod, fake-notifier]
dependency_graph:
  requires: [07-01, 07-02, 07-03, 07-04]
  provides: [widget-test-coverage-loc-01-05]
  affects: [test/features/profile_screen_location_test.dart, test/features/home_screen_location_test.dart]
tech_stack:
  added: []
  patterns:
    - FakeNotifier extends concrete class (not _$abstract) per Phase 3/6 pattern
    - ProviderScope.overrides with overrideWith(() => FakeXxxNotifier(...))
    - await tester.pump() + await tester.pump(Duration(milliseconds: 100)) — no pumpAndSettle
    - Completer<void>().future for permanent AsyncLoading simulation
key_files:
  created:
    - test/features/profile_screen_location_test.dart
    - test/features/home_screen_location_test.dart
  modified: []
decisions:
  - "07-05: FakeWeatherNotifier lokaal gedefinieerd in profile_screen_location_test (extends WeatherNotifier) — ProfileScreen vereist weatherProvider via ProviderScope om te bouwen"
  - "07-05: Test 2 HomeScreen verifieert kDefaultCity ('Amsterdam') niet literal '...' — conform STATE.md 07-04 beslissing over daadwerkelijke implementatie"
  - "07-05: skipOffstage: false gebruikt voor alle locatie-gerelateerde finders — ListView scrollt items buiten viewport"
  - "07-05: FakeLocationLoading gebruikt Completer die nooit completeert — betrouwbaarder dan Future.delayed voor AsyncLoading simulatie"
metrics:
  duration: 5m
  completed_date: "2026-06-03"
  tasks_completed: 2
  files_modified: 2
---

# Phase 07 Plan 05: Widget-tests locatie-UI Summary

**One-liner:** Widget-test dekking van LOC-01 t/m LOC-05 via 5 ProfileScreen tests + 2 HomeScreen tests met FakeNotifier-subklassen die GPS, toestemming en locatie-override isoleren van echte hardware.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | ProfileScreen locatie widget-tests (5 tests) | 0e128e9 | test/features/profile_screen_location_test.dart |
| 2 | HomeScreen locatienaam widget-tests (2 tests) | 1c0faad | test/features/home_screen_location_test.dart |

## What Was Built

**Task 1 — ProfileScreen locatie widget-tests:**

`test/features/profile_screen_location_test.dart` — 5 tests:
- Test 1: `find.text('GPS (automatisch)')` findsOneWidget als `locationOverride == null`
- Test 2: `find.text('Rotterdam')` findsOneWidget als `locationOverride == 'Rotterdam'` (LOC-05)
- Test 3: `find.byIcon(Icons.clear)` findsOneWidget als override actief is (LOC-03)
- Test 4: `find.byIcon(Icons.clear)` findsNothing als geen override (negatief pad)
- Test 5: `find.text('Locatie-toegang geblokkeerd')` + `find.text('Instellingen openen')` bij `LocationPermission.deniedForever` (LOC-04)

Lokaal gedefinieerde FakeNotifiers:
- `FakeProfileNotifier extends ProfileNotifier`
- `FakeGpsPermissionNotifier extends GpsPermissionNotifier`
- `FakeLocationNotifier extends LocationNotifier`
- `FakeWeatherNotifier extends WeatherNotifier` (minimaal, retourneert `[]`)

**Task 2 — HomeScreen locatienaam widget-tests:**

`test/features/home_screen_location_test.dart` — 2 tests:
- Test 1: `find.text('Rotterdam')` findsOneWidget als `locationProvider` `LocationData(city: 'Rotterdam')` retourneert (LOC-02)
- Test 2: `find.text('Amsterdam')` findsOneWidget als `locationProvider` nooit completeert (AsyncLoading fallback naar kDefaultCity)

Lokaal gedefinieerde FakeNotifiers:
- `FakeLocationNotifier extends LocationNotifier` (retourneert onmiddellijk data)
- `FakeLocationLoading extends LocationNotifier` (Completer die nooit completeert)
- `FakeWeatherNotifier`, `FakeProfileNotifier`, `FakeAvailabilityNotifier`, `FakeStaticSlotsNotifier`

**Volledige suite:** 173 tests, alle groen.

## Deviations from Plan

### Automatisch aangepast (geen afwijkingsregel)

**1. HomeScreen Test 2 verwacht 'Amsterdam' i.p.v. '...'**
- **Gevonden tijdens:** Task 2 implementatie
- **Issue:** Plan specificeerde `find.text('...')` maar de HomeScreen implementatie (STATE.md 07-04) gebruikt `locationAsync.value?.city ?? kDefaultCity` ('Amsterdam') als fallback
- **Fix:** Test verifieert `'Amsterdam'` — dit is de werkelijke geimplementeerde waarde, geen afwijking van de implementatie maar van de planspecificatie
- **Reden:** STATE.md beslissing 07-04 documenteert expliciet deze keuze; de implementatie is correct

## Decisions Made

- `FakeWeatherNotifier` lokaal in `profile_screen_location_test.dart` gedefinieerd — ProfileScreen bouwt een `ConsumerStatefulWidget` dat ProviderScope-overrides nodig heeft voor alle providers die het direct of indirect gebruikt
- `skipOffstage: false` voor alle locatie-gerelateerde tekst-finders — `ListView` rendert items buiten het viewport niet standaard (consistent met Phase 6 beslissing 07-03)
- `Completer<void>().future` voor permanente AsyncLoading — betrouwbaarder dan `Future.delayed(Duration(seconds: 60))` omdat het nooit tijdgebonden is

## Known Stubs

None — alle tests verifiëren echte widget-rendering met volledig gecontroleerde FakeNotifier-state.

## Threat Flags

None — T-07-05-01 (FakeNotifiers die echte services aanroepen) gemitigeerd: alle `build()` methoden retourneren direct een waarde zonder `Geolocator`, `SharedPreferences`, of netwerk aanroepen.

## Self-Check: PASSED (post-commit verification)

| Check | Result |
|-------|--------|
| test/features/profile_screen_location_test.dart | FOUND |
| test/features/home_screen_location_test.dart | FOUND |
| Commit 0e128e9 (Task 1) | FOUND |
| Commit 1c0faad (Task 2) | FOUND |
| flutter test profile_screen_location_test.dart — 5/5 geslaagd | PASSED |
| flutter test home_screen_location_test.dart — 2/2 geslaagd | PASSED |
| flutter test (volledige suite) — 173/173 geslaagd | PASSED |
