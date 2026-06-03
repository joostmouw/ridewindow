# Phase 08: Background refresh + Notifications — Patroonkaart

**Gemaakt:** 2026-06-03
**Gebaseerd op:** Phase 07-PATTERNS.md + codebase-analyse Phases 1–7

---

## Bestandsclassificatie

| Nieuw/Gewijzigd bestand | Rol | Dataflow | Dichtstbijzijnd analogon | Match-kwaliteit |
|---|---|---|---|---|
| `pubspec.yaml` (wijziging) | config | — | zichzelf (Phase 7 geolocator-toevoeging) | exact |
| `android/app/src/main/AndroidManifest.xml` (wijziging) | config | — | zichzelf (Phase 7 locatie-permissies) | exact |
| `lib/main.dart` (wijziging) | bootstrap | tz.init → runApp | zichzelf | exact |
| `lib/platform/notification_service.dart` (nieuw) | platform-service | FlutterLocalNotifications → OS | `lib/data/weather_repository.dart` (data-laag scheiding) | rol-match |
| `lib/platform/background_task.dart` (nieuw) | isolate-worker | Drift + HTTP → SharedPrefs | `lib/data/weather_repository.dart` (thin data layer) | rol-match |
| `lib/providers/last_refreshed_provider.dart` (nieuw) | provider (AsyncNotifier) | SharedPrefs → UI | `lib/providers/profile_notifier.dart` (SharedPrefs lezen) | exact |
| `lib/providers/last_refreshed_provider.g.dart` (gegenereerd) | codegen output | — | zichzelf | — |
| `lib/data/weather_repository.dart` (wijziging) | repository | POST naar SharedPrefs na fetch | zichzelf | exact |
| `lib/features/home/home_screen.dart` (wijziging) | scherm | lastRefreshedProvider → header | zichzelf (Phase 7 versie) | exact |
| `lib/features/profile/profile_screen.dart` (wijziging) | scherm | notif-toggles → NotificationService | zichzelf (Phase 7 versie) | exact |
| `test/platform/notification_service_test.dart` (nieuw) | unit-test | — | `test/data/weather_repository_test.dart` | rol-match |
| `test/providers/last_refreshed_provider_test.dart` (nieuw) | unit-test | — | `test/providers/profile_notifier_test.dart` | rol-match |
| `test/features/profile_screen_notif_test.dart` (nieuw) | widget-test | — | `test/features/profile_screen_location_test.dart` | exact |
| `test/features/home_screen_refresh_test.dart` (nieuw) | widget-test | — | `test/features/home_screen_test.dart` | exact |

---

## Patroonopdrachtkaarten

### `lib/platform/notification_service.dart` (nieuwe platform-service)

**Analogon:** `lib/data/weather_repository.dart` (geïsoleerde service-klasse, geen Riverpod)

```dart
// lib/platform/notification_service.dart
// NotificationService: initilisatie + permissie-flow + 3 notificatie-schedulers.
// Geen @riverpod — direct instantieerbaar en mockable in tests.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const _channelRideAlerts = AndroidNotificationChannel(
    'ride_alerts',
    'Rijmeldingen',
    description: 'Avond-van-tevoren en ochtend-van-de-dag rijmeldingen',
    importance: Importance.high,
  );
  static const _channelWeeklyDigest = AndroidNotificationChannel(
    'weekly_digest',
    'Wekelijks overzicht',
    description: 'Zondagavond overzicht van de beste rijmomenten',
    importance: Importance.defaultImportance,
  );

  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Initialiseer plugin + maak kanalen aan. Aanroepen in main() na tz.init.
  Future<void> init() async { ... }

  /// Vraag POST_NOTIFICATIONS op (Android 13+). Geeft true terug als verleend.
  Future<bool> requestPostNotificationsPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Controleer of exacte alarmen mogelijk zijn (Android 12+).
  Future<bool> canScheduleExact() async { ... }

  /// Deep-link naar systeeminstellingen voor exacte alarmen (Android 12+).
  Future<void> openExactAlarmSettings() async { ... }

  /// Plan "Avond van tevoren" notificatie op 19:00 de dag ervoor.
  Future<void> scheduleEveningBefore({
    required DateTime slotDay,
    required String slotTitle,
    required bool exact,
  }) async { ... }

  /// Plan "Ochtend van de dag" notificatie op slotStart − 2h.
  Future<void> scheduleMorningOf({
    required DateTime slotStart,
    required String slotTitle,
    required bool exact,
  }) async { ... }

  /// Plan "Wekelijks overzicht" notificatie op eerstvolgende zondag 19:00.
  Future<void> scheduleWeeklyDigest({
    required String bodySummary,
    required bool exact,
  }) async { ... }

  /// Annuleer alle geplande notificaties (bijv. bij toggle uitzetten).
  Future<void> cancelAll() async => _plugin.cancelAll();
}
```

