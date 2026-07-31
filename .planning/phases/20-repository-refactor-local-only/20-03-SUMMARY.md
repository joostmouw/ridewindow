---
phase: 20-repository-refactor-local-only
plan: 03
subsystem: database
tags: [shared_preferences, riverpod, repository-pattern, planned-rides, D-09, D-10, D-11]

# Dependency graph
requires:
  - phase: 20-repository-refactor-local-only
    provides: "Plan 20-01/20-02's repository-pattern shape (constructor-injected SharedPreferences, public key constants, save(..., {bool stamp = true}), readUpdatedAt() never retroactively stamping) — this plan replicates it for the planned-rides domain and adds the async-notifier-reacting-to-authStateProvider shape"
provides:
  - PlannedRidesRepository (lib/data/repositories/planned_rides_repository.dart) — the sole owner of the `planned_rides` key and the additive `planned_rides.updatedAt` key
  - PlannedRide relocated to plain-Dart lib/domain/models/planned_ride.dart, re-exported from planned_rides_notifier.dart
  - PlannedRidesNotifier is now Future<List<PlannedRide>> AsyncNotifier that watches authStateProvider as a pure reactivity trigger (D-11), proven not to blank the list on rebuild (D-10)
affects: [20-04, 20-05, 21]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Repository pattern (from 20-01/20-02, replicated): plain-Dart class takes SharedPreferences via constructor, exposes public static const key constants, no Riverpod/Flutter imports"
    - "Async-notifier-watches-auth-as-pure-trigger: `ref.watch(authStateProvider);` as a bare statement inside build() — establishes the rebuild dependency without using the emitted value, since there is no cloud path yet (D-11)"
    - "D-10 proven, not assumed: a ProviderContainer test with an active `container.listen` and a broadcast StreamController<User?> override demonstrates that Riverpod's default AsyncLoading-carries-previous-.value behavior actually holds for this notifier"

key-files:
  created:
    - lib/domain/models/planned_ride.dart
    - lib/data/repositories/planned_rides_repository.dart
    - test/data/repositories/planned_rides_repository_test.dart
    - test/providers/planned_rides_notifier_test.dart
  modified:
    - lib/providers/planned_rides_notifier.dart
    - lib/providers/planned_rides_notifier.g.dart

key-decisions:
  - "PlannedRidesNotifier.build() watches authStateProvider as a bare statement (not .future) — the D-11 reactivity trigger fires on every auth transition including the initial Loading→Data transition, without ever blocking build() on the auth stream settling first"
  - "add()/remove()/clearAll() now read via `state.value ?? const []` and write-before-visible (await repo.save(next) before state = AsyncData(next)), same ordering as AvailabilityNotifier's mutators from plan 20-01"
  - "A doc-comment on plannedRidesRepositoryProvider originally quoted the literal string 'sharedPrefsProvider' in prose, tripping the plan's own literal grep acceptance check (same self-inflicted pattern as plan 20-02's deviation #2) — reworded before commit, no behavior change"
  - "plannedRidesRepositoryProvider constructs its repository via SharedPreferences.getInstance() (async), not the app's sharedPrefsProvider — same reasoning as 20-01/20-02"

requirements-completed: []

# Metrics
duration: ~25min
completed: 2026-07-31
---

# Phase 20 Plan 03: Planned Rides Repository Refactor Summary

**PlannedRidesRepository now owns the `planned_rides` key; PlannedRidesNotifier is now an async AsyncNotifier that reacts to authStateProvider purely as a local-reread trigger, with D-10 (previous list survives the rebuild) proven by an explicit ProviderContainer test rather than assumed.**

## Performance

- **Duration:** ~25 min (three task commits between 18:07 and 18:15 local time)
- **Completed:** 2026-07-31
- **Tasks:** 3
- **Files modified:** 6 (2 created domain/repo files, 2 modified notifier + its generated file, 2 created test files)

## Accomplishments

