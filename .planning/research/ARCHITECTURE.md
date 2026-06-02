# Architecture Research

**Domain:** Local-first Flutter Android app — cyclist weather-window scheduler
**Researched:** 2026-06-01
**Confidence:** HIGH (Flutter official docs + Riverpod official docs + verified community sources)

---

## Standard Architecture

### System Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                          │
│   Views (Screens/Widgets)       ViewModels / Notifiers             │
│   HomeScreen  DetailScreen      WeatherNotifier  SlotsNotifier     │
│   ProfileScreen  OnboardScreen  AvailabilityNotifier               │
├────────────────────────────────────────────────────────────────────┤
│                         DOMAIN LAYER                               │
│   (Pure Dart — zero Flutter / zero I/O dependencies)               │
│   ScoringEngine   SlotGenerator   AvailabilityFilter               │
│   RideSlot        HourlyScore     UserProfile   WeatherTolerances  │
├────────────────────────────────────────────────────────────────────┤
│                          DATA LAYER                                │
│   WeatherRepository     ProfileRepository     ForecastCache        │
│   OpenMeteoClient       HiveProfileStore      HiveForecastStore    │
│   CalendarService       NotificationService                        │
├────────────────────────────────────────────────────────────────────┤
│                       PLATFORM LAYER                               │
│   LocationPlugin    WorkManagerPlugin    FirebaseMessaging          │
│   GoogleCalendarAPI                                                │
└────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Layer |
|-----------|---------------|-------|
| `ScoringEngine` | Converts hourly weather data + tolerances → 0–100 score per hour. Pure function, no I/O. | Domain |
| `SlotGenerator` | Finds contiguous good-score hours, produces `RideSlot` objects of 2h / 3h / 4–5h. Pure function. | Domain |
| `AvailabilityFilter` | Removes slots that overlap blocked hours from user profile. Pure function. | Domain |
| `WeatherRepository` | Fetches forecast from Open-Meteo and writes to local cache. Returns typed domain models. | Data |
| `ProfileRepository` | Persists and reads user profile, availability grid, tolerances, ride-length prefs. | Data |
| `ForecastCache` | Hive box wrapping 168-hour (7×24) forecast. Exposes `isStale()` for cache decisions. | Data |
| `OpenMeteoClient` | Raw HTTP to Open-Meteo API. Returns raw JSON → domain `HourlyForecast`. | Data |
| `CalendarService` | Google Calendar OAuth sign-in + event creation. Optional, on-demand only. | Data |
| `NotificationService` | Firebase Messaging + local notification scheduling. Decoupled from weather logic. | Data |
| `WeatherNotifier` | AsyncNotifier watching `WeatherRepository`. Exposes `AsyncValue<List<HourlyForecast>>`. | Presentation |
| `SlotsNotifier` | Derives `List<RideSlot>` by running domain pipeline on weather + profile. Watches both. | Presentation |
| `AvailabilityNotifier` | Manages availability grid edits; persists on save. | Presentation |
| `ProfileNotifier` | Manages tolerances, ride lengths, location preference. | Presentation |
| `HomeScreen` | Reads `SlotsNotifier`. Renders week strip + ranked slot cards. | Presentation |
| `DetailScreen` | Reads single `RideSlot` from route args. Renders hourly breakdown + insights sheet. | Presentation |

---

## Data Flow

### Primary Pipeline: weather data → score → slots → UI

```
[App Launch / Foreground Resume]
         │
         ▼
  WeatherRepository.getForecast(lat, lon)
    ├─ cache fresh?  YES → return cached HourlyForecast list
    └─ cache stale?  NO  → OpenMeteoClient.fetch()
                              │
                              ▼
                         cache to Hive (ForecastCache)
                              │
                              ▼
                     return HourlyForecast list
         │
         ▼
  ScoringEngine.score(hourly, tolerances)
    → List<HourlyScore>  (0–100 per hour, with temp/rain/wind sub-scores)
         │
         ▼
  SlotGenerator.generate(scores, rideLengthPrefs)
    → List<RideSlot>  (start, end, duration, overallScore)
         │
         ▼
  AvailabilityFilter.filter(slots, userProfile.blockedHours)
    → List<RideSlot>  (available only, sorted by score desc)
         │
         ▼
  SlotsNotifier (Riverpod AsyncNotifier)
    → HomeScreen watches → renders ranked slot cards
    → DetailScreen watches single slot → renders hourly + insights
```

