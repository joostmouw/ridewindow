---
phase: 19-auth
plan: 04
subsystem: auth
tags: [riverpod, supabase, account-switch, data-safety, tdd]

# Dependency graph
requires:
  - phase: 19-auth (Plan 19-03)
    provides: "AccountSection widget with Google sign-in/out wired into ProfileScreen, authStateProvider seeded from Supabase's currentSession + onAuthStateChange"
provides:
  - "resolveAccountSwitch(): pure, zero-import decision function for first-login/same-account/different-account"
  - "account.lastSyncedUid local SharedPreferences key -- the foundation Phase 21's real cloud conflict resolver needs"
  - "ProfileNotifier.resetToDefaults() and PlannedRidesNotifier.clearAll() -- the two notifiers that lacked a full reset method"
  - "Account-switch AlertDialog wired into AccountSection, triggered reactively off authStateProvider so it fires for both interactive sign-in and rehydrated-session cold start"
affects: [20-repository-refactor, 21-sync-migration]

tech-stack:
  added: []
  patterns:
    - "Pure decision function (no SDK, no SharedPreferences) mirrors availability_key.dart's convention -- fully unit-testable without mocks"
    - "ref.listen(authStateProvider) inside build() as the single shared trigger for both interactive and rehydrated sign-in paths, guarded by a _lastCheckedUid field to avoid double-processing"
    - "ref.listenManual() + try/finally to keep a non-keepAlive provider (availabilityProvider) alive across an async multi-step operation triggered via ref.read()"

key-files:
  created:
    - lib/domain/services/account_switch_resolver.dart
    - test/domain/services/account_switch_resolver_test.dart
  modified:
    - lib/features/profile/account_section.dart
    - lib/providers/profile_notifier.dart
    - lib/providers/planned_rides_notifier.dart
    - test/features/profile_account_section_test.dart

key-decisions:
  - "Switch-check logic lives behind a ref.listen(authStateProvider) callback in build(), not solely embedded in _handleSignInSuccess -- this is the one code path both the interactive tap flow and a rehydrated cold-start session hit, matching Task 3's explicit test requirement"
  - "_lastCheckedUid guard field prevents the check from double-running when both the reactive listener and the direct post-signInWithIdToken call fire for the same sign-in event"
  - "availabilityProvider (not keepAlive, unwatched elsewhere in ProfileScreen) needed a temporary ref.listenManual() subscription across the 'start fresh' wipe sequence to survive the async gaps -- without it, AvailabilityNotifier.clearAll() throws UnmountedRefException mid-flight"
  - "keepData == null (dialog dismissed without a button, defensively) is treated as 'keep data', never as 'wipe' -- a safe default on ambiguous outcome"

requirements-completed: [AUTH-08]

duration: ~45min
completed: 2026-07-26
---

# Phase 19 Plan 04: Account-switch data safety (AUTH-08) Summary

**Pure `resolveAccountSwitch()` decision function plus a reactive `authStateProvider`-driven AlertDialog in `AccountSection` that asks the user to keep or wipe local data whenever a different Google account signs in on the same device than last time.**

## Performance

- **Duration:** ~45min
- **Started:** 2026-07-26T08:20:00Z (approx)
- **Completed:** 2026-07-26T09:06:33Z
- **Tasks:** 3/3 completed
- **Files modified:** 6 (2 created, 4 modified)

