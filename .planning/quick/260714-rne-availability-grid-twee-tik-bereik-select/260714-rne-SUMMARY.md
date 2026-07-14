---
phase: quick-260714-rne
plan: 01
subsystem: availability-screen
tags: [availability, gesture, two-tap, range-select, l10n, bottom-sheet]
requires: []
provides:
  - computeRangeFillKeys pure day-scoped range-fill helper
  - two-tap range-select state machine (_pendingAnchor) on the Availability grid
  - long-press cell-info bottom sheet
  - reactive "N losse tijdvakken" counter bar (drag OR pending-anchor states)
affects:
  - lib/features/availability/availability_screen.dart
tech-stack:
  added: []
  patterns:
    - "Pure domain helper (computeRangeFillKeys) kept separate from widget state, following the existing drag_run_counter.dart precedent"
    - "domain→providers import direction (BlockType enum) — same accepted pattern as availability_filter.dart"
key-files:
  created:
    - lib/domain/services/range_fill.dart
    - test/domain/services/range_fill_test.dart
  modified:
    - lib/features/availability/availability_screen.dart
    - test/features/availability_screen_test.dart
    - lib/l10n/app_nl.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_en.dart
    - lib/l10n/app_localizations_nl.dart
decisions:
  - "Test-only fix: legend always shows 'Vrij' (legendFree), colliding with the bottom-sheet's free-cell status text of the same string — disambiguated the Test 1 long-press assertion by matching Text.style.fontSize == 16.0 (bodyLarge, the bottom sheet's style) instead of a bare find.text('Vrij') match, rather than changing production copy."
metrics:
  duration: ~45min
  completed: 2026-07-14
---

# Quick Task 260714-rne: Availability grid two-tap range-select Summary

Two-tap range-selection model for the Availability screen's 7×24 grid (open a pending block on first tap, fill-and-close on a second same-day tap, cancel on re-tap, cross-day close-and-reopen), plus a long-press cell-info bottom sheet and a day-scoped reactive selection counter — all coexisting with the pre-existing drag-to-select gesture.

## What Was Built

**Task 1 — Pure day-scoped range-fill helper** (`lib/domain/services/range_fill.dart`): `computeRangeFillKeys({anchorKey, secondTapKey, blockedHours})` returns the inclusive, ascending-hour-ordered list of keys between two same-day taps, skipping `BlockType.work`/`BlockType.calendar` hours (gap preserved, never overwritten) while including already-`BlockType.custom` hours. 6 unit tests cover ascending/descending tap order, single-hour range, work-skip, calendar-skip, and already-custom-included. TDD RED (`63e0098`) → GREEN (`2de65bb`).

**Task 2 — Two-tap state machine** (`lib/features/availability/availability_screen.dart`): added `DateTime? _pendingAnchor` field and rewrote `_onCellTap` as a state machine implementing all 7 design points from the plan (open-anchor, same-day fill-and-close, re-tap-cancel, non-anchor-toggle-off-leaves-block-open, cross-day close-and-reopen, blocked-cell no-op regardless of anchor state, closed-block-always-followed-by-new-independent-anchor). `_buildCell` now renders a 2px `Theme.of(context).colorScheme.primary` border on the anchor cell. `_buildDragIndicatorBar` now also shows during an open pending anchor (not only `_isDragging`), with the count scoped to the anchor's own calendar day via `countSelectionRuns` on a day-filtered subset of `blockedHours` — never the whole week's persisted selections. 8 widget tests cover every design point plus the day-scoped counter correctness against a "dirty" multi-day grid. TDD RED (`258c9f3`) → GREEN (`e5a3683`). The existing drag gesture (`_onDragStart`/`_onDragUpdate`/`_onDragEnd`) is untouched.

**Task 3 — Long-press cell-info bottom sheet** (`lib/features/availability/availability_screen.dart`, `lib/l10n/app_nl.arb`, `lib/l10n/app_en.arb`): added `cellInfoStatusWork`/`cellInfoStatusCalendar`/`cellInfoStatusCustom`/`cellInfoStatusFree` NL/EN l10n strings, regenerated via `flutter gen-l10n`. Implemented `_showCellInfo`, wired to `onLongPress` on each cell's `GestureDetector`, showing a `showModalBottomSheet` with day name (localized via `intl` `DateFormat('EEEE', locale)`, capitalized) + hour range + status label. 4 widget tests cover free/work/custom/calendar status text. TDD RED (`fec606c`) → GREEN (`031ef97`).

## Deviations from Plan

### Auto-fixed Issues

