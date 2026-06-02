# Technology Stack: RideWindow

**Project:** RideWindow — Android cyclist weather-window app
**Researched:** 2026-06-01
**Overall confidence:** HIGH (all versions verified against pub.dev)

---

## Flutter / Dart Runtime

| Item | Version | Notes |
|------|---------|-------|
| Flutter SDK | 3.x (stable) | Material 3 is on by default since 3.16; `useMaterial3: true` is no longer needed explicitly |
| Dart SDK | 3.x | Null-safety, pattern matching, records — use throughout |

Material 3 is the correct target. Use `ColorScheme.fromSeed(seedColor: Color(0xFF2E7D32))` (cycling green from mockup) and `NavigationBar` (not the deprecated `BottomNavigationBar`). No theming library needed — Flutter's built-in M3 system covers all screens in the mockup.

---

## State Management

**Recommendation: Riverpod 3 with code generation**

| Package | Version (pub.dev) | Publisher | Likes | Published |
|---------|------------------|-----------|-------|-----------|
| `flutter_riverpod` | 3.3.1 | dash-overflow.net | 2.87k | 2 months ago |
| `riverpod_annotation` | 4.0.2 | dash-overflow.net | — | 3 months ago |
| `riverpod_generator` | resolved via build_runner | dash-overflow.net | — | — |
| `build_runner` | >=2.4 | dart.dev | — | active |

**Why Riverpod 3 over alternatives:**

- Riverpod 3.0 (released Sept 2025) unifies `AutoDisposeNotifier`/`Notifier` into one interface, reducing boilerplate
- `AsyncNotifier` is the idiomatic pattern for weather fetch + caching (loading/data/error states built in)
- Code generation (`@riverpod` annotation) eliminates provider registration boilerplate — solo-dev friendly
- No `BuildContext` dependency: providers are testable in isolation, which matters for scoring logic
- Provider and Bloc are either too simple (Provider — missing async primitives) or too verbose for a solo project (Bloc — event/state ceremony is overkill for 6 screens)

**Do NOT use:** `StateProvider`, `StateNotifierProvider`, `ChangeNotifierProvider` — these are legacy in Riverpod 3, moved to a `legacy` import path.

**Do NOT use:** GetX — v5.0 stuck in RC for 12+ months, anti-pattern concerns for code that needs to remain readable after a week away from it.

---

## Local Storage

Two-layer approach: simple settings in `shared_preferences`, structured data (availability calendar, cached forecasts) in `drift`.

### Layer 1 — Simple key-value settings

| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `shared_preferences` | 2.5.5 | flutter.dev | 10.5k | 2 months ago |

**Why:** User profile scalar values (ride length preferences, tolerance slider values, notification toggles, location override) are all primitive types (`bool`, `int`, `double`, `String`). `shared_preferences` is the official Flutter-team package, 4.83M weekly downloads, zero maintenance concern.

**Limitation to respect:** Not for critical data — weather cache goes to Drift, not here.

### Layer 2 — Structured local database

| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `drift` | 2.33.0 | simonbinder.eu | 2.4k | 28 days ago |

**Why Drift over alternatives:**

- **Drift vs Isar:** Isar 3.1.0 was last published 3 years ago on pub.dev (the stable version). Isar v4 is explicitly not production-ready. The community fork (`isar_community`) exists but adds maintenance uncertainty for a solo dev. Drift is a Flutter Favorite, published 28 days ago, battle-tested.
- **Drift vs Hive:** Hive original is unmaintained (community successor `hive_ce` exists but is a fork). Drift has SQL-level query power needed for the availability calendar (7×24 grid of hour cells, queryable by day+hour range). Hive's key-value model would require full-box scans.
- **Drift vs SQLite directly:** Drift is SQLite under the hood with type-safe query API and compile-time schema verification. Migration support is first-class — needed when adding features in v2.

**Data stored in Drift:**
1. `availability_blocks` table — the 7×24 weekly hour grid (day_index INT, hour INT, state TEXT)
2. `forecast_cache` table — serialized hourly forecast JSON + location + fetched_at timestamp
3. `ride_slots` table — computed scored slots (derived, cached to avoid recomputation on every open)

---

## Networking

| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `http` | 1.6.0 | dart.dev | 8.4k | 6 months ago |

**Why `http` over Dio:**

Open-Meteo has a single, simple REST endpoint: `GET /v1/forecast?latitude=...&longitude=...&hourly=...`. No auth, no interceptors, no token refresh, no file upload. Dio's extra weight (interceptor chains, CancelToken plumbing) is unjustified. The official Dart team `http` package is lighter, has a mock client built in for testing, and is already a transitive dependency of several other packages in this stack.

**Data model:** Use `freezed` + `json_serializable` for the Open-Meteo response model (see Models section).

---

## Data Models / Code Generation

| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `freezed` | 3.2.5 | dash-overflow.net | 4.4k | 3 months ago |
| `freezed_annotation` | (companion) | dash-overflow.net | — | — |
| `json_serializable` | >=6.7 | dart.dev | — | active |
| `json_annotation` | >=4.8 | dart.dev | — | active |

**Why:** The Open-Meteo response is deeply nested JSON. `freezed` gives immutable, equality-comparable model classes with `copyWith` and `fromJson`/`toJson` in a single annotation. This is the standard Flutter data-layer pattern in 2025/2026 and pairs naturally with Riverpod's `AsyncNotifier`.

---

## Location / GPS

| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `geolocator` | 14.0.2 | baseflow.com | 6.1k | 11 months ago |
| `permission_handler` | 12.0.3 | baseflow.com | 5.98k | 11 hours ago |

**Why `geolocator`:** Standard choice for Flutter GPS. Uses Android's `FusedLocationProviderClient` (preferred) or `LocationManager` fallback. Handles permission status, accuracy modes, and one-shot vs stream position. 6.1k likes, active.

**Why `permission_handler` separately:** `geolocator` has its own location permission request, but `permission_handler` is needed for the `POST_NOTIFICATIONS` permission (Android 13+) and for `SCHEDULE_EXACT_ALARM` (Android 12+/14+). Using one unified API for all permissions is cleaner than mixing two approaches.

**Android 14 alert:** `SCHEDULE_EXACT_ALARM` is denied by default on Android 14+ for new installs. The app must call `AlarmManager.canScheduleExactAlarms()` and prompt the user. `permission_handler` 12.x handles this.

**Manual location override:** No separate geocoding package needed for v1. Store city name + lat/lon pair in `shared_preferences` from a simple `TextField` with a curated short-list. Full city search (e.g., `geocoding` package) is a v2 feature.

---

## Background Work

| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `workmanager` | 0.9.0+3 | fluttercommunity.dev | 2.4k | 9 months ago |

**Why:** `workmanager` is the Flutter wrapper around Android's WorkManager — the platform-recommended approach for deferrable background work. Fetch fresh weather data every 3–6 hours in background even when app is closed. Supports periodic tasks and constraint-based execution (e.g., only when network available).

**Architecture note:** The background task callback must be a top-level Dart function (Flutter isolate limitation). Keep background task logic minimal: fetch Open-Meteo → write to Drift cache → optionally trigger a notification if a new great window is detected.

**Do NOT use:** `android_alarm_manager_plus` — requires `SCHEDULE_EXACT_ALARM` permission which users must grant manually on Android 14+. WorkManager's battery-efficient scheduling is the right default. Exact alarms are only needed for notification delivery (handled by `flutter_local_notifications`).

---

## Notifications

| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `flutter_local_notifications` | 21.0.0 | dexterx.dev | 7.3k | 2 months ago |
| `timezone` | 0.11.0 | labs.dart.dev | 580 | 4 months ago |
| `flutter_timezone` | 5.1.0 | wolverinebeach.net | 332 | 4 days ago |

**Why this trio:**

- `flutter_local_notifications` is the definitive Flutter notification package (1.88M weekly downloads, 160 pub points, prerelease v22 in progress). Handles "Evening before", "Morning of", and "Weekly digest" notification types. Uses `zonedSchedule()` for time-based delivery.
- `timezone` is required by `flutter_local_notifications` for `TZDateTime` — without it, scheduled notifications drift on DST changes or when users travel.
- `flutter_timezone` retrieves the device's current IANA timezone name at runtime so you can construct `tz.getLocation(deviceTimezone)` correctly. Published 4 days ago, actively maintained.

