---
phase: quick-260714-rne
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [lib/domain/services/range_fill.dart, test/domain/services/range_fill_test.dart, lib/features/availability/availability_screen.dart, test/features/availability_screen_test.dart, lib/l10n/app_en.arb, lib/l10n/app_nl.arb, lib/l10n/app_localizations.dart, lib/l10n/app_localizations_en.dart, lib/l10n/app_localizations_nl.dart]
autonomous: false
requirements: [RNE-01, RNE-02, RNE-03, RNE-04]

must_haves:
  truths:
    - "First tap on an empty (not blocked, not yet custom) hour selects that hour AND opens a pending block anchored on it, shown with a visible accent-border indicator on that cell"
    - "Second tap on a DIFFERENT empty hour, SAME calendar day, while a block is open, fills all empty/custom-toggleable hours between anchor and second tap (inclusive of both ends) and closes the block — work/calendar-blocked hours in between are skipped, not overwritten"
    - "Second tap on the SAME hour as the open anchor cancels the pending block entirely (that hour reverts to empty), anchor resets to null"
    - "Tapping an hour that is already custom-selected (not the anchor) toggles it off via existing behavior and leaves any other open block untouched"
    - "Second tap on a DIFFERENT day than the anchor closes the old anchor's block as a standalone 1-hour block (no cross-day fill) and the new tap becomes the anchor of a new block on the new day"
    - "Tapping a work/calendar-blocked cell remains a no-op regardless of any open pending block"
    - "The existing drag-to-select gesture (_onDragStart/_onDragUpdate/_onDragEnd) continues to work completely unchanged, coexisting with the two-tap model"
    - "Long-pressing any cell shows a bottom sheet with day name + hour range + a status label (Werk-geblokkeerd / Agenda-geblokkeerd / Beschikbaar gezet / Vrij)"
    - "The live 'N losse tijdvakken' counter bar is visible and reactive both while dragging AND while a pending anchor block is open (not only during _isDragging), reflecting the true count of separate selected blocks derived from real selected hours, scoped to the anchor's own calendar day when a pending anchor is open (not the whole week's persisted blockedHours)"
  artifacts:
    - path: "lib/domain/services/range_fill.dart"
      provides: "computeRangeFillKeys(...) pure function — day-scoped inclusive hour-range fill, skipping work/calendar-blocked hours"
      contains: "List<DateTime> computeRangeFillKeys"
    - path: "test/domain/services/range_fill_test.dart"
      provides: "unit tests for computeRangeFillKeys covering ascending/descending taps, single-hour range, work-skip, calendar-skip, already-custom-included"
      contains: "computeRangeFillKeys"
    - path: "lib/features/availability/availability_screen.dart"
      provides: "_pendingAnchor state field, rewritten _onCellTap two-tap state machine, pending-anchor cell border, reactive counter bar, long-press info bottom sheet"
      contains: "_pendingAnchor"
    - path: "lib/l10n/app_nl.arb"
      provides: "cellInfoStatusWork/cellInfoStatusCalendar/cellInfoStatusCustom/cellInfoStatusFree strings (NL, template file)"
      contains: "cellInfoStatusFree"
    - path: "lib/l10n/app_en.arb"
      provides: "matching EN strings for the four cell-info status labels"
      contains: "cellInfoStatusFree"
  key_links:
    - from: "lib/features/availability/availability_screen.dart _onCellTap"
      to: "lib/domain/services/range_fill.dart computeRangeFillKeys"
      via: "import + call when closing a same-day pending block"
      pattern: "computeRangeFillKeys\\("
    - from: "lib/features/availability/availability_screen.dart _buildCell"
      to: "_pendingAnchor"
      via: "conditional Border.all(color: primary, width: 2) when key == _pendingAnchor"
      pattern: "_pendingAnchor == key"
    - from: "lib/features/availability/availability_screen.dart cell GestureDetector"
      to: "_showCellInfo"
      via: "onLongPress wiring on the per-cell GestureDetector"
      pattern: "onLongPress:.*_showCellInfo"
    - from: "lib/features/availability/availability_screen.dart _buildDragIndicatorBar"
      to: "countSelectionRuns"
      via: "when not dragging but a pending anchor is open, counts ONLY custom-type entries on the anchor's own calendar day (day-scoped, matching countSelectionRuns' internal day-grouping semantics and mirroring the day-scoped _draggedCells path) — never the whole week's blockedHours, which would wrongly aggregate pre-existing selections on other days"
      pattern: "_pendingAnchor!\\.day"