- `PlannedRide` (with its `'time'`-field backwards-compat branch) lives in plain-Dart `lib/domain/models/planned_ride.dart`; the five existing import sites (`home_screen.dart`, `planned_rides_screen.dart`, `ride_detail_screen.dart`, `week_agenda_screen.dart`, `account_section.dart`) keep working unchanged via a re-export from `planned_rides_notifier.dart`.
- `PlannedRidesRepository` is the single source of truth for the `planned_rides` key — identical byte-for-byte write format to the pre-refactor code (D-01) — and additively owns `planned_rides.updatedAt`. The read path's filter (`end.isAfter(todayStart)`) and sort (`by start`) moved from the notifier's `build()` into the repository's `readLocal()`, matching `AvailabilityRepository.readLocal()`'s precedent of normalization living in the repository, not the notifier.
- `PlannedRidesNotifier` went from a synchronous `Notifier<List<PlannedRide>>` to an async `AsyncNotifier<List<PlannedRide>>` that watches `authStateProvider` as a pure reactivity trigger (`ref.watch(authStateProvider);` as a bare statement, value unused) — this is ROADMAP success-criterion 3 and D-11 in code: any auth transition (sign-in, sign-out, account switch) causes a local reread, never a cloud call.
- **D-10 proven, not assumed**: `test/providers/planned_rides_notifier_test.dart` sets up a `ProviderContainer` with `authStateProvider` overridden by a broadcast `StreamController<User?>`, attaches an active listener (required for eager rebuild — see Issues Encountered below), fires an auth transition, and asserts that (a) no state after the first data load ever has `.value == null`, and (b) the intermediate `AsyncLoading` carries the previous list via `.value`. A second test proves the reactivity trigger is real — not just present in code but actually causing a reread — by changing the underlying `SharedPreferences` content between two auth events and confirming the new content only appears after the second event.
- New `test/data/repositories/planned_rides_repository_test.dart` covers the risk the wider suite doesn't: reading both the current (`start`/`end`) and legacy (`time`) on-disk formats, the already-passed filter, sort stability, exact write format, and the stamp/no-stamp/never-retroactive `updatedAt` behavior (D-08).

## Task Commits

Each task was committed atomically:

1. **Task 1: Verhuis PlannedRide naar lib/domain/models/ en schrijf PlannedRidesRepository** - `f944c1e` (refactor)
2. **Task 2: Herschrijf PlannedRidesNotifier als async AsyncNotifier die authStateProvider watcht** - `9bdcd0b` (refactor)
3. **Task 3: Unit-tests voor PlannedRidesRepository en het automatiseerbare bewijs van D-10** - `cdb948c` (test)

_No plan-metadata commit — per worktree isolation rules, STATE.md/ROADMAP.md updates are owned by the orchestrator after merge._

## Files Created/Modified

- `lib/domain/models/planned_ride.dart` - New plain-Dart home for `PlannedRide`, including the complete `'time'`-field backwards-compat branch in `fromJson()`; zero imports beyond dart:core
- `lib/data/repositories/planned_rides_repository.dart` - `readLocal()` (filter + sort moved in from the old `build()`), `save(rides, {stamp})`, `readUpdatedAt()`; owns `kPlannedRidesKey`/`kUpdatedAtKey`
- `lib/providers/planned_rides_notifier.dart` - Re-exports `PlannedRide`; new `plannedRidesRepositoryProvider`; `build()` is now `Future<List<PlannedRide>>` watching `authStateProvider`; `add()`/`remove()`/`clearAll()` are all `Future<void>`, write-then-visible; `_kPrefsKey`/`_persist()` removed
- `lib/providers/planned_rides_notifier.g.dart` - Regenerated via `dart run build_runner build` to add `plannedRidesRepositoryProvider` and switch `PlannedRidesNotifierProvider` to `$AsyncNotifierProvider`
- `test/data/repositories/planned_rides_repository_test.dart` - 8 `test()` blocks: new-format read, old-format (`'time'`) read, already-passed filter, sort-by-start, exact write format, `save()` stamps, `save(stamp: false)` doesn't, `readUpdatedAt()` null on missing field (D-08)
- `test/providers/planned_rides_notifier_test.dart` - 2 tests in a group explicitly named for D-10: the no-null-value-after-first-data + loading-carries-previous-value proof, and the "auth change actually triggers a reread" proof