**Android manifest items needed:**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <!-- RECEIVE_BOOT_COMPLETED intent filter -->
</receiver>
```

---

## Navigation / Routing

| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `go_router` | 17.2.3 | flutter.dev | 5.73k | 31 days ago |

**Why:** Official Flutter-team router (2.9M downloads, Flutter Favorite). Navigation 2.0 based, handles Android back button correctly without `WillPopScope` hacks. Use `StatefulShellRoute` for the two-tab bottom nav (Home / Profile) to preserve each tab's scroll state. Named routes with `goNamed()` throughout.

**Routes to define:**
- `/` → Welcome (first run only)
- `/onboard` → Onboarding
- `/home` → Home (default after onboard)
- `/detail/:rideId` → Ride Detail
- `/profile` → Profile
- `/profile/availability` → Availability calendar

---

## Google Calendar Integration

| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `google_sign_in` | 7.2.0 | flutter.dev | 3.58k | 8 months ago |
| `extension_google_sign_in_as_googleapis_auth` | 3.0.0 | flutter.dev | 108 | 11 months ago |
| `googleapis` | 16.0.0 | google.dev | — | 3 months ago |

**Why this trio (not `googleapis_auth` directly):**

The official Flutter docs explicitly state: "Do not use `package:googleapis_auth` with a Flutter application; use `package:extension_google_sign_in_as_googleapis_auth` instead." The extension adds an `authenticatedClient()` method to `GoogleSignIn`, producing an `AuthClient` accepted by `CalendarApi`. This is the officially supported path as of Flutter 2026 docs.

**Scope needed:** `CalendarApi.calendarScope` (read/write). Request only at the moment the user taps "Add to calendar" — not at app launch (minimises permission friction and data-privacy surface).

**Calendar integration is optional and on-demand.** The entire Google Sign-In flow should be behind a lazy initialisation guard so it doesn't add cold-start cost.

---

## UI / Charts

**No chart package needed.**

The mockup shows three progress bars (temperature / rain / wind scores) in the "Why this score?" insight sheet. These are plain `LinearProgressIndicator` or a simple `CustomPainter` (a 8px high coloured bar). Adding `fl_chart` or Syncfusion for three static bars is massive overkill.

**If charts are added later (v2 — weekly overview sparklines, historical data):**

| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `fl_chart` | 1.2.0 | flchart.dev | 7.1k | 2 months ago |

`fl_chart` is the right choice at that point: 1.38M weekly downloads, 160 pub points, no licensing cost (unlike Syncfusion which requires a paid license for commercial use beyond community edition limits).

**Do NOT use:** Syncfusion Flutter Charts — commercial licensing required for production apps beyond the community free tier. Overkill for three progress bars.

---

## Packages Summary Table

| Category | Package | Version | Confidence |
|----------|---------|---------|------------|
| State mgmt | `flutter_riverpod` | 3.3.1 | HIGH |
| State mgmt codegen | `riverpod_annotation` + `riverpod_generator` | 4.0.2 | HIGH |
| Settings store | `shared_preferences` | 2.5.5 | HIGH |
| Structured DB | `drift` | 2.33.0 | HIGH |
| Networking | `http` | 1.6.0 | HIGH |
| Data models | `freezed` + `freezed_annotation` | 3.2.5 | HIGH |
| JSON serialization | `json_serializable` + `json_annotation` | >=6.7 | HIGH |
| Location | `geolocator` | 14.0.2 | HIGH |
| Permissions | `permission_handler` | 12.0.3 | HIGH |
| Background work | `workmanager` | 0.9.0+3 | HIGH |
| Notifications | `flutter_local_notifications` | 21.0.0 | HIGH |
| Timezone runtime | `flutter_timezone` | 5.1.0 | HIGH |
| Timezone data | `timezone` | 0.11.0 | HIGH |
| Navigation | `go_router` | 17.2.3 | HIGH |
| Google auth | `google_sign_in` | 7.2.0 | HIGH |
| Google auth bridge | `extension_google_sign_in_as_googleapis_auth` | 3.0.0 | HIGH |
| Google APIs | `googleapis` | 16.0.0 | HIGH |

---

## Installation (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2

  # Storage
  shared_preferences: ^2.5.5
  drift: ^2.33.0
  sqlite3_flutter_libs: ^0.5.0   # bundled SQLite for Drift on Android

  # Networking
  http: ^1.6.0

  # Data models
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

  # Location
  geolocator: ^14.0.2
  permission_handler: ^12.0.3

  # Background work
  workmanager: ^0.9.0+3

  # Notifications
  flutter_local_notifications: ^21.0.0
  timezone: ^0.11.0
  flutter_timezone: ^5.1.0

  # Navigation
  go_router: ^17.2.3

  # Google Calendar
  google_sign_in: ^7.2.0
  extension_google_sign_in_as_googleapis_auth: ^3.0.0
  googleapis: ^16.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code generation
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.0
  freezed: ^3.2.5
  json_serializable: ^6.7.0
```

