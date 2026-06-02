---
phase: "02-data-layer-drift-open-meteo"
plan: "03"
subsystem: "data/repositories"
tags: ["drift", "cache-policy", "repository-pattern", "tdd", "null-preservation", "amsterdam-coords"]
dependency_graph:
  requires:
    - "02-01 — AppDatabase with ForecastCacheEntries + HourlyForecastEntries tables"
    - "02-02 — ForecastDao (latestCache, hourlyForecasts, replaceAll) + OpenMeteoClient.fetch()"
  provides:
    - "WeatherRepository.getForecast() with 1-hour cache policy"
    - "Cache-hit path: returns DB rows without HTTP call when cache < 1h old"
    - "Cache-miss path: fetches, persists, and returns fresh data on cold start or stale cache"
    - "Null field preservation end-to-end: null windspeedKmh from API surfaces as null in domain model"
    - "5 unit tests covering cold start, fresh cache, stale cache, null preservation, Amsterdam coordinates"
  affects:
    - "Phase 3 — Riverpod providers call WeatherRepository.getForecast() directly"
tech-stack:
  added: []
  patterns:
    - "Repository owns cache policy — staleness check (DateTime.now().difference(cache.fetchedAt) < _cacheDuration) lives in WeatherRepository, not in providers"
    - "TDD RED/GREEN cycle — stub with UnimplementedError first, then implement"
    - "NativeDatabase.memory() passed as QueryExecutor to AppDatabase constructor for in-memory integration tests"
    - "flutter test used for repository tests (vs dart test for pure-Dart client tests) because AppDatabase imports drift_flutter which pulls Flutter UI"
key-files:
  created:
    - lib/data/repositories/weather_repository.dart
    - test/data/repositories/weather_repository_test.dart
    - test/data/repositories/weather_repository_test.mocks.dart
  modified: []
key-decisions:
  - "flutter test chosen over dart test for repository tests — AppDatabase imports drift_flutter which transitively pulls dart:ui; dart test cannot load this without the Flutter engine"
  - "NativeDatabase.memory() passed directly as QueryExecutor (not wrapped in DatabaseConnection) — Drift 2.x AppDatabase([QueryExecutor?]) constructor accepts NativeDatabase directly"
  - "Amsterdam coordinates hardcoded in WeatherRepository (not in OpenMeteoClient or ForecastDao) — repository is the caller of fetch(), so it is the correct layer for the dev placeholder"
patterns-established:
  - "Repository cache pattern: latestCache() → staleness check → return cached rows OR fetch + replaceAll + return fresh"
  - "Static const coordinates with TODO Phase N comment — marks replacement point for Phase 7 LocationService"
requirements-completed: ["FORE-01", "FORE-04", "FORE-05"]
duration: 4min
completed: "2026-06-02"
---

# Phase 2 Plan 3: WeatherRepository Summary

**Cache-policy orchestrator wiring ForecastDao + OpenMeteoClient with 1-hour staleness check, Amsterdam dev coordinates, and null-preservation verified end-to-end.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-06-02T20:05:42Z
- **Completed:** 2026-06-02T20:09:00Z
- **Tasks:** 2 (Task 1: TDD RED + GREEN; Task 2: full suite gate)
- **Files modified:** 3 created

## Accomplishments

- WeatherRepository.getForecast() returns DB rows without HTTP when cache < 1 hour old
- Re-fetches via OpenMeteoClient and persists via ForecastDao.replaceAll() on cold start or stale cache
- Null windspeedKmh from API preserved as null through repository → domain model (FORE-05 end-to-end)
- Amsterdam lat/lon hardcoded as static const with TODO Phase 7 comment (FORE-01 dev baseline)
- Full test suite now passes: 78 tests (67 domain + 6 client + 5 repository)

## Task Commits

Each task was committed atomically:

1. **Task 1 (RED): Failing tests for WeatherRepository** - `bb1ad80` (test)
2. **Task 1 (GREEN): Implement WeatherRepository** - `22f5a68` (feat)

**Plan metadata:** *(final docs commit follows)*