## Decisions Made

See `key-decisions` in frontmatter. Most consequential: proving D-10 with a real `ProviderContainer` + `StreamController<User?>` test rather than trusting "Riverpod's default behavior should just work" — this surfaced a genuine test-authoring pitfall (see Issues Encountered) that would have made the test pass trivially without ever exercising the rebuild path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Doc-comment on `plannedRidesRepositoryProvider` accidentally embedded the literal string `sharedPrefsProvider`**
- **Found during:** Task 2 acceptance-criteria verification
- **Issue:** The task's acceptance criteria require `grep -c "sharedPrefsProvider" lib/providers/planned_rides_notifier.dart` to be `0`. My first draft's doc-comment explained the design choice by quoting `sharedPrefsProvider` in prose ("niet `sharedPrefsProvider` — die gooit..."), which the literal grep check does not distinguish from an actual dependency — same self-inflicted pattern plan 20-02 documented as its deviation #2.
- **Fix:** Reworded the doc-comment to describe the same behavior ("niet de app-brede prefs-provider hieronder") without quoting the literal identifier.
- **Files modified:** `lib/providers/planned_rides_notifier.dart` (and its regenerated `.g.dart`)
- **Verification:** `grep -c "sharedPrefsProvider" lib/providers/planned_rides_notifier.dart` returns `0`; `flutter analyze` clean.
- **Committed in:** `9bdcd0b` (Task 2 commit)

### Out-of-scope discovery (logged, not fixed — same as plans 20-01/20-02)

**Pre-existing date-boundary bug in `test/platform/notification_service_test.dart`** — already documented in `.planning/phases/20-repository-refactor-local-only/deferred-items.md` from plan 20-01. Confirmed it is still present in this plan's full-suite run (one of the 8 total failures below); not touched, not re-logged.

---

