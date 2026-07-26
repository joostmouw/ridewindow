---
phase: 19-auth
plan: 03
subsystem: auth
tags: [supabase, riverpod, google_sign_in, l10n, flutter, widget-tests]

# Dependency graph
requires:
  - phase: 19-auth (plans 01-02)
    provides: "supabase_flutter + Supabase.initialize(), authStateProvider/currentUserIdProvider, serverClientId on the shared GoogleSignIn init gate, CalendarService.ensureGoogleSignInReady()"
provides:
  - "lib/features/profile/account_section.dart -- the sign-in/out UI, embedded as Profile's first section"
  - "Conditional-import seam for the web-only Google renderButton() (google_signin_button.dart/_stub.dart/_web.dart), mirroring lib/core/pwa_display_mode.dart"
  - "14 new l10n keys (NL+EN) covering this plan plus 19-04's switch dialog and 19-05's Calendar-mismatch warning"
  - "google_sign_in_web as an explicit direct pubspec dependency"
affects: [19-auth (plans 04-05, consume the switch-dialog and mismatch-warning l10n keys already defined here)]

# Tech tracking
tech-stack:
  added: [google_sign_in_web (promoted from transitive to direct dependency)]
  patterns:
    - "Conditional import via `if (dart.library.js_interop)` for web-only widgets that pull in dart:js_interop-based packages -- reuses the exact seam lib/core/pwa_display_mode.dart established, now generalized to a second use case (google_signin_button.dart)"
    - "authStateProvider (a plain @Riverpod Stream function-provider) is overridden in widget tests via `.overrideWith((ref) => stream)`, distinct from the class-based Fake*Notifier.overrideWith(() => Fake...()) pattern used for the other providers on the same screen"

key-files:
  created:
    - lib/features/profile/account_section.dart
    - lib/features/profile/google_signin_button.dart
    - lib/features/profile/google_signin_button_stub.dart
    - lib/features/profile/google_signin_button_web.dart
    - test/features/profile_account_section_test.dart
  modified:
    - lib/features/profile/profile_screen.dart
    - lib/l10n/app_nl.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_nl.dart
    - lib/l10n/app_localizations_en.dart
    - pubspec.yaml
    - pubspec.lock

key-decisions:
  - "The plan's interface note (`package:google_sign_in/web_only.dart` is safe to import unconditionally) does not hold for google_sign_in 7.2.0 -- that path does not exist; renderButton() lives in the federated google_sign_in_web package, whose dart:js_interop-based code fails to compile for the Dart VM test target. Routed through a conditional-import seam instead, following the existing lib/core/pwa_display_mode.dart pattern exactly."
  - "google_sign_in_web promoted from transitive to a direct pubspec.yaml dependency (already resolved in pubspec.lock at 1.1.3 -- no new package install, no legitimacy risk)."

patterns-established:
  - "Web-only widget code that transitively needs dart:js_interop must go through a conditional-import seam (stub/web split + `if (dart.library.js_interop)` facade), never a direct unconditional import -- otherwise `flutter test` (Dart VM) fails to compile with `toJS`/`JSObject` CFE errors."

requirements-completed: [AUTH-01, AUTH-02, AUTH-03, AUTH-06]

# Metrics
duration: ~35min
completed: 2026-07-26
---

# Phase 19 Plan 03: Account Section UI Summary

**AccountSection widget (Google sign-in/out via Supabase, D-01..D-12) embedded as Profile's first section, with a working web renderButton() seam and 3 new widget tests (309/0 full suite).**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-07-26 (worktree base a924bc7)
- **Completed:** 2026-07-26T08:53:26Z
- **Tasks:** 3
- **Files modified:** 13 (5 created, 8 modified)

