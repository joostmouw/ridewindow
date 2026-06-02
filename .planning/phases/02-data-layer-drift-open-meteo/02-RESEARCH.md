# Phase 2: Data layer — Drift + Open-Meteo — Research

**Researched:** 2026-06-02
**Domain:** Flutter local database (Drift/SQLite), HTTP networking (dart:http + Open-Meteo), repository pattern with cache
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FORE-01 | App fetches 7-day hourly weather forecast from Open-Meteo for the user's location (lat/lon) | OpenMeteoClient.fetch() pattern; Amsterdam hardcoded for dev |
| FORE-02 | Forecast requests pass `timezone=auto&timeformat=unixtime` so timestamps are local-correct | Enforced at client construction, not call-site; baked into base URL |
| FORE-03 | Forecast response includes all six required fields | All six confirmed valid API params; both `windspeed_10m` and `wind_speed_10m` spellings accepted |
| FORE-04 | Forecast results are cached locally (Drift) with `fetched_at`; reused within 1h, refetched after | WeatherRepository pattern; unit-tested with injected mock HTTP client + in-memory Drift DB |
| FORE-05 | All forecast fields are modeled as nullable; missing data surfaced (not treated as 0) | `double?` columns in Drift `HourlyForecastEntries` table; preserved through to domain model |
| PERS-02 | Availability grid and forecast cache persist in Drift (SQLite) | Drift schema with `ForecastCacheEntries` table for cache metadata |
| PERS-03 | Drift schema is versioned with explicit migrations for v1→v1.x upgrades | `schemaVersion = 1`, `MigrationStrategy` scaffolded with `onCreate`/`onUpgrade`, append-only comment |
</phase_requirements>

---

## Summary

Phase 2 builds the data layer: an HTTP client for Open-Meteo, a Drift database schema for forecast storage, and a `WeatherRepository` that serves cached data within 1 hour and triggers a re-fetch when the cache is stale. Amsterdam coordinates are hardcoded so the layer is fully testable before GPS location (Phase 7) is wired.

The technology choices are already locked in CLAUDE.md: `drift 2.33.0` + `drift_flutter 0.3.0` for SQLite persistence, `http 1.6.0` for networking. No alternatives need evaluating. The research focuses on: correct Drift table definitions with nullable real columns, the precise Open-Meteo request URL shape, the cache-check pattern in `WeatherRepository`, and how to test all of this with an in-memory Drift database and a Mockito-generated `MockHttpClient`.

One field-name nuance to flag for planning: the existing `HourlyForecast` Freezed model uses `windspeed_10m` and `winddirection_10m` (no separator between "wind" and "speed/direction"). **Both spellings are accepted by the Open-Meteo API** — confirmed by live API call returning identical data for both names. The existing model spellings are safe to use as-is.

**Primary recommendation:** Build `OpenMeteoClient` → `AppDatabase` + Drift tables → `WeatherRepository` in that order. Each layer is independently testable: the client with a mock HTTP client, the database with `NativeDatabase.memory()`, and the repository with both injected together.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| HTTP fetch from Open-Meteo | Data layer (`lib/data/`) | — | Network I/O belongs in data, not domain |
| JSON parsing → `HourlyForecast` | Data layer (`lib/data/`) | Domain model (already defined) | Mapping between wire format and domain model |
| Forecast cache storage | Data layer (`lib/data/`) | — | Drift DB lives in data tier |
| Cache staleness check (1h) | Data layer (`lib/data/`) | — | Repository owns the cache policy |
| `HourlyForecast` domain model | Domain layer (`lib/domain/`) | — | Already built in Phase 1.5 — no change |
| Amsterdam hardcode (dev) | Data layer (`lib/data/`) | — | Config constant, replaced in Phase 7 by GPS |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `drift` | 2.33.0 | Type-safe SQLite ORM with code-gen | Flutter Favorite, CLAUDE.md locked, published 28 days ago [VERIFIED: pub.dev] |
| `drift_flutter` | 0.3.0 | Flutter-specific Drift executor (`driftDatabase()`) | Official companion package; wraps `sqlite3_flutter_libs` + `path_provider` | [VERIFIED: pub.dev] |
| `drift_dev` | 2.33.0 | Build-time code generator for Drift | Required dev tool — generates `*.g.dart` schema files [VERIFIED: pub.dev] |
| `http` | 1.6.0 | HTTP client for Open-Meteo API | dart.dev published, CLAUDE.md locked — no Dio needed for single GET [VERIFIED: pub.dev] |