---

<objective>
Add a two-tap range-selection model to the Availability screen's 7×24 grid, coexisting with the existing drag-to-select gesture (do not remove or regress `_onDragStart`/`_onDragUpdate`/`_onDragEnd`):

1. First tap on an empty hour selects it and opens a "pending block" anchored on that hour.
2. Second tap on a different empty hour, same day, fills every empty/custom-toggleable hour between the two (inclusive), skipping work/calendar-blocked hours in the gap, and closes the block.
3. After a block closes, the next tap on an empty hour starts a brand-new separate block — this is what lets a user create 2 separate ride windows on the same day (e.g. 9–11 and, separately, 15–17) instead of everything merging forever.
4. Tapping an already-selected (custom) hour always toggles it off (existing behavior), regardless of whether a block is open; this may leave a block "unfinished" — that's fine, it stays open.
5. Re-tapping the anchor hour itself cancels the pending block entirely (that hour reverts to empty).
6. Tapping a work/calendar-blocked cell remains a no-op, unaffected by any open block.
7. A second tap on a DIFFERENT day than the anchor closes the old block as a standalone 1-hour block (no cross-day fill, day-scoped like `countSelectionRuns`) and the new tap opens a fresh block on the new day.
8. The existing drag gesture keeps working unchanged alongside this.
9. Long-press on any cell shows an info bottom sheet: day + hour range + status (Werk-geblokkeerd / Agenda-geblokkeerd / Beschikbaar gezet / Vrij) — structurally modeled on `week_agenda_screen.dart`'s `_showDetail`, minus weather (this grid has none).
10. A visible "pending block open" indicator (accent border on the anchor cell) per MD3 conventions.
11. The existing live "N losse tijdvakken" counter bar (`_buildDragIndicatorBar`, built in quick-260714-o54) becomes visible/reactive when a pending anchor is open too (not only `_isDragging`), reflecting the real selected-hours count, scoped to the anchor's own calendar day.

Purpose: Make multi-block same-day availability editing (e.g. two separate windows in one day) fast and discoverable via tap, without regressing the existing drag flow, and give users a way to inspect any cell's status without altering it.
Output: New pure `computeRangeFillKeys` helper + unit tests; rewritten `_onCellTap` state machine in `availability_screen.dart`; pending-anchor visual indicator; long-press info bottom sheet; reactive counter bar; new NL/EN l10n strings; widget tests.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

<interfaces>
<!-- Confirmed by reading the actual files (not assumed). -->

**Current `_AvailabilityScreenState` fields** (`lib/features/availability/availability_screen.dart`): `bool _isDragging`, `bool _dragBlocking`, `final Set<DateTime> _draggedCells`. This plan adds one new field: `DateTime? _pendingAnchor` (null = no open block).

**`_cellKey(weekStart, dayIndex, hour)`** returns `DateTime.utc(weekStart.year, weekStart.month, weekStart.day + dayIndex, hour)` — distinct calendar days always have distinct `.day` values (never wraps within a displayed week); the hour component is the literal 0–23 hour.

**Current `_onCellTap(DateTime key, Map<DateTime, BlockType> blocked)`** (~line 517): guards `blocked[key] == BlockType.work || blocked[key] == BlockType.calendar` (return, no-op), otherwise calls `HapticFeedback.lightImpact()` then `ref.read(availabilityProvider.notifier).toggleCustomHour(key)`. This whole method is rewritten by Task 2 below; the work/calendar guard is preserved verbatim as the first line.

**`AvailabilityNotifier`** (`lib/providers/availability_notifier.dart`): `Future<void> toggleCustomHour(DateTime hour)` — toggles a single hour between absent and `BlockType.custom`. `Future<void> setCustomHours(List<DateTime> hours, {required bool block})` — batch-sets (`block: true` → `BlockType.custom` for any hour not already `work`/`calendar`) or batch-clears (`block: false` → removes only `custom` entries). Both persist via `_persist` and update `state = AsyncData(next)`. `enum BlockType { work, custom, calendar }`.

**`_buildCell`** (~line 218): builds a `GestureDetector(onTap: () => _onCellTap(key, blockedHours), child: Container(...))` per cell — no `onLongPress` yet. `_cellColor` (~line 494) switches on `blocked[key]` to pick `rw.availWork` / `rw.availCustom` / `rw.availCalendar` / surface color; drag-highlight is a separate `isDragHighlighted` param computed from `_isDragging && _draggedCells.contains(key)` — untouched by this plan.