### Background Refresh Pipeline (WorkManager)

```
[Android WorkManager periodic task — min 15 min interval]
  callbackDispatcher()   ← separate Dart isolate, NOT the Flutter UI isolate
         │
         ▼
  WeatherRepository.getForecast()  ← opens Hive in background isolate
         │
         ▼
  Write fresh forecast to Hive ForecastCache
         │
         ▼
  [Task returns Future.value(true)]

[App returns to foreground]
         │
         ▼
  WeatherNotifier detects stale cache invalidated
         │
         ▼
  Re-runs primary pipeline → SlotsNotifier updates → UI rebuilds
```

**Key constraint:** WorkManager runs in a separate Dart isolate. It cannot directly update Riverpod state. The bridge is Hive — WorkManager writes to Hive, and on foreground resume the Riverpod provider re-reads Hive and triggers reactive rebuilds. Use `WidgetsBinding.instance.addObserver` in the root widget to trigger a provider refresh on `AppLifecycleState.resumed`.

### Notification Trigger Pipeline

```
[SlotsNotifier computes slots for tomorrow / this morning]
         │
         ▼
  NotificationService.schedule(slot)
    ├─ "Evening before" → local notification at 19:00 prior day
    ├─ "Morning of"     → local notification at slot.start - 2h
    └─ "Weekly digest"  → WorkManager one-off task Sunday 19:00
```

### Google Calendar Flow (on-demand only)

```
[User taps "Add to calendar" on Plan sheet]
         │
         ▼
  CalendarService.isSignedIn() → prompt OAuth if not
         │
         ▼
  CalendarService.createEvent(slot) → Google Calendar API
         │
         ▼
  Show success snackbar
```

---

## State Management: Riverpod

**Recommendation: Riverpod 3.x with code generation (`@riverpod` annotations)**

**Rationale:**

- **No boilerplate overhead for solo dev.** BLoC requires Event classes, State classes, Bloc classes — approximately 145 lines vs Riverpod's ~78 lines for equivalent auth/data flows (verified source: flutterstudio.dev, 2026). For a solo dev working evenings, this is a meaningful DX difference.
- **Built-in dependency injection.** No separate `get_it` / `injectable` setup. `ref.watch` and `ref.read` replace DI containers.
- **Testability via ProviderContainer.** Override any provider in tests with `ProviderContainer(overrides: [...])`. Clean test isolation without mocking framework ceremony.
- **`FutureProvider` handles the weather fetch lifecycle.** Loading / error / data states are first-class (`AsyncValue`). The weather fetch → cache → UI pattern maps directly onto `AsyncNotifier`.
- **Compile-time safety.** Code-gen annotations catch missing providers at build time, not runtime.
- **Provider watches across boundaries.** `SlotsNotifier` can `ref.watch(weatherProvider)` and `ref.watch(profileProvider)` — the derived slots re-compute automatically when either changes. This eliminates manual trigger wiring.

**Provider types used in RideWindow:**

| Provider type | Used for |
|--------------|---------|
| `FutureProvider` | Weather fetch (async, cached) |
| `AsyncNotifier` | WeatherNotifier with refresh capability |
| `Notifier` | SlotsNotifier, AvailabilityNotifier, ProfileNotifier (mutable, synchronous-feeling) |
| `Provider` | ScoringEngine, SlotGenerator (stateless services — injected as providers for testability) |

**Why not Provider (package):** Deprecated trajectory; requires BuildContext for access; no compile-time safety. Not recommended for new projects in 2026.

**Why not BLoC:** Appropriate for large teams that need strict architectural guardrails. Overkill boilerplate for a solo dev building a 6-screen app.

**Why not setState:** Adequate for leaf widgets only. Cannot share state across screens or survive navigation without lifting to root widget. Not viable for cross-screen data (weather, profile).

---

## Recommended Folder Structure

**Choice: Feature-first, with shared domain and data layers**

Feature-first is recommended by Andrea Bizzotto (codewithandrea.com) and the broader Flutter community for apps where features are independently modifiable. For RideWindow, layer-first would scatter the scoring engine, its repository, and its UI across four top-level folders — harder to navigate on a solo project where you're constantly context-switching.

