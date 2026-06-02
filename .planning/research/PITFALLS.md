# Pitfalls Research

**Domain:** Flutter Android cycling weather app (solo dev, first Play Store ship)
**Researched:** 2026-06-01
**Confidence:** HIGH for Flutter/Android pitfalls (multiple verified sources); MEDIUM for scoring/API edge cases (verified with Open-Meteo docs + community issues); HIGH for Play Store go-to-market pitfalls (verified with official Play Console docs)

---

## Critical Pitfalls

### Pitfall 1: setState() Called After Async Operation on Disposed Widget

**What goes wrong:**
An async operation (e.g., fetching weather from Open-Meteo) completes after the user has navigated away from the screen. The code calls `setState()` on the now-disposed widget, throwing a runtime exception: `setState() called after dispose()`. In debug mode this surfaces as a red screen; in release mode it silently fails or crashes.

**Why it happens:**
Flutter's `StatefulWidget` lifecycle does not cancel in-flight Futures. Any `await` point is a place where the widget may have been removed from the tree between the call and the resumption.

**How to avoid:**
Check `mounted` before every `setState()` call that follows an `await`. Pattern:
```dart
final data = await fetchWeather();
if (!mounted) return;
setState(() { _weatherData = data; });
```
For Riverpod/Provider users: async notifiers handle this automatically; prefer them over manual `setState` in screens that make API calls.

**Warning signs:**
- `FlutterError: setState() called after dispose()` in debug logs
- Weather screen momentarily shows data then disappears when navigating quickly

**Phase to address:** Phase 1 (project setup) — add `mounted` checks as a code convention from day one. Reinforce in Phase 3 (weather/scoring engine) where async fetch is implemented.

---

### Pitfall 2: Hot Reload Masks initState / Static Variable Bugs

**What goes wrong:**
Hot reload preserves app state — it does NOT rerun `main()` or `initState()`. If you change initialization logic (default slider values, scoring weights, Hive box opening logic), the running app keeps the old values. You ship code that "worked in dev" but fails on a cold install because the initialization path was never actually exercised during development.

**Why it happens:**
Flutter's hot reload patches Dart code in the VM and rebuilds the widget tree, but it does not reset static fields, singletons, or `initState()` bodies. Global variables changed in source are not reinitialized.

**How to avoid:**
- Use **hot restart** (not hot reload) whenever you change: `initState()`, `Hive.openBox()` calls, default values of stored settings, singleton constructors, or WorkManager registration.
- Write an explicit unit test for the cold-start initialization path.
- Add `// HOT RESTART REQUIRED` comments above initialization functions as a reminder.

**Warning signs:**
- "Works on my device" but crashes on a clean install
- Scoring sliders reset to wrong defaults after a clean uninstall/reinstall
- Hive boxes appear empty on first launch of a published build

**Phase to address:** Phase 1 (project setup) — document hot reload vs. hot restart distinction in dev notes. Phase 5 (persistence) — always test Hive initialization with a clean uninstall.

---

### Pitfall 3: Open-Meteo Timezone Mismatch Corrupts Ride Slot Times

**What goes wrong:**
Open-Meteo defaults to returning timestamps in **GMT**. If the request omits `timezone=auto` (or the correct IANA timezone), all 168 hourly timestamps are UTC. The scoring engine happily processes them, but the resulting "ride slots" are hours off. A user in Amsterdam (UTC+2 in summer) sees "Saturday 07:00–11:00" when the actual local window is "Saturday 09:00–13:00". The score may also be wrong because the temperature/wind at 05:00 UTC (07:00 CEST) does not match midday conditions.

**Why it happens:**
Open-Meteo's `timezone` parameter is optional and defaults to GMT. Developers testing in UTC (common on CI, cloud environments, or developer machines set to UTC) never notice the offset. The bug only appears when users are in a non-UTC timezone — i.e., always in production for a Dutch app.

**How to avoid:**
- Always pass `timezone=auto` in every Open-Meteo request. The API resolves coordinates to their local timezone automatically.
- Alternatively, pass the IANA timezone string derived from the device: `DateTime.now().timeZoneName` is insufficient (returns abbreviation like "CEST") — use the `timezone` Dart package to get a proper IANA string.
- Internally store all timestamps as **UTC epoch seconds** (use `unixtime` format from Open-Meteo). Convert to local time only at the display layer.
- Unit test: assert that a coordinate in Amsterdam at 08:00 local time maps to hour index 6 (not 8) when UTC is used without correction.

