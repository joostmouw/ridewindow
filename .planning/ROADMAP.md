# Roadmap: RideWindow

## Overview

RideWindow builds from the inside out: a pure-Dart scoring engine with 100% unit tests, layered with a Drift + Open-Meteo data stack, wired via a Riverpod provider graph, and finally surfaced across six screens (Welcome, Onboarding, Home, Ride Detail, Profile, Availability). v1.0 shipped this as a native Android app (Play Store, internal testing track). v2.0 ports the same Dart codebase to Flutter Web/PWA to reach iOS users without an Apple Developer account — swapping platform-coupled seams (Drift storage backend, geolocation, background refresh, Calendar OAuth) while keeping domain/UI code untouched, then hardening for iOS Safari's PWA quirks and deploying to Firebase Hosting.

## Milestones

- ✅ **v1.0 Android App** - Phases 1–10 (shipped, Internal testing track live)
- 🚧 **v2.0 iOS Web App (PWA)** - Phases 11–17 (planning)

## Phases

**Phase Numbering:**

- Integer phases: Planned milestone work, numbered continuously across milestones (never restarts)
- Decimal phases (e.g., 1.5, 11.1): Urgent insertions between integers

<details>
<summary>✅ v1.0 Android App (Phases 1–10) - SHIPPED</summary>

- [x] **Phase 1: Project skeleton + test infrastructure** - Flutter project boots, locked deps, canonical lib/ tree, structural test enforcing pure-Dart domain boundary
- [x] **Phase 1.5: Scoring domain — Freezed models + ScoringEngine + SlotGenerator** - Pure-Dart domain code with 100% unit test coverage of lib/domain/
- [x] **Phase 2: Data layer — Drift + Open-Meteo** - Drift schema, OpenMeteoClient, WeatherRepository, forecast cache
- [x] **Phase 3: Riverpod providers + state graph** - Full provider graph with ProviderContainer tests and reactive recomputation
- [x] **Phase 4: UI Phase A — Onboarding + Home + Welcome** - Welcome, Onboarding (4 presets), Home (week strip + ride cards)
- [x] **Phase 5: UI Phase B — Ride Detail + Insights sheet** - Ride Detail screen + "Why this score?" insights bottom sheet
- [x] **Phase 6: UI Phase C — Profile + Availability + Tolerance sliders** - Profile screen, availability calendar, tolerance sliders, ride-length chips
- [x] **Phase 7: Location — GPS + manual city + permission state machine** - geolocator, permission_handler, city picker fallback
- [x] **Phase 8: Background refresh + Notifications** - WorkManager, flutter_local_notifications, 3 notification types
- [x] **Phase 9: Google Calendar integration** - Lazy OAuth, AutoRefreshingAuthClient, calendar.events scope
- [x] **Phase 10: Release — Internal track only** - Signed AAB, Play App Signing, privacy policy, Data Safety form, Internal testing track

</details>

### 🚧 v2.0 iOS Web App (PWA) (In Progress)

**Milestone Goal:** Reach iOS users cheaply via a Flutter Web/PWA build of RideWindow, deployed to Firebase Hosting, without an Apple Developer account.

- [ ] **Phase 11: Web Scaffolding & Build Baseline** - `web/` platform added, `flutter build web --release` (CanvasKit) works, existing UI renders/navigates with zero domain code changes, native-only plugins guarded
- [ ] **Phase 12: Drift Web Persistence** - Drift's IndexedDB/wasm web backend wired and proven to survive page reload
- [ ] **Phase 13: Geolocation & Manual Fallback** - Browser Geolocation API wired; manual city picker promoted to primary fallback for iOS Safari's per-session re-prompting
- [ ] **Phase 14: Foreground Refresh Strategy** - On-load/on-focus/pull-to-refresh replaces WorkManager; "Last updated" label; stale-data fallback UI
- [ ] **Phase 15: Google Calendar Web Integration** - Web OAuth client ID, popup-safe sign-in, "Add to calendar" verified end-to-end on the deployed domain
- [ ] **Phase 16: PWA Installability & iOS Polish** - iOS meta tags, Add to Home Screen overlay, standalone-mode navigation, real-iPhone verification of install + storage durability
- [ ] **Phase 17: Deployment Hardening & Firebase Hosting** - `firebase.json` routing/headers, production deploy, full Android + web regression pass

