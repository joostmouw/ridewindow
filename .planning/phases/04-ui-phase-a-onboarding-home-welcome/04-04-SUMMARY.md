---
phase: 04-ui-phase-a-onboarding-home-welcome
plan: "04"
subsystem: ui/home
tags: [flutter, riverpod, go_router, home-screen, week-strip, ride-cards, skeleton, material3]
dependency_graph:
  requires: ["04-03"]
  provides:
    - "HomeScreen ConsumerStatefulWidget with week strip + ride cards"
    - "MaterialApp.router wired to routerProvider"
    - "router.dart real HomeScreen import"
  affects:
    - lib/features/home/home_screen.dart
    - lib/main.dart
    - lib/app/router.dart
tech_stack:
  added: []
  patterns:
    - "ConsumerStatefulWidget with SingleTickerProviderStateMixin for AnimationController"
    - "AnimatedBuilder with AnimationController for skeleton pulse animation"
    - "NavigationBar (Material 3) for bottom navigation"
    - "Sealed class pattern-matching switch expressions for tier colours/labels"
    - "MaterialApp.router with routerProvider (ConsumerWidget)"
key_files:
  created:
    - lib/features/home/home_screen.dart
  modified:
    - lib/main.dart
    - lib/app/router.dart
decisions:
  - "Weather chip values shown as '?°C / ?mm / ?km/u' placeholder — real HourlyForecast data wiring deferred to Phase 5 (RideDetailScreen + Insights)"
  - "HomeScreen mixes SingleTickerProviderStateMixin for skeleton pulse AnimationController — simplest approach, no shimmer package needed"
  - "Day selection uses year+month+day triple comparison to avoid cross-month false matches"
metrics:
  duration: "~5 minutes"
  completed: "2026-06-03"
  tasks_completed: 2
  files_changed: 3
---

# Phase 4 Plan 04: HomeScreen + MaterialApp.router Summary

**One-liner:** HomeScreen ConsumerStatefulWidget with week strip (7 day chips with good/ok/bad indicators, tap-to-filter), tier colour-coded ride cards (Perfect/Great/Acceptable), animated skeleton loading state, empty states, and "Plan het" SnackBar; main.dart updated to MaterialApp.router with routerProvider; router.dart using real HomeScreen import.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | HomeScreen widget | c9835c1 | lib/features/home/home_screen.dart |
| 2 | main.dart MaterialApp.router + router.dart real HomeScreen import | 7db99e3 | lib/main.dart, lib/app/router.dart |

## What Was Built

### Task 1: HomeScreen widget

**HomeScreen (`lib/features/home/home_screen.dart`):**
- `ConsumerStatefulWidget` with `SingleTickerProviderStateMixin` for skeleton animation
- State: `DateTime? _selectedDay` — null = show all slots; non-null = filter to that day
- Watches: `weatherProvider`, `slotsProvider`, `locationProvider`

