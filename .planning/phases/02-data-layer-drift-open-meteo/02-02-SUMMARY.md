---
phase: "02"
plan: "02"
subsystem: "data/remote + data/database/daos"
tags: ["http", "open-meteo", "drift", "dao", "tdd", "null-preservation"]
dependency_graph:
  requires:
    - "02-01 — AppDatabase with ForecastCacheEntries + HourlyForecastEntries tables"
    - "lib/domain/models/hourly_forecast.dart — HourlyForecast Freezed model"
  provides:
    - "OpenMeteoClient.fetch() returning List<HourlyForecast> with null preservation"
    - "ForecastDao with latestCache(), hourlyForecasts(), replaceAll()"
    - "AppDatabase.forecastDao getter"
    - "6 unit tests verifying URL params, null preservation, error handling"
  affects:
    - "lib/data/remote/"
    - "lib/data/database/daos/"
    - "lib/data/database/app_database.dart"
    - "test/data/remote/"
tech_stack:
  added:
    - "http: 1.6.0 — HTTP client for Open-Meteo API calls"
  patterns:
    - "TDD RED/GREEN cycle for OpenMeteoClient"
    - "MockHttpClient via mockito @GenerateMocks(customMocks:) pattern"
    - "Array-zip parsing: List.generate + local get() helper for null preservation"
    - "Drift DatabaseAccessor + @DriftAccessor for type-safe DAO queries"
    - "Drift transaction() for atomic replaceAll with delete+insert"
key_files:
  created:
    - lib/data/remote/open_meteo_client.dart
    - lib/data/database/daos/forecast_dao.dart
    - lib/data/database/daos/forecast_dao.g.dart
    - test/data/remote/open_meteo_client_test.dart
    - test/data/remote/open_meteo_client_test.mocks.dart
  modified:
    - lib/data/database/app_database.dart
    - lib/data/database/app_database.g.dart
    - pubspec.yaml
    - pubspec.lock
decisions:
  - "Array-zip with local get() helper chosen over HourlyForecast.fromJson() — Open-Meteo returns parallel arrays, not per-hour objects; fromJson() is designed for flat maps"
  - "@override annotation added to forecastDao getter — Drift generates a stub in _$AppDatabase that the concrete getter overrides; linter requires explicit @override"
  - "http.Client.get() called without headers parameter — Mockito mock stubs use anyNamed('headers') matcher to match both with and without headers"
metrics:
  duration_minutes: 20
  completed_date: "2026-06-02"
  tasks_completed: 2
  files_created: 5
  files_modified: 4
---

# Phase 2 Plan 2: OpenMeteoClient + ForecastDao Summary

**One-liner:** HTTP client for Open-Meteo with array-zip parsing and null preservation (FORE-05), plus Drift DAO exposing latestCache/hourlyForecasts/replaceAll for WeatherRepository.

## What Was Built

### OpenMeteoClient (lib/data/remote/open_meteo_client.dart)

HTTP client for the Open-Meteo forecast API. Key design decisions:

- `timezone=auto` and `timeformat=unixtime` are baked into the `queryParameters` map inside `fetch()`, not passed at call sites (FORE-02).
- All six hourly field names are in a static `_hourlyFields` list joined into the `hourly=` parameter (FORE-03).
- `_parseResponse()` uses a local `get(String key, int i)` helper that returns `null` when the array key is absent OR when the element at index `i` is `null`. This ensures FORE-05 (null ≠ 0) is enforced at the parsing layer.
- Constructor accepts optional `http.Client` for test injection.

### ForecastDao (lib/data/database/daos/forecast_dao.dart)

Drift `DatabaseAccessor` wired into `AppDatabase`:

- `latestCache({lat, lon})` — queries `ForecastCacheEntries` ordered by `fetchedAt DESC`, limit 1.
- `hourlyForecasts({cacheId})` — queries `HourlyForecastEntries` ordered by `time ASC`, maps rows to `HourlyForecast` domain model (unixtime → DateTime conversion at read time).
- `replaceAll({lat, lon, forecasts})` — atomic transaction: deletes existing hourly rows for all matching cache entries, deletes cache metadata, inserts fresh cache row, inserts all new hourly rows with `time` stored as unixtime integer.

### AppDatabase update

Added `daos: [ForecastDao]` to `@DriftDatabase` annotation and `forecastDao` getter (with `@override` — Drift generates a stub in the base class).

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 (RED) | Write 6 failing tests for OpenMeteoClient | 2e5c7c6 |
| 1 (GREEN) | Implement OpenMeteoClient — all 6 tests pass | c5aac2e |
| 2 | Create ForecastDao, wire into AppDatabase, regenerate | 9338d4b |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] @override annotation missing on forecastDao getter**
- **Found during:** Task 2 — `dart analyze lib/data/database/` reported `annotate_overrides` info
- **Issue:** Drift generates a `forecastDao` getter stub in the generated `_$AppDatabase` base class. The concrete getter in `AppDatabase` overrides it but lacked `@override`. Flutter lints treat this as an issue.
- **Fix:** Added `@override` annotation to the `ForecastDao get forecastDao` getter.
- **Files modified:** `lib/data/database/app_database.dart`
- **Commit:** 9338d4b (included in same task commit)

## Verification Results

| Check | Result |
|-------|--------|
| `dart test test/data/remote/open_meteo_client_test.dart` | PASS — 6/6 tests passed |
| `dart analyze lib/data/` | PASS — No issues found |
| `dart run build_runner build` | PASS — Exit 0 |
| `grep "timezone=auto" lib/data/remote/open_meteo_client.dart` | PASS — found in queryParameters |
| `grep -c "nullable()" hourly_forecast_entries.dart` | PASS — count=6 |
| `ForecastDao contains latestCache, hourlyForecasts, replaceAll` | PASS |
| `ForecastDao uses transaction()` | PASS |
| `AppDatabase has daos: [ForecastDao]` | PASS |
| `forecast_dao.g.dart exists` | PASS |
| No `?? 0` null coercion in open_meteo_client.dart | PASS |

## Known Stubs

None — all method implementations are complete and functional. WeatherRepository (Plan 02-03) is the next consumer of these components.

## Threat Flags

No new threat surface introduced beyond what is documented in the plan's `<threat_model>`:
- T-02-02 (lat/lon in URL): accepted — Amsterdam hardcoded for dev
- T-02-03 (no HTTP timeout): accepted — Phase 8 concern
- T-02-04 (JSON cast): mitigated — `get()` helper null-checks before `(val as num).toDouble()`

## Self-Check: PASSED

- lib/data/remote/open_meteo_client.dart: FOUND
- lib/data/database/daos/forecast_dao.dart: FOUND
- lib/data/database/daos/forecast_dao.g.dart: FOUND
- test/data/remote/open_meteo_client_test.dart: FOUND
- test/data/remote/open_meteo_client_test.mocks.dart: FOUND
- Commit 2e5c7c6 (RED): FOUND
- Commit c5aac2e (GREEN): FOUND
- Commit 9338d4b (ForecastDao): FOUND
