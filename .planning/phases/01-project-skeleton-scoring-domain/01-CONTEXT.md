# Phase 1: Project skeleton + scoring domain - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

A Flutter project skeleton exists with a **pure-Dart scoring domain** that is provably correct before any network, device, or UI code is written.

Concretely, this phase delivers:
1. A Flutter project (`flutter create`) with the canonical `lib/` tree from `.planning/research/ARCHITECTURE.md` scaffolded — but populated **only** in `lib/domain/` for now. Other folders (`data/`, `features/`, `platform/`, `core/`) exist as empty/stub directories so future phases can drop in.
2. The full `lib/domain/` module: models (`HourlyForecast`, `HourlyScore`, `RideSlot`, `UserProfile`, `WeatherTolerances`) + services (`ScoringEngine`, `SlotGenerator`, `AvailabilityFilter`) — pure Dart, zero Flutter imports, zero I/O.
3. A `dart test` suite that exercises every scoring/slot edge case (cold, hot, heavy rain, strong wind, mixed nulls, slot boundaries, all four tier categorisations) with **100% line coverage of `lib/domain/`**.
4. A minimal `lib/main.dart` that boots an empty `MaterialApp` (so `flutter run` succeeds) — but no real UI yet.

Out of scope for Phase 1: weather fetching (Phase 2), persistence (Phase 2), Riverpod providers (Phase 3), any screen (Phase 4+).

</domain>

<decisions>
## Implementation Decisions

### Sub-score curve: temperature

- **D-01:** Temperature sub-score uses **plateau + linear shoulders**, with **asymmetric** shoulder spans.
- **D-02:** **Plateau:** `score = 100` for `12 ≤ T ≤ 26` °C (locked in `.planning/PROJECT.md`).
- **D-03:** **Cold shoulder:** linear from `100` at 12 °C → `0` at **−5 °C** (17 °C span). Casual cyclists ride through cold with gear; this is forgiving on purpose for the Dutch climate.
- **D-04:** **Hot shoulder:** linear from `100` at 26 °C → `0` at **38 °C** (12 °C span). Heat is biologically more dangerous than cold; shorter span is honest.
- **D-05:** Reference scores (must hold via unit tests): −5 °C → 0; 0 °C → ~29 (Poor); 5 °C → ~41 (Poor); 8 °C → ~76 (Great); 12–26 °C → 100; 30 °C → ~67 (Acceptable); 35 °C → ~25 (Poor); 38 °C → 0.

### Sub-score curve: rain

- **D-06:** Rain sub-score: plateau `score = 100` for `0 ≤ R ≤ 0.5` mm/h (locked default), linear to `0` at **5 mm/h** (meteorological "moderate" rain).
- **D-07:** Reference scores: 0 mm/h → 100; 0.5 mm/h → 100; 1 mm/h → ~89; 2 mm/h → ~67 (Acceptable); 3 mm/h → ~44 (Poor); 5+ mm/h → 0.
- **D-08:** Rain only has a "bad direction" (no negative-rain plateau like temp). Curve is one-sided.

### Sub-score curve: wind

- **D-09:** Wind sub-score: plateau `score = 100` for `0 ≤ W ≤ 15` km/h (locked default), linear to `0` at **45 km/h** (cyclist-sources "very hard" / "hazardous" territory).
- **D-10:** Reference scores: 15 km/h → 100; 20 km/h → ~83; 25 km/h → ~67 (Acceptable); 30 km/h → ~50 (Acceptable); 35 km/h → ~33 (Poor); 45+ km/h → 0.
- **D-11:** Wind is one-sided (no penalty for low wind). Curve mirrors rain in shape.

### Tolerance slider semantics

- **D-12:** Tolerance sliders (Phase 6) **stretch the shoulder span**, not the plateau. Plateau bounds (12–26, 0.5, 15) are fixed canonical thresholds; sliders adjust *only* the unrideable edge.
- **D-13:** `WeatherTolerances` class in Phase 1 must therefore carry one value per factor representing **shoulder span** (or equivalently, the unrideable edge). Suggested shape: `{ coldEdge: -5.0, hotEdge: 38.0, rainEdge: 5.0, windEdge: 45.0 }` — Phase 6 sliders move these.