**Warning signs:**
- Ride slots shown are consistently offset by the user's UTC offset (e.g., always 2h early in CEST)
- DST transition days show 25 or 23 valid hours instead of 24

**Phase to address:** Phase 3 (weather fetch + scoring engine) — enforce timezone parameter in the HTTP client layer, not in individual call sites.

---

### Pitfall 4: Weather Scoring NaN / Null Propagation Produces Silent Wrong Scores

**What goes wrong:**
Open-Meteo returns `null` for some weather variables when model data is unavailable (e.g., precipitation probability may be missing for some forecast models, or wind gusts near coastlines). If the scoring engine divides by or multiplies a `null` value without guarding, Dart throws a `Null check operator used on a null value` exception. Worse, if the null is coerced to 0 before the guard, precipitation probability of `null` becomes "0% rain" — the slot scores as perfect when data is actually missing.

**Why it happens:**
Open-Meteo's JSON has nullable fields. Dart's type system helps only if you model the response with proper nullable types. Auto-generated or hand-written JSON deserialization that uses `as double` (non-nullable cast) will throw at runtime; using `as double?` without null handling silently propagates null as 0.

**How to avoid:**
- Model every Open-Meteo response field as nullable (`double?`, `int?`).
- In the scoring engine, treat null as "data unavailable" — either skip the slot entirely or clamp the sub-score to a defined "uncertain" value (e.g., 50/100) and surface an "Incomplete data" indicator in the UI.
- Write unit tests with partial Open-Meteo responses (some fields null) to verify the scoring engine does not crash and produces a marked-uncertain result.

**Warning signs:**
- A slot scores 100/100 despite a storm forecast (precipitation null → 0 → "no rain")
- Dart runtime exception `Null check operator used on a null value` in scoring code
- `double.nan` propagating into the score display

**Phase to address:** Phase 3 (weather fetch + scoring engine) — define the nullable response model and null-handling policy before writing the scoring function.

---

### Pitfall 5: Off-by-One Hour Errors in Slot Boundary Detection

**What goes wrong:**
The slot generator finds contiguous "good" hours and creates a slot from `startHour` to `endHour`. An off-by-one in the index iteration includes a marginal hour at the boundary (e.g., 19:00 with rain starting) or excludes the last valid hour. A 4-hour ride slot becomes 3h or 5h. The user taps "Add to Calendar" and the event duration is wrong.

**Why it happens:**
The hourly array is 0-indexed (index 0 = midnight). Contiguous-run algorithms require careful handling of inclusive vs. exclusive end indices. Developers often write `endIndex` to mean "last good index" in some places and "first bad index" in others — mixing conventions silently.

**How to avoid:**
- Define and document a single convention: `slotEnd` is **exclusive** (open interval `[start, end)`), consistent with Dart's `DateTime` arithmetic.
- Write property-based tests: for N consecutive "good" hours, assert the slot duration equals exactly N hours.
- Test the edge case where the last hour of the 7-day forecast is "good" — no out-of-bounds.

**Warning signs:**
- Slots shown as "3h" but calendar event spans 4 hours
- App crashes with `RangeError` on the last day of the forecast
- Slots starting or ending at midnight include the wrong day

**Phase to address:** Phase 3 (scoring engine + slot generation) — include boundary unit tests as acceptance criteria.

---

### Pitfall 6: WorkManager Background Refresh Silently Fails on OEM-Skinned Android Devices

**What goes wrong:**
WorkManager correctly schedules periodic weather refreshes, and they run fine on stock Android (Pixel, emulator). On Xiaomi (MIUI), Samsung (One UI), Huawei, OPPO, and OnePlus devices — which represent the majority of Android market share — aggressive proprietary battery killers prevent WorkManager tasks from executing unless the user manually whitelists the app in "Battery optimization" or enables "Auto-start". The forecast shown is stale (potentially 12–24 hours old) with no visible error to the user.

**Why it happens:**
OEM Android skins add battery restrictions that go beyond AOSP Doze mode. These are not covered by standard Android APIs. WorkManager defers to them; it does not override them.