### Supporting (dev / test only)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mockito` | 5.7.0 | Generate `MockHttpClient` for repository unit tests | Required to mock `http.Client` in tests [VERIFIED: pub.dev] |
| `build_runner` | ^2.4.0 | Already in pubspec; also generates mockito mocks | Run once after adding `@GenerateMocks` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `mockito` for HTTP mocking | `http` package's built-in `MockClient` | `http` has a `MockClient` in `package:http/testing.dart`; it does NOT require code gen. Simpler for one-off stubs. Either is fine; `mockito` is more consistent with project patterns if Phase 3 already uses it. |

**Installation (additions to pubspec.yaml):**

```yaml
# Add to dependencies:
drift: ^2.33.0
drift_flutter: ^0.3.0

# Add to dev_dependencies:
drift_dev: ^2.33.0
mockito: ^5.7.0
# build_runner already present
```

Note: `drift_flutter` transitively brings `sqlite3_flutter_libs`, `path_provider`, and `sqlite3` — do not add these separately.

---

## Package Legitimacy Audit

> slopcheck not available in this environment. All packages below are tagged `[ASSUMED]` per graceful degradation protocol. However, all four packages are in the CLAUDE.md verified-publisher table (drift) or are dart.dev / official publishers, providing strong legitimacy signal. The project's existing STATE.md notes that the package legitimacy audit was already handled via the CLAUDE.md verified-publisher table.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `drift` | pub.dev | ~6 yrs | 2.4k likes | github.com/simolus3/drift | [ASSUMED] | Approved — Flutter Favorite, CLAUDE.md verified |
| `drift_flutter` | pub.dev | ~1 yr | Official companion | github.com/simolus3/drift | [ASSUMED] | Approved — same author as drift |
| `drift_dev` | pub.dev | ~6 yrs | Official dev tool | github.com/simolus3/drift | [ASSUMED] | Approved — same author as drift |
| `mockito` | pub.dev | ~7 yrs | High | github.com/dart-lang/mockito | [ASSUMED] | Approved — dart.dev publisher |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Amsterdam coords (hardcoded const)
        |
        v
  OpenMeteoClient
  ┌───────────────────────────────────────┐
  │ base URL: https://api.open-meteo.com  │
  │ ?timezone=auto&timeformat=unixtime    │  ← enforced here, not at call site
  │ +hourly=…all six fields…              │
  │ fetch(lat, lon) → List<HourlyForecast>│
  └───────────────────────────────────────┘
        |                          ^
        | HTTP GET                 | JSON → domain model
        v                          |
  Open-Meteo API             parse response
  (external, free)

  WeatherRepository
  ┌─────────────────────────────────────────┐
  │ getForecast()                           │
  │   1. read ForecastCache from Drift      │
  │   2. if cache.fetched_at > now - 1h     │
  │        return cached HourlyForecasts    │
  │   3. else call OpenMeteoClient.fetch()  │
  │        persist to Drift                 │
  │        return fresh HourlyForecasts     │
  └─────────────────────────────────────────┘
        |
        v
  AppDatabase (Drift)
  ┌────────────────────────────────────────┐
  │ ForecastCacheEntries table             │
  │   id, fetched_at (DateTime), lat, lon  │
  │                                        │
  │ HourlyForecastEntries table            │
  │   id, cache_id (FK), time (int unixtime│
  │   temperature, apparent_temp,          │
  │   precipitation, precip_prob,          │
  │   windspeed, winddirection             │
  │   (all weather fields: real().nullable)│
  └────────────────────────────────────────┘
        |
        v
  Phase 3: Riverpod WeatherNotifier consumes WeatherRepository
```

### Recommended Project Structure

```
lib/
├── data/
│   ├── database/
│   │   ├── app_database.dart          # @DriftDatabase class, schemaVersion, MigrationStrategy
│   │   ├── app_database.g.dart        # generated
│   │   ├── tables/
│   │   │   ├── forecast_cache_entries.dart
│   │   │   └── hourly_forecast_entries.dart
│   │   └── daos/
│   │       └── forecast_dao.dart      # type-safe queries on forecast tables
│   ├── remote/
│   │   └── open_meteo_client.dart     # http.Client, URL construction, JSON parsing
│   └── repositories/
│       └── weather_repository.dart    # cache policy, orchestrates DAO + client
├── domain/                            # unchanged from Phase 1.5
│   ├── models/
│   │   └── hourly_forecast.dart       # already built
│   └── services/
│       └── ...
test/
└── data/
    ├── remote/
    │   └── open_meteo_client_test.dart  # mock http.Client
    └── repositories/
        └── weather_repository_test.dart # NativeDatabase.memory() + mock client
```

### Pattern 1: Drift Table with Nullable Real Columns

**What:** Define a Drift table that stores nullable doubles (all six weather fields).
**When to use:** Any persisted weather measurement that may be absent from the API response.

```dart
// Source: https://drift.simonbinder.eu/dart_api/tables/
import 'package:drift/drift.dart';

class HourlyForecastEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cacheId => integer().references(ForecastCacheEntries, #id)();
  IntColumn get time => integer()();             // unixtime from Open-Meteo

  RealColumn get temperatureC => real().nullable()();
  RealColumn get apparentTemperatureC => real().nullable()();
  RealColumn get precipitationMm => real().nullable()();
  RealColumn get precipitationProbability => real().nullable()();
  RealColumn get windspeedKmh => real().nullable()();
  RealColumn get winddirectionDeg => real().nullable()();
}

class ForecastCacheEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  DateTimeColumn get fetchedAt => dateTime()();
}
```

### Pattern 2: Open-Meteo Client with Baked-In Params

**What:** Enforce `timezone=auto&timeformat=unixtime` at the client level so no call site can forget them.
**When to use:** Always — this is the only HTTP client in the app.

```dart
// Source: https://open-meteo.com/en/docs (verified by live API call)
class OpenMeteoClient {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _hourlyFields = [
    'temperature_2m',
    'apparent_temperature',
    'precipitation',
    'precipitation_probability',
    'windspeed_10m',      // Both spellings accepted by API — match HourlyForecast model
    'winddirection_10m',
  ].join(',');

