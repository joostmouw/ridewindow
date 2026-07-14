# Deferred Items — quick-260714-nfk

Pre-existing issues discovered during execution that are out of scope for this
quick task (not caused by this plan's changes). Logged per SCOPE BOUNDARY rule.

## 1. `test/features/profile_screen_notif_test.dart` fails independently of this plan

**Status:** Pre-existing, confirmed via `git stash` bisection before touching
`lib/features/profile/profile_screen.dart`.

- Test 5 ("Tap op eerste SwitchListTile roept setNotifEveningBefore(true) aan")
  throws `Bad state: No element` inside `WidgetController.scrollUntilVisible`
  — fails identically standalone on the pre-Task-2 baseline (no changes to
  `profile_screen.dart` or any l10n file).
- When run in the same `flutter test` invocation as other Profile screen test
  files (e.g. combined with `profile_screen_location_test.dart`), Tests 1-4 of
  this file also throw `Null check operator used on a null value` inside
  `S.of(context)` during `ProfileScreen` build — this reproduces identically
  on the pre-Task-2 baseline too (confirmed with `location_test.dart` +
  `notif_test.dart` combined, zero changes to source).
- Root cause appears to be either a Flutter SDK version drift since these
  tests were authored, or localization-delegate/test-binding state leaking
  across widget test files run in the same process — not something
  introduced by backlog #36's `CalendarService`/`ProfileScreen` changes.
- `test/features/ride_detail_screen_test.dart` also shows widespread failures
  (13) when run standalone, further supporting a pre-existing, project-wide
  test-suite health issue unrelated to this plan.

**Action:** Not fixed here (out of scope — pre-existing, unrelated file).
Recommend a dedicated quick task or phase to investigate Flutter test-runner/
localization-delegate state pollution across the Profile screen test suite.
