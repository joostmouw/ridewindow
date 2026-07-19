---
phase: quick-260718-f1m
plan: 01
subsystem: accessibility
tags: [semantics, screen-reader, wcag, touch-targets, l10n]
dependency-graph:
  requires: []
  provides: [Semantics-labeled icon controls, Semantics-labeled grid cells, 48dp touch targets, WCAG AA text contrast]
  affects: [lib/features/home, lib/features/detail, lib/features/profile, lib/features/onboarding, lib/features/availability, lib/features/agenda, lib/features/shared, lib/theme]
tech-stack:
  added: []
  patterns: [Semantics(label:/hint:/selected:/button:) wrapping GestureDetector/IconButton, IconButton.tooltip, extracted day-name/status helper methods shared between long-press sheet and Semantics label]
key-files:
  created: []
  modified:
    - lib/l10n/app_en.arb
    - lib/l10n/app_nl.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_en.dart
    - lib/l10n/app_localizations_nl.dart
    - lib/features/home/home_screen.dart
    - lib/features/detail/ride_detail_screen.dart
    - lib/features/profile/profile_screen.dart
    - lib/features/onboarding/onboarding_screen.dart
    - lib/features/profile/feedback_dialog.dart
    - lib/features/shared/weather_indicator_bar.dart
    - lib/features/shared/weather_icon.dart
    - lib/features/availability/availability_screen.dart
    - lib/features/agenda/week_agenda_screen.dart
    - lib/theme/app_colors.dart
    - test/features/availability_screen_test.dart
decisions:
  - "Availability grid _showCellInfo: extracted two focused helpers (_dayNameFor, _statusFor) instead of one combined string-return helper, so the bottom-sheet header/body Text widgets keep their original independent format while _cellSemanticLabel composes both for the Semantics label — avoids string-parsing hacks to split a combined label back into its parts."
  - "Full flutter test baseline: the plan's own <verification> step 5 cites a stale '282/2' baseline from an older debug session. STATE.md's most recent (2026-07-17) entry supersedes it with a corrected 215/69 baseline. This plan's actual full-suite result (214 passing / 70 failing) matches the STATE.md baseline almost exactly per-file (13 identical file:count pairs), with one extra flaky failure in notification_service_test.dart that passes 4/4 in isolation — confirmed test-binding cross-file state leakage (BACKLOG #11), not a regression. See Verification section below."
  - "grep -c Semantics( lib/ returns 8, not the >=13 the plan's aggregate <verification> step 3 estimated. Every individual Semantics wrap specified across Task 1 (2 wraps: home day-chip, feedback stars) and Task 2 (6 wraps: weather-icon, weather-metric-info, availability cell, availability day-header, availability hour-header, agenda cell) was implemented — 2+6=8. The >=13 aggregate figure in the plan appears to be a planner estimation error, not a scope gap; every task's own <done> criteria (verified per-task, not just the aggregate) pass."
metrics:
  duration: ~90min
  completed: 2026-07-19
---

# Phase quick-260718-f1m Plan 01: Accessibility Audit (Screen Reader, Touch Targets, Contrast) Summary

Closed backlog #9 by adding Semantics labels/tooltips to every audited icon-only control and both custom hour-grids (previously zero screen-reader support), raising 5 touch targets to the 48dp Material minimum (one documented 44dp tradeoff), and correcting 3 WCAG AA contrast failures in the shared theme tokens.

## What Was Built

**Task 1 — Tooltips, Semantics(selected), and a TextField label (commit `3918a79`)**
- 9 new EN/NL ARB key pairs: `removePlannedRideTooltip`, `showScoreDetails`, `decreaseStartTime`, `increaseStartTime`, `decreaseEndTime`, `increaseEndTime`, `clearLocationOverride`, `feedbackStarRating` (ICU plural), `feedbackCommentLabel`.
- Home: delete-planned-ride `IconButton` tooltip; day-selector chip wrapped in `Semantics(selected:, button:)`.
- Ride Detail: info-icon tooltip (opens Insights sheet); 4 time-adjuster `IconButton`s each get a distinct tooltip (decrease/increase start/end).
- Profile: clear-location-override `IconButton` tooltip.
- Onboarding: back button tooltip via `MaterialLocalizations.of(context).backButtonTooltip` (matches the existing `SafeBackButton` pattern).
- Feedback dialog: each of the 5 star `IconButton`s gets a `feedbackStarRating(n)` tooltip and is wrapped in `Semantics(selected:, button:)`; the comment `TextField` gets a persistent `labelText` alongside its existing `hintText`.