  final http.Client _client;
  OpenMeteoClient({http.Client? client}) : _client = client ?? http.Client();

  Future<List<HourlyForecast>> fetch(double lat, double lon) async {
    final uri = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon'
      '&hourly=$_hourlyFields'
      '&timezone=auto&timeformat=unixtime',
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Open-Meteo error: ${response.statusCode}');
    }
    return _parseResponse(response.body);
  }

  List<HourlyForecast> _parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<int>();
    // zip times with field arrays — each index i produces one HourlyForecast
    return List.generate(times.length, (i) {
      double? _get(String key) {
        final list = hourly[key];
        if (list == null) return null;
        final val = (list as List)[i];
        if (val == null) return null;
        return (val as num).toDouble();
      }
      return HourlyForecast(
        time: DateTime.fromMillisecondsSinceEpoch(times[i] * 1000),
        temperatureC: _get('temperature_2m'),
        apparentTemperatureC: _get('apparent_temperature'),
        precipitationMm: _get('precipitation'),
        precipitationProbability: _get('precipitation_probability'),
        windspeedKmh: _get('windspeed_10m'),
        winddirectionDeg: _get('winddirection_10m'),
      );
    });
  }
}
```

Note: `HourlyForecast.fromJson()` (the existing Freezed `@JsonKey` mapping) is designed for a flat JSON object (one hour per map). Open-Meteo returns arrays-of-values. The client must zip the arrays manually (as shown above) rather than calling `HourlyForecast.fromJson()` directly on the API response.

### Pattern 3: WeatherRepository Cache Policy

**What:** Check `fetched_at` staleness; return cached data or re-fetch.
**When to use:** Every call to `getForecast()` goes through this logic.

```dart
class WeatherRepository {
  final AppDatabase _db;
  final OpenMeteoClient _client;
  static const _cacheDuration = Duration(hours: 1);
  static const _amsterdamLat = 52.3676;
  static const _amsterdamLon = 4.9041;

