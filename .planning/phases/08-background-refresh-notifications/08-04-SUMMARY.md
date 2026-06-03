---
phase: 08-background-refresh-notifications
plan: "04"
subsystem: ui
tags: [notifications, profile, home, lifecycle]
dependency_graph:
  requires: [08-03]
  provides: [NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05, NOTIF-06]
  affects: [lib/features/profile/profile_screen.dart, lib/features/home/home_screen.dart]
tech_stack:
  added: []
  patterns: [SwitchListTile, WidgetsBindingObserver, AsyncValue.when]
key_files:
  modified:
    - lib/features/profile/profile_screen.dart
    - lib/features/home/home_screen.dart
decisions:
  - "08-04: NOTIFICATIES sectie geplaatst NA LOCATIE en VOOR THEMA in ProfileScreen ListView"
  - "08-04: _scheduleNotificationsIfPermitted() als hulpmethode op _ProfileScreenState — niet als provider"
  - "08-04: lastRefreshedAsync doorgegeven als parameter aan _buildHeader() voor expliciete dataflow"
  - "08-04: WidgetsBindingObserver naast SingleTickerProviderStateMixin via with-clausule"
metrics:
  duration: "~5 min"
  completed: "2026-06-03"
  tasks: 2
  files: 2
---

# Phase 08 Plan 04: UI — NOTIFICATIES sectie + lastRefreshed header Summary

**One-liner:** NOTIFICATIES sectie met drie SwitchListTile-toggles toegevoegd aan ProfileScreen; HomeScreen header toont 'Bijgewerkt: HH:mm' met foreground-resume refresh via WidgetsBindingObserver.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Voeg NOTIFICATIES sectie toe aan ProfileScreen | 1468db3 | lib/features/profile/profile_screen.dart |
| 2 | Voeg lastRefreshed header + WidgetsBindingObserver toe aan HomeScreen | 2169ed1 | lib/features/home/home_screen.dart |

## What Was Built

### Task 1: ProfileScreen NOTIFICATIES sectie

- Importeert `NotificationService` uit `lib/platform/notification_service.dart`
- `_notifService` instantie als veld van `_ProfileScreenState`
- `_scheduleNotificationsIfPermitted()` hulpmethode: vraagt `POST_NOTIFICATIONS` op en toont SnackBar met Instellingen-actie als `SCHEDULE_EXACT_ALARM` niet beschikbaar is
- Drie `SwitchListTile` widgets na de LOCATIE sectie (vóór THEMA):
  - Avond van tevoren → `setNotifEveningBefore()`
  - Ochtend van de dag → `setNotifMorningOf()`
  - Wekelijks overzicht → `setNotifWeeklyDigest()`
- Elke toggle heeft `if (v && context.mounted)` guard vóór de async call (T-08-04-01 mitigatie)

### Task 2: HomeScreen lastRefreshed + WidgetsBindingObserver

- Importeert `lastRefreshedProvider` uit `lib/providers/last_refreshed_provider.dart`
- `WidgetsBindingObserver` toegevoegd aan `_HomeScreenState` via `with`-clausule
- `addObserver(this)` in `initState()`, `removeObserver(this)` in `dispose()` (T-08-04-02 mitigatie)
- `didChangeAppLifecycleState()` roept `lastRefreshedProvider.notifier.refresh()` aan bij `AppLifecycleState.resumed`
- `_buildHeader()` accepteert `AsyncValue<DateTime?>` parameter en toont:
  - `'Bijgewerkt: HH:mm'` wanneer timestamp bekend
  - `'Bijgewerkt: —'` bij loading, error of null

## Deviations from Plan

None — plan executed exactly as written.

## Threat Mitigations Applied

| Threat-ID | Mitigatie | Status |
|-----------|-----------|--------|
| T-08-04-01 | `if (v && context.mounted)` guard vóór elke async notificatie-call | Toegepast |
| T-08-04-02 | `removeObserver(this)` in `dispose()` vóór `super.dispose()` | Toegepast |
| T-08-04-03 | lastRefreshed toont alleen HH:mm — geen PII | Geaccepteerd |

## Known Stubs

None — alle data is live via providers.

## Threat Flags

None.

## Self-Check: PASSED

- `lib/features/profile/profile_screen.dart` aanwezig: FOUND
- `lib/features/home/home_screen.dart` aanwezig: FOUND
- Commit 1468db3: FOUND
- Commit 2169ed1: FOUND
- `dart analyze` beide bestanden: geen fouten
