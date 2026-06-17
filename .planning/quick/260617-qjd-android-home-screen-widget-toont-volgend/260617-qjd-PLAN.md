---
phase: quick
plan: 260617-qjd
type: execute
wave: 1
depends_on: []
files_modified:
  - pubspec.yaml
  - android/app/src/main/AndroidManifest.xml
  - android/app/src/main/res/xml/ride_widget_info.xml
  - android/app/src/main/res/layout/ride_widget.xml
  - android/app/src/main/kotlin/ridewindow/joost/amsterdam/RideWidgetProvider.kt
  - lib/services/widget_update_service.dart
  - lib/providers/slots_notifier.dart
autonomous: true
requirements: [BACKLOG-01]

must_haves:
  truths:
    - "User can add 'RideWindow' widget to their Android home screen"
    - "Widget shows next best ride slot: date, time window, duration, and tier label (Perfect / Great / Acceptable)"
    - "Widget shows 'Geen slot gevonden' when no slots are available"
    - "Widget updates automatically after each WorkManager weather refresh"
    - "Tapping the widget opens the app to the Home screen"
  artifacts:
    - path: "android/app/src/main/kotlin/ridewindow/joost/amsterdam/RideWidgetProvider.kt"
      provides: "AppWidgetProvider that reads SharedPreferences data written by Flutter and updates RemoteViews"
    - path: "android/app/src/main/res/xml/ride_widget_info.xml"
      provides: "AppWidget metadata (min size, update period, preview)"
    - path: "android/app/src/main/res/layout/ride_widget.xml"
      provides: "Widget RemoteViews XML layout"
    - path: "lib/services/widget_update_service.dart"
      provides: "Dart class that serialises next slot to SharedPreferences via home_widget package"
  key_links:
    - from: "lib/providers/slots_notifier.dart"
      to: "lib/services/widget_update_service.dart"
      via: "SlotsNotifier listener or WorkManager callback calls WidgetUpdateService.update(slot)"
    - from: "lib/services/widget_update_service.dart"
      to: "android/.../RideWidgetProvider.kt"
      via: "home_widget SharedPreferences channel (HomeWidget.saveWidgetData)"
    - from: "AndroidManifest.xml"
      to: "RideWidgetProvider.kt"
      via: "receiver declaration with android.appwidget.action.APPWIDGET_UPDATE intent"
---

<objective>
Add an Android home screen widget that shows the next best ride slot at a glance — date, time window, duration, and quality tier — so a user can check rideability without opening the app.

Purpose: Backlog item #1 — highest user-value feature for casual cyclists. Zero-friction check: widget on home screen surfaces the most important output of the app (the next bookable slot) without any interaction.

Output: A 4×1 Android AppWidget registered in the manifest, driven by a Kotlin AppWidgetProvider that reads slot data from SharedPreferences via the `home_widget` Flutter package, updated after every WorkManager weather refresh.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/PROJECT.md

Key decisions from STATE.md that constrain this task:
- applicationId = ridewindow.joost.amsterdam (permanent — Kotlin package path must match)
- WorkManager periodic refresh already runs via workmanager ^0.9.0+3 (Phase 8)
- No backend — all data is local (SharedPreferences / Drift)
- shared_preferences ^2.5.5 already in pubspec
- RideSlot has: start (DateTime), end (DateTime), overallScore (double), tier (RideTier sealed class), hours (List<HourlyScore>)
- RideTier sealed: Perfect | Great | Acceptable | Poor (Poor slots are excluded from slotsProvider output)
- SlotsNotifier emits SlotsLoaded(slots, reason?) — slots is List<RideSlot>, may be empty with SlotsEmptyReason

<interfaces>
From lib/domain/models/ride_slot.dart:
```dart
@freezed
abstract class RideSlot with _$RideSlot {
  const factory RideSlot({
    required DateTime start,   // inclusive
    required DateTime end,     // exclusive [start, end)
    required double overallScore,
    required RideTier tier,
    required List<HourlyScore> hours,
  }) = _RideSlot;
}
```

From lib/providers/slots_notifier.dart:
```dart
sealed class SlotsState { const SlotsState(); }
final class SlotsLoaded extends SlotsState {
  final List<RideSlot> slots;
  final SlotsEmptyReason? reason;
  const SlotsLoaded(this.slots, {this.reason});
}
enum SlotsEmptyReason { badWeather, allBlocked }
// generated provider name: slotsProvider
```

