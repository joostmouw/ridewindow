---
phase: 05-ui-phase-b-ride-detail-insights-sheet
plan: "01"
subsystem: ui-navigation
tags: [navigation, view-model, widget, go_router, weather-chips]
dependency_graph:
  requires:
    - lib/domain/models/ride_slot.dart
    - lib/domain/models/hourly_score.dart
    - lib/domain/models/hourly_forecast.dart
    - lib/domain/models/ride_tier.dart
    - lib/app/router.dart
    - lib/features/home/home_screen.dart
    - lib/providers/weather_notifier.dart
  provides:
    - lib/domain/models/hourly_row.dart
    - lib/features/detail/detail_args.dart
    - lib/features/shared/score_badge.dart
    - lib/features/detail/ride_detail_screen.dart (stub)
    - /detail GoRoute in router.dart
    - Tap navigation from HomeScreen ride cards
    - Real weather chip values in HomeScreen
  affects:
    - lib/app/router.dart
    - lib/features/home/home_screen.dart
tech_stack:
  added:
    - go_router extra parameter pattern for navigation with complex objects
  patterns:
    - Plain Dart class for view-model (HourlyRow) — no code-gen required
    - Plain Dart class DTO for router extra (DetailArgs)
    - Shared StatelessWidget extracted from private method (ScoreBadge)
    - T-05-01 null-safe cast guard in router builder
key_files:
  created:
    - lib/domain/models/hourly_row.dart
    - lib/features/detail/detail_args.dart
    - lib/features/shared/score_badge.dart
    - lib/features/detail/ride_detail_screen.dart
    - test/domain/models/hourly_row_test.dart
  modified:
    - lib/app/router.dart
    - lib/features/home/home_screen.dart
decisions:
  - "HourlyRow is a plain Dart class (no Freezed) — Phase-5-only view model for merging scores + forecasts"
  - "DetailArgs uses const constructor — immutable DTO safe for go_router extra"
  - "ScoreBadge extracted from HomeScreen._buildBadge using identical colors/labels for visual consistency"
  - "T-05-01 mitigated: router uses 'is! DetailArgs' guard before cast, returns error Scaffold"
  - "Weather chips show avg temp (1 decimal), total precip (1 decimal), avg wind (0 decimal); '—' when no data"
  - "Forecast filtering uses !f.time.isBefore(slot.start) && f.time.isBefore(slot.end) per SLOT-02 [start, end) convention"
metrics:
  duration: "~20 minutes"
  completed: "2026-06-03"
  tasks_completed: 2
  files_created: 5
  files_modified: 2
---

# Phase 5 Plan 1: HourlyRow model + DetailArgs DTO + ScoreBadge widget + /detail route + HomeScreen tap-navigation Summary

**One-liner:** Navigation contract from HomeScreen to /detail via go_router extra with DetailArgs(slot + filtered forecasts), shared ScoreBadge widget extracted, and real average weather chip values replacing placeholders.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | HourlyRow model + DetailArgs DTO + ScoreBadge widget | 11d244d | hourly_row.dart, detail_args.dart, score_badge.dart |
| 2 | /detail route + HomeScreen tap-navigation + real weather chips | fc72d22 | router.dart, home_screen.dart, ride_detail_screen.dart |

### Task 1 — TDD Commits

| Phase | Commit | Description |
|-------|--------|-------------|
| RED | f86e093 | Failing test for HourlyRow + buildHourlyRows |
| GREEN | 11d244d | Implementation — all 4 unit tests pass |

## What Was Built

### `lib/domain/models/hourly_row.dart`

Plain Dart class `HourlyRow` with 9 fields (time, temperatureC?, apparentTemperatureC?, precipitationMm?, windspeedKmh?, overallScore, temperatureScore, rainScore, windScore). Pure helper function `buildHourlyRows(RideSlot, List<HourlyForecast>)` merges by time using `firstWhere` with null-forecast `orElse` fallback.

### `lib/features/detail/detail_args.dart`

Const-constructor DTO carrying `RideSlot slot` and `List<HourlyForecast> forecasts` (pre-filtered to slot window). Used as go_router `extra` parameter.

### `lib/features/shared/score_badge.dart`

`StatelessWidget` with sealed class switch-expression for tier colors and Dutch labels (Perfect/Goed/Acceptabel/Slecht). Extracted from `HomeScreen._buildBadge` — visually identical.

### `lib/features/detail/ride_detail_screen.dart`

Stub `StatelessWidget` accepting `slot` and `forecasts` parameters, rendering an empty Scaffold. Enables router.dart to compile for Wave 2.

### `lib/app/router.dart` — /detail route added

GoRoute for `/detail` with T-05-01 null-safe guard: `if (state.extra is! DetailArgs) → error Scaffold` before cast.

### `lib/features/home/home_screen.dart` — tap + real data

- `_buildBadge` removed, replaced by `ScoreBadge(tier: slot.tier)`
- `GestureDetector.onTap` added to ride card: filters forecasts, navigates via `context.go('/detail', extra: DetailArgs(...))`
- Weather chips now show real computed values: avg temperature (1 decimal °C), total precipitation (1 decimal mm), avg windspeed (0 decimal km/u). Shows "—" when weather not loaded or no data.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Security Mitigations Applied (per threat model)

**T-05-01 mitigated (Tampering — state.extra as DetailArgs):**
- Applied `if (state.extra is! DetailArgs)` guard in router before cast
- Returns an error Scaffold with Dutch message if navigation is invalid
- File: `lib/app/router.dart`

## Known Stubs

| File | Stub | Reason |
|------|------|--------|
| lib/features/detail/ride_detail_screen.dart | Empty Scaffold body (`SizedBox.shrink()`) | Wave 2 (05-02) implements full screen |

These stubs do not block this plan's goal (navigation contract + HomeScreen wiring) — they are placeholders intentionally deferred to Wave 2.

## Verification Results

```
dart analyze lib/ → No issues found
flutter test (JSON reporter) → success: True
grep context.go.*detail home_screen.dart → 1
grep path.*detail router.dart → 1
grep ScoreBadge home_screen.dart → 1
```

## Self-Check: PASSED

Files created:
- lib/domain/models/hourly_row.dart — FOUND
- lib/features/detail/detail_args.dart — FOUND
- lib/features/shared/score_badge.dart — FOUND
- lib/features/detail/ride_detail_screen.dart — FOUND
- test/domain/models/hourly_row_test.dart — FOUND

Commits:
- f86e093 — test(05-01): add failing tests for HourlyRow + buildHourlyRows — FOUND
- 11d244d — feat(05-01): HourlyRow model + DetailArgs DTO + ScoreBadge widget — FOUND
- fc72d22 — feat(05-01): /detail route + HomeScreen tap-navigation + real weather chips — FOUND