## Accomplishments
- `AccountSection` (`lib/features/profile/account_section.dart`): signed-out/loading/signed-in states driven by `authStateProvider`, Android `ListTile` + `GoogleSignIn.instance.authenticate()` vs. web `renderButton()` + `authenticationEvents`, branching on `supportsAuthenticate()` not `kIsWeb`
- Embedded as the literal first child of Profile's `ListView`, above all 7 existing sections and the Calendar row (D-01), with zero changes to those sections
- Sign-in completion: `signInWithIdToken` via `CalendarService.ensureGoogleSignInReady()`'s shared init gate, `profile.userName` auto-filled only when empty (D-04)
- Sign-out: confirm dialog, then only `Supabase.instance.client.auth.signOut()` -- Calendar authorization and local SharedPreferences untouched (D-12)
- 14 new l10n keys (NL+EN), including two keys (`accountSwitchDialog*`, `calendarMismatchWarning`) pre-defined for Plans 19-04/19-05 so those plans never touch the `.arb` files
- 3 new widget tests pumping the full `ProfileScreen` (not `AccountSection` in isolation), proving both the widget and its embedding

## Task Commits

Each task was committed atomically:

1. **Task 1: l10n keys + account_section.dart** - `c729abd` (feat)
2. **Task 2: Embed AccountSection as ProfileScreen's first section** - `e28800c` (feat, includes a Rule 1 fix discovered while running the existing test suite)
3. **Task 3: Widget tests for signed-out/signed-in/sign-out-confirm** - `798e60d` (test)

## Files Created/Modified
- `lib/features/profile/account_section.dart` - The account section widget (signed-out/loading/signed-in, platform-branched sign-in, confirm-then-sign-out)
- `lib/features/profile/google_signin_button.dart` - Conditional-import facade exposing `renderGoogleSignInButton()`
- `lib/features/profile/google_signin_button_stub.dart` - No-op implementation compiled for Android/VM (and `flutter test`)
- `lib/features/profile/google_signin_button_web.dart` - Real `google_sign_in_web`-backed implementation, web-only
- `test/features/profile_account_section_test.dart` - 3 widget tests (signed-out, signed-in, sign-out confirm dialog)
- `lib/features/profile/profile_screen.dart` - `AccountSection()` inserted as the first `ListView` child
- `lib/l10n/app_nl.arb`, `lib/l10n/app_en.arb` - 14 new keys
- `lib/l10n/app_localizations*.dart` - regenerated via `flutter gen-l10n`
- `pubspec.yaml`, `pubspec.lock` - `google_sign_in_web` promoted to a direct dependency

