# Phase 07: Location — Pattern Map

**Gemaakt:** 2026-06-03
**Gebaseerd op:** Fases 03, 04, 06 PATTERNS.md + codebase-analyse

---

## Bestandsclassificatie

| Nieuw/Gewijzigd bestand | Rol | Dataflow | Dichtstbijzijnd analogon | Match-kwaliteit |
|---|---|---|---|---|
| `pubspec.yaml` (wijziging) | config | — | zichzelf (Phase 4 go_router toevoeging) | exact |
| `android/app/build.gradle.kts` (wijziging) | config | — | zichzelf | exact |
| `android/app/src/main/AndroidManifest.xml` (wijziging) | config | — | zichzelf | exact |
| `lib/core/nl_cities.dart` (nieuw) | data-constante | — | `lib/core/config.dart` | exact |
| `lib/providers/gps_permission_notifier.dart` (nieuw) | provider (AsyncNotifier) | GPS → state | `lib/providers/weather_notifier.dart` | rol-match |
| `lib/providers/location_provider.dart` (VERVANGEN) | provider (AsyncNotifier) | permission + profile → LocationData | zichzelf (stub) + `weather_notifier.dart` patroon | exact |
| `lib/providers/location_provider.g.dart` (hergenereerd) | codegen output | — | zichzelf | — |
| `lib/data/weather_repository.dart` (wijziging) | repository | LocationData → API | zichzelf | exact |
| `lib/providers/weather_notifier.dart` (wijziging) | provider | locatie param doorgeven | zichzelf | exact |
| `lib/features/profile/profile_screen.dart` (wijziging) | scherm | city picker + GPS-status banner | zichzelf (Phase 6 versie) | exact |
| `lib/features/home/home_screen.dart` (wijziging) | scherm | actieve stadsnaam tonen | zichzelf (Phase 6 versie) | exact |
| `test/providers/gps_permission_notifier_test.dart` (nieuw) | unit-test | — | `test/providers/weather_notifier_test.dart` | rol-match |
| `test/providers/location_provider_test.dart` (nieuw) | unit-test | — | `test/providers/weather_notifier_test.dart` | rol-match |
| `test/features/profile_screen_location_test.dart` (nieuw) | widget-test | — | `test/features/profile_screen_test.dart` | exact |

---

## Patroonopdrachtkaarten

### `lib/core/nl_cities.dart` (data-constante)

**Analogon:** `lib/core/config.dart`

```dart
// lib/core/nl_cities.dart
/// Gecureerde lijst van NL steden voor de stad-picker (LOC-03, v1).
class NlCity {
  const NlCity({required this.name, required this.lat, required this.lon});
  final String name;
  final double lat;
  final double lon;
}

const List<NlCity> kNlCities = [
  NlCity(name: 'Amsterdam',   lat: 52.3676, lon: 4.9041),
  NlCity(name: 'Rotterdam',   lat: 51.9225, lon: 4.4792),
  NlCity(name: 'Den Haag',    lat: 52.0705, lon: 4.3007),
  NlCity(name: 'Utrecht',     lat: 52.0907, lon: 5.1214),
  NlCity(name: 'Eindhoven',   lat: 51.4416, lon: 5.4697),
  NlCity(name: 'Groningen',   lat: 53.2194, lon: 6.5665),
  NlCity(name: 'Tilburg',     lat: 51.5555, lon: 5.0913),
  NlCity(name: 'Almere',      lat: 52.3508, lon: 5.2647),
  NlCity(name: 'Breda',       lat: 51.5719, lon: 4.7683),
  NlCity(name: 'Nijmegen',    lat: 51.8425, lon: 5.8372),
  NlCity(name: 'Leiden',      lat: 52.1601, lon: 4.4970),
  NlCity(name: 'Haarlem',     lat: 52.3874, lon: 4.6462),
];
```

---

### `lib/providers/gps_permission_notifier.dart` (AsyncNotifier)

**Analogon:** `lib/providers/weather_notifier.dart` (AsyncNotifier structuur)

