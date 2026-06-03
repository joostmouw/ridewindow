---
phase: 08-background-refresh-notifications
plan: 03
subsystem: platform
tags: [flutter_local_notifications, permission_handler, timezone, TZDateTime, notifications, android]

# Dependency graph
requires:
  - phase: 08-01-dependency-setup
    provides: flutter_local_notifications ^21.0.0 + permission_handler ^12.0.3 + timezone ^0.11.0 in pubspec.yaml
  - phase: 08-02-workmanager-background-task
    provides: tz.initializeTimeZones() in main() voor TZDateTime gebruik
provides:
  - lib/platform/notification_service.dart met NotificationService klasse + 8 methoden
  - kNotifIdEveningBefore (1001), kNotifIdMorningOf (1002), kNotifIdWeeklyDigest (1003) constanten
  - AndroidNotificationChannel 'ride_alerts' en 'weekly_digest' definities
affects:
  - 08-04-notification-ui: ProfileScreen integreert NotificationService voor permission + scheduling flow
  - lib/features/profile/profile_screen.dart: zal NotificationService gebruiken voor notif-toggles

# Tech tracking
tech-stack:
  added: []
  patterns:
    - flutter_local_notifications v21 API: initialize(settings: initSettings) — named param (niet positional)
    - flutter_local_notifications v21 API: zonedSchedule met named params (id:, title:, body:, scheduledDate:, notificationDetails:, androidScheduleMode:)
    - AndroidNotificationDetails heeft geen androidScheduleMode constructor-param — alleen zonedSchedule() heeft die
    - exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexact patroon voor SCHEDULE_EXACT_ALARM fallback
    - TZDateTime verleden-check: scheduledDate.isBefore(TZDateTime.now(tz.local)) guard
    - TZDateTime.from(DateTime, tz.local) voor Duration-substractie van dart DateTime naar TZDateTime

key-files:
  created:
    - lib/platform/notification_service.dart
  modified: []

key-decisions:
  - "flutter_local_notifications v21 breekt met v18/v19 API: initialize() vereist settings: named param; zonedSchedule() is volledig named-param-based; UILocalNotificationDateInterpretation bestaat niet meer in v21"
  - "AndroidNotificationDetails heeft geen androidScheduleMode in constructor — alleen als top-level named param op zonedSchedule()"
  - "TZDateTime.from(slotStart.subtract(Duration(hours:2)), tz.local) voor scheduleMorningOf — converteert dart DateTime na Duration-aftrek naar TZDateTime"

patterns-established:
  - "NotificationService als plain Dart class met optionele FlutterLocalNotificationsPlugin? plugin DI-param voor testbaarheid"
  - "Kanalen als static const op klasse (niet top-level) — leesbaar en gebundeld bij klasse"

requirements-completed: [NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05]

# Metrics
duration: 8min
completed: 2026-06-03
---

# Phase 08 Plan 03: NotificationService platform-service Summary

**NotificationService met flutter_local_notifications v21 API — twee kanalen, permissie-flow, drie TZDateTime-schedulers en cancelAll geimplementeerd**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-03T18:20:38Z
- **Completed:** 2026-06-03T18:28:00Z
- **Tasks:** 1
- **Files modified:** 1 (nieuw platform-bestand)

## Accomplishments

- notification_service.dart aangemaakt als plain Dart class (geen @riverpod) met optionele DI voor testbaarheid
- Twee AndroidNotificationChannel-definities als static const: `ride_alerts` (Importance.high) en `weekly_digest` (Importance.defaultImportance)
- kNotifIdEveningBefore (1001), kNotifIdMorningOf (1002), kNotifIdWeeklyDigest (1003) constanten
- init(): plugin initialiseert met AndroidInitializationSettings + beide kanalen aanmaken via resolvePlatformSpecificImplementation
- requestPostNotificationsPermission(): Permission.notification.request() via permission_handler; retourneert status.isGranted
- canScheduleExact(): androidPlugin?.canScheduleExactNotifications() ?? false
- openExactAlarmSettings(): requestExactAlarmsPermission() met openAppSettings() fallback via try-catch
- scheduleEveningBefore(): TZDateTime(tz.local, y, m, day-1, 19, 0); verleden-guard; exact/inexact mode; kNotifIdEveningBefore
- scheduleMorningOf(): TZDateTime.from(slotStart.subtract(2h), tz.local); verleden-guard; exact/inexact mode; kNotifIdMorningOf
- scheduleWeeklyDigest(): eerstvolgende zondag 19:00 berekend via daysUntilSunday; weekly_digest kanaal; kNotifIdWeeklyDigest
- cancelAll(): delegeert naar _plugin.cancelAll()
- dart analyze: "No issues found!"

## Task Commits

1. **Task 1: Maak lib/platform/notification_service.dart aan met alle methoden** — `3ec30ce` (feat)

## Files Created/Modified

- `lib/platform/notification_service.dart` — NotificationService klasse met init(), requestPostNotificationsPermission(), canScheduleExact(), openExactAlarmSettings(), scheduleEveningBefore(), scheduleMorningOf(), scheduleWeeklyDigest(), cancelAll()

## Decisions Made

