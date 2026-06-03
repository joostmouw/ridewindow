# Phase 07: Location — Context & Beslissingen

**Gemaakt:** 2026-06-03
**Fase:** GPS + manual city + permission state machine

---

## Vergrendelde beslissingen (LOC-*)

| ID | Beslissing | Rationale |
|----|-----------|-----------|
| D-07-01 | Gebruik `geolocator: 14.0.2` voor GPS-coördinaten | Vastgelegd in CLAUDE.md; baseflow.com publisher, 6.1k likes |
| D-07-02 | Gebruik `permission_handler: 12.0.3` voor toestemmingsbeheer | Vastgelegd in CLAUDE.md; vereist `compileSdk = 35` in build.gradle.kts |
| D-07-03 | `GpsPermissionNotifier` als aparte `AsyncNotifier<LocationPermission>` | Enkelvoudige verantwoordelijkheid; permission state machine los van locatielogica |
| D-07-04 | `LocationNotifier` vervangt de stub `location(Ref ref)` — wordt `AsyncNotifier<LocationData>` | Riverpod 3.x AsyncNotifier patroon; consistentie met `WeatherNotifier` en `ProfileNotifier` |
| D-07-05 | Stadskeuze uit een gehardcodeerde Dart-constante (~12 NL steden) in `lib/core/nl_cities.dart` | v1-scope; LOC-03 zegt "curated short-list of NL cities" |
| D-07-06 | Stad-picker als `showModalBottomSheet` vanuit ProfileScreen (geen nieuwe route) | Instructies: "no new routes needed — city picker opens as a dialog/bottom sheet" |
| D-07-07 | `ProfileNotifier.setLocationOverride(String? location)` gebruikt als persistentielaag voor city override | Al geïmplementeerd in Phase 3; sleutel: `profile.locationOverride` in SharedPreferences |
| D-07-08 | `locationProvider` blijft de gegenereerde naam (Riverpod 3.x strip Notifier-suffix) | Bestaande `HomeScreen` en `WeatherNotifier` verwijzen al naar `locationProvider` |
| D-07-09 | Bij permanente weigering: `AppSettings.openAppSettings()` via `permission_handler` voor deep-link | Standaard aanpak voor Android settings deep-link |
| D-07-10 | `WeatherRepository.getForecast(lat, lon)` signature uitbreiden met `lat` en `lon` parameters | Noodzakelijk om dynamische locatie door te sturen; was hardcoded Amsterdam |
| D-07-11 | `compileSdk = 35` instellen via `compileSdk = 35` (override flutter.compileSdkVersion) in `android/app/build.gradle.kts` | `permission_handler 12.x` vereiste; CLAUDE.md constraint |
| D-07-12 | FakeNotifier test patroon: `extends GpsPermissionNotifier` en `extends LocationNotifier` | Gevestigd patroon uit Phase 3 en 6 (STATE.md beslissing 03-03 en 03-04) |

---

## Uitgestelde ideeën (NIET in deze fase)

- Background GPS polling (Phase 8 WorkManager scope)
- iOS location permission (Android-only in v1)
- Route-gebaseerde locatie (out of scope voor v1)
- Meerdere locaties tegelijk (out of scope voor v1)

---

## Claude's discretie

- Steden-lijst: 12 NL steden met lat/lon hardcoded in `lib/core/nl_cities.dart` als `const List<NlCity>`. Steden: Amsterdam, Rotterdam, Den Haag, Utrecht, Eindhoven, Groningen, Tilburg, Almere, Breda, Nijmegen, Leiden, Haarlem.
- Bottom sheet stijl: `DraggableScrollableSheet` of standaard `showModalBottomSheet` met `isScrollControlled: true` — kies eenvoudigste optie die werkt.
- `LocationPermission.deniedForever` banner in ProfileScreen: eenvoudige rode `Card` met uitleg en `TextButton('Instellingen openen')`.
- GPS timeout: 30 seconden; daarna fallback naar SharedPreferences override of kDefaultLat/kDefaultLon.