### Aggregation formula (sub-scores → overall hourly score)

- **D-14:** `overall_hour = 0.6 · min(temp, rain, wind) + 0.4 · mean(temp, rain, wind)`.
- **D-15:** Rationale: pure mean lets unrideable slots score as "Great" (100/100/30 → 77), violating the core value claim. Pure min is too pessimistic (100/100/85 → 85). Hybrid catches killer factors (100/100/30 → 49, hidden) while rewarding near-balanced days (100/100/85 → 89).
- **D-16:** Reference values (must hold via unit tests): 100/100/100 → 100; 100/100/85 → 89; 100/100/50 → 63; 100/100/30 → 49; 70/40/90 → 51; 65/65/65 → 65.

### Slot generation

- **D-17:** An hour qualifies as part of a contiguous "good" run iff `overall_hour ≥ 50`. A score of 49 breaks the run; 51 continues it. Matches SLOT-04 ("Poor <50 hidden").
- **D-18:** Slot durations: **2h, 3h, 4–5h** (per SLOT-01). The 4–5h band is a *range*: SlotGenerator should emit a 4h slot if exactly 4 contiguous hours qualify, a 5h slot if 5+ qualify (cap at 5h for v1).
- **D-19:** Slot boundary convention: **`[start, end)` exclusive end** (per SLOT-02 + Pitfall 5). Documented in code comment on `RideSlot.end` field.
- **D-20:** **Slot overall score** = arithmetic mean of its hourly `overall_hour` values. **Slot tier** comes from thresholds applied to slot.overall: ≥85 Perfect, 70–84 Great, 50–69 Acceptable, <50 Poor (hidden per SLOT-04).
- **D-21:** Within a 4–5h good run, SlotGenerator emits **all valid sub-slots** (2h, 3h, 4h, 5h) as separate `RideSlot` objects. De-duplication / preferred-length filtering happens later in `AvailabilityFilter` or the UI based on user's ride-length preferences (Phase 6). Phase 1 always emits all options.

### Temperature input source

- **D-22:** Temp sub-score consumes `apparent_temperature` (feels-like). Wind sub-score stays separate (handles bike-handling + power output — a different physical concern from thermal comfort).
- **D-23:** Null cascade: `apparent_temperature` → fall back to `temperature_2m` → fall back to clamp at **50/100 "uncertain"** (per SCOR-04). Each step has a unit test.
- **D-24:** `HourlyForecast` model must carry **both** `apparentTemperature` and `temperature2m` as `double?` fields — InsightsSheet (Phase 5) shows both to the user.

### Null handling (cross-cutting)

- **D-25:** Any sub-score whose primary input is null clamps to **50/100 "uncertain"** rather than crashing or coercing to 0 (per SCOR-04 + Pitfall 4).
- **D-26:** When `≥1` sub-score is "uncertain (50)", the overall hourly score is still computed by the standard formula (D-14). The aggregation pipeline does not treat null specially; only the sub-score functions do.

### Claude's Discretion

