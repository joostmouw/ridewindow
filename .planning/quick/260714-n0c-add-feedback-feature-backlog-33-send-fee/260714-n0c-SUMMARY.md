---
phase: quick-260714-n0c
plan: 01
subsystem: ui
tags: [flutter, l10n, url_launcher, profile-screen, feedback]

requires: []
provides:
  - "Send feedback entry in Profile screen OVER section"
  - "buildFeedbackMailtoUri pure function for mailto: URI construction"
  - "FeedbackDialog widget with 1-5 star rating and comment field"
affects: [profile-screen]

tech-stack:
  added: []
  patterns:
    - "mailto: feedback channel via existing url_launcher dependency (no backend, no new package)"
    - "Uri(queryParameters: {...}) constructor for safe percent-encoding of user free-text into a URI"

key-files:
  created:
    - lib/features/profile/feedback_dialog.dart
    - test/features/feedback_dialog_test.dart
  modified:
    - lib/features/profile/profile_screen.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_nl.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_en.dart
    - lib/l10n/app_localizations_nl.dart

key-decisions:
  - "Recipient/subject hardcoded as constants (joostmouw@gmail.com, 'RideWindow feedback') per locked backlog decision — solo-dev hobby project, no config needed"
  - "url_launcher's canLaunchUrl guard (no LaunchMode override) mirrors _launchPrivacyPolicy's existing pattern for mailto: URIs"
  - "Widget tests require MaterialApp theme: ThemeData(extensions: const [RideWindowTheme.light]) for context.rw star-color lookup — matches home_screen_refresh_test.dart precedent"

requirements-completed: [N0C-01]

duration: ~25min
completed: 2026-07-14
---

# Phase quick-260714-n0c Plan 01: Send Feedback Dialog Summary

**Backlog #33: mailto:-based feedback dialog (1-5 star rating + comment) wired into Profile screen's OVER section, using the existing url_launcher dependency — no backend, no new package.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-14
- **Tasks:** 2/2 completed
- **Files modified:** 8

## Accomplishments
- "Send feedback" entry added to Profile screen, above "Privacy policy"
- `buildFeedbackMailtoUri` pure function builds a safely percent-encoded `mailto:` URI (rating + comment)
- `FeedbackDialog` widget: 5-star rating row, multi-line comment field, Send disabled until a star is selected
- 4 automated tests (2 unit, 2 widget) covering URI construction and dialog UI wiring
- EN/NL localization strings added and regenerated via `flutter gen-l10n`

## Task Commits

Each task was committed atomically:

1. **Task 1: Add l10n strings and create the feedback dialog widget** - `69c8fb9` (feat)
2. **Task 2: Wire "Send feedback" into Profile screen and add tests** - `055c2eb` (test) + `5f00127` (feat)

_TDD task (Task 2) has two commits: test → feat, per RED/GREEN discipline._

## Files Created/Modified
- `lib/features/profile/feedback_dialog.dart` - `buildFeedbackMailtoUri` pure function, `showFeedbackDialog(context)` entrypoint, `_FeedbackDialog` StatefulWidget
- `lib/features/profile/profile_screen.dart` - "Send feedback" ListTile in OVER section, wired to `showFeedbackDialog`
- `lib/l10n/app_en.arb` / `lib/l10n/app_nl.arb` - `sendFeedback`, `feedbackRatingLabel`, `feedbackCommentHint`, `feedbackSendButton`
- `lib/l10n/app_localizations*.dart` - regenerated via `flutter gen-l10n`
- `test/features/feedback_dialog_test.dart` - 4 tests: URI construction (rating/comment, whitespace-trim), dialog title + 5 star buttons, Send button enable/disable

## Decisions Made
- Hardcoded recipient/subject constants (no settings/config) — matches solo-dev hobby-project scope per plan's locked decision.
- No `LaunchMode` override for the `mailto:` launch — plain `launchUrl(uri)` after `canLaunchUrl` guard, consistent with `_launchPrivacyPolicy`.
- Widget test `MaterialApp` needed an explicit `theme: ThemeData(extensions: const [RideWindowTheme.light])` — without it, `context.rw.scorePerfect` (used for the selected-star color) throws a null-check error in the test environment's default `ThemeData`. This mirrors an existing precedent in `home_screen_refresh_test.dart`, not a new pattern.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing theme extension in widget test setup**
- **Found during:** Task 2 (writing `feedback_dialog_test.dart`, RED phase)
- **Issue:** First test run threw `Null check operator used on a null value` in `RideWindowThemeX.rw` when Test 4 tapped a star (star becomes selected, triggering `context.rw.scorePerfect` color lookup) — the test's `MaterialApp` had no `theme` set, so `Theme.of(context).extension<RideWindowTheme>()` was null.
- **Fix:** Added `theme: ThemeData(extensions: const [RideWindowTheme.light])` to the test's `MaterialApp`, following the established pattern in `test/features/home_screen_refresh_test.dart`.
- **Files modified:** `test/features/feedback_dialog_test.dart`
- **Verification:** `flutter test test/features/feedback_dialog_test.dart` — all 4 tests pass.
- **Committed in:** `055c2eb` (Task 2 test commit)

**2. [Rule 1 - Lint] const literal for ThemeData extensions list**
- **Found during:** Task 2 verification (`flutter analyze`)
- **Issue:** `prefer_const_literals_to_create_immutables` info on the `[RideWindowTheme.light]` list literal.
- **Fix:** Changed to `const [RideWindowTheme.light]`.
- **Files modified:** `test/features/feedback_dialog_test.dart`
- **Verification:** `flutter analyze` reports zero issues on the test file.
- **Committed in:** `5f00127` (Task 2 feat commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 lint) — both confined to the new test file's own setup, not production code.
**Impact on plan:** No scope creep. Both fixes were required for the plan's own verification commands to pass as specified.

## Issues Encountered
None beyond the deviations above.

## TDD Gate Compliance

Task 2 (`tdd="true"`) followed RED→GREEN: test commit (`055c2eb`) precedes the feat commit (`5f00127`) wiring the Profile screen entry. Note: since `feedback_dialog.dart`'s pure function and dialog widget were built non-TDD in Task 1 (per plan design — Task 1 is `type="auto"` without `tdd`), the 4 tests in Task 2 exercised already-implemented dialog logic directly (via `showFeedbackDialog`, not through the Profile screen) — so 3 of 4 tests passed on first run; only Test 4 surfaced the genuine theme-setup gap documented above. The RED phase therefore validated test-harness correctness rather than driving new production logic, which matches the plan's explicit task split (dialog built in Task 1, wiring + regression tests in Task 2).

## User Setup Required
None - no external service configuration required. `url_launcher: ^6.3.1` was already a pubspec dependency; no new packages added.

## Next Phase Readiness
- Feature is self-contained and ready for use; no follow-up work identified.
- Manual verification recommended: run the app, open Profile > Send feedback, select a star, tap Send, confirm the device's mail app opens pre-filled with the correct recipient/subject/body.

---
*Phase: quick-260714-n0c*
*Completed: 2026-07-14*

## Self-Check: PASSED

All created/modified files verified present on disk; all 3 task commit hashes (`69c8fb9`, `055c2eb`, `5f00127`) verified present in git log.