**How to avoid:**
- Use the `battery_plus` or `disable_battery_optimization` plugin to detect whether the app is battery-optimized and prompt the user to whitelist it. Show this prompt once during onboarding if background refresh is a core feature.
- Design the app so a **foreground pull-to-refresh** always works as the primary path. Background refresh is a "nice to have" enhancement, not a requirement for correctness.
- Show the forecast's `lastRefreshed` timestamp prominently. If data is >3 hours old, show a "Refresh now" nudge rather than silently displaying stale data.
- Set WorkManager constraints: `requiresNetwork: true`, `requiresCharging: false`. Do not use exact timing — use periodic work with a 3–6 hour interval (more lenient = more likely to actually execute).

**Warning signs:**
- Background refresh works perfectly on your Pixel dev device but testers on Samsung report stale data
- WorkManager `enqueue` returns success but callbacks never fire on Xiaomi
- `WorkInfo.State` is `ENQUEUED` indefinitely

**Phase to address:** Phase 6 (background refresh + notifications) — design the background work as best-effort from the start, never as guaranteed.

---

### Pitfall 7: Location Permission "Denied Forever" Not Reliably Detected

**What goes wrong:**
The `geolocator` plugin's `checkPermission()` returns `LocationPermission.denied` both when the user has denied once (re-request allowed) AND when they have denied with "Don't ask again" (re-request silently fails). Calling `requestPermission()` in the "denied forever" state does nothing — no dialog appears — but the app has no way to distinguish this from a first-time denial on some Android versions. The result: the app loops on a permission request that will never succeed, or silently falls back to a manual city picker without explaining why.

**Why it happens:**
Android's `shouldShowRequestPermissionRationale()` is the signal that distinguishes "denied once" from "denied forever," but the `geolocator` plugin does not expose this reliably across all Android versions. There are confirmed open bugs in the geolocator issue tracker for this exact scenario on Android 9, 10, and 11.

**How to avoid:**
- After a `requestPermission()` call that returns `denied`, attempt the request again once. If the second attempt also returns `denied` without showing a dialog (you can detect this by timing the response — if it returns near-instantly, no dialog was shown), assume "denied forever" and show a settings-deep-link dialog.
- Use `Geolocator.openAppSettings()` to send the user directly to app settings when "denied forever" is suspected.
- Always provide the manual city picker as a first-class alternative — never gate the entire app on GPS permission being granted.
- Test the full permission state machine: fresh install → grant, fresh install → deny → re-request, fresh install → deny → "don't ask again" → manual fallback.

**Warning signs:**
- On a device where GPS was denied with "Don't ask again," no dialog appears after calling `requestPermission()` but the app shows no error and no fallback
- Manual city picker is never shown even when GPS is permanently denied
- `LocationPermission.deniedForever` is only returned on some Android versions but not others

**Phase to address:** Phase 4 (location + onboarding) — implement the full permission state machine with the manual city picker fallback before any other location logic.

---

### Pitfall 8: Hive TypeAdapter Breaking Change on App Update

**What goes wrong:**
A Hive `TypeAdapter` is generated for `UserProfile` with field indices (e.g., `@HiveField(0)` = `windTolerance`, `@HiveField(1)` = `rainTolerance`). In a later version, you add `temperatureTolerance` as `@HiveField(1)` and shift `rainTolerance` to `@HiveField(2)`. Users who update the app find their stored preferences corrupted or the app crashes with a type cast error because old binary data maps field index 1 to the wrong type.

**Why it happens:**
Hive stores field values by index number, not by name. Adding a field at an existing index, removing a field, or reordering fields without incrementing the index breaks backward compatibility for all existing installations.

**How to avoid:**
- **Never reuse or reorder `@HiveField` index numbers.** Only append new fields with the next available index. Example: if fields 0, 1, 2 exist, a new field is always `@HiveField(3)`, even if field 1 was removed.
- Document the Hive field index registry in a comment at the top of every `@HiveType` class.
- For breaking schema changes, implement a migration: check a stored schema version number in `SharedPreferences` at app startup; if old, discard Hive data and re-run onboarding.
- Write an integration test that: saves a `UserProfile` with adapter v1, upgrades to adapter v2, and asserts the data loads without error.

**Warning signs:**
- `type 'int' is not a subtype of type 'String'` crash on app update
- User settings silently reset to defaults after update
- `HiveError: Cannot read, unknown typeId` on startup