From lib/domain/models/ride_tier.dart:
```dart
sealed class RideTier { const RideTier(); }
final class Perfect extends RideTier { const Perfect(); }
final class Great extends RideTier { const Great(); }
final class Acceptable extends RideTier { const Acceptable(); }
final class Poor extends RideTier { const Poor(); }
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add home_widget package and create WidgetUpdateService</name>
  <files>pubspec.yaml, lib/services/widget_update_service.dart</files>
  <action>
Add `home_widget: ^2.0.1` to pubspec.yaml under dependencies (after `share_plus`). Run `flutter pub get`.

Create `lib/services/widget_update_service.dart`:

- Import `home_widget` and the domain models.
- Define a static class `WidgetUpdateService` with a single static async method `update(RideSlot? nextSlot)`.
- When `nextSlot` is non-null:
  - Compute duration in whole hours: `nextSlot.end.difference(nextSlot.start).inHours`.
  - Format date as short Dutch weekday + day+month: e.g. "za 21 jun" — use `DateFormat('EEE d MMM', 'nl_NL')` from `intl` package. Check if `intl` is already in pubspec; if not, add `intl: ^0.19.0`.
  - Format time window as "HH:mm–HH:mm" using `DateFormat('HH:mm')`.
  - Map tier to label string: Perfect→"Perfect", Great→"Geweldig", Acceptable→"Acceptabel".
  - Call `HomeWidget.saveWidgetData<String>('slot_date', dateStr)`, same for `slot_time` (time window), `slot_duration` (`"${durationH}u"`), `slot_tier` (tier label).
  - Call `HomeWidget.saveWidgetData<bool>('slot_available', true)`.
- When `nextSlot` is null:
  - Call `HomeWidget.saveWidgetData<bool>('slot_available', false)`.
- After saving all data, call `HomeWidget.updateWidget(androidName: 'RideWidgetProvider')` to trigger a RemoteViews refresh.

The method must be safe to call from both the main isolate (via a provider listener) and the WorkManager isolate (where Riverpod is not available — pass null or a plain RideSlot value directly).
  </action>
  <verify>
    <automated>flutter pub get && flutter analyze lib/services/widget_update_service.dart</automated>
  </verify>
  <done>home_widget in pubspec.lock, WidgetUpdateService.update() compiles without errors, static analysis passes.</done>
</task>

<task type="auto">
  <name>Task 2: Create Android widget layout, metadata, and AppWidgetProvider</name>
  <files>
    android/app/src/main/res/xml/ride_widget_info.xml,
    android/app/src/main/res/layout/ride_widget.xml,
    android/app/src/main/kotlin/ridewindow/joost/amsterdam/RideWidgetProvider.kt,
    android/app/src/main/AndroidManifest.xml
  </files>
  <action>
**1. android/app/src/main/res/xml/ride_widget_info.xml**

Create the `xml/` subdirectory. Write AppWidget metadata:
- `android:minWidth="250dp"` `android:minHeight="40dp"` — fits a 4×1 cell on most launchers.
- `android:updatePeriodMillis="0"` — updates are pushed by WorkManager, not polled.
- `android:initialLayout="@layout/ride_widget"`.
- `android:widgetCategory="home_screen"`.

**2. android/app/src/main/res/layout/ride_widget.xml**

Widget layout using `RelativeLayout` root (required for RemoteViews compatibility — no ConstraintLayout):
- Background: `@android:color/holo_green_dark` with `android:padding="8dp"`.
- `TextView` id `@+id/widget_date` — top-left, small font, white text, bold.
- `TextView` id `@+id/widget_time` — below date, larger font (16sp), white.
- `TextView` id `@+id/widget_duration` — right of widget_time or below, small grey/white.
- `TextView` id `@+id/widget_tier` — bottom-right corner, white, small caps style.
- `TextView` id `@+id/widget_empty` — centered, white, visibility GONE by default. Text: "Geen slot gevonden".

All TextViews must be separate ids — the Kotlin provider sets each individually.

**3. android/app/src/main/kotlin/ridewindow/joost/amsterdam/RideWidgetProvider.kt**

Create `kotlin/ridewindow/joost/amsterdam/` directories. Write a Kotlin class `RideWidgetProvider` extending `AppWidgetProvider`:

```
package ridewindow.joost.amsterdam

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
```

In `onUpdate()`:
- Read SharedPreferences via `context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)`.
- home_widget stores keys with a `flutter.` prefix. Read:
  - `flutter.slot_available` (Boolean, default false)
  - `flutter.slot_date` (String?)
  - `flutter.slot_time` (String?)
  - `flutter.slot_duration` (String?)
  - `flutter.slot_tier` (String?)
- Create `RemoteViews(context.packageName, R.layout.ride_widget)`.
- If `slotAvailable`:
  - Set `widget_date`, `widget_time`, `widget_duration`, `widget_tier` text.
  - Set `widget_empty` visibility to `View.GONE`.
- Else:
  - Set `widget_empty` visibility to `View.VISIBLE`.
  - Set date/time/duration/tier to empty string.
- Create a tap `PendingIntent` that opens `MainActivity`:
  ```kotlin
  val intent = Intent(context, MainActivity::class.java).apply {
      flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
  }
  val pendingIntent = PendingIntent.getActivity(
      context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
  )
  views.setOnClickPendingIntent(R.id.widget_root_layout, pendingIntent)
  ```
  Give the root `RelativeLayout` the id `@+id/widget_root_layout` in the XML (add it in step 2).
- Call `appWidgetManager.updateAppWidget(appWidgetId, views)` for each id in the loop.

**4. android/app/src/main/AndroidManifest.xml**

Add inside `<application>`:
```xml
<receiver
    android:name=".RideWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/ride_widget_info" />
