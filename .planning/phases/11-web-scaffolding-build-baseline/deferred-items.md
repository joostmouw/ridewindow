# Deferred Items — Phase 11 Plan 01

## Pre-existing `flutter test` failures (out of scope, not fixed)

**Found during:** Task 2 (Build web + run full test suite + Android regression build)

**Observation:** `flutter test` on this plan's changes produces `+135 -77` (135 passed,
77 failed). A baseline check against the phase's starting commit
(`6c6bb557354f2e40723c73c38d46fbac7750f248`, before any Task 1/2 changes were made — a
fresh clone was checked out to that commit in a scratch directory, `flutter pub get` run,
and `flutter test` run there) produced the **identical** result: `+135 -77`.

This confirms the 77 failing tests are pre-existing and unrelated to:
- the `web/` scaffold added in Task 1
- the `kIsWeb` guards added to `lib/main.dart` in Task 1
- the `riverpod` 3.3.2-dev.2 → 3.3.2 (stable) lockfile bump picked up by `flutter pub get`
  in Task 2 (and the corresponding `build_runner` regeneration of `.g.dart` files needed
  to match the new `NotifierProvider.runBuild()` signature)

Per the executor's SCOPE BOUNDARY rule, pre-existing failures in files/areas not touched
by this plan are out of scope and were not fixed here. Representative failing test files:
`test/features/profile_screen_location_test.dart`, `test/features/availability_screen_test.dart`,
and others — many appear related to a `Localizations.of<S>(context, S)!` null-check in
`lib/l10n/app_localizations.dart:71` not finding the `S` delegate in certain test harness
setups, and pre-existing widget/golden mismatches unrelated to web platform work.

**Action taken:** None (fix deferred — out of scope for Phase 11 Plan 01). The plan's
Task 2 acceptance criterion "`flutter test` output contains 'All tests passed!'" could not
be satisfied because the baseline was already broken before this plan started. Verified
instead that this plan introduced **zero new test failures** (identical `+135 -77` before
and after).

**Recommended next step:** A future phase/plan should triage and fix these 77 pre-existing
failures (likely a test-harness localization delegate setup issue plus some unrelated
widget assertions), independent of the v2.0 web milestone.
