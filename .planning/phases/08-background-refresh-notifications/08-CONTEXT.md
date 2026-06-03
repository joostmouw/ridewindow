# Phase 08: Background refresh + Notifications — Context

**Gemaakt:** 2026-06-03
**Gebaseerd op:** ROADMAP.md, REQUIREMENTS.md, STATE.md, CLAUDE.md, bestaande codebase (Phases 1–7)

---

## Fase-doel

De app vernieuwt weerdata op de achtergrond en kan drie soorten opt-in-notificaties sturen — zonder dat de gebruiker de app hoeft te openen.

---

## Vergrendelde beslissingen (D-08-xx)

| ID | Beslissing | Reden |
|----|-----------|-------|
| D-08-01 | `workmanager: 0.9.0+3` voor achtergrondtaken | Vastgelegd in CLAUDE.md; federated plug-in, workmanager_android automatisch meegetrokken |
| D-08-02 | `flutter_local_notifications: 21.0.0` voor geplande notificaties | Vastgelegd in CLAUDE.md; v21 vereist `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle` |
| D-08-03 | `timezone: 0.11.0` + `flutter_timezone: 5.1.0` | Vereist door flutter_local_notifications voor DST-correcte `TZDateTime`-planning |
| D-08-04 | WorkManager-achtergrondtaak draait in een aparte Dart-isolate — Riverpod + Drift OPNIEUW initialiseren in de callback | Kritische isolate-beperking uit CLAUDE.md; de achtergrondtaak mag GEEN ProviderScope/ref van de foreground-isolate gebruiken |
| D-08-05 | `lastRefreshed` timestamp opslaan in SharedPreferences onder sleutel `'weather.lastRefreshed'` | Simpele key-value persistentie voldoet; Drift is te zwaar voor één timestamp |
| D-08-06 | WorkManager periodiek interval: 3–6 uur (FlexInterval: min=3h, max=6h) | NOTIF-06 vereiste; iOS-achtige flex laat OS batterij-optimalisatie uitvoeren |
| D-08-07 | Notificatiekanalen: `'ride_alerts'` (Avond-van-tevoren + Ochtend-van-de-dag) en `'weekly_digest'` | Android 8+ kanaalsegregatie; gebruiker kan elk kanaal onafhankelijk dempen in OS-instellingen |
| D-08-08 | `POST_NOTIFICATIONS`-permissie via `permission_handler` (al in pubspec.yaml) opvragen vóór eerste notificatie-planning | NOTIF-04 vereiste; runtime-prompt op Android 13+ |
| D-08-09 | `SCHEDULE_EXACT_ALARM`: controleer via `AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()`; deep-link naar systeeminstellingen als geweigerd; plan inexact als fallback | NOTIF-05 vereiste; Android 12+ vereist systeeminstellingen-deep-link |
| D-08-10 | `tz.initializeTimeZones()` + `tz.setLocalLocation()` aanroepen in `main()` vóór `runApp()` | Vereiste initialisatie voor flutter_local_notifications zonedSchedule |
| D-08-11 | Notificatie-scheduling gecentraliseerd in `lib/platform/notification_service.dart` | Scheidt platform-code van UI en providers; analoog aan `WeatherRepository` data-laag-scheiding |
| D-08-12 | WeatherRepository schrijft `lastRefreshed` na succesvolle fetch (zowel foreground als background) | Enkelvoudige bron van waarheid; HomeScreen leest via een eenvoudige `lastRefreshedProvider` |
| D-08-13 | HomeScreen toont `lastRefreshed` als `'Bijgewerkt: HH:mm'` ondertitel in de header | NOTIF-06 UI-deliverable; leesbaar en beknopt |
| D-08-14 | FakeNotifier-patroon (`extends ConcreteClass`) voor widget-tests | Consistent met STATE.md beslissing 03-03, 04-05 et al. |

---

## Uitgestelde ideeën (NIET in te plannen)

- iOS notificatiesupport (buiten scope v1)
- FCM push-notificaties (vereist backend — out of scope)
- Notificatie-rich media / grote afbeeldingen
- Wear OS companion notificaties
- Achtergrond geo-fencing (locatiewijzigings-triggers)

---

## Technische beperkingen (kritisch voor uitvoerders)

### WorkManager isolate-beperking

De achtergrondcallback draait in een **aparte Dart-isolate**. Dit betekent:

- Geen toegang tot ProviderScope of Riverpod providers van de foreground
- Drift (`AppDatabase`) OPNIEUW initialiseren met `NativeDatabase.createInBackground()`
- `http.Client` OPNIEUW instantiëren
- `SharedPreferences` werkt normaal (platform-kanaal is thread-safe)
- `flutter_local_notifications` werkt normaal (platform-kanaal)
- De taak is thin data-laag: fetch → schrijf naar Drift → update `lastRefreshed` in SharedPreferences → klaar

### timezone-initialisatie

`tz.initializeTimeZones()` laadt timezone-data synchroon in geheugen. Dit MOET aanroepen worden in `main()` vóór `runApp()`. Zonder dit crasht `zonedSchedule()`.

### SCHEDULE_EXACT_ALARM Android-beleid

- Android 12 (API 31): toestemming vereist, maar standaard verleend
- Android 13 (API 33): zelfde als 12
- Android 14 (API 34)+: standaard GEWEIGERD bij nieuwe installatie; gebruiker moet handmatig toekennen via Instellingen → Apps → Speciale app-toegang → Exacte alarmen
- Fallback: `AndroidScheduleMode.alarmClock` mislukken detecteren, overschakelen naar `inexact`, SnackBar tonen

---

## Afhankelijkheden van vorige fases

| Van | Wat Phase 8 hergebruikt |
|-----|------------------------|
| Phase 2 | `WeatherRepository.getForecast()`, Drift `AppDatabase`, `OpenMeteoClient` |
| Phase 3 | `ProfileNotifier` (notif-toggles bestaan al), `WeatherNotifier`, `profileProvider` |
| Phase 6 | `ProfileScreen` structuur (`_SectionHeader`, sectie-ListView-patroon) |
| Phase 7 | `permission_handler` (al in pubspec), AndroidManifest-permissie-patroon, `LocationNotifier` voor lat/lon |