```
lib/
├── main.dart                     # ProviderScope, Firebase init, WorkManager setup
├── app.dart                      # MaterialApp, router, theme
│
├── core/                         # Shared across all features
│   ├── theme/
│   │   └── app_theme.dart        # Material 3 color scheme, text styles
│   ├── router/
│   │   └── app_router.dart       # go_router route definitions
│   ├── widgets/
│   │   ├── score_badge.dart      # Reusable "Perfect/Great/OK" chip
│   │   └── weather_chip.dart     # Temp/rain/wind inline chip
│   └── extensions/
│       └── date_extensions.dart
│
├── domain/                       # Pure Dart — no Flutter, no I/O
│   ├── models/
│   │   ├── hourly_forecast.dart  # Value object: temp, rain, wind per hour
│   │   ├── hourly_score.dart     # Value object: overall + 3 sub-scores
│   │   ├── ride_slot.dart        # Value object: start, end, duration, score
│   │   └── user_profile.dart    # Availability grid, tolerances, prefs
│   └── services/
│       ├── scoring_engine.dart   # score(HourlyForecast, Tolerances) → HourlyScore
│       ├── slot_generator.dart   # generate(List<HourlyScore>, prefs) → List<RideSlot>
│       └── availability_filter.dart  # filter(List<RideSlot>, UserProfile) → List<RideSlot>
│
├── data/                         # Repositories, remote clients, local stores
│   ├── weather/
│   │   ├── open_meteo_client.dart     # HTTP calls to Open-Meteo
│   │   ├── weather_repository.dart    # Cache-or-fetch logic
│   │   └── forecast_cache.dart        # Hive box wrapper, isStale()
│   ├── profile/
│   │   └── profile_repository.dart    # Hive persistence for UserProfile
│   ├── calendar/
│   │   └── calendar_service.dart      # Google Calendar OAuth + event creation
│   └── notifications/
│       └── notification_service.dart  # Firebase + local notification scheduling
│
├── features/
│   ├── onboarding/
│   │   ├── onboarding_screen.dart
│   │   └── onboarding_notifier.dart
│   │
│   ├── home/
│   │   ├── home_screen.dart           # Week strip + slot cards
│   │   ├── home_notifier.dart         # Watches SlotsNotifier, exposes UI state
│   │   └── widgets/
│   │       ├── week_strip.dart
│   │       └── ride_card.dart
│   │
│   ├── ride_detail/
│   │   ├── ride_detail_screen.dart    # Score banner, weather rows, hourly table
│   │   ├── ride_detail_notifier.dart
│   │   └── widgets/
│   │       ├── insights_sheet.dart    # "Why this score?" bottom sheet
│   │       └── hourly_table.dart
│   │
│   ├── profile/
│   │   ├── profile_screen.dart        # Settings rows: location, ride length, notifications
│   │   ├── profile_notifier.dart
│   │   └── widgets/
│   │       └── tolerance_slider.dart
│   │
│   └── availability/
│       ├── availability_screen.dart   # 7×16 hour grid
│       └── availability_notifier.dart
│
├── platform/                     # Android-specific integration
│   ├── workmanager_setup.dart    # callbackDispatcher + task registration
│   ├── location_service.dart     # geolocator wrapper
│   └── background_refresh.dart   # Task body: fetch + cache
│
└── providers.dart                # Barrel file: all top-level provider declarations
```

**Structure rationale:**

- `domain/` is flat and import-free — no `package:flutter`, no Hive, no HTTP. This makes the scoring engine trivially unit-testable with `dart test`.
- `data/` repositories depend on `domain/models/` but not on `features/`. Clean downward dependency.
- `features/` contain screen + notifier + feature-specific widgets. A feature's notifier imports from `data/` repositories and `domain/services/`, never from another feature.
- `platform/` isolates all Android-specific wiring. If iOS is added in v2, this folder gets an iOS counterpart without touching `features/`.
- `providers.dart` barrel: a single import for all Riverpod provider declarations prevents circular imports across features.

---

## Architectural Patterns

### Pattern 1: Derived Provider (SlotsNotifier watches WeatherNotifier + ProfileNotifier)

**What:** `SlotsNotifier` is a Riverpod `AsyncNotifier` that `ref.watch`es both the weather provider and the profile provider. When either changes, slots automatically recompute.

**When to use:** Any time you have computed/derived state that depends on multiple sources. Eliminates manual "refresh" calls.

