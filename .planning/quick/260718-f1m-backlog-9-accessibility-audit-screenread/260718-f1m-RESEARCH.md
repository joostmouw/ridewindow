# Backlog #9: Accessibility Audit — Research

**Researched:** 2026-07-18
**Domain:** Flutter accessibility (Semantics, touch targets, WCAG contrast) — Material 3, RideWindow codebase
**Confidence:** HIGH (all findings are direct code inspection with file:line references, not framework-API speculation)

## Summary

RideWindow's `lib/features/**` contains **zero** `Semantics(` widgets anywhere in the codebase (`grep -rn "Semantics(" lib/` → 0 matches). Accessibility currently relies entirely on Flutter's default widget semantics — `Text` auto-labels, `IconButton.tooltip` doubling as the a11y label when present. Roughly half of the icon-only interactive elements have no `tooltip`, so they are effectively unlabeled to screen readers (TalkBack/VoiceOver announces only "button"). The two custom interactive grids (Availability's 7×24 hour grid, Agenda's 7×17 hour grid) are built from raw `GestureDetector` + `Container` with **no Semantics wrapper at all** — a screen-reader user gets zero information about which day/hour a cell represents or its blocked/available state, and several dimensions are explicitly sized below the 48dp Material minimum touch target (`_cellHeight` floors at 16px, header cells hardcoded to 36×28). One clear WCAG AA contrast failure was found in a widely-reused foreground/background text pair (`ScoreBadge` "Acceptable" tier: 3.46:1, needs 4.5:1), plus a systemic near-fail in the `textHint` color token (2.85:1) used as real label text across multiple screens.

**Primary recommendation:** Fix in this priority order — (1) add `tooltip`/`Semantics(label:)` to all icon-only buttons and the two grid cell widgets (highest value, cheapest fix, screen-reader users currently cannot use these at all); (2) enlarge the two smallest explicit touch targets (`profile_screen.dart` 28×28 info button, `weather_indicator_bar.dart` unpadded 14px info icon, availability/agenda grid cells) to ≥48dp or wrap in `GestureDetector` + `Semantics(button: true)` with a padded hit area via `MinInteractiveDimension`-equivalent sizing; (3) fix the `acceptableFg`/`acceptableBg` pair and reconsider `textHint` for actual label text (contrast is real but secondary priority per task scope).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Screen-reader labels (Semantics) | Client (Flutter widget tree) | — | Pure widget-tree concern, no backend/data-layer involvement |
| Touch target sizing | Client (Flutter widget tree) | — | Layout-only fix, `BoxConstraints`/`SizedBox` adjustments |
| Color contrast | Client (theme tokens in `lib/theme/`) | — | Centralized in `AppColors`/`TierColors`; fixing tokens fixes all call sites at once |

This is a client-only, code/config-only audit — no environment, package, or backend research applies.

## Phase Requirements

