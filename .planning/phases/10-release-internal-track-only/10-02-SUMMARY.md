---
phase: 10-release-internal-track-only
plan: "02"
subsystem: infra
tags: [android, release-build, aab, apk, obfuscation, signing, flutter]

# Dependency graph
requires:
  - plan: 10-01
    provides: Android upload keystore, release signing config, compileSdk=35, pubspec version 1.0.0+1
provides:
  - Signed release AAB at build/app/outputs/bundle/release/app-release.aab (56.5MB)
  - Signed release APK at build/app/outputs/flutter-apk/app-release.apk (58.0MB)
  - Obfuscation debug symbols at build/app/outputs/symbols/ (arm, arm64, x64)
  - compileSdk bumped to 36 (required by multiple plugins)
  - Core library desugaring enabled (required by flutter_local_notifications v21+)
affects:
  - 10-04 (Play Console upload — AAB is the artifact to upload)

# Tech tracking
tech-stack:
  added:
    - desugar_jdk_libs:2.1.5 (Gradle dependency for core library desugaring)
    - Android cmdline-tools/latest (installed to Android SDK for Flutter post-build processing)
  patterns:
    - "compileSdk=36 required for Flutter plugins that target API 36 (url_launcher_android, shared_preferences_android, flutter_local_notifications, geolocator_android, google_sign_in_android, package_info_plus)"
    - "isCoreLibraryDesugaringEnabled = true required for flutter_local_notifications v21+"
    - "flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols produces signed AAB + symbol files"

key-files:
  modified:
    - android/app/build.gradle.kts (compileSdk 35→36, isCoreLibraryDesugaringEnabled=true, desugar_jdk_libs dependency)
    - pubspec.lock (url_launcher 6.3.2 + url_launcher_android platform plugin resolved)

key-decisions:
  - "compileSdk bumped from 35 to 36 — multiple plugins (url_launcher_android, shared_preferences_android, flutter_local_notifications, geolocator_android, google_sign_in_android, package_info_plus) now require compileSdk 36; backward compatible with targetSdk and minSdk"
  - "Core library desugaring enabled — flutter_local_notifications v21+ (used in Phase 8) requires it; desugar_jdk_libs:2.1.5 added as Gradle dependency"
  - "Android cmdline-tools installed to ~/Library/Android/sdk/cmdline-tools/latest — required for Flutter's post-build symbol stripping step; not bundled with Android Studio on this machine"
  - "Task 2 (physical device smoke test) is a human-action checkpoint — cannot be automated; developer must connect device via USB, adb install, and verify 6 scenarios"

# Metrics
duration: ~10 minutes (automated build, excluding human smoke test time)
completed: 2026-06-05
---

# Phase 10 Plan 02: Build Signed Release AAB and APK Summary

**Signed release AAB (56.5MB) and APK (58.0MB) built with obfuscation and debug symbols; three blocking build issues auto-fixed (compileSdk, desugaring, cmdline-tools); Task 2 sideload smoke test is awaiting human action**

## Performance

- **Duration:** ~10 minutes (automated tasks only; Task 2 is a human checkpoint)
- **Started:** 2026-06-05T19:40:42Z
- **Completed:** 2026-06-05 (Task 1 complete; Task 2 awaiting human)
- **Tasks:** 2 (1 automated complete, 1 human-action checkpoint)
- **Files modified:** 2 (android/app/build.gradle.kts, pubspec.lock)

## Accomplishments

- `flutter pub get` executed — `url_launcher 6.3.2` resolved and pulled into pubspec.lock
- `flutter clean` cleared all cached build artifacts
- Release AAB built: `build/app/outputs/bundle/release/app-release.aab` (56.5 MB)
  - Signed with release signing config (keystoreProperties from `android/key.properties`)
  - Obfuscated with `--obfuscate` flag
  - Symbol files produced at `build/app/outputs/symbols/` (arm, arm64, x64)
- Release APK built: `build/app/outputs/flutter-apk/app-release.apk` (58.0 MB)
  - Same signing + obfuscation flags

## Task Commits

1. **Task 1: flutter pub get + clean + build signed release AAB and APK** — `7c5421f` (feat)
2. **Task 2: Sideload APK to physical device + smoke test** — checkpoint:human-action (awaiting developer)

## Files Created/Modified

- `android/app/build.gradle.kts` — compileSdk bumped 35→36; `isCoreLibraryDesugaringEnabled = true` added to compileOptions; `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")` added to dependencies block
- `pubspec.lock` — url_launcher 6.3.2 and all platform implementations resolved (url_launcher_android, url_launcher_ios, url_launcher_linux, url_launcher_macos, url_launcher_platform_interface, url_launcher_web, url_launcher_windows)

## Decisions Made

