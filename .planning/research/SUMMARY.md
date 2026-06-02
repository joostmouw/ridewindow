# Project Research Summary

**Project:** RideWindow
**Domain:** Local-first Flutter Android app — cyclist weather-window scheduler
**Researched:** 2026-06-01
**Confidence:** HIGH

## Executive Summary

RideWindow is a solo-dev Flutter Android app that occupies a genuine white space: no competitor (MyWindsock, Epic Ride Weather, Headwind, Komoot, Windy.app, cyclingweather.app) combines a cyclist-specific weather score with the user's personal availability calendar to output ready-made, bookable time slots. All existing apps either require a pre-existing route or leave the user to read a chart and infer their own window. The recommended build approach is domain-first: write and fully unit-test the pure Dart scoring engine and slot generator before touching the UI or network layer. Every screen and every notification is downstream of the scoring pipeline — a bug discovered late here is catastrophic.

The stack is fully validated against pub.dev (all packages verified 2026-06-01). Flutter 3.x + Riverpod 3 + Drift cover the core runtime. `workmanager` + `flutter_local_notifications` handle background refresh and notifications. `google_sign_in` + `googleapis` cover the optional Calendar export. Open-Meteo provides free, key-free, hourly forecasts. No backend is needed for v1: all data lives on device, which eliminates auth, hosting, and GDPR complexity. The ~€25 Play Console account is the only cash outlay.

The top risks are (1) Open-Meteo timezone mismatches that shift slot times by hours if `timezone=auto` is omitted from every HTTP request, (2) null weather fields silently producing perfect scores when data is absent, (3) WorkManager background refresh silently failing on OEM-skinned devices (Xiaomi, Samsung), (4) the Android 12+ exact-alarm permission requirement silently suppressing notifications, and (5) losing the signing keystore with no recovery path. All five are preventable with upfront conventions and a single physical-device release-APK smoke test before any Play Console submission.

---

## Key Findings

### Recommended Stack

The full stack is a single coherent choice with no ambiguous decisions remaining. Flutter 3.x with Material 3 defaults is the correct target — `useMaterial3: true` is no longer needed and `NavigationBar` replaces the deprecated `BottomNavigationBar`. Riverpod 3 (released Sept 2025) is the right state management layer for a solo dev: code generation via `@riverpod` annotations eliminates boilerplate, `AsyncNotifier` maps directly to the weather-fetch → cache → UI pipeline, and `SlotsNotifier` can `ref.watch` both weather and profile providers so derived slots recompute automatically on any change. Drift (not Isar — stable release 3 years stale; not Hive — unmaintained original) is the correct local database: SQL-level queries for the 7×24 availability grid, type-safe schema, first-class migrations for v2 additions.

**Core technologies:**

- `flutter_riverpod` 3.3.1 + `riverpod_annotation` 4.0.2: state management with code generation — eliminates provider boilerplate, AsyncNotifier handles weather fetch lifecycle, derived providers auto-recompute
- `drift` 2.33.0 + `sqlite3_flutter_libs`: structured local DB for availability grid, forecast cache, and ride slots — SQL queries, compile-time schema, first-class migration support
- `shared_preferences` 2.5.5: key-value store for scalar settings (tolerances, notification toggles, location override) — official Flutter-team package, zero maintenance concern
- `http` 1.6.0: Open-Meteo REST calls — single GET endpoint, no auth, no interceptors; Dio is unjustified
- `freezed` 3.2.5 + `json_serializable`: immutable domain models with `fromJson`/`toJson` — standard pattern for deeply nested Open-Meteo JSON responses
- `geolocator` 14.0.2 + `permission_handler` 12.0.3: GPS with FusedLocationProvider; unified permission API for location, POST_NOTIFICATIONS, and SCHEDULE_EXACT_ALARM
- `workmanager` 0.9.0+3: Android WorkManager wrapper for periodic background weather refresh — battery-aware, OS-deferred scheduling; cannot update Riverpod state directly (bridge via Drift)
- `flutter_local_notifications` 21.0.0 + `timezone` 0.11.0 + `flutter_timezone` 5.1.0: trio required for DST-correct scheduled notifications; `timezone` package mandatory for `TZDateTime`, `flutter_timezone` for runtime IANA name
- `go_router` 17.2.3: official Flutter-team router, `StatefulShellRoute` preserves tab scroll state, named routes throughout
- `google_sign_in` 7.2.0 + `extension_google_sign_in_as_googleapis_auth` 3.0.0 + `googleapis` 16.0.0: officially documented trio for Calendar OAuth — do NOT use `googleapis_auth` directly per Flutter docs

