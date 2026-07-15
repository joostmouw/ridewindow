# Deferred Items — quick-260714-spo

## Pre-existing whole-suite test isolation failures (out of scope)

Running the full `flutter test` (no path argument, whole repo) produces 69 failures across
~20 unrelated test files (`weather_repository_test.dart`, `availability_screen_test.dart`,
`profile_screen_location_test.dart`, `calendar_service_test.dart`, `home_screen_test.dart`,
`ride_detail_screen_test.dart`, and others). This is a pre-existing, already-tracked test-suite
health issue (see STATE.md decisions log: "note test-suite health finding on #11") — not
introduced by this plan.

**Verified:** `test/features/week_agenda_screen_test.dart` (this plan's new file) passes all
7 tests both in isolation (`flutter test test/features/week_agenda_screen_test.dart` — 7/7
pass, no failures) and when run as part of the full suite (grep for
`week_agenda.*\[E\]` across the full-suite run output returns zero matches). None of the
69 whole-suite failures originate from this plan's files.

Root cause is very likely cross-file global-state bleed when many widget tests run in the
same isolate (e.g. `SharedPreferences` mock state, Riverpod provider container state, or
`ServicesBinding` initialization order) — consistent with the same class of issue already
flagged in prior quick tasks' deferred-items.md files. Not investigated further here; out of
scope for this plan's Agenda gesture rewrite.

**Recommendation:** A future quick task or phase plan should investigate why `flutter test`
(whole-suite) produces far more failures than the sum of each file's isolated run, likely by
auditing `setUp`/`tearDown` hygiene (global mutable statics, unclosed `Timer`s, mock reset
ordering) across the test suite.