---

## Alternatives Considered and Rejected

| Category | Rejected | Reason |
|----------|----------|--------|
| State mgmt | Bloc/BLoC | Event+state ceremony is 3× the code for 6 screens; overkill for solo dev |
| State mgmt | Provider | Missing native async primitives; effectively superseded by Riverpod |
| State mgmt | GetX | v5 stuck in RC; routing+DI+state in one package creates coupling; anti-patterns at scale |
| Database | Isar 3.x | Last stable pub.dev release 3 years ago; v4 not production-ready; community fork adds uncertainty |
| Database | `hive` / `hive_ce` | Original abandoned; `hive_ce` is community fork; NoSQL key-value is wrong fit for the availability grid |
| Database | ObjectBox | Proprietary native binary, adds ~5 MB to APK; Drift is lighter and SQL is portable |
| Networking | Dio | Interceptors / CancelToken / multipart are all unused for a single GET to Open-Meteo; adds 250 kB |
| Charts | Syncfusion | Paid license required in production; progress bars don't need a chart library |
| Charts | charts_flutter | Archived by Google in 2023; do not use |
| Background | `android_alarm_manager_plus` | Requires `SCHEDULE_EXACT_ALARM` which is denied by default on Android 14+; wrong tool for periodic background refresh |
| Calendar auth | `googleapis_auth` directly | Flutter docs explicitly state: use `extension_google_sign_in_as_googleapis_auth` instead |

---

## Flutter 3.x / Dart 3.x Considerations

- **Material 3 is default** since Flutter 3.16. `useMaterial3: true` is no longer needed in `ThemeData`. Use `NavigationBar` instead of `BottomNavigationBar`.
- **Dart 3 patterns:** Use sealed classes + pattern matching for ride slot quality tiers (Perfect/Great/Acceptable/Poor). This is cleaner than string enums.
- **`flutter_local_notifications` v21+** requires `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle` — the old `androidAllowWhileIdle: true` parameter is deprecated.
- **Riverpod 3.0:** `AutoDisposeNotifier` is now just `Notifier` (auto-dispose is default). `StateProvider` / `StateNotifierProvider` are legacy — do not use in new code.
- **`permission_handler` 12.x** requires `compileSdkVersion 35` in `android/app/build.gradle`.
- **`workmanager` 0.9.x** uses a federated plugin architecture — `workmanager_android` is pulled in automatically.
- **Isolate constraint:** WorkManager background callbacks run in a separate Dart isolate. Riverpod providers and Drift must be re-initialised inside the callback. Keep the background task a thin data layer operation (fetch → write → done).

---

## Sources

- pub.dev package pages (verified 2026-06-01): workmanager, flutter_local_notifications, geolocator, permission_handler, flutter_riverpod, riverpod_annotation, shared_preferences, drift, http, freezed, go_router, google_sign_in, extension_google_sign_in_as_googleapis_auth, googleapis, timezone, flutter_timezone, fl_chart
- [Flutter official: Google APIs integration](https://docs.flutter.dev/data-and-backend/google-apis)
- [Flutter Material 3 migration guide](https://docs.flutter.dev/release/breaking-changes/material-3-migration)
- [Riverpod 3.0 what's new](https://riverpod.dev/docs/whats_new)
- [Android 14 SCHEDULE_EXACT_ALARM changes](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)
- Quash blog: Hive vs Drift vs Floor vs Isar 2025
- FlutterFever: Dio vs http in Flutter
