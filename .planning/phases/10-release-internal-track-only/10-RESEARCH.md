# Phase 10: Release — Internal Track Only - Research

**Researched:** 2026-06-04
**Domain:** Android release signing, Play Console internal testing, privacy policy, Data Safety form
**Confidence:** HIGH

## Summary

Phase 10 converts the completed RideWindow codebase into a signed release AAB that can be distributed to 10–20 testers via the Google Play Console Internal testing track. There are six requirements (REL-01 through REL-06) covering the full release pipeline: keystore creation and backup, sideload smoke testing on a physical device, privacy policy hosting on GitHub Pages, Data Safety form completion, and uploading to the Internal testing track with an opt-in link.

The critical blocker identified during research is that the Android SDK is NOT installed on this machine (`flutter doctor` shows `[✗] Android toolchain — Unable to locate Android SDK`). This is a known deferred item from STATE.md. Wave 0 of the plan must install Android Studio + SDK and accept licenses before any build step can proceed.

The `applicationId` is currently `com.fanalists.ridewindow.ridewindow` in `build.gradle.kts`. This is a permanent identifier — it cannot be changed after the first upload to Play Console. It should be confirmed as intentional before any upload.

The current `.gitignore` does NOT include entries for `key.properties` or `*.jks` keystore files. These must be added before committing the signing configuration to avoid accidentally exposing credentials.

**Primary recommendation:** Wave 0 = install Android SDK. Wave 1 = keystore creation + signing config + gitignore hardening + version bump. Wave 2 = build AAB + APK sideload smoke test. Wave 3 = GitHub Pages privacy policy + About screen. Wave 4 = Play Console setup (store listing, content rating, Data Safety) + upload to Internal testing.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Release build signing | Build toolchain (Gradle) | Flutter CLI | Signing config lives in build.gradle.kts; Flutter CLI invokes Gradle |
| App icon (Play Store 512×512) | Build toolchain | Android res | Separate asset from mipmap launcher icons; required for Play Console store listing |
| Privacy policy | Static hosting (GitHub Pages) | In-app About screen | Google Play requires a publicly accessible URL; the in-app screen is the secondary display |
| Data Safety declaration | Play Console UI | — | Form is filled manually in the Play Console web interface |
| Internal testing track | Play Console UI | — | Track setup and tester opt-in link management live entirely in Play Console |
| Obfuscation symbol files | Build output | Offline backup | `--split-debug-info` output must be retained alongside the keystore for future crash de-obfuscation |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | App is built as a signed release AAB with Play App Signing enrolled | Keystore creation + Gradle signing config + `flutter build appbundle --obfuscate --split-debug-info`; Play App Signing is automatically enrolled for new apps when AAB is uploaded |
| REL-02 | Upload keystore is backed up to password manager (Bitwarden/1Password) with passwords | The `upload-keystore.jks` file and `key.properties` contents must be exported to the password manager immediately after creation — losing these means the app can never be updated |
| REL-03 | Privacy policy is published to a stable URL (GitHub Pages) and linked from Play Console + in-app About screen | Simplest approach: new GitHub repo with a single `index.html` or `privacy.md` + GitHub Pages enabled; no Jekyll required |
| REL-04 | Data Safety form in Play Console declares: precise location for app functionality; Google account info ephemerally accessed via Calendar OAuth (user-initiated only) | Location: collected, purpose=app functionality, precise, encrypted in transit. Calendar: ephemeral access may qualify for exemption; safest = declare collected under "App info and performance" with purpose=app functionality, mark optional and user-initiated |
| REL-05 | Release AAB is sideloaded and manually tested on a physical Android device before upload | Build release APK (`flutter build apk --release`), install via `adb install`, verify app launches, slots show, notifications fire, Calendar export works |
| REL-06 | App is uploaded to Play Console Internal testing track with opt-in link; at least one external tester has installed and opened it | Internal testing bypasses app review and goes live within minutes; opt-in URL appears after first publish of the release |
</phase_requirements>

## Standard Stack

### Core Build Tools