**Notities:**
- `_plugin` is injecteerbaar voor testbaarheid (DI via constructor)
- Gebruik `TZDateTime` van `package:timezone/timezone.dart` voor alle geplande tijden
- `exact: false` → `AndroidScheduleMode.inexact`, `exact: true` → `AndroidScheduleMode.exactAllowWhileIdle`
- Kanaal-IDs zijn stabiele strings — worden ook in AndroidManifest gebruikt

---

### `lib/platform/background_task.dart` (isolate-worker)

**Analogon:** `lib/data/weather_repository.dart` (thin data layer)

```dart
// lib/platform/background_task.dart
// WeatherRefreshTask: WorkManager callback — draait in aparte Dart-isolate.
// KRITISCH: Geen Riverpod/ProviderScope — eigen Drift + HTTP client initialiseren.

import 'package:workmanager/workmanager.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const kWeatherRefreshTaskName = 'weatherRefresh';
const kWeatherRefreshTaskTag = 'com.ridewindow.weatherRefresh';

/// Top-level callback — moet top-level of static zijn voor WorkManager isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kWeatherRefreshTaskName) {
      await _runWeatherRefresh();
    }
    return Future.value(true);
  });
}

Future<void> _runWeatherRefresh() async {
  // 1. Eigen Drift DB initialiseren (NativeDatabase — niet in-memory)
  // 2. Eigen http.Client instantiëren
  // 3. SharedPreferences ophalen voor locatie-override + lastRefreshed
  // 4. Fetch uitvoeren via OpenMeteoClient (direct, geen WeatherRepository wrapper)
  // 5. Schrijf resultaten naar Drift ForecastEntries tabel
  // 6. Schrijf lastRefreshed naar SharedPreferences('weather.lastRefreshed')
  // 7. Sluit DB + HTTP client
}
```

**Notities:**
- `@pragma('vm:entry-point')` is VEREIST zodat de Dart tree-shaker de callback niet verwijdert
- `callbackDispatcher` MOET top-level zijn (niet in een klasse)
- In Phase 8 haalt `_runWeatherRefresh` direct de forecast op zonder slot-berekening — dat is de taak van de foreground providers
- Drift initialisatie: gebruik `driftDatabase(name: 'ridewindow_db')` (zelfde DB-bestandsnaam als de foreground AppDatabase)

---

### `lib/providers/last_refreshed_provider.dart` (nieuwe provider)

**Analogon:** `lib/providers/profile_notifier.dart` (SharedPreferences lezen in AsyncNotifier)

```dart
// lib/providers/last_refreshed_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'last_refreshed_provider.g.dart';

const kLastRefreshedKey = 'weather.lastRefreshed';

/// Leest de lastRefreshed timestamp uit SharedPreferences.
/// Gegenereerde naam: lastRefreshedProvider
@riverpod
class LastRefreshedNotifier extends _$LastRefreshedNotifier {
  @override
  Future<DateTime?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(kLastRefreshedKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Herlaad timestamp (aanroepen bij foreground resume in HomeScreen).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
```

**Gegenereerde naam:** `lastRefreshedProvider`

---

### HomeScreen `lastRefreshed`-weergave (wijziging)

**Analogon:** Phase 7 locatienaam-weergave (`locationAsync.value?.city`)

```dart
// In HomeScreen.build():
final lastRefreshedAsync = ref.watch(lastRefreshedProvider);
final lastRefreshed = lastRefreshedAsync.value;

// In _buildHeader() — vervang 'This week' ondertitel:
Text(
  lastRefreshed == null
      ? 'Bijgewerkt: —'
      : 'Bijgewerkt: ${_formatTime(lastRefreshed)}',
  style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
),
```

Foreground-resume refresh: gebruik `WidgetsBindingObserver` in `_HomeScreenState` — in `didChangeAppLifecycleState` aanroepen als `state == AppLifecycleState.resumed`:

```dart
ref.read(lastRefreshedProvider.notifier).refresh();
```

---

### ProfileScreen NOTIFICATIES sectie (wijziging)

**Analogon:** Phase 7 LOCATIE sectie (dezelfde `_SectionHeader` + ListView-patroon)

