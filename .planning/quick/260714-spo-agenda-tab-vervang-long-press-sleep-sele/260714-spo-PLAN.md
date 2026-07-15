---
phase: quick-260714-spo
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [lib/features/agenda/week_agenda_screen.dart, test/features/week_agenda_screen_test.dart, lib/l10n/app_en.arb, lib/l10n/app_nl.arb, lib/l10n/app_localizations.dart, lib/l10n/app_localizations_en.dart, lib/l10n/app_localizations_nl.dart]
autonomous: false
requirements: [SPO-01, SPO-02, SPO-03, SPO-04]

must_haves:
  truths:
    - "Tapping an empty (not work/calendar-blocked, not already-planned) hour cell on Agenda, with no active selection, starts a new 1-hour pending selection (visible via the existing selected-cell checkmark styling and the appearing 'Plan rit' button)"
    - "Tapping a different hour on the SAME day while a selection is open recomputes the range against the ORIGINAL anchor hour (not the current range boundary), so the range can grow or SHRINK back on repeated taps"
    - "Tapping the anchor hour again while the selection is still exactly 1 hour (not yet extended) cancels the pending selection entirely"
    - "Tapping a work/calendar-blocked cell OR an already-planned cell is always a complete no-op: it never starts, extends, shrinks, or cancels any active selection"
    - "Tapping a cell on a DIFFERENT day than the active selection's day discards the old (never-committed) selection and starts a brand-new one anchored on the new day/hour"
    - "Long-pressing ANY cell (blocked, planned, selected, or free; regardless of whether a selection is currently active) shows the existing weather-detail bottom sheet"
    - "The 'Plan rit' button and its live hour counter continue to commit the currently selected range exactly as before, now fed by the new tap state machine instead of the old long-press-drag state machine"
    - "No dead code remains from the removed long-press-drag gesture: _onLongPressStart, _onLongPressMoveUpdate, _onLongPressEnd, _dragStartHour, _dragDayIndex, _cellAt, _keyFor, _cellKeys are all fully removed from week_agenda_screen.dart"
  artifacts:
    - path: "lib/features/agenda/week_agenda_screen.dart"
      provides: "_onCellTap(dayIndex, hour, day, blockedHours) tap-based state machine + _anchorHour field; per-cell onTap/onLongPress wiring on _CellWidget"
      contains: "_onCellTap"
    - path: "test/features/week_agenda_screen_test.dart"
      provides: "New widget test suite (baseline coverage for this previously-untested screen) covering all 8 locked behavior rules"
      contains: "_onCellTap"
    - path: "lib/l10n/app_en.arb"
      provides: "Updated hintTapWeatherDetail(Desc)/hintDragSelect(Desc) copy reflecting long-press-for-info and tap-tap-range gestures"
      contains: "hintDragSelect"
    - path: "lib/l10n/app_nl.arb"
      provides: "Matching NL copy for the same four hint keys"
      contains: "hintDragSelect"
  key_links:
    - from: "lib/features/agenda/week_agenda_screen.dart _CellWidget.build onTap"
      to: "_WeekAgendaScreenState._onCellTap"
      via: "onTap: () => _onCellTap(di, hour, days[di], blockedHours) wired in _buildGrid's _CellWidget constructor"
      pattern: "_onCellTap\\("
    - from: "lib/features/agenda/week_agenda_screen.dart _CellWidget.build onLongPress"
      to: "_showDetail"
      via: "onLongPress: () => _showDetail(context, ref, score) always wired, unconditional on selection/blocked/planned state"
      pattern: "onLongPress:.*_showDetail"
    - from: "_onCellTap"
      to: "_isBlocked / _isPlanned guard"
      via: "first-line no-op guard before any _selection mutation"
      pattern: "_isBlocked\\(day, hour, blockedHours\\)"
---

<objective>
Replace the Agenda screen's long-press-and-drag range-selection gesture with a two-tap range model, and repurpose long-press for the weather-detail info sheet — bringing Agenda to full gesture parity with the sibling Availability screen's tap=select / long-press=info pattern (per the user's locked decision from this quick task's discussion).

Locked design (verbatim, not open for re-interpretation):