- flutter_local_notifications v21 API-wijziging: `initialize()` vereist `settings:` named parameter (niet positional). `zonedSchedule()` is volledig named-param-based — geen `uiLocalNotificationDateInterpretation` meer in v21.
- `AndroidNotificationDetails` heeft geen `androidScheduleMode` in de constructor — dit is uitsluitend een top-level named parameter op `zonedSchedule()`.
- `TZDateTime.from(slotStart.subtract(Duration(hours: 2)), tz.local)` voor `scheduleMorningOf` — converteert een dart `DateTime` (na Duration-aftrek) naar `TZDateTime`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] flutter_local_notifications v21 init() API verschilt van plan-documentatie**
- **Found during:** Task 1 (dart analyze na eerste implementatie)
- **Issue:** Plan-interfaces specificeerden `await _plugin.initialize(initSettings)` (positional arg) — maar v21 API vereist `await _plugin.initialize(settings: initSettings)` (named param). dart analyze meldde `missing_required_argument` en `extra_positional_arguments_could_be_named`.
- **Fix:** Aangepast naar `await _plugin.initialize(settings: initSettings)`.
- **Files modified:** lib/platform/notification_service.dart
- **Commit:** 3ec30ce

**2. [Rule 1 - Bug] flutter_local_notifications v21 zonedSchedule() API verschilt van plan-documentatie**
- **Found during:** Task 1 (dart analyze na eerste implementatie)
- **Issue:** Plan-interfaces specificeerden positional arguments voor zonedSchedule (notificationId, titel, body, scheduledDate, NotificationDetails, androidScheduleMode:, uiLocalNotificationDateInterpretation:) — maar v21 API gebruikt volledig named parameters en `UILocalNotificationDateInterpretation` bestaat niet meer.
- **Fix:** Aangepast naar `zonedSchedule(id:, title:, body:, scheduledDate:, notificationDetails:, androidScheduleMode:)`.
- **Files modified:** lib/platform/notification_service.dart
- **Commit:** 3ec30ce

**3. [Rule 1 - Bug] AndroidNotificationDetails heeft geen androidScheduleMode constructor-param**
- **Found during:** Task 1 (dart analyze na eerste implementatie)
- **Issue:** Plan-interfaces plaatsten `androidScheduleMode:` binnen `AndroidNotificationDetails(...)` constructor — maar dit is uitsluitend een parameter van `zonedSchedule()`, niet van `AndroidNotificationDetails`.
- **Fix:** `androidScheduleMode:` verplaatst naar top-level `zonedSchedule()` call; verwijderd uit `AndroidNotificationDetails`.
- **Files modified:** lib/platform/notification_service.dart
- **Commit:** 3ec30ce

---

**Total deviations:** 3 auto-fixed (3x Rule 1 — flutter_local_notifications v21 API-wijzigingen t.o.v. plan-documentatie)
**Impact on plan:** Alle drie noodzakelijk voor compilerende, analyseerbare code. Functionaliteit en semantiek identiek aan plan-intentie.

## Issues Encountered

Geen blocking issues. Alle drie API-deviaties gedetecteerd door dart analyze na eerste implementatie en direct opgelost.

## Threat Surface Scan

- T-08-03-02 (DoS): `isBefore(TZDateTime.now(tz.local))` guard geimplementeerd in scheduleEveningBefore() en scheduleMorningOf()
- T-08-03-03 (EoP): `exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexact` patroon geimplementeerd in alle drie schedulers — caller bepaalt `exact` op basis van canScheduleExact()
- T-08-03-01 (Spoofing): Accepted — notificaties komen altijd van app-package
- T-08-03-04 (Info Disclosure): Accepted — bodySummary bevat alleen rijslot-tijden en scores

Geen nieuwe security-relevante surface buiten de geplande threat_model.

## User Setup Required

None — geen externe service-configuratie vereist.

## Next Phase Readiness

- NotificationService klaar voor gebruik in ProfileScreen (Plan 08-04)
- requestPostNotificationsPermission() + canScheduleExact() + openExactAlarmSettings() gereed voor permission-flow in ProfileScreen
- scheduleEveningBefore() + scheduleMorningOf() + scheduleWeeklyDigest() klaar voor koppeling aan profileProvider notif-toggles

## Known Stubs

None — alle methoden volledig geimplementeerd.

## Self-Check

- [x] lib/platform/notification_service.dart bestaat: aangemaakt in Task 1
- [x] NotificationService klasse aanwezig: bevestigd in bestand
- [x] Alle 8 publieke methoden aanwezig: init, requestPostNotificationsPermission, canScheduleExact, openExactAlarmSettings, scheduleEveningBefore, scheduleMorningOf, scheduleWeeklyDigest, cancelAll
- [x] kNotifId* constanten aanwezig: kNotifIdEveningBefore, kNotifIdMorningOf, kNotifIdWeeklyDigest
- [x] Kanalen 'ride_alerts' en 'weekly_digest' gedeclareerd: `grep 'ride_alerts\|weekly_digest'` — gevonden
- [x] TZDateTime gebruikt: `grep 'TZDateTime'` — 6 resultaten
- [x] dart analyze: "No issues found!"
- [x] Commit aanwezig: 3ec30ce (Task 1)

## Self-Check: PASSED

---
*Phase: 08-background-refresh-notifications*
*Completed: 2026-06-03*