</receiver>
```

Do not add a new `<uses-permission>` — no extra permissions needed for AppWidget.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter build apk --debug 2>&1 | tail -20</automated>
  </verify>
  <done>Debug APK builds without errors. RideWidgetProvider.kt, ride_widget.xml, ride_widget_info.xml, and manifest receiver are all in place.</done>
</task>

<task type="auto">
  <name>Task 3: Wire WidgetUpdateService into WorkManager callback and SlotsNotifier listener</name>
  <files>lib/services/background_service.dart, lib/app/app.dart, lib/main.dart</files>
  <action>
There are two update triggers: WorkManager background refresh and foreground slot changes. Both must call `WidgetUpdateService.update()`.

**A. WorkManager callback (background isolate)**

Locate the file that contains the WorkManager `callbackDispatcher` function (likely `lib/services/background_service.dart` or `lib/main.dart` — grep for `callbackDispatcher` or `Workmanager().executeTask`).

At the end of the successful weather fetch path — after writing to Drift — retrieve the next slot and call `WidgetUpdateService.update(nextSlot)`.

Because the WorkManager isolate has no Riverpod, query Drift directly:
- Open `AppDatabase` with `driftDatabase(name: 'ridewindow')` (same pattern as 08-02 decision).
- Read cached `HourlyForecast` rows for the next 7 days.
- Run `SlotGenerator` + `ScoringEngine` + `AvailabilityFilter` with the stored availability pattern from SharedPreferences.
- Take `slots.firstOrNull` as nextSlot (or null if empty).
- Call `await WidgetUpdateService.update(nextSlot)`.

If this Drift query adds too much complexity to the background isolate, use a simpler fallback: read the last-cached slot from SharedPreferences directly (if it was stored there by the foreground path). In that case, the background isolate only calls `HomeWidget.updateWidget(androidName: 'RideWidgetProvider')` to refresh the display without recomputing slots, and the foreground path (B) handles the data write.

**B. Foreground provider listener**

Locate the root widget or `app.dart` where `ProviderScope` is set up. Add a `ref.listen` on `slotsProvider` (or equivalent `slotsProvider` — generated name confirmed in STATE.md as `slotsProvider`):

```dart
ref.listen<SlotsState>(slotsProvider, (_, next) {
  if (next is SlotsLoaded) {
    final slot = next.slots.firstOrNull;
    WidgetUpdateService.update(slot);
  }
});
```

Place this `ref.listen` inside a `ConsumerWidget` or `ConsumerStatefulWidget` build/initState that is always alive (e.g. the root `App` widget or `HomeScreen`).

Run `flutter analyze lib/` to confirm no new errors.
  </action>
  <verify>
    <automated>flutter analyze lib/ 2>&1 | grep -v "^Analyzing" | grep -v "^No issues"</automated>
  </verify>
  <done>flutter analyze reports no errors on the wired files. WidgetUpdateService.update() is called from both WorkManager callback and foreground slot listener. Debug build still succeeds.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Flutter→Android | Slot data crosses process boundary via SharedPreferences (home_widget channel) |
| Widget tap→MainActivity | PendingIntent opens app from launcher context |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-QJD-01 | Information Disclosure | SharedPreferences slot data | accept | Data is non-sensitive weather/schedule info; no PII stored in widget keys |
| T-QJD-02 | Tampering | RideWidgetProvider reads SharedPreferences | mitigate | Keys are namespaced under `flutter.` prefix by home_widget; read-only from Kotlin side; no user-writable surface |
| T-QJD-03 | Elevation of Privilege | PendingIntent FLAG_IMMUTABLE | mitigate | PendingIntent created with FLAG_IMMUTABLE (required Android 12+) to prevent intent hijacking |
| T-QJD-SC | Tampering | home_widget package install | mitigate | home_widget is a well-known Flutter community package (pub.dev verified, 1k+ likes); confirm on pub.dev before running flutter pub get |
</threat_model>

<verification>
1. Install debug APK on Android device/emulator.
2. Long-press home screen → Widgets → search "RideWindow" — widget should appear.
3. Add widget. Verify it shows next slot data (or "Geen slot gevonden" if no slots).
4. Kill app, wait for WorkManager interval or trigger via `adb shell am broadcast -a androidx.work.diagnostics.REQUEST_DIAGNOSTICS` — widget should refresh.
5. Tap widget — app should open to Home screen.
</verification>

<success_criteria>
- Widget appears in Android launcher widget picker under the name "RideWindow".
- Widget displays: date, time window (HH:mm–HH:mm), duration (Xu), tier label.
- Widget shows "Geen slot gevonden" when slotsProvider returns empty list.
- Tapping the widget opens MainActivity.
- WidgetUpdateService.update() is called from both WorkManager isolate path and foreground slotsProvider listener.
- flutter analyze reports zero new errors.
- Debug APK builds successfully.
</success_criteria>

<output>
Create `.planning/quick/260617-qjd-android-home-screen-widget-toont-volgend/260617-qjd-SUMMARY.md` when done.
</output>