No chart package needed for v1. The insights sheet uses three plain `LinearProgressIndicator` widgets. `fl_chart` 1.2.0 is the right choice if weekly sparklines are added in v2.

### Expected Features

Six competitors were analyzed. The white space is confirmed: no app does (a) cyclist-specific score + (b) personal availability calendar + (c) ready-made bookable slots. RideWindow's moat is the combination, not any individual feature.

**Must have — table stakes (users expect, missing = uninstall):**

- 7-day hourly weather forecast for GPS location — Open-Meteo covers this, no key needed
- Cyclist-relevant parameters: temperature, rain, wind — all three in scoring model
- "Feels like" temperature (apparent_temperature field) — GAP: not in current mockup, must add to Ride Detail screen
- Hourly breakdown within a ride window — in mockup (Ride Detail "Hourly" card)
- Color-coded quality at a glance (green/amber/red) — in mockup (week strip dots, card border colors)
- Transparent score explanation ("Why this score?") — in mockup (insights sheet, 3 progress bars + i button)
- GPS auto-detection with graceful degradation — GAP: mockup shows happy path only; denied state and fallback must be built
- Manual location override (city picker) — in PROJECT.md; needs implementation
- Local data persistence (settings survive restart) — in PROJECT.md
- Basic opt-in notifications — in mockup (Profile, 3 types)
- Onboarding that sets expectations — in mockup (4 preset options)
- Empty state when no slots qualify — GAP: mockup has no empty/error state; must design before build

**Should have — RideWindow's competitive edge:**

- Availability-aware slot generation (weather score x blocked hours) — the single biggest gap across all competitors; protect this first
- Concrete bookable time slots with duration labels ("Saturday 09:00–13:00, 4h — Perfect") — unique UX pattern in this space
- Weekly availability calendar (work-hour blocking, hour-cell grid) — no competitor does this
- Pre-set availability patterns for onboarding (4 one-tap options) — reduces setup to one tap
- Weather tolerance sliders per factor (temp, rain, wind) — no competitor offers casual-rider tolerance adjustment
- Ride-length preference filter (2h / 3h / 4–5h chips) — low complexity, high perceived value
- Google Calendar export with weather summary — optional, on-demand OAuth
- "After work" context labels on slot cards — simple, highly resonant with persona

**Defer to v1.x (post-validation):**

- Wind direction label on cards ("tailwind/headwind on return")
- "Feels like" on home card chips (currently only detail)
- Android home screen widget
- Settings export/import file

**Defer to v2+:**

- Route planning / GPX + weather overlay
- Multi-location saved spots
- Cycling-type profiles (road / gravel / MTB)
- iOS port (Flutter codebase is ready)
- Wear OS tile

### Architecture Approach

RideWindow uses a clean 4-layer architecture: Presentation (screens + Riverpod notifiers), Domain (pure Dart — ScoringEngine, SlotGenerator, AvailabilityFilter, value objects), Data (repositories, OpenMeteoClient, CalendarService, NotificationService), and Platform (WorkManager callbackDispatcher, geolocator wrapper). The central architectural pattern is a derived provider chain: `WeatherNotifier` (AsyncNotifier) feeds `SlotsNotifier` which watches both weather and profile, and `HomeScreen` watches `SlotsNotifier`. Slots are never stored in Drift — they are recomputed in memory from the 168-hour forecast cache on demand (pure Dart, <5ms). The WorkManager bridge is Drift: the background isolate writes fresh forecast to Drift; `AppLifecycleState.resumed` triggers `ref.invalidate(weatherNotifierProvider)` which re-reads Drift and rebuilds the pipeline. Folder structure is feature-first with shared `domain/` and `data/` layers.

