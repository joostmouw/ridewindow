---
phase: 05-ui-phase-b-ride-detail-insights-sheet
plan: 02
subsystem: ui-detail
tags: [flutter, widget, ride-detail, score-banner, hourly-table, insights-sheet]
dependency_graph:
  requires: [05-01]
  provides: [RideDetailScreen-full, InsightsSheet-stub]
  affects: [lib/features/detail/]
tech_stack:
  added: []
  patterns: [StatelessWidget, showModalBottomSheet, switch-expression-on-sealed-class]
key_files:
  created:
    - lib/features/detail/ride_detail_screen.dart
    - lib/features/detail/insights_sheet.dart
    - test/features/ride_detail_screen_test.dart
  modified: []
decisions:
  - "ScoreBadge widget embedded in score-banner alongside tier emoji + description text (plan key_links requirement)"
  - "Inline tier switch expressions used for banner colors/emoji/description — no separate helper class"
  - "buildHourlyRows called in build() — O(n×m) acceptable per T-05-02-01 threat model (max 7h × 168 forecasts)"
  - "Empty-slot guard returns '—' for all avg fields when forecasts list is empty (T-05-02-02 mitigated)"
metrics:
  duration: 8min
  completed: 2026-06-03
  tasks_completed: 1
  files_changed: 3
---

# Phase 05 Plan 02: RideDetailScreen Full Implementation Summary

**One-liner:** Full RideDetailScreen with score-banner (tier emoji + ScoreBadge), weather info-card with averages, hourly table via buildHourlyRows, and InsightsSheet stub opened via showModalBottomSheet.

## What Was Built

### Task 1: RideDetailScreen volledig scherm (TDD)

**RED phase** — 13 failing widget tests written covering:
- AppBar start/end time display
- Score-banner tier emoji (Perfect=🟢, Acceptable=🟡, Poor=⚪)
- Score-banner description text per tier
- Hourly table time/temp rows
- i-button visibility + showModalBottomSheet trigger
- Placeholder action buttons (agenda + reminder) → SnackBar
- Info-kaart "Weer" avg temperature + "Droog" for zero precipitation
- Empty slot (no hours) renders without crash showing "—" fallbacks

**GREEN phase** — Implementation:

`lib/features/detail/ride_detail_screen.dart` — Full StatelessWidget:
- AppBar: `HH:mm – HH:mm` title + `Xu · [tier] omstandigheden` subtitle
- Score-banner: tier emoji + `ScoreBadge(tier: slot.tier)` + description text + `IconButton(Icons.info_outline)` that calls `showModalBottomSheet` with `InsightsSheet`
- Info-kaart "WEER": avg temperatureC + apparentTemperatureC, total precipitationMm ("Droog" if 0.0), avg windspeedKmh — all with "—" fallback for empty data
- Info-kaart "UURLIJKS": one row per `HourlyRow` from `buildHourlyRows(slot, forecasts)` — time / temp / `v.a. X°C` (if apparentTemperatureC not null) / 🌧 precip / 💨 wind
- Placeholder actions: ElevatedButton "Toevoegen aan agenda" (green #2E7D32) + "Herinner me de avond ervoor" (grey #F5F5F5) — both show SnackBar

`lib/features/detail/insights_sheet.dart` — Wave 3 stub:
```dart
class InsightsSheet extends StatelessWidget {
  final RideSlot slot;
  const InsightsSheet({super.key, required this.slot});
  @override
  Widget build(BuildContext context) => const SizedBox(height: 200);
}
```

## TDD Gate Compliance

- RED commit: `4f9c880` — test(05-02): add failing tests for RideDetailScreen full implementation
- GREEN commit: `ec41471` — feat(05-02): full RideDetailScreen + InsightsSheet stub
- 13 tests written, all 13 pass after implementation
- No REFACTOR phase needed — implementation was clean from the start

## Verification

```
dart analyze lib/ → No issues found
flutter test → 155 tests passed, 0 failed (full suite)
grep -c "buildHourlyRows" ride_detail_screen.dart → 1
grep -c "showModalBottomSheet" ride_detail_screen.dart → 1
grep -c "ScoreBadge" ride_detail_screen.dart → 1
```

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as specified.

### Deliberate Deviations

**1. ScoreBadge placement in score-banner**

Plan `key_links` specified `ScoreBadge(tier: slot.tier)` must appear in the detail screen.
The score-banner uses both the tier emoji + a ScoreBadge widget side-by-side. ScoreBadge is placed below the emoji in a Column alongside the description text. This satisfies the `must_haves` truth "Een ScoreBadge matching de Home card is zichtbaar in het detailscherm".

## Known Stubs

| Stub | File | Description |
|------|------|-------------|
| InsightsSheet body | `lib/features/detail/insights_sheet.dart` | `SizedBox(height: 200)` — Wave 3 (05-03) will implement score breakdown with LinearProgressIndicator bars |
| "Toevoegen aan agenda" | `lib/features/detail/ride_detail_screen.dart` | SnackBar placeholder — Phase 9 will wire Google Calendar |
| "Herinner me de avond ervoor" | `lib/features/detail/ride_detail_screen.dart` | SnackBar placeholder — Phase 8 will wire flutter_local_notifications |

These stubs are intentional — InsightsSheet is marked for Wave 3 (05-03), buttons for Phases 8/9.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced.
Threat T-05-02-02 (empty slot → crash on avg computation) mitigated by guard: `if (vals.isEmpty) return '—'` in all three avg helpers.

## Self-Check: PASSED

- [x] `lib/features/detail/ride_detail_screen.dart` — exists, 406 lines, full implementation
- [x] `lib/features/detail/insights_sheet.dart` — exists, stub for Wave 3
- [x] `test/features/ride_detail_screen_test.dart` — exists, 13 tests
- [x] RED commit `4f9c880` — confirmed via git log
- [x] GREEN commit `ec41471` — confirmed via git log
- [x] `dart analyze lib/` — No issues found
- [x] `flutter test` — 155 passed, 0 failed
