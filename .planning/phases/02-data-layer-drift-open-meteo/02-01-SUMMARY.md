---
phase: "02"
plan: "01"
subsystem: "data/database"
tags: ["drift", "sqlite", "schema", "code-gen"]
dependency_graph:
  requires: []
  provides:
    - "AppDatabase Drift class with injectable QueryExecutor"
    - "ForecastCacheEntries table (id, lat, lon, fetchedAt)"
    - "HourlyForecastEntries table with 6 nullable real weather columns"
    - "AvailabilityGridEntries table scaffold (Phase 6 writes rows)"
    - "app_database.g.dart generated Drift schema code"
  affects:
    - "lib/data/database/"
tech_stack:
  added:
    - "drift: 2.33.0 — type-safe SQLite ORM with code-gen"
    - "drift_flutter: 0.3.0 — Flutter executor (wraps sqlite3_flutter_libs + path_provider)"
    - "drift_dev: 2.33.0 — build-time code generator"
    - "mockito: 5.6.4 — test mock generation"
    - "path_provider: 2.1.5 — direct dependency for getApplicationSupportDirectory"
  patterns:
    - "Drift table classes extend Table with column getter syntax"
    - "AppDatabase extends _$AppDatabase (generated base class)"
    - "MigrationStrategy with onCreate + append-only comment convention"
    - "Optional QueryExecutor constructor for test injection"
key_files:
  created:
    - lib/data/database/tables/forecast_cache_entries.dart
    - lib/data/database/tables/hourly_forecast_entries.dart
    - lib/data/database/tables/availability_grid_entries.dart
    - lib/data/database/app_database.dart
    - lib/data/database/app_database.g.dart
  modified:
    - pubspec.yaml
    - pubspec.lock
decisions:
  - "mockito downgraded from ^5.7.0 to ^5.6.4 — mockito 5.6.5+ requires analyzer ^13.0.0 which conflicts with drift_dev 2.33.0 (requires analyzer <13.0.0)"
  - "path_provider added as direct dependency — app_database.dart imports it directly for getApplicationSupportDirectory"
  - "Part directives removed from table files — Drift 2.x does not require part '*.g.dart' in individual table files; all generated code aggregated in app_database.g.dart"
  - "AvailabilityGridEntries scaffolded with no rows — Phase 6 writes availability data; schema included here to establish complete PERS-03 v1 baseline"
metrics:
  duration_minutes: 15
  completed_date: "2026-06-02"
  tasks_completed: 2
  files_created: 5
  files_modified: 2
---

# Phase 2 Plan 1: Drift Schema Setup Summary

**One-liner:** Drift 2.33.0 database with injectable QueryExecutor, three-table v1 schema (ForecastCache + HourlyForecast + AvailabilityGrid scaffold), and generated app_database.g.dart.

## What Was Built

Added Drift to the project and defined the complete v1 database schema. The schema establishes two forecast tables (`ForecastCacheEntries` for cache metadata and `HourlyForecastEntries` with six nullable real weather columns) plus an `AvailabilityGridEntries` scaffold table that Phase 6 will populate.

`AppDatabase` uses `schemaVersion=1` with a `MigrationStrategy` scaffolded for future append-only column additions. The constructor accepts an optional `QueryExecutor` parameter, allowing tests to inject `NativeDatabase.memory()` without triggering Flutter-specific executors.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Add drift, drift_flutter, drift_dev, mockito to pubspec.yaml | 5165871 |
| 2 | Create Drift table files, AppDatabase, generate app_database.g.dart | 43d7e18 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed incorrect part directives from table files**
- **Found during:** Task 2 verification (`dart analyze` step)
- **Issue:** Plan specified `part 'forecast_cache_entries.g.dart'` etc. in table files. In Drift 2.x, table classes do NOT need individual part directives — build_runner generates all code into `app_database.g.dart` (part of `app_database.dart`). The analyzer reported `uri_has_not_been_generated` errors for all three table `.g.dart` files.
- **Fix:** Removed all `part '*.g.dart'` directives from the three table files.
- **Files modified:** `forecast_cache_entries.dart`, `hourly_forecast_entries.dart`, `availability_grid_entries.dart`
- **Commit:** 43d7e18

**2. [Rule 1 - Bug] mockito downgraded from ^5.7.0 to ^5.6.4**
- **Found during:** Task 1 — `flutter pub get` failed
- **Issue:** `mockito >=5.6.5` requires `analyzer ^13.0.0` but `drift_dev 2.33.0` requires `analyzer >=10.0.0 <13.0.0`. The two constraints are mutually exclusive.
- **Fix:** Downgraded `mockito` constraint from `^5.7.0` to `^5.6.4`. Version 5.6.4 resolves cleanly alongside drift_dev 2.33.0.
- **Files modified:** `pubspec.yaml`, `pubspec.lock`
- **Commit:** 5165871

**3. [Rule 2 - Missing critical dependency] Added path_provider as direct dependency**
- **Found during:** Task 2 — `dart analyze` reported `The imported package 'path_provider' isn't a dependency of the importing package`
- **Issue:** `app_database.dart` imports `path_provider` directly but it was only a transitive dependency via `drift_flutter`. Dart's analysis rules require explicitly declaring direct imports.
- **Fix:** Added `path_provider: ^2.1.0` to pubspec.yaml dependencies.
- **Files modified:** `pubspec.yaml`, `pubspec.lock`
- **Commit:** 43d7e18

## Verification Results

| Check | Result |
|-------|--------|
| `dart analyze lib/data/` | PASS — No issues found |
| `dart run build_runner build` | PASS — Exit 0 |
| `app_database.g.dart` exists | PASS — 69KB file |
| `app_database.g.dart` contains `class _$AppDatabase` | PASS |
| HourlyForecastEntries has 6 nullable real columns | PASS — count=6 |
| AppDatabase constructor accepts optional QueryExecutor | PASS |

## Known Stubs

None — this plan only defines schema structure with no data. The `AvailabilityGridEntries` table is intentionally empty (scaffold only); Phase 6 will write rows.

## Self-Check: PASSED

- lib/data/database/tables/forecast_cache_entries.dart: FOUND
- lib/data/database/tables/hourly_forecast_entries.dart: FOUND
- lib/data/database/tables/availability_grid_entries.dart: FOUND
- lib/data/database/app_database.dart: FOUND
- lib/data/database/app_database.g.dart: FOUND
- Commit 5165871: FOUND
- Commit 43d7e18: FOUND