## Decisions Made
- Followed the plan's D-01 through D-12 decisions from `19-CONTEXT.md` exactly (account section as its own top-of-screen section, platform-branched sign-in, sign-out-ends-only-the-Supabase-session, userName auto-fill-if-empty).
- Where the plan's `<interfaces>` note about `package:google_sign_in/web_only.dart` being safe to import unconditionally turned out to be incorrect for this project's exact dependency versions, fixed via the codebase's own established conditional-import pattern rather than inventing a new one.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `package:google_sign_in/web_only.dart` does not exist in google_sign_in 7.2.0**
- **Found during:** Task 1 (building `account_section.dart` per the plan's `<interfaces>` guidance)
- **Issue:** The plan instructed importing `package:google_sign_in/web_only.dart` for `renderButton()`. That path does not exist in the resolved `google_sign_in` 7.2.0 package (`google_sign_in.dart`, `widgets.dart`, `testing.dart` are the only top-level files). `renderButton()` lives in the federated web implementation package, `google_sign_in_web`, at `package:google_sign_in_web/web_only.dart`.
- **Fix:** Added `google_sign_in_web` as an explicit direct dependency in `pubspec.yaml` (already resolved transitively in `pubspec.lock` at `1.1.3` -- `flutter pub get` reported "transitive dependency to direct dependency", no new package fetched, no legitimacy risk) and corrected the import.
- **Files modified:** `pubspec.yaml`, `pubspec.lock`
- **Verification:** `flutter pub get` succeeded with zero new resolutions.
- **Committed in:** `c729abd` (Task 1 commit)

**2. [Rule 1 - Bug] Unconditional `google_sign_in_web` import broke `flutter test` (Dart VM) compilation**
- **Found during:** Task 2 (running the existing 4-file Profile test suite after embedding `AccountSection`)
- **Issue:** Even after fixing the import path, directly importing `package:google_sign_in_web/web_only.dart` from `account_section.dart` pulled in `google_identity_services_web`'s `dart:js_interop`-based extension types (`bool.toJS`, `JSObject`, etc.), which are only valid for web/JS/Wasm compilation. `flutter test` runs on the native Dart VM and failed with CFE errors ("The getter 'toJS' isn't defined for the type 'bool'", `'JSObject' isn't a type`) across all 4 pre-existing Profile test files, since they all transitively import `profile_screen.dart` -> `account_section.dart`.
- **Fix:** Created a conditional-import seam mirroring the codebase's own existing pattern in `lib/core/pwa_display_mode.dart`: `google_signin_button_stub.dart` (no-op, compiled for Android/VM/tests) and `google_signin_button_web.dart` (the real `google_sign_in_web` call, compiled only for web), selected via `google_signin_button.dart`'s `import 'google_signin_button_stub.dart' if (dart.library.js_interop) 'google_signin_button_web.dart' as impl;`. `account_section.dart` now calls `renderGoogleSignInButton()` from the facade instead of importing `google_sign_in_web` directly.
- **Files modified:** `lib/features/profile/account_section.dart`, `lib/features/profile/google_signin_button.dart` (new), `lib/features/profile/google_signin_button_stub.dart` (new), `lib/features/profile/google_signin_button_web.dart` (new)
- **Verification:** `flutter test` on the 4 pre-existing Profile test files: 21/21 passing (was failing to even compile before the fix). Full suite: 309/0.
- **Committed in:** `e28800c` (Task 2 commit)

**3. [Rule 1 - Bug] `pumpAndSettle` timeout in the sign-out confirm dialog test**
- **Found during:** Task 3 (writing the 3 widget tests)
- **Issue:** Test 3 used `tester.pumpAndSettle()` after tapping "Sign out", which timed out because `ProfileScreen`'s existing animated rain/wind widgets (`_AnimatedRainDropsState`/`_AnimatedWindFlagState`) use `AnimationController.repeat()`, which never settles -- the same class of issue already documented in `STATE.md` for `home_screen_test.dart` (decision 04-05).
- **Fix:** Replaced `pumpAndSettle()` with `tester.pump()` followed by a fixed `tester.pump(Duration(milliseconds: 300))`.
- **Files modified:** `test/features/profile_account_section_test.dart`
- **Verification:** Test 3 passes; full suite unaffected (309/0).
- **Committed in:** `798e60d` (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocking-issue fix)
**Impact on plan:** All three were required for the plan's own acceptance criteria to be achievable (a compiling, testable `account_section.dart` per Task 1's criteria; a passing existing test suite per Task 2's criteria; 3 passing new tests per Task 3's criteria). No scope creep -- no new dependency was actually fetched from the network (both `google_sign_in_web` and its own transitive deps were already in `pubspec.lock`), and the conditional-import pattern reuses, rather than invents, existing project convention.

## Issues Encountered
None beyond the three deviations documented above.

## User Setup Required
None - no external service configuration required. AUTH-10's release-build sign-in gate is Plan 19's final manual checklist item, not part of this plan's scope.

## Next Phase Readiness
- `AccountSection` is live and tested; Plans 19-04 (account-switch dialog) and 19-05 (Calendar-mismatch warning) can proceed directly -- their l10n keys (`accountSwitchDialogTitle/Body`, `accountSwitchKeepAction`, `accountSwitchRestartAction`, `calendarMismatchWarning`) already exist in both `.arb` files and the generated `app_localizations*.dart`, so neither plan needs to touch those files.
- The `google_signin_button.dart` conditional-import seam is a reusable pattern for any future web-only widget that pulls in `dart:js_interop`-based packages.
- Full suite at 309/0 confirmed on this HEAD; no regressions in the other 306 pre-existing tests.

---
*Phase: 19-auth*
*Completed: 2026-07-26*

## Self-Check: PASSED

- All 7 claimed created/modified files verified present on disk (`ls -la`).
- All 3 task commit hashes (`c729abd`, `e28800c`, `798e60d`) verified present in `git log --oneline --all`.