```dart
@riverpod
class SlotsNotifier extends _$SlotsNotifier {
  @override
  Future<List<RideSlot>> build() async {
    final forecast = await ref.watch(weatherNotifierProvider.future);
    final profile  = ref.watch(profileNotifierProvider);
    final scores   = ref.read(scoringEngineProvider).score(forecast, profile.tolerances);
    final slots    = ref.read(slotGeneratorProvider).generate(scores, profile.rideLengthPrefs);
    return ref.read(availabilityFilterProvider).filter(slots, profile);
  }
}
```

**Trade-offs:** Slightly harder to debug than explicit imperative refresh, but eliminates stale-data bugs.

### Pattern 2: Repository with Cache-or-Fetch

**What:** `WeatherRepository.getForecast()` checks `ForecastCache.isStale()` before hitting the network. Returns domain models regardless of source (cache or network).

**When to use:** Any remote data that should survive cold starts without re-fetching unnecessarily.

```dart
class WeatherRepository {
  Future<List<HourlyForecast>> getForecast(double lat, double lon) async {
    if (!_cache.isStale()) return _cache.read();
    final raw = await _client.fetch(lat, lon);
    _cache.write(raw);
    return raw;
  }
}
```

**Trade-offs:** Cache invalidation logic lives in one place. The `isStale()` threshold (e.g., 1 hour) is a tunable constant.

### Pattern 3: Background → Hive → Foreground Resume Bridge

**What:** WorkManager task writes to Hive. On `AppLifecycleState.resumed`, the root widget calls `ref.invalidate(weatherNotifierProvider)` which re-reads Hive and triggers the full pipeline.

**When to use:** Any background work that must surface in the UI without direct isolate-to-Flutter communication (which WorkManager does not support).

```dart
// In root widget
class AppLifecycleObserver extends ConsumerWidget with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(weatherNotifierProvider);
    }
  }
}
```

**Trade-offs:** The UI never directly knows about WorkManager. Decoupled and testable. Minor: a brief loading state on resume (acceptable — same as fresh start).

---

## Build Order (Phase Dependencies)

The scoring engine is the center of gravity. Nothing else is correct until the domain layer is correct.

```
Phase 1: Domain layer + Scoring engine
  └─ ScoringEngine, SlotGenerator, AvailabilityFilter
  └─ All domain models (HourlyForecast, RideSlot, UserProfile, Tolerances)
  └─ Full unit test coverage
  └─ Unblocks: everything (no other component is meaningful without correct scores)

Phase 2: Data layer — local storage
  └─ ProfileRepository (Hive/Isar)
  └─ ForecastCache (Hive/Isar)
  └─ Unblocks: weather fetch (needs cache); profile (needs persistence)

Phase 3: Data layer — weather fetch
  └─ OpenMeteoClient (HTTP)
  └─ WeatherRepository (cache-or-fetch)
  └─ Unblocks: SlotsNotifier (needs real weather data); background refresh

Phase 4: Riverpod providers + state wiring
  └─ WeatherNotifier, SlotsNotifier, ProfileNotifier, AvailabilityNotifier
  └─ providers.dart barrel
  └─ Unblocks: all screens (screens are thin consumers of providers)

Phase 5: Onboarding + Home screen (MVP visible value)
  └─ OnboardingScreen, HomeScreen, week strip, RideCard
  └─ Unblocks: end-to-end flow; first real testing on device

Phase 6: Ride Detail screen + Insights sheet
  └─ RideDetailScreen, InsightsSheet, hourly breakdown
  └─ Unblocks: "Why this score?" — critical for trust in scoring

Phase 7: Profile + Availability screens
  └─ ProfileScreen, AvailabilityScreen (7×16 grid)
  └─ Tolerance sliders, ride-length chips
  └─ Unblocks: personalisation; slots filtered by real user availability

Phase 8: Background refresh + Notifications
  └─ WorkManager setup, callbackDispatcher
  └─ Firebase Messaging, local notification scheduling
  └─ Unblocks: passive value (heads-up without opening app)

Phase 9: Google Calendar integration
  └─ CalendarService, OAuth flow
  └─ "Add to calendar" action on Plan sheet
  └─ Unblocks: booking workflow; deferred because it requires Google Cloud project setup

Phase 10: Location (GPS + city picker)
  └─ geolocator, city search (Open-Meteo geocoding API)
  └─ Unblocks: real-location forecast (vs hardcoded Amsterdam for dev)
  └─ Note: hardcode Amsterdam in Phase 3 to unblock weather fetch development

Phase 11: Release packaging
  └─ AAB signing, ProGuard, Play Console setup
  └─ Privacy policy, Store listing
```

**Why this order:**

