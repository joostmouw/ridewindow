---
phase: 04-ui-phase-a-onboarding-home-welcome
plan: "01"
subsystem: providers/domain
tags: [availability, riverpod, breaking-change, tdd]
dependency_graph:
  requires: ["03-03"]
  provides: ["Map<DateTime, BlockType> API for AvailabilityNotifier"]
  affects: ["lib/providers/availability_notifier.dart", "lib/domain/services/availability_filter.dart", "lib/providers/slots_notifier.dart"]
tech_stack:
  added: []
  patterns: ["BlockType enum for typed availability cells", "try-catch SharedPreferences deserialization for corrupt entry skip"]
key_files:
  created: []
  modified:
    - lib/providers/availability_notifier.dart
    - lib/providers/availability_notifier.g.dart
    - lib/domain/services/availability_filter.dart
    - lib/providers/slots_notifier.dart
    - test/providers/availability_notifier_test.dart
    - test/domain/services/availability_filter_test.dart
    - test/providers/slots_notifier_test.dart
    - test/providers/integration_test.dart
decisions:
  - "BlockType enum placed in availability_notifier.dart (not a separate file) — simpler for Phase 4; refactor in Phase 6 if needed"
  - "domain→providers import direction in availability_filter.dart accepted per PATTERNS.md note (temporary, Phase 6 refactor)"
  - "try-catch around SharedPreferences deserialization skips corrupt entries per T-04-01 threat mitigation"
metrics:
  duration: "~10 minutes"
  completed: "2026-06-03"
  tasks_completed: 2
  files_changed: 8
---

# Phase 4 Plan 01: AvailabilityNotifier Map<DateTime, BlockType> Upgrade Summary

**One-liner:** Upgraded AvailabilityNotifier from Set<DateTime> to Map<DateTime, BlockType> with BlockType enum, seedPreset method, and updated AvailabilityFilter/SlotsNotifier — enabling Phase 6 three-state availability cell rendering.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | BlockType enum + AvailabilityNotifier upgrade (TDD) | f1d01ea | availability_notifier.dart, availability_notifier.g.dart, availability_notifier_test.dart |
| 2 | AvailabilityFilter + SlotsNotifier Map<DateTime, BlockType> | 8e3232d | availability_filter.dart, slots_notifier.dart, availability_filter_test.dart, integration_test.dart, slots_notifier_test.dart |

## What Was Built

### Task 1: AvailabilityNotifier (TDD — RED/GREEN cycle)

**RED phase:** Updated `test/providers/availability_notifier_test.dart` to use `Map<DateTime, BlockType>`, `toggleCustomHour`, `seedPreset`, and `clearAll` with typed map expectations. Tests failed with compile errors as expected.

**GREEN phase:** Rewrote `lib/providers/availability_notifier.dart`:
- Added `enum BlockType { work, custom }` above the class
- Changed `build()` return type to `Future<Map<DateTime, BlockType>>`
- Renamed `toggleHour` to `toggleCustomHour` (adds/removes `BlockType.custom` entries)
- Added `seedPreset(Map<DateTime, BlockType> preset)` — replaces full map and persists
- Updated `clearAll()` to emit typed empty map `const AsyncData(<DateTime, BlockType>{})`
- Updated `_persist()` to serialise entries as `"ISO8601|blocktype"` strings
- Wrapped deserialization in try-catch, skipping corrupt entries (T-04-01 mitigation)
- Ran `dart run build_runner build` to regenerate `availability_notifier.g.dart`

All 6 AvailabilityNotifier tests pass.

### Task 2: AvailabilityFilter + SlotsNotifier + test fixes

Updated `lib/domain/services/availability_filter.dart`:
- Changed all three method signatures from `Set<DateTime>` to `Map<DateTime, BlockType>`
- Changed `blockedHours.contains(current)` to `blockedHours.containsKey(current)` in `_overlapsBlocked`
- Added import for `BlockType` from `availability_notifier.dart`

Updated `lib/providers/slots_notifier.dart`:
- Changed `_determineReason` parameter type from `Set<DateTime>` to `Map<DateTime, BlockType>`

Fixed downstream test files (Rule 1 — breaking type change propagates to tests):
- `availability_filter_test.dart`: Changed `{h(9)}` set literals to `{h(9): BlockType.custom}` map literals; added `BlockType.work` test case
- `slots_notifier_test.dart`: Updated `FakeAvailabilityNotifier` to return `Map<DateTime, BlockType>`; fixed allBlocked test using `Map.fromEntries`
- `integration_test.dart`: Updated `EmptyAvailabilityNotifier.build()` return type; renamed `toggleHour` → `toggleCustomHour`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FakeAvailabilityNotifier in slots_notifier_test.dart used old Set<DateTime> type**
- **Found during:** Task 2 full test suite run
- **Issue:** After updating AvailabilityNotifier, FakeAvailabilityNotifier subclasses in test files still had the old `Future<Set<DateTime>> build()` signature
- **Fix:** Updated FakeAvailabilityNotifier and EmptyAvailabilityNotifier in both test files; fixed Set literal to Map in blockedHours construction
- **Files modified:** test/providers/slots_notifier_test.dart, test/providers/integration_test.dart
- **Commit:** 8e3232d (included in Task 2 commit)

**2. [Rule 1 - Bug] availability_filter_test.dart used old Set<DateTime> literals**
- **Found during:** Task 2 full test suite run
- **Issue:** All `{h(n)}` literals in filter tests were `Set<DateTime>` but the method now requires `Map<DateTime, BlockType>`
- **Fix:** Updated all literals to `{h(n): BlockType.custom}` maps; added a `BlockType.work` test case as bonus coverage
- **Files modified:** test/domain/services/availability_filter_test.dart
- **Commit:** 8e3232d (included in Task 2 commit)

## Verification Results

```
dart analyze lib/ → No issues found
flutter test --reporter=compact → 101 tests passed (was 95 before this plan, +6 new AvailabilityNotifier tests)
grep enum BlockType lib/providers/availability_notifier.dart → 1
grep "Map<DateTime, BlockType>" lib/providers/availability_notifier.dart → 5
grep "Map<DateTime, BlockType>" lib/domain/services/availability_filter.dart → 3
```

## Success Criteria Verification

1. `enum BlockType { work, custom }` exists in lib/providers/availability_notifier.dart — PASS
2. `AvailabilityNotifier.build()` returns `Future<Map<DateTime, BlockType>>` — PASS
3. `toggleCustomHour`, `seedPreset`, `clearAll` present with correct signatures — PASS
4. `AvailabilityFilter.apply` accepts `Map<DateTime, BlockType>` — PASS
5. `dart analyze lib/` reports No issues found — PASS
6. `flutter test --reporter=compact` passes all 101 tests, no regressions — PASS

## Threat Model Applied

| Threat | Disposition | Applied |
|--------|-------------|---------|
| T-04-01 Tampering via SharedPreferences deserialization | mitigate | try-catch wraps `DateTime.parse` + `BlockType.values.byName`; corrupt entries are skipped and logged |
| T-04-02 BlockType in SharedPreferences information disclosure | accept | Client-side only, not PII |

## Self-Check: PASSED

Files verified:
- lib/providers/availability_notifier.dart — FOUND
- lib/providers/availability_notifier.g.dart — FOUND
- lib/domain/services/availability_filter.dart — FOUND
- lib/providers/slots_notifier.dart — FOUND
- test/providers/availability_notifier_test.dart — FOUND

Commits verified:
- f1d01ea — FOUND
- 8e3232d — FOUND
