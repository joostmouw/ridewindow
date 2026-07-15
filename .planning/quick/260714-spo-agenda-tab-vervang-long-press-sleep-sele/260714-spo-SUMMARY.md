---
phase: quick-260714-spo
plan: 01
subsystem: ui
tags: [flutter, riverpod, widget-tests, gesture, agenda, l10n]

# Dependency graph
requires:
  - phase: quick-260714-rne
    provides: "Availability screen's two-tap range-select precedent (tap=select / long-press=info gesture model)"
provides:
  - "Agenda screen tap-based range-selection state machine (_onCellTap), replacing long-press-and-drag"
  - "Long-press on any Agenda cell reliably opens the weather-detail bottom sheet"
  - "Baseline widget-test coverage for WeekAgendaScreen (previously untested screen)"
  - "Updated EN/NL hint copy describing long-press-for-info + tap-twice-for-range"
affects: [agenda, availability]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tap-based range-selection state machine with a fixed `_anchorHour` (recompute-against-original-anchor, not current range edge) — same pattern as the sibling Availability screen's two-tap model, adapted for Agenda's single-open-selection + explicit-commit-button UX"
    - "ValueKey('cell_${di}_$hour') per-cell identity keys replace GlobalKey-map-based drag hit-testing once cross-cell drag gestures are removed"

key-files:
  created:
    - test/features/week_agenda_screen_test.dart
    - .planning/quick/260714-spo-agenda-tab-vervang-long-press-sleep-sele/deferred-items.md
  modified:
    - lib/features/agenda/week_agenda_screen.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_nl.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_en.dart
    - lib/l10n/app_localizations_nl.dart

key-decisions:
  - "_anchorHour tracked separately from _Selection.startHour/endHour so repeated same-day taps always recompute against the ORIGINAL anchor, allowing the range to grow or shrink back (not just grow) across multiple taps before commit"
  - "Blocked/planned-cell no-op guard moved from the grid wiring (onTap: _selection != null ? _clearSelection : null) into _onCellTap itself, so it applies unconditionally regardless of whether a selection is active"
  - "_CellWidget.onTap changed from optional (nullable, used as a long-press-fallback signal) to required — onTap and onLongPress are now two always-wired, independent callbacks"
  - "Task 2's test suite validates Task 1's already-implemented state machine (test-after, not strict test-first) — matches the plan's own two-task structure (implementation task, then dedicated coverage task) rather than canonical RED-before-GREEN"

patterns-established:
  - "Fixed-anchor tap-range-select: track the original anchor hour separately from the mutable selection range so later taps always recompute against the same fixed reference point"

requirements-completed: [SPO-01, SPO-02, SPO-03, SPO-04]

# Metrics
duration: ~35min
completed: 2026-07-15
---

# Quick Task 260714-spo: Agenda tap-to-select gesture parity Summary

**Replaced Agenda's long-press-and-drag range-selection with a two-tap fixed-anchor model, and long-press now always opens the weather-detail sheet — full gesture parity with the sibling Availability screen, plus new baseline widget-test coverage for a previously-untested screen.**

## Performance

- **Duration:** ~35 min
- **Tasks:** 2 automated tasks completed (Task 1: implementation, Task 2: test suite); Task 3 is a `checkpoint:human-verify` awaiting the user
- **Files modified:** 6 (1 screen file + 5 l10n files, 3 of them generated)
- **Files created:** 1 test file + 1 deferred-items note

## Accomplishments

- Rewrote `_WeekAgendaScreenState`'s selection logic as a tap-based state machine (`_onCellTap`) implementing all 6 locked tap-behavior rules: open-anchor, same-day recompute-against-fixed-anchor (grow AND shrink), cancel-on-anchor-retap, cross-day discard-and-restart, and a complete no-op guard for blocked/planned cells.
- Removed all dead long-press-drag infrastructure: `_cellKeys`, `_dragStartHour`, `_dragDayIndex`, `_keyFor`, `_cellAt`, `_onLongPressStart`, `_onLongPressMoveUpdate`, `_onLongPressEnd` — verified absent via grep.
- `_CellWidget` now always wires both `onTap` (required) and `onLongPress` (always triggers `_showDetail`, regardless of selection/blocked/planned state) — long-press is now a reliable weather-detail affordance on every cell.
- Grid wrapper simplified from a drag-tracking `GestureDetector` to a plain `KeyedSubtree` (still carrying `_gridKey` for the hint-overlay spotlight).
- Updated EN/NL hint copy (`hintTapWeatherDetail(Desc)`/`hintDragSelect(Desc)`) to describe the new gestures; regenerated l10n via `flutter gen-l10n`.
- Added `test/features/week_agenda_screen_test.dart` — 7 widget tests covering all 8 locked behavior rules (2 tests jointly cover rules 2/4 per the plan's own note that rule 4 needs no special-case code beyond rule 2's logic), giving this screen its first-ever test coverage.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite tap-based state machine, remove dead drag-select code, retarget long-press, update hint copy** - `de9e44d` (feat)
2. **Task 2: Widget test suite establishing baseline coverage for all 8 locked behavior rules** - `52495b9` (test)

