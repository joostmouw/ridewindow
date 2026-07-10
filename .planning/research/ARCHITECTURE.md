# Architecture Research

**Domain:** Flutter Web/PWA integration for an existing Android Flutter app (RideWindow v2.0)
**Researched:** 2026-07-10
**Confidence:** MEDIUM-HIGH (package platform support verified against pub.dev/official docs; exact web-auth behavior for `google_sign_in` 7.x scope-authorization flagged LOW and needs phase-specific validation)

## Standard Architecture

### System Overview

RideWindow's existing layering (domain → data → providers → UI) is **already well-suited to adding a web target** because platform-specific code was pushed to the edges (`lib/data/database`, `lib/platform`, `lib/services`, and the handful of `lib/providers/*_notifier.dart` files that call geolocator/permission_handler/google_sign_in) rather than leaking into `lib/domain` or `lib/features`. The work is almost entirely about **swapping/gating implementations at existing seams**, not restructuring layers.

```
┌───────────────────────────────────────────────────────────────────────┐
│  UI (lib/features/*, lib/app/*)                — NO CHANGES for web   │
├───────────────────────────────────────────────────────────────────────┤
│  Providers (lib/providers/*_notifier.dart)                             │
│  ┌───────────────┐ ┌────────────────┐ ┌──────────────┐ ┌────────────┐ │
│  │ WeatherNotifier│ │ProfileNotifier │ │Availability  │ │SlotsNotifier│ │
│  │ (no change)   │ │(no change)      │ │Notifier      │ │(no change)  │ │
│  └───────┬───────┘ └────────────────┘ │(no change)   │ └────────────┘ │
│  ┌───────┴───────┐ ┌────────────────┐ └──────────────┘                │
│  │LocationNotifier│ │GpsPermission   │  ← geolocator/permission_handler│
│  │(transparent   │ │Notifier         │    branch INSIDE these two only │
│  │ via federated │ │(openSettings()  │                                 │
│  │ web plugin)   │ │ needs kIsWeb    │                                 │
│  └───────────────┘ │ guard)          │                                 │
│                     └────────────────┘                                 │
├───────────────────────────────────────────────────────────────────────┤
│  Data / Platform Layer  — THIS is where web branching concentrates     │
│  ┌─────────────────┐ ┌────────────────────┐ ┌─────────────────────┐   │
│  │ AppDatabase      │ │ CalendarService    │ │ background_task.dart │   │
│  │ (Drift)          │ │ (google_sign_in +  │ │ (WorkManager isolate)│   │
│  │ needs web:       │ │  googleapis)       │ │ NEVER runs on web —  │   │
│  │ DriftWebOptions  │ │ needs clientId      │ │ guarded at call site │   │
│  │ + sqlite3.wasm + │ │ passed conditionally│ │ in main.dart, file   │   │
│  │ drift_worker.js  │ │ at initialize()     │ │ itself untouched     │   │
│  └─────────────────┘ └────────────────────┘ └─────────────────────┘   │
│  ┌─────────────────┐ ┌────────────────────┐                            │
│  │ shared_preferences│ │ home_widget        │                          │
│  │ — already fully  │ │ (Android-only,      │                          │
│  │ cross-platform,  │ │ MissingPluginException│                        │
│  │ NO CHANGES       │ │ on web — guard call │                          │
│  │ needed           │ │ sites with kIsWeb)  │                          │
│  └─────────────────┘ └────────────────────┘                            │
├───────────────────────────────────────────────────────────────────────┤
│  NEW for web only: web/ directory (index.html, manifest.json,          │
│  sqlite3.wasm, drift_worker.dart.js, service worker/PWA install)        │
└───────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Web-specific handling |
|-----------|----------------|------------------------|
| `lib/data/database/app_database.dart` | Owns Drift `_openConnection()` | Add `web: DriftWebOptions(...)` alongside existing `native:` param — single function already supports both via `drift_flutter`'s internal conditional imports |
| `lib/platform/background_task.dart` | WorkManager isolate callback (weather refresh) | Entire file is dead code on web — never registered, never imported into a web-reachable path. No internal `kIsWeb` branching needed inside the file itself |
| `main.dart` | App bootstrap: timezone init, WorkManager registration, ProviderScope | `if (!kIsWeb) { await Workmanager()... }` guard around WorkManager init/registration; the `ref.listen(slotsProvider, ...) → WidgetUpdateService.update()` call needs a `kIsWeb` guard too |
| `lib/providers/location_provider.dart` (`LocationNotifier`) | Resolve lat/lon from override → GPS → default | No code change required — `geolocator_web` federated plugin makes `Geolocator.getCurrentPosition()` work transparently via the browser Geolocation API (requires HTTPS/secure context, which Firebase Hosting provides) |
| `lib/providers/gps_permission_notifier.dart` (`GpsPermissionNotifier`) | GPS permission state machine | `openSettings()` (deep-links to OS app settings via `permission_handler`) has no web equivalent — must be gated with `kIsWeb` and replaced with an in-app message ("enable location in your browser's site settings") |
| `lib/services/calendar_service.dart` (`CalendarService`) | Google Calendar OAuth + event CRUD | `google_sign_in` 7.x is cross-platform via `google_sign_in_web`, but `initialize()` needs a platform-conditional `clientId`/`serverClientId` (web OAuth client ID vs Android's `google-services.json`-derived config). `authorizeScopes()` / `authClient()` are expected to work unchanged, but this is the single LOW-confidence item in this research — validate early |
| `lib/services/widget_update_service.dart` | Pushes next-slot data to Android home screen widget via `home_widget` | Android-only feature; package has no web implementation → guard every call site with `kIsWeb`, do not attempt a web equivalent (out of scope) |
| `lib/providers/profile_notifier.dart`, `availability_notifier.dart` | SharedPreferences-backed settings/availability grid | Zero changes — `shared_preferences` has a mature, fully-supported `shared_preferences_web` implementation (backed by `window.localStorage`) |
| `lib/domain/services/*` (ScoringEngine, SlotGenerator, AvailabilityFilter) | Pure Dart business logic | Zero changes — no Flutter/platform imports exist here today; this is the strongest evidence the architecture already isolates domain logic correctly |

## Recommended Project Structure

```
ridewindow/
├── web/                          # NEW — created via `flutter create --platforms web .`
│   ├── index.html                # add Google Identity Services script/meta if needed for GIS
│   ├── manifest.json              # PWA manifest — name, icons, theme_color, display: standalone
│   ├── favicon.png, icons/         # PWA icon set (192, 512, maskable variants)
│   ├── sqlite3.wasm                # NEW — copied from `sqlite3` package release, drift's wasm backend
│   └── drift_worker.dart.js        # NEW — generated by drift_dev / bundled drift web worker
├── lib/
│   ├── data/database/app_database.dart   # MODIFIED — add DriftWebOptions
│   ├── platform/background_task.dart     # UNCHANGED — simply never invoked on web
│   ├── providers/gps_permission_notifier.dart  # MODIFIED — kIsWeb guard on openSettings()
│   ├── services/calendar_service.dart    # MODIFIED — conditional clientId at initialize()
│   ├── services/widget_update_service.dart  # UNCHANGED (call sites gated instead)
│   └── main.dart                          # MODIFIED — kIsWeb guards around WorkManager + widget update
```

### Structure Rationale

- **`web/` is entirely new** — this project has never run `flutter create --platforms web .`. That command must be run first; it scaffolds `index.html`, `manifest.json`, icons, and default service worker registration. Do not hand-write these from scratch.
- **No new `lib/` folders needed.** The existing `lib/data`, `lib/platform`, `lib/providers`, `lib/services` split already puts every platform-coupled call behind a narrow interface (`AppDatabase`, `CalendarService`, `LocationNotifier`, `WidgetUpdateService`). Web support is additive configuration inside these files plus `kIsWeb` guards at 2-3 call sites — not a new abstraction layer.
- **No conditional-import (`dart:io` vs `dart:html`) files are required.** Every package in the current dependency list (`drift_flutter`, `geolocator`, `google_sign_in`, `shared_preferences`, `flutter_timezone`) already ships its own federated web implementation that resolves automatically via Flutter's plugin registration — the app code calls the same API on every platform. `kIsWeb` runtime checks (not conditional imports) are the correct pattern here because the branching is about *whether to call a package at all* (WorkManager, home_widget — no web implementation exists), not about *which implementation of the same API to use*.

## Architectural Patterns

### Pattern 1: `kIsWeb` guard at the call site, not inside the platform module

**What:** For packages with **no web implementation at all** (`workmanager`, `home_widget`), wrap every call in `if (!kIsWeb) { ... }` at the point of invocation (`main.dart`), rather than pushing `kIsWeb` checks down into `background_task.dart` or `widget_update_service.dart`.
**When to use:** When a package throws (`MissingPluginException`) or simply doesn't exist for web — there is no "web behavior" to implement, only "don't call this."
**Trade-offs:** Keeps `background_task.dart` and `widget_update_service.dart` unmodified and Android-only in effect; the guard lives where the decision to run background/widget code is made, which is `main.dart`'s bootstrap sequence and the `RideWindowApp.build()` listener — both single locations.

**Example:**
```dart
// main.dart
if (!kIsWeb) {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    kWeatherRefreshTaskTag,
    kWeatherRefreshTaskName,
    frequency: const Duration(hours: 3),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
```

### Pattern 2: Same-API cross-platform packages need config, not code branches

**What:** `drift_flutter`'s `driftDatabase()`, `geolocator`'s `Geolocator.getCurrentPosition()`, and `shared_preferences`'s `SharedPreferences.getInstance()` are single functions that already dispatch to the right platform backend internally. The only work needed is supplying the web-specific *configuration* (`DriftWebOptions`, OAuth `clientId`) — not writing `if (kIsWeb)` around the call.
**When to use:** Whenever a dependency lists a `_web` federated implementation on pub.dev (verify per-package, don't assume).
**Trade-offs:** Much less code to maintain than manual conditional imports, but failures are configuration-shaped (missing wasm file, missing OAuth client ID, missing HTTPS) rather than compile-time-shaped — these bugs only surface when actually running `flutter build web` / deploying, so this must be tested on web early, not assumed from reading the API.

**Example:**
```dart
// lib/data/database/app_database.dart
static QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'ridewindow',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
```

### Pattern 3: Background refresh becomes a foreground trigger, not a platform branch inside `SlotsNotifier`/`WeatherNotifier`

**What:** Because `WorkManager` has no web equivalent, "background weather refresh" on web is replaced by a **new, small provider** (e.g. a lifecycle-aware refresh trigger inside `RideWindowApp` or a dedicated `WebRefreshNotifier`) that calls `ref.invalidate(weatherProvider)` when the app resumes from background/gains focus, and optionally on a `Timer.periodic` while the tab stays open. This is additive — it does not touch `WeatherNotifier`, `SlotsNotifier`, or any domain code, because those already react correctly to invalidation (Riverpod's dependency graph re-runs `SlotsNotifier` automatically once `weatherProvider` refreshes).
**When to use:** Any time a background task needs a foreground-only substitute on web.
**Trade-offs:** Refresh only happens while/when the PWA is open (acceptable per the milestone's explicit scope — "on-foreground/on-load refresh" is the accepted tradeoff, already captured in PROJECT.md).

## Data Flow

### Weather Refresh Flow (native vs web)

```
Native (Android):
WorkManager isolate (every 3h, background)
   → background_task.dart: own AppDatabase + http.Client
   → writes ForecastCacheEntries via ForecastDao
   → foreground WeatherNotifier reads from same Drift DB on next app open

Web (new):
App resumed / tab focused / page loaded
   → NEW: kIsWeb-gated trigger (app lifecycle listener or on-init)
   → ref.invalidate(weatherProvider) — same WeatherNotifier.build() runs
   → WeatherRepository.getForecast() → OpenMeteoClient.fetch() → Drift write
   → SlotsNotifier recomputes automatically (unchanged reactive graph)
```

### Google Calendar Auth Flow (native vs web)

```
Native (Android):
User taps "Add to calendar"
   → CalendarService._ensureInitialized() → GoogleSignIn.instance.initialize()
     (uses google-services.json client config, no explicit clientId needed)
   → authorizationClient.authorizeScopes([calendarEventsScope]) → native OAuth consent UI
   → authClient() → CalendarApi(client).events.insert(...)

Web (modified):
User taps "Add to calendar"
   → CalendarService._ensureInitialized() → GoogleSignIn.instance.initialize(
       clientId: webOAuthClientId,       // NEW — required on web, from Google Cloud Console
     )
   → authorizationClient.authorizeScopes([calendarEventsScope]) → GIS popup/redirect consent
   → authClient() → CalendarApi(client).events.insert(...)   (same code path)
```

### Availability Grid / Profile Flow (no change)

`ProfileNotifier`, `AvailabilityNotifier` read/write `shared_preferences` exactly as today. `shared_preferences_web` persists to `window.localStorage`, which — unlike Drift's IndexedDB backend — is not subject to the same storage-eviction risk profile; it can still be cleared by "Clear browsing data," but there's no separate wasm/worker setup to break.

### Key Data Flows

1. **Weather cache persistence risk on Safari/iOS PWA:** Drift's web backend prefers OPFS (needs COOP/COEP headers for full benefit, works without them at reduced performance) and falls back to IndexedDB. iOS Safari is known to evict IndexedDB/site data after extended website inactivity in non-installed contexts; an **installed PWA (added to home screen)** is treated more leniently by iOS's storage eviction policy than a regular Safari tab. This is a real risk flagged already in PROJECT.md — recommend surfacing "Add to Home Screen" during onboarding on iOS Safari specifically, and treating full cache loss as a normal, low-cost event (re-fetch from Open-Meteo, not data the user would mourn).
2. **First paint before Drift is ready:** on web, the wasm module + worker must download before the Drift connection resolves. This is asynchronous the same way native Drift is (already `Future`-based via Riverpod's `AsyncNotifier`), so the loading state UI (already built for native cold start) should carry over unchanged — but initial load may be slower on web due to wasm download, worth measuring against the "2s cold start" performance constraint in CLAUDE.md.

## Scaling Considerations

Not applicable in the traditional user-count sense (no backend, no shared infra) — reframed as **platform-maturity considerations**:

| Stage | Web-specific concern |
|-------|----------------------|
| First `flutter build web` render | No storage/auth wired yet — verify UI, theming, go_router paths, and Riverpod providers that don't touch platform packages render correctly |
| Wiring Drift on web | Verify `sqlite3.wasm` Content-Type is `application/wasm` on Firebase Hosting (may need a `firebase.json` header rule) |
| Wiring Calendar auth on web | Verify Authorized JavaScript origins in Google Cloud Console include the Firebase Hosting domain; verify popup-blocker behavior since `authorizeScopes()` on web typically opens a popup |
| Post-launch (PWA installed) | Monitor for storage-eviction complaints on iOS Safari; this is the top known risk per PROJECT.md and should have a research/validation checkpoint of its own, not just be assumed fine |

### Scaling Priorities

1. **First bottleneck:** Drift web setup (wasm + worker + COOP/COEP headers) is the most likely thing to silently fail or degrade to in-memory-only storage without an error — must be explicitly tested (write data, reload page, confirm persistence) rather than assumed from a successful `flutter build web`.
2. **Second bottleneck:** Google Calendar OAuth on web is the most likely thing to require back-and-forth with Google Cloud Console (authorized origins, consent screen verification status, testing-mode user allowlist) — budget calendar-integration time generously and start it early enough to hit console configuration issues before the milestone deadline.

## Anti-Patterns

### Anti-Pattern 1: Pushing `kIsWeb` checks into domain or provider logic

**What people do:** Add `if (kIsWeb) { ... } else { ... }` branches inside `ScoringEngine`, `SlotGenerator`, `WeatherNotifier`, or `SlotsNotifier` "just in case."
**Why it's wrong:** These layers have zero platform dependency today — that's why they're trivially testable and reusable across Android/web. Introducing `kIsWeb` here re-couples domain logic to platform and defeats the entire reason the architecture was built this way.
**Instead:** Keep all platform branching in `lib/data`, `lib/platform`, `lib/services`, and the 2-3 specific provider files that directly wrap platform packages (`LocationNotifier`, `GpsPermissionNotifier`). Everything downstream of `WeatherNotifier`/`AvailabilityNotifier`/`ProfileNotifier` should never need to know it's running on web.

### Anti-Pattern 2: Assuming a package "supports web" because pub.dev lists the platform badge

**What people do:** See a green "Web" badge on pub.dev and assume full parity with mobile behavior (e.g., assuming `Geolocator.requestPermission()` shows a permission dialog on web the same way it does on Android, or assuming `permission_handler`'s `openAppSettings()` works everywhere).
**Why it's wrong:** Web badges mean "compiles and has some implementation," not "identical UX." Concretely: web browsers auto-prompt for location permission the first time `getCurrentPosition()`/`getPositionStream()` is called rather than via an explicit separate "request" step; `permission_handler`'s web implementation only supports a subset of permissions and has no equivalent to opening OS app settings.
**Instead:** For every platform package the app uses beyond `drift_flutter`/`shared_preferences`, explicitly test the actual web behavior of each call during the phase that wires it up, and add narrow `kIsWeb` UX adjustments (e.g., a different copy string for "enable location" on web vs. a settings deep-link on Android) rather than assuming code reuse implies behavior reuse.

## Integration Points

### External Services / Platform Packages

| Package | Web support | Integration pattern | Notes |
|---------|-------------|----------------------|-------|
| `drift` + `drift_flutter` | Yes (federated, via `sqlite3.wasm` + worker) | Add `web: DriftWebOptions(sqlite3Wasm: ..., driftWorker: ...)` to existing `driftDatabase()` call in `app_database.dart` | Requires `sqlite3.wasm` + `drift_worker.dart.js` in `web/`; version-match against `pubspec.lock`; serve wasm with `Content-Type: application/wasm` (Firebase Hosting header rule may be needed) |
| `shared_preferences` | Yes (mature, `shared_preferences_web` uses `localStorage`) | No change | Zero risk item |
| `geolocator` | Yes (`geolocator_web`, uses browser Geolocation API) | No code change; behavior differs (auto-prompt on first `getCurrentPosition()` call, requires HTTPS/secure context) | Firebase Hosting is HTTPS by default — satisfies secure-context requirement |
| `permission_handler` | Partial (`permission_handler_html`, limited permission set, no `openAppSettings()` equivalent) | `kIsWeb` guard in `GpsPermissionNotifier.openSettings()` | Only touch point in the codebase is the deep-link-to-settings call; the location-permission state machine itself uses `geolocator`'s own permission API, not `permission_handler` directly |
| `google_sign_in` + `extension_google_sign_in_as_googleapis_auth` + `googleapis` | Yes (`google_sign_in_web`, GIS-based) | Pass a platform-conditional `clientId`/`serverClientId` to `GoogleSignIn.instance.initialize()`; requires a Web OAuth client ID configured in Google Cloud Console with Firebase Hosting domain as an authorized JavaScript origin | LOW confidence on exact `authorizeScopes()`/`authClient()` web behavior (popup vs redirect, scope-authorization-only vs full sign-in) — validate early in the Calendar-integration phase |
| `workmanager` | No | `kIsWeb` guard around init/registration in `main.dart`; leave `background_task.dart` untouched (never imported into a web-only path) | Confirmed no web implementation exists (long-standing open feature request, unresolved) |
| `home_widget` | No | `kIsWeb` guard at call sites (`main.dart` listener, any other invocation) | Android/iOS-native-widget-only package; calling on web throws `MissingPluginException` |
| `flutter_local_notifications` + `timezone` + `flutter_timezone` | Out of scope for v2.0 web (notifications explicitly deferred per PROJECT.md) | N/A this milestone | `flutter_timezone` itself does have web support (fetches timezone via `Intl` under the hood) if revisited later |
| Firebase Hosting | N/A (deployment target, not a Flutter package) | `flutter build web` output deployed via `firebase deploy` | Free tier sufficient per CLAUDE.md; needs a `firebase.json` with correct rewrite/headers config for wasm Content-Type |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Domain (`lib/domain`) ↔ Providers (`lib/providers`) | Direct function calls, no platform awareness | Unaffected by web — this is the layer that proves the architecture generalizes |
| Providers ↔ Data/Platform (`lib/data`, `lib/platform`, `lib/services`) | Riverpod `ref.watch`/`ref.read` against thin wrapper classes (`AppDatabase`, `CalendarService`, `WeatherRepository`) | All web-specific branching concentrates here; no new boundary needed, just new configuration/guards inside existing classes |
| `main.dart` bootstrap ↔ platform packages (WorkManager, home_widget) | Direct static calls, `kIsWeb`-gated | The only place where "should this platform feature run at all" is decided |

## Suggested Build Order

1. **`flutter create --platforms web .`** — scaffold `web/` directory with default `index.html`/`manifest.json`. Commit this scaffold before touching anything else.
2. **`flutter build web` (or `flutter run -d chrome`) with zero web-specific code changes** — confirm the existing UI (Home, Ride Detail, Profile, Availability, Onboarding, Welcome via go_router) renders, navigates, and that providers relying only on `shared_preferences` (Profile, Availability, locale, theme) work end-to-end. Expect `AppDatabase` and location/calendar features to fail or throw at this stage — that's expected and confirms the scope of remaining work.
3. **Wire Drift for web** — add `sqlite3.wasm` + `drift_worker.dart.js` to `web/`, add `DriftWebOptions` to `app_database.dart`. Prove persistence explicitly: write data, hard-reload the page, confirm data survives. This is the highest-risk, most silently-failable step — do not skip manual verification.
4. **Wire geolocation** — test `LocationNotifier`/`GpsPermissionNotifier` in a real browser (not just `flutter run -d chrome` which may behave differently around permission prompts than a deployed HTTPS site). Add the `kIsWeb` guard/copy change for `openSettings()`.
5. **Wire the on-foreground/on-load refresh trigger** replacing WorkManager — add the new small provider/listener, guard WorkManager init in `main.dart` with `!kIsWeb`, guard `home_widget` calls with `kIsWeb`.
6. **Wire Google Calendar auth for web** — set up Web OAuth client ID + authorized origins in Google Cloud Console, pass conditional `clientId` into `CalendarService`, manually test the full "Add to calendar" flow in a deployed (not just local) environment since OAuth redirect/origin behavior differs between `localhost` and the production domain.
7. **PWA polish + deploy** — manifest icons/theme-color, install prompt behavior, Firebase Hosting `firebase.json` headers (wasm Content-Type), verify Lighthouse PWA installability checklist, deploy and test "Add to Home Screen" on an actual iOS device (Safari PWA behavior cannot be reliably verified in desktop-browser dev tools alone).

This order front-loads the step most likely to reveal architecture-level surprises (step 2: does the reactive Riverpod/go_router UI even run on web with zero changes) before investing in the higher-effort, higher-risk platform integrations (Drift persistence, then geolocation, then OAuth) — each subsequent step also has a hard dependency on the previous one working (e.g., there's no point debugging Calendar OAuth popups if the underlying page doesn't render yet).

## Sources

- [Drift Web platform docs](https://drift.simonbinder.eu/platforms/web/) — storage backends (OPFS/IndexedDB/in-memory), sqlite3.wasm + drift_worker setup, COOP/COEP header notes — HIGH confidence, official docs
- [drift_flutter on pub.dev](https://pub.dev/packages/drift_flutter) — `driftDatabase()` API surface incl. `DriftWebOptions` — HIGH confidence
- [geolocator on pub.dev](https://pub.dev/packages/geolocator) + changelog — web (`geolocator_web`) requires secure context; permission-check nuances on web — MEDIUM-HIGH confidence (WebSearch-verified against package docs)
- [permission_handler / permission_handler_web on pub.dev](https://pub.dev/packages/permission_handler_web) — partial web support, no OS-settings equivalent — MEDIUM confidence
- [google_sign_in on pub.dev](https://pub.dev/packages/google_sign_in) + GitHub issues on v7.x `initialize(clientId/serverClientId)` breaking changes — MEDIUM confidence; exact `authorizeScopes()` web popup behavior is LOW confidence, flagged for phase-specific validation
- [workmanager (flutter_workmanager) GitHub](https://github.com/fluttercommunity/flutter_workmanager) — confirmed no web platform support (long-open feature request) — HIGH confidence
- [home_widget on pub.dev](https://pub.dev/packages/home_widget) — Android/iOS-native-widget-only, no web implementation — MEDIUM-HIGH confidence (absence of web platform listing across multiple sources)
- [flutter_timezone on pub.dev](https://pub.dev/packages/flutter_timezone) — confirmed web support added — MEDIUM confidence (not needed for this milestone since notifications are deferred, included for completeness)
- Existing codebase read directly: `lib/data/database/app_database.dart`, `lib/platform/background_task.dart`, `lib/services/calendar_service.dart`, `lib/providers/location_provider.dart`, `lib/providers/gps_permission_notifier.dart`, `lib/providers/weather_notifier.dart`, `lib/providers/availability_notifier.dart`, `lib/providers/profile_notifier.dart`, `lib/providers/slots_notifier.dart`, `lib/services/widget_update_service.dart`, `lib/main.dart`, `pubspec.yaml` — HIGH confidence (primary source, current state of the repo)

---
*Architecture research for: Flutter Web/PWA integration (RideWindow v2.0)*
*Researched: 2026-07-10*