1. Tap an empty (not work/calendar-blocked, not already planned) hour, when NO selection is currently active, starts a new pending selection: a 1-hour range anchored on that hour.
2. Tap a DIFFERENT hour, SAME day, while the selection is still active, recomputes the range between the ORIGINAL anchor hour and this new tapped hour (min/max), exactly like the old drag-move logic. Unlike Availability's strict "2nd tap closes forever" model, the user MAY tap a 3rd, 4th, etc. time and the range keeps recomputing against the SAME fixed anchor — it stays adjustable until the user explicitly taps "Plan rit" or cancels. This is a deliberate, considered adaptation from Availability's model: Agenda has only one pending selection at a time (no persistent multi-block map) and already has an explicit commit step (the "Plan rit" button), so continuous adjustment before commit is the desired UX here.
3. Tap again on the SAME hour as the anchor, while the selection is still exactly 1 hour (not yet extended), cancels the pending selection entirely.
4. Tap an hour that is already part of the current (already-extended) range, but not the anchor itself, behaves like point 2 — recompute against the fixed anchor. Inherently safe/idempotent, no special-case code needed beyond point 2's logic.
5. Tap an hour on a DIFFERENT day than the current selection's day, while a selection is active: the old pending selection is simply replaced (discarded — it was never committed) by a new selection anchored on the new tap/day.
6. Tap a work/calendar-blocked cell OR an already-planned cell: complete no-op. Does NOT touch any active selection — doesn't clear it, doesn't extend it, doesn't cancel it. This is a behavior CHANGE from the current code (currently ANY tap, even on blocked cells, clears the active selection).
7. Long-press on ANY cell (regardless of whether a selection is active) shows the existing `_showDetail` weather-detail bottom sheet, unchanged in content, now triggered by long-press. This REPLACES `_onLongPressStart`/`_onLongPressMoveUpdate`/`_onLongPressEnd` and their `GestureDetector` wiring entirely — full removal, no dead code.
8. The "Plan rit" button, the live hour counter, and `_planSelection`/`_clearSelection` stay functionally unchanged — they're now fed by the new tap state machine instead of the old long-press-drag state machine.
9. Visual feedback for a 1-hour pending selection: the existing `isSelected` styling (checkmark + accent border, active as soon as `_selection` is non-null) and the already-appearing "Plan rit" button are sufficient existing feedback — no new "pending anchor" indicator is added (judged against the actual styling code; this differs from Availability only because Availability's persistent multi-block map needs to visually distinguish "the currently-open anchor" from "already-closed blocks", a distinction that doesn't exist here since there is only ever one `_selection` at a time).

Purpose: remove an inconsistent, single-purpose long-press-drag gesture and align Agenda's interaction model with the sibling Availability screen, making long-press a reliable, discoverable way to inspect any cell's weather detail without altering it.
Output: rewritten tap-based state machine in `week_agenda_screen.dart` (dead drag-gesture code fully removed), new widget test suite establishing baseline coverage for this previously-untested screen, updated EN/NL hint copy describing the new gestures.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

<interfaces>
<!-- Confirmed by reading the actual current file (not assumed). -->

**Current `_WeekAgendaScreenState` fields** (`lib/features/agenda/week_agenda_screen.dart`): `bool _showBlocked`, `bool _showHints`, `_Selection? _selection`, `final _cellKeys = <String, GlobalKey>{}` (drag-only, to remove), `final _gridKey = GlobalKey()` (KEEP — used by the hint-overlay spotlight), `final _busyToggleKey = GlobalKey()` (KEEP, unrelated), `int? _dragStartHour`/`int? _dragDayIndex` (drag-only, to remove).

**`_Selection` class** (unchanged by this plan — already fits the tap model as-is): `const _Selection({required dayIndex, required startHour, required endHour})`, `bool contains(int di, int hour)`, `int get count => endHour - startHour + 1`.

**Methods to remove entirely** (dead code after this plan): `_keyFor(int, int) -> GlobalKey`, `(int,int)? _cellAt(Offset globalPos)`, `void _onLongPressStart(LongPressStartDetails)`, `void _onLongPressMoveUpdate(LongPressMoveUpdateDetails)`, `void _onLongPressEnd(LongPressEndDetails)`. All five existed solely to support cross-cell drag hit-testing, which no longer exists once every cell has its own discrete tap/long-press `GestureDetector` (already true via `_CellWidget`).

**Methods to keep, with small edits**: `_clearSelection()` (add `_anchorHour = null` alongside `_selection = null`), `_planSelection(...)` (its final `setState(() => _selection = null)` must also reset `_anchorHour = null`), `_isBlocked(DateTime day, int hour, Map<DateTime, BlockType> blocked)` (unchanged, reused as the no-op guard), `_isPlanned(DateTime day, int hour)` (unchanged, reused as the no-op guard).

**Grid wiring to change** (in `build()`, ~line 320-328): the `Expanded(child: GestureDetector(key: _gridKey, onLongPressStart: ..., onLongPressMoveUpdate: ..., onLongPressEnd: ..., child: _buildGrid(...)))` becomes `Expanded(child: KeyedSubtree(key: _gridKey, child: _buildGrid(...)))` — `_gridKey` must stay attached to something in the tree because `_agendaHints()` targets it for the spotlight coach-mark overlay.

**Per-cell wiring to change** (in `_buildGrid`, ~line 449-466): `key: _keyFor(di, hour)` becomes `key: ValueKey('cell_${di}_$hour')` (a plain, test-friendly identity key — no GlobalKey map needed once drag hit-testing is gone). `onTap: _selection != null ? _clearSelection : null` becomes `onTap: () => _onCellTap(di, hour, days[di], blockedHours)` — always wired, never null; the no-op guard now lives INSIDE `_onCellTap`, not in the wiring.