**Total deviations:** 1 auto-fixed (Rule 1, self-inflicted, discovered via the plan's own literal-grep acceptance criteria, fixed before commit). 0 new out-of-scope issues (the notification-service failure was already logged by plan 20-01).
**Impact on plan:** None on this plan's correctness — the fix was a wording-only doc-comment change with no behavioral effect.

## Issues Encountered

**D-10 test timing pitfall (resolved before commit, not a deviation from the plan — the plan explicitly asked Task 3 to "prove, not assume" this behavior, and this is exactly the kind of subtlety that justified that instruction).** An early draft of the D-10 reactivity test called `authController.add(user)` followed immediately by `container.read(plannedRidesProvider.future)`, with no active `container.listen` on `plannedRidesProvider` beyond the one being asserted on. That version's second test (auth-change → reread) failed: the rebuild had not yet been triggered by the time `.future` was re-read, because without an active listener Riverpod does not eagerly recompute a provider on a dependency change — it defers to the next read, and `.future`'s already-resolved previous value was returned instead of awaiting the pending rebuild. A debug harness (`test/providers/_debug_auth_test.dart`, written temporarily to isolate the timing, then deleted before committing — never staged) confirmed that adding an active `container.listen(plannedRidesProvider, (prev, next) {})` — matching how a real `Consumer` widget always has an active listener — makes the provider rebuild eagerly and resolves the race. Both tests in `test/providers/planned_rides_notifier_test.dart` now include this listener and pass deterministically across repeated runs.

**Full-suite `flutter test` result diverges from Task 3's literal numeric floor — this is the plan's own predicted and pre-authorized consequence, not a new failure.** Task 3's acceptance criteria state "minstens 338 geslaagd en niet meer dan 1 gefaald." The actual full-suite result on this plan's final commit is **306 passed / 8 failed**. All 8 failures are accounted for:
- 1 is the pre-existing, already-logged `notification_service_test.dart` date-boundary bug (documented since plan 20-01).
- 7 are **compilation failures**, not assertion failures, in test files that either (a) declare a `FakePlannedRidesNotifier extends PlannedRidesNotifier` with a synchronous `List<PlannedRide> build()` override — no longer valid against the new `Future<List<PlannedRide>> build()` signature — or (b) exercise `lib/features/home/home_screen.dart`, which still calls `.isEmpty`/`.any()`/`.where()` directly on `ref.watch(plannedRidesProvider)`, now `AsyncValue<List<PlannedRide>>` instead of `List<PlannedRide>`. The affected files: `test/features/week_agenda_screen_test.dart`, `test/features/home_screen_test.dart`, `test/features/profile_account_section_test.dart`, `test/features/ride_detail_screen_test.dart`, `test/features/home_screen_refresh_test.dart`, `test/features/detail/ride_detail_screen_calendar_test.dart`, `test/features/home_screen_location_test.dart`.

This is exactly what this plan's own `<verification>` section pre-authorizes in its final bullet: *"Dit plan wijzigt geen enkel bestand onder `lib/features/` ... `flutter analyze` zal in `lib/features/` dus type-fouten tonen totdat 20-05 draait — dat is verwacht en geen falen van dít plan; de acceptance criteria hierboven verifiëren uitsluitend de bestanden in `files_modified`."* The same reasoning extends to the test files that import those `lib/features/` files or their `FakePlannedRidesNotifier` overrides — they are downstream of the identical, deliberately-deferred type change. Per this plan's own scope boundary, `lib/features/*` was explicitly **not** touched (confirmed: `git diff --stat` for this plan's three commits shows zero files under `lib/features/`). The 306/8 numbers, not 338/1, are the correct and expected outcome given the plan's own design; Task 3's numeric floor appears to have been written without accounting for this cascade, and is recorded here as a discrepancy rather than silently reconciled. `flutter analyze` on the exact files in this plan's `files_modified` list (all 5: 3 lib files + 2 test files) shows zero issues, matching every literal acceptance criterion scoped to those files.

**Recommendation for plan 20-05:** once `lib/features/` consumers are updated to handle `AsyncValue<List<PlannedRide>>` (e.g., via `.value ?? const []` per this plan's own `<interfaces>` note), all 7 compile-broken test files should return to green, and the corresponding `FakePlannedRidesNotifier` overrides across those files will need `Future<List<PlannedRide>> build() async => ...` signatures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All three domains (availability, profile, planned rides) now sit behind repositories with the identical shape: constructor-injected `SharedPreferences`, public key constants, `save(..., {bool stamp = true})`, `readUpdatedAt()` never retroactively stamping. `PlannedRidesNotifier` additionally demonstrates the async-notifier-reacting-to-`authStateProvider` shape that D-09/D-10/D-11 required — this is the pattern phase 21's cloud-sync work will build on top of, not replace. Plan 20-04 can now assert the full import graph (all three repositories) is Riverpod/Flutter/Supabase-free. Plan 20-05 has a concrete, scoped list of exactly 7 test files (plus their corresponding `lib/features/` source files) that need updating from `List<PlannedRide>` to `AsyncValue<List<PlannedRide>>` consumption — this list is enumerated above, not left for 20-05 to rediscover.

---
*Phase: 20-repository-refactor-local-only*
*Completed: 2026-07-31*

## Self-Check: PASSED

All created files verified present on disk: `lib/domain/models/planned_ride.dart`,
`lib/data/repositories/planned_rides_repository.dart`,
`test/data/repositories/planned_rides_repository_test.dart`,
`test/providers/planned_rides_notifier_test.dart`,
`.planning/phases/20-repository-refactor-local-only/20-03-SUMMARY.md`.
All 3 commits verified present in `git log`: `f944c1e`, `9bdcd0b`, `cdb948c`.
