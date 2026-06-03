---
phase: 07-location-gps-manual-city-permission-state-machine
plan: 04
subsystem: location-ui
tags: [home-screen, location, async-value, riverpod]
dependency_graph:
  requires: [07-02, 07-03]
  provides: [home-header-dynamic-city]
  affects: [HomeScreen]
tech_stack:
  added: []
  patterns:
    - locationAsync.value?.city ?? kDefaultCity in HomeScreen.build()
    - AsyncValue<LocationData> consumed via .value nullable getter
key_files:
  created: []
  modified:
    - lib/features/home/home_screen.dart
decisions:
  - "07-04: HomeScreen reeds bijgewerkt in Wave 2 (07-02) als Rule 3 auto-fix — locationAsync.value?.city ?? kDefaultCity al aanwezig"
  - "07-04: .value gebruikt (niet .valueOrNull) — Riverpod 3.x API consistent met STATE.md 06-01 beslissing"
  - "07-04: kDefaultCity ('Amsterdam') als fallback tijdens AsyncLoading i.p.v. literal '...' — robuuster en consistent met kDefaultLat/kDefaultLon"
metrics:
  duration: 2m
  completed_date: "2026-06-03"
  tasks_completed: 1
  files_modified: 0
---

# Phase 07 Plan 04: HomeScreen dynamische locatienaam Summary

**One-liner:** HomeScreen header toont echte locatienaam via `locationAsync.value?.city ?? kDefaultCity` — reeds geimplementeerd als Wave 2 Rule 3 auto-fix in commit 9850f0f.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | HomeScreen header — dynamische locatienaam | 9850f0f (Wave 2) | lib/features/home/home_screen.dart |

## What Was Built

**Task 1 — HomeScreen dynamische locatienaam:**

De wijzigingen waren reeds aangebracht in Wave 2 (plan 07-02) als Rule 3 auto-fix toen `locationProvider` werd omgezet van synchroon naar `AsyncNotifier<LocationData>`.

Huidige staat van `home_screen.dart` build() methode (regel 60-61):
```dart
final locationAsync = ref.watch(locationProvider);
final cityName = locationAsync.value?.city ?? kDefaultCity;
```

En doorgave aan `_buildHeader()` (regel 69):
```dart
_buildHeader(cityName, weatherState)
```

De `_buildHeader(String city, ...)` signature was reeds correct en ongewijzigd. De optionele GPS-icoon vervanging (plan sectie "Optioneel") is niet geimplementeerd — het bestaande `Icons.watch_later_outlined` icoon blijft gebruikt.

**Verificatie:**
- `dart analyze lib/features/home/home_screen.dart` — no issues found
- `grep "locationAsync"` — aanwezig op regel 60
- `grep ".value?.city"` — aanwezig op regel 61
- `flutter test test/features/` — 51/51 tests geslaagd

## Deviations from Plan

### Auto-fixed Issues (pre-existing, Wave 2)

**1. [Rule 3 - Blocking] HomeScreen bijgewerkt in Wave 2 als blocking fix**
- **Found during:** Wave 2 (07-02 plan), commit 9850f0f
- **Issue:** Na conversie van `LocationNotifier` naar `AsyncNotifier<LocationData>` compileerde `HomeScreen` niet meer — `ref.watch(locationProvider)` retourneerde nu `AsyncValue<LocationData>` maar code behandelde het als synchrone `LocationData`
- **Fix:** `locationAsync.value?.city ?? kDefaultCity` patroon toegepast
- **Files modified:** lib/features/home/home_screen.dart
- **Commit:** 9850f0f

### Afwijking van plan-specificaties

- Plan specificeerde `.valueOrNull?.city ?? '...'` maar STATE.md beslissing 06-01 bevestigt dat `.valueOrNull` niet bestaat in Riverpod 3.x — correct is `.value?.city`
- Plan specificeerde `'...'` als fallback maar `kDefaultCity` ('Amsterdam') is consistenter met de bestaande config-constanten

## Decisions Made

- `locationAsync.value?.city` (niet `.valueOrNull?.city`) — Riverpod 3.x API; `valueOrNull` bestaat niet
- `kDefaultCity` als fallback — consistent met `kDefaultLat`/`kDefaultLon` in config.dart
- Optioneel GPS-icoon niet geimplementeerd — `Icons.watch_later_outlined` volstaat voor v1

## Known Stubs

None — alle locatiedata is functioneel doorgebonden. HomeScreen toont echte stadsnaam vanuit `locationProvider`.

## Threat Flags

None — T-07-04-01 (DoS via null tijdens AsyncLoading) gemitigeerd via `?? kDefaultCity` fallback. T-07-04-02 (coördinaten niet getoond) inherent gemitigeerd — alleen `city` string wordt getoond.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| lib/features/home/home_screen.dart | FOUND |
| locationAsync.value?.city aanwezig | FOUND (regel 61) |
| Commit 9850f0f | FOUND |
| dart analyze schoon | PASSED |
| 51 feature tests geslaagd | PASSED |