**`_buildDragIndicatorBar(BuildContext context)`** (~line 245) currently takes only `context`, checks `!_isDragging` to decide whether to render `SizedBox.shrink()` vs. the icon+text row, and computes `S.of(context).dragRunsSelected(countSelectionRuns(_draggedCells))`. It is called as `_buildDragIndicatorBar(context)` inside `_buildGrid`'s `Column` (first child, ~line 119), where `blockedHours` is already in scope as a parameter of `_buildGrid`.

**`countSelectionRuns(Set<DateTime> cells)`** (`lib/domain/services/drag_run_counter.dart`) — pure, already tested (7 cases). Groups by calendar day (year/month/day), counts maximal same-day consecutive-hour runs. Reused as-is (no changes) for the pending-anchor-open counter path, called on `{for (final e in blockedHours.entries) if (e.value == BlockType.custom && e.key.year == _pendingAnchor!.year && e.key.month == _pendingAnchor!.month && e.key.day == _pendingAnchor!.day) e.key}` — day-scoped to the anchor's own calendar day only (never the whole week's blockedHours, which would wrongly aggregate pre-existing selections on other days) — instead of `_draggedCells`.

**domain→providers import precedent**: `lib/domain/services/availability_filter.dart` already imports `package:ridewindow/providers/availability_notifier.dart` for the `BlockType` enum (accepted pattern per STATE.md 04-01 decision — not a new precedent). `range_fill.dart` follows the same pattern.

**`week_agenda_screen.dart` `_showDetail`** (~line 570): `showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [...]))))`. Day name formatted via `DateFormat('EEEE d MMMM', locale)` where `locale = Localizations.localeOf(context).languageCode == 'en' ? 'en_US' : 'nl_NL'` (`package:intl/intl.dart`, already a pubspec dependency). This grid's new `_showCellInfo` reuses the `showModalBottomSheet` + `Padding` + `Column` shape and the locale-detection line, but needs only day-name + hour-range + status text (no forecast/score rows — this screen has no weather data).

**l10n pattern** — `S.of(context)` from `package:ridewindow/l10n/app_localizations.dart`, generated by `flutter gen-l10n` (NOT hand-edited). `l10n.yaml`: `template-arb-file: app_nl.arb` (NL carries `@key` metadata blocks where placeholders exist; `app_en.arb` mirrors keys, no metadata needed for plain strings — see `legendFree`/`legendBusy`/`legendWork` as the precedent for plain-string entries with no `@` block in either file). After editing the ARB files, run `flutter gen-l10n` to regenerate the three generated files (all three are committed to git, confirmed via `git log`).

**MD3 pending-indicator convention**: this app has no existing "isSelected" cell border in `availability_screen.dart` itself, but `week_agenda_screen.dart`'s hour-cell builder (~line 549) uses `border: isSelected ? Border.all(color: rw.tiers.perfectFg, width: 2) : ...` as its precedent for a 2px accent border marking an active in-progress selection. For the pending-anchor indicator here, use `Theme.of(context).colorScheme.primary` (not `rw.tiers.perfectFg`, which is a weather-tier color — semantically wrong for a plain "block open" indicator) at `width: 2`, replacing the existing static `Border.all(color: rw.border, width: 0.5)` conditionally.

