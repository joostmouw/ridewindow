# Phase 15: Google Calendar Web Integration - Pattern Map

**Mapped:** 2026-07-12
**Files analyzed:** 5 (2 modified source files, 1 modified config file, 2 net-new config/deploy artifacts)
**Analogs found:** 4 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `lib/services/calendar_service.dart` (modify) | service | request-response (OAuth + REST) | itself (existing file) + `lib/providers/gps_permission_notifier.dart` (for the `isWebPlatform` branch idiom) | exact (self) / role-match (branch idiom) |
| `lib/main.dart` (modify — add web-only eager `GoogleSignIn.instance.initialize()`) | config / bootstrap | event-driven (app startup) | itself (existing `if (!kIsWeb) { await Workmanager()... }` block) | exact |
| `web/index.html` (modify — add `google-signin-client_id` meta tag) | config | request-response (static asset) | itself (existing file, no meta-tag precedent yet) | no analog (first of its kind) |
| `firebase.json` / `.firebaserc` (new — preliminary hosting config for CAL-07) | config | file-I/O (deploy config) | none in repo | no analog |
| `test/services/calendar_service_test.dart` / new web-branch test additions | test | request-response | `test/providers/gps_permission_notifier_test.dart` (the `debugIsWebOverride` test idiom) | exact |

## Pattern Assignments

### `lib/services/calendar_service.dart` (service, request-response)

**Analog:** itself (`lib/services/calendar_service.dart`, this repo, Phase 9) + `lib/providers/gps_permission_notifier.dart` for the platform-branch idiom.

**Imports pattern** (current file, lines 1-10):
```dart
// Source: lib/services/calendar_service.dart lines 6-10
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
```
Add `import 'package:ridewindow/core/platform_info.dart';` alongside these — do not import `kIsWeb` directly (see Shared Patterns > isWebPlatform below).

**Existing lazy-init pattern to preserve/modify** (lines 12-22):
```dart
// Source: lib/services/calendar_service.dart lines 12-22
class CalendarService {
  static bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }
```
This is the exact spot RESEARCH.md Pitfall 1 / Pattern 2 targets: on web, `GoogleSignIn.instance.initialize()` must have already run (via eager main.dart init — see below) before the tap handler fires, so this method should become effectively a no-op on the *first* web call rather than the thing that performs the `await` inside the tap's call chain. Native (Android) behavior is unchanged — CAL-02's file-header comment ("GoogleSignIn.instance wordt uitsluitend lazy gebruikt... nooit aangemaakt bij app-start") must remain true for non-web.

**Platform-conditional clientId idiom to copy** (from `lib/providers/gps_permission_notifier.dart` lines 32-35):
```dart
// Source: lib/providers/gps_permission_notifier.dart lines 32-35
Future<void> openSettings() async {
  if (isWebPlatform) return;
  await openAppSettings();
}
```
Apply the same shape: `if (isWebPlatform) { /* web branch */ } else { /* native branch, UNCHANGED */ }`. A second close analog for a *value-returning* (not just early-return) branch is `lib/features/profile/profile_screen.dart` lines 296-297 (`isWebPlatform ? s.locationBlockedWebHint : s.locationBlockedHint`) — use this ternary shape if the web/native branch differs only in the `clientId` argument passed to `initialize()`.

**Core OAuth + REST pattern to preserve as-is** (lines 33-83, both `addRideSlotToCalendar` and `getEvents` share this shape):
```dart
// Source: lib/services/calendar_service.dart lines 36-46
final GoogleSignInClientAuthorization authorization;
try {
  authorization = await GoogleSignIn.instance.authorizationClient
      .authorizeScopes([CalendarApi.calendarEventsScope]);
} on GoogleSignInException catch (e) {
  if (e.code == GoogleSignInExceptionCode.canceled) {
    throw Exception('Aanmelden geannuleerd');
  }
  rethrow;
}
```
RESEARCH.md's primary recommendation is that this exact block needs **no code change** — only the reachability of `_ensureInitialized()` before it changes (must resolve synchronously/instantly on web after eager init).