- **Skeleton scope:** User did not pick "Skeleton scope" as a discussion area. My call: Phase 1 runs `flutter create`, scaffolds the full `lib/{core,domain,data,features,platform}/` tree (empty subfolders + barrel files where applicable), but populates **only** `lib/domain/` with real code. `main.dart` boots a minimal `MaterialApp`. CI is **deferred** to a later phase — not in scope for Phase 1. Rationale: scaffolding the tree once is cheap and prevents future phases from re-laying-out folders; CI is wasted effort until there's something meaningful for it to verify beyond `dart test` (which the developer can run locally).
- **Test fixture strategy:** User did not pick. My call: use **inline literal fixtures** for boundary unit tests (one fixture per edge case, defined at the top of each test file). Add a shared `test/fixtures/amsterdam_typical_day.dart` with a hand-crafted 24-hour representative dataset for integration-style scoring tests. Avoid loading real Open-Meteo JSON from disk in Phase 1 — that introduces I/O into the domain test suite. Rationale: pure-Dart, no asset loading, fast tests.
- **Dart record types vs Freezed:** `freezed` is on the locked stack (CLAUDE.md). But for Phase 1 the only models are pure value objects with `==`, `hashCode`, and `copyWith`. My call: **use Freezed for all domain models** even in Phase 1 — it's already in the stack, avoids a refactor in Phase 2, and gives JSON serialization for free when Phase 2 wires Open-Meteo deserialization.
- **Tier as sealed class:** CLAUDE.md mentions "sealed classes + pattern matching for ride slot quality tiers (Perfect/Great/Acceptable/Poor)". My call: **adopt** — `sealed class RideTier` with `Perfect`, `Great`, `Acceptable`, `Poor` cases. Cleaner pattern-matching, no stringly-typed tier comparisons.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project-level (locked)
- `.planning/PROJECT.md` — Project vision, locked constraints (tech stack, platforms, budget, no-backend, performance), key decisions table. Plateau defaults for temp/rain/wind locked here.
- `.planning/REQUIREMENTS.md` — All v1 REQ-IDs. Phase 1 implements SCOR-01..05, SLOT-01..04. Read these requirement bodies verbatim — they are normative.
- `.planning/ROADMAP.md` §"Phase 1" — Success criteria for this phase (5 must-be-TRUE items). Verifier will check these.
- `/Users/joostmouw/ridewindow/CLAUDE.md` — Locked tech stack (Flutter 3.x, Dart 3.x, Freezed, sealed classes for tier).

### Research (read before planning)
- `.planning/research/ARCHITECTURE.md` §"Recommended Folder Structure" — Canonical `lib/` tree shape. Phase 1 scaffolds this.
- `.planning/research/ARCHITECTURE.md` §"Component Responsibilities" — Defines what `ScoringEngine`, `SlotGenerator`, `AvailabilityFilter` each own.
- `.planning/research/ARCHITECTURE.md` §"Anti-Patterns to Avoid" — Especially #1 (no scoring logic in UI) and #4 (don't persist computed slots).
- `.planning/research/PITFALLS.md` Pitfall 4 — Null propagation in scoring. Must produce a test that proves null doesn't coerce to 0.
- `.planning/research/PITFALLS.md` Pitfall 5 — Off-by-one in slot boundaries. Property tests required.
- `.planning/research/PITFALLS.md` Pitfall 1 — `setState() after dispose()` convention. Establish `mounted` check pattern from day one even though no UI exists yet (just a `dev_notes.md` or convention doc).

### External (cited in discussion, for scoring curve justification)
- https://windy.app/blog/bicycle-riding-temperature.html — Temperature thresholds source
- https://www.cyclingweekly.com/fitness/training/what-to-wear-cycling-a-temperature-by-temperature-cycling-dress-guide — Granular temperature bands
- https://weatherontheway.app/blog/weather-safety-thresholds-for-cyclists — Wind & cold thresholds
- https://www.roadbikerider.com/too-much-wind-cycling/ — Wind speed cycling thresholds
- https://www.baranidesign.com/faq-articles/2020/1/19/rain-rate-intensity-classification — Meteorological rain intensity standards

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **None yet** — this is the first phase and `lib/` is empty. Phase 1 *creates* the assets that Phases 2–10 reuse.

### Established Patterns
- **Pure-Dart domain isolation** (ARCHITECTURE.md): `lib/domain/` MUST NOT import `package:flutter` or any I/O package. Enforce via `dart test` working without `flutter test`. A `dart analyze` rule or a CI grep can catch violations later.
- **Tier as `sealed class`** (CLAUDE.md): Use Dart 3 sealed classes + pattern matching for `RideTier`, not string enums.
- **Freezed for value objects** (CLAUDE.md): All `lib/domain/models/*.dart` use `freezed` for `==`, `hashCode`, `copyWith`, and (in Phase 2) JSON serialization.

