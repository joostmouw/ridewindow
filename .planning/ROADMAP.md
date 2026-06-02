# Roadmap: RideWindow

## Overview

RideWindow builds from the inside out: a pure-Dart scoring engine with 100% unit tests, layered with a Drift + Open-Meteo data stack, wired via a Riverpod provider graph, and finally surfaced across six screens (Welcome, Onboarding, Home, Ride Detail, Profile, Availability). Background refresh, notifications, Google Calendar export, real GPS location, and Play Store packaging complete the vertical. Every phase produces a verifiable, testable artifact — nothing is deferred to "we'll sort it later".

## Phases

**Phase Numbering:**
- Integer phases (1–10): Planned milestone work
- Decimal phases (e.g., 2.1): Urgent insertions between integers

- [ ] **Phase 1: Project skeleton + scoring domain** - Flutter project + pure-Dart scoring engine with 100% unit tests
- [ ] **Phase 2: Data layer — Drift + Open-Meteo** - Drift schema, OpenMeteoClient, WeatherRepository, forecast cache
- [ ] **Phase 3: Riverpod providers + state graph** - Full provider graph with ProviderContainer tests and reactive recomputation
- [ ] **Phase 4: UI Phase A — Onboarding + Home + Welcome** - Welcome, Onboarding (4 presets), Home (week strip + ride cards)
- [ ] **Phase 5: UI Phase B — Ride Detail + Insights sheet** - Ride Detail screen + "Why this score?" insights bottom sheet
- [ ] **Phase 6: UI Phase C — Profile + Availability + Tolerance sliders** - Profile screen, availability calendar, tolerance sliders, ride-length chips
- [ ] **Phase 7: Location — GPS + manual city + permission state machine** - geolocator, permission_handler, city picker fallback
- [ ] **Phase 8: Background refresh + Notifications** - WorkManager, flutter_local_notifications, 3 notification types
- [ ] **Phase 9: Google Calendar integration** - Lazy OAuth, AutoRefreshingAuthClient, calendar.events scope
- [ ] **Phase 10: Release — Internal track only** - Signed AAB, Play App Signing, privacy policy, Data Safety form, Internal testing track

## Phase Details

### Phase 1: Project skeleton + scoring domain
**Goal**: A Flutter project exists with a pure-Dart scoring engine that is provably correct before any network, device, or UI code is written
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: SCOR-01, SCOR-02, SCOR-03, SCOR-04, SCOR-05, SLOT-01, SLOT-02, SLOT-03, SLOT-04
**Success Criteria** (what must be TRUE):
  1. `dart test` runs the full suite and all tests pass with zero Flutter or I/O imports in the domain layer
  2. `ScoringEngine.score()` returns a 0–100 overall score plus three sub-scores; documented edge cases (cold, hot, heavy rain, strong wind, mixed nulls) each have a passing unit test
  3. `SlotGenerator` produces slots of 2h, 3h, and 4–5h from a hardcoded fixture; off-by-one boundary tests pass using the exclusive `[start, end)` convention
  4. `AvailabilityFilter` removes slots overlapping a blocked-hours fixture; all four slot quality tiers (Perfect / Great / Acceptable / hidden Poor) are covered by unit tests
  5. Null weather inputs clamp to 50/100 "uncertain" rather than crash or coerce to 0; this is unit-tested explicitly
**Plans**: TBD

### Phase 2: Data layer — Drift + Open-Meteo
**Goal**: Forecast data can be fetched from Open-Meteo, stored in Drift, and served from cache — with Amsterdam hardcoded as the development location
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: FORE-01, FORE-02, FORE-03, FORE-04, FORE-05, PERS-02, PERS-03
**Success Criteria** (what must be TRUE):
  1. `OpenMeteoClient.fetch()` returns a typed `List<HourlyForecast>` for Amsterdam coordinates; all six required fields (`temperature_2m`, `apparent_temperature`, `precipitation`, `precipitation_probability`, `windspeed_10m`, `winddirection_10m`) are modeled as `double?`
  2. Every HTTP request includes `timezone=auto&timeformat=unixtime` and this is enforced at the client layer — not at each call site
  3. `WeatherRepository` returns cached data when `fetched_at` is within 1 hour and re-fetches when the cache is stale; this is verified with a unit test using a mock HTTP client
  4. A partial null response (some fields missing) does not crash or coerce to 0 — the test confirms the null is preserved through to the domain model
  5. Drift schema has a migration scaffolding comment and the append-only column convention is established before any data is written
**Plans**: TBD

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
**Plans**: TBD

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
**Plans**: TBD
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
**Requirements**: REL-01, REL-02, REL-03, REL-04, REL-05, REL-06
**Success Criteria** (what must be TRUE):
  1. A signed release AAB builds without errors using `--obfuscate --split-debug-info`; the upload keystore and passwords are backed up in a password manager
  2. The release APK is sideloaded and smoke-tested on a physical Android device — app launches, shows slots, notifications fire, Calendar export works — before any Play Console submission
  3. A privacy policy is published at a stable URL (GitHub Pages) and the URL appears both in Play Console and in the app's About screen
  4. The Data Safety form in Play Console correctly declares precise location (collected for app functionality) and Google account info (ephemerally accessed via Calendar OAuth, user-initiated only)
  5. The app is live on the Internal testing track with an opt-in link; at least one tester outside the developer has installed and opened it

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Project skeleton + scoring domain | 0/TBD | Not started | - |
| 2. Data layer — Drift + Open-Meteo | 0/TBD | Not started | - |
| 3. Riverpod providers + state graph | 0/TBD | Not started | - |
| 4. UI Phase A — Onboarding + Home + Welcome | 0/TBD | Not started | - |
| 5. UI Phase B — Ride Detail + Insights sheet | 0/TBD | Not started | - |
| 6. UI Phase C — Profile + Availability + Tolerance sliders | 0/TBD | Not started | - |
| 7. Location — GPS + manual city + permission state machine | 0/TBD | Not started | - |
| 8. Background refresh + Notifications | 0/TBD | Not started | - |
| 9. Google Calendar integration | 0/TBD | Not started | - |
| 10. Release — Internal track only | 0/TBD | Not started | - |