```dart
// Toevoegen na LOCATIE sectie, vóór THEMA sectie:
const _SectionHeader('NOTIFICATIES'),

// NOTIF-01: Avond van tevoren
SwitchListTile(
  title: const Text('Avond van tevoren'),
  subtitle: const Text('19:00 de vorige dag als er een top-slot is'),
  value: profile.notifEveningBefore,
  onChanged: (v) async {
    await ref.read(profileProvider.notifier).setNotifEveningBefore(v);
    if (v) await _scheduleNotificationsIfPermitted(context);
  },
),

// NOTIF-02: Ochtend van de dag
SwitchListTile(
  title: const Text('Ochtend van de dag'),
  subtitle: const Text('2 uur voor het slot begint'),
  value: profile.notifMorningOf,
  onChanged: (v) async {
    await ref.read(profileProvider.notifier).setNotifMorningOf(v);
    if (v) await _scheduleNotificationsIfPermitted(context);
  },
),

// NOTIF-03: Wekelijks overzicht
SwitchListTile(
  title: const Text('Wekelijks overzicht'),
  subtitle: const Text('Zondagavond 19:00 — beste momenten van de week'),
  value: profile.notifWeeklyDigest,
  onChanged: (v) async {
    await ref.read(profileProvider.notifier).setNotifWeeklyDigest(v);
    if (v) await _scheduleNotificationsIfPermitted(context);
  },
),
```

Hulpmethode `_scheduleNotificationsIfPermitted`:
- Vraag `POST_NOTIFICATIONS` op via `NotificationService.requestPostNotificationsPermission()`
- Controleer `canScheduleExact()`; als false, open instellingen of ga door met inexact + SnackBar

---

### Widget-testpatronen (overgenomen uit Phase 7)

```dart
// FakeLastRefreshedNotifier
class FakeLastRefreshedNotifier extends LastRefreshedNotifier {
  final DateTime? fakeTime;
  FakeLastRefreshedNotifier(this.fakeTime);
  @override
  Future<DateTime?> build() async => fakeTime;
}

// FakeNotificationService (voor ProfileScreen tests)
class FakeNotificationService implements NotificationService {
  bool permissionGranted = true;
  bool exactSupported = true;

  @override
  Future<bool> requestPostNotificationsPermission() async => permissionGranted;

  @override
  Future<bool> canScheduleExact() async => exactSupported;
  // ... overige methoden no-op
}
```

---

## Gedeelde patronen (overgenomen uit vorige fases)

| Patroon | Bron | Toepassen op |
|---------|------|--------------|
| `@riverpod` AsyncNotifier | `weather_notifier.dart` | `LastRefreshedNotifier` |
| FakeNotifier (`extends ConcreteClass`) | STATE.md beslissing 03-03 | `FakeLastRefreshedNotifier` |
| `_SectionHeader` in ProfileScreen | Phase 6/7 ProfileScreen | NOTIFICATIES sectie |
| SharedPreferences lezen in `build()` | `profile_notifier.dart` | `LastRefreshedNotifier.build()` |
| `part 'x.g.dart'` + build_runner | alle providers | `last_refreshed_provider.g.dart` |
| `package:` imports (niet relatief) | alle bestanden | alle nieuwe bestanden |
| Dutch comments (`///`) | alle bestanden | alle nieuwe bestanden |

---

## Aantekeningen voor uitvoerders

1. **WorkManager registratie in `main()`**: Roep `Workmanager().initialize(callbackDispatcher)` aan vóór `runApp()`, ná `tz.initializeTimeZones()`.

2. **WorkManager periodieke taak registreren**: Gebruik `Workmanager().registerPeriodicTask(kWeatherRefreshTaskTag, kWeatherRefreshTaskName, frequency: const Duration(hours: 3), flexInterval: const Duration(hours: 3))`. Op Android is de minimale periode 15 minuten — gebruik 3h voor productie.

3. **Drift DB-naam**: De achtergrond-isolate moet dezelfde DB-naam gebruiken als de foreground (`'ridewindow_db'`). Controleer de naam in `lib/providers/app_database_provider.dart`.

4. **`@pragma('vm:entry-point')`**: Vergeet dit NIET op `callbackDispatcher` — zonder dit verwijdert de Dart-compiler de functie in release-builds.

5. **`tz.setLocalLocation()` aanroep**: Gebruik `flutter_timezone` om de IANA-naam van het apparaat op te halen: `final timezoneName = await FlutterTimezone.getLocalTimezone(); tz.setLocalLocation(tz.getLocation(timezoneName));`

6. **`AndroidManifest.xml` WorkManager entries**: WorkManager 0.9.x heeft een `<service>` én een `<receiver>` nodig voor BOOT_COMPLETED herscheduling. Zie Plan 08-01 voor de exacte XML-blokken.

7. **Bouw volgorde**: Na toevoegen van `last_refreshed_provider.dart`: `flutter pub run build_runner build --delete-conflicting-outputs`.