1. Domain first because it has zero dependencies — you can build and test it offline, before any API key, package, or device. A broken scoring formula discovered in Phase 8 would be catastrophic.
2. Local storage before network because the cache layer must exist before the repository can use it.
3. Providers before screens because screens are thin wrappers — without a working provider graph, widget development is blocked.
4. Background refresh before calendar because WorkManager is simpler (no OAuth) and more impactful for daily usage.
5. Location deferred because Amsterdam hardcoded is sufficient for all development phases — GPS is polish, not MVP.

---

## Testing Boundaries

| Layer | Test type | What to test | Framework |
|-------|-----------|-------------|-----------|
| `domain/services/` | Unit test (`dart test`) | ScoringEngine with edge cases (boundary temps, 0mm rain, 30+ wind), SlotGenerator with various score sequences, AvailabilityFilter with complex blocked grids | Pure Dart — no flutter_test, no mocks needed |
| `domain/models/` | Unit test | Value equality, fromJson/toJson round-trip | Pure Dart |
| `data/weather/` | Unit test with mocks | WeatherRepository cache-or-fetch logic; OpenMeteoClient JSON parsing | `mocktail` for HTTP client |
| `data/profile/` | Integration test (in-memory Hive) | ProfileRepository read/write/update with real Hive in-memory store | `hive_test` or temp directory |
| Riverpod providers | Unit test with ProviderContainer | SlotsNotifier derives correct slots; WeatherNotifier exposes AsyncValue states | `riverpod` ProviderContainer + `mocktail` |
| Screens | Widget test | HomeScreen renders correct slot count; RideCard shows correct score badge; AvailabilityScreen toggles cells | `flutter_test`, `ProviderScope` with overrides |
| End-to-end flows | Integration test | Onboarding → home → detail → plan sheet flow | `integration_test` package |

**Key principle:** The scoring engine must have 100% unit test coverage before Phase 5. It is the product's core value claim — if it scores wrong, the app is wrong regardless of how polished the UI is.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Calling scoring logic from the UI layer

**What people do:** Compute scores inside `build()` methods or directly in screen widgets.
**Why it's wrong:** Makes the scoring engine untestable in isolation, ties business logic to widget lifecycle, and makes tolerance slider changes hard to propagate.
**Do this instead:** ScoringEngine is a domain service, exposed as a Riverpod `Provider`. The `SlotsNotifier` calls it. Screens only watch `SlotsNotifier`.

### Anti-Pattern 2: Updating UI state directly from WorkManager callbackDispatcher

**What people do:** Try to call `ref.read(provider.notifier).update()` from the background isolate.
**Why it's wrong:** WorkManager runs in a separate Dart isolate. Riverpod state lives in the main isolate's `ProviderScope`. Cross-isolate provider mutation is not supported and will silently fail or crash.
**Do this instead:** WorkManager writes to Hive only. The UI isolate reads Hive on foreground resume via `ref.invalidate()`. The bridge is the local database, not direct state mutation.

### Anti-Pattern 3: Feature folders organized by screen instead of by capability

**What people do:** `features/home_screen/`, `features/detail_screen/`, `features/profile_screen/`.
**Why it's wrong:** Screen-first organization breaks down when one feature (e.g., "ride planning") spans multiple screens. You end up with cross-screen imports that create circular dependencies.
**Do this instead:** Organize by user capability: `features/home/` (what the user does on the main screen), `features/ride_detail/`, `features/profile/`. Each feature owns its screens, notifiers, and feature-specific widgets.

### Anti-Pattern 4: Storing computed slots in local storage

**What people do:** Persist `List<RideSlot>` to Hive alongside the forecast.
**Why it's wrong:** Slots are derived from forecast + profile. Any tolerance change or availability edit invalidates cached slots instantly — you'd have to invalidate and recompute anyway. Storing them adds complexity with no benefit.
**Do this instead:** Store only raw `HourlyForecast` in Hive. Recompute slots on demand via `SlotsNotifier`. The domain pipeline is cheap (pure in-memory computation over 168 hours).

### Anti-Pattern 5: One giant `UserProfile` Hive box for everything

**What people do:** Serialize `UserProfile` as one JSON blob in a single Hive entry.
**Why it's wrong:** The availability grid (7 days × 24 hours = 168 booleans) embedded in the profile JSON becomes expensive to deserialize just to read the user's ride length preference.
**Do this instead:** Split into two Hive boxes: `profileBox` (tolerances, ride prefs, location, notification settings) and `availabilityBox` (grid). Load them independently. The availability grid is only needed in `AvailabilityFilter`, not on every app resume.

