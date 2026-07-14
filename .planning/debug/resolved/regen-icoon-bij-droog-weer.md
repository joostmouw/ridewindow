---
status: resolved
trigger: "Backlog item #37: tester meldt dat een regen-icoontje getoond wordt terwijl de neerslagkans/hoeveelheid 'dry' is"
created: 2026-07-14
updated: 2026-07-14
---

## Symptoms

- **Expected behavior:** The rain icon in the Ride Detail "HOURLY" breakdown table should reflect actual precipitation — no rain-drop icon (or a "dry" icon) when the adjacent text label says "dry".
- **Actual behavior:** A rain-cloud-with-drops icon is shown directly next to the text "dry" in the Hourly table on the Ride Detail screen. Confirmed via screenshot: both the 17:00 and 18:00 rows show "🌧️ dry" side by side — the icon contradicts the text on the same row.
- **Error messages:** None — this is a visual/logic inconsistency, not a crash or exception.
- **Timeline:** Found 2026-07-14 during Phase 15 real-iPhone-Safari manual verification (web deploy at https://my-project-joost.web.app), reported by tester Jacco. Unknown whether this is a new regression or has always been present — not previously reported by other testers/QA.
- **Reproduction:** Open Ride Detail for a slot with dry conditions, high temp, moderate wind (screenshot example: 17:00–19:00, 29°C, Rain: Dry, Wind 23km/h from NE, scored "Perfect"). Scroll to the "HOURLY" section — each hour row shows a rain-drop icon next to the word "dry".

## Current Focus

reasoning_checkpoint:
  hypothesis: "The rain-cloud emoji (U+1F327) is hardcoded as a literal prefix in all four branches of the `precip` string builder in `_buildHourlyRowWidget` (ride_detail_screen.dart:452-458), including the branch that produces the 'dry' text — so the icon never reflects dryness because it was never made conditional."
  confirming_evidence:
    - "Direct read of source: all four ternary branches building `precip` start with the literal '\\u{1F327} ' string, including the dry branch ('\\u{1F327} ${s.hourlyDry}')."
    - "The dry-detection condition (precipitationMm == 0.0 && (probability == null || probability == 0)) is the exact same condition used to select the dry TEXT label — so icon and text are computed from the same data, ruling out a field/threshold mismatch."
  falsification_test: "If the emoji were NOT hardcoded, changing precipitationMm to 0.0 with probability 0/null would produce a different (non-rain) icon in the resulting string. It does not — the string literal is identical rain-cloud glyph in every branch."
  fix_rationale: "Root cause is that no branch differs in the icon glyph, only in text. The fix makes the icon itself conditional: use a neutral/no-rain glyph (or omit the rain icon) specifically in the dry branch, matching the same condition already used for the dry text, while leaving the three wet-branches' icon untouched."
  blind_spots: "Have not checked whether other screens (home_screen.dart, week_agenda_screen.dart) have the same pattern for precipitation icons — this session's symptom report was specific to Ride Detail Hourly rows only, so fix is scoped there. Have not run the actual widget test / screenshot after fix, will verify via flutter analyze + code re-read."
next_action: Apply minimal fix in ride_detail_screen.dart — make the rain emoji conditional so the dry branch does not show the rain-cloud glyph.

## Evidence

- timestamp: 2026-07-14T00:00:00Z
  checked: lib/features/detail/ride_detail_screen.dart, `_buildHourlyRowWidget` (lines 442-458), specifically the `precip` string construction
  found: |
    The rain-cloud emoji `\u{1F327}` (🌧) is hardcoded as a literal prefix in EVERY branch of the
    conditional expression that builds the `precip` label, including the "dry" branch:
    ```
    final precip = row.precipitationMm != null
        ? (row.precipitationMm! == 0.0 && (row.precipitationProbability == null || row.precipitationProbability == 0)
            ? '\u{1F327} ${s.hourlyDry}'                                          // <-- dry branch still gets rain icon
            : row.precipitationProbability != null && row.precipitationProbability! > 0
                ? '\u{1F327} ${row.precipitationMm!.toStringAsFixed(1)}mm ${row.precipitationProbability!.round()}%'
                : '\u{1F327} ${row.precipitationMm!.toStringAsFixed(1)}mm')
        : '\u{1F327} —';
    ```
    There is no icon/text decoupling and no threshold mismatch — the icon is unconditional, always
    the rain-cloud emoji regardless of whether precipitation is actually present.
  implication: |
    Root cause found directly in code — no further hypothesis testing needed. Original hypothesis
    (icon/text derived from different thresholds) was PARTIALLY correct in spirit (icon logic is
    decoupled from meaning) but the actual mechanism is simpler: the icon glyph itself was never
    made conditional when the "dry" text branch was added — likely an oversight when the dry-label
    branch was introduced (the emoji prefix was probably copy-pasted from the wet branches without
    updating for the dry case).

## Eliminated

- hypothesis: Icon and text are keyed off different fields/thresholds (e.g., icon off raw probability, text off mm amount), disagreeing at low-but-nonzero values.
  evidence: Read the exact source at ride_detail_screen.dart:452-458 — both icon and text are computed in the same expression from the same `row.precipitationMm` / `row.precipitationProbability` fields. The "dry" branch condition (`precipitationMm == 0.0 && (probability == null || probability == 0)`) is the same condition that produces the "dry" text; the icon is simply not made conditional on it. Not a threshold disagreement — a hardcoded icon.
  timestamp: 2026-07-14

## Resolution

root_cause: |
  In `_buildHourlyRowWidget` (lib/features/detail/ride_detail_screen.dart), the `precip` label was
  built with the rain-cloud emoji `\u{1F327}` hardcoded as a literal prefix on ALL branches of the
  ternary expression, including the branch specifically reached when precipitation is zero/absent
  (the "dry" branch, which produces `s.hourlyDry` text). The dry-detection condition already existed
  and correctly selected the "dry" text, but nobody made the icon glyph itself conditional on that
  same check — an oversight, likely from copy-pasting the emoji prefix across all branches when the
  dry-text branch was added.
fix: |
  Removed the hardcoded `\u{1F327}` (rain-cloud) emoji prefix specifically from the dry branch of the
  `precip` ternary, so dry rows now render just `s.hourlyDry` (e.g. "dry" / "droog") with no rain
  icon at all. The three branches that represent actual precipitation (probability>0, mm-only, and
  the null/no-data fallback) are untouched and still show the rain-cloud icon, which is correct for
  those cases.
verification: |
  - flutter analyze on the modified file: no new issues introduced (6 pre-existing warnings/info
    unrelated to this change, e.g. unused_element, use_build_context_synchronously — none touch the
    `precip` variable or `_buildHourlyRowWidget`).
  - Re-read the modified code: dry branch now returns `s.hourlyDry` with no emoji; other three
    branches unchanged and still correctly show the rain icon for actual/unknown precipitation.
  - This fix was never committed on its own — it sat in the working tree until superseded by a
    follow-up quick task (quick-260714-m63) that added a sun/partly-cloudy icon enhancement on top
    of the same dry branch (user request, not a bug). Both changes landed together in a single
    commit: c5967b9 (feat(quick-260714-m63): add sun/partly-cloudy icon to Hourly precip label).
    The original bug (rain icon on "dry" rows) no longer reproduces — dry rows with no rain
    probability show a sun icon instead of the rain-cloud glyph.
files_changed:
  - lib/features/detail/ride_detail_screen.dart