**Phase to address:** Phase 5 (local persistence) — establish the field-index registry convention before writing any Hive model. Reinforce at every subsequent phase that adds a model field.

---

### Pitfall 9: Notification Exact Alarm Permission Breaks Scheduling on Android 12+

**What goes wrong:**
The app schedules "Evening before" and "Morning of" notifications using `flutter_local_notifications` with `AndroidScheduleMode.exactAllowWhileIdle`. On Android 12 (API 31) and above, this requires the `SCHEDULE_EXACT_ALARM` special permission, which users must grant through a separate system settings screen. If the permission is not requested and granted, the notification is silently not scheduled — no error is thrown, the plugin logs a warning that may be invisible in release builds.

On Android 14+, the `USE_EXACT_ALARM` alternative is available but may require Play Store approval. Samsung devices additionally cap Alarm Manager to 500 scheduled alarms; going over silently fails.

**Why it happens:**
Android 12 added the exact alarm permission as a battery-saving measure. It is not a runtime permission that can be requested with `requestPermission()` — it requires opening a specific system settings intent. Most tutorials and plugin documentation do not clearly call this out.

**How to avoid:**
- In the notifications setup phase, call `flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission()` which opens the system dialog.
- Check permission before scheduling: if `SCHEDULE_EXACT_ALARM` is not granted, fall back to `AndroidScheduleMode.inexact` and inform the user notifications may be slightly delayed.
- Add `SCHEDULE_EXACT_ALARM` to `AndroidManifest.xml`.
- Test on an API 31+ emulator or device with a fresh app install (permission is not granted by default).

**Warning signs:**
- Notifications work in debug on a Pixel (where exact alarms may already be allowed) but not on user devices
- `flutter_local_notifications` logs "Exact alarm permission not granted" with no UI feedback
- Testers report missing morning/evening notifications

**Phase to address:** Phase 6 (notifications) — implement and test the exact alarm permission request flow before implementing any notification scheduling logic.

---

### Pitfall 10: Google Calendar OAuth Token Not Persisted — User Re-Signs In on Every Launch

**What goes wrong:**
Google Sign-In via `google_sign_in` returns an access token (valid ~1 hour) but does NOT automatically return a refresh token for Android native OAuth without extra configuration. After the access token expires, the Calendar API call fails with a 401. The simplest fix — calling `signInSilently()` — only works if the user's Google session is active. If it isn't, the user must go through the OAuth consent screen again. This is especially jarring because "Add to Calendar" is triggered from a UI button and an unexpected re-auth dialog breaks the flow.

**Why it happens:**
The `google_sign_in` package handles token refresh silently only for the scope of Google Sign-In itself. When using the `googleapis` package to make Calendar API calls, you must wire the `GoogleSignIn` auth client to the API client explicitly, and `signInSilently()` must be called before making any API request. The `googleapis` package's `AutoRefreshingAuthClient` handles refresh automatically — but only if you initialize it correctly from `googleSignIn.currentUser?.authHeaders`.

**How to avoid:**
- Use `googleSignIn.signInSilently()` at app start if Calendar integration was previously authorized; cache the auth state in `SharedPreferences` or Hive.
- For the `googleapis` calendar client, always create the HTTP client via `clientViaUserConsent` or `authenticatedClient(http.Client(), AccessCredentials(...))` from the `googleapis_auth` package, which wraps automatic token refresh.
- Request only the minimum scope: `CalendarApi.calendarEventsScope` (`https://www.googleapis.com/auth/calendar.events`) — NOT the full calendar read scope. Requesting minimal scopes reduces OAuth consent friction and lowers rejection risk during Play review.
- Handle `PlatformException(sign_in_required)` at every Calendar API call site and re-trigger the sign-in flow gracefully.

**Warning signs:**
- "Add to Calendar" fails silently ~1 hour after the user first signed in
- `googleapis` throws `DetailedApiRequestError status 401` on Calendar insert
- `signInSilently()` returns null even when the user previously authorized

**Phase to address:** Phase 7 (Google Calendar integration) — design the auth state machine (not signed in → sign in → authorized → token refreshed → insert event) before writing any Calendar API code.

---

## Go-to-Market Pitfalls

