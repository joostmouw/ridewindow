# Phase 1: Project skeleton + scoring domain — Research

**Researched:** 2026-06-02
**Domain:** Flutter project bootstrap + pure-Dart numeric domain modelling
**Confidence:** HIGH for stack/Freezed/coverage tooling (verified via pub.dev + dart.dev). HIGH for algorithms (locked in CONTEXT.md, just need clean Dart shape). MEDIUM for `dart test` coverage on a Flutter package (one known SDK ticket — see Open Questions).

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

All decisions D-01 through D-26 from `01-CONTEXT.md` are LOCKED. The planner MUST treat them as immovable. Highlights the implementation will encode verbatim:

- **D-02, D-06, D-09 — Plateau ranges:** temp `[12, 26]` °C → 100, rain `[0, 0.5]` mm/h → 100, wind `[0, 15]` km/h → 100.
- **D-03/D-04 — Asymmetric temp shoulders:** cold linear `100 @ 12°C → 0 @ -5°C` (17°C span); hot linear `100 @ 26°C → 0 @ 38°C` (12°C span).
- **D-05 — Reference temp scores (test fixtures):** −5 → 0; 0 → ~29; 5 → ~41; 8 → ~76; 12–26 → 100; 30 → ~67; 35 → ~25; 38 → 0.
- **D-07 — Reference rain scores:** 0 → 100; 0.5 → 100; 1 → ~89; 2 → ~67; 3 → ~44; 5+ → 0.
- **D-10 — Reference wind scores:** 15 → 100; 20 → ~83; 25 → ~67; 30 → ~50; 35 → ~33; 45+ → 0.
- **D-13 — Tolerances:** `WeatherTolerances { coldEdge: -5.0, hotEdge: 38.0, rainEdge: 5.0, windEdge: 45.0 }`. These are the unrideable edges; plateau is fixed.
- **D-14 — Aggregation:** `overall = 0.6 · min(temp, rain, wind) + 0.4 · mean(temp, rain, wind)`.
- **D-16 — Aggregation reference values:** 100/100/100→100; 100/100/85→89; 100/100/50→63; 100/100/30→49; 70/40/90→51; 65/65/65→65.
- **D-17 — Slot qualifier:** `overall ≥ 50` keeps run; 49 breaks it; 51 continues.
- **D-18, D-21 — Slot emission:** within a contiguous good run, emit ALL valid sub-slots of length 2, 3, 4, 5 (capped at 5h for v1).
- **D-19 — Boundary convention:** `[start, end)` exclusive end, documented on `RideSlot.end`.
- **D-20 — Slot scoring & tiers:** slot.overall = arithmetic mean of hourly overall scores; tier thresholds Perfect ≥85, Great 70–84, Acceptable 50–69, Poor <50 (hidden).
- **D-22/D-23 — Temp input cascade:** apparent_temperature → temperature_2m → clamp 50/100.
- **D-25/D-26 — Null sub-score policy:** any null primary input clamps that sub-score to 50; aggregation formula has NO special case for null — feeds 50 into min/mean like any normal value.
- **CLAUDE.md locked stack:** Flutter 3.x, Dart 3.x, Freezed for all domain models, `sealed class RideTier` with Perfect/Great/Acceptable/Poor.

### Claude's Discretion (settled in CONTEXT.md, planner should follow)

- **Skeleton scope:** scaffold full `lib/{core,domain,data,features,platform}/` tree; only `lib/domain/` gets real code; `main.dart` boots empty `MaterialApp`; CI deferred to a later phase.
- **Test fixtures:** inline literal fixtures per edge case + ONE shared `test/fixtures/amsterdam_typical_day.dart` (hand-crafted 24h dataset). No JSON-from-disk in Phase 1 — keeps domain tests pure.
- **Models in Phase 1:** Freezed even though only value objects — avoids Phase 2 refactor.
- **Tier shape:** Dart 3 `sealed class RideTier` (Perfect / Great / Acceptable / Poor), NOT a Freezed union (see "Sub-Score Implementations → Tier as sealed class" below).

### Deferred Ideas (OUT OF SCOPE for Phase 1)

- `precipitation_probability` weighting in rain sub-score — Phase 2/3.
- `winddirection_10m` / headwind — out of v1 entirely.
- CI / GitHub Actions — Phase 10 release prep.
- Tolerance slider UI range — Phase 6.
- Sun / UV / cloud cover — out of v1.
- Property-based testing (`glados`) — example-based tests sufficient for Phase 1.
- Weather fetching, persistence, Riverpod providers, real UI — Phases 2+.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCOR-01 | `ScoringEngine.score()` returns 0–100 overall + three sub-scores per hour | "Sub-Score Implementations" + "Aggregation & Slot Algorithms" sections define exact Dart shape; D-01..D-16 lock the math |
| SCOR-02 | Scoring uses user-adjustable tolerances (defaults per PROJECT.md) | `WeatherTolerances` Freezed model in "Domain Models" carries the four shoulder edges; D-13 locks defaults |
| SCOR-03 | Pure Dart, zero Flutter / zero I/O — testable via `dart test` | "Bootstrap → Pure-Dart Isolation" defines pubspec layout + lint enforcement; "Test Strategy" confirms `dart test` works on Flutter packages |
| SCOR-04 | Null inputs clamp affected sub-score to 50/100 ("uncertain"), no crash, no 0-coercion | "Sub-Score Implementations" specifies guard pattern; "Test Strategy" lists mandatory null-fixture tests; cites PITFALLS.md Pitfall 4 |
| SCOR-05 | Documented unit tests: ideal, cold edge, hot edge, light/heavy rain, calm/strong wind, mixed nulls | "Test Strategy → Phase Requirements → Test Map" enumerates every fixture |
| SLOT-01 | `SlotGenerator` produces 2h/3h/4–5h slots from contiguous good runs | "Aggregation & Slot Algorithms → Slot generation" gives sliding-window pseudocode + edge cases |
| SLOT-02 | Slots use exclusive end `[start, end)`; documented + property-tested | "Aggregation & Slot Algorithms → Boundary convention"; cites PITFALLS.md Pitfall 5 |
| SLOT-03 | `AvailabilityFilter` removes slots overlapping blocked hours | "Aggregation & Slot Algorithms → Availability filter" gives `Set<DateTime>` intersection approach |
| SLOT-04 | Slots categorized Perfect ≥85 / Great 70–84 / Acceptable 50–69 / Poor <50 (hidden) | "Sub-Score Implementations → Tier as sealed class" + slot-emission code keeps Poor out of output list |
</phase_requirements>

## Summary