**Major components:**

1. `ScoringEngine` (domain) — pure function: `(HourlyForecast, Tolerances) → HourlyScore (0–100 with 3 sub-scores)`; must have 100% unit test coverage before any screen is built
2. `SlotGenerator` + `AvailabilityFilter` (domain) — pure functions: contiguous-run detection → `List<RideSlot>`; filtered by user's blocked hours
3. `WeatherRepository` (data) — cache-or-fetch: checks Drift `ForecastCache.isStale()` before hitting Open-Meteo; always returns typed domain models
4. `SlotsNotifier` (presentation) — Riverpod `AsyncNotifier` that `ref.watch`es weather + profile; entire UI rebuilds reactively on any change
5. `ProfileRepository` (data) — persists two separate Drift tables: scalar settings and 7×24 availability grid — never one combined blob
6. `NotificationService` (data) — schedules evening-before / morning-of via exact alarms; weekly digest via WorkManager one-off task
7. `CalendarService` (data) — lazy-initialized Google Calendar OAuth; only touched when user taps "Add to calendar"
8. `callbackDispatcher` (platform) — top-level Dart function in WorkManager isolate; Drift re-initialized independently; must NOT touch Riverpod

### Critical Pitfalls

1. **Open-Meteo timezone mismatch** — Always pass `&timezone=auto&timeformat=unixtime` in every HTTP request, enforced at the client layer (not call sites). Store all timestamps as UTC epoch ints; convert to local time only at display. Unit test: Amsterdam coordinate asserts slot time is UTC+2 offset. Address in Phase 3.

2. **Null weather fields produce silent perfect scores** — Model every Open-Meteo field as `double?`. Treat null as "data unavailable" — clamp to 50/100 and surface an "Incomplete data" indicator. Never coerce null to 0. Unit test with partial null responses. Address in Phase 3.

3. **Off-by-one slot boundary errors** — Define one convention: `slotEnd` is exclusive (open interval `[start, end)`) matching Dart's `DateTime` arithmetic. Write property-based tests: N consecutive good hours → slot duration == N hours exactly. Test the 7-day forecast boundary. Address in Phase 1.

4. **WorkManager silent failure on OEM devices** — Treat background refresh as best-effort, never guaranteed. Always provide foreground pull-to-refresh as the primary path. Show `lastRefreshed` timestamp; if data is >3 hours old, show a "Refresh now" nudge. Test on Samsung / Xiaomi, not only Pixel. Address in Phase 6.

5. **Exact alarm permission silently suppresses notifications on Android 12+** — Call `requestExactAlarmsPermission()` before scheduling any notification. Fall back to `AndroidScheduleMode.inexact` with user communication if permission is denied. Test on a fresh Android 12+ install. Address in Phase 6.

**Additional critical pitfalls:**

6. **Location "denied forever" not reliably detected** — After second `denied` return, show `Geolocator.openAppSettings()` deep-link. Manual city picker must be a first-class, fully functional alternative. Address in Phase 7.

7. **Signing keystore lost = app permanently unrecoverable** — Enroll in Google Play App Signing on the very first upload. Store keystore + all passwords in a password manager as the first act of Phase 9. Never store keystore in the repo.

8. **Drift schema breaking changes on app update** — Append-only column convention: never drop or reorder columns. Use Drift's built-in migration API for any schema change. Document column history in a comment on every table class.

9. **Release build crashes that never appeared in debug** — Build and sideload a release APK on a physical device before any Play Console submission. Use `--split-debug-info` on every release build and keep the output files.

10. **Google Play 12-tester / 14-day closed testing gate** — Recruit 12+ testers from week 1. Open the closed testing track as soon as Phase 5A produces a functional build. The internal testing track does NOT count toward this requirement.

---

## Implications for Roadmap

The architecture research provides an explicit build order. The FEATURES.md dependency graph confirms slot generation is the center of gravity — it must be correct before any UI, notification, or calendar feature can be validated. The UI splits into three sub-phases (A/B/C) covering the mockup's three screen clusters. Release targets the internal testing track only — no public production gate in v1 scope.

### Phase 1: Foundation — Domain Layer + Scoring Engine