### Pitfall 11: Signing Keystore Lost = App Dead (Cannot Update)

**What goes wrong:**
If the upload keystore file (`.jks`) and its password are lost, you cannot sign a new release build. Without a valid signature matching the original upload key, Google Play rejects the AAB. If you are NOT enrolled in Google Play App Signing, the app is permanently bricked — you must create a new app with a new package name and lose all existing installs. If you ARE enrolled in Play App Signing, Google can reset your upload key (takes 48–72h and requires a support request).

**Why it happens:**
Solo devs often generate the keystore quickly, store it in the project directory, and then lose it when a machine is replaced or a repo is cloned fresh (the keystore is in `.gitignore`). This is a single point of failure with no graceful recovery path outside of Play App Signing enrollment.

**How to avoid:**
- Enable **Google Play App Signing** when creating the app in Play Console — do this on the very first upload. Once enrolled, Google holds the App Signing Key; your upload key can be reset if lost.
- Store the keystore in at minimum two off-repository locations: a password manager (Bitwarden, 1Password) as a file attachment, and an encrypted backup drive.
- Store all keystore metadata (`key alias`, `key password`, `store password`) in the same password manager entry.
- Add a `key.properties` file to `.gitignore` and document the keystore backup location in a private note — not in the repo.

**Warning signs:**
- Keystore file only exists in the project's `android/` directory
- Keystore password is stored in a `.env` file in the repo (security risk AND fragile)
- Play Console shows "App Signing not enrolled" when you check app integrity settings

**Phase to address:** Phase 8 (release build + Play Console setup) — the very first task: create the keystore, enable Play App Signing, and back up credentials before writing a single line of build config.

---

### Pitfall 12: Data Safety Form Rejection Due to Incomplete Scope Declaration

**What goes wrong:**
Google Play rejects or flags the app because the Data Safety form does not fully declare all data accessed. Common mistakes: (1) Declaring that location data is "not collected" because it is not sent to a server — but Google's definition of "collection" includes any access by the app, even local-only. (2) Forgetting that the Google Sign-In SDK (used for Calendar OAuth) collects name, email, and Google account identifiers — these must be declared even if you never store them yourself.

As of late 2024, Google uses ML-assisted scanning to compare app runtime behavior against the Data Safety form and is actively rejecting apps where they don't match.

**Why it happens:**
The form's wording is ambiguous — "collect" means something different to Google than to developers. Solo devs fill it out quickly without reading the definitions, then get surprised by a policy violation notice after submission.

**How to avoid:**
- Read Google's Data Safety form guide in full before submission, specifically the definition of "collect" vs. "share."
- For this app, declare:
  - **Location (precise)**: collected, not shared with third parties, not used for tracking, purpose = "App functionality"
  - **Google Account info** (if Calendar integration is included): collected ephemerally, used only for authentication, not stored
- If using any analytics SDK (even Firebase Crashlytics), declare its data collection separately.
- After filling the form, use the "Preview" link to check how it appears to users.

**Warning signs:**
- App submission returns a policy violation notice about "data type mismatch"
- Play Console shows a yellow warning on the Data Safety section after submission
- You declared "No data collected" but the app requests `ACCESS_FINE_LOCATION`

**Phase to address:** Phase 8 (Play Console setup) — fill the Data Safety form before submitting any build, using the final `AndroidManifest.xml` permissions as the ground truth for what to declare.

---

### Pitfall 13: Production Access Gated Behind 12-Tester / 14-Day Closed Testing Requirement

**What goes wrong:**
For personal Google Play developer accounts created after November 13, 2023, you cannot move to open production without completing a closed testing phase with **at least 12 opted-in testers for 14 consecutive days**. If a tester opts out before the 14 days are up, their days do not count. Many first-time developers discover this gate only after building the app and trying to publish — causing a 2-week mandatory delay.

**Why it happens:**
Google introduced this requirement in 2023 to reduce low-quality and fraudulent apps. It applies only to personal accounts (not organization accounts). It is not prominently surfaced during account creation.

**How to avoid:**
- Check your Play Console account type. If personal and created after November 2023, plan for the 12-tester / 14-day closed testing gate.
- Start recruiting 12+ cyclist testers (friends, colleagues, cycling community) as early as week 1. Do not wait until the app is "done."
- Create the closed testing track in Play Console and invite testers as soon as you have a functional internal build (even a rough one) — the 14-day clock starts when testers opt in, not when you upload a polished release.
- The internal testing track (used for your own device testing) does NOT count toward the 12-tester requirement — closed testing is a separate track.