1. **Bootstrap is trivial but has one Android-only gotcha:** `flutter create rideapp --platforms=android --org=com.fanalists.ridewindow` scaffolds the project, but `--platforms=android` only suppresses the `ios/`, `web/`, `linux/`, `macos/`, `windows/` directories — it does not strip them if they already exist. On a fresh `flutter create` it does the right thing.
2. **Pure-Dart isolation is achievable inside a Flutter package** — no need to split into a sub-package. `dart test` works on a Flutter package as long as the tested files do not transitively import `package:flutter`. The cheapest enforcement for Phase 1 is a single grep-based test (`test/structure/no_flutter_imports_test.dart`) that scans every file under `lib/domain/` and asserts none import `package:flutter`, `dart:io`, `dart:ui`, `package:http`, `package:drift`, or `package:shared_preferences`. Adding `custom_lint` or `import_lint` is over-engineering for one rule.
3. **Coverage is a known sharp edge:** `flutter test --coverage` emits lcov directly; `dart test --coverage=coverage` emits **JSON** that must be post-processed by `dart pub global run coverage:format_coverage --lcov` to produce lcov.info (dart-lang/sdk#60958 tracks unifying this). Phase 1 plan must include the format_coverage step in the test script, plus an `lcov --remove` to strip `*.freezed.dart` and `*.g.dart` before computing 100%.
4. **Freezed 3.x is the right tool for value objects AND for the RideTier sum type** — but CONTEXT.md D-locked `sealed class RideTier` (a hand-written Dart 3 sealed class), not a Freezed union. Use Freezed only for the data records (`HourlyForecast`, `HourlyScore`, `RideSlot`, `UserProfile`, `WeatherTolerances`). Do not generate a Freezed union for RideTier. (Freezed unions and sealed classes are interoperable; the locked decision is the simpler hand-written form.)
5. **Sub-score algorithms are 8-line piecewise functions** with one shared `_linearShoulder(x, ideal, zero)` helper. Place the helper in `lib/domain/services/_score_math.dart` (file-private with `_` prefix on functions — Dart's library privacy model means it's only visible inside that file, which is what we want). All three sub-score files import nothing but `dart:math` and the tolerances model.

**Primary recommendation:** Plan five waves of tasks: (W0) bootstrap + pubspec + analysis_options + the no-flutter-imports test infrastructure; (W1) all five Freezed models + generated code committed; (W2) three sub-score functions with their unit tests passing; (W3) aggregation + SlotGenerator + AvailabilityFilter with edge-case tests; (W4) coverage tooling wired (`dart test --coverage` → format_coverage → lcov filter → 100% gate) + the Amsterdam fixture integration test + minimal `main.dart` with empty `MaterialApp`. Phase exit: `dart test` is green, `lcov` reports 100% line coverage of `lib/domain/`, `flutter run` boots an empty Material app, and the no-flutter-imports test passes.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Numeric sub-score functions (temp/rain/wind) | Domain | — | Pure math; no I/O, no UI; per PITFALLS.md anti-pattern #1, never put scoring in UI |
| Aggregation formula (overall hourly score) | Domain | — | Pure function of three sub-scores; isolated for test coverage |
| Slot enumeration over contiguous good runs | Domain | — | Pure transformation `List<HourlyScore> → List<RideSlot>`; future Riverpod provider wraps it |
| Availability filter (slot ∩ blocked hours) | Domain | — | Pure set intersection over `DateTime` |
| Tier classification (Perfect/Great/Acceptable/Poor) | Domain | — | Pure threshold check on overall score; sealed class makes pattern matching exhaustive |
| `MaterialApp` boot (so `flutter run` succeeds) | Presentation (minimal) | — | Required for "phase exit" gate; trivially empty in Phase 1; expanded in Phase 4 |
| `lib/{core, data, features, platform}/` scaffolding | (placeholder dirs) | — | Empty stubs; reserved for Phases 2–10; no logic in Phase 1 |
| Freezed code generation | Build-time tooling | — | Runs once via `dart run build_runner build`; output committed to git so consumers don't need to regenerate |
| Test execution (`dart test`) | Test runner | — | Pure-Dart test runner; works on Flutter packages provided tested files have no Flutter imports |
| Coverage measurement & enforcement | Test runner | — | `coverage` package emits lcov via `format_coverage` post-step |

## Bootstrap

### `flutter create` incantation

```bash
flutter create \
  --platforms=android \
  --org=com.fanalists.ridewindow \
  --description="RideWindow — cyclist-specific weather windows" \
  --project-name=ridewindow \
  .
```

Notes:
- `--platforms=android` ensures **only** `android/` is scaffolded — no `ios/`, `web/`, `linux/`, `macos/`, `windows/`. `[VERIFIED: docs.flutter.dev + GitHub flutter/flutter#62594]`.
- Use `=` not space (`--platforms=android`, not `--platforms android`) — both work in current Flutter but `=` is the documented form. `[CITED: docs.flutter.dev flutter-cli reference]`.
- `--org` becomes the Android `applicationId` prefix (`com.fanalists.ridewindow`). Locking this NOW prevents a costly rename later — the Play Store binds the `applicationId` to the app listing.
- The trailing `.` creates in the current directory. The project root `/Users/joostmouw/ridewindow/` already exists and contains `CLAUDE.md` + `mockup.html` + `.planning/` + `.git`. Verify `flutter create .` does not clobber these (it will not — it only adds the missing scaffolding). If `flutter create` refuses to run because the directory is non-empty, use a temp dir and copy the generated `android/`, `lib/`, `test/`, `pubspec.yaml`, `analysis_options.yaml`, `.gitignore` files into place.
- Project name `ridewindow` must be a valid Dart package name: all lowercase, snake_case allowed, no leading digits.

### Folders to leave alone (scaffold defaults)

`flutter create --platforms=android` produces:
- `android/` — keep, will be customized in Phase 10
- `lib/main.dart` — REPLACE in W4 with minimal empty `MaterialApp` boot
- `test/widget_test.dart` — DELETE (it tests the counter app)
- `pubspec.yaml` — heavily modified
- `analysis_options.yaml` — replaced/extended
- `.gitignore` — extended (add `coverage/` and `*.freezed.dart`/`*.g.dart`? NO — commit generated files per Freezed best practice so consumers and CI don't need build_runner just to read code)
- `.metadata`, `pubspec.lock`, `README.md` — keep as-is

### `pubspec.yaml` (Phase 1)

```yaml
name: ridewindow
description: "RideWindow — cyclist-specific weather windows"
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ">=3.6.0 <4.0.0"   # Dart 3 + sealed-class pattern-matching guaranteed
  flutter: ">=3.27.0"     # Material 3 default; matches CLAUDE.md "3.x stable"

dependencies:
  flutter:
    sdk: flutter
  freezed_annotation: ^3.1.0   # runtime annotation only — pure Dart, no Flutter dep
  json_annotation: ^4.9.0      # used by Freezed when toJson() needed (no-op in Phase 1, ready for Phase 2)

dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.25.0                # plain dart test runner — needed for `dart test`
  freezed: ^3.2.5              # build-time only
  json_serializable: ^6.8.0    # build-time only
  build_runner: ^2.4.0         # runs freezed
  coverage: ^1.10.0            # provides format_coverage CLI for lcov conversion

flutter:
  uses-material-design: true
```

Why Phase 1 already has `flutter:` block: `flutter create` requires it for the project to be a valid Flutter package. The fact that `lib/domain/` files don't import `package:flutter` is enforced by **test**, not by package configuration. A Flutter package can contain pure-Dart libraries; the test runner discriminates by what each file actually imports.

### `analysis_options.yaml` (Phase 1)

```yaml
include: package:flutter_lints/flutter_lints.yaml

analyzer:
  errors:
    # treat missing return type as error in domain code
    always_declare_return_types: error
  exclude:
    - "**/*.freezed.dart"   # generated — don't lint
    - "**/*.g.dart"

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: true
    require_trailing_commas: true
```

Add `flutter_lints` to `dev_dependencies`:
```yaml
flutter_lints: ^5.0.0
```

NOTE: do NOT add `custom_lint` / `import_lint` / `import_rules` in Phase 1. They are excellent tools `[CITED: pub.dev/packages/import_lint, pub.dev/packages/import_rules]` but require Dart SDK ≥ 3.10 and a `dart run custom_lint` separate analyzer plugin step. For one rule ("no `package:flutter` under `lib/domain/`"), a 30-line grep-based test (see "Test Strategy → Structural tests") is dramatically simpler and runs as part of `dart test` automatically.

### Bootstrap commands (in order)

```bash
# 1. Scaffold
flutter create --platforms=android --org=com.fanalists.ridewindow --project-name=ridewindow .

# 2. Replace pubspec.yaml and analysis_options.yaml with the versions above
# 3. Delete test/widget_test.dart
rm test/widget_test.dart

# 4. Fetch dependencies
flutter pub get

# 5. Scaffold lib/ tree (empty subdirs except domain/)
mkdir -p lib/core lib/data lib/features lib/platform
mkdir -p lib/domain/models lib/domain/services
touch lib/core/.gitkeep lib/data/.gitkeep lib/features/.gitkeep lib/platform/.gitkeep

# 6. Replace lib/main.dart with empty MaterialApp boot (see "Minimal main.dart" below)

# 7. Run build_runner once domain models are written (W1)
dart run build_runner build --delete-conflicting-outputs

# 8. Run tests
dart test                   # for lib/domain/ tests (pure Dart, no Flutter loader)
flutter test                # for any widget tests (none in Phase 1)
```

### Minimal `lib/main.dart`

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const RideWindowApp());
}

