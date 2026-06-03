---
phase: 08-background-refresh-notifications
plan: 01
subsystem: infra
tags: [workmanager, flutter_local_notifications, timezone, flutter_timezone, android, notifications, background]

# Dependency graph
requires:
  - phase: 07-location-gps-manual-city-permission-state-machine
    provides: permission_handler al in pubspec; AndroidManifest permissie-patroon
provides:
  - workmanager ^0.9.0+3 runtime-dep in pubspec.yaml
  - flutter_local_notifications ^21.0.0 runtime-dep in pubspec.yaml
  - timezone ^0.11.0 runtime-dep in pubspec.yaml
  - flutter_timezone ^5.1.0 runtime-dep in pubspec.yaml
  - Android permissies: RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM, POST_NOTIFICATIONS, FOREGROUND_SERVICE, WAKE_LOCK
  - WorkManager SystemForegroundService en RescheduleOnBootReceiver in AndroidManifest.xml
  - flutter_local_notifications default notificatiekanaal meta-data (ride_alerts)
affects:
  - 08-02-background-worker
  - 08-03-notification-service
  - 08-04-notification-ui

# Tech tracking
tech-stack:
  added:
    - workmanager 0.9.0+3 (fluttercommunity.dev)
    - flutter_local_notifications 21.0.0 (dexterx.dev)
    - timezone 0.11.0 (labs.dart.dev)
    - flutter_timezone 5.1.0 (wolverinebeach.net)
  patterns:
    - Phase 8 dependencies gegroepeerd onder "# Phase 8 — Achtergrond + Notificaties" commentaar in pubspec.yaml
    - WorkManager service + receiver registratie in AndroidManifest.xml na activity block

key-files:
  created: []
  modified:
    - pubspec.yaml
    - pubspec.lock
    - android/app/src/main/AndroidManifest.xml

key-decisions:
  - "workmanager ^0.9.0+3 — federated plugin, workmanager_android automatisch meegetrokken (D-08-01)"
  - "flutter_local_notifications ^21.0.0 — v21 vereist androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle (D-08-02)"
  - "timezone ^0.11.0 + flutter_timezone ^5.1.0 — vereist voor DST-correcte TZDateTime-planning (D-08-03)"
  - "ride_alerts als standaard notificatiekanaal ID in meta-data (D-08-07)"
  - "SCHEDULE_EXACT_ALARM permissie gedeclareerd — Android 12+ vereist expliciete gebruikerstoestemming via systeeminstellingen (T-08-01-02)"

patterns-established:
  - "Phase 8 deps: gegroepeerd commentaarblok in pubspec.yaml per fase"
  - "WorkManager: SystemForegroundService + RescheduleOnBootReceiver in AndroidManifest.xml"

requirements-completed: [NOTIF-04, NOTIF-05, NOTIF-06]

# Metrics
duration: 8min
completed: 2026-06-03
---

# Phase 08 Plan 01: Dependency Setup — Background + Notifications Summary

**Vier Phase 8 runtime-packages (workmanager, flutter_local_notifications, timezone, flutter_timezone) toegevoegd aan pubspec.yaml; Android permissies en WorkManager-registraties in AndroidManifest.xml**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-03T18:15:00Z
- **Completed:** 2026-06-03T18:23:00Z
- **Tasks:** 2
- **Files modified:** 3 (pubspec.yaml, pubspec.lock, AndroidManifest.xml)

## Accomplishments

- Alle vier Phase 8 runtime-deps toegevoegd aan pubspec.yaml met correcte versies; flutter pub get geslaagd zonder versieconflicten
- AndroidManifest.xml uitgebreid met vijf permissies (RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM, POST_NOTIFICATIONS, FOREGROUND_SERVICE, WAKE_LOCK), WorkManager service/receiver, en notificatiekanaal meta-data
- dart analyze lib/ meldt geen nieuwe fouten na alle wijzigingen

## Task Commits

Elke taak atomisch gecommit:

1. **Task 1: Voeg vier runtime-deps toe aan pubspec.yaml** - `b8f6791` (chore)
2. **Task 2: Update AndroidManifest.xml met permissies en WorkManager-entries** - `4a2bbb1` (chore)

## Files Created/Modified

- `pubspec.yaml` - Vier nieuwe Phase 8 runtime-deps toegevoegd onder "# Phase 8 — Achtergrond + Notificaties" commentaar
- `pubspec.lock` - Bijgewerkt door flutter pub get; 13 nieuwe packages opgelost
- `android/app/src/main/AndroidManifest.xml` - Vijf permissies, WorkManager service + receiver, notificatiekanaal meta-data

## Decisions Made

Geen nieuwe beslissingen — plan volledig gevolgd conform D-08-01 t/m D-08-07 uit 08-CONTEXT.md.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - geen externe service-configuratie vereist.

## Next Phase Readiness

- pubspec.yaml en AndroidManifest.xml klaar als fundering voor Phase 8 plannen 02–04
- Plan 08-02 kan WorkManager background worker implementeren (workmanager package nu beschikbaar)
- Plan 08-03 kan NotificationService implementeren (flutter_local_notifications + timezone nu beschikbaar)
- Blocker nog steeds actief: Samsung/Xiaomi fysiek apparaat vereist voor volledige WorkManager OEM-betrouwbaarheidstests (gedocumenteerd in STATE.md)

## Self-Check

- [x] pubspec.yaml bevat alle vier deps: grep bevestigt count=4
- [x] flutter pub get geslaagd: 13 nieuwe packages opgelost, geen conflicten
- [x] AndroidManifest.xml bevat alle vereiste entries: grep count=4 voor kritische keys
- [x] dart analyze lib/: "No issues found!"
- [x] Commits aanwezig: b8f6791 (Task 1), 4a2bbb1 (Task 2)

## Self-Check: PASSED

---
*Phase: 08-background-refresh-notifications*
*Completed: 2026-06-03*