**Warning signs:**
- Play Console shows "Apply for production access" button is greyed out
- You have only 3–4 testers and the 14-day window is not complete
- You are discovering this requirement the day you want to publish

**Phase to address:** Phase 1 (planning) — recruit testers during project setup. Phase 8 (release) — open the closed testing track at least 3 weeks before you want production access.

---

### Pitfall 14: Privacy Policy Link Broken or Missing at Submission Time

**What goes wrong:**
Google Play requires a privacy policy URL for any app that accesses location data. If the privacy policy page is down, returns a 404, requires a login, or is not in a language Google's review system can read, the submission is rejected. This is the #1 reason new apps are rejected on first submission. A privacy policy hosted on a free tier service that goes down (Notion, Google Sites with incorrect sharing, a personal server) is a common failure mode.

**Why it happens:**
Privacy policy is often an afterthought — written quickly, hosted haphazardly, and not tested end-to-end before submission.

**How to avoid:**
- Host the privacy policy on a stable, always-on URL. GitHub Pages (`https://username.github.io/ridewindow-privacy`) is free, reliable, and survives forever. Avoid services that require login or have free-tier uptime limits.
- The policy must explicitly state: what data is collected (location), how it is used (generating forecast for the user), that it is not shared with third parties, and how users can request deletion (in this case: uninstall the app, as all data is local).
- Test the URL from an incognito browser and from a mobile browser before submission.
- Link the privacy policy in two places: the Play Store listing AND inside the app (Settings or About screen).

**Warning signs:**
- Privacy policy URL is a Google Doc that requires "request access"
- The URL works when logged in but returns 403 when accessed by Google's review bot
- Play Console submission form shows a warning on the privacy policy field

**Phase to address:** Phase 8 (release) — publish the privacy policy to GitHub Pages at the start of release prep, not as the last step before submission.

---

### Pitfall 15: Release Build Crashes That Never Appeared in Debug

**What goes wrong:**
Dart obfuscation (`--obfuscate`) and ProGuard minification (`minifyEnabled true`) can strip classes that Flutter plugins require through reflection. A plugin that works perfectly in `flutter run` (debug) crashes silently or with an unintelligible error in `flutter build appbundle --release --obfuscate`. Stack traces from the release build are unreadable without the `--split-debug-info` symbol file.

**Why it happens:**
Debug builds include all symbols and skip ProGuard. Release builds enable minification, which can aggressively remove classes referenced only through reflection (common in Java/Kotlin interop). Developers often run the full test suite in debug mode and assume the release build is equivalent.

**How to avoid:**
- Always build and manually test a release build on a physical device before submitting to Play Console. Use `flutter build apk --release` → sideload → test manually.
- Add `--split-debug-info=./debug-info/` to the release build command and keep the output. It is required to decode obfuscated crash stack traces from Play Console's Android vitals.
- If any plugin crashes in release but not debug: check ProGuard rules in `android/app/proguard-rules.pro`; most plugins document required keep rules in their README.
- Test the release build with: weather fetch, location permission request, Hive read/write, and notification scheduling.

**Warning signs:**
- `MissingPluginException` in release but not debug
- Stack traces from Play Console show only `<obfuscated>` with no line numbers (means `--split-debug-info` output was not saved)
- The app opens and immediately crashes on the first physical device test of the release build

