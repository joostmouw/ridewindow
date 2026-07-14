---
phase: quick-260714-nfk
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [lib/services/calendar_service.dart, lib/l10n/app_en.arb, lib/l10n/app_nl.arb, lib/l10n/app_localizations.dart, lib/l10n/app_localizations_en.dart, lib/l10n/app_localizations_nl.dart, lib/features/profile/profile_screen.dart, test/features/profile_screen_calendar_test.dart]
autonomous: true
requirements: [NFK-01]

must_haves:
  truths:
    - "User can see whether Google Calendar is Connected or Not connected as soon as the Profile screen opens, without any tap required"
    - "Checking calendar status never triggers an OAuth prompt/popup — it uses the promptIfUnauthorized:false check-only path"
    - "When connected, a 'Disconnect' action is visible next to the status; when not connected, no Disconnect action is shown"
    - "Tapping Disconnect revokes the Google Calendar authorization and the row updates to 'Not connected' with no crash"
    - "If the platform's Google Sign-In channel is unavailable or throws (e.g. transient error), the Profile screen degrades gracefully to 'Not connected' instead of crashing"
    - "No account email or other Google identity is shown — status is a simple boolean text per locked decision"
    - "All new strings render via S.of(context) with matching EN and NL ARB entries"
  artifacts:
    - path: "lib/services/calendar_service.dart"
      provides: "isCalendarConnected() and disconnectCalendar() instance methods, both sharing the existing lazy _ensureInitialized() guard"
      contains: "isCalendarConnected"
    - path: "lib/features/profile/profile_screen.dart"
      provides: "Google Calendar status ListTile in the OVER section, wired to CalendarService, with checking/connected/not-connected UI states and a Disconnect action"
      contains: "isCalendarConnected"
    - path: "lib/l10n/app_en.arb"
      provides: "EN calendar status strings"
      contains: "googleCalendarLabel"
    - path: "lib/l10n/app_nl.arb"
      provides: "NL calendar status strings"
      contains: "googleCalendarLabel"
    - path: "test/features/profile_screen_calendar_test.dart"
      provides: "Widget test proving the graceful-degradation path (status check throws in test env, caught, defaults to Not connected, no Disconnect button shown)"
      contains: "calendarStatusNotConnected"
  key_links:
    - from: "lib/features/profile/profile_screen.dart _checkCalendarConnection"
      to: "CalendarService().isCalendarConnected()"
      via: "await call in initState-triggered async method, wrapped in try/catch"
      pattern: "isCalendarConnected\\(\\)"
    - from: "lib/features/profile/profile_screen.dart Disconnect TextButton onPressed"
      to: "CalendarService().disconnectCalendar()"
      via: "await call, wrapped in try/catch, followed by setState"
      pattern: "disconnectCalendar\\(\\)"
---

<objective>
Add backlog item #36: make the Google Calendar connection visible and manageable from the Profile screen. Extend `CalendarService` with two new methods — `isCalendarConnected()` (check-only, never prompts) and `disconnectCalendar()` (revokes authorization) — and wire a new "Google Calendar" status row into the Profile screen's OVER section, showing a simple "Connected"/"Not connected" text and a "Disconnect" action when connected.

Purpose: Today the app silently uses Google Calendar (add-to-calendar, availability import) with zero visibility into whether the user is actually authorized, and no way to revoke access short of Google's own account settings. This closes that gap per backlog #36.
Output: `CalendarService.isCalendarConnected()` / `CalendarService.disconnectCalendar()`, a new Google Calendar row in `ProfileScreen`, new EN/NL ARB strings, and a widget test covering the graceful-degradation status-check path.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

<interfaces>
<!-- Confirmed by reading the actual files and the google_sign_in 7.2.0 package source directly — do not re-discover. -->