**Rationale:** Zero external dependencies. Built and fully unit-tested with plain `dart test` before any API key, device, or package is needed. A broken scoring formula discovered in Phase 8 would require reworking every downstream component. This is the highest-leverage phase to get right first.
**Delivers:** `ScoringEngine`, `SlotGenerator`, `AvailabilityFilter`; all domain models (`HourlyForecast`, `HourlyScore`, `RideSlot`, `UserProfile`, `Tolerances`); 100% unit test coverage including null-field edge cases, off-by-one slot boundaries, and Amsterdam UTC+2 timezone assertion.
**Addresses:** Core scoring and slot generation (PROJECT.md Active requirements)
**Avoids:** Null propagation pitfall, off-by-one slot boundary pitfall (both must be caught here, not in production)
**Research flag:** Standard patterns — pure Dart, no external dependencies; skip research-phase

### Phase 2: Data Layer — Local Storage (Drift + SharedPreferences)

**Rationale:** Cache layer must exist before the weather repository can write to it. Profile persistence must exist before onboarding can save defaults.
**Delivers:** `ProfileRepository` (two Drift tables: scalar settings + 7×24 availability grid), `ForecastCache` (Drift), `shared_preferences` setup for scalar settings; Drift schema with migration scaffolding; append-only column convention established before any data is written.
**Uses:** `drift` 2.33.0 + `sqlite3_flutter_libs`, `shared_preferences` 2.5.5
**Implements:** Data layer — local storage (ARCHITECTURE.md)
**Avoids:** Schema migration pitfall (append-only column convention from day one)
**Research flag:** Standard patterns — Drift official docs are thorough; skip research-phase

### Phase 3: Data Layer — Weather Fetch + Repository

**Rationale:** With the cache layer in place, the `WeatherRepository` can implement cache-or-fetch. Freezed models for Open-Meteo JSON must be defined here so the domain layer can consume typed data.
**Delivers:** `OpenMeteoClient` (HTTP GET with `timezone=auto&timeformat=unixtime` hardcoded at the client layer), `WeatherRepository` (cache-or-fetch logic, 1h TTL), `freezed` response models with all fields typed as `double?`; unit tests with partial null responses; Amsterdam hardcoded for development.
**Uses:** `http` 1.6.0, `freezed` 3.2.5 + `json_serializable`, Drift ForecastCache
**Avoids:** Open-Meteo timezone mismatch pitfall, null propagation pitfall
**Research flag:** Single GET endpoint with two known gotchas (timezone param, nullable fields) — fully documented; skip research-phase

### Phase 4: State Wiring — Riverpod Provider Graph

**Rationale:** Screens are thin consumers of providers. Without a working provider graph, widget development is blocked. Build the full provider graph first so each screen wires up directly.
**Delivers:** `WeatherNotifier` (AsyncNotifier), `SlotsNotifier` (derived — watches weather + profile), `AvailabilityNotifier`, `ProfileNotifier`; `providers.dart` barrel file; `AppLifecycleState.resumed` → `ref.invalidate` bridge for WorkManager; `ProviderContainer` override tests.
**Uses:** `flutter_riverpod` 3.3.1 + `riverpod_annotation` 4.0.2
**Avoids:** Anti-pattern of scoring logic in UI layer; anti-pattern of storing computed slots in Drift
**Research flag:** Riverpod 3 official docs are thorough; skip research-phase

### Phase 5A: UI — Onboarding + Home Screen

**Rationale:** First visible end-to-end flow. With the full pipeline working (Phases 1–4), onboarding and the home screen are the MVP visible value — the first moment the app produces real ride slots on a device.
**Delivers:** `OnboardingScreen` (4 preset options seeding availability grid), `HomeScreen` (week strip + ranked ride cards with Perfect/Great/Acceptable tiers and "after work" labels), `WelcomeScreen` (first run only); `go_router` route setup with all 6 routes defined.
**Gap to close:** Design and implement empty state for "no qualifying slots" — must be in this phase, not deferred.
**Uses:** `go_router` 17.2.3, Material 3 `NavigationBar`, `StatefulShellRoute`
**Research flag:** Mockup is the visual contract; skip research-phase