  WeatherRepository({required AppDatabase db, required OpenMeteoClient client})
      : _db = db, _client = client;

  Future<List<HourlyForecast>> getForecast() async {
    final cache = await _db.forecastDao.latestCache(
      lat: _amsterdamLat, lon: _amsterdamLon,
    );
    if (cache != null &&
        DateTime.now().difference(cache.fetchedAt) < _cacheDuration) {
      return _db.forecastDao.hourlyForecasts(cacheId: cache.id);
    }
    final fresh = await _client.fetch(_amsterdamLat, _amsterdamLon);
    await _db.forecastDao.replaceAll(
      lat: _amsterdamLat, lon: _amsterdamLon, forecasts: fresh,
    );
    return fresh;
  }
}
```

### Pattern 4: Drift Migration Scaffolding (v1 baseline)

**What:** Establish `schemaVersion = 1`, `MigrationStrategy` with `onCreate`, and the append-only comment before any data is written.
**When to use:** The very first database class definition in this phase.

```dart
// Source: https://drift.simonbinder.eu/docs/migrations/
@DriftDatabase(tables: [ForecastCacheEntries, HourlyForecastEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // MIGRATION RULE: columns are append-only.
  // Never remove or rename a column; always add new columns in a new
  // schemaVersion block with a nullable default or an explicit default value.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 → v1.x example (for future use):
          // if (from < 2) {
          //   await m.addColumn(hourlyForecastEntries, hourlyForecastEntries.someNewField);
          // }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'ridewindow',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
```

### Pattern 5: Unit Test with In-Memory DB + Mock HTTP Client

**What:** Test the `WeatherRepository` cache policy with deterministic inputs.
**When to use:** Two tests minimum — fresh cache returns cached data; stale cache triggers re-fetch.

```dart
// Sources:
//   - https://drift.simonbinder.eu/testing/ (NativeDatabase.memory)
//   - https://docs.flutter.dev/cookbook/testing/unit/mocking (Mockito pattern)
import 'package:drift/native.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([], customMocks: [MockSpec<http.Client>(as: #MockHttpClient)])
void main() {
  late AppDatabase db;
  late MockHttpClient mockHttp;
  late WeatherRepository repo;

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    mockHttp = MockHttpClient();
    repo = WeatherRepository(
      db: db,
      client: OpenMeteoClient(client: mockHttp),
    );
  });

  tearDown(() => db.close());

  test('returns cached forecast when fetched_at is within 1 hour', () async {
    // Seed cache with a recent fetched_at
    // ... insert rows, then call repo.getForecast() and verify no HTTP call made
    verifyNever(mockHttp.get(any));
  });

  test('re-fetches when cache is older than 1 hour', () async {
    // Seed cache with fetched_at = 2 hours ago
    // stub mockHttp to return valid JSON
    when(mockHttp.get(any)).thenAnswer((_) async => http.Response(_validJson, 200));
    await repo.getForecast();
    verify(mockHttp.get(any)).called(1);
  });

  test('null field in API response is preserved as null, not coerced to 0', () async {
    when(mockHttp.get(any))
        .thenAnswer((_) async => http.Response(_jsonWithNullWindspeed, 200));
    final forecasts = await repo.getForecast();
    expect(forecasts.first.windspeedKmh, isNull);
  });
}
```

### Anti-Patterns to Avoid

- **Putting cache policy in the provider (Phase 3):** Cache staleness logic belongs in `WeatherRepository`, not in `WeatherNotifier`. Providers should call the repository and let it decide whether to fetch.
- **Static `http.get()` calls:** Using `http.get(uri)` (static) instead of `client.get(uri)` (instance) makes the client impossible to mock. Always inject `http.Client`.
- **Calling `HourlyForecast.fromJson()` directly on the API response:** Open-Meteo returns parallel arrays, not an array of per-hour objects. The client must zip arrays manually.
- **Forgetting `drift` import in table files:** Table files need `import 'package:drift/drift.dart'` — `part 'of'` alone is not sufficient.
- **`drift_flutter: ^0.3.1-wip` in pubspec:** The docs mention `0.3.1-wip` but pub.dev latest stable is `0.3.0`. Use `^0.3.0`.
- **DateTime vs unixtime in cache table:** Store `fetchedAt` as `dateTime()` (Drift handles conversion). Store `time` from Open-Meteo as `integer()` (unixtime), converted to `DateTime` in the domain layer.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SQLite schema + type-safe queries | Custom SQL strings + `sqflite` rawQuery() | Drift with code-gen | Type safety at compile time; migration system; stream queries for Phase 3 reactivity |
| HTTP response caching (TTL) | Custom in-memory map with expiry | Drift `fetched_at` column + repository check | Persistent across app restarts; survives WorkManager cycle |
| Mock HTTP responses in tests | Custom `FakeHttpClient` class | `mockito` `@GenerateMocks` + `MockHttpClient` | Null-safe mocks with `when()`/`verify()`; consistent with project toolchain |
| DateTime timezone conversion | Manual offset math | `timeformat=unixtime` + `DateTime.fromMillisecondsSinceEpoch()` | Open-Meteo returns UTC epoch; Dart handles display-layer conversion |

**Key insight:** The fetch-check-cache pattern looks simple but has several edge cases: concurrent calls triggering two fetches, partial writes on crash, and WorkManager background isolates reinitialising the DB. Drift's transaction support prevents partial writes; WeatherRepository handles concurrent calls if accessed through a single Riverpod provider in Phase 3.

---

## Common Pitfalls

### Pitfall 1: Open-Meteo Returns Arrays, Not Per-Hour Objects

**What goes wrong:** Developer calls `HourlyForecast.fromJson(hourly[i])` expecting per-hour maps, but the API returns `{"time": [...], "temperature_2m": [...]}` — parallel arrays.
**Why it happens:** The `HourlyForecast.fromJson` Freezed method is designed for a flat `{fieldName: value}` map, not the API's column-oriented format.
**How to avoid:** In `OpenMeteoClient._parseResponse()`, zip arrays by index (see Pattern 2 above).
**Warning signs:** Compile error `type 'int' is not a subtype of type 'Map<String, dynamic>'` when trying to parse `hourly['time'][0]`.

### Pitfall 2: Nullable Fields Coerced to 0.0

**What goes wrong:** `(val as num).toDouble()` when `val` is `null` throws; or developer writes `(val ?? 0.0)` and silently hides missing data, violating FORE-05.
**Why it happens:** Dart's non-nullable default and the temptation to use a default value.
**How to avoid:** Use the helper pattern `double? _get(String key)` that returns `null` when the list or value is null (see Pattern 2). The domain model `HourlyForecast` already declares all fields as `double?`.
**Warning signs:** A unit test that passes in a JSON with a missing field and asserts `forecast.windspeedKmh == null` fails.

### Pitfall 3: Forgetting `part` Directive and Code-Gen

**What goes wrong:** Drift table/database files compile fine without the generated file until `build_runner` runs. If `part 'app_database.g.dart'` is missing, the generated file is never linked.
**Why it happens:** Easy to forget when creating a new Dart file.
**How to avoid:** Every Drift file must start with `part 'filename.g.dart';`. Run `dart run build_runner build --delete-conflicting-outputs` after any schema change.
**Warning signs:** `Error: Method not found: '_$AppDatabase'` at runtime.

### Pitfall 4: Using `drift_flutter` `driftDatabase()` in Tests

**What goes wrong:** Tests that use `driftDatabase()` (the production executor) fail on non-mobile platforms because `sqlite3_flutter_libs` isn't available on macOS/Linux `dart test` targets.
**Why it happens:** `driftDatabase()` is a Flutter-specific executor.
**How to avoid:** Make `AppDatabase(QueryExecutor? executor)` accept an optional executor. In tests, always pass `NativeDatabase.memory()` (from `package:drift/native.dart`).
**Warning signs:** `MissingPluginException` or `sqlite3 not found` when running `dart test`.

### Pitfall 5: `drift_flutter` Version Mismatch

**What goes wrong:** Pubspec specifying `drift_flutter: ^0.3.1-wip` (from some docs) resolves to nothing or a pre-release, causing pub resolution failure.
**Why it happens:** Drift getting-started docs sometimes reference unreleased versions.
**How to avoid:** Use `drift_flutter: ^0.3.0` — verified as the current stable on pub.dev (2026-06-02).
**Warning signs:** `dart pub get` fails with `No versions of drift_flutter match constraint ^0.3.1-wip`.

### Pitfall 6: Background Isolate (WorkManager — Phase 8 note)

**What goes wrong:** In Phase 8, `WorkManager` runs the background callback in a separate isolate. The `AppDatabase` instance from the main isolate is NOT available there.
**Why it happens:** Dart isolates do not share memory.
**How to avoid:** (Phase 8 concern, document now.) The WorkManager callback must call `AppDatabase()` (with `driftDatabase()`) fresh inside the callback. Keep this in mind when designing the database constructor — it must be constructable without Flutter bindings if `WidgetsFlutterBinding.ensureInitialized()` is called first.
**Warning signs:** `StateError: AppDatabase not initialised` or null pointer inside the background callback.

---

## Code Examples

### Open-Meteo Live API Response (Amsterdam, verified 2026-06-02)

```
GET https://api.open-meteo.com/v1/forecast
  ?latitude=52.3676&longitude=4.9041
  &hourly=windspeed_10m,winddirection_10m,temperature_2m,apparent_temperature,precipitation,precipitation_probability
  &timezone=auto&timeformat=unixtime
  &forecast_days=1