**Current `lib/services/calendar_service.dart` (full file already read):**
```dart
class CalendarService {
  static bool _initialized = false;
  static Future<void>? _initFuture;

  static Future<void> _sharedInitialize() { ... } // memoized init guard (Rule 1 bugfix)

  static Future<void> warmUpForWeb() async { ... } // web-only eager warmup (CAL-06)

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _sharedInitialize();
  }

  Future<void> addRideSlotToCalendar(RideSlot slot, List<HourlyForecast> forecasts) async {
    await _ensureInitialized();
    // ... authorizeScopes([CalendarApi.calendarEventsScope]) ... (prompts if needed)
  }

  Future<List<({DateTime start, DateTime end})>> getEvents(DateTime start, DateTime end) async {
    await _ensureInitialized();
    // ... authorizeScopes([CalendarApi.calendarEventsScope]) ... (prompts if needed)
  }

  static String buildWeatherSummary(List<HourlyForecast> forecasts) { ... } // pure, tested

  String _fmtTime(DateTime dt) => ...;
}
```
The file header comment (lines 1-6) currently states CAL-02: `GoogleSignIn.instance` is used lazily, "never created at app-start, only on-demand on button tap -- except on web, where main.dart eagerly warms GoogleSignIn via `CalendarService.warmUpForWeb()`". This plan adds a SECOND deliberate, documented exception: navigating to the Profile screen now also triggers a lazy, check-only (non-prompting) initialization. Update the header comment to say so explicitly. This does NOT change `addRideSlotToCalendar()`'s or `getEvents()`'s lazy-init timing in any way — they are untouched.

**google_sign_in 7.2.0 confirmed API surface** (from `google_sign_in.dart` in `/Users/joostmouw/.pub-cache/hosted/pub.dev/google_sign_in-7.2.0/lib/google_sign_in.dart`):
```dart
class GoogleSignInAuthorizationClient {
  /// Requests client authorization tokens if they can be returned WITHOUT
  /// user interaction. If authorization would require user interaction,
  /// returns null (does NOT throw, does NOT prompt).
  Future<GoogleSignInClientAuthorization?> authorizationForScopes(List<String> scopes) async;

  /// Requests that the user authorize the given scopes (WILL prompt if needed).
  /// Already used by addRideSlotToCalendar/getEvents — do not use this one here.
  Future<GoogleSignInClientAuthorization> authorizeScopes(List<String> scopes) async;
}

class GoogleSignIn {
  static GoogleSignIn get instance => ...;
  GoogleSignInAuthorizationClient get authorizationClient => ...;

  /// Disconnects any currently authorized user, revoking previous authorization.
  /// Also synthesizes a sign-out.
  Future<void> disconnect() async;
}
```
`GoogleSignInClientAuthorization` (used via `extension_google_sign_in_as_googleapis_auth`) only carries an `accessToken` in this app's scope-only (`authorizeScopes`) flow — no account email/identity is available, confirming the locked decision to show only a boolean status.

**New `CalendarService` methods to add** (place after `getEvents()`, before the `// --- Public helpers (testbaar) ---` divider). Signatures and bodies:
- `Future<bool> isCalendarConnected() async` — awaits `_ensureInitialized()`, then awaits `GoogleSignIn.instance.authorizationClient.authorizationForScopes([CalendarApi.calendarEventsScope])`, returns whether that result is non-null.
- `Future<void> disconnectCalendar() async` — awaits `_ensureInitialized()`, then awaits `GoogleSignIn.instance.disconnect()`.

Write proper Dutch doc comments above each, matching the file's existing comment language/style (see `addRideSlotToCalendar`/`getEvents` doc comments for tone). `isCalendarConnected()`'s doc comment MUST explicitly state it never prompts the user (uses the `promptIfUnauthorized: false` path) and that it is the deliberate CAL-02 exception triggered by Profile-screen navigation.

**Current `lib/features/profile/profile_screen.dart` OVER section (already read, lines 642-670):** the section header `_SectionHeader(s.sectionAbout)` is followed by a "Send feedback" `ListTile` (leading `Icons.feedback_outlined`, opens `showFeedbackDialog`), then "Privacy policy", "Weather data attribution", and "Version" `ListTile`s in that order. Insert the new Google Calendar `ListTile` immediately after "Send feedback" and before "Privacy policy" (per locked decision: "near the recently-added Send feedback entry, in a similar list-item style").

**`_ProfileScreenState` current shape** (already read, lines 36-90): has `late double _tempMin/_tempMax/_rainMax/_windMax` fields and an `initState()` override that reads the initial profile snapshot. Add a `bool? _calendarConnected;` field (null = still checking) alongside those, and call the new `_checkCalendarConnection()` method (fire-and-forget, not awaited) at the end of `initState()`.

