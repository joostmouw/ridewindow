---
phase: quick-260714-rrx
plan: 01
subsystem: ui
tags: [flutter, riverpod, l10n, alert-dialog, material3]

requires:
  - phase: quick-260714-qor
    provides: "Reactive Planned/Plan ride button state on Ride Detail's pinned bottom bar"
provides:
  - showUnplanConfirmDialog(BuildContext) -> Future<bool> reusable AlertDialog helper
  - Unplan capability from Ride Detail's "Planned" button (was display-only, now removes via confirm dialog)
  - Delete icon on Home's planned-rides row (alongside existing tap-to-open navigation)
affects: [ride-detail-screen, home-screen, planned-rides-flow]

tech-stack:
  added: []
  patterns:
    - "Shared confirm-dialog-only helper (no side effects baked in) — each call site owns its own remove()+SnackBar logic since the two screens differ slightly (reconstruct PlannedRide vs. use the existing instance)"

key-files:
  created:
    - lib/features/shared/unplan_confirm_dialog.dart
  modified:
    - lib/features/detail/ride_detail_screen.dart
    - lib/features/home/home_screen.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_nl.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_en.dart
    - lib/l10n/app_localizations_nl.dart

key-decisions:
  - "One shared dialog-only helper, not a shared remove+notify helper — the two call sites' side effects differ enough (Ride Detail reconstructs a PlannedRide from _effectiveSlot; Home already holds the exact instance) that forcing them into one helper would require threading WidgetRef through a UI-only widget"
  - "Reused existing 'cancel' and 'rideRemoved' l10n strings unchanged; only added the 3 new confirm-dialog-specific strings (title/message/action)"

patterns-established:
  - "Destructive action from a casual tap target (button/list row, as opposed to a deliberate swipe) gets a short AlertDialog confirm — mirrors this app's existing swipe/bottom-sheet delete pattern's intent without copying its exact UX"

requirements-completed: []

duration: ~25min
completed: 2026-07-14
---

# Phase quick-260714-rrx: Unplan Ride from Detail + Home Summary

**Ride Detail's "Planned" button and a new delete icon on Home's planned-rides row both open a shared confirm dialog and, on confirm, remove the ride via the existing plannedRidesProvider.remove() and show the existing "Ride removed" SnackBar.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3 automated tasks completed (4th task in the plan is a blocking human-verify checkpoint, intentionally left for the user)
- **Files modified:** 8 (1 new, 7 modified)

## Accomplishments
- New `lib/features/shared/unplan_confirm_dialog.dart` — `showUnplanConfirmDialog(BuildContext) -> Future<bool>`, MD3 `AlertDialog` with Cancel + error-colored destructive action
- Ride Detail's "Planned" `OutlinedButton.icon` (previously `onPressed: null`, built in quick-260714-qor) now opens the confirm dialog and removes the ride on confirm — button reactively flips back to green "Plan ride" afterward
- Home's `_buildPlannedRidesSliver` row gains a `delete_outline` IconButton alongside the `ScoreBadge`, using the same dialog + `.remove(ride)` + SnackBar, without disturbing the row's existing tap-to-open-detail navigation
- 3 new EN/NL l10n strings (`unplanConfirmTitle`, `unplanConfirmMessage`, `unplanConfirmAction`); existing `cancel`/`rideRemoved` strings reused unchanged

## Task Commits

1. **Task 1: Add l10n strings for the unplan confirm dialog** - `441ff0e` (feat)
2. **Task 2: Create shared confirm dialog and wire it into Ride Detail's Planned button** - `376d21e` (feat)
3. **Task 3: Add delete icon to Home's planned-ride row using the shared dialog** - `5ce3e6e` (feat)

**Plan metadata:** (this commit, following SUMMARY/STATE update)

## Files Created/Modified
- `lib/features/shared/unplan_confirm_dialog.dart` - New reusable confirm-dialog helper
- `lib/features/detail/ride_detail_screen.dart` - "Planned" button `onPressed` now awaits the dialog and calls `remove()`
- `lib/features/home/home_screen.dart` - New delete `IconButton` on each planned-ride row
- `lib/l10n/app_en.arb` / `app_nl.arb` - 3 new confirm-dialog strings
- `lib/l10n/app_localizations.dart` / `app_localizations_en.dart` / `app_localizations_nl.dart` - Regenerated via `flutter gen-l10n`

## Decisions Made
- Dialog-only sharing (not remove+notify sharing) — see `key-decisions` above
- `home_screen.dart`'s new `IconButton.onPressed` guards the post-remove `ScaffoldMessenger` call with the State's own `mounted` getter (not `context.mounted`), matching this file's existing convention (`if (mounted) _controller.forward();`) since the enclosing method has no `context` parameter of its own — functionally identical to `ride_detail_screen.dart`'s `context.mounted` guard, just matching local file convention

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Lint cleanliness] Used `mounted` instead of `context.mounted` in home_screen.dart**
- **Found during:** Task 3 implementation
- **Issue:** `context.mounted` triggered a new `use_build_context_synchronously`-adjacent lint in this method (no local `context` parameter, unlike `ride_detail_screen.dart`'s `_buildPlanRideBar(BuildContext context)`)
- **Fix:** Used the State's own `mounted` getter instead, matching existing usage elsewhere in the same file
- **Files modified:** `lib/features/home/home_screen.dart`
- **Verification:** `flutter analyze` reports no new issues
- **Committed in:** `5ce3e6e` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (lint-cleanliness only, no behavior change)
**Impact on plan:** None — functionally identical guard, just matching local file convention.

## Issues Encountered
None beyond the deviation above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness

Backlog follow-up (unplan from Ride Detail + Home) is implemented and pending the plan's blocking human-verify checkpoint (Task 4). `planned_rides_screen.dart`'s existing Dismissible swipe-to-delete and bottom-sheet delete button were not touched.

---
*Phase: quick-260714-rrx*
*Completed: 2026-07-14*

## Self-Check: PASSED

All created/modified files verified present; all task commit hashes (`441ff0e`, `376d21e`, `5ce3e6e`) verified present in `git log`.
