---
phase: quick
plan: 260618-csx
subsystem: agenda-ui
tags: [ui, navigation, week-agenda, open-meteo, availability]
dependency_graph:
  requires: [slotsProvider, availabilityProvider, open_meteo_client]
  provides: [WeekAgendaScreen, /agenda route, 3-tab NavigationBar]
  affects: [scaffold_with_nav, router, open_meteo_client]
tech_stack:
  added: []
  patterns: [ConsumerWidget, StatefulShellBranch, SingleChildScrollView nested horizontal+vertical]
key_files:
  created:
    - lib/features/agenda/week_agenda_screen.dart
  modified:
    - lib/data/remote/open_meteo_client.dart
    - lib/app/router.dart
    - lib/app/scaffold_with_nav.dart
    - lib/app/router.g.dart
decisions:
  - Weekday-projection for days 8-10: map targetDay.weekday to stored current-week keys in availabilityProvider
  - Solid tier colors (no opacity): Perfect=0xFF2E7D32, Great=0xFF81C784, Acceptable=0xFFFFB74D per Flutter 3.x lint
  - No package:collection dependency: firstWhereOrNull implemented as for-loop (collection not in pubspec.yaml)
  - const _Legend() constructor added to satisfy prefer_const_constructors lint
metrics:
  duration: ~10min
  completed: "2026-06-18"
  tasks_completed: 3
  files_changed: 6
---

# Quick Task 260618-csx: Week Agenda View Summary

**One-liner:** 10-day time grid with blocked-hour shading and tier-colored ride slot overlays, accessed via a 3rd Agenda tab in the NavigationBar.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend Open-Meteo fetch to 10 days | 7a6dbbe | lib/data/remote/open_meteo_client.dart |
| 2 | Build WeekAgendaScreen with time grid | e0c1310 | lib/features/agenda/week_agenda_screen.dart |
| 3 | Wire route and add Agenda tab | af16b02 | lib/app/router.dart, lib/app/scaffold_with_nav.dart |

## What Was Built

**Task 1 — Open-Meteo 10-day fetch:**
Added `'forecast_days': '10'` inline in the `queryParameters` map in `OpenMeteoClient.fetch()`. The existing generic `List.generate` parser handles any count, so no other changes were needed. `weatherProvider` now exposes 240 hourly entries (10 × 24).

**Task 2 — WeekAgendaScreen:**
New `ConsumerWidget` at `lib/features/agenda/week_agenda_screen.dart`. Layout: outer vertical `SingleChildScrollView` wrapping a `Row` with a fixed hour-label column and an inner horizontal `SingleChildScrollView` for the day grid. Days 0–9 from today, hours 06–22 (17 rows × 10 cols = 170 cells). Cell coloring priority: ride slot tier color > blocked grey > free white. Availability pattern for days beyond current week is projected by weekday mapping. Legend bar (Vrij / Geblokkeerd / Rijvenster) fixed at bottom.

**Task 3 — Navigation wiring:**
- `scaffold_with_nav.dart`: added `NavigationDestination` for Agenda (calendar_view_week icon) at index 1 between Home and Profiel.
- `router.dart`: added import and `StatefulShellBranch` for `/agenda` at index 1.
- `build_runner build` run to regenerate `router.g.dart` and related `.g.dart` files.

## Deviations from Plan

**1. [Rule 1 - Bug] Removed duplicate `_weekdayLabels` constant**
- **Found during:** Task 2 flutter analyze
- **Issue:** `_weekdayLabels` defined in both `_DayHeaderRow` (unused) and `_DayHeaderCell` (used) — `unused_field` warning
- **Fix:** Removed the definition from `_DayHeaderRow`; only `_DayHeaderCell` uses it
- **Files modified:** lib/features/agenda/week_agenda_screen.dart

**2. [Rule 1 - Lint] Added const constructors and const Row in _Legend**
- **Found during:** Task 2 flutter analyze — `prefer_const_constructors` / `prefer_const_literals_to_create_immutables`
- **Fix:** Added `const _Legend()` constructor; changed `Row(...)` to `const Row(...)` with child literals promoted to const
- **Files modified:** lib/features/agenda/week_agenda_screen.dart

## Verification Results

```
grep forecast_days open_meteo_client.dart → line 29: 'forecast_days': '10'
flutter analyze week_agenda_screen.dart  → No issues found
flutter analyze router.dart scaffold_with_nav.dart → No issues found
grep -c NavigationDestination scaffold_with_nav.dart → 3
```

## Known Stubs

None — grid renders live data from `slotsProvider` and `availabilityProvider`. No hardcoded placeholder values.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundaries introduced beyond what the plan's threat model documented (T-csx-01 accepted, T-csx-02 mitigated by 17×10 cell limit).

## Self-Check: PASSED

- lib/features/agenda/week_agenda_screen.dart: FOUND
- lib/data/remote/open_meteo_client.dart forecast_days: FOUND
- Commit 7a6dbbe: FOUND
- Commit e0c1310: FOUND
- Commit af16b02: FOUND
