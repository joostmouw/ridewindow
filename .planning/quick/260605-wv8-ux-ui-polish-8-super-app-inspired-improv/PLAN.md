---
id: 260605-wv8
slug: ux-ui-polish-8-super-app-inspired-improv
description: "UX/UI polish -- 8 super-app inspired improvements"
status: complete
created: 2026-06-05
---

# Quick Task: UX/UI Polish -- 8 Super-App Inspired Improvements

## Goal

Improve RideWindow's UX and UI with patterns commonly found in top-tier apps (Strava, Buienradar, Dark Sky, Uber) to make the app feel polished and premium before internal testing release.

## Tasks

### Wave 1 (independent)

- [x] **T1: Fix "Plan het" button** — Replace placeholder SnackBar in HomeScreen with real `CalendarService.addRideSlotToCalendar()` call (Phase 9 was already complete)
- [x] **T2: Pull-to-refresh** — Wrap HomeScreen cards section in `RefreshIndicator`, add `AlwaysScrollableScrollPhysics` to all scrollable states (empty, error, list)
- [x] **T3: Hero animation on ScoreBadge** — Add optional `heroTag` to ScoreBadge, pass through DetailArgs and router for smooth card-to-detail transition
- [x] **T4: Haptic feedback** — Add `HapticFeedback.lightImpact()` to week strip taps, ride card taps, chip toggles, availability cell taps

### Wave 2 (independent)

- [x] **T5: "Beste keuze" highlight** — First/best slot gets gradient background (green-to-white), enhanced shadow, and "Beste keuze" label chip
- [x] **T6: Animated weather icons** — New `WeatherIcon` widget with per-tier animations (rotating sun for Perfect, drifting clouds for Great/Acceptable, bouncing rain for Poor)
- [x] **T7: Swipe-to-calendar** — Wrap ride cards in `Dismissible` (swipe right = add to Google Calendar with green background + icon feedback)
- [x] **T8: Share function** — Add `share_plus` dependency, share button on RideDetailScreen with formatted ride slot text via native share sheet

## Files Modified

- `lib/features/home/home_screen.dart` — T1, T2, T3, T4, T5, T6, T7
- `lib/features/detail/ride_detail_screen.dart` — T3, T8
- `lib/features/detail/detail_args.dart` — T3
- `lib/features/shared/score_badge.dart` — T3
- `lib/features/shared/weather_icon.dart` — T6 (new file)
- `lib/features/profile/profile_screen.dart` — T4
- `lib/features/availability/availability_screen.dart` — T4
- `lib/app/router.dart` — T3
- `pubspec.yaml` — T8 (share_plus dependency)

## Commit

`ca6f0f8` — feat: UX/UI polish — 8 improvements inspired by super apps