**Plan metadata:** not yet committed — orchestrator handles the docs commit (SUMMARY.md, STATE.md) after this executor returns.

_Note: Both tasks carried `tdd="true"` in the plan, but the plan's own structure sequences implementation (Task 1) before the validating test suite (Task 2) rather than canonical test-first RED-then-GREEN — see "TDD Gate Compliance" below._

## Files Created/Modified

- `lib/features/agenda/week_agenda_screen.dart` - New `_onCellTap` tap state machine + `_anchorHour` field; removed all drag-gesture dead code; `_CellWidget.onTap` required, `onLongPress` always wired to `_showDetail`; grid wrapped in `KeyedSubtree` instead of a drag `GestureDetector`; per-cell `ValueKey('cell_${di}_$hour')` identity keys.
- `lib/l10n/app_en.arb` / `lib/l10n/app_nl.arb` - Updated `hintTapWeatherDetail(Desc)`/`hintDragSelect(Desc)` copy for long-press-for-info + tap-twice-for-range.
- `lib/l10n/app_localizations.dart` / `_en.dart` / `_nl.dart` - Regenerated via `flutter gen-l10n` (do not hand-edit).
- `test/features/week_agenda_screen_test.dart` - New widget test suite (7 tests) with fake notifiers mirroring `home_screen_refresh_test.dart`'s pattern, plus a `FakePlannedRidesNotifier` that fakes `add()` to avoid touching `SharedPreferences`.
- `.planning/quick/260714-spo-agenda-tab-vervang-long-press-sleep-sele/deferred-items.md` - Notes a pre-existing, already-tracked whole-suite test-isolation issue discovered while running the full `flutter test` suite (not caused by this plan).

## Decisions Made

- `_anchorHour` is a separate field from `_Selection.startHour`/`endHour` specifically so repeated same-day taps always recompute against the fixed original anchor (not the current range's own edge) — required for the shrink-back behavior in Rule 2/4.
- The blocked/planned no-op guard (Rule 6) now lives as the first check inside `_onCellTap`, applying unconditionally rather than being expressed via conditional `onTap` wiring at the call site.
- `_CellWidget.onTap` changed from optional-with-long-press-fallback to required-and-separate-from-`onLongPress`, since every cell now needs both callbacks simultaneously (previously only one of the two could ever fire per cell).

## Deviations from Plan

None — plan executed exactly as written. `flutter gen-l10n`, `flutter analyze`, the dead-code-absence grep, and `flutter test test/features/week_agenda_screen_test.dart` all passed on the first attempt for both tasks; no auto-fixes (Rules 1-3) were needed.

## TDD Gate Compliance

Both tasks in the plan are marked `tdd="true"`, but the plan's own task ordering places the implementation (Task 1, `feat` commit `de9e44d`) BEFORE the dedicated test suite (Task 2, `test` commit `52495b9`) — the reverse of canonical RED-then-GREEN. This is a deliberate plan-level structure (Task 1's own `<verify>`/`<done>` explicitly defer behavioral proof to Task 2's test suite; Task 2's `<action>` only creates the test file, with no further implementation step), not an executor deviation. All 7 tests in Task 2 passed on first run against Task 1's already-committed implementation — no GREEN-phase implementation changes were required for Task 2. Flagging here per the TDD gate-sequence check since a strict `test(...)` → `feat(...)` commit order was not produced.

## Issues Encountered

Running the full `flutter test` (whole repo, no path) surfaces 69 pre-existing failures across ~20 unrelated test files — a known, already-tracked test-suite health issue (see STATE.md: "note test-suite health finding on #11"), not caused by this plan. Verified `test/features/week_agenda_screen_test.dart` passes cleanly both in isolation and as part of the full-suite run (zero failures attributable to this file). Documented in `deferred-items.md`; not fixed (out of scope for this plan's Agenda gesture rewrite).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Tasks 1 and 2 are complete, committed, and verified. Task 3 is a `checkpoint:human-verify` (gate="blocking") requiring the user to manually verify the real-touch gesture feel on a device/emulator per the plan's 10-step verification checklist — this executor stops here and does not attempt to resolve that checkpoint.
- No blockers for merging once the human-verify checkpoint is approved.

---
*Quick task: 260714-spo*
*Completed: 2026-07-15*

## Self-Check: PASSED

- FOUND: lib/features/agenda/week_agenda_screen.dart
- FOUND: test/features/week_agenda_screen_test.dart
- FOUND: lib/l10n/app_en.arb
- FOUND: lib/l10n/app_nl.arb
- FOUND: .planning/quick/260714-spo-agenda-tab-vervang-long-press-sleep-sele/260714-spo-SUMMARY.md
- FOUND: .planning/quick/260714-spo-agenda-tab-vervang-long-press-sleep-sele/deferred-items.md
- FOUND commit: de9e44d (feat: rewrite Agenda tap state machine)
- FOUND commit: 52495b9 (test: widget test suite)