No formal REQ-IDs were supplied for this quick task (backlog item #9, free-text scope). The `<focus>` block in the task brief serves as the requirement list; mapped below.

| Focus Item | Research Support |
|------------|-------------------|
| Icon-only buttons/gesture targets missing Semantics/tooltip | Section "Priority A" below — 9 concrete locations with file:line |
| Touch target sizes <48dp | Section "Priority B" below — 6 concrete locations with file:line |
| Color contrast spot-check | Section "Priority C" below — 4 computed WCAG ratios |
| Common Flutter a11y pitfalls (images/CustomPaint w/o Semantics, form fields w/o labels, debug flags) | Section "Priority D" below |

## Priority A — Missing Semantics/Tooltip (screen-reader blockers)

These are icon-only or custom-gesture interactive elements with **zero** accessible label. A screen-reader user cannot determine what these elements do or, in the case of the grids, what cell they are even focused on.

| # | File:Line | Element | Current State | Fix |
|---|-----------|---------|----------------|-----|
| A1 | `lib/features/home/home_screen.dart:580` | `IconButton(icon: Icons.delete_outline)` — remove planned ride | No `tooltip` | Add `tooltip: S.of(context).unplanRide` (or equivalent existing/new l10n key) |
| A2 | `lib/features/detail/ride_detail_screen.dart:317` | `IconButton(icon: Icons.info_outline)` — opens "why this score" Insights sheet | No `tooltip` | Add `tooltip: S.of(context).whyThisScore` (or reuse an existing insights-related string) |
| A3 | `lib/features/detail/ride_detail_screen.dart:691,704,722,735` | 4× `IconButton` (`remove_circle_outline`/`add_circle_outline`) — start/end time ±1h adjusters | No `tooltip` on any of the 4; screen reader cannot distinguish "decrease start" from "decrease end" | Add 4 distinct tooltips, e.g. `decreaseStartTime` / `increaseStartTime` / `decreaseEndTime` / `increaseEndTime` — new l10n keys needed |
| A4 | `lib/features/profile/profile_screen.dart:376` | `IconButton(icon: Icons.clear)` — remove location override | No `tooltip` | Add `tooltip: S.of(context).clearLocationOverride` (new l10n key likely needed) |
| A5 | `lib/features/onboarding/onboarding_screen.dart:103` | `IconButton(icon: Icons.arrow_back_ios)` — back to Welcome | No `tooltip` | Add `tooltip: MaterialLocalizations.of(context).backButtonTooltip` (built-in, no new l10n key needed) — note `lib/core/safe_back_button.dart:48-50` already does this correctly; reuse that pattern/widget here if feasible |
| A6 | `lib/features/profile/feedback_dialog.dart:86` | 5× `IconButton` (star rating 1–5) | No `tooltip`; no way for a screen reader to know which star = which value, or which rating is currently selected | Add `tooltip: '$n ${s.starsLabel}'` or wrap each in `Semantics(label: ..., selected: n <= _rating, button: true)` |
| A7 | `lib/features/shared/weather_indicator_bar.dart:111-114` | Raw `GestureDetector` wrapping `Icon(Icons.info_outline)` — opens per-metric (temp/rain/wind) info sheet | No Semantics at all — not even an `IconButton`, so there's no built-in semantics node merge | Wrap in `Semantics(button: true, label: '$label info')` or replace with `IconButton(tooltip: ...)`. Reused across Home ride cards, Ride Detail, and Insights sheet — fixing this one widget fixes it everywhere |
| A8 | `lib/features/availability/availability_screen.dart:236` (`_buildCell`) | Core 7×24 availability grid cell `GestureDetector` (`onTap`/`onLongPress`) | Zero Semantics — screen reader gets nothing: no day, no hour, no blocked/available state | **Highest-value fix in this audit.** Wrap in `Semantics(label: '$dayName $hour:00, ${blocked ? "blocked" : "available"}', button: true, onTap: ...)`. This is the core AVAIL-01/02/03 interaction — currently 100% unusable via screen reader |
| A9 | `lib/features/agenda/week_agenda_screen.dart:515` (`_CellWidget.build`) | Agenda grid cell `GestureDetector` (`onTap`/`onLongPress`) | Same as A8 — zero Semantics | Same fix pattern as A8, include score/tier in the label (e.g. "Monday 14:00, Great riding weather, planned") |
| A10 | `lib/features/availability/availability_screen.dart:145,168` | Day-header / hour-header `GestureDetector`s (tap toggles whole column/row) | Visible `Text` inside gives *some* auto-label, but no indication the element is tappable-to-toggle-all, and no state feedback | Lower priority than A8/A9 (has partial text label already) — consider `Semantics(hint: 'Toggle all hours for this day')` |

**Systemic note:** Because zero `Semantics(` widgets exist anywhere in `lib/`, none of the custom "selected" states (e.g. `home_screen.dart`'s day-selector chip `GestureDetector` at line 465, which toggles `_selectedDay`) expose `selected: true/false` to the accessibility tree. This is a secondary, lower-priority finding but worth noting if the fix pass touches `home_screen.dart` anyway — add `Semantics(selected: isSelected)` around the day chip at line 465.

## Priority B — Touch Targets Below 48dp

Material Design / WCAG 2.5.5 (Target Size, AA-adjacent) minimum is 48×48dp. Flutter's default `IconButton` in Material 3 provides this automatically via internal padding *unless* explicitly overridden — several instances below explicitly override it smaller.

| # | File:Line | Element | Measured/Computed Size | Issue |
|---|-----------|---------|------------------------|-------|
| B1 | `lib/features/availability/availability_screen.dart:118-120` | Grid hour cells (`_cellHeight`/`_cellWidth`) | `_cellHeight = (availableHeight - 28) / 24`, explicitly floored at **16px** (`if (_cellHeight < 16) _cellHeight = 16;`); `_cellWidth = (maxWidth - 36) / 7` ≈ 40-50px on a typical 360-412dp-wide phone | Both dimensions are frequently below 48dp; height is *guaranteed* below 48dp on any device where `availableHeight < 1180px` (i.e. essentially all phones) since 24 rows must fit in the remaining vertical space |
| B2 | `lib/features/availability/availability_screen.dart:142-143,171-172` | Day-header / hour-header cells | Hardcoded `_headerWidth = 36`, `_headerHeight = 28` | Both constants are hardcoded below 48dp — deliberate compression, not a computed overflow like B1 |
| B3 | `lib/features/agenda/week_agenda_screen.dart:22,413-441` | Agenda grid hour rows | 17 entries in `_kHours` (`[6..22]`), each row `Expanded` inside a `Column` filling the remaining `Scaffold` body height | On a typical phone (~500-650dp available grid height after app bar + legend + day-header), each row computes to roughly 30-40dp — below 48dp |
| B4 | `lib/features/profile/profile_screen.dart:748-749` | Info `IconButton` (tier/tolerance explainer) | Explicit `constraints: const BoxConstraints(minWidth: 28, minHeight: 28)` | Deliberately overrides Flutter's default 48dp minimum down to 28×28 — clearest single violation in the codebase |
| B5 | `lib/features/onboarding/onboarding_screen.dart:103-107` | Back `IconButton` | `padding: EdgeInsets.zero` + `visualDensity: VisualDensity.compact` | Removes the padding that normally pads the tap target to 48dp; compact density further reduces it. Effective target ≈ icon size only (~24px) |
| B6 | `lib/features/shared/weather_indicator_bar.dart:111-114` | Raw `GestureDetector` around 14px `Icon` | No padding/`SizedBox` at all — effective tap target ≈ 14×14px | Same widget as A7 — fixing needs both a Semantics label *and* a larger hit area (wrap in `SizedBox(width: 48, height: 48)` or use `IconButton` with default constraints instead of raw `GestureDetector`) |

**Lower-confidence / needs manual device check:**
- `lib/features/home/home_screen.dart:398` — `SegmentedButton` with `visualDensity: VisualDensity.compact` (day-period filter). `SegmentedButton` is a Material widget with its own internal semantics, but compact density may push individual segments below 48dp on narrow screens. `[ASSUMED — flag for manual measurement, not code-inspectable without running the widget]`
- `lib/features/detail/ride_detail_screen.dart:691-738` (the four time-adjuster `IconButton`s from A3) use `size: 20` for the icon but do **not** override `constraints`, so Flutter's default IconButton padding likely still provides the full 48dp tap target. `[ASSUMED — the icon is small but the tappable IconButton hit-box is probably fine; verify with the Flutter Inspector's "Show tap targets" or a real device before deciding this needs a size fix, vs. just the tooltip fix from A3]`

## Priority C — Color Contrast (spot-check, lower priority per task scope)

Computed using the standard WCAG relative-luminance formula against the exact hex values in `lib/theme/app_colors.dart`. Not run through an automated tool — flagged here for manual verification per the task's own instructions.

| # | Pair | File | Ratio | WCAG AA Threshold | Verdict |
|---|------|------|-------|--------------------|---------|
| C1 | `acceptableFg (#E65100)` on `acceptableBg (#FFF3E0)` | `lib/theme/app_colors.dart:31-32`, rendered in `lib/features/shared/score_badge.dart` ("Acceptable" tier badge text, `labelMedium`) | **3.46:1** | 4.5:1 (normal text) | **FAIL** — this is real, user-facing badge text at normal size, shown on every Acceptable-tier ride card/detail screen |
| C2 | `rw.textHint (#999999)` on light surfaces (white/`#F5F5F5`) | `lib/theme/app_colors.dart:58` (`lightTextHint`), used as literal `TextStyle(color: rw.textHint)` at `ride_detail_screen.dart:346,523,630,678,792`, `week_agenda_screen.dart:422`, `onboarding_screen.dart:241`, `weather_indicator_bar.dart:113` | **2.85:1** | 4.5:1 (normal, most of these are 10-13px) / 3:1 (large text) | **FAIL** on both thresholds — this token is used as real label text (hour numbers, secondary metadata), not purely decorative, at multiple sites across the app |
| C3 | `poorFg (#757575)` on `poorBg (#F5F5F5)` | `lib/theme/app_colors.dart:33-34`, `ScoreBadge` "Poor" tier text | **4.23:1** | 4.5:1 (normal text) | Borderline FAIL (0.27 short) |
| C4 | `lightScorePoor (#BDBDBD)` on white | `lib/theme/app_colors.dart:69`, used as a fill/border/dot color (not text) in `home_screen.dart:1116`, `weather_icon.dart:121`, `ride_detail_screen.dart:773`, `planned_rides_screen.dart:26`, `week_agenda_screen.dart:28,280` | **1.88:1** | 3:1 (WCAG 1.4.11 non-text/UI-component contrast) | FAIL — the "Poor" tier's color-coding is very low-contrast against light backgrounds, a low-vision user may not perceive the Poor-tier score strip/border/legend-dot as distinct from the background at all |

**Not flagged (checked, pass):** `perfectFg`/`perfectBg` (7.00:1), `greatFg`/`greatBg` (5.71:1), `lightTextTertiary` on white (5.74:1) — all comfortably pass AA.

**Recommendation:** C1 and C2 are the two worth fixing in this pass — C1 is a single centralized token pair (`TierColors.light.acceptableFg/Bg`) whose fix propagates everywhere the badge is used; C2 requires either darkening `lightTextHint` (and its dark-mode counterpart `darkTextHint`, which is a separate/passing pair — verify before changing) or auditing which of its 8 call sites are decorative (icon tint — fine) vs. real text label (needs the fix). C3 and C4 are worth a one-line note in the fix plan but are self-admittedly lower priority per the task's own instructions.

## Priority D — Other Flutter A11y Pitfalls

| # | Finding | File:Line | Detail |
|---|---------|-----------|--------|
| D1 | `WeatherIcon` (animated tier icon: sun/partly-cloudy/cloudy/rain) has no `Semantics`/`semanticLabel` at all | `lib/features/shared/weather_icon.dart` (whole file) | Prominently displayed on Home ride cards. A screen reader skips this widget entirely — no "Perfect riding weather" or equivalent announcement. `Semantics(label: ..., child: ...)` wrap needed at the top-level `SizedBox` in `build()` (line 39) |
| D2 | `TextField` in feedback dialog uses only `hintText`, no `labelText`/persistent `Semantics` label | `lib/features/profile/feedback_dialog.dart:96-101` | Hint text is not a reliable substitute for a real accessible label on all screen readers once text is entered. Add `labelText: s.feedbackCommentHint` (Material's `InputDecoration` supports both simultaneously — hint remains as placeholder, label persists) |
| D3 | Zero `Semantics(` widgets anywhere in `lib/` | codebase-wide (`grep -rn "Semantics(" lib/` → 0) | Confirms the audit's premise — the app has never had a dedicated accessibility pass. Every fix in Priority A/B is net-new, not a regression fix |
| D4 | No debug accessibility flags shipped | `lib/main.dart` | Checked — no `showSemanticsDebugger`, `debugShowCheckedModeBanner` is untouched (defaults to Flutter's own debug-mode-only banner, which is fine and not shippable in release builds). **No action needed**, confirmed clean |
| D5 | Day-selector chip (Home) has no `selected` semantic state | `lib/features/home/home_screen.dart:465` (`GestureDetector`, `_DayClass`-based chip) | Visible via color/border/scale animation only; screen reader has no way to know which day is currently selected. Lower priority — bundle with A10 if `home_screen.dart` is touched |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Flutter Material 3 `IconButton` provides a default ≥48dp tap target unless `constraints`/`padding`/`visualDensity` is explicitly overridden (used to *exclude* the 4 time-adjuster buttons in ride_detail_screen.dart from the touch-target fix list) | Priority B, "Lower-confidence" note | If wrong, those 4 buttons also need explicit `constraints: BoxConstraints(minWidth: 48, minHeight: 48)` added — cheap to add defensively even if unconfirmed |
| A2 | `SegmentedButton` with `VisualDensity.compact` may reduce segment tap targets below 48dp on narrow screens | Priority B | Unverified without running on a real/narrow device; if the segments are already ≥48dp this is a non-issue, no harm in checking |

**All contrast ratios (Priority C) are computed directly from the hex values in `lib/theme/app_colors.dart` using the standard WCAG relative-luminance formula — these are `[VERIFIED: local computation against source-of-truth hex constants]`, not `[ASSUMED]`.** All file:line references throughout are `[VERIFIED: grep + direct file read]`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Accessible label for a custom grid cell | A bespoke announcement/focus-management system | `Semantics(label:, button:, onTap:)` wrapping the existing `GestureDetector`/`Container` | Flutter's Semantics API already integrates with TalkBack/VoiceOver focus traversal; no custom logic needed, just labels |
| Enlarging a touch target without changing visual size | Manually recalculating tap hit-testing | Wrap the small visual (e.g. the 14px info icon in `weather_indicator_bar.dart`) in a `SizedBox(width: 48, height: 48, child: Center(child: ...))` combined with `GestureDetector.behavior: HitTestBehavior.opaque`, or switch to `IconButton` (which already does this via `constraints`) | Standard Flutter pattern — the visual can stay small while the tappable area grows to 48dp |

## Open Questions

1. **Should the Availability/Agenda grid cells get per-cell Semantics nodes, or a merged row/region semantics with a custom `SemanticsSortKey`?**
   - What we know: Per-cell `Semantics` (A8/A9) is the simplest fix and matches how most Flutter calendar/grid a11y patterns work.
   - What's unclear: With 7×24 = 168 cells (Availability) and 7×17 = 119 cells (Agenda), a screen reader user swiping cell-by-cell through the whole week could be a poor UX even once each cell is labeled — this is a UX question, not just a labeling bug.
   - Recommendation: Ship per-cell Semantics first (correctness baseline), flag "grid navigation UX for screen readers" as a possible follow-up backlog item rather than blocking this fix on redesigning the interaction model.

2. **New l10n strings needed for tooltips (A1, A3, A4, A6) — EN/NL required per existing project convention.**
   - What we know: The project has established EN/NL l10n infra (`lib/l10n/`) and existing patterns for adding new keys (see e.g. `S.of(context).retryButton`, `S.of(context).importFromCalendar` already used as tooltips).
   - What's unclear: Exact wording for the new tooltip strings — not something research should invent.
   - Recommendation: Planner/executor should add new keys following the existing naming convention (`camelCase`, verb-first for actions) and provide both EN and NL translations, consistent with the project's stated i18n-complete convention.

## Sources

### Primary (HIGH confidence — direct codebase inspection)
- `lib/features/**/*.dart` — grep + direct read for `Semantics(`, `IconButton(`, `GestureDetector(`, `tooltip:`, touch-target-related `constraints`/`padding`/`VisualDensity`
- `lib/theme/app_colors.dart` — exact hex values used for computed contrast ratios
- `lib/main.dart` — confirmed no debug accessibility flags shipped

### Secondary (MEDIUM confidence)
- WCAG 2.1 contrast formulas (relative luminance, 4.5:1 normal text / 3:1 large text or UI components) — standard, well-established formula, applied directly to the hex values above (not sourced from an external fetch this session, but the formula itself is not in dispute)
- Material Design touch-target guidance (48×48dp minimum) — standard Material 3 spec, consistent with Flutter's own `IconButton` default sizing behavior

## Metadata

**Confidence breakdown:**
- Priority A (missing Semantics): HIGH — every finding is a direct grep+read match, not inference
- Priority B (touch targets): HIGH for B1-B4 (explicit constants/constraints in code); MEDIUM for the two "lower-confidence" notes (SegmentedButton, time-adjuster IconButtons) which need a real-device check
- Priority C (contrast): HIGH for the ratio computations (exact hex values, standard formula); MEDIUM for whether every listed call site of `textHint` is "real text" vs. decorative — spot-checked, not exhaustively categorized
- Priority D: HIGH

**Research date:** 2026-07-18
**Valid until:** Valid until the next significant UI refactor touches these files — flag for re-audit if `lib/theme/app_colors.dart`, `availability_screen.dart`, or `week_agenda_screen.dart` are substantially rewritten before this backlog item is executed