**Phase to address:** Phase 8 (release build) — first task: build a release APK and test it on a physical device before investing time in Play Console metadata.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Parse Open-Meteo timestamps as strings, not epoch ints | Simpler JSON parsing | Timezone conversion bugs; DST edge cases break slot times | Never — always use `unixtime` format |
| Hardcode scoring weights (temp/rain/wind) as constants | No UI needed | Impossible to A/B test or adjust without a new release | Acceptable for v1 if sliders update them at runtime |
| Skip `mounted` check on weather fetch callbacks | Fewer lines of code | `setState() after dispose()` crashes in production | Never — 2 lines prevents a crash category |
| Store keystore in project repo | Convenient on one machine | Key exposure + loss on repo clone | Never |
| Use internal testing track only (skip closed testing) | Ship to testers faster | Cannot get production access | Never for production-bound apps |
| Request full Calendar scope (`calendar`) | Simpler | Higher OAuth rejection rate; Play policy may flag it | Never — use `calendar.events` scope only |
| Hive without field index registry comment | Faster initial dev | Breaking migrations on next field addition | Never |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Open-Meteo | Omit `timezone` param; receive GMT timestamps | Always pass `&timezone=auto&timeformat=unixtime` |
| Open-Meteo | Assume all fields are non-null doubles | Model all forecast fields as `double?`; guard in scorer |
| geolocator | Call `requestPermission()` in a loop on `denied` | After second `denied`, show settings deep-link dialog |
| geolocator | Treat `deniedForever` as reliable across all API levels | It is NOT — use timing heuristic + fallback city picker |
| flutter_local_notifications | Schedule exact alarms without requesting the permission | Call `requestExactAlarmsPermission()` in notification setup |
| workmanager | Assume periodic tasks fire reliably on OEM devices | Treat as best-effort; show `lastRefreshed` timestamp as fallback |
| google_sign_in + googleapis | Use access token directly; it expires in 1h | Use `googleapis_auth` `AutoRefreshingAuthClient` |
| Hive | Add a field at an existing `@HiveField` index | Append-only: always use the next available index number |

---

## "Looks Done But Isn't" Checklist

- [ ] **Weather timezone:** `timezone=auto` is in every Open-Meteo HTTP request — verify in network logs, not just code
- [ ] **Null scores:** Scoring function tested with a response where `precipitation_probability` is null — does not score as 0% rain
- [ ] **Slot boundaries:** Slot start and end times verified correct on a day where the user's timezone is UTC+2 (not UTC)
- [ ] **Permission denied-forever:** Manual city picker appears and is fully functional when GPS permission is permanently denied
- [ ] **Exact alarm:** "Evening before" notification arrives on a physical Android 12+ device with a fresh install (not previously whitelisted)
- [ ] **Background refresh:** `lastRefreshed` timestamp is shown in the UI and updates visibly after a background task fires
- [ ] **Release build:** The app has been sideloaded from a release APK (not debug) and all screens tested before Play submission
- [ ] **Keystore backup:** Keystore file exists in a password manager, and Play App Signing is enrolled in Play Console
- [ ] **Data safety form:** Form declares `ACCESS_FINE_LOCATION` and any Google account data from Calendar OAuth
- [ ] **Privacy policy URL:** URL opens without login from an incognito browser tab on mobile
- [ ] **Closed testing track:** 12+ testers invited and 14-day timer confirmed running in Play Console before the target release date minus 3 weeks
- [ ] **Hive field index registry:** Every `@HiveType` class has a comment listing all field indices and their history

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| setState after dispose | Phase 1 (setup) + Phase 3 (weather) | Code review: grep for `setState` without preceding `if (!mounted)` |
| Hot reload masks init bugs | Phase 1 (setup) | Unit test for cold-start initialization path |
| Open-Meteo timezone mismatch | Phase 3 (weather fetch) | Unit test: Amsterdam coord → assert slot time is UTC+2 offset |
| Null propagation in scoring | Phase 3 (scoring engine) | Unit test with partial null response |
| Off-by-one slot boundaries | Phase 3 (scoring engine) | Property test: N good hours → slot duration = N hours |
| WorkManager OEM failures | Phase 6 (background + notifications) | Test on Xiaomi/Samsung; show lastRefreshed timestamp |
| Location permission denied-forever | Phase 4 (location + onboarding) | Test full state machine: grant / deny / deny-forever / manual fallback |
| Hive TypeAdapter migration | Phase 5 (persistence) | Integration test: save v1 data, load with v2 adapter |
| Exact alarm permission | Phase 6 (notifications) | Test on fresh Android 12+ install: notification arrives |
| Google Calendar token refresh | Phase 7 (calendar integration) | Test: sign in → wait 1h → add to calendar → succeeds |
| Signing keystore lost | Phase 8 (release setup) | Confirm Play App Signing enrolled + keystore in password manager |
| Data Safety form rejection | Phase 8 (Play Console) | Preview form in Play Console; cross-check with AndroidManifest permissions |
| 12-tester / 14-day gate | Phase 1 (planning) + Phase 8 | Confirm tester count ≥ 12 and 14-day window in Play Console dashboard |
| Privacy policy broken link | Phase 8 (release) | Test URL from incognito mobile browser |
| Release build crashes | Phase 8 (release build) | Sideload release APK on physical device; test all feature paths |

