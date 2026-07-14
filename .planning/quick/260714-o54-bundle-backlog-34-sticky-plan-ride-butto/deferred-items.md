# Deferred Items — quick-260714-o54

## Pre-existing broken tests in test/features/availability_screen_test.dart (out of scope)

Discovered while adding Task 3's new `group('BACKLOG-35: drag run indicator', ...)` test.

All 11 pre-existing tests in this file (SC-1 through P04-5) fail on `b7a7b7a` (the base
commit this plan started from) — i.e. before any change made by this plan. Root cause:
these tests pump `AvailabilityScreen` inside a bare `MaterialApp(home: AvailabilityScreen())`
with:
1. No `localizationsDelegates`/`supportedLocales` — `S.of(context)` (used throughout
   `AvailabilityScreen`, e.g. `_dagLabels`) throws a null-check failure via
   `Localizations.of<S>(context, S)!`.
2. No `theme:` with the `RideWindowTheme` extension registered — `context.rw` (the
   `RideWindowThemeX` extension, used e.g. in `_buildGrid`'s `LayoutBuilder`) throws a
   null-check failure via `Theme.of(this).extension<RideWindowTheme>()!`.

This mirrors the same class of pre-existing test-infra gap already called out in this
plan's `<interfaces>` section for `test/features/ride_detail_screen_test.dart` and
`test/features/detail/ride_detail_screen_calendar_test.dart` (bare `MaterialApp` with no
`ProviderScope`/localization delegate) — just not previously flagged for this specific file.

**Verified:** running `flutter test test/features/availability_screen_test.dart` against
the unmodified `b7a7b7a` base commit shows `00:01 +0 -11: Some tests failed.` — identical
11-test failure count to what remains after this plan's Task 3 changes. No new failures
were introduced by this plan.

**Resolution applied for this plan:** Task 3's new test
(`group('BACKLOG-35: drag run indicator', ...)`) is self-contained and supplies both
`localizationsDelegates`/`supportedLocales` and a `theme: ThemeData(extensions: const
[RideWindowTheme.light])` so it builds and passes correctly in isolation
(`flutter test test/features/availability_screen_test.dart --plain-name "BACKLOG-35"` →
1 passed). The 11 pre-existing tests were left untouched (not fixed) — fixing them is a
separate, larger test-infra undertaking out of scope for this bundle, consistent with how
this plan already treats the RideDetailScreen test-infra gap.

**Recommendation:** A future quick task or phase plan should retrofit
`test/features/availability_screen_test.dart`'s existing `MaterialApp(home:
AvailabilityScreen())` instances with `localizationsDelegates`/`supportedLocales` and a
`theme:` carrying `RideWindowTheme.light`, mirroring the fix applied to the new
BACKLOG-35 test group.