---

## Integration Points

### External Services

| Service | Integration pattern | Layer | Notes |
|---------|---------------------|-------|-------|
| Open-Meteo API | HTTP GET, no API key | `data/weather/open_meteo_client.dart` | Free tier, 10,000 req/day — weekly background refresh uses ~50/day. Cache aggressively (1h TTL minimum). |
| Google Calendar API | OAuth 2.0, `googleapis` + `google_sign_in` packages | `data/calendar/calendar_service.dart` | On-demand only (user taps "Plan it"). Do not initialize on startup. Requires Google Cloud project. |
| Firebase Cloud Messaging | Push token registration, `firebase_messaging` package | `data/notifications/notification_service.dart` | Used for "weekly digest" triggered from server-side schedule. Local notifications for evening/morning alerts. |
| Android WorkManager | `workmanager` package, `callbackDispatcher` | `platform/workmanager_setup.dart` | Min 15-min interval. Register on first run + after boot via `RECEIVE_BOOT_COMPLETED`. Cannot update Riverpod state directly — see bridge pattern above. |
| Device GPS | `geolocator` package | `platform/location_service.dart` | Request permission once. Cache last known position. Fall back to stored city coordinates if permission denied. |

### Internal Boundaries

| Boundary | Communication | Rule |
|----------|---------------|------|
| `domain/` ↔ `data/` | `data/` imports `domain/models/`. Never reversed. | Domain has zero data dependencies. |
| `data/` ↔ `features/` | Features import repositories via Riverpod providers. Never import repository class directly. | Keeps features testable via provider overrides. |
| `features/` ↔ `features/` | Never. Features do not import each other. | Shared state lives in providers.dart or core/. |
| `platform/` ↔ `data/` | `platform/background_refresh.dart` instantiates `WeatherRepository` directly (no Riverpod — different isolate). | ProviderScope is not available in WorkManager isolate. |
| `platform/` ↔ `features/` | Never. Platform code does not know about UI features. | Platform writes to Hive; UI reads Hive. |

---

## Scalability Considerations

RideWindow is a local-first single-user app with no backend. Scalability concerns are device-level, not infrastructure-level.

| Concern | Current approach | If it becomes a problem |
|---------|-----------------|------------------------|
| 168-hour forecast in memory | In-memory list of 168 `HourlyForecast` structs — negligible (<100 KB) | Non-issue at this scale |
| Scoring engine CPU time | Pure Dart, 168 iterations — <5ms on any modern phone | If expanded to 14-day forecast: run in `compute()` isolate |
| Availability grid re-render | 7×16 = 112 cell widgets — StatefulWidget is fine | If grid expands: use `RepaintBoundary` per row |
| Background refresh battery | WorkManager 15-min minimum, batched by OS | Already handled by WorkManager's battery-aware scheduling |
| Hive box size | Forecast + profile ≈ 200 KB | Non-issue on any device with >1 GB storage |

---

## Sources

- Flutter official architecture docs: https://docs.flutter.dev/app-architecture/concepts (HIGH confidence — official)
- Flutter MVVM layered architecture case study: https://docs.flutter.dev/app-architecture/case-study (HIGH confidence — official)
- Riverpod 3.x official docs: https://riverpod.dev/docs/how_to/testing (HIGH confidence — official)
- Riverpod GitHub docs/providers: https://github.com/rrousselgit/riverpod (HIGH confidence — official)
- Flutter background isolates: https://docs.flutter.dev/perf/isolates (HIGH confidence — official)
- Flutter WorkManager package: https://pub.dev/packages/workmanager (HIGH confidence — official pub.dev)
- BLoC vs Riverpod 2026 comparison: https://flutterstudio.dev/blog/bloc-vs-riverpod.html (MEDIUM confidence — verified analysis, single source)
- Flutter feature-first vs layer-first: https://codewithandrea.com/articles/flutter-project-structure/ (MEDIUM confidence — widely cited community authority, Andrea Bizzotto)
- WorkManager state update challenge: https://github.com/fluttercommunity/flutter_workmanager/issues/559 (MEDIUM confidence — community issue thread confirming isolate boundary)

---

*Architecture research for: RideWindow — local-first Flutter Android cyclist weather-window app*
*Researched: 2026-06-01*