### Phase 5B: UI — Ride Detail + Insights Sheet

**Rationale:** The "Why this score?" transparency is a table-stakes trust feature. Testers cannot evaluate whether scoring is correct without seeing the score breakdown. Must exist before any tester feedback is meaningful.
**Delivers:** `RideDetailScreen` (score banner, weather parameter rows, hourly breakdown table), `InsightsSheet` (bottom sheet with 3 `LinearProgressIndicator` bars + text explanations per factor).
**Gap to close:** Add "feels like" temperature (`apparent_temperature` from Open-Meteo) to the detail screen — confirmed table stakes, not in current mockup.
**Research flag:** Standard Material 3 patterns; skip research-phase

### Phase 5C: UI — Profile + Availability Screens

**Rationale:** Personalisation closes the feedback loop. Tolerance sliders modify scoring; availability calendar modifies slot filtering. These screens make the slots personally meaningful rather than generic.
**Delivers:** `ProfileScreen` (location row, ride length chips, notification toggles, weather sensitivity section, Google Calendar row), `AvailabilityScreen` (7×24 hour-cell grid with tap-to-toggle, save button), `ToleranceSlider` widget.
**Addresses:** Tolerance sliders, ride-length preference chips, weekly availability calendar (FEATURES.md differentiators)
**Research flag:** 7×24 grid is non-trivial but standard Flutter; use `RepaintBoundary` per row if redraws feel slow; skip research-phase

### Phase 6: Background Refresh + Notifications

**Rationale:** Passive value layer — heads-up without opening the app. Depends on the full pipeline being correct (Phases 1–4) and UI being testable (Phase 5). WorkManager background refresh must be treated as best-effort from the start.
**Delivers:** `callbackDispatcher` (top-level Dart function, Drift re-initialized in background isolate, periodic task registration), `NotificationService` (evening-before + morning-of exact alarms, weekly digest one-off task), `lastRefreshed` timestamp visible in UI, pull-to-refresh as primary foreground path.
**Uses:** `workmanager` 0.9.0+3, `flutter_local_notifications` 21.0.0, `timezone` + `flutter_timezone`, `permission_handler` 12.0.3
**Avoids:** WorkManager OEM failure pitfall (best-effort design, `lastRefreshed` display), exact alarm permission pitfall (`requestExactAlarmsPermission()` called before scheduling)
**Research flag:** Pitfalls fully documented in PITFALLS.md; test on Samsung / Xiaomi physical devices; skip research-phase

### Phase 7: Location — GPS + City Picker

**Rationale:** Deferred because Amsterdam hardcoded is sufficient for all development phases 1–6. GPS is polish, not MVP blocking. Deferring removes the permission state machine complexity from every earlier phase.
**Delivers:** `LocationService` wrapper (geolocator one-shot position, permission request, denied-forever detection with `openAppSettings()` deep-link), manual city picker (short-list with stored lat/lon in `shared_preferences`), full permission state machine tested (grant / deny / deny-forever / manual fallback).
**Gap to close:** Location permission denied state and manual city picker fallback must be first-class — confirmed gap in FEATURES.md.
**Uses:** `geolocator` 14.0.2, `permission_handler` 12.0.3
**Avoids:** Location "denied forever" pitfall (timing heuristic + city picker fallback)
**Research flag:** Geolocator `deniedForever` cross-API-level behaviour documented in PITFALLS.md; test physically on Android 9, 10, 11, 14; skip research-phase

### Phase 8: Google Calendar Integration

**Rationale:** Fully optional and on-demand. Requires a Google Cloud project separate from the app — deferred until core product is validated. Decoupled from all other features.
**Delivers:** `CalendarService` (lazy-initialized, `isSignedIn()` guard, `createEvent(slot)` with weather summary in event description), `signInSilently()` on resume if previously authorized, `AutoRefreshingAuthClient` for automatic token refresh, graceful handling of `PlatformException(sign_in_required)`.
**Uses:** `google_sign_in` 7.2.0, `extension_google_sign_in_as_googleapis_auth` 3.0.0, `googleapis` 16.0.0
**Avoids:** OAuth token expiry pitfall (AutoRefreshingAuthClient), full calendar scope pitfall (use `calendar.events` scope only)
**Research flag:** Google Cloud project setup (OAuth consent screen, SHA-1 fingerprint registration, Play Console SHA-1) is procedural but fiddly for first-time publishers. Consider `/gsd-plan-phase --research-phase 8` for a step-by-step checklist before writing Calendar code.

