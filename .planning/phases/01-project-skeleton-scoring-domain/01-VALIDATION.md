---
phase: 1
slug: project-skeleton-scoring-domain
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `package:test` (Dart 3.x — pure-Dart, NOT `flutter_test`) |
| **Config file** | `dart_test.yaml` (Wave 0 — optional) + `pubspec.yaml` dev_dependencies |
| **Quick run command** | `dart test test/domain/<area>_test.dart` |
| **Full suite command** | `dart test` |
| **Coverage command** | `dart test --coverage=coverage && dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib/domain` |
| **Estimated runtime** | ~5–10 seconds (pure Dart, no I/O, no Flutter engine boot) |

---

## Sampling Rate

- **After every task commit:** Run quick test for the file changed (`dart test test/domain/<area>_test.dart`)
- **After every plan wave:** Run full suite (`dart test`)
- **Before `/gsd-verify-work`:** Full suite green + 100% line coverage of `lib/domain/` verified via lcov
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

> Filled by planner. Each row links a plan task to its REQ-ID, the test that proves it, and the command that runs that test.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 0 | (env gate) | — | `flutter --version` succeeds; Flutter SDK installed | manual | `flutter --version` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 0 | SCOR-03 | — | `dart test` runnable on fresh scaffold (spike) | smoke | `dart test test/smoke_test.dart` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | (scaffold) | — | `flutter run` boots empty MaterialApp | manual | `flutter run -d <android-emu>` | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 2 | SCOR-01, SCOR-02 | — | Freezed models compile + equality test passes | unit | `dart test test/domain/models/` | ❌ W0 | ⬜ pending |
| 01-04-01 | 04 | 2 | SCOR-03 | T-1-01 | `lib/domain/**/*.dart` imports no `package:flutter/`, `dart:io`, `package:http`, `package:drift` | structural | `dart test test/structure/no_flutter_imports_test.dart` | ❌ W0 | ⬜ pending |
| 01-05-01 | 05 | 3 | SCOR-01 | — | `scoreTemp` returns reference values from CONTEXT.md D-05 | unit | `dart test test/domain/scoring/score_temp_test.dart` | ❌ W0 | ⬜ pending |
| 01-05-02 | 05 | 3 | SCOR-01 | — | `scoreRain` returns reference values from CONTEXT.md D-07 | unit | `dart test test/domain/scoring/score_rain_test.dart` | ❌ W0 | ⬜ pending |
| 01-05-03 | 05 | 3 | SCOR-01 | — | `scoreWind` returns reference values from CONTEXT.md D-10 | unit | `dart test test/domain/scoring/score_wind_test.dart` | ❌ W0 | ⬜ pending |
| 01-05-04 | 05 | 3 | SCOR-04 | — | Null `apparent_temperature` falls back to `temperature_2m`; both null → 50/100 | unit | `dart test test/domain/scoring/null_cascade_test.dart` | ❌ W0 | ⬜ pending |
| 01-06-01 | 06 | 3 | SCOR-01 | — | `aggregate(temp,rain,wind)` matches reference values from CONTEXT.md D-16 | unit | `dart test test/domain/scoring/aggregate_test.dart` | ❌ W0 | ⬜ pending |
| 01-07-01 | 07 | 3 | SLOT-01, SLOT-02 | — | `SlotGenerator.generate()` emits all sub-slots (2h/3h/4h/5h) within good runs; `[start, end)` boundary correct | unit | `dart test test/domain/slots/slot_generator_test.dart` | ❌ W0 | ⬜ pending |
| 01-07-02 | 07 | 3 | SLOT-04 | — | All four tiers (Perfect/Great/Acceptable/Poor) covered + tier thresholds correct | unit | `dart test test/domain/slots/ride_tier_test.dart` | ❌ W0 | ⬜ pending |
| 01-08-01 | 08 | 3 | SLOT-03 | — | `AvailabilityFilter` removes slots overlapping any blocked hour | unit | `dart test test/domain/slots/availability_filter_test.dart` | ❌ W0 | ⬜ pending |
| 01-09-01 | 09 | 4 | SCOR-05 | — | Amsterdam-typical 24h fixture produces expected Perfect/Great/Acceptable slots | integration | `dart test test/domain/scoring/amsterdam_fixture_test.dart` | ❌ W0 | ⬜ pending |
| 01-10-01 | 10 | 4 | SCOR-03 | — | `dart test --coverage` + `format_coverage` produces lcov with 100% lib/domain/ line coverage | coverage | `bash scripts/verify_coverage.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Planner: this map is a starting skeleton derived from the research; reconcile and refine against the actual PLAN.md task IDs you emit. The Task IDs above are illustrative — replace with the real IDs you assign and link each row to its plan number.*

---

## Wave 0 Requirements

- [ ] **Environment check (BLOCKING)** — `flutter --version` and `dart --version` succeed (Dart 3.x + Flutter 3.x). Researcher confirmed Flutter is NOT installed on this machine; this must be resolved as the first task. (See RESEARCH.md §Bootstrap.)
- [ ] `test/smoke_test.dart` — 1-line `expect(true, isTrue)` proving `dart test` (not `flutter test`) works on the fresh Flutter scaffold. Per RESEARCH.md Open Question #2 — if `dart test` cannot find `package:test` on the Flutter project, fallback is to extract `lib/domain/` to a sub-package (much bigger change; verify cheap upfront).
- [ ] `test/structure/no_flutter_imports_test.dart` — structural test that greps every file under `lib/domain/` and fails if any contains `import 'package:flutter/...'`, `import 'dart:io'`, `import 'package:http/...'`, or `import 'package:drift/...'`.
- [ ] `dart_test.yaml` (optional) — configure test reporter / timeout.
- [ ] `pubspec.yaml` dev_dependencies installed: `test`, `freezed`, `freezed_annotation`, `build_runner`, `json_serializable`, `coverage`. (Versions per RESEARCH.md §Bootstrap.)
- [ ] `scripts/verify_coverage.sh` (or equivalent) — runs `dart test --coverage`, converts JSON → lcov via `format_coverage`, filters `.freezed.dart`/`.g.dart` out, fails if any line in `lib/domain/` is uncovered.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `flutter run` boots an empty MaterialApp on Android emulator | (Phase Goal — `lib/main.dart` works) | Requires Android emulator + Flutter SDK; not automatable in pure-Dart test harness | `flutter emulators --launch <id>` → `flutter run -d <android-emu>` → confirm white/themed `MaterialApp` Scaffold loads without errors |
| Flutter SDK installed and on PATH | (env prerequisite) | One-time machine setup | `flutter --version` exits 0 with version ≥ 3.x; `flutter doctor` shows no blocking issues for Android |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (planner to confirm during plan generation)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter (after planner reconciles task map)

**Approval:** pending