**Google Calendar row logic to implement in `_ProfileScreenState`:**
- `_checkCalendarConnection()`: an async method that calls `CalendarService().isCalendarConnected()` inside a try/catch. On success, `setState` sets `_calendarConnected` to the returned bool (guarded by `mounted`). On any exception, `setState` sets `_calendarConnected = false` (guarded by `mounted`) — this is the graceful-degradation fallback.
- `_disconnectCalendar(BuildContext context)`: an async method that calls `CalendarService().disconnectCalendar()` inside a try/catch (best-effort — matches `CalendarService`'s own fail-soft style; on error, proceed anyway since user intent is to disconnect). After the call (success or caught failure), if `mounted`, `setState` sets `_calendarConnected = false`, then if `context.mounted` shows a `ScaffoldMessenger` `SnackBar` with `Text(S.of(context).calendarDisconnectedSnackbar)`.
- `_calendarStatusText(S s)`: a small helper returning `s.calendarStatusChecking` when `_calendarConnected == null`, else `s.calendarStatusConnected` or `s.calendarStatusNotConnected` depending on the bool value.
- The new `ListTile` in `build()`: `leading: const Icon(Icons.calendar_month)`, `title: Text(s.googleCalendarLabel)`, `subtitle: Text(_calendarStatusText(s))`, `trailing`: while `_calendarConnected == null` show a small 20x20 `CircularProgressIndicator(strokeWidth: 2)`; once resolved, show a `TextButton` with `Text(s.calendarDisconnectButton)` calling `_disconnectCalendar(context)` when `_calendarConnected == true`, otherwise `null` (no trailing widget) when `false`.

**l10n pattern** — `lib/l10n/app_en.arb`/`app_nl.arb` are flat `"key": "value"` maps (no `@key` metadata blocks used in this repo), template file is `app_nl.arb` per `l10n.yaml`. Every key MUST exist in BOTH files. After editing, regenerate with `flutter gen-l10n` (writes into `lib/l10n/app_localizations*.dart`, committed to git). Insert the new calendar keys immediately after the existing `feedbackSendButton` entry and before `privacyPolicy` in both files (same relative position pattern used for the `sendFeedback`/`feedback*` block).

**Test pattern for ProfileScreen widget tests** — `test/features/profile_screen_location_test.dart` (already read in full) is the confirmed-working pattern: `ProviderScope` overrides for `profileProvider` (`FakeProfileNotifier`), `gpsPermissionProvider` (`FakeGpsPermissionNotifier`), `locationProvider` (`FakeLocationNotifier`), `weatherProvider` (`FakeWeatherNotifier`), wrapped in `MaterialApp(locale: Locale('nl'), localizationsDelegates: S.localizationsDelegates, supportedLocales: S.supportedLocales, home: ProfileScreen())`, then `await tester.pump()` followed by `await tester.pump(const Duration(milliseconds: 100))`. Reuse this exact override/fixture shape (do not touch the existing test file — create a new sibling file instead, per file-ownership convention).

**Why the new test is safe without mocking GoogleSignIn:** in the Flutter test environment there is no registered platform-channel handler for `google_sign_in`, so any real call into `GoogleSignIn.instance` throws `MissingPluginException`. `_checkCalendarConnection()`'s try/catch makes this deterministic: after settling, the row always resolves to "Not connected" in test env, with no Disconnect button. This is not "invoking a real platform channel and expecting it to work" — it proves the app's own designed fallback path, matching the spirit of the existing `feedback_dialog_test.dart` caution (never assert on a code path that requires the channel to succeed).
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Extend CalendarService with connection-status check and disconnect</name>
  <files>lib/services/calendar_service.dart</files>
  <action>
  Update the file's header doc comment (lines 1-6) to add a sentence documenting the new, deliberate CAL-02 exception: navigating to the Profile screen triggers a lazy, non-prompting authorization check via the new `isCalendarConnected()` method (backlog #36) — this is separate from, and does not change, the existing lazy-init timing for `addRideSlotToCalendar()`/`getEvents()` or the web `warmUpForWeb()` path.

  Add two new public instance methods, placed after `getEvents()` and before the `// --- Public helpers (testbaar) ---` divider, per the exact signatures and bodies given in the `<interfaces>` block above: `isCalendarConnected()` (calls `_ensureInitialized()` then `authorizationClient.authorizationForScopes([CalendarApi.calendarEventsScope])`, returns non-null-ness) and `disconnectCalendar()` (calls `_ensureInitialized()` then `GoogleSignIn.instance.disconnect()`). Add Dutch doc comments matching the file's existing tone, with `isCalendarConnected()`'s comment explicitly noting it never prompts the user and is the CAL-02 exception.

  Do not modify `addRideSlotToCalendar()`, `getEvents()`, `_sharedInitialize()`, or `warmUpForWeb()` in any way — only add the two new methods and the header comment addition.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter analyze lib/services/calendar_service.dart</automated>
  </verify>
  <done>
  `flutter analyze` reports zero new errors/warnings on `calendar_service.dart`. `isCalendarConnected()` and `disconnectCalendar()` both call `_ensureInitialized()` first, matching the existing method style. Neither `addRideSlotToCalendar()` nor `getEvents()` changed.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Wire Google Calendar status row into Profile screen, add l10n strings and test</name>
  <files>lib/l10n/app_en.arb, lib/l10n/app_nl.arb, lib/l10n/app_localizations.dart, lib/l10n/app_localizations_en.dart, lib/l10n/app_localizations_nl.dart, lib/features/profile/profile_screen.dart, test/features/profile_screen_calendar_test.dart</files>
  <behavior>
    - Test 1: With no `CalendarService` mocking (real service, throws `MissingPluginException` in test env), after pumping `ProfileScreen` and settling, the Google Calendar row shows `s.calendarStatusNotConnected` text (the graceful-degradation fallback) and `s.googleCalendarLabel` as its title.
    - Test 2: In that same settled state, no widget with text `s.calendarDisconnectButton` exists (Disconnect is only shown when connected).
  </behavior>
  <action>
  In `lib/l10n/app_en.arb`, insert these new keys immediately after the existing `"feedbackSendButton"` entry and before `"privacyPolicy"`: `googleCalendarLabel` = "Google Calendar", `calendarStatusChecking` = "Checking...", `calendarStatusConnected` = "Connected", `calendarStatusNotConnected` = "Not connected", `calendarDisconnectButton` = "Disconnect", `calendarDisconnectedSnackbar` = "Disconnected from Google Calendar.".

  In `lib/l10n/app_nl.arb`, insert the matching keys in the same relative position: `googleCalendarLabel` = "Google Agenda", `calendarStatusChecking` = "Controleren...", `calendarStatusConnected` = "Verbonden", `calendarStatusNotConnected` = "Niet verbonden", `calendarDisconnectButton` = "Loskoppelen", `calendarDisconnectedSnackbar` = "Losgekoppeld van Google Agenda.".

  Run `flutter gen-l10n` from repo root to regenerate the three `app_localizations*.dart` files. Do not hand-edit generated files.

  In `lib/features/profile/profile_screen.dart`: add `import 'package:ridewindow/services/calendar_service.dart';`. Implement the field, methods, and `ListTile` exactly as specified in the `<interfaces>` block above ("Google Calendar row logic to implement in `_ProfileScreenState`") — the `bool? _calendarConnected` field, `_checkCalendarConnection()` called from `initState()`, `_disconnectCalendar(BuildContext context)`, `_calendarStatusText(S s)`, and the new `ListTile` inserted into the OVER section immediately after "Send feedback" and before "Privacy policy".

  Create `test/features/profile_screen_calendar_test.dart` implementing the two behaviors above, reusing the `FakeProfileNotifier`/`FakeGpsPermissionNotifier`/`FakeLocationNotifier`/`FakeWeatherNotifier` override pattern and `MaterialApp` setup from `test/features/profile_screen_location_test.dart` (do not modify that file — this is a new sibling file). Use `SharedPreferences.setMockInitialValues({})` in `setUp`. Pump, then `await tester.pump(const Duration(milliseconds: 100))` to let `_checkCalendarConnection()`'s catch-and-setState resolve before asserting.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter gen-l10n && flutter analyze lib/features/profile/profile_screen.dart lib/l10n/app_localizations.dart test/features/profile_screen_calendar_test.dart && flutter test test/features/profile_screen_calendar_test.dart test/features/profile_screen_location_test.dart test/features/profile_screen_notif_test.dart</automated>
  </verify>
  <done>
  `flutter gen-l10n` runs clean and `S` exposes `googleCalendarLabel`, `calendarStatusChecking`, `calendarStatusConnected`, `calendarStatusNotConnected`, `calendarDisconnectButton`, `calendarDisconnectedSnackbar` in both generated localization files. `flutter analyze` reports zero new errors/warnings on the touched files. `flutter test` passes the two new tests AND both pre-existing `profile_screen_location_test.dart` and `profile_screen_notif_test.dart` suites (proving the new `initState` call does not break existing Profile screen tests). The Profile screen's OVER section shows a "Google Calendar" row above "Privacy policy" that settles to "Not connected" with no Disconnect button in the test environment.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Profile screen navigation → lazy GoogleSignIn init | User navigating to Profile now triggers a lazy, check-only (non-prompting) OAuth authorization check — a deliberate, documented exception to CAL-02's "only on explicit Calendar-related tap" rule |
| GoogleSignIn platform channel → app UI | Platform channel failures/exceptions must not crash the Profile screen |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-quick260714nfk-01 | Information Disclosure | Google Calendar status row | mitigate | Show only a boolean "Connected"/"Not connected" text — no account email or Google identity surfaced, per locked decision and confirmed API limitation (`GoogleSignInClientAuthorization` carries only an `accessToken` in this app's scope-only flow) |
| T-quick260714nfk-02 | Denial of Service | `isCalendarConnected()` / `disconnectCalendar()` platform-channel failure | mitigate | Both calls wrapped in try/catch in `_ProfileScreenState`; on any exception the UI degrades to "Not connected" (`_checkCalendarConnection`) or proceeds with the disconnect UI update anyway (`_disconnectCalendar`) rather than crashing or leaving the screen stuck loading |
| T-quick260714nfk-03 | Elevation of Privilege | Disconnect action | accept | `disconnectCalendar()` only revokes an existing authorization — it cannot grant new scopes or elevate privilege; worst case is the user must re-authorize next time a calendar action is used |
| T-quick260714nfk-04 | Tampering | New `initState`-triggered network/platform call | accept | No user-controlled input crosses this boundary — the call takes no parameters beyond the fixed `CalendarApi.calendarEventsScope` constant already used elsewhere in this file |
</threat_model>

<verification>
Run `flutter analyze` on all files in `files_modified`, then `flutter gen-l10n`, then `flutter test test/features/profile_screen_calendar_test.dart test/features/profile_screen_location_test.dart test/features/profile_screen_notif_test.dart`. Confirm the Profile screen's OVER section shows a "Google Calendar" row (title + status subtitle) between "Send feedback" and "Privacy policy", that it settles to "Not connected" with no Disconnect button when Google Sign-In is unavailable (test env / no prior authorization), and that existing Profile screen tests still pass unmodified.
</verification>

<success_criteria>
- `CalendarService.isCalendarConnected()` and `CalendarService.disconnectCalendar()` added, both sharing the existing lazy `_ensureInitialized()` guard; `addRideSlotToCalendar()`/`getEvents()` untouched
- Profile screen's OVER section shows a "Google Calendar" row (between "Send feedback" and "Privacy policy") displaying "Checking...", "Connected", or "Not connected" based on live status
- A "Disconnect" action appears only when connected, and tapping it revokes authorization, updates the row to "Not connected", and shows a confirmation SnackBar
- The status check never prompts the user (uses `authorizationForScopes`, not `authorizeScopes`) and gracefully degrades to "Not connected" on any platform-channel failure
- No account email or Google identity shown — boolean status only, per locked decision
- EN and NL ARB files both contain the new calendar strings; `flutter gen-l10n` runs clean
- `flutter analyze` and all listed `flutter test` targets pass, including the two pre-existing Profile screen test suites (proving no regression from the new `initState` call)
- No new pubspec dependency added
</success_criteria>

<output>
Create `.planning/quick/260714-nfk-add-backlog-36-google-calendar-connectio/260714-nfk-SUMMARY.md` when done
</output>
