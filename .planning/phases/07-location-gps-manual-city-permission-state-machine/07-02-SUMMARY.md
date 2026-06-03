---
phase: 07-location-gps-manual-city-permission-state-machine
plan: 02
subsystem: location
tags: [gps, permissions, async-notifier, riverpod, state-machine]
dependency_graph:
  requires: [07-01]
  provides: [gpsPermissionProvider, locationProvider]
  affects: [home_screen, weather_notifier]
tech_stack:
  added: []
  patterns: [AsyncNotifier, FakeNotifier TDD, ProviderContainer tests, build_runner codegen]
key_files:
  created:
    - lib/providers/gps_permission_notifier.dart
    - lib/providers/gps_permission_notifier.g.dart
    - test/providers/gps_permission_notifier_test.dart
    - test/providers/location_provider_test.dart
  modified:
    - lib/providers/location_provider.dart
    - lib/providers/location_provider.g.dart
    - lib/features/home/home_screen.dart
decisions:
  - "GpsPermissionNotifier uses Geolocator.checkPermission() in build() for initial state"
  - "LocationNotifier implements three-step priority: profile override > GPS > Amsterdam default"
  - "HomeScreen updated to handle AsyncValue<LocationData> via .value?.city with kDefaultCity fallback"
  - "FakeNotifier pattern (extends concrete class) used for all provider tests"
metrics:
  duration: "~15 minutes"
  completed_date: "2026-06-03T17:34:14Z"
  tasks_completed: 2
  files_changed: 7
---

# Phase 07 Plan 02: GPS Permission State Machine + LocationNotifier Summary

GPS toestemmings-state machine (GpsPermissionNotifier) en echte LocationNotifier met drie-stappen prioriteitslogica: city override > GPS-coördinaten > Amsterdam default.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 (RED) | GpsPermissionNotifier test | a7a5961 | test/providers/gps_permission_notifier_test.dart |
| 1 (GREEN) | GpsPermissionNotifier implementation | 29a642e | lib/providers/gps_permission_notifier.dart, .g.dart |
| 2 (RED) | LocationNotifier tests | 9a269e0 | test/providers/location_provider_test.dart |
| 2 (GREEN) | LocationNotifier implementation | 9850f0f | lib/providers/location_provider.dart, .g.dart, home_screen.dart |

## What Was Built

**GpsPermissionNotifier** (`lib/providers/gps_permission_notifier.dart`):
- `AsyncNotifier<LocationPermission>` with generated `gpsPermissionProvider`
- `build()` calls `Geolocator.checkPermission()` for initial permission state
- `requestPermission()` calls `Geolocator.requestPermission()` and updates state
- `openSettings()` calls `openAppSettings()` from `permission_handler` (LOC-04)

**LocationNotifier** (`lib/providers/location_provider.dart`):
- `AsyncNotifier<LocationData>` replacing the hardcoded stub, generated `locationProvider`
- Implements LOC-05: city override from `profileProvider.locationOverride` takes priority
- Implements LOC-02: GPS coordinates returned when permission is `whileInUse` or `always`
- Implements LOC-04: Amsterdam default when GPS denied and no override
- T-07-02-02 mitigated: 30s `timeLimit` in `LocationSettings` + try-catch fallback
- Unknown city override falls back to `kNlCities.first` (Amsterdam)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] HomeScreen does not compile after locationProvider change to AsyncNotifier**
- **Found during:** Task 2 GREEN verification
- **Issue:** `HomeScreen` called `location.city` directly on `AsyncValue<LocationData>`, which was valid for the old synchronous `location(Ref ref)` provider but not for the new `LocationNotifier extends _$LocationNotifier`
- **Fix:** Added `import 'package:ridewindow/core/config.dart'` and changed `final location = ref.watch(locationProvider)` + `location.city` to `final locationAsync = ref.watch(locationProvider)` + `final cityName = locationAsync.value?.city ?? kDefaultCity`
- **Files modified:** `lib/features/home/home_screen.dart`
- **Commit:** 9850f0f (included in GREEN commit)

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED (test) Task 1 | a7a5961 | PASS |
| GREEN (feat) Task 1 | 29a642e | PASS |
| RED (test) Task 2 | 9a269e0 | PASS |
| GREEN (feat) Task 2 | 9850f0f | PASS |

## Verification Evidence

```
dart analyze lib/providers/gps_permission_notifier.dart  → No issues found
dart analyze lib/providers/location_provider.dart        → No issues found
dart analyze lib/features/home/home_screen.dart          → No issues found
flutter test test/providers/gps_permission_notifier_test.dart → +2 All tests passed
flutter test test/providers/location_provider_test.dart       → +3 All tests passed
grep gpsPermissionProvider gps_permission_notifier.g.dart     → found
grep locationProvider location_provider.g.dart                → found
```

## Known Stubs

None. LocationNotifier is a full real implementation that replaces the previous stub. GPS coordinates (`city: 'GPS'`) returned when GPS permission granted — no placeholder values.

## Threat Flags

No new threat surface introduced beyond what was catalogued in the plan's threat model (T-07-02-01 through T-07-02-SC). T-07-02-02 (GPS timeout DoS) is mitigated via 30s timeLimit + try-catch.

## Self-Check: PASSED

- [x] `lib/providers/gps_permission_notifier.dart` — FOUND
- [x] `lib/providers/gps_permission_notifier.g.dart` — FOUND
- [x] `lib/providers/location_provider.dart` — FOUND (contains LocationNotifier)
- [x] `lib/providers/location_provider.g.dart` — FOUND (contains locationProvider)
- [x] `test/providers/gps_permission_notifier_test.dart` — FOUND
- [x] `test/providers/location_provider_test.dart` — FOUND
- [x] Commits a7a5961, 29a642e, 9a269e0, 9850f0f — all present in git log
