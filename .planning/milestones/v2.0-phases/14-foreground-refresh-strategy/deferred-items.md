# Deferred Items — Phase 14 Plan 01

## Pre-existing test failure (out of scope)

- **Test:** `test/providers/slots_notifier_test.dart` — `'recomputes on profile change — slots recomputeren bij tolerantie-wijziging'`
- **Failure:** `Expected: not <5> / Actual: <5>` at line 210 (slot-count comparison between a wide-tolerance and a strict-tolerance profile).
- **Root cause:** Not caused by this plan. Confirmed by running the same test against the pre-Task-2 `lib/providers/slots_notifier.dart` (git HEAD before this plan's commits) — the test fails identically without any of this plan's changes. Likely a pre-existing fixture/assertion drift (e.g. the strict-tolerance profile in the test fixture no longer produces a different slot count than the base fixture, or the underlying scoring/slot-generation logic changed since this test was last green).
- **Scope decision:** Per the executor's scope boundary rule ("only auto-fix issues directly caused by the current task's changes"), this failure is out of scope for Phase 14 Plan 01 and was not fixed. It is logged here rather than fixed inline.
- **Suggested follow-up:** File a quick-fix or debug task to investigate `SlotsNotifier`/`ScoringEngine`/`SlotGenerator` behavior against the strict-tolerance fixture in a future session.