### Integration Points
- `WeatherRepository` (Phase 2) will produce `List<HourlyForecast>` to feed `ScoringEngine`. Phase 1 designs `HourlyForecast` with the fields needed (per FORE-03): `temperature2m`, `apparentTemperature`, `precipitation`, `precipitationProbability`, `windspeed10m`, `winddirection10m` — all `double?`.
- `SlotsNotifier` (Phase 3) will call `ScoringEngine.score(...)` → `SlotGenerator.generate(...)` → `AvailabilityFilter.filter(...)` in sequence. Phase 1 must ensure these compose cleanly as plain Dart functions / classes (Riverpod will inject them as `Provider`s later).
- `UserProfile` carries the `WeatherTolerances`, ride-length preferences, and an availability grid. Phase 1 builds the type; Phase 2 persists it (Drift); Phase 6 lets the user edit it.

</code_context>

<specifics>
## Specific Ideas

- **Curve formula in code:** Each sub-score function is a 3-line piecewise expression. Suggested API: `double scoreTemp(double? apparentTemp, double? rawTemp, WeatherTolerances t)`. Internal helper: `double _linearShoulder(double x, double idealEdge, double zeroEdge)` for DRY. Plateau check is a simple range guard.
- **Worked example for InsightsSheet (Phase 5 prep):** A 12 °C / 0.2 mm / 18 km/h hour scores: temp=100 (plateau), rain=100 (plateau), wind=90 (just out of plateau). Hybrid: 0.6·90 + 0.4·96.67 = 54 + 38.67 = ~93. Tier: Perfect. This worked example should appear as a unit test (it's the canonical "good day" check).
- **Worst-case sanity check:** A 0 °C / 4 mm / 35 km/h hour: temp=~29, rain=~22, wind=~33. Hybrid: 0.6·22 + 0.4·28 = 13.2 + 11.2 = ~24. Tier: Poor (hidden). Also a unit test.
- **Slot composability:** SlotGenerator emits *all* valid lengths within a good run. A 5h contiguous block produces 2h slots (×4 overlapping), 3h slots (×3 overlapping), one 4h slot, one 5h slot. AvailabilityFilter + ride-length prefs prune later. Phase 1 keeps generation unopinionated.
- **Reference dataset for tests:** A hand-crafted 24-hour Amsterdam-typical fixture (cool morning rising to mild afternoon, gentle breeze, dry) should produce: ~12 contiguous good hours, 1 Perfect 4h slot, several Great 2h/3h options. Used as the "integration" scoring test.

</specifics>

<deferred>
## Deferred Ideas

- **`precipitation_probability` weighting** — Whether the rain sub-score should penalise high-probability dry hours (e.g., 0 mm but 80% chance of rain). For Phase 1 the rain sub-score only consumes `precipitation` (mm/h). Probability handling deferred to Phase 2 or 3 when real data flows.
- **Wind direction (`winddirection_10m`) handling** — For v1, only `windspeed_10m` is scored. Direction (tailwind vs headwind on a route) is route-aware and out of scope (PROJECT.md "Out of Scope: route planning").
- **CI / GitHub Actions pipeline** — Not in Phase 1. A `dart test` invocation locally is sufficient until Phase 10 release prep, when a CI run on PR becomes worthwhile.
- **Tolerance slider UI semantics** — Decided "stretch the shoulder" model (D-12) in Phase 1; Phase 6 builds the actual sliders. Slider range (e.g., 0.5× to 2.0× of canonical shoulder span) is a Phase 6 detail.
- **Sun / UV / cloud cover** — Open-Meteo provides these; they affect apparent temperature on hot days. Out of scope for v1 scoring.
- **Property-based testing (e.g., `glados`)** — Considered for slot-boundary tests. Phase 1 uses example-based tests with explicit edge cases (faster to write, easier to debug). Property tests can be added later if a slot bug appears in practice.

</deferred>

---

*Phase: 1 — Project skeleton + scoring domain*
*Context gathered: 2026-06-02*