**Existing widget test file** `test/features/availability_screen_test.dart` already establishes the exact cell-center coordinate math needed for tap/drag interaction tests at a fixed viewport (`physicalSize: Size(800, 1400)`, `devicePixelRatio: 1.0`): `cellWidth = (800 - 36) / 7`, `cellHeight = (1344 - 140 - 32 - 28) / 24`, `x = 36 + (dayIndex + 0.5) * cellWidth`, `y = 56 + 32 + 28 + (hour + 0.5) * cellHeight` (56 = AppBar height, 32 = `_dragIndicatorHeight`, 28 = `_headerHeight`, 36 = `_headerWidth`). Reuse this exact formula for all new tap/long-press tests in this plan — do not recompute independently.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Pure day-scoped range-fill helper</name>
  <files>lib/domain/services/range_fill.dart, test/domain/services/range_fill_test.dart</files>
  <behavior>
    - Test 1: anchor hour 9, second-tap hour 11, same day, no blocks in between -> returns hours [9, 10, 11] (ascending, inclusive of both ends).
    - Test 2: anchor hour 11, second-tap hour 9 (tapped in reverse/descending order), same day, no blocks -> still returns [9, 10, 11] ascending (order of the two input keys must not affect the result).
    - Test 3: anchor and second-tap are the SAME key (same hour) -> returns a single-element list containing just that hour.
    - Test 4: anchor hour 9, second-tap hour 13, with hour 11 marked `BlockType.work` in the blockedHours map -> returns [9, 10, 12, 13], excluding hour 11 (the work-blocked hour is skipped, not overwritten).
    - Test 5: same as Test 4 but hour 11 is `BlockType.calendar` instead of `BlockType.work` -> same skip behavior, returns [9, 10, 12, 13].
    - Test 6: anchor hour 9, second-tap hour 11, with hour 10 already `BlockType.custom` in the blockedHours map -> hour 10 IS included in the result (custom is toggleable, not a skip case) -> returns [9, 10, 11].
  </behavior>
  <action>
  Create `lib/domain/services/range_fill.dart` with a single top-level pure function `List<DateTime> computeRangeFillKeys({required DateTime anchorKey, required DateTime secondTapKey, required Map<DateTime, BlockType> blockedHours})`, importing `BlockType` from `package:ridewindow/providers/availability_notifier.dart` (same accepted domain→providers import direction already used in `availability_filter.dart`). Implementation: assert `anchorKey` and `secondTapKey` share the same year/month/day (this function is day-scoped only — cross-day handling is the caller's responsibility, per the locked design's day-scoped fill rule). Compute `startHour = min(anchorKey.hour, secondTapKey.hour)` and `endHour = max(anchorKey.hour, secondTapKey.hour)`. Loop `h` from `startHour` to `endHour` inclusive, construct `key = DateTime.utc(anchorKey.year, anchorKey.month, anchorKey.day, h)`, skip (do not add to the result) when `blockedHours[key] == BlockType.work || blockedHours[key] == BlockType.calendar`, otherwise add `key` to the result list. Return the result in ascending hour order. Add a doc comment explaining this is the pure fill-range logic for the two-tap range-select flow (RNE-01/RNE-02), noting it deliberately preserves work/calendar blocks rather than overwriting them.

  Create `test/domain/services/range_fill_test.dart` implementing the 6 behaviors above using `DateTime.utc(year, month, day, hour)` values, importing `package:ridewindow/domain/services/range_fill.dart` and `package:ridewindow/providers/availability_notifier.dart` (for `BlockType`), grouped under `group('computeRangeFillKeys', ...)`.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter test test/domain/services/range_fill_test.dart && flutter analyze lib/domain/services/range_fill.dart</automated>
  </verify>
  <done>
  `flutter test test/domain/services/range_fill_test.dart` passes all 6 tests. `computeRangeFillKeys` is a pure top-level function with no `BuildContext`/widget dependency. `flutter analyze` reports zero new errors/warnings.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Two-tap state machine, pending-anchor indicator, reactive counter bar</name>
  <files>lib/features/availability/availability_screen.dart, test/features/availability_screen_test.dart</files>
  <behavior>
    - Test 1: tap an empty cell (day 0, hour 1) -> that cell turns the custom color (`0xFFFF9800`) AND gains a 2px `Theme.of(context).colorScheme.primary`-colored border (pending anchor open). Tap a different empty cell on the SAME day (day 0, hour 3, no blocks in between) -> hours 1, 2, 3 on day 0 all become custom-colored, and no cell in the grid still has the 2px primary border (block closed).
    - Test 2: tap an empty cell (day 1, hour 5) to open a block (border present) -> tap that SAME cell again -> the cell reverts to the free/surface color (no longer in blockedHours) and no cell has the pending-anchor border anywhere (block canceled).
    - Test 3: after the single first tap in Test 1 (before the second tap), the counter bar (`_buildDragIndicatorBar`) shows `"1 tijdvak geselecteerd"` even though `_isDragging` is false — proving the bar's visibility/text now reacts to an open pending anchor, not only to drag state. After the second tap closes the block, the counter bar text disappears again (matches existing post-drag-end behavior).
    - Test 4: tap an empty cell (day 0, hour 9) then tap a different empty cell (day 0, hour 11) -> closes the first block (hours 9, 10, 11 custom, border gone). Tap a THIRD empty cell (day 0, hour 15) -> opens a brand-new SEPARATE anchor on the same day (border now on hour 15; hours 9-11 remain custom and untouched). Tap a fourth empty cell (day 0, hour 17) -> fills hours 15, 16, 17 and closes this second block. Assert final blockedHours contains exactly hours 9, 10, 11, 15, 16, 17 as custom on day 0, and no cell anywhere has the pending-anchor border (design point 3 — two independent same-day blocks, not one merged block).
    - Test 5: tap an empty cell (day 0, hour 2) to open a pending anchor (border present). Then tap a DIFFERENT cell on day 0 that is pre-seeded as `BlockType.work` (e.g. hour 5) -> assert this tap is a total no-op: the work cell's color/BlockType is unchanged, no fill occurs, `_pendingAnchor` is still hour 2 (border still shown on hour 2 only), and blockedHours has no new entries — proving the work/calendar-blocked no-op guard applies REGARDLESS of an open pending anchor (design point 6), not only when no anchor is open.
    - Test 6: tap an empty cell (day 0, hour 2) to open a pending anchor. Then tap an empty cell on a DIFFERENT day (day 1, hour 4) -> assert day 0 hour 2 remains custom-colored as a standalone closed 1-hour block with NO border, day 1 hour 4 becomes custom-colored AND gains the 2px pending-anchor border (the new anchor), and blockedHours contains both hours as separate custom entries (design point 7 — cross-day close-old-anchor-and-open-new-anchor transition).
    - Test 7: pre-seed day 1 with an existing standalone custom block spanning 3 hours (e.g. hours 8, 9, 10 all `BlockType.custom`, no pending anchor). Tap an empty cell on day 0 (hour 1) to open a new pending anchor there -> assert the counter bar shows `"1 tijdvak geselecteerd"` (day-0-scoped count), NOT an aggregated count reflecting day 1's pre-existing 3-hour block — proving the pending-anchor counter path is scoped to the anchor's own day, not the whole week's blockedHours.
  </behavior>
  <action>
  In `_AvailabilityScreenState`, add `DateTime? _pendingAnchor;` alongside the existing drag-state fields.

  Rewrite `_onCellTap(DateTime key, Map<DateTime, BlockType> blocked)` as a state machine (RNE-01), preserving the existing work/calendar no-op guard as the first line (per D-06 unchanged behavior) and making it apply regardless of whether `_pendingAnchor` is open (design point 6):
  1. If `blocked[key] == BlockType.work || blocked[key] == BlockType.calendar`, return (no-op, unaffected by any open `_pendingAnchor`).
  2. If `blocked[key] == BlockType.custom` (already selected): call `HapticFeedback.lightImpact()`, call `ref.read(availabilityProvider.notifier).toggleCustomHour(key)` (existing toggle-off), then if `_pendingAnchor == key`, `setState(() => _pendingAnchor = null)` (re-tapping the anchor cancels the open block — RNE-01 point 5). If the toggled-off cell is NOT the anchor, leave `_pendingAnchor` untouched (an open block may be left "unfinished" — RNE-01 point 4). Return after this branch.
  3. Otherwise the cell is empty. If `_pendingAnchor == null`: call `HapticFeedback.lightImpact()`, call `toggleCustomHour(key)`, then `setState(() => _pendingAnchor = key)` — this is the first tap opening a new block (RNE-01 point 1). This also applies after any prior block has closed: a subsequent tap on an empty hour always opens a brand-new, independent anchor (RNE-01 point 3 — e.g. two separate windows on the same day). Return.
  4. Otherwise `_pendingAnchor` holds an open anchor. Compare `anchor.year/month/day` against `key.year/month/day`. If SAME day: call `computeRangeFillKeys(anchorKey: anchor, secondTapKey: key, blockedHours: blocked)` (import from `lib/domain/services/range_fill.dart`), call `HapticFeedback.mediumImpact()`, call `ref.read(availabilityProvider.notifier).setCustomHours(fillKeys, block: true)`, then `setState(() => _pendingAnchor = null)` — fills the range and closes the block (RNE-01 point 2). If DIFFERENT day: call `HapticFeedback.lightImpact()`, call `toggleCustomHour(key)`, then `setState(() => _pendingAnchor = key)` — closes the old anchor's block as a standalone 1-hour block (nothing further needed for it — it was already selected from its own first tap) and opens a brand-new block anchored on the new day (RNE-01 point 7).

  In `_buildCell`, compute `final isPendingAnchor = _pendingAnchor == key;` and change the `Container`'s `border` to `Border.all(color: isPendingAnchor ? Theme.of(context).colorScheme.primary : rw.border, width: isPendingAnchor ? 2 : 0.5)`. Also wire `onLongPress` on the cell's `GestureDetector` to a stub call `() => _showCellInfo(context, key, blockedHours, hour)` (the body of `_showCellInfo` is implemented in Task 3 — declare it now as a method returning nothing so this task compiles standalone; Task 3 fills in the implementation).

  Change `_buildDragIndicatorBar(BuildContext context)` to `_buildDragIndicatorBar(BuildContext context, Map<DateTime, BlockType> blockedHours)` (update the call site in `_buildGrid`'s `Column` to `_buildDragIndicatorBar(context, blockedHours)` — `blockedHours` is already in scope there as a `_buildGrid` parameter). Change the visibility condition from `!_isDragging` to `!(_isDragging || _pendingAnchor != null)`, and compute the count as: when `_isDragging`, `countSelectionRuns(_draggedCells)` (unchanged); otherwise (pending anchor open, not dragging — so `_pendingAnchor` is guaranteed non-null here), `countSelectionRuns({for (final e in blockedHours.entries) if (e.value == BlockType.custom && e.key.year == _pendingAnchor!.year && e.key.month == _pendingAnchor!.month && e.key.day == _pendingAnchor!.day) e.key})` — scoped to ONLY the anchor's own calendar day, matching `countSelectionRuns`' internal day-grouping semantics and mirroring the day-scoped intuition of "how many separate blocks on THIS day" rather than aggregating the whole week's persisted selections (RNE-04).
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter analyze lib/features/availability/availability_screen.dart && flutter test test/features/availability_screen_test.dart</automated>
  </verify>
  <done>
  `flutter analyze` reports zero new errors/warnings. `flutter test test/features/availability_screen_test.dart` passes, including the new tests for: open-block-then-fill-close, re-tap-anchor-cancels, counter-bar reactivity while a pending anchor is open, same-day two-separate-blocks after a close (Test 4), blocked-cell no-op with an anchor open (Test 5), cross-day close-old-open-new transition (Test 6), and day-scoped counter correctness against a dirty multi-day grid (Test 7). The existing BACKLOG-35 drag-indicator test and all P04/SC tests still pass unmodified (drag gesture untouched).
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Long-press cell-info bottom sheet</name>
  <files>lib/features/availability/availability_screen.dart, test/features/availability_screen_test.dart, lib/l10n/app_en.arb, lib/l10n/app_nl.arb, lib/l10n/app_localizations.dart, lib/l10n/app_localizations_en.dart, lib/l10n/app_localizations_nl.dart</files>
  <behavior>
    - Test 1: long-press a free cell (no entry in blockedHours) -> a bottom sheet appears showing the day name + hour range text and the status text `S.of(context).cellInfoStatusFree` ("Vrij").
    - Test 2: long-press a `BlockType.work` cell -> bottom sheet shows `cellInfoStatusWork` ("Werk-geblokkeerd").
    - Test 3: long-press a `BlockType.custom` cell -> bottom sheet shows `cellInfoStatusCustom` ("Beschikbaar gezet").
    - Test 4: long-press a `BlockType.calendar` cell -> bottom sheet shows `cellInfoStatusCalendar` ("Agenda-geblokkeerd").
  </behavior>
  <action>
  In `lib/l10n/app_nl.arb` (template file), insert after the existing `"legendCalendar"` entry four new plain-string keys (no `@` metadata blocks needed, matching the `legendFree`/`legendBusy`/`legendWork` precedent): `"cellInfoStatusWork": "Werk-geblokkeerd"`, `"cellInfoStatusCalendar": "Agenda-geblokkeerd"`, `"cellInfoStatusCustom": "Beschikbaar gezet"`, `"cellInfoStatusFree": "Vrij"`.

  In `lib/l10n/app_en.arb`, insert the matching keys in the same relative position: `"cellInfoStatusWork": "Work-blocked"`, `"cellInfoStatusCalendar": "Calendar-blocked"`, `"cellInfoStatusCustom": "Marked available"`, `"cellInfoStatusFree": "Free"`.

  Run `flutter gen-l10n` from the repo root to regenerate `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_nl.dart` with the four new getters. Do not hand-edit the generated files.

  In `lib/features/availability/availability_screen.dart`, add `import 'package:intl/intl.dart';`. Implement `_showCellInfo(BuildContext context, DateTime key, Map<DateTime, BlockType> blockedHours, int hour)` (RNE-03; declared as a stub in Task 2): compute `locale = Localizations.localeOf(context).languageCode == 'en' ? 'en_US' : 'nl_NL'`, format the day name via `DateFormat('EEEE', locale).format(key)` and capitalize its first letter (the raw `intl` output is lowercase, e.g. "maandag" -> "Maandag", matching the design's example "Maandag 09:00–10:00"). Build the status label via a `switch` on `blockedHours[key]`: `BlockType.work` -> `S.of(context).cellInfoStatusWork`, `BlockType.calendar` -> `S.of(context).cellInfoStatusCalendar`, `BlockType.custom` -> `S.of(context).cellInfoStatusCustom`, `null` -> `S.of(context).cellInfoStatusFree`. Call `showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$dayName ${hour.toString().padLeft(2, '0')}:00–${(hour + 1).toString().padLeft(2, '0')}:00', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(status, style: Theme.of(context).textTheme.bodyLarge)])))` — mirroring `week_agenda_screen.dart`'s `_showDetail` `Padding`+`Column` shape, without any weather/score rows (this grid has none).

  In `test/features/availability_screen_test.dart`, add a new `group('BACKLOG-rne: long-press cell info', ...)` with the 4 behaviors above. Use the same fixed-viewport setup and cell-center coordinate formula already established in the file (`physicalSize: Size(800, 1400)`, `devicePixelRatio: 1.0`, `x = 36 + (dayIndex + 0.5) * cellWidth`, `y = 56 + 32 + 28 + (hour + 0.5) * cellHeight`), pumping with `MaterialApp(locale: const Locale('nl'), localizationsDelegates: S.localizationsDelegates, supportedLocales: S.supportedLocales, home: const AvailabilityScreen())` wrapped in the appropriate `FakeEmptyAvailabilityNotifier`/`FakeFilledAvailabilityNotifier` override per test. Trigger the long-press via `await tester.longPressAt(cellCenterOffset); await tester.pump(); await tester.pumpAndSettle();` then assert `find.text(expectedStatusText)` finds one widget.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter gen-l10n && flutter analyze lib/features/availability/availability_screen.dart lib/l10n/app_localizations.dart && flutter test test/features/availability_screen_test.dart</automated>
  </verify>
  <done>
  `flutter gen-l10n` runs clean and `S` exposes `cellInfoStatusWork`/`cellInfoStatusCalendar`/`cellInfoStatusCustom`/`cellInfoStatusFree` in both generated locale files. `flutter analyze` reports zero new errors/warnings. `flutter test test/features/availability_screen_test.dart` passes, including all 4 new long-press status tests, alongside every pre-existing test in the file (drag, two-tap, P04/SC).
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
  The Availability screen's 7×24 grid now supports a two-tap range-select model alongside the existing drag gesture: tap an empty hour to open a pending block (shown with an accent border), tap a second empty hour on the same day to fill the range and close the block, re-tap the anchor to cancel it, tap a different day to close-and-reopen elsewhere. Long-pressing any cell shows a bottom sheet with day/hour/status. The "N losse tijdvakken" counter bar now also shows while a block is pending open (not just during drag), scoped to the anchor's own day.
  </what-built>
  <how-to-verify>
  Run the app (`flutter run` on a connected device/emulator, or the release APK per usual workflow) and open the Availability screen (Profile -> Mijn schema, or onboarding).
  1. Tap one empty hour cell. Confirm it turns orange (custom-selected) and shows a visible accent border. Confirm a "N tijdvak(ken) geselecteerd" counter appears above the grid, counting only blocks on THAT day (if you start from an empty schedule, N will be 1; if other days already have selections from prior testing, N should still reflect only the tapped day's own count, not the whole week's).
  2. Tap a different empty hour, 2-3 hours away, on the SAME day. Confirm every hour in between turns orange, the accent border disappears (block closed), and the counter disappears.
  3. If a work-blocked (grey-blue) hour sits between two taps, confirm it is skipped (stays grey-blue, not overwritten) while hours on both sides of it still fill orange.
  4. Tap an empty hour to open a new block, then immediately re-tap that SAME hour. Confirm it reverts to free/white and the border disappears (block canceled).
  5. On the same day, after closing one block (step 2), tap a different empty hour further away and tap a second empty hour near it to open and close a SECOND, separate block on that same day. Confirm both blocks exist independently (the hours between them, if any, remain unselected) rather than merging into one continuous block.
  6. Tap an empty hour to open a new block, then tap a work- or calendar-blocked cell elsewhere on the same day. Confirm nothing happens to the blocked cell and the original pending anchor's border is still showing (the no-op guard applies even while a block is open).
  7. Tap an empty hour on Monday to open a block, then tap an empty hour on Tuesday. Confirm Monday's hour stays selected as its own standalone 1-hour block, and Tuesday's tap opens a new block there (border now on Tuesday's cell).
  8. Long-press any cell. Confirm a bottom sheet appears showing the day name, hour range (e.g. "Maandag 09:00–10:00"), and correct status text depending on the cell (Vrij / Werk-geblokkeerd / Agenda-geblokkeerd / Beschikbaar gezet).
  9. Perform the existing drag-to-select gesture (press and drag across multiple cells) exactly as before. Confirm it still works identically — orange/grey highlight while dragging, commit on release, drag-run counter shows during the drag.
  10. Confirm tapping a work-blocked or calendar-blocked cell (outside of any drag) still does nothing, whether or not a block is currently pending open elsewhere.
  11. Interleaved-gesture check: tap one empty hour to open a pending anchor (border visible), then WITHOUT tapping to close it, perform the drag gesture starting on a different, unrelated cell (press-drag-release across a few hours elsewhere on the grid). Confirm the drag completes normally and commits its own selection, and does NOT clear or corrupt the still-open pending anchor's border. Afterward, tap a second empty hour on the anchor's day to confirm the original pending block still closes/fills correctly — the interleaved drag must not have silently discarded or corrupted the anchor.
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| None new | All changes are local gesture-driven UI state operating on data the user already owns on-device (blockedHours map, persisted via existing SharedPreferences flow). No new network call, no new external input, no persisted-data-format change. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-quick260714rne-01 | Tampering | SharedPreferences-persisted `blockedHours` entries | accept | No new persisted format — `setCustomHours`/`toggleCustomHour` (unchanged, pre-existing methods) are the only write paths; existing try/catch deserialization guard (T-04-01) already covers corrupt entries. |
| T-quick260714rne-02 | Denial of Service (logic) | `computeRangeFillKeys` gap-fill logic | mitigate | Explicit `BlockType.work`/`BlockType.calendar` skip inside the pure function, proven by dedicated unit tests (Task 1, Tests 4-5) so work/calendar-blocked hours can never be silently overwritten by a range fill. |
| T-quick260714rne-03 | Information Disclosure | Long-press cell-info bottom sheet | accept | Displays only the user's own locally-known cell status (BlockType) for their own device data; nothing leaves the device, nothing new is persisted. |
| T-quick260714rne-04 | Elevation of privilege (logic) | `_pendingAnchor` state machine — "stuck open" block silently applying an unintended fill on a later, unrelated tap | mitigate | Explicit widget tests (Task 2, Tests 4-7) cover open-then-fill-close, re-tap-cancel, same-day-two-separate-blocks, blocked-cell-no-op-with-anchor-open, cross-day close/reopen, and day-scoped counter correctness; the human-verify checkpoint (final task) additionally confirms real touch-gesture feel and interleaved drag-during-pending-anchor behavior, since drag-vs-tap gesture arena disambiguation is easier to misjudge by simulated `tester.tap`/`longPress` calls than by real touch input. |
</threat_model>

<verification>
Run, in order: `flutter analyze` (whole repo, to catch cross-file issues), `flutter test test/domain/services/range_fill_test.dart`, `flutter test test/features/availability_screen_test.dart`. Then complete the human-verify checkpoint above for the real-touch gesture feel that automated widget tests can't cheaply prove (drag-vs-tap coexistence, cross-day close/reopen, interleaved drag-during-pending-anchor, long-press timing).
</verification>

<success_criteria>
- Two-tap range-select works exactly as specified: open-anchor, same-day fill-and-close, re-tap-cancel, cross-day close-and-reopen, already-custom toggle-off leaves block open, and a closed block is always followed by a brand-new independent anchor on the next empty-cell tap (never a silent re-merge)
- Work/calendar-blocked hours are never overwritten by a range fill (skipped, gap preserved), and tapping a blocked cell is always a no-op regardless of whether a pending anchor is open
- Existing drag-to-select gesture is completely unregressed, including when interleaved with an open pending anchor
- Pending-anchor cell shows a visible 2px primary-colored accent border while a block is open, and never otherwise
- Long-press on any cell shows a bottom sheet with day + hour range + correct status label in both NL and EN
- "N losse tijdvakken" counter bar shows during BOTH active drag and open pending-anchor states, with a count scoped to the anchor's own calendar day (not the whole week) in the pending-anchor case, and hides again once neither is active
- No new pubspec dependency added
- `flutter analyze` and both new `flutter test` commands pass; `flutter gen-l10n` runs clean
</success_criteria>

<output>
Create `.planning/quick/260714-rne-availability-grid-twee-tik-bereik-select/260714-rne-SUMMARY.md` when done
</output>