### Phase 9: Release — Internal Testing Track

**Rationale:** Internal testing track has no review and unlimited invites — correct first deployment target. No public production gate needed for v1. Start tester recruitment from Phase 1 to avoid being surprised by the 12-tester / 14-day closed testing gate.
**Delivers:** Signed release AAB (ProGuard + `--obfuscate` + `--split-debug-info` symbol files retained), Google Play App Signing enrolled, keystore backed up in password manager, `proguard-rules.pro` with plugin keep-rules validated, release APK sideloaded and smoke-tested on physical device before Play submission, privacy policy published on GitHub Pages, Data Safety form completed (precise location + ephemeral Google account data declared), Play Store listing, internal testing track with 10–20 cyclist friends invited.
**Avoids:** Keystore lost pitfall, release build crash pitfall, Data Safety form rejection pitfall, privacy policy broken link pitfall, 12-tester gate pitfall (recruit early, open closed testing track in parallel with Phase 5A)
**Research flag:** Play Console steps and Data Safety form requirements are fully documented in PITFALLS.md; skip research-phase

### Phase Ordering Rationale

- Domain before data before providers before screens: strict downward dependency, no layer depends on anything above it. Every phase adds testable, shippable value without requiring rework of earlier phases.
- UI split into three sub-phases (5A / 5B / 5C) because the mockup covers three screen clusters that can be built and tested independently. Onboarding + home first because it is the first moment the app produces visible output on a device.
- GPS deferred to Phase 7 because Amsterdam hardcoded unblocks all development phases with zero friction — explicitly called out in ARCHITECTURE.md build order.
- Calendar deferred to Phase 8 because it requires a Google Cloud project and is fully optional. The app is complete and shippable without it.
- Release is Phase 9, internal testing track only — no public production submission in v1 scope.

### Research Flags

Phases needing deeper research during planning:

- **Phase 8 (Google Calendar):** Google Cloud project setup, OAuth consent screen configuration, and SHA-1 fingerprint registration in Play Console are procedural but error-prone for first-time publishers. Recommend `/gsd-plan-phase --research-phase 8` to generate a step-by-step setup checklist before writing any Calendar code.

Phases with standard, well-documented patterns (skip research-phase):

- **Phase 1 (Domain layer):** Pure Dart, no dependencies; standard scoring and slot-generation patterns
- **Phase 2 (Local storage):** Drift official docs are thorough
- **Phase 3 (Weather fetch):** Single Open-Meteo GET; timezone and null pitfalls fully documented
- **Phase 4 (State wiring):** Riverpod 3 official docs; derived provider pattern explicit in ARCHITECTURE.md
- **Phase 5A / 5B / 5C (UI):** Mockup is the visual contract; Material 3 patterns are standard
- **Phase 6 (Background + Notifications):** Pitfalls fully documented; test on physical OEM devices
- **Phase 7 (Location):** Geolocator patterns are standard; pitfalls documented
- **Phase 9 (Release):** Play Console steps are procedural; all pitfalls documented in PITFALLS.md

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All 17 packages verified on pub.dev 2026-06-01; versions confirmed current; all rejected alternatives documented with reasons |
| Features | HIGH | 6 competitors analyzed via official sources + review sites; white space confirmed; 3 gaps identified vs. mockup |
| Architecture | HIGH | Flutter official docs + Riverpod official docs + verified community sources; all code patterns explicitly validated |
| Pitfalls | HIGH | 15 pitfalls with specific open GitHub issues and official docs cited; all Play Store requirements verified against Play Console Help |

**Overall confidence:** HIGH

### Gaps to Address