```dart
// lib/providers/gps_permission_notifier.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gps_permission_notifier.g.dart';

/// Beheert de GPS-toestemmings-state machine.
/// Gegenereerde providernaam: gpsPermissionProvider
@riverpod
class GpsPermissionNotifier extends _$GpsPermissionNotifier {
  @override
  Future<LocationPermission> build() async {
    return Geolocator.checkPermission();
  }

  /// Vraag toestemming op; update state op basis van resultaat.
  Future<LocationPermission> requestPermission() async {
    final result = await Geolocator.requestPermission();
    state = AsyncData(result);
    return result;
  }

  /// Deep-link naar app-instellingen (deniedForever geval, LOC-04).
  Future<void> openSettings() async {
    await openAppSettings(); // van permission_handler
  }
}
```

**Gegenereerde naam:** `gpsPermissionProvider`

---

### `lib/providers/location_provider.dart` (VERVANGEN — AsyncNotifier)

**Analogon:** `lib/providers/weather_notifier.dart` (AsyncNotifier) + huidige stub

De functionele `location(Ref ref)` provider wordt vervangen door `LocationNotifier extends _$LocationNotifier`.

```dart
// lib/providers/location_provider.dart
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ridewindow/core/config.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';

part 'location_provider.g.dart';

class LocationData {
  const LocationData({required this.lat, required this.lon, required this.city});
  final double lat;
  final double lon;
  final String city;
}

/// Gegenereerde providernaam: locationProvider (Notifier-suffix gestript)
@riverpod
class LocationNotifier extends _$LocationNotifier {
  @override
  Future<LocationData> build() async {
    // 1. Check city override uit profile (LOC-05: override heeft voorrang)
    final profile = await ref.watch(profileProvider.future);
    final override = profile.locationOverride;
    if (override != null) {
      // Zoek stad in kNlCities; fallback naar Amsterdam als niet gevonden
      final city = kNlCities.firstWhere(
        (c) => c.name == override,
        orElse: () => kNlCities.first,
      );
      return LocationData(lat: city.lat, lon: city.lon, city: city.name);
    }

    // 2. Check GPS-toestemming
    final permission = await ref.watch(gpsPermissionProvider.future);
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.reduced,
            timeLimit: Duration(seconds: 30),
          ),
        );
        return LocationData(lat: pos.latitude, lon: pos.longitude, city: 'GPS');
      } catch (_) {
        // Timeout of fout — fallback naar default
      }
    }

    // 3. Fallback naar Amsterdam default
    return const LocationData(lat: kDefaultLat, lon: kDefaultLon, city: kDefaultCity);
  }
}
```

**Gegenereerde naam:** `locationProvider` (ongewijzigd — bestaande consumers hoeven niet te worden aangepast)

---

### `lib/data/weather_repository.dart` (wijziging)

**Analogon:** zichzelf

`getForecast()` moet `lat` en `lon` accepteren zodat de echte locatie wordt gebruikt:

```dart
// Huidig (Phase 2):
Future<List<HourlyForecast>> getForecast() async { ... }

// Gewenst (Phase 7):
Future<List<HourlyForecast>> getForecast({
  double lat = kDefaultLat,
  double lon = kDefaultLon,
}) async { ... }
```

Named parameters met defaults — bestaande aanroep zonder args blijft compileren.

---

### `lib/providers/weather_notifier.dart` (wijziging)

**Analogon:** zichzelf

```dart
@riverpod
class WeatherNotifier extends _$WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() {
    // Wacht op locationProvider en geef lat/lon door aan repository
    final locationAsync = ref.watch(locationProvider);
    return locationAsync.when(
      data: (loc) => ref.watch(weatherRepositoryProvider)
          .getForecast(lat: loc.lat, lon: loc.lon),
      loading: () => Future.value([]),
      error: (e, _) => Future.error(e),
    );
  }
}
```

**Alternatief:** gebruik `ref.watch(locationProvider.future)` in een async build voor nettere error propagatie.

---

### Stad-picker bottom sheet (in ProfileScreen)

**Analogon:** Phase 5 InsightsSheet bottom sheet patroon

