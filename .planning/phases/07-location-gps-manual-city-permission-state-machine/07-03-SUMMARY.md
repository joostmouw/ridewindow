---
phase: 07-location-gps-manual-city-permission-state-machine
plan: 03
subsystem: location-ui
tags: [profile, location, gps, city-picker, weather-repository]
dependency_graph:
  requires: [07-02]
  provides: [profile-locatie-sectie, weather-real-location]
  affects: [WeatherNotifier, WeatherRepository, ProfileScreen]
tech_stack:
  added: []
  patterns:
    - showModalBottomSheet city picker over kNlCities
    - skipOffstage: false in widget tests for scrollable ListView
    - locationProvider.overrideWith(FakeLocationNotifier.new) in ProviderContainer tests
key_files:
  created: []
  modified:
    - lib/features/profile/profile_screen.dart
    - lib/data/repositories/weather_repository.dart
    - lib/providers/weather_notifier.dart
    - lib/providers/weather_notifier.g.dart
    - test/features/profile_screen_test.dart
    - test/providers/weather_notifier_test.dart
    - test/providers/weather_notifier_test.mocks.dart
decisions:
  - "07-03: Riverpod 3.x gebruikt .value (niet .valueOrNull) voor AsyncValue getter — valueOrNull bestaat niet in 3.x API (bevestigd STATE.md 06-01 beslissing)"
  - "07-03: skipOffstage: false vereist in ProfileScreen widget tests — LOCATIE sectie zorgt dat RIJLENGTE/THEMA buiten de test-viewport rolt in een scrollbare ListView"
  - "07-03: FakeLocationNotifier (extends LocationNotifier) toegevoegd aan weather_notifier_test — WeatherNotifier watchet nu locationProvider; ProviderContainer tests vereisen override"
  - "07-03: when(mock.getForecast(lat: anyNamed, lon: anyNamed)) — mockito anyNamed matcher vereist na signature uitbreiding"
metrics:
  duration: 6m
  completed_date: "2026-06-03"
  tasks_completed: 2
  files_modified: 7
---

# Phase 07 Plan 03: ProfileScreen locatie-UI + WeatherNotifier echte locatie Summary

**One-liner:** ProfileScreen LOCATIE sectie met stad-picker bottom sheet en GPS-banner; WeatherRepository.getForecast({lat, lon}) + WeatherNotifier watchet locationProvider voor dynamische locatie.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | ProfileScreen LOCATIE sectie — stad-picker + GPS-banner | d237d6c | profile_screen.dart |
| 2 | WeatherRepository lat/lon params + WeatherNotifier locatie doorsturen | 8b18af5 | weather_repository.dart, weather_notifier.dart, tests |

## What Was Built

**Task 1 — ProfileScreen LOCATIE sectie:**
- LOCATIE sectiekoptekst toegevoegd boven THEMA (bestaande secties intact)
- GPS-geblokkeerd banner: rode `Card` met `errorContainer` kleur, verschijnt als `permission == LocationPermission.deniedForever`, bevat "Instellingen openen" knop die `openSettings()` aanroept
- GPS toestemming banner: `ListTile` met "Toestemming geven" knop, verschijnt als `permission == LocationPermission.denied`
- Actieve locatie `ListTile`: toont `profile.locationOverride ?? 'GPS (automatisch)'`, wis-knop (`Icons.clear`) als override actief, `onTap` opent stad-picker
- `_openCityPicker()` methode: `showModalBottomSheet` met `isScrollControlled: true`, `SizedBox` 50% hoogte, `ListView.builder` over `kNlCities`, elke tegel roept `setLocationOverride(city.name)` aan en sluit het sheet