Response structure:
{
  "latitude": 52.366,
  "longitude": 4.901,
  "timezone": "Europe/Amsterdam",
  "utc_offset_seconds": 7200,
  "hourly_units": {"time": "unixtime", "windspeed_10m": "km/h", ...},
  "hourly": {
    "time": [1780351200, 1780354800, ...],       // 24 values
    "windspeed_10m": [10.1, 7.2, ...],
    "winddirection_10m": [218, 166, ...],
    "temperature_2m": [...],
    "apparent_temperature": [...],
    "precipitation": [...],
    "precipitation_probability": [...]
  }
}
```

Note: `windspeed_10m` and `wind_speed_10m` both work — confirmed by live API call returning identical data for both spellings. Use `windspeed_10m` to match the existing `HourlyForecast` model's `@JsonKey` annotations.

### Amsterdam Hardcoded Coordinates

```dart
// lib/data/repositories/weather_repository.dart
static const double _amsterdamLat = 52.3676;
static const double _amsterdamLon = 4.9041;
// TODO Phase 7: replace with LocationService.currentLatLon()
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `sqflite` rawQuery strings | Drift type-safe ORM | Drift became Flutter Favorite ~2022 | Compile-time schema validation, no SQL string bugs |
| `Isar` for Flutter local DB | Drift | Isar 3.x unmaintained (3yr gap); Drift actively maintained | Drift is now the clear recommendation for new Flutter projects |
| `http.get()` static call | `http.Client` instance injection | Best practice established ~2020 | Enables mocking in unit tests |
| Hand-rolled cache with `SharedPreferences` | Drift table with `fetched_at` column | N/A | Structured queries, transactional writes, survives background kill |

