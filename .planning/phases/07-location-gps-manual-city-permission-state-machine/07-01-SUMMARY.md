---
phase: 07-location-gps-manual-city-permission-state-machine
plan: "01"
subsystem: location-foundation
tags:
  - geolocator
  - permission_handler
  - android
  - nl-cities
dependency_graph:
  requires: []
  provides:
    - geolocator 14.0.2 package resolved
    - permission_handler 12.0.3 package resolved
    - Android ACCESS_FINE_LOCATION permission
    - Android ACCESS_COARSE_LOCATION permission
    - compileSdk = 35 in build.gradle.kts
    - kNlCities const list (12 NL cities)
  affects:
    - Wave 2 GPS logic (GpsPermissionNotifier, LocationNotifier)
    - Wave 3 city picker UI
tech_stack:
  added:
    - geolocator: ^14.0.2 (baseflow.com)
    - permission_handler: ^12.0.3 (baseflow.com)
  patterns:
    - Pure Dart data class with const constructor (NlCity)
    - Curated constant list pattern (kNlCities)
key_files:
  created:
    - lib/core/nl_cities.dart
  modified:
    - pubspec.yaml
    - pubspec.lock
    - android/app/build.gradle.kts
    - android/app/src/main/AndroidManifest.xml
decisions:
  - "D-07-01: geolocator 14.0.2 — confirmed version used"
  - "D-07-02: permission_handler 12.0.3 — confirmed version used"
  - "D-07-11: compileSdk = 35 override required for permission_handler 12.x"
  - "D-07-05: 12 NL cities hardcoded in kNlCities as const List<NlCity>"
  - "Used // comment (not ///) for nl_cities.dart header to avoid dangling_library_doc_comments lint info"
metrics:
  duration: "1min 20s"
  completed_date: "2026-06-03T17:28:39Z"
  tasks_completed: 2
  files_modified: 5
---

# Phase 07 Plan 01: GPS Foundation — Packages, Android Config, NL Cities Summary

**One-liner:** Added geolocator 14.0.2 + permission_handler 12.0.3, set compileSdk = 35, added Android location permissions, and created kNlCities const list with 12 NL cities.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | pubspec.yaml + build.gradle.kts + AndroidManifest.xml | 4a5647a | pubspec.yaml, pubspec.lock, build.gradle.kts, AndroidManifest.xml |
| 2 | lib/core/nl_cities.dart — NL steden-constante | d83de44 | lib/core/nl_cities.dart |

## Verification Results

- `flutter pub get` resolved 22 new dependencies cleanly
- `geolocator: ^14.0.2` present in pubspec.yaml
- `permission_handler: ^12.0.3` present in pubspec.yaml
- `compileSdk = 35` set in android/app/build.gradle.kts
- `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` present in AndroidManifest.xml within `<manifest>` root
- `dart analyze lib/core/nl_cities.dart` — No issues found
- 12 `NlCity(` entries in kNlCities (Amsterdam, Rotterdam, Den Haag, Utrecht, Eindhoven, Groningen, Tilburg, Almere, Breda, Nijmegen, Leiden, Haarlem)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Changed `///` doc comment to `//` in nl_cities.dart**
- **Found during:** Task 2 verification
- **Issue:** `dart analyze` reported `dangling_library_doc_comments` info — a `///` at file top without a `library` directive is treated as a library doc comment and flagged
- **Fix:** Changed `///` to `//` (regular comment) so the file is analysis-clean
- **Files modified:** lib/core/nl_cities.dart
- **Commit:** d83de44 (included in same task commit)

## Known Stubs

None — this plan creates foundational infrastructure only (packages + config + data constant). No UI, no providers.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundaries introduced. Package legitimacy accepted per T-07-01-SC (baseflow.com publisher, validated in CLAUDE.md).

## Self-Check: PASSED

- [x] lib/core/nl_cities.dart exists
- [x] Commit 4a5647a exists (Task 1)
- [x] Commit d83de44 exists (Task 2)
- [x] dart analyze clean
- [x] flutter pub get clean