**Header (`_buildHeader`):**
- White container with bottom border #F0F0F0
- City name (20px bold) from `locationProvider.city` + watch icon
- "This week" subtitle (13px #999)
- Refresh `IconButton` shown when `weatherState.hasError`

**Week strip (`_buildWeekStrip`):**
- 7 day chips MA–ZO calculated from current week Monday
- Each chip: `_DayClass.good` (green #E8F5E9/#2E7D32) / `ok` (amber #FFF3E0/#E65100) / `bad` (red #FFEBEE/#C62828)
- Class determined from best tier of slots on that day via `SlotsLoaded`
- Selected day gets green ring border (2.5px #2E7D32)
- Tap toggles selection; tap again deselects

**Ride cards (`_buildRideCard`):**
- White card, border-radius 18, left border 4px with tier colour
- Tier colours: Perfect #2E7D32 / Great #66BB6A / Acceptable #FFA726 / Poor #BDBDBD
- Tier badge (tinted background): Perfect #E8F5E9/#1B5E20 / Great #F1F8E9/#33691E / Acceptable #FFF3E0/#E65100
- Time format: "09:00 – 13:00 · 4u"
- Weather chips placeholder: "🌡 ?°C / 🌧 ?mm / 💨 ?km/u" (Phase 5 will wire real data)
- "Plan het" ElevatedButton (green or amber for Acceptable) → SnackBar

**Skeleton loading (`_buildSkeletonCards`):**
- 3 grey (#E0E0E0) cards with AnimatedBuilder pulse animation (0.4→1.0 opacity, 900ms)

**Empty states:**
- `badWeather` → "Geen goede rijmomenten deze week. Slecht weer verwacht."
- `allBlocked` → "Alle goede momenten zijn geblokkeerd. Pas je schema aan."
- Empty list → "Geen rijmomenten gevonden."
- No slots on selected day → "Geen rijmomenten op deze dag."

**Bottom navigation:**
- `NavigationBar` (Material 3) with Home (active) + Profiel destinations
- `onDestinationSelected: (i) {}` — Profile navigation deferred to Phase 6

### Task 2: main.dart + router.dart

**main.dart:**
- `RideWindowApp` changed from `StatelessWidget` to `ConsumerWidget`
- `build(BuildContext context, WidgetRef ref)` watches `routerProvider`
- `MaterialApp.router(routerConfig: router)` replaces `MaterialApp(home: ...)`
- `ProviderScope(child: RideWindowApp())` in `main()` unchanged

**router.dart:**
- Removed `_HomeScreenPlaceholder` class
- Added `import 'package:ridewindow/features/home/home_screen.dart'`
- `/home` route builder uses `const HomeScreen()`
- Removed unused `package:flutter/material.dart` import (no longer needed after placeholder removed)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing feature] Weather chips show placeholder values**
- **Found during:** Task 1 design review
- **Issue:** `HourlyForecast` data is not directly accessible from `RideSlot` (slots contain `List<HourlyScore>` not raw forecasts). The plan explicitly notes this: "HourlyForecast data niet direct in scope hier; toon placeholder chips"
- **Fix:** Weather chips display "🌡 ?°C  🌧 ?mm  💨 ?km/u" as placeholders. Documented as intentional stub for Phase 5.
- **Files modified:** lib/features/home/home_screen.dart

None - plan executed as written for all other aspects.

## Verification Results

```
dart analyze lib/ → No issues found
flutter test → exit code 0 (all tests passed)
grep -c "MaterialApp.router" lib/main.dart → 2
grep -c "ConsumerWidget" lib/main.dart → 2
grep -c "slotsProvider" lib/features/home/home_screen.dart → 1
grep -c "locationProvider" lib/features/home/home_screen.dart → 1
grep -c "Plan het" lib/features/home/home_screen.dart → 3
grep -c "HomeScreen" lib/app/router.dart → 2
```

## Success Criteria Verification

1. HomeScreen is ConsumerStatefulWidget watching slotsProvider, weatherProvider, locationProvider — PASS
2. Week strip: 7 day chips; tap filters cards per day; tap again deselects — PASS
3. Ride cards: tier colour left border, time range, "Plan het" button — PASS
4. Loading state: 3 animated skeleton cards during weatherProvider.isLoading — PASS
5. Empty state: readable message for badWeather/allBlocked/empty-on-day — PASS
6. "Plan het" shows SnackBar with Google Calendar message — PASS
7. main.dart uses MaterialApp.router(routerConfig: routerProvider) — PASS
8. router.dart imports real HomeScreen — PASS
9. dart analyze lib/ No issues found — PASS
10. flutter test exit code 0 (all tests pass) — PASS

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| Weather chip values "?°C / ?mm / ?km/u" | lib/features/home/home_screen.dart | ~336 | Phase 5 (RideDetailScreen) will wire real HourlyForecast data to ride cards |
| AvailabilityScreen body text | lib/features/availability/availability_screen.dart | ~16 | Phase 6 will replace with full 7x24 calendar grid (carried from 04-03) |

These stubs are intentional and do not prevent the plan's goal from being achieved. HomeScreen fully functions with real provider data; weather chip values are UI decoration that Phase 5 will populate.

## Threat Model Applied

| Threat | Disposition | Applied |
|--------|-------------|---------|
| T-04-04-01 DoS via slots.where() filter per dag | accept | Max 168 slots (7x24); O(n) filtering is negligible |
| T-04-04-02 LocationData.city in UI | accept | Hardcoded 'Amsterdam' in Phase 4; no sensitive user data |
| T-04-04-03 MaterialApp.router routerConfig | accept | routerProvider is keepAlive; router instance is deterministic |
| T-04-SC No new package installations | accept | All dependencies already present |

## Self-Check: PASSED

Files verified:
- lib/features/home/home_screen.dart — FOUND
- lib/main.dart — FOUND (updated)
- lib/app/router.dart — FOUND (updated)

Commits verified:
- c9835c1 — FOUND (feat(04-04): HomeScreen with week strip, ride cards, skeleton loading)
- 7db99e3 — FOUND (feat(04-04): wire MaterialApp.router + routerProvider in main.dart)