**Deprecated/outdated:**
- `sqflite` + raw SQL for new Flutter projects: Drift is preferred (type safety, migrations, streams)
- `Isar 3.x`: Last stable release 3 years ago — do not use
- Static `http.get()` for testable code: Always use `http.Client` instance

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `dart test` | All unit tests | ✓ | Dart 3.6.0 (from Phase 1) | — |
| `build_runner` | Drift code-gen, mockito gen | ✓ | ^2.4.0 (in pubspec) | — |
| Open-Meteo API | Live fetch (not needed for tests) | ✓ | Free, no auth | Tests use mock |
| `dart run build_runner` | After any schema change | ✓ | Same as build_runner | — |

**Missing dependencies with no fallback:** none

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `windspeed_10m` and `wind_speed_10m` are both accepted by Open-Meteo API | Code Examples | If API drops `windspeed_10m`, client returns empty data for wind fields — LOW risk given confirmed by live API call |
| A2 | Amsterdam coordinates: lat=52.3676, lon=4.9041 | Code Examples | Minor — off by a few km; irrelevant for dev hardcode |
| A3 | `drift_flutter 0.3.0` works with `drift 2.33.0` | Standard Stack | `drift_flutter` depends on `drift: ^2.30.0` so ^2.33.0 resolves cleanly — LOW risk |