| Tool | Version | Purpose | Source |
|------|---------|---------|--------|
| Android Studio | Latest stable (2024.x / Ladybug+) | Installs Android SDK, SDK Manager, build tools, `keytool` JDK | [CITED: docs.flutter.dev/deployment/android] |
| Flutter CLI | 3.44.1 (already installed) | `flutter build appbundle`, `flutter build apk`, `flutter symbolize` | [VERIFIED: flutter doctor output] |
| Gradle (Kotlin DSL) | Already configured (build.gradle.kts) | Signing config, release build type | [VERIFIED: codebase] |
| keytool | Ships with Android Studio JDK | Keystore generation | [CITED: docs.flutter.dev/deployment/android] |
| adb | Ships with Android SDK platform-tools | APK sideloading for smoke test | [ASSUMED] |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| flutter_launcher_icons (dev dep) | Generates all mipmap densities from a single source PNG | Use if a custom app icon is needed; current icon is the Flutter default |
| bundletool | Converts AAB to device-specific APK set for local install testing | Use if `adb install` of APK is insufficient; `flutter build apk` is simpler |
| GitHub Pages | Static hosting for privacy policy | Free, stable URL, no backend |

**No new runtime packages are needed for this phase.** All release work happens at the build toolchain and Play Console level.

## Package Legitimacy Audit

No new packages are being added in this phase. The phase is build toolchain, Play Console configuration, and static site work only.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
[Source code + pubspec.yaml]
        |
        v
[flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols]
        |
        +---> [app.aab] --> [Play Console upload] --> [Internal testing track]
        |                                                      |
        +---> [symbols/*.symbols] --> [Backup offline]         v
                                                      [Opt-in URL sent to testers]
[flutter build apk --release]
        |
        v
[adb install app-release.apk] --> [Physical device smoke test]

[GitHub repo: privacy-policy]
        |
        v
[GitHub Pages: https://username.github.io/privacy-policy/]
        |
        +---> [Play Console store listing: privacy policy URL]
        +---> [RideWindow About screen: launches URL in browser]
```

### Recommended Project Structure Changes

```
android/
├── key.properties          # NEW — gitignored, contains keystore path + passwords
├── app/
│   └── build.gradle.kts    # MODIFIED — add signingConfigs + release signingConfig
.gitignore                  # MODIFIED — add *.jks, key.properties, build/app/outputs/symbols/
lib/features/profile/       # MODIFIED — add About screen or About section in ProfileScreen
  └── about_screen.dart     # NEW (or add ListTile to ProfileScreen)
```

**Separate GitHub repository** (new, not part of this repo):
```
ridewindow-privacy/
└── index.html (or privacy.md)   # Privacy policy content
```

### Pattern 1: Kotlin DSL Signing Config (build.gradle.kts)

**What:** Load key.properties at the top of build.gradle.kts, define a `release` signingConfig, reference it in the release buildType.
**When to use:** Any Flutter release build. This replaces the existing `signingConfig = signingConfigs.getByName("debug")` placeholder.

```kotlin
// Source: https://docs.flutter.dev/deployment/android
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.fanalists.ridewindow.ridewindow"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.fanalists.ridewindow.ridewindow"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
```

### Pattern 2: key.properties Template

**What:** Plain text properties file loaded by build.gradle.kts. Must NOT be committed to git.

```properties
# android/key.properties — NEVER COMMIT THIS FILE
storePassword=<store-password>
keyPassword=<key-password>
keyAlias=upload
storeFile=/Users/joostmouw/upload-keystore.jks
```

### Pattern 3: Keystore Generation Command

```bash
# Source: https://docs.flutter.dev/deployment/android
keytool -genkey -v \
  -keystore ~/upload-keystore.jks \
  -keyalg RSA \
  -storetype JKS \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

After generating: immediately export to password manager (Bitwarden/1Password). Store:
- The `.jks` file itself (as attachment or base64)
- storePassword
- keyPassword
- keyAlias (`upload`)

### Pattern 4: Release Build Commands

```bash
# Source: https://docs.flutter.dev/deployment/android + https://docs.flutter.dev/deployment/obfuscate

# 1. Clean first to prevent cached build artifacts from using old signing
flutter clean

# 2. Build signed release AAB (for Play Console upload)
flutter build appbundle \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols

# Output: build/app/outputs/bundle/release/app.aab
# Symbols: build/app/outputs/symbols/

# 3. Build signed release APK (for sideload smoke test)
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols

# Output: build/app/outputs/flutter-apk/app-release.apk

# 4. Sideload to physical device
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Pattern 5: Version Bump (pubspec.yaml)

```yaml
# Current: version: 0.1.0+1
# For release: bump versionCode (the +N number) — must be higher than any previous upload
version: 1.0.0+1
```

The `+1` becomes `versionCode=1` in the AAB. versionCode must be monotonically increasing; it can never go backward.

### Anti-Patterns to Avoid

- **Committing key.properties or *.jks to git:** Exposes signing credentials publicly. Add both to .gitignore before creating the files.
- **Losing the keystore:** If the upload keystore is lost, the app can never receive an update — you'd need a new package name and lose all existing installations.
- **Using `--split-debug-info` without keeping the symbols:** Obfuscated crash reports become unreadable without the corresponding `.symbols` files. Back up `build/app/outputs/symbols/` alongside the keystore.
- **Not running `flutter clean` before release build:** Cached build artifacts may use the debug signing config even after updating build.gradle.kts.
- **Uploading an AAB with debug signing:** Play Console will reject it. Verify by checking `flutter build appbundle` output does not say "debug".
- **Skipping physical device smoke test:** An AAB accepted by Play Console can still crash on real hardware due to permission dialogs, WorkManager OEM restrictions, or real GPS behavior.
- **Forgetting to increment versionCode:** Play Console rejects uploads with a duplicate or lower versionCode.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| App icon resizing | Manual Photoshop/GIMP at each mipmap density | `flutter_launcher_icons` | Generates all required densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi) + adaptive icons from one 1024×1024 source |
| Privacy policy HTML | Complex HTML template | One-page Markdown + GitHub Pages | Google only needs a stable URL serving readable text; Jekyll or raw HTML.md both work |
| Symbol file storage | Building custom CI | Back up `build/app/outputs/symbols/` to the same password manager as the keystore | flutter symbolize requires matching symbols per build |

**Key insight:** This phase is almost entirely configuration and ceremony, not code. The signing infrastructure, Play Console forms, and GitHub Pages page are the deliverables — not new Dart code.

## Runtime State Inventory

Step 2.5: SKIPPED — This is not a rename/refactor/migration phase. No runtime state renaming is involved.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Android SDK | flutter build appbundle, adb | **NO** | — | Install Android Studio (Wave 0 — blocks everything else) |
| Flutter CLI | All build commands | YES | 3.44.1 (stable) | — |
| Java / keytool | Keystore generation | **NO** (ships with Android Studio JDK) | — | Resolved by installing Android Studio |
| adb | APK sideloading | **NO** (ships with Android platform-tools) | — | Resolved by installing Android Studio / SDK |
| Physical Android device | REL-05 smoke test | Unknown (not checkable via CLI) | — | Must be human-confirmed; no emulator substitute for REL-05 |
| GitHub account + Pages | REL-03 privacy policy | Unknown (not checkable here) | — | Must be human-confirmed; free GitHub.com account suffices |
| Google Play Console account | REL-06 | Unknown (not checkable here) | — | One-time $25 fee; developer confirmed project budget |
| Bitwarden/1Password | REL-02 keystore backup | Unknown | — | Any password manager works; or encrypted local backup |

**Missing dependencies blocking execution:**
- **Android SDK** (includes build-tools, platform-tools, adb, keytool): blocks REL-01, REL-02, REL-05. Install via Android Studio. This is deferred from Phase 1 per STATE.md.

**Missing dependencies with human confirmation required (cannot verify programmatically):**
- Physical Android device for smoke test (REL-05)
- Google Play Console account active + $25 paid
- GitHub account for privacy policy hosting

**Android Studio installation commands (macOS):**
```bash
# Option A: Homebrew Cask (recommended for macOS)
brew install --cask android-studio

# After install: open Android Studio, complete setup wizard,
# install SDK components (API 35, build-tools 35.x, platform-tools)
# Then accept licenses:
~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --licenses
# OR via flutter:
/Users/joostmouw/development/flutter/bin/flutter doctor --android-licenses
```

## Common Pitfalls

### Pitfall 1: applicationId Cannot Be Changed After First Upload

**What goes wrong:** Developer changes `applicationId` after uploading even one test build. Play Console treats the new ID as a completely different app — all installations and any test results are lost.
**Why it happens:** applicationId is the permanent unique identifier for an app in the Play Store.
**How to avoid:** Confirm `com.fanalists.ridewindow.ridewindow` is the intended permanent ID before the very first upload. Consider whether the double `ridewindow.ridewindow` suffix is intentional — `com.fanalists.ridewindow` or `dev.joost.ridewindow` might be cleaner. The decision must be made in Wave 1 (before any Play Console upload).
**Warning signs:** "com.fanalists.ridewindow.ridewindow" looks like an auto-generated default that may not have been intentionally confirmed.

### Pitfall 2: key.properties and *.jks Not in .gitignore

**What goes wrong:** Developer runs `git add -A` and commits the keystore file and key.properties to the repository. If the repo is ever made public or if git history is not carefully managed, signing credentials are permanently exposed.
**Why it happens:** The current `.gitignore` (verified in codebase) has no entries for `key.properties` or `*.jks`.
**How to avoid:** Add these entries to `.gitignore` in Wave 1, before creating the files:
```
# Signing
*.jks
*.keystore
android/key.properties
```
**Warning signs:** Running `git status` after creating key.properties and seeing it as "untracked" (not "ignored").

### Pitfall 3: Android SDK Licenses Not Accepted

**What goes wrong:** `flutter build appbundle` fails with "SDK not found" or "Android license status unknown" even after Android Studio is installed.
**Why it happens:** Android Studio may be installed but the SDK Manager component install was not completed, or `flutter doctor --android-licenses` was not run.
**How to avoid:** After Android Studio installation, run `flutter doctor -v` and confirm `[✓] Android toolchain` before attempting any build.

### Pitfall 4: Debug Symbols Not Backed Up Alongside Keystore

**What goes wrong:** A crash report arrives from a tester. The stack trace is obfuscated because `--obfuscate` was used, but the corresponding `.symbols` files were not retained.
**Why it happens:** `build/` directory is gitignored; symbols in `build/app/outputs/symbols/` are silently lost on next `flutter clean`.
**How to avoid:** After every release build, copy the symbols directory to a safe location (same folder as keystore backup, or password manager attachment). The `flutter symbolize` command requires the matching symbols file.

### Pitfall 5: versionCode Not Incremented Between Builds

**What goes wrong:** A second upload to Play Console fails with "Version code already used".
**Why it happens:** `pubspec.yaml` version is still `0.1.0+1` and the developer forgets to increment it before rebuilding.
**How to avoid:** Always update `version: X.Y.Z+N` in `pubspec.yaml` before each Play Console upload. The `+N` becomes versionCode; must be strictly increasing.

### Pitfall 6: Internal Testing Requires Minimum Store Listing

**What goes wrong:** Developer tries to upload AAB to Internal testing track but Play Console blocks the release because the store listing has no app name, icon, description, or screenshots.
**Why it happens:** Internal testing still requires a minimal store listing to be created (not necessarily complete, but non-empty).
**How to avoid:** Before uploading the AAB, complete the minimum store listing: app name ("RideWindow"), short description (max 80 chars), full description (max 4000 chars), app icon (512×512 PNG), feature graphic (1024×500 PNG), and at least 2 screenshots.
**[ASSUMED]** — exact minimum may vary; verify in Play Console UI.

### Pitfall 7: 12-Tester Closed Testing Requirement Applies Only to Production

**What goes wrong:** Developer confuses the 12-tester/14-day requirement (for production access) with internal testing track.
**Why it happens:** Recent Google policy changes in 2024 introduced stricter production requirements, which some articles describe without clearly distinguishing from internal testing.
**How to avoid:** Internal testing bypasses app review entirely and goes live within minutes. The 12-tester/14-day requirement applies ONLY when applying for production access — not for internal testing. For v1 scope (internal testing only), this requirement is irrelevant. [CITED: support.google.com/googleplay/android-developer/answer/14151465]

### Pitfall 8: Data Safety Form — Internal Testing Exemption

**What goes wrong:** Developer spends time completing the Data Safety form only to discover it was not required for internal testing, or skips it and hits a surprise during future track promotion.
**Why it happens:** Google's guidance states internal-testing-only apps are exempt from the Data Safety section requirement.
**How to avoid:** For this phase (internal testing only), completing the Data Safety form is technically optional. However, the requirements (REL-04) specify it should be done correctly. Completing it now prevents delays when promoting to closed/production later. The Data Safety information that should be declared is documented in the REL-04 requirement.

## Code Examples

### About Screen / Privacy Policy Link in ProfileScreen

```dart
// Source: Flutter docs pattern — url_launcher (if not already a dep, use Android Intent directly)
// Add to ProfileScreen's ListView, after existing sections:

const _SectionHeader('OVER'),
ListTile(
  title: const Text('Privacybeleid'),
  trailing: const Icon(Icons.open_in_new),
  onTap: () async {
    final uri = Uri.parse('https://your-github-username.github.io/ridewindow-privacy/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  },
),
ListTile(
  title: const Text('Versie'),
  trailing: const Text('1.0.0'),
),
```

Note: `url_launcher` is not yet in `pubspec.yaml`. Either add it or open via the Calendar OAuth flow's existing Intent pattern. Alternatively, use `AndroidIntent` directly. [ASSUMED] — verify whether url_launcher is needed or if an alternative approach fits better.

### Minimal GitHub Pages Privacy Policy (index.html)

```html
<!DOCTYPE html>
<html lang="nl">
<head><meta charset="UTF-8"><title>RideWindow — Privacybeleid</title></head>
<body>
<h1>Privacybeleid — RideWindow</h1>
<p><em>Bijgewerkt: [datum]</em></p>

<h2>Gegevens die we verzamelen</h2>
<p><strong>Locatie (nauwkeurig):</strong> Wanneer u locatietoestemming verleent,
gebruikt de app uw GPS-locatie om weersvoorspellingen op te halen.
Locatiegegevens worden uitsluitend lokaal op uw apparaat verwerkt en
nooit naar onze servers verzonden.</p>

<p><strong>Google-account (optioneel):</strong> Als u op "Toevoegen aan agenda" tikt,
vraagt de app toegang tot uw Google Agenda (alleen schrijfrechten voor afspraken).
Uw Google-accountgegevens worden nooit opgeslagen en niet gedeeld met derden.</p>

<h2>Gegevens die we niet verzamelen</h2>
<p>We verzamelen geen persoonsgegevens, we voeren geen analyses uit en
we sturen geen gegevens naar eigen servers. Alle instellingen worden
lokaal op uw apparaat opgeslagen.</p>

<h2>Contact</h2>
<p>Vragen? Stuur een e-mail naar [uw e-mailadres].</p>
</body>
</html>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Upload APK directly | Upload AAB (Android App Bundle) | 2021 (mandatory for new apps Aug 2021) | AAB is required; Google rejects direct APK uploads for new apps |
| 20 testers for 14 days (production) | 12 testers for 14 days (production only) | December 2024 | Slightly less friction for production; internal testing unaffected |
| Manual multi-density icon creation | flutter_launcher_icons + single source PNG | ~2019 | Removes tedious manual asset work |
| Separate upload key + app signing key | Play App Signing (Google manages app signing key, developer keeps upload key) | 2017, mandatory for new AAB uploads | Safer: losing upload key can be recovered via Google; losing app signing key cannot |

**Deprecated/outdated:**
- `android:allowBackup="true"` default: Android 12+ changed backup behavior; not directly relevant but worth knowing.
- `isInDebugMode` in workmanager: already removed in Phase 8 (STATE.md confirmed).
- Direct APK uploads for new apps: rejected by Play Console; AAB is mandatory.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Internal testing track requires a minimum store listing (app name, icon, description, at least 2 screenshots) before the first upload is accepted | Common Pitfalls #6 | If wrong, less prep is needed in Wave 4; play Console UI will clarify |
| A2 | `url_launcher` is not yet in pubspec.yaml and needs to be added for the privacy policy link in the About screen | Code Examples | If it's already present, skip the pubspec step |
| A3 | `com.fanalists.ridewindow.ridewindow` applicationId is the developer's intended permanent package name | Common Pitfalls #1 | If wrong and changed after first upload, all test installs become orphaned — very high impact |
| A4 | The Google Play Developer account ($25) is already registered | Environment Availability | If not, account setup adds 1–2 days |
| A5 | A physical Android device is available for REL-05 smoke test | Environment Availability | If not, sideload test cannot be completed; no emulator substitute passes the REL-05 requirement as written |
| A6 | Data Safety form is optional for internal-testing-only apps but recommended to complete now (per REL-04 requirement) | Common Pitfalls #8 | If Play Console has changed this policy, the form may be mandatory even for internal testing |

## Open Questions

1. **applicationId: is `com.fanalists.ridewindow.ridewindow` intentional?**
   - What we know: It appears auto-generated by the Flutter scaffold; the double `ridewindow.ridewindow` looks like the namespace and module name were concatenated.
   - What's unclear: Whether the developer consciously confirmed this or left it as a default.
   - Recommendation: Confirm before Wave 1. Change it in `build.gradle.kts` `applicationId` and `namespace` (and `AndroidManifest.xml` package attribute if set) before any Play Console upload. Options: `com.fanalists.ridewindow` or a personal domain like `dev.joost.ridewindow`.

2. **Does the app currently have a custom icon or is it using the Flutter default blue logo?**
   - What we know: Only `ic_launcher.png` exists in `mipmap-hdpi/` — likely the default Flutter blue diamond icon.
   - What's unclear: Whether a custom icon needs to be designed for this phase.
   - Recommendation: A custom icon is needed for the Play Console store listing (512×512 PNG required). This is an art task. If a custom icon is already designed (e.g., bike/window logo), use `flutter_launcher_icons` to generate all mipmap densities. If not, design one before Wave 4.

3. **Will the privacy policy need to be in Dutch or English?**
   - What we know: The app UI is in Dutch (per codebase); testers are cyclist friends, presumably Dutch.
   - What's unclear: Whether Play Console requires a specific language for the privacy policy.
   - Recommendation: Write it in Dutch since the app and target audience are Dutch. A simple bilingual version is also fine but not required for internal testing.

## Validation Architecture

`nyquist_validation` is set to `false` in config.json. This section is SKIPPED.

## Security Domain

`security_enforcement` is set to `false` in config.json. This section is SKIPPED.

## Sources

### Primary (HIGH confidence)
- [docs.flutter.dev/deployment/android](https://docs.flutter.dev/deployment/android) — keystore creation, Kotlin DSL signing config, `flutter build appbundle`
- [docs.flutter.dev/deployment/obfuscate](https://docs.flutter.dev/deployment/obfuscate) — `--obfuscate` + `--split-debug-info` flags, `flutter symbolize`
- `flutter doctor -v` output (run 2026-06-04) — Android SDK not installed, Flutter 3.44.1 confirmed
- Codebase inspection (2026-06-04) — `applicationId`, `build.gradle.kts` signing placeholder, `.gitignore` missing keystore entries

### Secondary (MEDIUM confidence)
- [support.google.com/googleplay/android-developer/answer/9845334](https://support.google.com/googleplay/android-developer/answer/9845334) — Internal testing track setup, opt-in link behavior
- [support.google.com/googleplay/android-developer/answer/14151465](https://support.google.com/googleplay/android-developer/answer/14151465) — 12 testers/14 days requirement (production only, not internal)
- [applander.io/blog/google-play-data-safety-form-complete-guide](https://applander.io/blog/google-play-data-safety-form-complete-guide) — Data Safety precise location and ephemeral access declaration guidance

### Tertiary (LOW confidence)
- WebSearch results about store listing minimum requirements for internal testing — exact minimums should be verified in Play Console UI

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — build toolchain is well-documented, codebase inspected
- Architecture: HIGH — flow is deterministic (build → sign → upload → distribute)
- Pitfalls: HIGH for keystore/gitignore/applicationId (verified in codebase); MEDIUM for Play Console UI behavior (policy details vary)
- Environment: HIGH — `flutter doctor` output is definitive; Android SDK absence confirmed

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable domain; Play Console UI policies could shift but signing process is stable)