- **"Feels like" temperature on Ride Detail screen:** Not in current mockup but confirmed table stakes across all competitor apps. Add `apparent_temperature` to the Open-Meteo request in Phase 3 and to the detail screen UI in Phase 5B. Mockup should be updated or a design decision made before Phase 5B begins.
- **Empty state design (no qualifying slots):** Mockup shows the happy path only. A week of bad weather or a fully blocked availability grid must show a meaningful empty state, not a blank screen. Design and implement in Phase 5A alongside the home screen.
- **Location permission denied fallback (city picker):** Mockup shows the happy path only. The full permission state machine (grant / deny once / deny forever / manual city picker) must be designed before Phase 7 begins. The city picker must be a first-class feature, not a hidden fallback path.
- **12-tester / 14-day closed testing gate:** Process gap, not technical. Recruit 12+ testers from week 1. Open the closed testing track as soon as Phase 5A produces a functional build — do not wait for a polished release.
- **Google Cloud project for Calendar OAuth:** Requires setting up a separate Google Cloud project, configuring an OAuth consent screen, and registering the app's SHA-1 fingerprint. Plan for this setup at the start of Phase 8 — it is not part of the app code but gates the entire Calendar feature.

---

## Sources

### Primary (HIGH confidence)

- pub.dev package pages (verified 2026-06-01): `flutter_riverpod`, `riverpod_annotation`, `shared_preferences`, `drift`, `http`, `freezed`, `go_router`, `google_sign_in`, `extension_google_sign_in_as_googleapis_auth`, `googleapis`, `geolocator`, `permission_handler`, `workmanager`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `fl_chart`
- Flutter official architecture docs: https://docs.flutter.dev/app-architecture/concepts
- Flutter MVVM layered architecture case study: https://docs.flutter.dev/app-architecture/case-study
- Riverpod 3.x official docs: https://riverpod.dev/docs/how_to/testing
- Riverpod 3.0 what's new: https://riverpod.dev/docs/whats_new
- Flutter background isolates: https://docs.flutter.dev/perf/isolates
- Flutter official: Google APIs integration: https://docs.flutter.dev/data-and-backend/google-apis
- Flutter Material 3 migration guide: https://docs.flutter.dev/release/breaking-changes/material-3-migration
- Android 14 SCHEDULE_EXACT_ALARM changes: https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
- Open-Meteo API reference: https://open-meteo.com/en/docs
- Play Console Help — Data safety section: https://support.google.com/googleplay/android-developer/answer/10787469
- Play Console Help — Testing requirements for new personal accounts: https://support.google.com/googleplay/android-developer/answer/14151465

### Secondary (MEDIUM confidence)

- BLoC vs Riverpod 2026: https://flutterstudio.dev/blog/bloc-vs-riverpod.html
- Flutter feature-first vs layer-first: https://codewithandrea.com/articles/flutter-project-structure/
- WorkManager OEM issues: https://medium.com/@priya.prajapati/flutters-background-work-that-survives-os-sleep-ee2397a40652
- WorkManager state update challenge: https://github.com/fluttercommunity/flutter_workmanager/issues/559
- geolocator deniedForever cross-API-level: issues #880, #626 on Baseflow/flutter-geolocator
- Open-Meteo timezone bugs: issues #850, #488, #1764 on open-meteo/open-meteo
- MyWindsock (ProCyclingUK review), Epic Ride Weather (official + Play), Headwind (official), Komoot Premium (official), Windy.app cycling guide (official), cyclingweather.app (official)
- BikeRadar best cycling apps 2026: https://www.bikeradar.com/advice/buyers-guides/best-cycling-apps
- CyclingWeekly best cycling apps 2026: https://www.cyclingweekly.com/group-tests/best-cycling-apps-143222

### Tertiary (LOW confidence — validate during implementation)

- Hive TypeAdapter migration: https://github.com/isar/hive/issues/781 — community issue; mitigated by using Drift instead of Hive
- Google Calendar token refresh: googleapis.dart issue #510 — community thread; validate AutoRefreshingAuthClient behaviour in Phase 8
- Release build ProGuard / obfuscation: flutter-uae Medium post — single source; validate with `--split-debug-info` on first release build

---

*Research completed: 2026-06-01*
*Ready for roadmap: yes*