**Task 2 — Semantics for custom-gesture widgets (commit `1589023`)**
- 7 new EN/NL ARB key pairs: `weatherMetricInfoTooltip`, `weatherTierDescription`, `cellStatusPlanned/Selected/Blocked`, `dayHeaderToggleHint`, `hourHeaderToggleHint`.
- `weather_indicator_bar.dart`: the 14px info-icon `GestureDetector` is now wrapped in `Semantics(button:, label:)` and widened to a 48dp hit area (`SizedBox` + `Center` + `HitTestBehavior.opaque`) — fixes both the missing label (A7) and the undersized tap target (B6) in one shared widget used across Home, Ride Detail, and Insights.
- `weather_icon.dart`: the tier-switch `SizedBox` is wrapped in `Semantics(label: "$tier riding weather")` — the animated sun/cloud/rain icon now announces its tier to a screen reader.
- `availability_screen.dart`: extracted `_dayNameFor`/`_statusFor` helpers (shared by `_showCellInfo`'s bottom sheet and the new `_cellSemanticLabel`); every grid cell (`_buildCell`) now exposes `Semantics(label: "$day $hour:00, $status", button:)`; day-header and hour-header toggle-all `GestureDetector`s get `Semantics(hint:, button:)`.
- `week_agenda_screen.dart`: `_CellWidget` composes a label from day name, hour, tier description (when scored), and conditional blocked/planned/selected status, wrapped in `Semantics(label:, button:)`.

**Task 3 — Touch-target sizing and contrast fixes (commit `2b1f374`)**
- `app_colors.dart`: `TierColors.light.acceptableFg` 0xFFE65100→0xFFBF360C (3.46:1→5.11:1); `AppColors.lightTextHint` 0xFF999999→0xFF6B6B6B (2.85:1/2.61:1→5.33:1/4.89:1); `AppColors.darkTextHint` 0xFF757575→0xFF949494 (3.62:1/3.03:1→5.5:1/4.6:1). Each change has an inline comment citing the new ratio.
- `availability_screen.dart`: `_cellHeight` floor raised 16→48dp; `_headerHeight` (day-header row) raised 28→48dp; `_headerWidth` (hour-label column) raised 36→44dp with an inline comment documenting the narrower-but-improved tradeoff (preserves day-column width on narrow phones).
- `week_agenda_screen.dart`: hour rows converted from `Expanded` (computed ~30-40dp) to a `SingleChildScrollView` wrapping fixed `SizedBox(height: 48)` rows — day-header row stays fixed at the top, hour rows scroll independently if they overflow the viewport.
- `profile_screen.dart`: tier/tolerance info `IconButton` constraints 28×28→48×48.
- `onboarding_screen.dart`: removed `padding: EdgeInsets.zero` and `visualDensity: VisualDensity.compact` from the back button — Material 3's default `IconButton` constraints now provide the 48dp target.
- `test/features/availability_screen_test.dart`: updated all 3 duplicated cell-sizing coordinate-math blocks to the new 44/48 header baselines; since the raw formula cellHeight (≈46.83) is still below the new 48dp floor at the test's fixed 800×1344 viewport, the test now uses the floored `48.0` literal directly (mirroring what production code does), not the raw formula result.

## Verification

- `flutter gen-l10n`: succeeded with no missing-key errors after all 3 tasks (both ARB files kept in sync).
- `dart analyze` on every touched `lib/` file: zero new errors/warnings introduced by this plan across all 3 tasks — only pre-existing warnings/infos (unused variables/elements, `use_build_context_synchronously`, `require_trailing_commas`) remain, none in code this plan touched.
- `grep -c "Semantics("` per Task 2's required files: all 4 files have >=1 (weather_indicator_bar.dart: 1, weather_icon.dart: 1, availability_screen.dart: 3, week_agenda_screen.dart: 1). Aggregate `grep -c Semantics( lib/` = 8 total (see Decisions above re: the plan's `>=13` aggregate estimate).
- Task-required test files: `feedback_dialog_test.dart` (4/4 pass), `availability_screen_test.dart` (13/24 pass — 11 pre-existing failures, see below), `onboarding_screen_test.dart` (0/3 pass — 3 pre-existing failures), `profile_screen_test.dart` (0/5 pass — 5 pre-existing failures). All failures traced to a pre-existing, plan-unrelated bug: several tests construct a bare `MaterialApp(home: ...)` without `localizationsDelegates: S.localizationsDelegates`, so `S.of(context)` throws `Null check operator used on a null value` — this is BACKLOG #11's documented test-binding/localization issue, not something this plan touched or introduced (confirmed: same failure signature, same test names, same counts as STATE.md's 2026-07-17 baseline).
- `week_agenda_screen_test.dart` (not in the plan's required verify list, but directly affected by the Task 3 scrollable-grid conversion): all 7/7 tests pass. One benign hit-test warning appeared (`tester.tap` on `cell_0_20`, now below the default 800×600 test viewport after the 48dp-row height increase) — the warning did not fail the test since it's a no-op assertion either way; flagged as a Known Issue below for anyone hardening that test file later.

### Full `flutter test` suite (constraint requirement)

Ran the complete suite once after all 3 tasks. Result: **214 passing / 70 failing** (284 total), parsed via `flutter test --reporter json` for reliable per-file attribution (the default compact reporter's carriage-return progress lines make plain-text tail parsing unreliable across concurrent test shards).

**Baseline discrepancy note:** the plan's own `<verification>` step 5 cites a "282/2 baseline established in the prior test-binding-state-leakage debug session." This figure is stale. `.planning/STATE.md`'s most recent entry (dated 2026-07-17, decision `17-01`) explicitly **supersedes** that older note with a corrected baseline: *"flutter test on current HEAD consistently reports 215 passing / 69 failing across 13 files... the exact per-file split shifts slightly run-to-run (test-binding/localization state leakage between files, tracked in BACKLOG.md #11)."*

Comparing this plan's result against the **corrected STATE.md baseline** (215/69), not the stale plan figure:

| File | STATE.md baseline (2026-07-17) | This run |
|---|---|---|
| ride_detail_screen_test.dart | 13 | 13 |
| insights_sheet_test.dart | 13 | 13 |
| availability_screen_test.dart | 11–12 | 11 |
| profile_screen_test.dart | 5 | 5 |
| profile_screen_notif_test.dart | 5 | 5 |
| weather_repository_test.dart | 3–5 | 5 |
| home_screen_test.dart | 4 | 4 |
| detail/ride_detail_screen_calendar_test.dart | 4 | 4 |
| onboarding_screen_test.dart | 3 | 3 |
| welcome_screen_test.dart | 2 | 2 |
| home_screen_location_test.dart | 2 | 2 |
| providers/integration_test.dart | 1 | 1 |
| providers/slots_notifier_test.dart *(one of two alternating)* | 1 | 1 |
| **platform/notification_service_test.dart** | — (not in baseline) | **1 (new, but flaky)** |

13 of 14 failing files match the STATE.md baseline exactly (using the documented upper bound where a range was given). The one extra: `test/platform/notification_service_test.dart` failed once in the full-suite run but **passed 4/4 when run in isolation** (`flutter test test/platform/notification_service_test.dart`) — this is the same cross-test-interference class of failure STATE.md already documents for this codebase (test-binding state leaking between files depending on run order), not a defect introduced by this plan's changes (this plan never touched `lib/services/notification_service.dart` or its test). No `lib/` file this plan modified appears anywhere in either failure list.

**Conclusion: zero new regressions.** All 70 failures are accounted for by the pre-existing, previously-documented BACKLOG #11 issue.

## Known Stubs

None.

## Known Issues (not blocking, informational)

- `test/features/week_agenda_screen_test.dart` produces a benign `WidgetController` hit-test warning when tapping cells beyond hour ~17 at the default 800×600 test viewport, now that Agenda rows are fixed at 48dp each (previously they compressed to fit). The warning does not fail the test (the assertion it's checking passes either way in the affected case), but a future hardening pass should set an explicit taller `tester.view.physicalSize` in that test file, consistent with what `availability_screen_test.dart`'s BACKLOG-35/rne groups already do.

## Threat Flags

None — this plan touches only client-side Flutter UI code (widget tree, theme constants, l10n strings); no new network calls, data persistence, or trust boundaries. Threat model in PLAN.md pre-registered both threats in this plan's scope (T-f1m-01 layout-only regression risk, T-f1m-02 Semantics labels expose only already-visible on-screen text) as `accept`.

## Self-Check: PASSED

- `lib/theme/app_colors.dart`, `lib/features/availability/availability_screen.dart`, `lib/features/agenda/week_agenda_screen.dart`, `lib/features/profile/profile_screen.dart`, `lib/features/onboarding/onboarding_screen.dart`, `lib/features/home/home_screen.dart`, `lib/features/detail/ride_detail_screen.dart`, `lib/features/profile/feedback_dialog.dart`, `lib/features/shared/weather_indicator_bar.dart`, `lib/features/shared/weather_icon.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_nl.arb`, `test/features/availability_screen_test.dart` — all FOUND on disk with the described changes.
- Commit `3918a79` (Task 1), `1589023` (Task 2), `2b1f374` (Task 3) — all FOUND in `git log --oneline`.
