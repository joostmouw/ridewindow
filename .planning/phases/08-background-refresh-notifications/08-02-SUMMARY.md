---
phase: 08-background-refresh-notifications
plan: 02
subsystem: infra
tags: [workmanager, drift, shared_preferences, riverpod, background, isolate, timezone, flutter_timezone]

# Dependency graph
requires:
  - phase: 08-01-dependency-setup
    provides: workmanager ^0.9.0+3 + flutter_timezone ^5.1.0 + timezone ^0.11.0 in pubspec.yaml
  - phase: 07-location-gps-manual-city-permission-state-machine
    provides: kNlCities list, kDefaultLat/kDefaultLon, WeatherRepository.getForecast() interface
  - phase: 02-data-layer
    provides: AppDatabase, ForecastDao.replaceAll(), OpenMeteoClient.fetch()
provides:
  - lib/platform/background_task.dart met callbackDispatcher top-level functie (@pragma vm:entry-point)
  - lib/providers/last_refreshed_provider.dart met LastRefreshedNotifier + refresh() methode
  - lib/providers/last_refreshed_provider.g.dart (lastRefreshedProvider code-gen output)
  - lib/main.dart: WorkManager.initialize() + tz.initializeTimeZones() voor runApp()
  - lib/data/repositories/weather_repository.dart: schrijft weather.lastRefreshed na fetch
affects:
  - 08-03-notification-service
  - 08-04-notification-ui
  - HomeScreen lastRefreshed-weergave (plan 08-04 of later)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - WorkManager isolate-safe pattern: eigen Drift DB + http.Client initialiseren in callbackDispatcher (geen Riverpod)
    - @pragma('vm:entry-point') op callbackDispatcher zodat tree-shaker de functie behoudt in release-builds
    - FlutterTimezone 5.1.0 retourneert TimezoneInfo object; .identifier property geeft IANA-naam (niet directe String)
    - Workmanager().initialize() zonder isInDebugMode (deprecated in 0.9.x)
    - lastRefreshed timestamp als int (millisecondsSinceEpoch) in SharedPreferences

key-files:
  created:
    - lib/platform/background_task.dart
    - lib/providers/last_refreshed_provider.dart
    - lib/providers/last_refreshed_provider.g.dart
  modified:
    - lib/main.dart
    - lib/data/repositories/weather_repository.dart

key-decisions:
  - "WorkManager isolate draait eigen Drift DB met naam 'ridewindow' (zelfde als foreground) — WAL-modus handelt gelijktijdige toegang af (T-08-02-02)"
  - "FlutterTimezone 5.1.0 API: TimezoneInfo.identifier property voor IANA-naam (niet directe String return)"
  - "isInDebugMode parameter verwijderd — deprecated in workmanager 0.9.x zonder vervanging in API"
  - "NetworkType.connected constraint in registerPeriodicTask — voorkomt zinloze retries zonder netwerk (T-08-02-01)"
  - "AppDatabase initialisatie met driftDatabase(name: 'ridewindow') in isolate — zelfde DB-naam als foreground"

patterns-established:
  - "WorkManager background worker: initialiseer alle dependencies lokaal in de callback (geen Riverpod)"
  - "SharedPreferences sleutel weather.lastRefreshed als int (millisecondsSinceEpoch)"
  - "LastRefreshedNotifier.refresh(): state = AsyncLoading() + AsyncValue.guard(() => build())"

requirements-completed: [NOTIF-06]

# Metrics
duration: 12min
completed: 2026-06-03
---

# Phase 08 Plan 02: WorkManager background worker + LastRefreshed persistence Summary

**WorkManager isolate-safe callbackDispatcher, LastRefreshedNotifier (SharedPreferences provider), timezone-initialisatie in main(), en lastRefreshed schrijven in WeatherRepository geimplementeerd**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-03T18:23:05Z
- **Completed:** 2026-06-03T18:35:00Z
- **Tasks:** 2
- **Files modified:** 5 (1 nieuw platform-bestand, 2 nieuwe provider-bestanden, main.dart, weather_repository.dart)

## Accomplishments

- background_task.dart met @pragma('vm:entry-point') callbackDispatcher — volledige isolate-safe implementatie: Drift DB initialiseren, locatie-override lezen uit SharedPreferences, OpenMeteoClient aanroepen, ForecastDao.replaceAll() schrijven, lastRefreshed timestamp opslaan
- LastRefreshedNotifier als AsyncNotifier<DateTime?> met refresh()-methode; last_refreshed_provider.g.dart gegenereerd door build_runner
- main.dart: async main() met tz.initializeTimeZones() + FlutterTimezone.getLocalTimezone() + Workmanager().initialize() + registerPeriodicTask(3h flexInterval) voor runApp()
- WeatherRepository schrijft nu 'weather.lastRefreshed' na elke succesvolle foreground fetch
- dart analyze meldt geen fouten in alle gewijzigde en nieuwe bestanden

## Task Commits

Elke taak atomisch gecommit:

1. **Task 1: Maak lib/platform/background_task.dart aan (isolate-safe WorkManager worker)** - `c6008a1` (feat)
2. **Task 2: LastRefreshedNotifier + main.dart WorkManager/timezone initialisatie + WeatherRepository lastRefreshed schrijven** - `c6f5b62` (feat)

**Plan metadata:** *(volgt in final commit)*

## Files Created/Modified