class RideWindowApp extends StatelessWidget {
  const RideWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideWindow',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2E7D32)),
      home: const Scaffold(
        body: Center(child: Text('RideWindow — domain ready')),
      ),
    );
  }
}
```

Notes:
- `useMaterial3: true` is omitted because Material 3 is default since Flutter 3.16 `[CITED: docs.flutter.dev/release/breaking-changes/material-3-migration]`.
- Cycling-green seed `0xFF2E7D32` matches the mockup color (STACK.md mentioned this).
- This file IS allowed to import `package:flutter` — it's in `lib/`, NOT in `lib/domain/`. The no-flutter-imports test ONLY scans `lib/domain/`.

### Pure-Dart isolation

The architectural rule: **no file under `lib/domain/` may import `package:flutter/*`, `dart:io`, `dart:ui`, `package:http`, `package:drift`, `package:shared_preferences`, `package:hive`, or `package:path_provider`.**

Enforcement: a single structural test (see "Test Strategy → Structural tests"). No custom analyzer plugin needed.

## Domain Models

All models live in `lib/domain/models/` and follow the same Freezed 3.x pattern. Generated files (`*.freezed.dart`, `*.g.dart`) are committed to git.

### File-by-file inventory

| File | Type | Purpose | JSON? |
|------|------|---------|-------|
| `lib/domain/models/hourly_forecast.dart` | Freezed value object | Single hour of weather input (`time`, `apparentTemperature?`, `temperature2m?`, `precipitation?`, `precipitationProbability?`, `windspeed10m?`, `winddirection10m?`) | YES (Phase 2 will deserialize from Open-Meteo) |
| `lib/domain/models/hourly_score.dart` | Freezed value object | Single hour of output (`time`, `overall`, `tempSubScore`, `rainSubScore`, `windSubScore`) | NO (computed, not persisted) |
| `lib/domain/models/ride_slot.dart` | Freezed value object | A scored time window (`start`, `end` exclusive, `durationHours`, `overall`, `tier: RideTier`) | NO (derived, never cached per ARCHITECTURE.md anti-pattern #4) |
| `lib/domain/models/user_profile.dart` | Freezed value object | (`tolerances: WeatherTolerances`, `blockedHours: Set<DateTime>`, `rideLengthPrefs: Set<int>`) | NO in Phase 1 (Phase 2 persists via Drift, not JSON) |
| `lib/domain/models/weather_tolerances.dart` | Freezed value object | (`coldEdge: double`, `hotEdge: double`, `rainEdge: double`, `windEdge: double`) with defaults `(-5.0, 38.0, 5.0, 45.0)` | NO in Phase 1 |
| `lib/domain/models/ride_tier.dart` | Hand-written sealed class | `Perfect` / `Great` / `Acceptable` / `Poor` cases; constructor `RideTier.fromScore(double)` returns appropriate case | NO |

### Canonical Freezed pattern (one file)

```dart
// lib/domain/models/hourly_forecast.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hourly_forecast.freezed.dart';
part 'hourly_forecast.g.dart';

@freezed
abstract class HourlyForecast with _$HourlyForecast {
  const factory HourlyForecast({
    required DateTime time,
    double? apparentTemperature,
    double? temperature2m,
    double? precipitation,
    double? precipitationProbability,
    double? windspeed10m,
    double? winddirection10m,
  }) = _HourlyForecast;

  factory HourlyForecast.fromJson(Map<String, dynamic> json) =>
      _$HourlyForecastFromJson(json);
}
```

`[VERIFIED: pub.dev/packages/freezed]` — `abstract class` form is the Freezed 3.x recommended shape; `with _$HourlyForecast` mixes in the generated implementation; `part` directives import generated code; `fromJson` factory is opt-in (omit for models that are never JSON).

### Sealed class for RideTier

```dart
// lib/domain/models/ride_tier.dart
sealed class RideTier {
  const RideTier();

  /// D-20 thresholds. Tier from slot overall score.
  static RideTier fromScore(double overall) {
    if (overall >= 85) return const Perfect();
    if (overall >= 70) return const Great();
    if (overall >= 50) return const Acceptable();
    return const Poor();
  }
}

final class Perfect    extends RideTier { const Perfect(); }
final class Great      extends RideTier { const Great(); }
final class Acceptable extends RideTier { const Acceptable(); }
final class Poor       extends RideTier { const Poor(); }
```

`[VERIFIED: dart.dev]` — Dart 3 `sealed class` restricts subtyping to the current library, enabling exhaustive pattern matching:

```dart
String tierLabel(RideTier t) => switch (t) {
  Perfect()    => 'Perfect',
  Great()      => 'Great',
  Acceptable() => 'Acceptable',
  Poor()       => 'Poor',
};
```

If a future contributor adds a 5th subclass without updating the switch, the compiler errors. This is the value of sealed-over-enum that CLAUDE.md locked in.

### Generated artifacts to commit

After `dart run build_runner build --delete-conflicting-outputs`, the following appear and MUST be committed:

```
lib/domain/models/hourly_forecast.freezed.dart
lib/domain/models/hourly_forecast.g.dart
lib/domain/models/hourly_score.freezed.dart
lib/domain/models/ride_slot.freezed.dart
lib/domain/models/user_profile.freezed.dart
lib/domain/models/weather_tolerances.freezed.dart
```

(No `.g.dart` for hourly_score, ride_slot, user_profile, weather_tolerances — they have no `fromJson`.)

Committing generated files keeps `dart test` and `flutter test` runnable on a fresh clone without a build_runner step. The CI cost (later, Phase 10) for not committing is "always run build_runner first" — for now, keep it simple.

## Sub-Score Implementations

### Helper: linear shoulder

```dart
// lib/domain/services/_score_math.dart
// File-private helper — only files in the same library (this file) can call it.
// Library privacy in Dart: any identifier starting with `_` is library-private.
// Since this file declares no `library;` directive, the library boundary is the file itself.

/// Linear interpolation from `100 @ idealEdge` to `0 @ zeroEdge`.
/// Caller passes the appropriate edges for the side being evaluated.
/// Pre: `idealEdge != zeroEdge`. Returns clamped [0, 100].
double linearShoulder(double x, double idealEdge, double zeroEdge) {
  final span = zeroEdge - idealEdge;          // signed span
  final progress = (x - idealEdge) / span;    // 0 at ideal, 1 at zero
  final score = 100.0 * (1.0 - progress);
  return score.clamp(0.0, 100.0);
}
```

**Why this signature works for both directions:**
- Cold shoulder: `linearShoulder(temp, 12.0, -5.0)` — `span = -17`, `temp = 5` → `progress = (5-12)/-17 ≈ 0.41` → `score ≈ 59`.
- Hot shoulder: `linearShoulder(temp, 26.0, 38.0)` — `span = 12`, `temp = 30` → `progress = (30-26)/12 ≈ 0.33` → `score ≈ 67`.
- Rain/wind one-sided: `linearShoulder(rain, 0.5, 5.0)` — `span = 4.5`, `rain = 2` → `progress = 1.5/4.5 = 0.33` → `score ≈ 67`. Matches D-07.

Verify D-05 / D-07 / D-10 reference scores with explicit `expect(linearShoulder(...), closeTo(expected, 1.0))` tests.

**Placement decision:** `_score_math.dart` (file-prefixed underscore is a strong convention signalling "internal to this directory"); the helper itself is NOT prefixed because we want sub-score files in the same directory to import and use it. Three Dart privacy strategies considered:

| Option | Visibility | Verdict |
|--------|------------|---------|
| Top-level `_linearShoulder` in `scoring_engine.dart` | File-private — only same file | TOO RESTRICTIVE: temp/rain/wind sub-scores want to be in separate files for testability |
| Top-level `linearShoulder` in `score_math.dart` (no underscore) | Library-public, package-exported | TOO OPEN: external packages could call it |
| Top-level `linearShoulder` in `_score_math.dart` (file prefix only) | Library-public BUT file name prefix signals "internal" | CHOSEN: convention-based + the no-flutter-imports test can ALSO grep that no file outside `lib/domain/services/` imports `_score_math.dart` |

Alternative if stronger enforcement is wanted later: make `_score_math.dart` a `part` file of `scoring_engine.dart` with a `library` directive — but that adds Dart library ceremony for marginal gain in Phase 1.

### Three sub-score files

```dart
// lib/domain/services/temp_score.dart
import 'dart:math' as math;
import '../models/weather_tolerances.dart';
import '_score_math.dart';

/// D-22, D-23, D-25: apparent_temperature primary, temperature_2m fallback, 50/100 if both null.
/// D-01..D-05: plateau [12, 26], cold shoulder to coldEdge, hot shoulder to hotEdge.
double scoreTemp(
  double? apparentTemperature,
  double? temperature2m,
  WeatherTolerances t,
) {
  final temp = apparentTemperature ?? temperature2m;
  if (temp == null) return 50.0;              // D-23 final fallback
  if (temp >= 12.0 && temp <= 26.0) return 100.0;
  if (temp < 12.0) return linearShoulder(temp, 12.0, t.coldEdge);
  return linearShoulder(temp, 26.0, t.hotEdge);
}
```

```dart
// lib/domain/services/rain_score.dart
import '../models/weather_tolerances.dart';
import '_score_math.dart';

/// D-06..D-08: plateau [0, 0.5] mm/h, linear to 0 at rainEdge. One-sided.
double scoreRain(double? precipitation, WeatherTolerances t) {
  if (precipitation == null) return 50.0;     // D-25
  if (precipitation <= 0.5) return 100.0;
  return linearShoulder(precipitation, 0.5, t.rainEdge);
}
```

```dart
// lib/domain/services/wind_score.dart
import '../models/weather_tolerances.dart';
import '_score_math.dart';

/// D-09..D-11: plateau [0, 15] km/h, linear to 0 at windEdge. One-sided.
double scoreWind(double? windspeed10m, WeatherTolerances t) {
  if (windspeed10m == null) return 50.0;      // D-25
  if (windspeed10m <= 15.0) return 100.0;
  return linearShoulder(windspeed10m, 15.0, t.windEdge);
}
```

**Idiom choice:** if/else over `switch` expressions. Switch on guards (`switch (temp) { < 12.0 => ..., }`) reads worse for 3-branch decisions and Dart's switch expressions don't compose nicely with `clamp`. The if-else form is what every Dart math library in the ecosystem looks like.

**`dart:math` import:** Actually unused in the above — `clamp` is on `num`, not in `dart:math`. The helper file is the only one that does numerical work. Remove `import 'dart:math'` from sub-score files unless needed.

## Aggregation & Slot Algorithms

### `ScoringEngine.score(...)` — aggregation per hour

```dart
// lib/domain/services/scoring_engine.dart
import '../models/hourly_forecast.dart';
import '../models/hourly_score.dart';
import '../models/weather_tolerances.dart';
import 'temp_score.dart';
import 'rain_score.dart';
import 'wind_score.dart';

class ScoringEngine {
  const ScoringEngine();

  /// SCOR-01: one HourlyScore per HourlyForecast.
  List<HourlyScore> score(List<HourlyForecast> forecast, WeatherTolerances t) {
    return forecast.map((h) => _scoreHour(h, t)).toList(growable: false);
  }

  HourlyScore _scoreHour(HourlyForecast h, WeatherTolerances t) {
    final temp = scoreTemp(h.apparentTemperature, h.temperature2m, t);
    final rain = scoreRain(h.precipitation, t);
    final wind = scoreWind(h.windspeed10m, t);
    final overall = _aggregate(temp, rain, wind);
    return HourlyScore(
      time: h.time,
      overall: overall,
      tempSubScore: temp,
      rainSubScore: rain,
      windSubScore: wind,
    );
  }

  /// D-14: overall = 0.6 · min(t,r,w) + 0.4 · mean(t,r,w).
  /// D-26: null-derived 50s are fed in exactly like any other value; no special case.
  static double _aggregate(double temp, double rain, double wind) {
    final lo = [temp, rain, wind].reduce((a, b) => a < b ? a : b);
    final mean = (temp + rain + wind) / 3.0;
    return 0.6 * lo + 0.4 * mean;
  }
}
```

**Why list-reduce instead of `math.min(math.min(a, b), c)`:** with exactly 3 doubles either works; list-reduce reads more cleanly and avoids an `import 'dart:math'` just for min. For 3 elements the allocation cost is irrelevant.

**Reference-value tests (must pass):**
- `_aggregate(100, 100, 100) ≈ 100` ✓
- `_aggregate(100, 100, 85) = 0.6·85 + 0.4·95.0 = 51 + 38 = 89` ✓ (D-16)
- `_aggregate(100, 100, 50) = 0.6·50 + 0.4·83.33 = 30 + 33.33 = 63.33` ✓ (D-16)
- `_aggregate(100, 100, 30) = 0.6·30 + 0.4·76.67 = 18 + 30.67 = 48.67` → rounds to 49, hidden (D-16)
- `_aggregate(70, 40, 90) = 0.6·40 + 0.4·66.67 = 24 + 26.67 = 50.67` → 51 (D-16: "→ 51"). Confirms.
- `_aggregate(65, 65, 65) = 0.6·65 + 0.4·65 = 65` ✓ (D-16)

### `SlotGenerator.generate(...)` — emit all valid sub-slots

```dart
// lib/domain/services/slot_generator.dart
import '../models/hourly_score.dart';
import '../models/ride_slot.dart';
import '../models/ride_tier.dart';

class SlotGenerator {
  const SlotGenerator();

  static const _validLengths = [2, 3, 4, 5];
  static const _qualifyingThreshold = 50.0; // D-17

  /// D-18, D-21: within each contiguous run of qualifying hours, emit ALL
  /// sub-slots of length 2..5 (capped at run-length). Phase 1 is unopinionated;
  /// AvailabilityFilter + user prefs prune later.
  List<RideSlot> generate(List<HourlyScore> scores) {
    final out = <RideSlot>[];
    for (final run in _contiguousRuns(scores)) {
      for (final len in _validLengths) {
        if (run.length < len) continue;
        for (var start = 0; start + len <= run.length; start++) {
          final window = run.sublist(start, start + len);
          out.add(_buildSlot(window, len));
        }
      }
    }
    return out;
  }

  Iterable<List<HourlyScore>> _contiguousRuns(List<HourlyScore> scores) sync* {
    var current = <HourlyScore>[];
    for (final s in scores) {
      if (s.overall >= _qualifyingThreshold) {
        current.add(s);
      } else if (current.isNotEmpty) {
        yield current;
        current = <HourlyScore>[];
      }
    }
    if (current.isNotEmpty) yield current;
  }

  RideSlot _buildSlot(List<HourlyScore> window, int len) {
    final overall = window.map((h) => h.overall).reduce((a, b) => a + b) / len;
    final tier = RideTier.fromScore(overall);
    final start = window.first.time;
    // D-19: exclusive end. Each HourlyScore covers [time, time+1h).
    // Slot covers [first.time, last.time + 1h).
    final end = window.last.time.add(const Duration(hours: 1));
    return RideSlot(
      start: start,
      end: end,
      durationHours: len,
      overall: overall,
      tier: tier,
    );
  }
}
```

**Slot enumeration cardinality (sanity check):**

For a contiguous run of N qualifying hours:
- N=1 → 0 slots emitted (no length qualifies)
- N=2 → 1 slot (one 2h)
- N=3 → 2+1 = 3 slots (two 2h, one 3h)
- N=4 → 3+2+1 = 6 slots (three 2h, two 3h, one 4h)
- N=5 → 4+3+2+1 = 10 slots (four 2h, three 3h, two 4h, one 5h)
- N=6 → 5+4+3+2 = 14 slots (CONTEXT.md says "cap at 5h" — so do NOT emit a 6h slot; the implementation above naturally caps because `_validLengths = [2,3,4,5]`)

Each cardinality is a unit test fixture.

**Boundary convention test (PITFALLS.md Pitfall 5):**

Given hours `[10:00, 11:00, 12:00, 13:00]` all qualifying (a 4-element run), the 4h slot must have:
- `start == 10:00`
- `end == 14:00` (exclusive, equal to `13:00 + 1h`)
- `durationHours == 4`
- `end.difference(start) == Duration(hours: 4)`

Property test: for any N-element qualifying run, the emitted L-length slot at position P satisfies `end.difference(start) == Duration(hours: L)` AND `start == run[P].time` AND `end == run[P+L-1].time + 1h`.

### `AvailabilityFilter.filter(...)` — slot ∩ blocked hours

```dart
// lib/domain/services/availability_filter.dart
import '../models/ride_slot.dart';
import '../models/user_profile.dart';

class AvailabilityFilter {
  const AvailabilityFilter();

  /// SLOT-03: drop any slot whose [start, end) overlaps any blocked hour.
  /// blockedHours is a Set<DateTime> of hour-starts that the user marked unavailable.
  /// A slot starting at 10:00 with duration 3h is blocked if ANY of {10:00, 11:00, 12:00} is in the set.
  List<RideSlot> filter(List<RideSlot> slots, UserProfile profile) {
    return slots.where((slot) => !_overlapsBlocked(slot, profile.blockedHours)).toList(growable: false);
  }

  bool _overlapsBlocked(RideSlot slot, Set<DateTime> blockedHours) {
    var cursor = slot.start;
    while (cursor.isBefore(slot.end)) {        // D-19 exclusive end
      if (blockedHours.contains(cursor)) return true;
      cursor = cursor.add(const Duration(hours: 1));
    }
    return false;
  }
}
```

**Representation decision — `Set<DateTime>` of hour-starts:**

CONTEXT.md "Specifics" says "blocked-hours fixture." A `Set<DateTime>` keyed by the exact hour-start (timezone-aware, with minute/second/millisecond/microsecond zeroed) is the simplest and fastest representation. It also matches how Phase 6's AvailabilityScreen will think about a 7×24 grid (each cell ↔ one hour-start within a representative week). A `WeeklySchedule` value object would be needed if blocking applied to a recurring weekly pattern, but Phase 2's Drift schema stores actual `(day_index, hour)` rows which the data layer will lower into `Set<DateTime>` for a specific 7-day window before handing to AvailabilityFilter. Phase 1 only needs the filter to work; the data layer maps from grid → set in Phase 2/3.

**Edge cases to test:**
- Empty `blockedHours` → no slot removed.
- Blocked hour exactly at `slot.start` → slot removed.
- Blocked hour exactly at `slot.end` → slot NOT removed (D-19 exclusive end).
- Blocked hour in the middle of a 4h slot → slot removed.
- Two adjacent slots, one blocked, one not → only the blocked one removed.

## Test Strategy

### Categories

| Category | Location | Framework | Purpose |
|----------|----------|-----------|---------|
| Sub-score unit | `test/domain/services/temp_score_test.dart`, `rain_score_test.dart`, `wind_score_test.dart` | `package:test` | Boundary + null fixtures for each curve |
| Aggregation unit | `test/domain/services/scoring_engine_test.dart` | `package:test` | D-16 reference values + null-propagation |
| Slot algorithm unit | `test/domain/services/slot_generator_test.dart` | `package:test` | Run lengths 1..6, slot boundary convention, threshold sensitivity (49 vs 51) |
| Availability filter unit | `test/domain/services/availability_filter_test.dart` | `package:test` | Empty set, start blocked, end NOT blocked, middle blocked |
| Tier classification unit | `test/domain/models/ride_tier_test.dart` | `package:test` | All 4 tiers + threshold edges (84.99 → Great, 85.0 → Perfect) |
| Helper unit | `test/domain/services/score_math_test.dart` | `package:test` | `linearShoulder` symmetry, clamp behavior |
| Integration ("Amsterdam") | `test/integration/amsterdam_typical_day_test.dart` | `package:test` | 24h fixture → expected number of qualifying hours, expected slots emitted, expected best-slot tier |
| Structural | `test/structure/no_flutter_imports_test.dart` | `package:test` (uses `dart:io` File API in TEST code — that's allowed; the rule restricts `lib/domain/`, not tests) | Greps every file under `lib/domain/` for forbidden imports |

### Structural test (the import isolation enforcer)

```dart
// test/structure/no_flutter_imports_test.dart
import 'dart:io';
import 'package:test/test.dart';

const _forbidden = [
  'package:flutter/',
  'dart:io',
  'dart:ui',
  'package:http',
  'package:drift',
  'package:shared_preferences',
  'package:hive',
  'package:path_provider',
];

void main() {
  test('lib/domain/ has zero Flutter/IO imports (SCOR-03)', () async {
    final domainDir = Directory('lib/domain');
    expect(domainDir.existsSync(), isTrue, reason: 'lib/domain/ must exist');

    final violations = <String>[];
    await for (final entity in domainDir.list(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.freezed.dart')) continue; // generated, may import
      if (entity.path.endsWith('.g.dart')) continue;
      final content = await entity.readAsString();
      for (final forbidden in _forbidden) {
        // Naive but sufficient: line starting with `import '<forbidden>` or `import "<forbidden>`
        final pattern = RegExp("import\\s+['\"]${RegExp.escape(forbidden)}");
        if (pattern.hasMatch(content)) {
          violations.add('${entity.path}: imports $forbidden');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
```

This test fails fast if a future contributor accidentally `import 'package:flutter/material.dart'` inside `lib/domain/`. It runs every time `dart test` runs. No analyzer plugin overhead.

**Note on generated files:** `*.freezed.dart` and `*.g.dart` may import `package:freezed_annotation` and `package:json_annotation`, both of which are pure Dart and contain no Flutter dependency `[VERIFIED: pub.dev/packages/freezed_annotation]`. So they're skipped from the structural test for safety, but they're not actually a Flutter dep risk.

### Test framework choice: `package:test` not `flutter_test`

For `lib/domain/` tests: `import 'package:test/test.dart'` and run with `dart test`. This guarantees no Flutter loader is initialized — if any tested file transitively imports `package:flutter`, the test fails to compile (which is exactly the signal we want).

For `lib/main.dart` (the empty `MaterialApp`): no widget tests in Phase 1 — the only assertion is "`flutter run` boots without throwing," which is a manual smoke test for the phase exit gate, not an automated test.

### Coverage tooling — the path to lcov

```bash
# Step 1: run dart tests with coverage (produces JSON in coverage/test/)
dart test --coverage=coverage

# Step 2: format to lcov.info (requires `coverage` dev_dependency)
dart pub global activate coverage         # one-time, OR use `dart run coverage:format_coverage` if it's in dev_deps
dart run coverage:format_coverage \
  --packages=.dart_tool/package_config.json \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --report-on=lib/domain

# Step 3: strip generated files from lcov (requires lcov CLI: `brew install lcov` on macOS)
lcov --remove coverage/lcov.info \
  '*/lib/domain/models/*.freezed.dart' \
  '*/lib/domain/models/*.g.dart' \
  -o coverage/lcov.info

# Step 4: assert 100% line coverage of lib/domain/
# Use the `coverage` package's `--check-coverage` flag OR a small shell script:
# Parse `lcov --summary coverage/lcov.info` output, fail if line coverage < 100%.
```

`[VERIFIED: pub.dev/packages/coverage]` for steps 1+2. `[CITED: Medium "Flutter Test Coverage with lcov"]` for the lcov filter pattern. `[CITED: dart-lang/sdk#60958]` for the dart/flutter coverage format divergence — this is a known sharp edge and worth a comment in the test script.

**Why `--report-on=lib/domain`:** restricts coverage measurement to the directory we actually care about. `lib/main.dart` and the empty subdirs do not need coverage in Phase 1.

**Suggested test script (`tool/test_with_coverage.sh`):**

```bash
#!/usr/bin/env bash
set -euo pipefail

rm -rf coverage
dart test --coverage=coverage
dart run coverage:format_coverage \
  --packages=.dart_tool/package_config.json \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --report-on=lib/domain

if command -v lcov >/dev/null 2>&1; then
  lcov --remove coverage/lcov.info \
    '*/lib/domain/models/*.freezed.dart' \
    '*/lib/domain/models/*.g.dart' \
    -o coverage/lcov.info >/dev/null

  # Phase exit gate: 100% line coverage of lib/domain/
  summary=$(lcov --summary coverage/lcov.info 2>&1)
  echo "$summary"
  pct=$(echo "$summary" | grep -oE 'lines\.+: [0-9]+\.[0-9]+%' | grep -oE '[0-9]+\.[0-9]+' | head -1)
  if [ "$pct" != "100.0" ]; then
    echo "COVERAGE GATE FAILED: lib/domain/ at ${pct}% (need 100.0%)"
    exit 1
  fi
  echo "COVERAGE GATE PASSED: lib/domain/ at 100.0%"
else
  echo "WARNING: lcov CLI not installed — cannot filter generated files or assert threshold."
  echo "Install: brew install lcov"
fi
```

### Test fixtures

- **Inline literal fixtures** for boundary tests (e.g., `final cold = HourlyForecast(time: DateTime.utc(2026,6,2,8), apparentTemperature: -5.0, temperature2m: -5.0, precipitation: 0.0, windspeed10m: 5.0);`).
- **Shared 24h fixture:** `test/fixtures/amsterdam_typical_day.dart` — hand-crafted `List<HourlyForecast>` for a representative late-spring Amsterdam day (cool 8°C morning rising to mild 18°C afternoon, light breeze 10–18 km/h, dry). Expected behavior documented in fixture file. Used only by the integration test.
- **No real Open-Meteo JSON fixtures in Phase 1** — would require `dart:io` File loading, contaminating the pure-domain test boundary. Open-Meteo response fixtures arrive in Phase 2 along with the deserialization layer.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `package:test` ^1.25.0 (pure Dart, not `flutter_test`) for `lib/domain/`; `flutter_test` available but unused in Phase 1 |
| Config file | none in Phase 1 — defaults sufficient; can add `dart_test.yaml` later if test parallelism / tagging needed |
| Quick run command | `dart test --reporter compact -x slow` (no slow tests in Phase 1, so equivalent to `dart test`) |
| Full suite command | `bash tool/test_with_coverage.sh` (runs tests + asserts 100% line coverage of `lib/domain/`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCOR-01 | Returns 0–100 overall + 3 sub-scores per hour | unit | `dart test test/domain/services/scoring_engine_test.dart -x` | ❌ Wave 0 |
| SCOR-02 | Tolerances drive shoulder edges | unit | `dart test test/domain/services/scoring_engine_test.dart -n "tolerances widen cold shoulder"` | ❌ Wave 0 |
| SCOR-03 | Pure Dart, zero Flutter/IO | structural | `dart test test/structure/no_flutter_imports_test.dart` | ❌ Wave 0 |
| SCOR-04 | Null inputs clamp to 50/100, no crash | unit | `dart test test/domain/services/temp_score_test.dart -n "null"` + same for rain/wind | ❌ Wave 0 |
| SCOR-05 | Documented edge tests: ideal/cold/hot/rain/wind/null | unit | `dart test test/domain/services/` (all files) | ❌ Wave 0 |
| SLOT-01 | 2h/3h/4–5h slots from contiguous runs | unit | `dart test test/domain/services/slot_generator_test.dart` | ❌ Wave 0 |
| SLOT-02 | Exclusive end `[start, end)` documented + tested | unit | `dart test test/domain/services/slot_generator_test.dart -n "exclusive end"` | ❌ Wave 0 |
| SLOT-03 | AvailabilityFilter removes overlapping slots | unit | `dart test test/domain/services/availability_filter_test.dart` | ❌ Wave 0 |
| SLOT-04 | Tiers Perfect ≥85 / Great 70–84 / Acceptable 50–69 / Poor <50 hidden | unit | `dart test test/domain/models/ride_tier_test.dart` + `slot_generator_test.dart -n "poor hidden"` | ❌ Wave 0 |
| (cross-cutting) | 100% line coverage of `lib/domain/` | structural | `bash tool/test_with_coverage.sh` | ❌ Wave 0 |
| (cross-cutting) | Amsterdam fixture end-to-end (smoke) | integration | `dart test test/integration/amsterdam_typical_day_test.dart` | ❌ Wave 0 |
| (cross-cutting) | `flutter run` boots empty MaterialApp | manual smoke | `flutter run` then visually confirm app loads with "RideWindow — domain ready" text | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `dart test` (fast, ~1s, all unit tests)
- **Per wave merge:** `bash tool/test_with_coverage.sh` (full suite + coverage gate, ~5s)
- **Phase gate:** Full suite green + coverage 100% of `lib/domain/` + `flutter run` smoke + the no-flutter-imports test green — before `/gsd-verify-work`

### Wave 0 Gaps

All testing infrastructure is missing — Phase 1 builds it from scratch.

- [ ] `tool/test_with_coverage.sh` — coverage gate script
- [ ] `test/structure/no_flutter_imports_test.dart` — import isolation enforcer
- [ ] `test/fixtures/amsterdam_typical_day.dart` — shared 24h fixture
- [ ] `test/domain/services/temp_score_test.dart`, `rain_score_test.dart`, `wind_score_test.dart`, `score_math_test.dart`, `scoring_engine_test.dart`, `slot_generator_test.dart`, `availability_filter_test.dart`
- [ ] `test/domain/models/ride_tier_test.dart`
- [ ] `test/integration/amsterdam_typical_day_test.dart`
- [ ] Framework install: `flutter pub get` after pubspec.yaml is written; `dart pub global activate coverage` for `format_coverage`. `lcov` CLI install: `brew install lcov` (macOS) — needed only for the coverage filter / threshold script; tests run without it.

## Security Threats

> Phase 1 has no network, no auth, no persistence, no user input, and no UI surface beyond an empty `MaterialApp`. The threat surface is narrow. The threats below apply primarily to the build process and design decisions that lock in future risk.

### Applicable ASVS Categories (level 1)

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (no auth in Phase 1; Phase 9 adds Google OAuth) |
| V3 Session Management | no | — (no sessions) |
| V4 Access Control | no | — (single-user local app) |
| V5 Input Validation | partial | Domain functions accept `double?` everywhere; bounds-check happens via `clamp(0,100)` in `linearShoulder`. No untrusted input enters Phase 1 (no network, no UI input). Phase 2 must validate Open-Meteo responses. |
| V6 Cryptography | no | — (no crypto needed; no secrets stored) |
| V7 Error Handling | yes | Sub-score functions must NOT throw on null/NaN; clamp to 50 and continue. Tested explicitly per SCOR-04. |
| V12 File / Resource | partial | The structural test reads files via `dart:io` — TEST code only, never `lib/domain/`. Limited blast radius. |
| V14 Configuration | partial | `analysis_options.yaml`, `pubspec.yaml`, and committed `*.freezed.dart` / `*.g.dart` are all attack-surface inputs to the build. Pin all versions with `^` (already in pubspec above). |

### Known Threat Patterns for {Dart code-generation + macOS dev machine}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious code-gen package (freezed / build_runner / json_serializable) executing arbitrary code during `dart run build_runner build` | Tampering, EoP | All four packages are from authoritative publishers (dash-overflow.net, dart.dev) on pub.dev with millions of weekly downloads; pin minor versions in pubspec; commit generated files to git so a future build_runner regression is reviewable in diff |
| Stale generated `.freezed.dart` checked in that doesn't match source `@freezed` annotation (silent data corruption) | Tampering | Require `dart run build_runner build --delete-conflicting-outputs` after any model edit; consider a pre-commit hook later (out of scope for Phase 1, note for Phase 10 CI) |
| `double.nan` or `-0.0` propagating through `linearShoulder` and producing invalid scores | Tampering | `clamp(0, 100)` in helper catches NaN → returns `NaN` actually (`NaN.clamp(0,100) == NaN`); ADD explicit `if (x.isNaN) return 50.0;` guards if test reveals this. Phase 1 inputs are nullable doubles, not NaN-producing — but defense-in-depth matters. |
| Integer overflow on `DateTime.add(Duration(hours: 1))` near year 275760 | DoS | Not exploitable for a 7-day forecast |
| Future-proofing: hardcoded Amsterdam lat/lon in fixtures | Information Disclosure (mild) | Phase 1 fixtures are pure synthetic, no real coords needed. Phase 7 GPS rollout must NOT hardcode coords in source — flag this in Phase 7 planning. |
| Slot enumeration DoS via pathological input (e.g., 1000 contiguous good hours → O(N²) slots) | DoS | Phase 1 input is always ≤168 hours (7 days × 24); worst-case slot count ≈ 4·168 ≈ 672 — negligible. Not a real risk at the locked input size. |

### Deferred / future-proofing notes

- **No secrets in Phase 1.** Phase 9 (Google Calendar) introduces OAuth — DO NOT commit any `secrets.json` or client_id values; use Google's secure storage pattern for Android.
- **No persistence in Phase 1.** Phase 2 (Drift) introduces SQLite — design schema with append-only column convention (per ROADMAP.md Phase 2 success criterion 5) so migrations can't corrupt data.
- **No user input in Phase 1.** Phases 4+ (UI) will accept text input (city picker) — must use input length caps and strip non-printable chars before storage.
- **No network in Phase 1.** Phase 2 (Open-Meteo) — enforce HTTPS-only at HTTP client construction (default for `package:http` ≥ 0.13).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | bootstrap (`flutter create`), `flutter pub get`, `flutter run` | ✗ | — | **None — BLOCKING.** Planner must add a Wave 0 install step OR ask user to install. |
| Dart SDK | `dart test`, `dart run build_runner build`, `dart pub global activate coverage` | ✗ | — | Comes bundled with Flutter; installing Flutter installs Dart. |
| `lcov` CLI | coverage filter + threshold script in `tool/test_with_coverage.sh` | unknown — not installed by default on macOS | — | If absent: script prints warning and skips filter/gate; `dart test --coverage` itself still runs. Install via `brew install lcov` |
| `brew` (Homebrew) | install `lcov` if missing | unknown | — | Manual installer download from lcov.io if no brew |
| Git | committing planning artifacts + generated files | (assumed present — `.git` directory exists in project root) | — | — |
| macOS / zsh | dev environment | ✓ | Darwin 25.5.0 | — |

**Missing dependencies with no fallback:**
- **Flutter SDK / Dart SDK — BLOCKING.** Without these, no command in this phase can run. The planner must either (a) add a checkpoint:human-verify task at the very start of Wave 0 instructing the user to install Flutter via the official guide (https://docs.flutter.dev/get-started/install/macos), or (b) fail fast with a clear error. Confirmed via `which flutter` (not found), `which dart` (not found), and checks of `/opt/homebrew/bin/`, `/usr/local/bin/`, `~/flutter/`, `~/development/flutter/`, `~/fvm/default/`, `brew list` — Flutter is genuinely absent from this system.

**Missing dependencies with fallback:**
- `lcov` CLI — script degrades gracefully (prints install hint, skips filter/threshold). All other test infra still works.

## Common Pitfalls

### Pitfall: Null propagation in scoring (PITFALLS.md Pitfall 4)

**What goes wrong:** A sub-score function that does `(temp - 12) / 17 * 100` on a null `temp` throws `Null check operator used on a null value`. Worse, code that treats `null` as `0.0` quietly scores a missing-data hour as "freezing cold" (or "perfectly dry" for null precipitation), giving the user wildly wrong slot picks.

**Why it happens:** Open-Meteo returns nullable fields. Dart's null-safety helps only if you model the response with `double?` and guard at every read.

**How to avoid in Phase 1:** Every sub-score function MUST guard the primary input as the first statement. CONTEXT.md D-23, D-25 lock this: `if (input == null) return 50.0;`. Then write THREE explicit unit tests per sub-score with the relevant input null. Bonus test: a `HourlyForecast` with `apparentTemperature: null, temperature2m: 10.0` must use the fallback (D-23) — not clamp to 50.

**Warning signs:** A 0/100/0 score for a 12°C / 0mm / 5 km/h hour (= perfect riding weather but with null apparent_temperature falling through to "uncertain 50"). The test for "all nulls → all 50s → overall = 50" must pass.

### Pitfall: Off-by-one in slot boundaries (PITFALLS.md Pitfall 5)

**What goes wrong:** A 4-hour ride slot becomes 3h or 5h because the iteration mixes inclusive-end and exclusive-end conventions. Calendar event spans the wrong duration. User shows up at the wrong time.

**Why it happens:** Hourly arrays are 0-indexed; sliding windows naturally tempt off-by-ones. Dart developers sometimes use `for (var i = start; i <= end; i++)` (inclusive) and sometimes `for (var i = start; i < end; i++)` (exclusive) in the same codebase.

**How to avoid in Phase 1:** D-19 locks the convention: `[start, end)` exclusive end. Document on `RideSlot.end` field via a `///` doc comment AND a comment in the SlotGenerator code. Write the explicit test from "Aggregation & Slot Algorithms": for hours `[10:00..14:00)` qualifying, the 4h slot has `start == 10:00` AND `end == 14:00`. Test the edge: last hour of forecast is qualifying — no `RangeError`. Test the threshold: a score of 49 breaks the run, 50.0 and 50.001 continue it.

**Warning signs:** `end.difference(start) != Duration(hours: durationHours)`. `RangeError` on the last day of the forecast. A 5h slot enumerated where only 4 hours qualify.

### Pitfall: `setState() after dispose()` (PITFALLS.md Pitfall 1)

**What goes wrong:** N/A in Phase 1 — no `StatefulWidget`, no async UI. But this is THE most common Flutter crash pattern, and Phase 4+ will hit it.

**How to avoid in Phase 1:** Add a 5-line convention note to `lib/main.dart` doc-comment OR `.planning/research/CONVENTIONS.md` (create it if it doesn't exist): "Any `setState()` following an `await` must be preceded by `if (!mounted) return;`. AsyncNotifier patterns from Riverpod handle this automatically — prefer them over manual `setState()` in async paths." This is paperwork for Phase 1, code-enforcement for Phase 4.

**Warning signs (future):** `FlutterError: setState() called after dispose()` in debug logs. Weather screen flashes data then disappears on quick navigation.

### Pitfall: Hot reload masks `initState` bugs (PITFALLS.md Pitfall 2)

**How to avoid in Phase 1:** None of Phase 1's code runs in `initState`. But note in CONVENTIONS.md: "After editing default Hive values, scoring-engine constants, WorkManager registration, or any `initState()` body — use `flutter run` cold start, not hot reload, to verify."

### Pitfall: Coverage tooling silently reports lib/domain/ as covered when it isn't

**What goes wrong:** `dart test --coverage=coverage` without `--report-on=lib/domain` includes generated `.freezed.dart` and `.g.dart` files in the denominator. Coverage reads "97%" because the generated files have a few lines that no test exercises directly (e.g., constructor-only branches). The 100% gate fails for the wrong reason and the developer disables the gate in frustration.

**How to avoid:** The `tool/test_with_coverage.sh` script uses `--report-on=lib/domain` AND `lcov --remove` to strip `*.freezed.dart`/`*.g.dart`. Both filters are needed because `--report-on` is path-prefix matching (which would include the generated files alongside source), and `lcov --remove` excludes by file pattern.

**Warning signs:** Coverage reports a small number of uncovered lines, all inside `.freezed.dart`. If you see this, the filter step isn't running.

## Code Examples

(All verified patterns assembled in "Domain Models" and "Sub-Score Implementations" and "Aggregation & Slot Algorithms" sections above. Citations: `[VERIFIED: pub.dev/packages/freezed]` for Freezed shape; `[VERIFIED: dart.dev language tour]` for sealed classes; `[VERIFIED: pub.dev/packages/coverage]` for coverage tooling.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Freezed 2.x: `@freezed class Foo with _$Foo` | Freezed 3.x: `@freezed abstract class Foo with _$Foo` | Freezed 3.0 (released 2024) | `abstract` keyword now required for non-union Freezed classes; old form deprecated |
| Freezed 2.x: `.when(...)` / `.map(...)` for unions | Freezed 3.x: native Dart `switch` expressions on the generated sealed-class output | Freezed 3.0 + Dart 3.0 | Cleaner pattern matching; old `when`/`map` still generated for backcompat |
| Riverpod 2.x: separate `AutoDisposeNotifier` and `Notifier` | Riverpod 3.0: unified `Notifier` (auto-dispose by default) | Riverpod 3.0 (Sept 2025) | Phase 3 concern, not Phase 1 — but ensures pubspec pin is correct |
| Material 2 default + `useMaterial3: true` opt-in | Material 3 default since Flutter 3.16 | Flutter 3.16 (late 2023) | `lib/main.dart` example omits `useMaterial3` per CLAUDE.md |
| `flutter test --coverage` produces lcov; `dart test --coverage` produces JSON | Still divergent in 2026 | dart-lang/sdk#60958 OPEN | `tool/test_with_coverage.sh` runs `format_coverage` to bridge |
| `StateProvider` / `StateNotifierProvider` | Legacy in Riverpod 3 | Riverpod 3.0 | Not relevant in Phase 1 (no providers yet) |

**Deprecated/outdated:**
- `import_lint` / `import_rules` / `custom_lint` for one-rule import enforcement — overkill for Phase 1; a 30-line grep test in `test/structure/` is simpler.
- `flutter pub run build_runner` — replaced by `dart run build_runner` since Flutter 2.5 `[CITED: docs.flutter.dev]`. Both work but `dart run` is the documented form.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `freezed: ^3.2.5`, `freezed_annotation: ^3.1.0`, `build_runner: ^2.4.0`, `json_serializable: ^6.8.0`, `coverage: ^1.10.0`, `flutter_lints: ^5.0.0`, `test: ^1.25.0` are all current and legitimate packages on pub.dev | Bootstrap → pubspec.yaml | Stale or hallucinated versions would fail `flutter pub get`. Mitigation: planner should add a `flutter pub outdated` check task after pubspec is written; all packages are cited in CLAUDE.md (with version numbers) and STACK.md (verified 2026-06-01) so risk is low. **Note:** slopcheck was unavailable during research — these are tagged `[ASSUMED]` per package legitimacy protocol's graceful degradation rule. |
| A2 | `flutter create --platforms=android` does NOT scaffold `ios/`, `web/`, `linux/`, `macos/`, `windows/` directories | Bootstrap → `flutter create` incantation | If it does, those folders need a `rm -rf` step. Risk: minor — a single `ls` after `flutter create` verifies. |
| A3 | `dart test --coverage=coverage` works inside a Flutter package as long as the tested files don't transitively import `package:flutter` | Test Strategy → Coverage tooling | If `dart test` requires the package to be a non-Flutter package, the domain code would need extraction to a sub-package. dart-lang/sdk#60958 implies dart test works on Flutter packages but emits different coverage format. Mitigation: planner adds an early-Wave-0 spike task that runs `dart test` against a trivial test inside the freshly-created package to verify before committing to the approach. |
| A4 | The `coverage` package's `format_coverage` accepts `--report-on=lib/domain` as a path filter | Test Strategy → Coverage tooling | If the flag name has changed (e.g., `--scope-output`), the script needs a one-line fix. Low risk — verifiable via `dart run coverage:format_coverage --help` once installed. |
| A5 | `lcov` CLI is installable via `brew install lcov` on macOS Darwin 25 | Environment Availability | If brew rejects (e.g., outdated brew), user follows lcov.io manual install. Low risk. |
| A6 | The user's macOS machine has Homebrew available for `brew install lcov` | Environment Availability | If not, manual lcov install is feasible but the `tool/test_with_coverage.sh` script handles absence gracefully. |
| A7 | Committing `*.freezed.dart` and `*.g.dart` is the right call for Phase 1 (vs adding to `.gitignore`) | Bootstrap → `.gitignore` | Many Flutter projects gitignore these and require `build_runner` on every fresh clone. For a solo dev project this is friction. Trade-off noted in Bootstrap section; planner may choose either. Both are valid. |
| A8 | Dart's library privacy means a file-private `_linearShoulder` in `_score_math.dart` is visible only inside that file, and a top-level `linearShoulder` is visible to other files in the same package (which is what we want) | Sub-Score Implementations → Helper placement | This is well-documented Dart behavior. Risk: nil. |
| A9 | `flutter run` on a freshly bootstrapped Android-only project will work on macOS without additional Android SDK setup beyond what `flutter doctor` would prompt for | Bootstrap | Likely false on a brand-new machine — Android SDK install / accept licenses / create AVD steps may be needed. Phase 1 success criterion only requires `flutter run` to succeed on the developer's machine; if blocked, planner should add a `flutter doctor` checkpoint task. The Android setup is out of Phase 1 scope per CONTEXT.md "Skeleton scope: CI is deferred." |

## Open Questions

1. **Should generated Freezed files be committed or gitignored?**
   - What we know: Both are common patterns. Committing avoids the "fresh clone needs build_runner" friction; gitignoring keeps the repo smaller and avoids regen-conflicts in PRs.
   - What's unclear: User's preference. CLAUDE.md and CONTEXT.md don't address.
   - Recommendation: Commit them for Phase 1 (simplest devloop for solo dev). Re-evaluate at Phase 10 CI setup.

2. **Will `dart test` actually work on the Flutter-flavored package?**
   - What we know: Per dart-lang/sdk#60958 and multiple community articles, `dart test` runs on Flutter packages provided the tested files have no Flutter imports. Coverage format differs from `flutter test --coverage`.
   - What's unclear: Whether there are any pubspec quirks (e.g., `flutter:` block requiring the Flutter binary on PATH even for `dart test`).
   - Recommendation: Wave 0 includes a 5-minute spike task: write a trivial `test/spike_test.dart` with `import 'package:test/test.dart'; void main() { test('a', () => expect(1, 1)); }`, run `dart test`, confirm green BEFORE building out the rest. If it fails, the fallback is to extract `lib/domain/` into a sub-package — but this is a much bigger task and worth ruling out early.

3. **Does the user have Flutter installed?**
   - What we know: `which flutter` returns "not found"; no Flutter at `/opt/homebrew/bin/`, `/usr/local/bin/`, `~/flutter/`, `~/development/flutter/`, `~/fvm/default/`. `brew list | grep flutter` returns empty.
   - What's unclear: Whether the user intends to install Flutter as part of this phase or expects it pre-installed.
   - Recommendation: Wave 0 first task is a `checkpoint:human-verify` asking the user to confirm Flutter SDK install OR install it via https://docs.flutter.dev/get-started/install/macos. Without Flutter, no other task in this phase can execute. This is a HARD BLOCKING dependency.

4. **`flutter create .` in a non-empty directory — clobber risk?**
   - What we know: The project root already contains `CLAUDE.md`, `mockup.html`, `.planning/`, `.git`. `flutter create` should only add missing files but the exact behavior on a non-empty dir is not documented in detail.
   - What's unclear: Whether `flutter create` aborts, prompts, or silently skips conflicting files.
   - Recommendation: Run `flutter create` in a tempdir first, then `rsync --ignore-existing` (or manual cp) the scaffolded files into place. Or simply test with `flutter create --offline .` and observe; rollback via git if it does something unwanted (the `.git` directory protects us).

5. **`coverage` package — global activation vs dev-dependency.**
   - What we know: `dart pub global activate coverage` installs `format_coverage` system-wide; alternatively `coverage: ^1.10.0` in dev_dependencies allows `dart run coverage:format_coverage`.
   - What's unclear: Slight preference for the dev-dependency approach (self-contained, version-pinned per-project) — but global activation is what most articles show.
   - Recommendation: Use dev-dependency approach (already in pubspec above). One less thing to install on a fresh clone.

## Sources

### Primary (HIGH confidence)
- `[VERIFIED: pub.dev/packages/freezed]` — Freezed 3.x usage pattern, `abstract class` form, factory constructor, sealed-class interop, `dart run build_runner` command — fetched 2026-06-02
- `[VERIFIED: pub.dev/packages/coverage]` — `format_coverage` invocation, `--lcov`/`--in`/`--out`/`--report-on` flags — fetched 2026-06-02
- `[CITED: docs.flutter.dev/release/breaking-changes/material-3-migration]` — Material 3 default since Flutter 3.16
- `[CITED: dart.dev/tools/dart-test]` — `dart test` is "not the recommended approach for Flutter projects" but works for pure-Dart libraries within them
- `.planning/research/STACK.md` — locked versions for all packages (verified pub.dev 2026-06-01)
- `.planning/research/ARCHITECTURE.md` — canonical `lib/` tree, component responsibilities, anti-patterns (#1 no scoring in UI, #4 no caching slots)
- `.planning/research/PITFALLS.md` — Pitfall 1 (setState/dispose), Pitfall 4 (null propagation), Pitfall 5 (slot off-by-one)
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `/Users/joostmouw/ridewindow/CLAUDE.md` — locked decisions and stack

### Secondary (MEDIUM confidence)
- `[CITED: GitHub flutter/flutter#62594]` — `flutter create --platforms=android` behavior in plugin vs app templates
- `[CITED: GitHub dart-lang/sdk#60958]` — open ticket on dart test / flutter test coverage format divergence
- `[CITED: Medium "Flutter Test Coverage with lcov" by Nicat Tagizada]` — exact `lcov --remove` filter command pattern for generated files
- `[CITED: pub.dev/packages/import_lint, pub.dev/packages/import_rules, pub.dev/packages/custom_lint]` — considered and rejected for Phase 1 in favor of grep-based test

### Tertiary (LOW confidence — flagged for validation)
- A1 — package versions are taken from CLAUDE.md / STACK.md (verified 2026-06-01) but slopcheck was unavailable during this research session; tagged `[ASSUMED]` per package legitimacy protocol's graceful degradation rule. Planner SHOULD gate the first `flutter pub get` behind a `checkpoint:human-verify` confirming `flutter pub outdated` returns clean.

## Project Constraints (from CLAUDE.md)

- **Locked stack:** Flutter 3.x (stable), Dart 3.x, Freezed for all data models, `sealed class` for `RideTier` (Perfect / Great / Acceptable / Poor) — enforced in this research's "Domain Models" and "Sub-Score Implementations" sections.
- **Material 3 default** (Flutter 3.16+) — `lib/main.dart` example omits the deprecated `useMaterial3: true` flag.
- **Riverpod 3.0 patterns** (only relevant from Phase 3 onward) — Phase 1 plan must NOT introduce providers; ScoringEngine/SlotGenerator/AvailabilityFilter are plain classes constructed without DI.
- **`dart_code_metrics` and `flutter_lints`** — `flutter_lints` is in this plan's `analysis_options.yaml`; `dart_code_metrics` is NOT (paid product since 2024, optional, deferrable).
- **GSD Workflow Enforcement (CLAUDE.md):** "Before using Edit, Write, or other file-changing tools, start work through a GSD command" — Phase 1 plans should be created through `/gsd-plan-phase` (which spawned this research), and execution should be through `/gsd-execute-phase`.

## Package Legitimacy Audit

**Slopcheck unavailable during research** — install was blocked by auto-mode classifier as scope escalation (correct behavior for an unverified external package install). All packages below are tagged `[ASSUMED]` per protocol's graceful degradation rule. Planner MUST add a `checkpoint:human-verify` task immediately before the first `flutter pub get` that runs:

```bash
flutter pub get
flutter pub outdated     # check for stale versions
# Manual eyeball: do all packages appear with sensible recent timestamps?
```

| Package | Registry | Source Repo | slopcheck | Disposition |
|---------|----------|-------------|-----------|-------------|
| `flutter` SDK | flutter.dev | github.com/flutter/flutter | unavailable | `[ASSUMED]` — official, no concern |
| `freezed_annotation` | pub.dev | github.com/rrousselGit/freezed | unavailable | `[ASSUMED]` — locked in CLAUDE.md, dash-overflow.net publisher |
| `json_annotation` | pub.dev | github.com/google/json_serializable.dart | unavailable | `[ASSUMED]` — locked in CLAUDE.md, dart.dev publisher |
| `flutter_test` SDK | flutter.dev | github.com/flutter/flutter | unavailable | `[ASSUMED]` — official |
| `test` | pub.dev | github.com/dart-lang/test | unavailable | `[ASSUMED]` — dart.dev publisher |
| `freezed` | pub.dev | github.com/rrousselGit/freezed | unavailable | `[ASSUMED]` — locked in CLAUDE.md |
| `json_serializable` | pub.dev | github.com/google/json_serializable.dart | unavailable | `[ASSUMED]` — locked in CLAUDE.md |
| `build_runner` | pub.dev | github.com/dart-lang/build | unavailable | `[ASSUMED]` — locked in CLAUDE.md |
| `coverage` | pub.dev | github.com/dart-lang/coverage | unavailable | `[ASSUMED]` — dart.dev publisher |
| `flutter_lints` | pub.dev | github.com/flutter/packages | unavailable | `[ASSUMED]` — flutter.dev publisher |

**Packages removed due to slopcheck [SLOP] verdict:** none (gate did not run)
**Packages flagged as suspicious [SUS]:** none (gate did not run)

All packages above are referenced in `.planning/research/STACK.md` with publisher names verified on pub.dev 2026-06-01 and pin requirements in CLAUDE.md. The risk of any being slopsquatted is very low, but the protocol requires explicit `[ASSUMED]` tagging when the gate cannot run — hence the recommended `checkpoint:human-verify` task.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — locked in CLAUDE.md + STACK.md, cross-verified via pub.dev WebFetch.
- Architecture: HIGH — fully locked by CONTEXT.md decisions D-01 through D-26 + ARCHITECTURE.md `lib/` tree.
- Algorithms: HIGH — all formulas locked in CONTEXT.md with reference test values; Dart code shapes are idiomatic and verifiable against `dart.dev` language tour.
- Pitfalls: HIGH — cited from existing PITFALLS.md research (Pitfalls 1, 4, 5).
- Coverage tooling: MEDIUM — dart-lang/sdk#60958 confirms divergence; `format_coverage` flags verified on pub.dev; the `--report-on` flag and lcov filter pattern need to be validated on the actual fresh project (Open Question 2).
- Environment: HIGH (Flutter absence confirmed) — this is a blocking finding the planner must address.

**Research date:** 2026-06-02
**Valid until:** 2026-09-02 (3 months — Flutter/Dart toolchain is stable; Freezed 3.x and coverage tooling unlikely to change radically; package versions may have patch updates by then, re-check with `flutter pub outdated`)

## RESEARCH COMPLETE