**`_CellWidget` change** (~line 501-568): the constructor's `this.onTap` (currently optional, `VoidCallback? onTap`) becomes `required this.onTap` (`required VoidCallback onTap` — parent always supplies a handler now). In `build()`, `onTap: onTap ?? () => _showDetail(context, ref, score)` becomes two separate, always-wired callbacks: `onTap: onTap` and a new `onLongPress: () => _showDetail(context, ref, score)`. `_showDetail` itself (content, guard, layout) is untouched — only its trigger moves from a null-onTap fallback to an explicit long-press.

**l10n**: `hintTapWeatherDetail`/`hintTapWeatherDetailDesc`/`hintDragSelect`/`hintDragSelectDesc` (in `lib/l10n/app_en.arb` + `app_nl.arb`) are used ONLY in this file's `_agendaHints()` (confirmed via repo-wide grep — not shared with the Availability screen's own separate long-press-info hint strings, `cellInfoStatus*`). Safe to edit their content in place; no key renames needed. `l10n.yaml`: `template-arb-file: app_nl.arb`, `output-class: S`, `generate: true`. Generated files (`app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_nl.dart`) are committed to git in this repo — run `flutter gen-l10n` after editing the ARB files, do not hand-edit the generated files.

**Test-scaffolding precedent** — `test/features/home_screen_refresh_test.dart` (`_buildApp` helper) is the closest precedent for a screen watching many providers at once: `sharedPrefsProvider` (only needed if a real, non-faked Notifier reads it — NOT needed here since every provider this plan's tests touch will be fully faked), `weatherProvider.overrideWith(() => Fake...())`, `profileProvider.overrideWith(() => FakeProfileNotifier())` (exact `UserProfile`/`WeatherTolerances` fixture reusable verbatim from that file), `availabilityProvider.overrideWith(...)`, `locationProvider.overrideWith(...)`, `slotsProvider.overrideWith(...)`. `WeekAgendaScreen` additionally watches `plannedRidesProvider` (`lib/providers/planned_rides_notifier.dart`, class `PlannedRidesNotifier extends _$PlannedRidesNotifier`, generated provider name `plannedRidesProvider`) and the pure derived `allHourlyScoresProvider` (`lib/providers/hourly_scores_provider.dart` — NOT independently overridable/needed; it's a plain computed function of `weatherProvider` + `profileProvider`, so faking those two is sufficient). Unlike `home_screen_refresh_test.dart`'s `HomeScreen` (which reads a REAL `PlannedRidesNotifier` and therefore needs `sharedPrefsProvider.overrideWithValue(prefs)`), this plan's tests override `plannedRidesProvider` itself with a fully-faked notifier that never touches `SharedPreferences` — no `sharedPrefsProvider` override is needed.

**`HourlyForecast`** (`lib/domain/models/hourly_forecast.dart`) fields: `required double? temperatureC`, `required double? apparentTemperatureC`, `required double? precipitationMm`, `required double? precipitationProbability`, `required double? windspeedKmh`, `required double? winddirectionDeg`, `required DateTime time`.

**`PlannedRide`** (`lib/providers/planned_rides_notifier.dart`): `PlannedRide({required DateTime start, required DateTime end, required double plannedScore})`, `int get durationHours`. `PlannedRidesNotifier.build()` reads `sharedPrefsProvider` directly and `add(PlannedRide)`/`remove(PlannedRide)` both persist via `_persist()` — the test fake overrides all three so no real prefs I/O occurs.

**`_isBlocked`/`_isPlanned` matching semantics** (both unchanged, read-only for this plan): `_isBlocked` checks a DIRECT key match first (`DateTime(day.year, day.month, day.day, hour)`, local, no `.utc`) before falling back to a weekday-normalized match — so test fixtures should seed the fake `availabilityProvider` map using this exact direct-match local `DateTime` shape (not `DateTime.utc`) to avoid depending on the weekday-normalization fallback or timezone-sensitive `.utc` comparisons. `_isPlanned` compares `PlannedRide.start`/`.end` against `DateTime(day.year, day.month, day.day, hour)` the same way — seed fake `PlannedRide.start` using that identical local-`DateTime` shape.

**Hint-overlay must be disabled in tests**: `WeekAgendaScreen.initState` calls `shouldShowHint('agenda')` (`lib/features/shared/screen_hint_overlay.dart`) via `SharedPreferences.getInstance()` — with a fresh mock (`SharedPreferences.setMockInitialValues({})`), this returns `true` and the full-screen `ScreenHintOverlay` spotlight will render after the first frame, which can intercept subsequent test taps. Seed `SharedPreferences.setMockInitialValues({'hint_seen_agenda': true})` in every test's setup to keep it permanently suppressed.