- `lib/platform/background_task.dart` - WorkManager callbackDispatcher + _runWeatherRefresh isolate-safe implementatie; kWeatherRefreshTaskName + kWeatherRefreshTaskTag constanten
- `lib/providers/last_refreshed_provider.dart` - LastRefreshedNotifier AsyncNotifier leest SharedPreferences 'weather.lastRefreshed'; refresh() herlaadt state
- `lib/providers/last_refreshed_provider.g.dart` - Gegenereerd door build_runner; exporteert lastRefreshedProvider
- `lib/main.dart` - main() nu async; tz.initializeTimeZones() + FlutterTimezone timezone-init + Workmanager().initialize() + registerPeriodicTask(3h, networkType: connected) voor runApp()
- `lib/data/repositories/weather_repository.dart` - Schrijft SharedPreferences 'weather.lastRefreshed' na succesvolle fetch (D-08-12)

## Decisions Made

- FlutterTimezone 5.1.0 API-wijziging: `getLocalTimezone()` retourneert `TimezoneInfo` object (niet `String`). Gebruikt `.identifier` property voor `tz.getLocation()`.
- `isInDebugMode` parameter in `Workmanager().initialize()` is deprecated in 0.9.x; parameter verwijderd.
- AppDatabase in isolate geinitialiseerd met `driftDatabase(name: 'ridewindow')` — zelfde naam als foreground DB zodat beide isolates dezelfde SQLite-file lezen/schrijven (Drift WAL-modus handelt dit af).
- NetworkType.connected constraint in registerPeriodicTask — implementeert T-08-02-01 mitigatie.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FlutterTimezone 5.1.0 retourneert TimezoneInfo, niet String**
- **Found during:** Task 2 (main.dart timezone-initialisatie)
- **Issue:** Plan specificeerde `final timezoneName = await FlutterTimezone.getLocalTimezone(); tz.setLocalLocation(tz.getLocation(timezoneName));` — maar FlutterTimezone 5.1.0 retourneert `TimezoneInfo` object, niet directe `String`. dart analyze meldde `argument_type_not_assignable`.
- **Fix:** Aangepast naar `final timezoneInfo = await FlutterTimezone.getLocalTimezone(); tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));`
- **Files modified:** lib/main.dart
- **Verification:** dart analyze lib/main.dart — "No issues found!"
- **Committed in:** c6f5b62 (Task 2 commit)

**2. [Rule 1 - Bug] isInDebugMode parameter deprecated in workmanager 0.9.x**
- **Found during:** Task 2 (main.dart WorkManager initialisatie)
- **Issue:** dart analyze meldde `deprecated_member_use` voor `isInDebugMode: false` — parameter heeft geen effect meer in 0.9.x.
- **Fix:** `isInDebugMode: false` parameter verwijderd; `Workmanager().initialize(callbackDispatcher)` volstaat.
- **Files modified:** lib/main.dart
- **Verification:** dart analyze lib/main.dart — "No issues found!"
- **Committed in:** c6f5b62 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2x Rule 1 — API-wijzigingen in flutter_timezone 5.1.0 en workmanager 0.9.x)
**Impact on plan:** Beide auto-fixes noodzakelijk voor correcte werking. Geen scope creep.

## Issues Encountered

Geen blocking issues. Beide API-deviaties snel gedetecteerd en opgelost via dart analyze na eerste implementatie.

## Threat Surface Scan

Geen nieuwe security-relevante surface buiten de geplande threat_model:
- T-08-02-01 (DoS): NetworkType.connected constraint geimplementeerd
- T-08-02-02 (Tampering): Drift WAL-modus inherent actief voor gelijktijdige DB-toegang
- T-08-02-03 (Info Disclosure): lastRefreshed is louter timestamp, geen PII — accepted
- T-08-02-04 (EoP): @pragma('vm:entry-point') aanwezig op callbackDispatcher

## User Setup Required

None — geen externe service-configuratie vereist.

## Next Phase Readiness

- background_task.dart klaar als WorkManager entry-point voor Android achtergrond-refresh
- lastRefreshedProvider beschikbaar voor HomeScreen ondertitel (Plan 08-04 of 08-05)
- WeatherRepository schrijft lastRefreshed bij iedere foreground fetch — enkelvoudige bron van waarheid
- Plan 08-03 (NotificationService) kan voortbouwen op dezelfde tz.initializeTimeZones() initialisatie

## Known Stubs

None — alle geimplementeerde onderdelen zijn volledig functioneel en schrijven/lezen echte data.

## Self-Check

- [x] lib/platform/background_task.dart bestaat: `ls` bevestigt aanwezigheid
- [x] @pragma('vm:entry-point') aanwezig: `grep '@pragma' lib/platform/background_task.dart` — gevonden
- [x] callbackDispatcher top-level: bevestigd in bestand
- [x] kWeatherRefreshTaskName + kWeatherRefreshTaskTag: aanwezig in background_task.dart
- [x] lib/providers/last_refreshed_provider.g.dart: build_runner succesvol gegenereerd
- [x] tz.initializeTimeZones() in main.dart: `grep 'initializeTimeZones'` — gevonden
- [x] Workmanager().initialize() in main.dart: `grep 'Workmanager.*initialize'` — gevonden
- [x] weather.lastRefreshed schrijven in weather_repository.dart: `grep 'lastRefreshed'` — gevonden
- [x] dart analyze alle nieuwe/gewijzigde bestanden: "No issues found!"
- [x] Commits aanwezig: c6008a1 (Task 1), c6f5b62 (Task 2)

## Self-Check: PASSED

---
*Phase: 08-background-refresh-notifications*
*Completed: 2026-06-03*
