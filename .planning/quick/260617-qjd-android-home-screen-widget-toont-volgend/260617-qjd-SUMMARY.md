---
phase: quick
plan: 260617-qjd
subsystem: widget
tags: [android, home-screen-widget, home_widget, kotlin, appwidget]
dependency_graph:
  requires: [slots_notifier, background_task, shared_preferences]
  provides: [home-screen-widget, WidgetUpdateService]
  affects: [main.dart, background_task.dart, AndroidManifest.xml]
tech_stack:
  added: [home_widget ^0.9.3, intl ^0.19.0]
  patterns: [AppWidgetProvider, RemoteViews, home_widget SharedPreferences bridge]
key_files:
  created:
    - lib/services/widget_update_service.dart
    - android/app/src/main/kotlin/com/fanalists/ridewindow/ridewindow/RideWidgetProvider.kt
    - android/app/src/main/res/layout/ride_widget.xml
    - android/app/src/main/res/xml/ride_widget_info.xml
  modified:
    - pubspec.yaml
    - pubspec.lock
    - android/app/src/main/AndroidManifest.xml
    - lib/main.dart
    - lib/platform/background_task.dart
decisions:
  - home_widget ^0.9.3 used — plan specified ^2.0.1 which does not exist on pub.dev (latest stable is 0.9.3)
  - RideWidgetProvider placed in com.fanalists.ridewindow.ridewindow package to match Gradle namespace for R class resolution
  - AndroidManifest receiver uses fully qualified class name because namespace != applicationId
  - WidgetUpdateService uses qualifiedAndroidName in HomeWidget.updateWidget() for same reason
  - Background task computes next slot with pure-Dart domain services (isolate-safe, no Riverpod)
  - Widget update errors in WorkManager callback are swallowed — widget is non-critical, task success must be preserved
metrics:
  duration: ~25min
  completed: 2026-06-17
  tasks: 3
  files_created: 4
  files_modified: 5
---

# Quick Task 260617-qjd: Android Home Screen Widget Summary

**One-liner:** AppWidget showing next ride slot (date, time, duration, tier) via home_widget SharedPreferences bridge, updated from both WorkManager background refresh and foreground slotsProvider listener.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Add home_widget package, create WidgetUpdateService | 95cea60 | pubspec.yaml, lib/services/widget_update_service.dart |
| 2 | Android widget layout, metadata, AppWidgetProvider | 4075898 | RideWidgetProvider.kt, ride_widget.xml, ride_widget_info.xml, AndroidManifest.xml |
| 3 | Wire into WorkManager + slotsProvider listener | 2691d59 | lib/platform/background_task.dart, lib/main.dart |

## What Was Built

A complete 4x1 Android home screen widget that:

1. Shows next best ride slot: Dutch weekday+date ("za 21 jun"), time window ("09:00–13:00"), duration ("4u"), and tier label ("Perfect" / "Geweldig" / "Acceptabel")
2. Shows "Geen slot gevonden" when no slots are available
3. Tapping the widget opens MainActivity via FLAG_IMMUTABLE PendingIntent (T-QJD-03 mitigated)
4. Updates via two paths:
   - Foreground: `ref.listen(slotsProvider)` in `RideWindowApp.build()` calls `WidgetUpdateService.update(slot)` on every slot change
   - Background: WorkManager callback computes next slot using pure-Dart domain services and calls `WidgetUpdateService.update(nextSlot)` after each weather refresh

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] home_widget version ^2.0.1 does not exist**
- **Found during:** Task 1
- **Issue:** Plan specified `home_widget: ^2.0.1` but pub.dev shows only versions up to `0.9.3`
- **Fix:** Used `home_widget: ^0.9.3` (latest stable). API is fully compatible with the plan's usage pattern (`saveWidgetData`, `updateWidget`)
- **Files modified:** pubspec.yaml

**2. [Rule 1 - Bug] R class unresolved — wrong Kotlin package**
- **Found during:** Task 2 build
- **Issue:** Plan specified package `ridewindow.joost.amsterdam` for `RideWidgetProvider.kt` but the Gradle namespace is `com.fanalists.ridewindow.ridewindow` (where the R class is generated). `applicationId = ridewindow.joost.amsterdam` is only the Play Store ID.
- **Fix:** Placed `RideWidgetProvider.kt` in `com/fanalists/ridewindow/ridewindow/` with `package com.fanalists.ridewindow.ridewindow`
- **Files modified:** RideWidgetProvider.kt location + package declaration

**3. [Rule 1 - Bug] androidName in updateWidget() resolves to wrong class**
- **Found during:** Task 2 analysis
- **Issue:** `HomeWidget.updateWidget(androidName: 'RideWidgetProvider')` constructs class name as `"${context.packageName}.RideWidgetProvider"` = `"ridewindow.joost.amsterdam.RideWidgetProvider"` at runtime — which does not match the actual class `com.fanalists.ridewindow.ridewindow.RideWidgetProvider`
- **Fix:** Used `qualifiedAndroidName: 'com.fanalists.ridewindow.ridewindow.RideWidgetProvider'` instead
- **Files modified:** lib/services/widget_update_service.dart

**4. [Rule 1 - Bug] Intent.flags assignment inside apply{} block failed to compile**
- **Found during:** Task 2 build
- **Issue:** `flags = Intent.FLAG_ACTIVITY_NEW_TASK or ...` inside `apply{}` block caused "Unresolved reference: flags" error in Kotlin
- **Fix:** Replaced with `launchIntent.addFlags(...)` outside the apply block
- **Files modified:** RideWidgetProvider.kt

## Known Stubs

None — the widget displays live data from SharedPreferences written by `WidgetUpdateService`.

## Threat Surface Scan

All threats from the plan's threat model are addressed:
- **T-QJD-02:** `flutter.` key namespace enforced by home_widget; Kotlin side is read-only
- **T-QJD-03:** `PendingIntent.FLAG_IMMUTABLE` applied in `RideWidgetProvider.kt` (line 51)
- **T-QJD-SC:** home_widget 0.9.3 verified on pub.dev before install

## Self-Check

### Created files exist:
- lib/services/widget_update_service.dart: FOUND
- android/app/src/main/kotlin/com/fanalists/ridewindow/ridewindow/RideWidgetProvider.kt: FOUND
- android/app/src/main/res/layout/ride_widget.xml: FOUND
- android/app/src/main/res/xml/ride_widget_info.xml: FOUND

### Commits exist:
- 95cea60: FOUND (Task 1)
- 4075898: FOUND (Task 2)
- 2691d59: FOUND (Task 3)

### Build status: debug APK builds successfully (verified after each task)

## Self-Check: PASSED