**Score/forecast availability for `_showDetail` tests**: `_showDetail` returns immediately with NO bottom sheet when both `_findScore(...)` and `_findForecast(...)` are null for the tapped cell (see the existing guard `if (score == null && forecast == null) return;`). Since `allHourlyScoresProvider` is a pure function of `weatherProvider` + `profileProvider`, an empty `weatherProvider` fake (as used for the tap-state-machine tests, where scores are irrelevant) would make EVERY long-press silently no-op — wrong for the long-press test group. The long-press tests therefore need a `weatherProvider` fake that returns real `HourlyForecast` entries covering every day/hour combination used in those tests (see Task 2 below for the exact fixture), so `_showDetail` actually opens.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Rewrite tap-based state machine, remove dead drag-select code, retarget long-press, update hint copy</name>
  <files>lib/features/agenda/week_agenda_screen.dart, lib/l10n/app_en.arb, lib/l10n/app_nl.arb, lib/l10n/app_localizations.dart, lib/l10n/app_localizations_en.dart, lib/l10n/app_localizations_nl.dart</files>
  <behavior>
    Behavior expectations that Task 2's widget test suite will exercise against this task's implementation (this task's own verification is analyzer-clean + dead-code-absence grep, since the test suite that proves each transition is written in Task 2):
    - Rule 1: tap an empty hour with no active selection -> `_selection` becomes a 1-hour range anchored on that hour, `_anchorHour` set to that hour.
    - Rules 2/4: tap a different hour, same day, while active -> `_selection` recomputes to `[min(anchorHour, tappedHour), max(anchorHour, tappedHour)]`, always measured against the ORIGINAL `_anchorHour` (never against the current range's own boundaries), so a later tap can shrink a previously-extended range back down.
    - Rule 3: tap the anchor hour again while `_selection.startHour == _selection.endHour == _anchorHour` -> `_selection` and `_anchorHour` both become null.
    - Rule 5: tap a different day while active -> old `_selection`/`_anchorHour` discarded, new 1-hour selection opened on the new day/hour.
    - Rule 6: tap a work/calendar-blocked cell (via `_isBlocked`) or an already-planned cell (via `_isPlanned`) -> `_selection`/`_anchorHour` completely untouched, function returns immediately.
    - Rule 7: long-press any cell, in any blocked/planned/selected state -> `_showDetail` always fires.
    - Rule 8: `_planSelection`/`_clearSelection` continue to work off `_selection` exactly as before, with `_anchorHour` reset alongside `_selection` in both.
  </behavior>
  <action>
  In `_WeekAgendaScreenState`, add a new field `int? _anchorHour;` next to `_Selection? _selection;`. This tracks the ORIGINAL anchor hour of the current selection, separately from `_selection.startHour`/`endHour` which mutate as the range is recomputed — required because rule 2 always recomputes against the fixed original anchor, not the current range boundary (e.g. anchor 9, extend to 9-14, then tap 12 must recompute to 9-12, not use the current 9 or 14 as a stand-in reference).

  Remove entirely: the `_cellKeys` field, `_dragStartHour`/`_dragDayIndex` fields, and the `_keyFor`, `_cellAt`, `_onLongPressStart`, `_onLongPressMoveUpdate`, `_onLongPressEnd` methods — all five were solely drag-hit-testing infrastructure for the removed gesture.

  Add a new method `void _onCellTap(int dayIndex, int hour, DateTime day, Map<DateTime, BlockType> blockedHours)` implementing the state machine: first, if `_isBlocked(day, hour, blockedHours)` is true or `_isPlanned(day, hour)` is true, return immediately with no state change (rule 6). Otherwise, if `_selection` is null OR `dayIndex` differs from `_selection!.dayIndex`, `setState` to set `_anchorHour = hour` and `_selection = _Selection(dayIndex: dayIndex, startHour: hour, endHour: hour)` (this single branch covers both rule 1 — no active selection — and rule 5 — different day replaces the old one). Otherwise (same day, selection active): if `hour == _anchorHour` AND `_selection!.startHour == _selection!.endHour` (still exactly 1 hour, unextended), call `_clearSelection()` (rule 3). Otherwise, compute `lo = hour < _anchorHour! ? hour : _anchorHour!` and `hi = hour > _anchorHour! ? hour : _anchorHour!`, then `setState` to set `_selection = _Selection(dayIndex: dayIndex, startHour: lo, endHour: hi)` — leaving `_anchorHour` untouched so subsequent taps keep recomputing against the same fixed anchor (rules 2/4).

  Update `_clearSelection()` to also set `_anchorHour = null` inside its `setState`. Update `_planSelection(...)`'s final `setState(() => _selection = null)` to also set `_anchorHour = null` in the same `setState` block.

  In `build()`, replace the grid's wrapping `GestureDetector` (with its `onLongPressStart`/`onLongPressMoveUpdate`/`onLongPressEnd` wiring) with a plain `KeyedSubtree(key: _gridKey, child: _buildGrid(...))`, preserving the existing `_buildGrid(...)` call and its arguments unchanged, and keeping `_gridKey` attached (still required by `_agendaHints()`'s spotlight targeting).

  In `_buildGrid`, change each cell's `key: _keyFor(di, hour)` to `key: ValueKey('cell_${di}_$hour')`, and change `onTap: _selection != null ? _clearSelection : null` to `onTap: () => _onCellTap(di, hour, days[di], blockedHours)` (always wired, unconditional — the no-op guard now lives inside `_onCellTap`).

  In `_CellWidget`, change the constructor parameter from optional `this.onTap` to `required this.onTap`, and change its field type from `final VoidCallback? onTap;` to `final VoidCallback onTap;`. In `_CellWidget.build()`, change the `GestureDetector`'s `onTap: onTap ?? () => _showDetail(context, ref, score)` to two separate always-wired callbacks: `onTap: onTap` and `onLongPress: () => _showDetail(context, ref, score)`. Do not otherwise modify `_showDetail`'s body, guard, or layout (per the locked design, its content stays unchanged — only the trigger moves).

  In `_agendaHints()`, keep the existing two `HintItem`s in place (same `targetKey: _gridKey`, same title/description key references), but update the underlying ARB copy (see below) so the hint text matches the new gestures rather than the removed drag gesture. For the second hint's `gestureIcon` (currently `Icons.swipe_vertical`, no longer semantically accurate since there is no more swipe/drag), change it to `Icons.touch_app` to reflect a tap-based interaction.

  In `lib/l10n/app_nl.arb`, update these four existing keys' string VALUES (do not rename keys, do not touch the `@agendaHoursSelected`-style metadata blocks of unrelated keys): `hintTapWeatherDetail` -> "Houd ingedrukt voor weerdetails", `hintTapWeatherDetailDesc` -> "Houd een gekleurd uurvak ingedrukt om temperatuur, regen en wind te bekijken.", `hintDragSelect` -> "Tik tweemaal om een periode te selecteren", `hintDragSelectDesc` -> "Tik op een uur om te beginnen, tik daarna op een ander uur om de periode in te stellen. Tik daarna op \"Rit inplannen\" onderaan.".

  In `lib/l10n/app_en.arb`, update the matching four keys: `hintTapWeatherDetail` -> "Long press for weather details", `hintTapWeatherDetailDesc` -> "Long press a colored hour cell to view temperature, rain and wind.", `hintDragSelect` -> "Tap twice to select a range", `hintDragSelectDesc` -> "Tap an hour to start, then tap another hour to set the range. Then tap \"Plan ride\" at the bottom.".

  Run `flutter gen-l10n` from the repo root to regenerate the three generated localization files. Do not hand-edit them.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter gen-l10n && flutter analyze lib/features/agenda/week_agenda_screen.dart lib/l10n/app_localizations.dart && test "$(grep -c '_onLongPressStart\|_onLongPressMoveUpdate\|_onLongPressEnd\|_dragStartHour\|_dragDayIndex\|_cellAt(\|_keyFor(\|_cellKeys' lib/features/agenda/week_agenda_screen.dart)" = "0"</automated>
  </verify>
  <done>
  `flutter gen-l10n` regenerates the three localization files with no errors. `flutter analyze lib/features/agenda/week_agenda_screen.dart lib/l10n/app_localizations.dart` reports zero new errors/warnings. The dead-code grep for `_onLongPressStart`/`_onLongPressMoveUpdate`/`_onLongPressEnd`/`_dragStartHour`/`_dragDayIndex`/`_cellAt(`/`_keyFor(`/`_cellKeys` returns exactly 0 matches in `week_agenda_screen.dart`. `_onCellTap`, `_anchorHour`, the `KeyedSubtree`-wrapped grid, the `ValueKey('cell_${di}_$hour')` cell keys, and `_CellWidget`'s always-wired `onTap`/`onLongPress` callbacks all exist as described in the action above (their correctness against the 8 locked behavior rules is proven by Task 2's test suite, not by this task's own automated check).
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Widget test suite establishing baseline coverage for all 8 locked behavior rules</name>
  <files>test/features/week_agenda_screen_test.dart</files>
  <behavior>
    - Test 1 (Rule 1): tap an empty hour cell (day 0, hour 9) with no active selection -> the cell shows the selected checkmark, `S.of(context).agendaHoursSelected(1)` ("1 uur geselecteerd") is visible, and the "Plan rit" button (`agendaPlanRide(1)` = "Rit inplannen (1u)") appears.
    - Test 2 (Rules 2/4): after opening an anchor on (day 0, hour 9), tap (day 0, hour 12) -> selection extends to hours 9-12 ("4 uur geselecteerd"). Then tap (day 0, hour 10) -> selection recomputes against the ORIGINAL anchor (9), shrinking to hours 9-10 ("2 uur geselecteerd") rather than using 12 as a reference. Then tap (day 0, hour 14) -> selection re-extends to hours 9-14 ("6 uur geselecteerd"), proving the anchor stays fixed across repeated taps.
    - Test 3 (Rule 3): tap an empty cell (day 1, hour 10) to open a 1-hour anchor ("1 uur geselecteerd"), then tap that SAME cell again -> selection and Plan rit button both disappear, cell no longer shows the checkmark.
    - Test 4 (Rule 5): open an anchor on (day 0, hour 9), then tap a cell on a DIFFERENT day (day 2, hour 11) -> day 0 hour 9's checkmark is gone (old selection discarded, never committed), day 2 hour 11 now shows the checkmark and "1 uur geselecteerd" is visible (brand-new selection).
    - Test 5 (Rule 6): with a work-blocked cell seeded at (day 0, hour 5) and a planned ride seeded covering (day 0, hour 20), open an anchor on (day 0, hour 9) ("1 uur geselecteerd"), then tap the blocked cell (day 0, hour 5) -> no change (still "1 uur geselecteerd", checkmark still only on hour 9). Then tap the planned cell (day 0, hour 20) -> still no change.
    - Test 6 (Rule 7): with real forecast/score data seeded for every grid cell, long-press a free cell with no active selection -> the weather-detail bottom sheet opens (assert its hour-range text, e.g. "9:00 – 10:00"). Dismiss it, open an anchor on (day 0, hour 9), then long-press the work-blocked cell (day 0, hour 5) -> the sheet still opens, AND the active selection is untouched afterward ("1 uur geselecteerd" still visible once the sheet is dismissed). Long-pressing the currently-selected anchor cell itself also opens the sheet (tap and long-press coexist without one canceling the other).
    - Test 7 (Rule 8): open an anchor on (day 0, hour 9) and tap "Rit inplannen (1u)" -> the fake `plannedRidesProvider.notifier.add(...)` is called exactly once, the selection clears (Plan rit button and checkmark gone), and the "Rit ingepland (1u)!" snackbar appears. Separately, open a new anchor on (day 1, hour 9) and tap "Annuleer" -> the selection clears without calling `add`.
  </behavior>
  <action>
  Create `test/features/week_agenda_screen_test.dart`. Mirror the fake-notifier + `ProviderScope` override pattern from `test/features/home_screen_refresh_test.dart`'s `_buildApp` helper, adapted for `WeekAgendaScreen`'s provider set: `weatherProvider`, `profileProvider`, `availabilityProvider`, `locationProvider`, `slotsProvider`, `plannedRidesProvider` (no `sharedPrefsProvider` override needed — see the interfaces note above on why).

  Define these fakes: `FakeWeatherWithForecasts extends WeatherNotifier` taking a `List<HourlyForecast> forecasts` constructor arg and returning it from `build()` — used by Test 6's long-press group, seeded via a helper `List<HourlyForecast> buildForecastsFor(DateTime today)` that generates one `HourlyForecast` (fixed `temperatureC: 20.0, apparentTemperatureC: 19.0, precipitationMm: 0.0, precipitationProbability: 5.0, windspeedKmh: 10.0, winddirectionDeg: 90.0`) for every combination of day offset 0-6 and hour 6-22 (`time: today.add(Duration(days: dayOffset, hours: hour))`) so every cell used by any test has a resolvable score/forecast. `FakeWeatherEmpty extends WeatherNotifier` returning `const []` — used by Tests 1-5, 7 where score/forecast content is irrelevant to the tap state machine. `FakeProfileNotifier extends ProfileNotifier` — reuse the exact `UserProfile`/`WeatherTolerances` fixture verbatim from `home_screen_refresh_test.dart` (`tempMinIdealC: 10.0, tempMaxIdealC: 30.0, windMaxIdealKmh: 25.0, rainMaxIdealMm: 1.0`, `allowedDurations: [2, 3]`, `theme: 'system'`, all three `notif*` flags `false`). `FakeAvailabilityNotifier extends AvailabilityNotifier` taking an optional `Map<DateTime, BlockType> seed = const {}` constructor arg, returning it from `build()`. `FakeLocationNotifier extends LocationNotifier` — reuse the exact Amsterdam fixture verbatim from `home_screen_refresh_test.dart`. `FakeStaticSlotsNotifier extends SlotsNotifier` — reuse `SlotsLoaded([], reason: null)` verbatim. `FakePlannedRidesNotifier extends PlannedRidesNotifier` taking an optional `List<PlannedRide> seed = const []` constructor arg, overriding `build()` to return `seed`, and overriding `add(PlannedRide ride)` to append to a public `List<PlannedRide> added = []` field AND update `state` (do not call `_persist`/read prefs) so tests can assert on `added.length` and `added.single` without needing `SharedPreferences`.

  Write a `pumpAgendaApp(WidgetTester tester, {Map<DateTime, BlockType> blockedHours = const {}, List<PlannedRide> plannedRides = const [], WeatherNotifier Function()? weatherFn, FakePlannedRidesNotifier? plannedRidesNotifier})` helper that pumps `ProviderScope(overrides: [weatherProvider.overrideWith(weatherFn ?? () => FakeWeatherEmpty()), profileProvider.overrideWith(() => FakeProfileNotifier()), availabilityProvider.overrideWith(() => FakeAvailabilityNotifier(blockedHours)), locationProvider.overrideWith(() => FakeLocationNotifier()), slotsProvider.overrideWith(() => FakeStaticSlotsNotifier()), plannedRidesProvider.overrideWith(() => plannedRidesNotifier ?? FakePlannedRidesNotifier(plannedRides))], child: MaterialApp(locale: const Locale('nl'), localizationsDelegates: S.localizationsDelegates, supportedLocales: S.supportedLocales, theme: ThemeData(extensions: [RideWindowTheme.light]), home: const WeekAgendaScreen()))`, then `await tester.pump(); await tester.pump(const Duration(milliseconds: 100));` to flush the initial async provider resolutions.

  In `setUp`, call `SharedPreferences.setMockInitialValues({'hint_seen_agenda': true})` (suppresses the hint overlay per the interfaces note). At the top of `main()`, compute `final now = DateTime.now(); final today = DateTime(now.year, now.month, now.day);` once, reused by every test to build day-N keys as `today.add(Duration(days: n, hours: hour))` (for `blockedHours`/`plannedRides` seeding, using this exact local, non-UTC shape) and `today.add(Duration(days: n))` (for the `PlannedRide.start`/`.end` day boundary) — matching `_isBlocked`/`_isPlanned`'s direct-match semantics exactly, per the interfaces note.

  Add small finder helpers: `Finder cellFinder(int dayIndex, int hour) => find.byKey(ValueKey('cell_${dayIndex}_$hour'))` (relies on Task 1's new `ValueKey('cell_${di}_$hour')` cell keys — no coordinate math needed, unlike the Availability screen's tests). `bool cellHasCheckmark(WidgetTester tester, int dayIndex, int hour) => find.descendant(of: cellFinder(dayIndex, hour), matching: find.byIcon(Icons.check)).evaluate().isNotEmpty`.

  Implement the 7 tests described in `<behavior>` above using `await tester.tap(cellFinder(dayIndex, hour)); await tester.pump();` for taps, and `await tester.longPress(cellFinder(dayIndex, hour)); await tester.pump(); await tester.pumpAndSettle();` for long-presses (Test 6 only, which needs `weatherFn: () => FakeWeatherWithForecasts(buildForecastsFor(today))`). For Test 6's sheet-dismiss step between assertions, tap a point clearly outside the modal sheet's content area (e.g. `await tester.tapAt(const Offset(20, 80)); await tester.pumpAndSettle();`, since `showModalBottomSheet`'s default barrier is dismissible) — do not tap the sheet's "Bekijk details" button, which calls `context.push('/detail', ...)` and would require a `GoRouter` this test's plain `MaterialApp` does not provide. For Test 7's "Plan rit"/"Annuleer" taps, use `await tester.tap(find.text('Rit inplannen (1u)')); await tester.pump();` and `await tester.tap(find.text('Annuleer')); await tester.pump();` respectively, passing a shared `FakePlannedRidesNotifier` instance into `pumpAgendaApp` via the `plannedRidesNotifier` param so the test can inspect its `added` list afterward.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter analyze test/features/week_agenda_screen_test.dart && flutter test test/features/week_agenda_screen_test.dart</automated>
  </verify>
  <done>
  `flutter analyze test/features/week_agenda_screen_test.dart` reports zero new errors/warnings. `flutter test test/features/week_agenda_screen_test.dart` passes all 7 tests, with every one of the 8 locked behavior rules (rules 2 and 4 combined in Test 2, per the locked design's own note that rule 4 needs no special-case code beyond rule 2's logic) covered by at least one assertion. No pre-existing test file is modified or regressed (this is a brand-new file for a previously-untested screen).
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
  The Agenda screen's tap gesture has been rewritten from long-press-and-drag range selection to a two-tap range model: tap an empty hour to open a 1-hour pending selection, tap a different hour on the same day to recompute the range against the fixed original anchor (can grow or shrink on repeated taps), re-tap the anchor to cancel, tap a different day to discard-and-restart. Long-press on ANY cell (blocked, planned, selected, or free) now always shows the weather-detail bottom sheet. The old long-press-drag gesture and its supporting dead code have been fully removed. Hint copy (NL/EN) has been updated to describe the new gestures.
  </what-built>
  <how-to-verify>
  Run the app (`flutter run` on a connected device/emulator, or the release APK per usual workflow) and open the Agenda tab.
  1. Tap one empty hour cell. Confirm it shows the checkmark/accent-border "selected" styling and the "Plan rit" button appears at the bottom with a "1u" label.
  2. Tap a different hour a few hours away, same day. Confirm the range extends to cover both hours (checkmarks on every hour in between) and the "Plan rit" label updates its hour count.
  3. Tap a hour BETWEEN the anchor and the current far edge (not the anchor, not the far edge). Confirm the range recomputes against the ORIGINAL anchor hour (shrinks correctly) rather than treating the previous far edge as a new reference point.
  4. Tap the anchor hour again while the selection is still exactly 1 hour (i.e. before ever extending it). Confirm the selection cancels entirely — checkmark and "Plan rit" button both disappear.
  5. Open a selection on one day, then tap an hour on a DIFFERENT day. Confirm the first day's selection is fully discarded (no checkmark left behind) and a brand-new 1-hour selection opens on the new day/hour.
  6. Tap a work-blocked or calendar-blocked hour cell (grey with a block icon), and separately tap an already-planned hour cell (bike icon). Confirm both are complete no-ops — no selection starts, and if a selection was already open elsewhere, it is completely unaffected (not cleared, not extended).
  7. Long-press ANY cell — free, blocked, planned, and the currently-selected anchor cell itself. Confirm the weather-detail bottom sheet opens every time, showing temperature/rain/wind and the score breakdown, and that opening it never disturbs an already-open pending selection underneath.
  8. Confirm the old long-press-and-drag-to-extend gesture is truly gone: pressing and holding, then dragging your finger across multiple cells, should NOT extend a selection across the dragged cells anymore — only discrete taps move the range now.
  9. Tap "Plan rit" to commit a selection. Confirm the ride is added to the plan (snackbar confirmation, ride now shows the planned-ride bike icon on its hours) exactly as before.
  10. Tap the info icon in the app bar to re-open the gesture hints. Confirm the NL (or EN, depending on device locale) hint text correctly describes "long press for weather details" and "tap twice to select a range" — no leftover wording about dragging/swiping to select.
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| None new | All changes are local gesture-driven UI state operating on data the user already owns on-device (blockedHours/plannedRides, both already-persisted via existing SharedPreferences flows). No new network call, no new external input, no persisted-data-format change. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-quick260714spo-01 | Tampering | SharedPreferences-persisted `planned_rides` entries | accept | No new persisted format — `PlannedRidesNotifier.add`/`_persist` (unchanged, pre-existing) are the only write paths touched by `_planSelection`, which itself is unchanged except for the `_anchorHour` reset. |
| T-quick260714spo-02 | Elevation of privilege (logic) | `_onCellTap` state machine — anchor-recompute-against-wrong-reference bug class (e.g. recomputing against the current range edge instead of the fixed original anchor, or a blocked/planned tap silently mutating an open selection) | mitigate | Explicit widget tests (Task 2, Tests 1-5) cover open-anchor, extend, shrink-back-against-fixed-anchor, cancel-on-anchor-retap, cross-day discard-and-restart, and the blocked/planned no-op guard applying regardless of an open selection; the human-verify checkpoint additionally confirms real touch-gesture feel and that the old drag-to-extend gesture is truly gone, since gesture-arena disambiguation (tap vs. the removed long-press-drag) is easier to misjudge by simulated `tester.tap`/`longPress` calls than by real touch input. |
| T-quick260714spo-03 | Information Disclosure | Long-press weather-detail bottom sheet | accept | Displays only the user's own locally-known weather/score data for their own device; nothing leaves the device, nothing new is persisted or exposed beyond what the removed long-press-drag's fallback already showed. |
| T-quick260714spo-04 | Denial of Service (logic) | Dead-code removal leaving orphaned references (`_onLongPressStart`/`_cellAt`/`_keyFor`/etc. no longer called, but still compiled in) that could mask a broken build | mitigate | Task 1's own `<verify>` includes a dead-code-absence grep (all 8 removed identifiers must return zero matches) in addition to `flutter analyze`, so an incomplete removal fails automated verification immediately rather than surfacing only via manual testing. |
</threat_model>

<verification>
Run, in order: `flutter gen-l10n` (regenerates the three localization files cleanly), `flutter analyze` (whole repo, to catch cross-file issues), the dead-code-absence grep from Task 1's `<verify>`, `flutter test test/features/week_agenda_screen_test.dart`. Then complete the human-verify checkpoint above for the real-touch gesture feel that automated widget tests can't cheaply prove (drag-truly-gone, long-press-always-works, hint copy reads correctly in the running app).
</verification>

<success_criteria>
- Two-tap range-select works exactly as specified: open-anchor on an empty hour, same-day recompute-against-fixed-anchor (both grow and shrink), re-tap-anchor-cancels (only while still exactly 1 hour), cross-day discard-and-restart
- Work/calendar-blocked and already-planned cells are always a complete no-op, regardless of whether a selection is currently open
- Long-press on ANY cell (blocked, planned, selected, or free) always shows the weather-detail bottom sheet, with no change to its content/layout
- No dead code remains from the removed long-press-drag gesture (`_onLongPressStart`/`_onLongPressMoveUpdate`/`_onLongPressEnd`/`_dragStartHour`/`_dragDayIndex`/`_cellAt`/`_keyFor`/`_cellKeys` all fully removed)
- "Plan rit" and "Annuleer" continue to commit/clear the selection exactly as before, now fed by the new tap state machine
- Updated NL/EN hint copy correctly describes long-press-for-info and tap-twice-for-range, with no leftover wording about dragging/swiping
- `flutter analyze` and `flutter test test/features/week_agenda_screen_test.dart` pass; `flutter gen-l10n` runs clean
- No new pubspec dependency added
</success_criteria>

<output>
Create `.planning/quick/260714-spo-agenda-tab-vervang-long-press-sleep-sele/260714-spo-SUMMARY.md` when done
</output>