## Accomplishments
- `resolveAccountSwitch()` is a genuinely pure, zero-import function (`firstSignIn` / `sameAccount` / `differentAccount`), unit-tested for all 4 cases including the defensive empty-string edge case
- The switch dialog is wired to fire from a single shared code path (`ref.listen(authStateProvider)` in `build()`) that both the interactive Google sign-in flow and a rehydrated-session cold start hit -- proven by a widget test that bypasses the tap handler entirely
- "Start fresh" wipes exactly the three local data domains D-09 names (profile settings, availability, planned rides) and provably never touches the Drift forecast cache (no Drift import anywhere in this plan's diff)

## Task Commits

Each task was committed atomically:

1. **Task 1a: Pure account_switch_resolver.dart (RED)** - `75e9d97` (test)
2. **Task 1b: Pure account_switch_resolver.dart (GREEN)** - `b7a0c30` (feat)
3. **Task 2: Wire the switch dialog and the three reset methods** - `6da2150` (feat)
4. **Task 3: Widget tests for the switch dialog state** - `9b53842` (test)

_Task 1 followed the full TDD RED/GREEN cycle: the test was committed first against a nonexistent implementation (confirmed compile failure), then the implementation was restored and committed once all 4 tests passed._

## Files Created/Modified
- `lib/domain/services/account_switch_resolver.dart` - Pure `resolveAccountSwitch()` + `AccountSwitchDecision` enum, zero imports
- `test/domain/services/account_switch_resolver_test.dart` - 4 unit tests covering all decision branches
- `lib/features/profile/account_section.dart` - `_kLastSyncedUidKey` constant, `_checkAccountSwitch()` method (reactive via `ref.listen(authStateProvider)` in `build()` and directly after `signInWithIdToken` succeeds in `_handleSignInSuccess`), `barrierDismissible: false` AlertDialog for the `differentAccount` branch, `ref.listenManual()` guard around the "start fresh" wipe sequence
- `lib/providers/profile_notifier.dart` - `resetToDefaults()`: removes all 11 `_key*` SharedPreferences keys, rebuilds state with `build()`'s exact default values
- `lib/providers/planned_rides_notifier.dart` - `clearAll()`: mirrors `add()`/`remove()`'s `state = []` + `_persist()` shape
- `test/features/profile_account_section_test.dart` - 2 new widget tests (dialog appears on differentAccount, "Opnieuw beginnen" closes it); added `sharedPrefsProvider` override to `_pumpProfileScreen` (needed once the wipe path can reach `plannedRidesProvider`)

## Decisions Made

- **Switch check wired via `ref.listen(authStateProvider)`, not solely inside `_handleSignInSuccess`.** The plan's `<action>` prose described adding the check "immediately after signInWithIdToken succeeds" inside `_handleSignInSuccess`, but Task 3's `<behavior>` explicitly required the dialog to appear when `authStateProvider` is overridden directly with a signed-in user (bypassing the tap handler entirely) — proving the trigger must be "the same code path both the interactive sign-in flow and a rehydrated-session cold-start would hit". Implemented both: the reactive listener in `build()` (the mechanism the test actually exercises) and a direct call right after `signInWithIdToken` succeeds in `_handleSignInSuccess` (matching the plan's literal ordering intent relative to the name-autofill step). A `_lastCheckedUid` guard field makes calling both paths for the same sign-in event a no-op after the first.
- **`keepData == null` treated as "keep data".** `showDialog` can theoretically resolve to `null` if the widget tree is torn down before a button is tapped (barrier dismiss is disabled, but defensive coding still applies). Only an explicit `false` (the user tapping "Start fresh") triggers the wipe -- an ambiguous/interrupted outcome never destroys data.
- **`ref.listenManual()` used to keep `availabilityProvider` alive during the wipe.** `AvailabilityNotifier` is not `@Riverpod(keepAlive: true)` and nothing in `ProfileScreen`'s widget tree watches it (only accessed via one-shot `ref.read()` calls, including a pre-existing debug "reset availability" menu item). Without an explicit subscription held across the `await` boundaries, the provider can self-dispose mid-sequence, and the subsequent `state = ...` write inside `clearAll()` throws `UnmountedRefException`. `PlannedRidesNotifier` did not need the same treatment since it is already `keepAlive: true`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] availabilityProvider self-disposal during the "start fresh" wipe sequence**
- **Found during:** Task 3 (writing "Opnieuw beginnen" widget test)
- **Issue:** `AvailabilityNotifier` (`@riverpod`, not `keepAlive`) has no active watcher inside `ProfileScreen`. Calling `ref.read(availabilityProvider.notifier).clearAll()` from the "start fresh" branch let the provider dispose itself between the method's internal `await` and its `state = ...` write, throwing `UnmountedRefException` (`Cannot use the Ref of availabilityProvider after it has been disposed`).
- **Fix:** Wrapped the three reset calls in a `ref.listenManual(availabilityProvider, (_, __) {})` subscription, held via a local variable and closed in a `finally` block once the sequence completes.
- **Files modified:** `lib/features/profile/account_section.dart`
- **Verification:** `flutter test test/features/profile_account_section_test.dart` -- Test 5 (tap "Opnieuw beginnen") now passes; full suite confirmed at 315/0.
- **Committed in:** `9b53842` (part of Task 3's commit, since the bug only surfaced while making that test green)

None of the other Auto-fixed categories (Rule 2/3) applied. No Rule 4 (architectural) escalations were needed.

## Known Stubs

None. No hardcoded empty values, placeholder text, or unwired data sources were introduced by this plan.

## Threat Flags

None. This plan adds a local-only SharedPreferences comparison and a client-side dialog -- no new network endpoints, auth paths, or schema changes at a trust boundary. The `account.lastSyncedUid` key is read/written entirely on-device.

## Self-Check

- `lib/domain/services/account_switch_resolver.dart` -- FOUND
- `test/domain/services/account_switch_resolver_test.dart` -- FOUND
- `lib/features/profile/account_section.dart` (modified) -- FOUND
- `lib/providers/profile_notifier.dart` (modified) -- FOUND
- `lib/providers/planned_rides_notifier.dart` (modified) -- FOUND
- `test/features/profile_account_section_test.dart` (modified) -- FOUND
- Commit `75e9d97` -- FOUND
- Commit `b7a0c30` -- FOUND
- Commit `6da2150` -- FOUND
- Commit `9b53842` -- FOUND

## TDD Gate Compliance

Task 1 followed the full RED/GREEN cycle:
- RED: `75e9d97` -- `test(19-04): add failing test for account_switch_resolver` (confirmed compile failure without the implementation file present)
- GREEN: `b7a0c30` -- `feat(19-04): implement account_switch_resolver pure decision function` (4/4 tests passing)

Task 3 added widget tests for behavior already wired in Task 2 (test-after, per this plan's task ordering) -- both new tests pass on the first run once the Task 3 disposal fix was applied; no separate RED commit was produced for Task 3 since the plan structures the implementation (Task 2) before the widget-level test (Task 3).

## Verification Against Plan

- `resolveAccountSwitch` is pure, zero-import, unit-tested for all 4 cases -- CONFIRMED (`lib/domain/services/account_switch_resolver.dart` has zero import statements)
- The switch dialog only appears when `lastSyncedUid` disagrees with the newly signed-in uid, never auto-resolves either direction -- CONFIRMED (firstSignIn/sameAccount persist silently; differentAccount always shows the barrierDismissible:false dialog)
- "Start fresh" clears exactly profile + availability + planned rides; the Drift forecast cache is untouched -- CONFIRMED (`grep -rn "drift\|Drift" lib/features/profile/account_section.dart lib/providers/profile_notifier.dart lib/providers/planned_rides_notifier.dart` returns no matches)
- Full suite growing, never shrinking, from the 309 baseline -- CONFIRMED: 315/0 (309 + 4 resolver unit tests + 2 new widget tests)

## Next Steps

- Phase 20 will extract `ProfileRepository`/`AvailabilityRepository`/`PlannedRidesRepository` per ARCHITECTURE.md §2 -- `account.lastSyncedUid` and the 11 `_key*` constants this plan relies on should migrate into that shared layer at that point, not before.
- Phase 21 builds the full `resolveAccountSync` (cloud-aware) resolver per ARCHITECTURE.md §5, reusing this plan's local-only `resolveAccountSwitch` as its cold-start/no-cloud-row special case.
- Plan 19-05 (next in this phase) modifies `lib/features/profile/profile_screen.dart` and `lib/services/calendar_service.dart` -- outside this plan's file scope, not touched here.