## Phase Details

<details>
<summary>v1.0 Phase Details (Phases 1–10) - SHIPPED</summary>

### Phase 1: Project skeleton + test infrastructure

**Goal**: A Flutter project boots, Phase 1 dependencies resolve, canonical `lib/` tree exists, and a structural test enforces that `lib/domain/` stays pure Dart
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: SCOR-03
**Success Criteria** (what must be TRUE):

  1. `flutter --version` ≥ 3.27.0, `dart --version` ≥ 3.6.0, `dart test` proven to run on a Flutter-bootstrapped package (RESEARCH Open Question #2 resolved)
  2. `flutter pub get` resolves the locked Phase 1 dependency set with no errors and no discontinued markers
  3. The canonical `lib/{core,domain,data,features,platform}/` tree exists with `lib/domain/{models,services}/` ready for code; only Android platform is scaffolded (no `ios/`, `web/`, `linux/`, `macos/`, `windows/`)
  4. `lib/main.dart` is a minimal Material 3 boot using `ColorScheme.fromSeed` (cycling green); `dart analyze` is clean
  5. `dart test` runs both the smoke test and the structural import test (`test/structure/no_flutter_imports_test.dart`) green; the structural test demonstrably fails when a violating import is planted under `lib/domain/` (negative verification performed)

**Plans**: 3 plans complete (01-01 env+spike, 01-02 bootstrap, 01-03 structural test)
**Status**: ✅ Completed 2026-06-02

### Phase 1.5: Scoring domain — Freezed models + ScoringEngine + SlotGenerator

**Goal**: A pure-Dart scoring engine, slot generator, and availability filter live under `lib/domain/` with 100% line coverage, ready for Phase 2 data integration
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: SCOR-01, SCOR-02, SCOR-04, SCOR-05, SLOT-01, SLOT-02, SLOT-03, SLOT-04
**Success Criteria** (what must be TRUE):

  1. Freezed models exist in `lib/domain/models/` for `HourlyForecast`, `HourlyScore`, `RideSlot`, `WeatherTolerances`, and the sealed `RideTier` (`Perfect`/`Great`/`Acceptable`/`Poor`); `*.freezed.dart` and `*.g.dart` files are committed
  2. `ScoringEngine.score()` returns a 0–100 overall score plus three sub-scores (temperature, rain, wind); documented edge cases (cold, hot, heavy rain, strong wind, mixed nulls) each have a passing unit test
  3. Aggregation follows `overall = 0.6·min(t,r,w) + 0.4·mean(t,r,w)` per decision D-14; verified by fixture tests
  4. `SlotGenerator` produces slots of 2h, 3h, and 4–5h from a hardcoded forecast fixture; off-by-one boundary tests pass using the exclusive `[start, end)` convention
  5. `AvailabilityFilter` removes slots overlapping a blocked-hours fixture; all four slot quality tiers (Perfect / Great / Acceptable / hidden Poor) are covered by unit tests
  6. Null weather inputs clamp to 50/100 "uncertain" rather than crash or coerce to 0; this is unit-tested explicitly
  7. `build_runner` pipeline produces committed generated files; `dart test --coverage=coverage` shows 100% line coverage of `lib/domain/` (excluding `*.freezed.dart` / `*.g.dart`)

**Plans**: TBD

### Phase 2: Data layer — Drift + Open-Meteo

**Goal**: Forecast data can be fetched from Open-Meteo, stored in Drift, and served from cache — with Amsterdam hardcoded as the development location
**Mode:** mvp
**Depends on**: Phase 1.5
**Requirements**: FORE-01, FORE-02, FORE-03, FORE-04, FORE-05, PERS-02, PERS-03
**Success Criteria** (what must be TRUE):

  1. `OpenMeteoClient.fetch()` returns a typed `List<HourlyForecast>` for Amsterdam coordinates; all six required fields (`temperature_2m`, `apparent_temperature`, `precipitation`, `precipitation_probability`, `windspeed_10m`, `winddirection_10m`) are modeled as `double?`
  2. Every HTTP request includes `timezone=auto&timeformat=unixtime` and this is enforced at the client layer — not at each call site
  3. `WeatherRepository` returns cached data when `fetched_at` is within 1 hour and re-fetches when the cache is stale; this is verified with a unit test using a mock HTTP client
  4. A partial null response (some fields missing) does not crash or coerce to 0 — the test confirms the null is preserved through to the domain model
  5. Drift schema has a migration scaffolding comment and the append-only column convention is established before any data is written

**Plans**: 3 plans
Plans:
**Wave 1**

- [x] 02-01-PLAN.md — Drift schema + pubspec additions (tables, AppDatabase, schemaVersion=1, build_runner)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 02-02-PLAN.md — OpenMeteoClient + ForecastDao + unit tests (null preservation, URL params)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 02-03-PLAN.md — WeatherRepository cache policy + integration tests + full suite gate

### Phase 3: Riverpod providers + state graph

**Goal**: The full provider chain is wired and tested in a ProviderContainer — any change to weather data or profile triggers automatic slot recomputation without manual refresh calls
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: PROF-03, AVAIL-04, SLOT-05, PERS-01
**Success Criteria** (what must be TRUE):

  1. `WeatherNotifier` exposes `AsyncValue<List<HourlyForecast>>`; a ProviderContainer test confirms it transitions through loading → data using a mock repository
  2. `SlotsNotifier` automatically recomputes `List<RideSlot>` when either the weather provider or profile provider changes — verified with a ProviderContainer test that changes one input at a time
  3. `AvailabilityNotifier` and `ProfileNotifier` persist changes to `shared_preferences`/Drift and trigger reactive recomputation — confirmed by a test that toggles a cell and asserts slots change
  4. When no slots qualify (bad-weather or fully-blocked week), the provider exposes an explicit empty state rather than an empty list with no context
  5. Scalar user settings (tolerances, ride-length prefs, location override, notification toggles, theme) are read from `shared_preferences` on cold start and survive a `ProviderContainer` dispose/re-create cycle

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 03-01-PLAN.md — WeatherNotifier + infrastructuur-providers (appDatabase, openMeteoClient, weatherRepository)

**Wave 2** *(onafhankelijk van Wave 1 — kan parallel uitgevoerd worden)*

- [x] 03-02-PLAN.md — ProfileNotifier + shared_preferences instellingen (toleranties, rijlengte, thema, etc.)

**Wave 3** *(geblokkeerd op Wave 1 + Wave 2)*

- [x] 03-03-PLAN.md — SlotsNotifier + AvailabilityNotifier reactieve keten

**Wave 4** *(geblokkeerd op Wave 3)*

- [x] 03-04-PLAN.md — End-to-end keten-integratietest + ProviderScope in main.dart + volledige suite gate

### Phase 4: UI Phase A — Onboarding + Home + Welcome

**Goal**: A first-time user can install the app, complete onboarding with one tap to pick an availability preset, and see a ranked list of ride slots for the week on the Home screen
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: ONB-01, ONB-02, ONB-03, ONB-04
**Success Criteria** (what must be TRUE):

  1. Fresh install shows WelcomeScreen → OnboardingScreen; subsequent launches go directly to HomeScreen — confirmed by toggling the `shared_preferences` flag
  2. Onboarding presents all four preset options ("Evenings & weekends", "Mornings & weekends", "Weekends only", "Set my own schedule") and tapping any one seeds the availability grid with sensible defaults
  3. HomeScreen displays a week strip and a ranked list of ride cards (Perfect / Great / Acceptable tiers with color indicators) using Amsterdam forecast data
  4. When no slots qualify, HomeScreen displays a meaningful empty state (not a blank screen) — verified by pointing the provider at an all-bad-weather fixture
  5. All six `go_router` routes are defined and navigable; the NavigationBar switches between Home and Profile tabs without losing scroll state

**Plans**: 5 plans
Plans:
**Wave 1**

- [x] 04-01-PLAN.md — AvailabilityNotifier upgrade: Set<DateTime> → Map<DateTime, BlockType> + AvailabilityFilter aanpassing + tests update

**Wave 2** *(geblokkeerd op Wave 1)*

- [x] 04-02-PLAN.md — go_router pubspec + config.dart + LocationProvider stub + availability_presets.dart + GoRouter met onboarding redirect

**Wave 3** *(geblokkeerd op Wave 2)*

- [x] 04-03-PLAN.md — WelcomeScreen + OnboardingScreen + AvailabilityScreen stub + router echte imports

**Wave 4** *(geblokkeerd op Wave 3)*

- [x] 04-04-PLAN.md — HomeScreen (week strip + ride cards + skeleton + lege staat) + main.dart MaterialApp.router

**Wave 5** *(geblokkeerd op Wave 4)*

- [x] 04-05-PLAN.md — Widget tests: WelcomeScreen, OnboardingScreen, HomeScreen (loading/data/leeg)

**UI hint**: yes

### Phase 5: UI Phase B — Ride Detail + Insights sheet

**Goal**: A user can tap any ride card and see a full breakdown of the slot — including hourly weather, feels-like temperature, and a score explanation with three progress bars
**Mode:** mvp
**Depends on**: Phase 4
**Requirements**: (UI delivery of Phase 1–3 domain and data requirements — no new REQ-IDs)
**Success Criteria** (what must be TRUE):

  1. Tapping a ride card navigates to RideDetailScreen showing the slot's start/end time, overall score, and a score badge matching the Home card
  2. The detail screen shows an hourly breakdown table covering every hour in the slot, including feels-like temperature (`apparent_temperature`) alongside actual temperature
  3. Tapping the "Why this score?" trigger opens the InsightsSheet as a bottom sheet with three `LinearProgressIndicator` bars (temp, rain, wind) and a one-line explanation per factor
  4. Each progress bar in the InsightsSheet reflects the actual sub-score values from `ScoringEngine` — confirmed by matching against a known fixture

**Plans**: TBD
**UI hint**: yes

### Phase 6: UI Phase C — Profile + Availability + Tolerance sliders

**Goal**: A user can fully personalize the app — adjusting tolerance sliders, selecting ride lengths, editing the weekly availability calendar — and see slots on Home update immediately after saving
**Mode:** mvp
**Depends on**: Phase 5
**Requirements**: PROF-01, PROF-02, PROF-04, AVAIL-01, AVAIL-02, AVAIL-03
**Success Criteria** (what must be TRUE):

  1. ProfileScreen shows three tolerance sliders (temperature, rain, wind) and moving any slider causes slot scores on Home to recompute within the same session
  2. Ride length chips (2h / 3h / 4–5h) can be toggled; at least one must remain selected — tapping the last active chip has no effect
  3. AvailabilityScreen shows a 7-day × 24-hour grid where each cell displays one of three states (free / blocked / work); tapping a cell toggles it and the change persists immediately to Drift
  4. After editing availability and returning to Home, the slot list reflects the updated blocked hours without requiring a manual refresh
  5. Material 3 light/dark theme preference (system default acceptable) is accessible from ProfileScreen and the app responds to the selection immediately

**Plans**: TBD
**UI hint**: yes

### Phase 7: Location — GPS + manual city + permission state machine

**Goal**: The app uses the device's GPS location for forecasts, with a fully functional city picker fallback for the denied and travel cases
**Mode:** mvp
**Depends on**: Phase 6
**Requirements**: LOC-01, LOC-02, LOC-03, LOC-04, LOC-05
**Success Criteria** (what must be TRUE):

  1. On first run, the app requests location permission via `permission_handler`; if granted, GPS coordinates are used for the Open-Meteo forecast request
  2. If GPS is granted, the Home screen shows forecast data for the device's actual location — not Amsterdam hardcoded
  3. User can open a city picker from ProfileScreen and select from a curated list of NL cities; the chosen city is stored in `shared_preferences` and overrides GPS until cleared
  4. If location permission is permanently denied, the app detects this, shows a clear explanation, offers a deep-link to app settings, and automatically falls back to the city picker as the primary location source
  5. A manually set location override persists across app restarts and takes precedence over GPS until the user explicitly clears it

**Plans**: TBD

### Phase 8: Background refresh + Notifications

**Goal**: The app refreshes weather data in the background and can send three types of opt-in notifications — without requiring the user to open the app
**Mode:** mvp
**Depends on**: Phase 7
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05, NOTIF-06
**Success Criteria** (what must be TRUE):

  1. WorkManager periodic task runs with a 3–6h interval; on foreground resume the app re-reads Drift and `lastRefreshed` timestamp updates in the UI
  2. User can independently toggle "Evening before" (19:00 prior day), "Morning of" (slot start −2h), and "Weekly digest" (Sunday 19:00) notifications from ProfileScreen
  3. Each enabled notification fires at the correct scheduled time — verified on a physical device for at least "Evening before"
  4. App requests Android 13+ `POST_NOTIFICATIONS` permission via the standard runtime prompt before scheduling any notification
  5. App requests Android 12+ `SCHEDULE_EXACT_ALARM` via system settings deep-link and falls back to inexact scheduling with a user-visible note if denied

**Plans**: TBD

### Phase 9: Google Calendar integration

**Goal**: A user can tap "Add to calendar" on any ride slot and create a Google Calendar event without having had to sign in before that moment
**Mode:** mvp
**Depends on**: Phase 8
**Requirements**: CAL-01, CAL-02, CAL-03, CAL-04, CAL-05, PERS-04
**Success Criteria** (what must be TRUE):

  1. The "Add to calendar" button appears on the Ride Detail screen and the app is fully functional without ever tapping it — Calendar is visibly optional
  2. Tapping "Add to calendar" for the first time triggers the Google OAuth flow requesting only the `calendar.events` scope; subsequent taps within the session skip sign-in
  3. The created Google Calendar event contains the correct start time, end time, and a one-line weather summary as the event description
  4. `AutoRefreshingAuthClient` handles token expiry silently — no sign-in prompt appears mid-session after a previously successful authentication
  5. No personal data leaves the device unless the user explicitly completes the Google Sign-In flow — confirmed by verifying no Calendar API calls are made on app start

**Plans**: TBD

### Phase 10: Release — Internal track only

**Goal**: A signed release AAB is uploaded to the Play Console Internal testing track and 10–20 cyclist friends can install it via opt-in link
**Mode:** mvp
**Depends on**: Phase 9
**Requirements**: REL-2201, REL-02, REL-03, REL-04, REL-05, REL-06
**Success Criteria** (what must be TRUE):

  1. A signed release AAB builds without errors using `--obfuscate --split-debug-info`; the upload keystore and passwords are backed up in a password manager
  2. The release APK is sideloaded and smoke-tested on a physical Android device — app launches, shows slots, notifications fire, Calendar export works — before any Play Console submission
  3. A privacy policy is published at a stable URL (GitHub Pages) and the URL appears both in Play Console and in the app's About screen
  4. The Data Safety form in Play Console correctly declares precise location (collected for app functionality) and Google account info (ephemerally accessed via Calendar OAuth, user-initiated only)
  5. The app is live on the Internal testing track with an opt-in link; at least one tester outside the developer has installed and opened it

**Plans**: TBD

</details>

### Phase 11: Web Scaffolding & Build Baseline

**Goal**: The existing Android app also builds and runs as a Flutter Web app in a browser, using the CanvasKit renderer, with zero domain/UI code changes and native-only plugins safely guarded
**Mode:** mvp
**Depends on**: Phase 10 (v1.0 shipped; this milestone builds on the same codebase)
**Requirements**: WEB-01, WEB-02, WEB-03, WEB-04, WEB-05
**Success Criteria** (what must be TRUE):

  1. `flutter create --platforms web .` has been run; a `web/` directory exists and is committed
  2. `flutter build web --release` (CanvasKit renderer, not `--wasm`) completes with zero errors
  3. Running the app in a desktop browser navigates through all six existing screens (Welcome, Onboarding, Home, Ride Detail, Profile, Availability) via `go_router` with no code changes to domain/UI layers
  4. `workmanager` and `home_widget` call sites in `main.dart` are guarded with `kIsWeb` checks so the web build neither crashes nor attempts to register native-only background tasks
  5. `flutter build apk` still succeeds and the existing Android app runs unchanged after these additions (regression check)

**Plans**: 1 plan
Plans:

**Wave 1**

- [x] 11-01-PLAN.md — Web platform scaffold + kIsWeb guards + build/render/regression verification
**UI hint**: yes

### Phase 12: Drift Web Persistence

**Goal**: User data (profile, availability, tolerances, settings) reliably persists in the browser across page reloads, on the same Drift schema used natively
**Mode:** mvp
**Depends on**: Phase 11
**Requirements**: PERS-05, PERS-06, PERS-07
**Success Criteria** (what must be TRUE):

  1. `AppDatabase` opens successfully on web via `DriftWebOptions` (`sqlite3.wasm` + `drift_worker.dart.js`), alongside the existing native `DriftNativeOptions` on Android
  2. A user can write data (e.g., toggle an availability cell) in the browser, do a full page reload, and see the same data still present — manually verified in a real browser, not just assumed from a successful build
  3. `sqlite3.wasm` is served with `Content-Type: application/wasm` from the deployed Firebase Hosting domain (explicit `firebase.json` header rule if needed), confirmed via browser network inspector
  4. The existing Android app's Drift-backed data and behavior continue to work unchanged (regression check)

**Plans:** 1/1 plans complete

Plans:
- [x] 12-01-PLAN.md — Wire DriftWebOptions + version-matched sqlite3.wasm/drift_worker.dart.js, manually verify write-then-reload persistence in a real browser

### Phase 13: Geolocation & Manual Fallback

**Goal**: Web users get their forecast for their real location via the browser Geolocation API, with the manual city picker promoted to an equally prominent, load-bearing path when permission is denied or times out
**Mode:** mvp
**Depends on**: Phase 12
**Requirements**: LOC-06, LOC-07
**Success Criteria** (what must be TRUE):

  1. On the deployed HTTPS Firebase Hosting domain, granting browser location permission produces a forecast for the user's real coordinates — verified in a desktop browser and manually on a real iPhone in Safari
  2. Denying or timing out the geolocation prompt on web immediately surfaces the manual city picker as the primary path, not a buried fallback — reflecting iOS Safari's per-session re-prompt behavior (no "Always Allow")
  3. Web-unsupported `geolocator` methods (`getLastKnownPosition`, `openAppSettings`) are guarded and do not throw uncaught errors on web
  4. The existing Android GPS + city picker flow continues to work unchanged (regression check)

**Plans**: 1 plan
Plans:

**Wave 1**

- [x] 13-01-PLAN.md — Web seam + guard openSettings() + promote city picker as primary web fallback + manual browser verification

### Phase 14: Foreground Refresh Strategy

**Goal**: Web users see fresh (or clearly-labeled stale) weather data without any background task, driven entirely by page load, regained focus, and manual pull-to-refresh
**Mode:** mvp
**Depends on**: Phase 13
**Requirements**: REFRESH-01, REFRESH-02, REFRESH-03, REFRESH-04
**Success Criteria** (what must be TRUE):

  1. Loading the web app, or returning to its browser tab after being away, automatically triggers a fresh weather fetch (`ref.invalidate(weatherProvider)`) — verified via network inspector and a changing "Last updated" timestamp
  2. A user can manually pull-to-refresh on the Home screen to force a re-fetch of weather data
  3. The UI displays a "Last updated HH:MM" label at all times, reflecting the cache-then-network pattern
  4. Going offline, or a failed fetch, shows the last-known slots clearly labeled as stale rather than a blank screen or crash

**Plans**: 1 plan
Plans:

**Wave 1**

- [x] 14-01-PLAN.md — Web-gated resume-refresh trigger + always-visible last-updated label + stale-data fallback UI + manual browser verification
**UI hint**: yes

### Phase 15: Google Calendar Web Integration

**Goal**: Web users can add a ride slot to Google Calendar directly from the deployed app, with sign-in surviving Safari's popup blocker and FedCM incompatibility
**Mode:** mvp
**Depends on**: Phase 14
**Requirements**: CAL-06, CAL-07
**Success Criteria** (what must be TRUE):

  1. `CalendarService` initializes with a platform-conditional web OAuth `clientId` configured in Google Cloud Console for the Firebase Hosting domain; native Android config is unchanged
  2. Tapping "Add to calendar" on the deployed production URL (not localhost) opens the Google sign-in popup synchronously inside the tap handler (not blocked by Safari) and completes the OAuth consent flow
  3. A real Google Calendar event is created with the correct start/end time and weather summary, verified end-to-end in a real browser against the deployed production domain
  4. The full flow is manually verified on a real iPhone in Safari (not just desktop Chrome), given LOW research confidence on iOS popup/FedCM behavior for `google_sign_in` 7.x web

**Plans**: 2 plans
Plans:

**Wave 1**

- [x] 15-01-PLAN.md — Web OAuth warmup wiring (kIsWeb-gated eager GoogleSignIn init) + Web OAuth client ID meta tag + Chrome dev-server (localhost) spike verification

**Wave 2** *(blocked on Wave 1 -- needs the Web OAuth client from 15-01 Task 1)*

- [x] 15-02-PLAN.md — Preliminary Firebase Hosting deploy + production-domain OAuth origin + real iPhone Safari verification

### Phase 16: PWA Installability & iOS Polish

**Goal**: iOS users can add RideWindow to their Home Screen and use it as a standalone app with correct icons, splash, safe-area layout, and navigation — and their data durably survives Safari's storage eviction policy
**Mode:** mvp
**Depends on**: Phase 15
**Requirements**: PWA-01, PWA-02, PWA-03, PWA-04, PWA-05
**Success Criteria** (what must be TRUE):

  1. `web/index.html` includes `apple-touch-icon`, `apple-touch-startup-image`, `theme_color`, and `background_color` tags; the app shows a correct icon and splash screen when added to an iPhone Home Screen
  2. In standalone mode (added to Home Screen), the app displays with no browser chrome (`display: standalone`), correct status bar styling, and content respects notch/Dynamic Island safe areas (`env(safe-area-inset-*)`)
  3. On iOS Safari in browser mode (not yet installed), a custom "Add to Home Screen" instructional overlay appears, detected via the `display-mode: standalone` media query and hidden once installed; Android Chrome instead uses its native `beforeinstallprompt` flow
  4. In standalone mode, in-app back/close navigation works correctly with no dead ends (no reliance on a browser back button that doesn't exist)
  5. The install flow and storage persistence are manually verified on a real iPhone in Safari — including leaving the installed app untouched for several days to confirm whether data survives ITP storage eviction (per research Gap: exemption for installed PWAs is unconfirmed)

**Plans**: 4 plans
Plans:

**Wave 1**

- [ ] 16-01-PLAN.md — Branded icon/splash assets (photos/main app logo real.png) + manifest.json/index.html meta tags + viewport-fit=cover (PWA-01, PWA-02)
- [ ] 16-02-PLAN.md — Display-mode/iOS detection seam + persistent "Add to Home Screen" overlay (PWA-03)
- [ ] 16-03-PLAN.md — SafeBackButton: fix standalone-mode navigation dead ends (PWA-04)

**Wave 2** *(blocked on Wave 1)*

- [ ] 16-04-PLAN.md — Deploy + real iPhone Safari verification: install, standalone nav, safe-area, storage durability (PWA-05)
**UI hint**: yes

### Phase 17: Deployment Hardening & Firebase Hosting

**Goal**: The web app is live at a stable, production HTTPS URL on Firebase Hosting with correct routing and asset headers, and the Android app remains fully unaffected by all web-platform additions
**Mode:** mvp
**Depends on**: Phase 16
**Requirements**: DEPLOY-01, DEPLOY-02, DEPLOY-03
**Success Criteria** (what must be TRUE):

  1. `firebase.json` configures `build/web` as the Hosting public directory with rewrite rules so client-side `go_router` routes work correctly on direct URL load and page refresh (no 404s)
  2. `firebase deploy` succeeds and the app is reachable at a stable HTTPS URL, with all features exercised across Phases 11–16 (build, persistence, geolocation, refresh, Calendar, PWA install) working on that live URL
  3. A full regression pass confirms `flutter build apk` still builds and the existing Android app's core flows (forecast, slots, availability, Calendar) work unchanged

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 1.5 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Project skeleton + test infrastructure | v1.0 | 3/3 | Complete | 2026-06-02 |
| 1.5. Scoring domain — Freezed models + ScoringEngine + SlotGenerator | v1.0 | 0/TBD | Not started | - |
| 2. Data layer — Drift + Open-Meteo | v1.0 | 3/3 | Complete | 2026-06-02 |
| 3. Riverpod providers + state graph | v1.0 | 4/4 | Complete | 2026-06-03 |
| 4. UI Phase A — Onboarding + Home + Welcome | v1.0 | 0/5 | Not started | - |
| 5. UI Phase B — Ride Detail + Insights sheet | v1.0 | 0/TBD | Not started | - |
| 6. UI Phase C — Profile + Availability + Tolerance sliders | v1.0 | 0/TBD | Not started | - |
| 7. Location — GPS + manual city + permission state machine | v1.0 | 0/TBD | Not started | - |
| 8. Background refresh + Notifications | v1.0 | 0/TBD | Not started | - |
| 9. Google Calendar integration | v1.0 | 0/TBD | Not started | - |
| 10. Release — Internal track only | v1.0 | 0/TBD | Not started | - |
| 11. Web Scaffolding & Build Baseline | v2.0 | 1/1 | Complete   | 2026-07-11 |
| 12. Drift Web Persistence | v2.0 | 1/1 | Complete   | 2026-07-11 |
| 13. Geolocation & Manual Fallback | v2.0 | 1/1 | Complete   | 2026-07-11 |
| 14. Foreground Refresh Strategy | v2.0 | 1/1 | Complete   | 2026-07-12 |
| 15. Google Calendar Web Integration | v2.0 | 2/2 | Complete    | 2026-07-14 |
| 16. PWA Installability & iOS Polish | v2.0 | 0/4 | Not started | - |
| 17. Deployment Hardening & Firebase Hosting | v2.0 | 0/TBD | Not started | - |

**Note:** The v1.0 progress table rows above (Phases 1, 2, 3 marked Complete; others Not started) reflect the state carried over from the v1.0 STATE.md snapshot at milestone transition — see `git log` / `.planning/STATE.md` Accumulated Context for actual v1.0 completion history (all of Phases 1–10 shipped to the Internal testing track).