**Error handling pattern** (lines 41-46, repeated at 98-103): `GoogleSignInException` with `.code == GoogleSignInExceptionCode.canceled` mapped to a Dutch-language `Exception('Aanmelden geannuleerd')`; all other exceptions `rethrow`. Reuse this exact pattern for any new error branch (e.g., a web-specific popup-blocked case if Pitfall 4's fallback is triggered) — do not introduce a different exception type.

**Resource cleanup pattern** (lines 48-51, 79-82):
```dart
// Source: lib/services/calendar_service.dart lines 79-82
} finally {
  // Stap 8: HTTP-client altijd sluiten (T-09-01-01: token opruimen).
  client.close();
}
```
Preserve this `finally { client.close(); }` shape unchanged — it is platform-agnostic (works identically on web `http` client).

---

### `lib/main.dart` (bootstrap/config, event-driven app startup)

**Analog:** itself — the existing web-conditional startup branch.

**Pattern to copy** (lines 55-67, existing `if (!kIsWeb)` startup block):
```dart
// Source: lib/main.dart lines 55-67
// Web heeft geen WorkManager-implementatie; sla deze stap over op web.
if (!kIsWeb) {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    kWeatherRefreshTaskTag,
    kWeatherRefreshTaskName,
    frequency: const Duration(hours: 3),
    flexInterval: const Duration(hours: 3),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
```
This is the closest structural analog for adding the *inverse* branch RESEARCH.md's Pattern 2 recommends: `if (kIsWeb) { await GoogleSignIn.instance.initialize(); }` placed after `runApp()` (matching where the Workmanager block currently sits, i.e., non-blocking for the first frame). Note `main.dart` currently imports `kIsWeb` directly from `package:flutter/foundation.dart` (line 5) rather than using `isWebPlatform` — RESEARCH.md and `platform_info.dart`'s own doc comment say every *testable* branch should use `isWebPlatform`, but `main()` itself is not unit-tested (no `flutter test` targets `main()` directly), so matching the file's own existing local convention (`kIsWeb`) here is consistent; introducing `isWebPlatform` in `CalendarService`/its consumers (which ARE tested) is still required. Flag this nuance for the planner to confirm during Task 1.

---

### `web/index.html` (config, static asset)

**Analog:** none — first meta-tag addition of this kind in the repo. Follow the documented mechanism directly from RESEARCH.md's Code Examples section rather than inventing a project pattern:
```html
<!-- Source: google_sign_in_web README (cited in 15-RESEARCH.md, Code Examples) -->
<meta name="google-signin-client_id" content="YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com">
```
Insert alongside the existing `<meta>` tags in `<head>` (current file has `description`, `mobile-web-app-capable`, `apple-mobile-web-app-status-bar-style`, `apple-mobile-web-app-title` — insert the new tag in that same block, before `<title>`). If the client ID must differ between local dev and the preliminary production deploy (RESEARCH.md Anti-Pattern 3 / Open Question 3), the planner must decide the templating mechanism (e.g., `--dart-define` + a small build-time substitution, or a single client ID with multiple authorized origins) — there is no existing project precedent for build-time HTML templating to copy from.

---

### `firebase.json` / `.firebaserc` (new config, file-I/O / deploy)

**Analog:** none. No Firebase config exists anywhere in this repo (confirmed: `find` for `firebase*` at repo root returns nothing). This is formally Phase 17's (`DEPLOY-01`/`DEPLOY-02`) responsibility per RESEARCH.md Pitfall 5, but a **preliminary, non-hardened** version is needed in this phase solely to obtain a real HTTPS domain for CAL-07 verification and for registering the OAuth "Authorized JavaScript origins." Since there is no in-repo pattern, the planner should treat this as greenfield config authored from Firebase's own `firebase init hosting` scaffold (per RESEARCH.md's "Don't Hand-Roll" table — do not hand-roll a custom static server config). Flag explicitly in the plan that Phase 17 will harden/extend this same file (rewrite rules, `sqlite3.wasm` content-type per PERS-07) rather than replace it.

---

### Test files — web-branch test additions

**Analog:** `test/providers/gps_permission_notifier_test.dart` lines 61-96 (the canonical `debugIsWebOverride` test idiom already established for `isWebPlatform`-gated behavior).

**Pattern to copy**:
```dart
// Source: test/providers/gps_permission_notifier_test.dart lines 61-67, 62
group('openSettings() web guard (LOC-07)', () {
  tearDown(() => debugIsWebOverride = null);

  test(
      'openSettings() completes without throwing when debugIsWebOverride is true',
      () async {
    debugIsWebOverride = true;
    // ... exercise the web branch ...
  });
});
```
Key rule embedded in this analog: `debugIsWebOverride` is a **process-global mutable variable** — every test group that sets it MUST reset it to `null` in `tearDown()` (see also `test/features/home_screen_refresh_test.dart` line 188 and `test/features/profile_screen_location_test.dart` line 125 for two more instances of the same tearDown discipline). Apply this exact idiom to any new test for `CalendarService`'s web-conditional `clientId`/init-skip branch.

For the existing `CalendarService` OAuth flow itself, note the explicit scope boundary already documented in `test/services/calendar_service_test.dart` lines 144-155: real `GoogleSignIn.instance` sign-in is declared out of unit-test scope ("mocken van GoogleSignIn.instance... vereist een aparte integratie-test setup") — widget-level factory injection (`CalendarServiceFactory`, see `ride_detail_screen.dart` lines 32-36 and `test/features/detail/ride_detail_screen_calendar_test.dart`'s `FakeCalendarService`/`SuccessFakeCalendarService`/`ErrorFakeCalendarService`) is the established substitute pattern. Any new web-specific test should follow this same factory-injection + fake-subclass shape rather than attempting to mock `GoogleSignIn.instance` directly.

## Shared Patterns

### `isWebPlatform` seam (applies to `calendar_service.dart` and any new provider/widget code touched this phase)
**Source:** `lib/core/platform_info.dart` (full file, 27 lines)
**Apply to:** `CalendarService._ensureInitialized()` / clientId selection; any UI copy differences for web vs native error states surfaced by the calendar flow.
```dart
// Source: lib/core/platform_info.dart lines 20-27
@visibleForTesting
bool? debugIsWebOverride;

bool get isWebPlatform => debugIsWebOverride ?? kIsWeb;
```
**Rule:** never import `kIsWeb` directly in code that has (or should have) `flutter test` coverage — `main.dart` is the one existing exception because it is not unit-tested directly (see note above).

### GoogleSignInException error-mapping (applies to any new branch inside `CalendarService`)
**Source:** `lib/services/calendar_service.dart` lines 41-46 and 98-103 (identical block, twice)
```dart
} on GoogleSignInException catch (e) {
  if (e.code == GoogleSignInExceptionCode.canceled) {
    throw Exception('Aanmelden geannuleerd');
  }
  rethrow;
}
```
**Apply to:** Any new error path introduced for web-specific failures (e.g., a `GoogleSignInExceptionCode` value observed only on web during Task 1's spike). Keep Dutch-language user-facing exception text consistent with the rest of the file (all in-file strings are Dutch — `Aanmelden geannuleerd`, `Geen weerdata beschikbaar`).

### CalendarServiceFactory dependency injection (applies to any widget-level test of the calendar flow)
**Source:** `lib/features/detail/ride_detail_screen.dart` lines 32-49
```dart
typedef CalendarServiceFactory = CalendarService Function();

CalendarService _defaultCalendarServiceFactory() => CalendarService();

class RideDetailScreen extends ConsumerStatefulWidget {
  final CalendarServiceFactory calendarServiceFactory;
  const RideDetailScreen({
    super.key,
    required this.slot,
    required this.forecasts,
    this.calendarServiceFactory = _defaultCalendarServiceFactory,
  });
```
**Apply to:** Do not introduce a new DI mechanism (Riverpod provider override, service locator, etc.) for any new web-testing seam this phase touches — this factory-typedef pattern is the project's established convention for service-level test injection (PERS-04 rationale documented at the call site).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `web/index.html` meta-tag addition | config | request-response (static) | First `<meta name="google-signin-client_id">`-style addition in the repo; no prior build-time HTML templating precedent exists for differentiating dev vs prod client IDs |
| `firebase.json` / `.firebaserc` (preliminary hosting config) | config | file-I/O | No Firebase config exists anywhere in the repo yet (verified via `find`); this is genuinely greenfield, formally owned by Phase 17 but needed early per RESEARCH.md Pitfall 5 |

## Metadata

**Analog search scope:** `lib/services/`, `lib/core/`, `lib/providers/`, `lib/features/detail/`, `lib/features/home/`, `lib/features/profile/`, `lib/main.dart`, `web/`, `test/services/`, `test/providers/`, `test/features/` (repo root for `firebase*`)
**Files scanned:** `lib/services/calendar_service.dart`, `lib/core/platform_info.dart`, `lib/providers/gps_permission_notifier.dart`, `lib/features/home/home_screen.dart`, `lib/features/profile/profile_screen.dart`, `lib/features/detail/ride_detail_screen.dart`, `lib/main.dart`, `web/index.html`, `test/services/calendar_service_test.dart`, `test/providers/gps_permission_notifier_test.dart`, `test/features/detail/ride_detail_screen_calendar_test.dart`
**Pattern extraction date:** 2026-07-12