```dart
// Trigger in ProfileScreen body:
ListTile(
  leading: const Icon(Icons.location_city),
  title: Text(profile.locationOverride ?? 'GPS (automatisch)'),
  subtitle: const Text('Tik om stad te kiezen'),
  trailing: profile.locationOverride != null
      ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => ref.read(profileProvider.notifier).setLocationOverride(null),
        )
      : null,
  onTap: () => _openCityPicker(context),
);

// Bottom sheet:
void _openCityPicker(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => ListView.builder(
      itemCount: kNlCities.length,
      itemBuilder: (_, i) {
        final city = kNlCities[i];
        return ListTile(
          title: Text(city.name),
          onTap: () {
            ref.read(profileProvider.notifier).setLocationOverride(city.name);
            Navigator.of(context).pop();
          },
        );
      },
    ),
  );
}
```

---

### GPS-geweigerd banner (in ProfileScreen)

```dart
// Toon alleen als toestemming permanentGeweigerd is:
if (permission == LocationPermission.deniedForever)
  Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Locatie-toegang geblokkeerd',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Kies een stad of open instellingen om GPS opnieuw in te schakelen.'),
          TextButton(
            onPressed: () => ref.read(gpsPermissionProvider.notifier).openSettings(),
            child: const Text('Instellingen openen'),
          ),
        ],
      ),
    ),
  ),
```

---

### Widget-testpatronen (overgenomen uit Phase 6)

```dart
// FakeGpsPermissionNotifier
class FakeGpsPermissionNotifier extends GpsPermissionNotifier {
  final LocationPermission fakePermission;
  FakeGpsPermissionNotifier(this.fakePermission);

  @override
  Future<LocationPermission> build() async => fakePermission;
}

// FakeLocationNotifier
class FakeLocationNotifier extends LocationNotifier {
  final LocationData fakeLocation;
  FakeLocationNotifier(this.fakeLocation);

  @override
  Future<LocationData> build() async => fakeLocation;
}

// ProviderScope overrides
ProviderScope(
  overrides: [
    gpsPermissionProvider.overrideWith(() => FakeGpsPermissionNotifier(LocationPermission.whileInUse)),
    locationProvider.overrideWith(() => FakeLocationNotifier(const LocationData(lat: 52.37, lon: 4.90, city: 'Amsterdam'))),
    profileProvider.overrideWith(() => FakeProfileNotifier(testProfile)),
  ],
  child: MaterialApp(home: const ProfileScreen()),
)
```

---

## Gedeelde patronen (overgenomen uit vorige fases)

| Patroon | Bron | Toepassen op |
|---------|------|--------------|
| `@riverpod` AsyncNotifier | `weather_notifier.dart` | `GpsPermissionNotifier`, `LocationNotifier` |
| FakeNotifier (`extends ConcreteClass`) | STATE.md beslissing 03-03 | `FakeGpsPermissionNotifier`, `FakeLocationNotifier` |
| `profileProvider.future` await in build | `slots_notifier.dart` | `LocationNotifier.build()` |
| `part 'x.g.dart'` + build_runner | alle providers | `gps_permission_notifier.g.dart`, `location_provider.g.dart` |
| SharedPreferences mock in tests | Phase 6 widget-tests | `location_provider_test.dart` |
| `package:` imports (niet relatief) | alle bestanden | alle nieuwe bestanden |

---

## Aantekeningen voor de uitvoerder

1. **`compileSdk = 35` in `android/app/build.gradle.kts`** — vervang `compileSdk = flutter.compileSdkVersion` door `compileSdk = 35`. Dit is een vereiste van `permission_handler 12.x`.

2. **`locationProvider` naam bewaard** — `LocationNotifier` genereert `locationProvider` (Notifier gestript door code-gen). `HomeScreen` en `WeatherNotifier` verwijzen hier al naar — geen aanpassingen nodig in die consumers.

3. **`WeatherNotifier` re-bouwt automatisch** als `locationProvider` verandert, omdat `ref.watch(locationProvider)` in `build()` zit. Dit is Riverpod's reactieve ketening.

4. **Geolocator `LocationSettings` API** — in geolocator 14.x wordt `desiredAccuracy` doorgegeven via `LocationSettings(accuracy: LocationAccuracy.reduced)`, niet als losse parameter.

5. **`openAppSettings()`** komt uit `permission_handler` (niet uit `geolocator`). Zorg dat `permission_handler` geïmporteerd is in `gps_permission_notifier.dart`.

6. **Bouw volgorde na nieuwe providers** — altijd `flutter pub run build_runner build --delete-conflicting-outputs` draaien na aanpassen van `@riverpod`-bestanden.