*Note: TDD task has two commits (test RED → feat GREEN)*

## Files Created/Modified

- `lib/data/repositories/weather_repository.dart` — WeatherRepository with cache policy; static const Amsterdam coordinates; _cacheDuration = 1h
- `test/data/repositories/weather_repository_test.dart` — 5 unit tests: cold start, fresh cache, stale cache, null preservation, Amsterdam coordinates
- `test/data/repositories/weather_repository_test.mocks.dart` — Generated MockHttpClient via @GenerateMocks(customMocks:)

## Decisions Made

- **flutter test vs dart test:** The repository test imports AppDatabase which imports drift_flutter (needs Flutter engine). `dart test` fails with "dart:ui not available". Used `flutter test` for repository tests.
- **NativeDatabase.memory() direct:** Drift 2.x AppDatabase constructor accepts a `QueryExecutor?` directly. `DatabaseConnection(NativeDatabase.memory())` — DatabaseConnection is not a separate class in Drift 2.x; passing NativeDatabase directly is correct.
- **Location of Amsterdam hardcode:** WeatherRepository is the correct layer — it calls OpenMeteoClient.fetch(lat, lon), so the placeholder coordinates belong there (not in the client or DAO).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] DatabaseConnection wrapper not available in Drift 2.x**
- **Found during:** Task 1 (RED) — `flutter test` reported "Method not found: 'DatabaseConnection'"
- **Issue:** The plan's test template used `AppDatabase(DatabaseConnection(NativeDatabase.memory()))` but Drift 2.x AppDatabase([QueryExecutor? executor]) accepts NativeDatabase directly as a QueryExecutor; there is no separate DatabaseConnection constructor
- **Fix:** Changed `DatabaseConnection(NativeDatabase.memory())` to `NativeDatabase.memory()` in the test setUp
- **Files modified:** `test/data/repositories/weather_repository_test.dart`
- **Verification:** flutter test passed with all 5 tests after the fix
- **Committed in:** bb1ad80 (included in RED task commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary correctness fix for Drift 2.x API. No scope creep.

## Issues Encountered

- `dart test` cannot load files that transitively import `drift_flutter` (pulls `dart:ui`). Solution: use `flutter test` for all tests in the `data/` layer that import AppDatabase. Pure-Dart tests (domain/, data/remote/) remain runnable with `dart test`.

## Known Stubs

None — WeatherRepository is fully implemented. The Amsterdam coordinates are an intentional dev placeholder (not a stub), documented with a `// TODO Phase 7` comment.

## Threat Flags

No new threat surface beyond the plan's threat model:
- T-02-05 (replaceAll partial write): mitigated — Drift transaction wraps delete+insert
- T-02-06 (concurrent stale cache calls): accepted — Phase 3 Riverpod provider serialises callers
- T-02-07 (hardcoded lat/lon): accepted — no PII, Phase 7 replaces with GPS

## Self-Check: PASSED

- lib/data/repositories/weather_repository.dart: FOUND
- test/data/repositories/weather_repository_test.dart: FOUND
- test/data/repositories/weather_repository_test.mocks.dart: FOUND
- Commit bb1ad80 (RED): FOUND
- Commit 22f5a68 (GREEN): FOUND
- `dart test test/data/repositories/weather_repository_test.dart` (via flutter test): 5/5 PASS
- `flutter test --reporter=compact`: 78/78 PASS
- `dart analyze lib/data/`: No issues found
- `grep "_amsterdamLat"`: FOUND in weather_repository.dart
- `grep "MIGRATION RULE"`: FOUND in app_database.dart

## Next Phase Readiness

- WeatherRepository is ready to be injected as a Riverpod provider in Phase 3
- Phase 3 pattern: `@riverpod Future<List<HourlyForecast>> forecastData(ref) => WeatherRepository(db: ref.watch(appDatabaseProvider), client: ref.watch(openMeteoClientProvider)).getForecast()`
- No blockers

---
*Phase: 02-data-layer-drift-open-meteo*
*Completed: 2026-06-02*