None — all three automated tasks were implemented exactly as specified in the plan's `<action>` blocks. The `_showCellInfo` stub-then-implement split across Task 2/Task 3 (per the plan's explicit instruction) was followed as written, not a deviation.

### Test-authoring corrections (not production-code deviations)

1. **Legend-collision disambiguation in Task 3's Test 1** — the Availability screen's legend row always shows "Vrij" (`legendFree`, unconditional `_legendItem`), which collided with the bottom sheet's free-cell status text of the identical string, causing `find.text('Vrij')` to match 2 widgets instead of 1. Fixed by matching on `Text.style.fontSize == 16.0` (the bottom sheet's `bodyLarge` style, distinct from the legend's `bodySmall` at 12.0) instead of a bare text match. This is a test-file-only correction; no production code was changed as a result.
2. **Custom/work-color test finders scoped to exclude legend swatches** — the 14×14 legend color swatches (`BorderRadius.circular(3)`) share the exact same `Color(0xFFFF9800)`/`Color(0xFFB0BEC5)` values as grid cells, so the widget tests' `customColorFinder()`/`workColorFinder()` helpers additionally check `decoration.borderRadius == null` to match only actual grid cells (which have no border radius), not the legend.

## Pre-existing Test Failures (out of scope)

11 pre-existing tests in `test/features/availability_screen_test.dart` (SC-1 through P04-5) fail due to `S.of(context)` throwing a null-check error — these tests use a bare `MaterialApp(home: AvailabilityScreen())` without `S.localizationsDelegates`/`S.supportedLocales`, which the screen's `S.of(context).availabilityTitle` call (pre-existing code, unrelated to this task) requires. Verified via `git stash` that this failure exists identically at the pre-task baseline commit (`5ce3e6e`), confirming it is not caused by any change in this plan. This matches the already-documented "test-suite health finding on #11" note referenced in STATE.md's recent commit history (`11da756`). Not fixed here per the scope-boundary rule (only auto-fix issues directly caused by this task's own changes).

## Verification

- `flutter test test/domain/services/range_fill_test.dart` — 6/6 pass
- `flutter analyze lib/domain/services/range_fill.dart` — 0 issues
- `flutter test test/features/availability_screen_test.dart` — all 13 new/existing tests introduced or touched by this plan pass (1 BACKLOG-35 + 8 two-tap + 4 long-press); the 11 pre-existing unrelated failures noted above are untouched by this plan
- `flutter analyze lib/features/availability/availability_screen.dart lib/l10n/app_localizations.dart` — 2 pre-existing info-level issues only (identical at baseline, confirmed via `git stash` diff), 0 new issues
- `flutter analyze` (whole repo) — 0 new issues in any file touched by this plan
- `flutter gen-l10n` — ran clean, `S` exposes all 4 new `cellInfoStatus*` getters in both generated locale files

## Known Stubs

None.

## Threat Flags

None — this plan's threat model (`T-quick260714rne-01` through `-04`) is fully covered by the implementation: `computeRangeFillKeys`'s work/calendar skip logic is unit-tested (Task 1, Tests 4-5); the `_pendingAnchor` state machine's edge cases are widget-tested (Task 2, Tests 4-8); no new persisted data format or network surface was introduced.

## Status: Paused at Checkpoint

Tasks 1-3 (all automated work) are complete and committed. The plan's final task is `checkpoint:human-verify` (gate="blocking") requiring real-device touch-gesture verification (drag-vs-tap coexistence, cross-day close/reopen, interleaved drag-during-pending-anchor, long-press timing) that cannot be cheaply proven by simulated widget tests. Per execution constraints, this checkpoint is left for the human to resolve — no attempt was made to auto-approve or bypass it.

## Self-Check: PASSED

All claimed files and commits verified to exist:
- FOUND: lib/domain/services/range_fill.dart
- FOUND: test/domain/services/range_fill_test.dart
- FOUND: _pendingAnchor in lib/features/availability/availability_screen.dart
- FOUND: cellInfoStatusFree in lib/l10n/app_nl.arb
- FOUND: cellInfoStatusFree in lib/l10n/app_en.arb
- FOUND: commit 63e0098 (test: RED computeRangeFillKeys)
- FOUND: commit 2de65bb (feat: GREEN computeRangeFillKeys)
- FOUND: commit 258c9f3 (test: RED two-tap state machine)
- FOUND: commit e5a3683 (feat: GREEN two-tap state machine)
- FOUND: commit fec606c (test: RED long-press cell-info)
- FOUND: commit 031ef97 (feat: GREEN long-press cell-info + l10n)