- **compileSdk=36** — Bumped from 35. Multiple plugins now require API 36 (url_launcher_android pulled in by this plan's `flutter pub get`; shared_preferences_android, flutter_local_notifications, geolocator_android, google_sign_in_android, package_info_plus were already pulling it). compileSdk is backward compatible with targetSdk and minSdk.
- **Core library desugaring** — `flutter_local_notifications` v21+ requires it. Added `isCoreLibraryDesugaringEnabled = true` in compileOptions and `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")` as a Gradle dependency.
- **cmdline-tools installation** — Flutter 3.44.1 requires `cmdline-tools` for post-build symbol stripping from the final AAB. Android Studio on this machine did not bundle cmdline-tools in the SDK. Downloaded `commandlinetools-mac-13114758_latest.zip` from `dl.google.com` and installed to `~/Library/Android/sdk/cmdline-tools/latest`. Android SDK licenses accepted via `sdkmanager --licenses` using Android Studio's bundled JDK at `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] compileSdk bumped from 35 to 36**
- **Found during:** Task 1 — first `flutter build appbundle` attempt
- **Issue:** Build failed with "Dependency ':url_launcher_android' requires libraries and applications that depend on it to compile against version 36 or later of the Android APIs" (same for 5 other plugins)
- **Fix:** Changed `compileSdk = 35` to `compileSdk = 36` in `android/app/build.gradle.kts`
- **Files modified:** `android/app/build.gradle.kts`
- **Commit:** Included in `7c5421f`

**2. [Rule 3 - Blocking] Core library desugaring required by flutter_local_notifications**
- **Found during:** Task 1 — second `flutter build appbundle` attempt (after compileSdk fix)
- **Issue:** Build failed with "Dependency ':flutter_local_notifications' requires core library desugaring to be enabled for :app"
- **Fix:** Added `isCoreLibraryDesugaringEnabled = true` to `compileOptions` block; added `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")` to `dependencies` block
- **Files modified:** `android/app/build.gradle.kts`
- **Commit:** Included in `7c5421f`

**3. [Rule 3 - Blocking] Android cmdline-tools missing, causing Flutter post-build failure**
- **Found during:** Task 1 — third `flutter build appbundle` attempt (Gradle built successfully but Flutter post-processing failed)
- **Issue:** `flutter build appbundle` reported "Release app bundle failed to strip debug symbols from native libraries" — verbose log showed "Failed to find cmdline-tools when checking final appbundle for debug symbols." The Gradle `bundleRelease` task succeeded; Flutter's post-processing step requires `cmdline-tools/latest/bin/` for `apkanalyzer`.
- **Fix:** Downloaded Android cmdline-tools from `https://dl.google.com/android/repository/commandlinetools-mac-13114758_latest.zip`, installed to `~/Library/Android/sdk/cmdline-tools/latest`, accepted all SDK licenses via `sdkmanager --licenses` (using Android Studio JDK at `/Applications/Android Studio.app/Contents/jbr/Contents/Home`). This is environment setup, not a committed change.
- **Files modified:** No code changes — environment only
- **Commit:** N/A (environment fix)

## Issues Encountered

Three sequential blocking build issues, all auto-fixed per Rule 3:
1. compileSdk=35 rejected by plugins requiring 36 — fixed by bumping to 36
2. Core library desugaring not enabled — fixed by enabling + adding desugar_jdk_libs
3. cmdline-tools not installed — fixed by downloading and installing from dl.google.com

After all three fixes: clean build succeeded in one pass.

## Threat Model Compliance

- **T-10-05** (debug-signed AAB uploaded): Mitigated — build output shows `✓ Built` without "debug" in signing summary; `flutter clean` was run before build; signing config reads from `key.properties` (real upload keystore, not debug keystore)
- **T-10-06** (symbol files lost): Mitigated in Task 2 — developer must run `cp -r build/app/outputs/symbols/ ~/ridewindow-symbols-v1.0.0+1/` before next `flutter clean`
- **T-10-07** (versionCode not incremented): Accepted — first upload; versionCode=1 from pubspec.yaml `1.0.0+1`

## Known Stubs

None — this plan produces build artifacts and environment configuration, not UI code.

## Next Phase Readiness

- `app-release.aab` is ready for Play Console upload (Plan 10-04)
- Smoke test (Task 2) must be completed before upload — developer must confirm "smoke-test-passed"
- Symbol files must be backed up to `~/ridewindow-symbols-v1.0.0+1/` as part of Task 2 Step 5

---
*Phase: 10-release-internal-track-only*
*Completed: 2026-06-05 (Task 1); Task 2 awaiting human action*

## Self-Check: PASSED

- `build/app/outputs/bundle/release/app-release.aab` — exists, 56,451,989 bytes
- `build/app/outputs/flutter-apk/app-release.apk` — exists, 58,019,201 bytes
- `build/app/outputs/symbols/` — exists with app.android-arm.symbols, app.android-arm64.symbols, app.android-x64.symbols
- `pubspec.lock` — contains url_launcher entries (confirmed via grep)
- `android/app/build.gradle.kts` — compileSdk=36, isCoreLibraryDesugaringEnabled=true, desugar_jdk_libs dependency
- Commit `7c5421f` — exists in git log (Task 1 automated commit)