**Task 2 — WeatherRepository + WeatherNotifier:**
- `WeatherRepository.getForecast({double lat = kDefaultLat, double lon = kDefaultLon})` — hardcoded `_amsterdamLat/_amsterdamLon` vervangen door parameters; `config.dart` import toegevoegd
- `WeatherNotifier.build()` nu `async`; `ref.watch(locationProvider.future)` voor echte locatie; `getForecast(lat: location.lat, lon: location.lon)` doorsturen
- Build_runner mock hergenereerd met nieuwe signature

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Riverpod 3.x .valueOrNull bestaat niet**
- **Found during:** Task 1 dart analyze
- **Issue:** Plan instrueerde `.valueOrNull` maar dit getter bestaat niet in Riverpod 3.x — identiek aan STATE.md beslissing 06-01
- **Fix:** Vervangen door `.value` (nullable getter in Riverpod 3.x)
- **Files modified:** lib/features/profile/profile_screen.dart
- **Commit:** d237d6c

**2. [Rule 1 - Bug] Stale MockWeatherRepository na getForecast signature wijziging**
- **Found during:** Task 2 full test suite
- **Issue:** `weather_notifier_test.mocks.dart` gegenereerd voor de signature-wijziging — `MockWeatherRepository.getForecast` had geen `lat/lon` parameters; compiler error "fewer named arguments than overridden method"
- **Fix:** `dart run build_runner build` aangeroepen om mock te regenereren; `when(mock.getForecast())` bijgewerkt naar `when(mock.getForecast(lat: anyNamed('lat'), lon: anyNamed('lon')))`
- **Files modified:** test/providers/weather_notifier_test.dart, test/providers/weather_notifier_test.mocks.dart
- **Commit:** 8b18af5

**3. [Rule 1 - Bug] WeatherNotifier test mist locationProvider override**
- **Found during:** Task 2 full test suite
- **Issue:** WeatherNotifier.build() watchet nu `locationProvider` die op zijn beurt `gpsPermissionProvider` en `profileProvider` vereist; ProviderContainer had geen override — zou GPS-syscall proberen
- **Fix:** `FakeLocationNotifier` klasse toegevoegd die vaste Amsterdam-locatie retourneert; `locationProvider.overrideWith(FakeLocationNotifier.new)` in alle drie tests
- **Files modified:** test/providers/weather_notifier_test.dart
- **Commit:** 8b18af5

**4. [Rule 1 - Bug] ProfileScreen widget tests vinden widgets niet (off-screen)**
- **Found during:** Task 2 full test suite run (tests bestonden al vóór plan 03)
- **Issue:** LOCATIE sectie boven THEMA/RIJLENGTE zorgt dat FilterChips en "Mijn schema bewerken" buiten de test-viewport rollen; `find.byType(FilterChip)` vindt 0 widgets
- **Fix:** `skipOffstage: false` toegevoegd aan alle widget-finders in profile_screen_test; `gpsPermissionProvider` mock toegevoegd (vereist na Wave 3 LOCATIE sectie)
- **Files modified:** test/features/profile_screen_test.dart
- **Commit:** 8b18af5

## Decisions Made

- `.value` (niet `.valueOrNull`) is de correcte nullable getter in Riverpod 3.x — bevestigt STATE.md 06-01 beslissing
- `skipOffstage: false` is het standaard patroon voor scrollbare ListView tests (ook STATE.md 06-04 precedent)
- `FakeLocationNotifier extends LocationNotifier` patroon consistent met D-07-12 (FakeNotifier via extends)
- `anyNamed()` matcher in mockito is de juiste aanpak voor named parameters in `when()` stubs

## Known Stubs

None — alle locatiedata is functioneel doorgebonden. WeatherNotifier gebruikt echte LocationData van locationProvider; ProfileScreen toont echte `profile.locationOverride` waarde.

## Threat Flags

None — geen nieuwe security-relevante surfaces buiten het bestaande threat model. GPS-coördinaten doorsturen naar Open-Meteo was al gedocumenteerd als T-07-03-01 (accept).

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| lib/features/profile/profile_screen.dart | FOUND |
| lib/data/repositories/weather_repository.dart | FOUND |
| lib/providers/weather_notifier.dart | FOUND |
| Commit d237d6c | FOUND |
| Commit 8b18af5 | FOUND |
| All 166 tests pass | PASSED |
