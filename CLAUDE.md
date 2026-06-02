<!-- GSD:project-start source:PROJECT.md -->
## Project

**RideWindow**

RideWindow is an Android app for casual cyclists who want to know — at a glance — the best windows to ride this week. It combines an accurate cycling-specific weather score (temperature, rain, wind) with the user's personal availability calendar to produce concrete, bookable time slots like "Saturday 09:00–13:00, 4h — Perfect".

**Core Value:** **Accurate cyclist-specific weather scoring translated into concrete bookable time slots.** If the score is wrong, or the slot is unrideable in practice, the app fails — everything else is decoration.

### Constraints

- **Tech stack:** Flutter (Dart) — chosen for cross-platform readiness (iOS in v2), Material 3 out-of-the-box, hot reload DX, lower dependency-maintenance burden than React Native for solo devs.
- **Platforms:** Android-only for v1 — focus on one store, one review process, no Apple Dev Account ($99/yr) until Android proves the concept.
- **Budget:** ~€25 one-time (Google Play Developer account). No ongoing infra costs (Open-Meteo free, Firebase free tier, Google Calendar API free, all client-side).
- **Timeline:** Realistic 8–12 weeks side-project pace. Acceptable to ship a thin v1 fast and iterate.
- **No backend:** Pure client-side. Hive or Isar for local storage. Removes a whole tier of complexity (auth, hosting, GDPR) and lets v1 ship fast.
- **Privacy:** Location permission is the only sensitive permission. Privacy policy required (Play Store mandate). Data never leaves device unless user opts into Calendar integration.
- **Performance:** App must show forecast + slots within 2s of cold start (after first run). Weather refresh runs in background via WorkManager.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Flutter / Dart Runtime
| Item | Version | Notes |
|------|---------|-------|
| Flutter SDK | 3.x (stable) | Material 3 is on by default since 3.16; `useMaterial3: true` is no longer needed explicitly |
| Dart SDK | 3.x | Null-safety, pattern matching, records — use throughout |
## State Management
| Package | Version (pub.dev) | Publisher | Likes | Published |
|---------|------------------|-----------|-------|-----------|
| `flutter_riverpod` | 3.3.1 | dash-overflow.net | 2.87k | 2 months ago |
| `riverpod_annotation` | 4.0.2 | dash-overflow.net | — | 3 months ago |
| `riverpod_generator` | resolved via build_runner | dash-overflow.net | — | — |
| `build_runner` | >=2.4 | dart.dev | — | active |
- Riverpod 3.0 (released Sept 2025) unifies `AutoDisposeNotifier`/`Notifier` into one interface, reducing boilerplate
- `AsyncNotifier` is the idiomatic pattern for weather fetch + caching (loading/data/error states built in)
- Code generation (`@riverpod` annotation) eliminates provider registration boilerplate — solo-dev friendly
- No `BuildContext` dependency: providers are testable in isolation, which matters for scoring logic
- Provider and Bloc are either too simple (Provider — missing async primitives) or too verbose for a solo project (Bloc — event/state ceremony is overkill for 6 screens)
## Local Storage
### Layer 1 — Simple key-value settings
| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `shared_preferences` | 2.5.5 | flutter.dev | 10.5k | 2 months ago |
### Layer 2 — Structured local database
| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `drift` | 2.33.0 | simonbinder.eu | 2.4k | 28 days ago |
- **Drift vs Isar:** Isar 3.1.0 was last published 3 years ago on pub.dev (the stable version). Isar v4 is explicitly not production-ready. The community fork (`isar_community`) exists but adds maintenance uncertainty for a solo dev. Drift is a Flutter Favorite, published 28 days ago, battle-tested.
- **Drift vs Hive:** Hive original is unmaintained (community successor `hive_ce` exists but is a fork). Drift has SQL-level query power needed for the availability calendar (7×24 grid of hour cells, queryable by day+hour range). Hive's key-value model would require full-box scans.
- **Drift vs SQLite directly:** Drift is SQLite under the hood with type-safe query API and compile-time schema verification. Migration support is first-class — needed when adding features in v2.
## Networking
| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `http` | 1.6.0 | dart.dev | 8.4k | 6 months ago |
## Data Models / Code Generation
| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `freezed` | 3.2.5 | dash-overflow.net | 4.4k | 3 months ago |
| `freezed_annotation` | (companion) | dash-overflow.net | — | — |
| `json_serializable` | >=6.7 | dart.dev | — | active |
| `json_annotation` | >=4.8 | dart.dev | — | active |
## Location / GPS
| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `geolocator` | 14.0.2 | baseflow.com | 6.1k | 11 months ago |
| `permission_handler` | 12.0.3 | baseflow.com | 5.98k | 11 hours ago |
## Background Work
| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `workmanager` | 0.9.0+3 | fluttercommunity.dev | 2.4k | 9 months ago |
## Notifications
| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `flutter_local_notifications` | 21.0.0 | dexterx.dev | 7.3k | 2 months ago |
| `timezone` | 0.11.0 | labs.dart.dev | 580 | 4 months ago |
| `flutter_timezone` | 5.1.0 | wolverinebeach.net | 332 | 4 days ago |
- `flutter_local_notifications` is the definitive Flutter notification package (1.88M weekly downloads, 160 pub points, prerelease v22 in progress). Handles "Evening before", "Morning of", and "Weekly digest" notification types. Uses `zonedSchedule()` for time-based delivery.
- `timezone` is required by `flutter_local_notifications` for `TZDateTime` — without it, scheduled notifications drift on DST changes or when users travel.
- `flutter_timezone` retrieves the device's current IANA timezone name at runtime so you can construct `tz.getLocation(deviceTimezone)` correctly. Published 4 days ago, actively maintained.
## Navigation / Routing
| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `go_router` | 17.2.3 | flutter.dev | 5.73k | 31 days ago |
- `/` → Welcome (first run only)
- `/onboard` → Onboarding
- `/home` → Home (default after onboard)
- `/detail/:rideId` → Ride Detail
- `/profile` → Profile
- `/profile/availability` → Availability calendar
## Google Calendar Integration
| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `google_sign_in` | 7.2.0 | flutter.dev | 3.58k | 8 months ago |
| `extension_google_sign_in_as_googleapis_auth` | 3.0.0 | flutter.dev | 108 | 11 months ago |
| `googleapis` | 16.0.0 | google.dev | — | 3 months ago |
## UI / Charts
| Package | Version | Publisher | Likes | Published |
|---------|---------|-----------|-------|-----------|
| `fl_chart` | 1.2.0 | flchart.dev | 7.1k | 2 months ago |
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
## Installation (pubspec.yaml)
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
## Flutter 3.x / Dart 3.x Considerations
- **Material 3 is default** since Flutter 3.16. `useMaterial3: true` is no longer needed in `ThemeData`. Use `NavigationBar` instead of `BottomNavigationBar`.
- **Dart 3 patterns:** Use sealed classes + pattern matching for ride slot quality tiers (Perfect/Great/Acceptable/Poor). This is cleaner than string enums.
- **`flutter_local_notifications` v21+** requires `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle` — the old `androidAllowWhileIdle: true` parameter is deprecated.
- **Riverpod 3.0:** `AutoDisposeNotifier` is now just `Notifier` (auto-dispose is default). `StateProvider` / `StateNotifierProvider` are legacy — do not use in new code.
- **`permission_handler` 12.x** requires `compileSdkVersion 35` in `android/app/build.gradle`.
- **`workmanager` 0.9.x** uses a federated plugin architecture — `workmanager_android` is pulled in automatically.
- **Isolate constraint:** WorkManager background callbacks run in a separate Dart isolate. Riverpod providers and Drift must be re-initialised inside the callback. Keep the background task a thin data layer operation (fetch → write → done).
## Sources
- pub.dev package pages (verified 2026-06-01): workmanager, flutter_local_notifications, geolocator, permission_handler, flutter_riverpod, riverpod_annotation, shared_preferences, drift, http, freezed, go_router, google_sign_in, extension_google_sign_in_as_googleapis_auth, googleapis, timezone, flutter_timezone, fl_chart
- [Flutter official: Google APIs integration](https://docs.flutter.dev/data-and-backend/google-apis)
- [Flutter Material 3 migration guide](https://docs.flutter.dev/release/breaking-changes/material-3-migration)
- [Riverpod 3.0 what's new](https://riverpod.dev/docs/whats_new)
- [Android 14 SCHEDULE_EXACT_ALARM changes](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)
- Quash blog: Hive vs Drift vs Floor vs Isar 2025
- FlutterFever: Dio vs http in Flutter
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
