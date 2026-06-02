# Phase 1: Project skeleton + scoring domain - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 1 — Project skeleton + scoring domain
**Areas discussed:** Sub-score curves, Aggregation, Feels-like vs raw temp

---

## Area Selection

The user was offered 4 candidate gray areas. They selected 3:

| Option | Description | Selected |
|---|---|---|
| Sub-score curve shape | How temp/rain/wind translate from ideal (100) to unrideable (0) | ✓ |
| Aggregation (sub → overall) | Weighted mean vs min vs hybrid | ✓ |
| Feels-like vs raw temp | apparent_temperature vs temperature_2m for the temp sub-score | ✓ |
| Skeleton scope | flutter create + full lib/ tree vs domain-only | (skipped — Claude's discretion) |

---

## Sub-score curves

### Q1 — Temperature curve

The user asked for online research grounding before deciding. Three cycling sources were consulted (Windy.app, Cycling Weekly, Outside Online + Velocite + Weather on the Way) and a recommendation was built from triangulated consensus: plateau 12–26 °C, asymmetric shoulders (17 °C cold, 12 °C hot) because cold is unpleasant-but-rideable while heat is dangerous.

| Option | Description | Selected |
|---|---|---|
| Lock as proposed (plateau 12–26, edges −5 / +38, asymmetric) | Backed by 3 cycling sources. Asymmetric to match real cyclist behaviour. | ✓ |
| Lock but cold less forgiving (edge 0 °C) | Tighter cold curve — 5 °C scores ~17 (Poor) instead of ~41. | |
| Lock but hot less harsh (edge 40 °C) | Hot shoulder more forgiving — 32 °C scores ~57 instead of ~50. | |
| Show one more comparison | Plot 3–4 alternative curves side by side. | |

**User's choice:** Lock as proposed.
**Notes:** Asked explicitly to research online before deciding. Picked the asymmetric data-backed recommendation.

### Q2 — Rain and wind curves

Research added (Weather on the Way, Road Bike Rider, Barani Design meteorology). Rain meteorological "moderate" = 2.6–7.5 mm/h. Wind cyclist-hard zone starts at 25–30 km/h. Recommendation: rain edge 5 mm/h, wind edge 45 km/h, both with locked plateau.

| Option | Description | Selected |
|---|---|---|
| Lock both as proposed (rain edge 5 mm/h, wind edge 45 km/h) | Honest defaults for a casual Dutch cyclist; sliders adjust. | ✓ |
| Rain stricter (edge 3 mm/h) | 2 mm/h scores ~40 (Poor) instead of ~67 (Acceptable). | |
| Wind more forgiving (edge 55 km/h) | 30 km/h scores ~63 instead of 50. | |
| Both: rain stricter + wind more forgiving | Conservative on rain, lenient on wind. | |

**User's choice:** Lock both as proposed.

### Q3 — Tolerance slider semantics

| Option | Description | Selected |
|---|---|---|
| Stretch the shoulder | Slider widens/narrows the shoulder span only; plateau fixed. | ✓ |
| Shift the plateau | Slider moves both plateau edge and unrideable edge together. | |
| Single multiplier | One 0.0–2.0 float per factor applied to span. | |
| Defer to Phase 6 | Hardcode in Phase 1, refactor when sliders arrive. | |

**User's choice:** Stretch the shoulder.
**Notes:** Cleanest model — plateau represents biology, sliders represent personal hardiness. Implies `WeatherTolerances` carries one shoulder-edge value per factor.

---

## Aggregation

### Q1 — Sub-scores → overall hourly score

Presented a 6-row table comparing 4 formulas across representative hour conditions (ideal, slightly windy, borderline, rainy+cool, one-factor killer, balanced meh). Showed that pure mean and weighted mean both let "one-factor killer" hours score as Great (77/100), violating PROJECT.md's core value claim.

| Option | Description | Selected |
|---|---|---|
| 0.6·min + 0.4·mean | Hybrid. Penalizes killer factors but rewards near-balanced days. | ✓ |
| Pure minimum | Worst factor wins outright. Honest but pessimistic. | |
| Weighted mean (rain ×1.5) | Lets 100/100/30 score as Great. | |
| Equal-weight arithmetic mean | Simplest, but lets unrideable slots score Great. | |

**User's choice:** 0.6·min + 0.4·mean.

### Q2 — Hour qualification floor

| Option | Description | Selected |
|---|---|---|
| Hour overall ≥ 50 | Matches SLOT-04 ("Poor <50 hidden"). | ✓ |
| Hour overall ≥ 70 | Only Great-or-better hours qualify. Risk: empty winter weeks. | |
| Hour overall ≥ 40 | More permissive; surfaces borderline slots. | |
| No floor — every contiguous block is a slot | Cleanest separation; lets downstream filter. | |

**User's choice:** Hour overall ≥ 50.

### Q3 — Slot tier from hourly scores

| Option | Description | Selected |
|---|---|---|
| Same formula on slot mean | Slot overall = mean of hourly overall scores; tier from standard thresholds. | ✓ |
| Min hourly determines tier | Worst hour pulls badge down. Very pessimistic. | |
| 0.6·min + 0.4·mean across hours | Same hybrid as within an hour. Adds cognitive load. | |
| Score the slot's middle hours (drop edges) | Hard to test, hard to explain. | |

**User's choice:** Same formula on slot mean.

---

## Feels-like vs raw temp

### Q1 — Which temperature value feeds the temp sub-score

Presented a mental-model split: temp sub-score = "how does it feel on skin?" (thermal comfort); wind sub-score = "how hard to control + power output?" (bike handling). Under that split, `apparent_temperature` is the correct input — it's not double-counting wind, it's measuring a different physical concern.

| Option | Description | Selected |
|---|---|---|
| apparent_temperature, fall back to raw | Captures wind chill; falls back if null; uncertain clamp if both null. | ✓ |
| temperature_2m only | Clean but under-penalises cold-windy days. | |
| Hybrid: apparent cold-side, raw hot-side | More accurate but asymmetric code path. | |
| temperature_2m, show apparent only in UI | Simple scoring; UI shows feels-like for transparency. | |

**User's choice:** apparent_temperature, fall back to raw.
**Notes:** Implies `HourlyForecast` carries both `apparentTemperature` and `temperature2m` as nullable doubles (Phase 5 InsightsSheet shows both).

---

## Claude's Discretion

- **Skeleton scope** — User explicitly skipped this area. Decision: run `flutter create`, scaffold the full `lib/{core,domain,data,features,platform}/` tree (empty stub folders for non-Phase-1 layers), populate only `lib/domain/`. Minimal `MaterialApp` in `main.dart`. CI deferred. See CONTEXT.md D-Discretion.
- **Test fixture strategy** — Inline literals for boundary unit tests + one shared hand-crafted Amsterdam 24h fixture for integration-style scoring tests. No real Open-Meteo JSON in Phase 1.
- **Freezed for Phase 1 domain models** — Use Freezed even though Phase 1 has no JSON serialization needs yet. It's on the locked stack and avoids a Phase 2 refactor.
- **`sealed class RideTier`** — Adopt Dart 3 sealed-class pattern (per CLAUDE.md). No string enums for tier comparisons.

---

## Deferred Ideas

- **`precipitation_probability` weighting** — Deferred to Phase 2/3. Phase 1 rain sub-score consumes `precipitation` (mm/h) only.
- **Wind direction handling** — Out of v1 scope (no route planning).
- **CI / GitHub Actions** — Deferred until Phase 10 release prep.
- **Tolerance slider UI range** (e.g., 0.5×–2.0× span) — Phase 6 detail.
- **Sun / UV / cloud cover** in scoring — Out of v1 scope.
- **Property-based testing (`glados`)** — Phase 1 uses example-based tests; revisit if a slot bug appears.