---

## Sources

- Flutter setState after dispose: [DCM Blog — 15 Common Flutter/Dart Mistakes (2025)](https://dcm.dev/blog/2025/03/24/fifteen-common-mistakes-flutter-dart-development/) | [DCM — Hidden Cost of Async Misuse (2025)](https://dcm.dev/blog/2025/05/28/hidden-cost-async-misuse-flutter-fix/)
- Flutter hot reload gotchas: [Medium — Dark Side of Flutter Hot Reload](https://medium.com/@naufalprakoso24/the-dark-side-of-flutter-hot-reload-why-its-not-always-your-friend-and-how-to-tame-it-9c3419d4cebd) | [Flutter official hot reload docs](https://flutter.dev/docs/development/tools/hot-reload)
- Open-Meteo timezone bugs: [GitHub issue #850 — timezone param not working as expected](https://github.com/open-meteo/open-meteo/issues/850) | [GitHub issue #488 — DST not handled](https://github.com/open-meteo/open-meteo/issues/488) | [GitHub issue #1764 — UtcOffsetSeconds incorrect](https://github.com/open-meteo/open-meteo/issues/1764)
- Open-Meteo API reference: [Open-Meteo Docs](https://open-meteo.com/en/docs)
- WorkManager OEM issues: [Medium — Flutter Background Work guide](https://medium.com/@priya.prajapati/flutters-background-work-that-survives-os-sleep-ee2397a40652) | [softaai — Surviving Doze and App Standby](https://softaai.com/building-resilient-android-apps-surviving-doze-standby/) | [pub.dev workmanager package](https://pub.dev/packages/workmanager)
- Location permission bugs: [geolocator issue #880 — DeniedForever not applied](https://github.com/Baseflow/flutter-geolocator/issues/880) | [geolocator issue #626 — denied vs denied-forever on Android 9](https://github.com/Baseflow/flutter-geolocator/issues/626)
- Exact alarm permission: [flutter_local_notifications pub.dev](https://pub.dev/packages/flutter_local_notifications) | [ASOasis — Flutter Local Notifications Scheduling Guide (2026)](https://asoasis.tech/articles/2026-03-19-2054-flutter-local-notifications-scheduling-guide/)
- Google Calendar OAuth: [Google OAuth 2.0 docs](https://developers.google.com/identity/protocols/oauth2) | [Flutter googleapis issue #510 — AutoRefreshing auth](https://github.com/google/googleapis.dart/issues/510)
- Hive schema migration: [GitHub issue #781 — new field breaks adapter](https://github.com/isar/hive/issues/781) | [Medium — Hive to Isar migration](https://saropa-contacts.medium.com/the-long-road-a-flutter-database-migration-from-hive-to-isar-reflections-from-the-saropa-122b8e9b289c)
- Play Console keystore loss: [Medium — Lost Keystore guide](https://medium.com/@TeddyYeung/how-to-handle-a-lost-keystore-in-android-8c1ca345b09d)
- Data Safety form: [Play Console Help — Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469) | [GitHub commons-app issue #5708 — rejected for location data type](https://github.com/commons-app/apps-android-commons/issues/5708)
- Closed testing requirement: [Play Console Help — Testing requirements for new personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465) | [primetestlab — Google Play 12 testers guide](https://primetestlab.com/blog/google-play-12-testers-closed-testing-guide)
- Privacy policy / GDPR: [Medium — GDPR Compliance in Flutter](https://hasankarli.medium.com/gdpr-compliance-in-flutter-mobile-applications-020751582e60)
- Release build pitfalls: [Medium — Flutter APK size 68MB to 27MB](https://medium.com/@garoono/i-shrunk-a-flutter-release-from-68-mb-to-27-mb-with-every-feature-intact-0da852103385) | [Medium — Obfuscation in Flutter](https://medium.com/flutter-uae/understanding-obfuscation-in-flutter-8fb534e02020)

---
*Pitfalls research for: Flutter Android cycling weather app — RideWindow*
*Researched: 2026-06-01*