---

## Open Questions

1. **DAO structure: single DAO vs multiple DAOs**
   - What we know: Drift supports `@DriftAccessor` for splitting query methods into DAOs
   - What's unclear: Whether a single `ForecastDao` is the right boundary or if it should be split
   - Recommendation: Single `ForecastDao` for Phase 2 (only two tables, cohesive concern). Split later if Phase 6 availability grid adds more tables.

2. **Availability grid table (PERS-02 scope)**
   - What we know: PERS-02 says "availability grid AND forecast cache persist in Drift"
   - What's unclear: Phase 2 success criteria only mention forecast cache. Does Phase 2 need to define the availability table schema too, or is that Phase 6?
   - Recommendation: Scaffold the availability table (empty, no rows written) in Phase 2 to establish the v1 schema completely before any data is written — this satisfies PERS-03's "schema is versioned" requirement. Phase 6 writes the actual availability data.

---

## Sources

### Primary (HIGH confidence)

- `https://drift.simonbinder.eu/docs/getting-started/` — Drift Flutter setup, QueryExecutor constructor pattern [CITED: drift.simonbinder.eu]
- `https://drift.simonbinder.eu/dart_api/tables/` — Column types, nullable(), RealColumn, primary key [CITED: drift.simonbinder.eu]
- `https://drift.simonbinder.eu/docs/migrations/` — MigrationStrategy, schemaVersion, append-only convention [CITED: drift.simonbinder.eu]
- `https://drift.simonbinder.eu/testing/` — NativeDatabase.memory(), in-memory test pattern [CITED: drift.simonbinder.eu]
- `https://open-meteo.com/en/docs` — API parameters, hourly field names, response structure [CITED: open-meteo.com]
- Live API call to `api.open-meteo.com` — confirmed both `windspeed_10m` and `wind_speed_10m` spellings are accepted [VERIFIED: live API]
- `https://pub.dev/api/packages/drift`, `drift_flutter`, `drift_dev`, `mockito` — current versions [VERIFIED: pub.dev]
- `https://docs.flutter.dev/cookbook/testing/unit/mocking` — Mockito `@GenerateMocks` pattern for `http.Client` [CITED: flutter.dev]

### Secondary (MEDIUM confidence)

- `https://drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/` — advanced table patterns (column type reference) [CITED: drift.simonbinder.eu]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions verified on pub.dev, all packages in CLAUDE.md
- Architecture: HIGH — patterns verified against official Drift and Flutter docs
- Pitfalls: HIGH — most pitfalls verified by direct testing or official docs; Pitfall 6 (WorkManager isolate) is MEDIUM (anticipated, not encountered yet)
- Open-Meteo API: HIGH — confirmed by live API call

**Research date:** 2026-06-02
**Valid until:** 2026-07-02 (drift and open-meteo are stable; mockito/http are dart.dev maintained)
