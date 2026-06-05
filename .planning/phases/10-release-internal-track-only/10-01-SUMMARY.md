---
phase: 10-release-internal-track-only
plan: "01"
subsystem: infra
tags: [android, signing, keystore, gradle, flutter, release]

# Dependency graph
requires:
  - phase: 09-google-calendar-integration
    provides: Complete Flutter app with Calendar integration ready for release packaging
provides:
  - Android upload keystore created and backed up to password manager
  - Gradle release signing config wired via key.properties (Pattern 1 Kotlin DSL)
  - applicationId confirmed as ridewindow.joost.amsterdam (permanent)
  - .gitignore hardened against credential exposure (*.jks, *.keystore, android/key.properties)
  - pubspec.yaml version bumped to 1.0.0+1 (versionCode=1 for first Play Console upload)
  - url_launcher dependency added for future About screen
  - Android SDK installed and flutter doctor shows Android toolchain ready
affects:
  - 10-02 (signed release AAB build — depends on signing config and keystore from this plan)
  - 10-03 (privacy policy About screen — url_launcher added here)
  - 10-04 (Play Console upload — applicationId is permanent, set here)

# Tech tracking
tech-stack:
  added:
    - url_launcher ^6.3.1 (future About screen privacy policy link)
  patterns:
    - "Kotlin DSL Pattern 1: keystoreProperties loaded from rootProject key.properties file with existence check guard"
    - "Credential gitignore pattern: *.jks + *.keystore + android/key.properties all gitignored before creation"
    - "key.properties lives inside android/ dir, gitignored by android/.gitignore, referenced by build.gradle.kts via rootProject.file()"

key-files:
  created:
    - android/key.properties (gitignored — not committed; holds real passwords after Task 4)
  modified:
    - android/app/build.gradle.kts (signingConfigs release block + Properties import + applicationId change)
    - .gitignore (appended *.jks, *.keystore, android/key.properties entries)
    - pubspec.yaml (version 0.1.0+1 → 1.0.0+1, url_launcher added)

key-decisions:
  - "applicationId confirmed as ridewindow.joost.amsterdam (user selected this over com.fanalists.ridewindow.ridewindow and com.fanalists.ridewindow) — PERMANENT, cannot change after first Play Console upload"
  - "Upload keystore at ~/upload-keystore.jks (outside project dir — never at risk of being committed)"
  - "key.properties gitignored via android/.gitignore (pre-existing Android gitignore) — double-protection with root .gitignore"
  - "versionCode uses flutter.versionCode (derived from pubspec.yaml version build number) — keeps Gradle and pubspec in sync"

patterns-established:
  - "Pattern: All release signing credentials flow through android/key.properties only — no hardcoded passwords in any committed file"
  - "Pattern: key.properties must be the first thing gitignored, before it is created — prevents accidental staging"

requirements-completed:
  - REL-01
  - REL-02

# Metrics
duration: ~2 days (human-paced — included Android Studio install, license acceptance, keystore generation, and password manager backup)
completed: 2026-06-05
---

# Phase 10 Plan 01: Android SDK + Keystore + Signing Config Summary

**Android upload keystore created and backed up, release signing wired into Kotlin DSL build.gradle.kts with applicationId confirmed as ridewindow.joost.amsterdam, credentials gitignored, version bumped to 1.0.0+1**

## Performance

- **Duration:** ~2 days (human-paced — multiple manual checkpoints)
- **Started:** 2026-06-04 (Phase 10 execution started)
- **Completed:** 2026-06-05
- **Tasks:** 4 (2 automated, 2 human-action checkpoints)
- **Files modified:** 4 (build.gradle.kts, .gitignore, pubspec.yaml, android/key.properties)

## Accomplishments
- Android SDK installed via Android Studio; `flutter doctor` shows Android toolchain ready
- applicationId permanently set to `ridewindow.joost.amsterdam` (confirmed via Task 2 checkpoint before any Play Console upload)
- Release signing config wired in build.gradle.kts using Kotlin DSL Pattern 1 — keystoreProperties loaded from `android/key.properties` with file existence guard
- Upload keystore generated at `~/upload-keystore.jks` (outside project directory, never at risk of being committed)
- Keystore backed up to password manager with storePassword, keyPassword, keyAlias, and jks file attachment
- .gitignore hardened with `*.jks`, `*.keystore`, `android/key.properties` entries before any credential files were created
- pubspec.yaml version bumped from `0.1.0+1` to `1.0.0+1` for first Play Console upload (versionCode=1)
- `url_launcher: ^6.3.1` added to pubspec.yaml for future About screen privacy policy link

## Task Commits

1. **Task 1: Install Android Studio + SDK + accept licenses** — human-action checkpoint (no commit; environment setup)
2. **Task 2: Confirm applicationId** — decision checkpoint; chose `ridewindow.joost.amsterdam` (no commit)
3. **Task 3: Harden .gitignore + apply applicationId + wire signing config + bump version + add url_launcher** — `f913f51` (chore)
4. **Task 4: Generate upload keystore + back up to password manager** — human-action checkpoint; key.properties updated with real passwords (gitignored, not committed)

## Files Created/Modified
- `android/app/build.gradle.kts` — Added Properties/FileInputStream imports, keystoreProperties loading block, signingConfigs.create("release") block, release buildType signingConfig assignment; applicationId set to ridewindow.joost.amsterdam
- `.gitignore` — Appended signing credential exclusion entries (*.jks, *.keystore, android/key.properties)
- `pubspec.yaml` — version bumped to 1.0.0+1; url_launcher ^6.3.1 added under dependencies
- `android/key.properties` — Created with real passwords (gitignored by android/.gitignore — never committed)

## Decisions Made
- **applicationId = `ridewindow.joost.amsterdam`** — User selected this over the original double-suffix `com.fanalists.ridewindow.ridewindow` and the shorter `com.fanalists.ridewindow`. This is permanent once the first AAB is uploaded to Play Console.
- **Keystore location `~/upload-keystore.jks`** — Stored outside the project directory entirely. No .gitignore entry needed for the file itself; only `android/key.properties` (which stores the path reference) needs to be gitignored.
- **`versionCode = flutter.versionCode`** — Gradle derives versionCode from pubspec.yaml version build number (`+1`). Keeps pubspec.yaml as the single source of truth for versioning.
- **`namespace = applicationId = ridewindow.joost.amsterdam`** — Both fields in build.gradle.kts use the same confirmed ID. AndroidManifest.xml has no package attribute, so no change needed there.

## Deviations from Plan

None — plan executed exactly as written. All four tasks completed per spec. The keystore was generated with real passwords and backed up before continuing as required by Task 4 acceptance criteria.

## Issues Encountered

None — setup proceeded without blocking issues. Android Studio GUI installation and license acceptance completed as documented in the plan's how-to-verify steps.

## Threat Model Compliance

All four STRIDE threats mitigated as planned:
- **T-10-01** (key.properties committed): Gitignored via `android/.gitignore` before file creation. `git check-ignore -v` confirms exclusion.
- **T-10-02** (*.jks committed): `*.jks` entry in root `.gitignore`; keystore lives at `~/upload-keystore.jks` (outside project dir, extra defense-in-depth).
- **T-10-03** (keystore lost): Backed up to password manager with file attachment and credential notes before proceeding.
- **T-10-04** (wrong applicationId after upload): Task 2 checkpoint forced explicit developer confirmation before any upload action.

## User Setup Required

The following credentials were set up by the developer and are stored outside version control:
- `~/upload-keystore.jks` — Upload keystore file (backed up to password manager)
- `android/key.properties` — Real storePassword, keyPassword, keyAlias, storeFile path (gitignored)

Any developer who clones this repo will need to:
1. Obtain the keystore file from the password manager backup
2. Create `android/key.properties` with the real credentials
3. Run `flutter pub get` before building

## Next Phase Readiness
- All prerequisites for `10-02-PLAN.md` (signed release AAB build) are complete
- `flutter build appbundle --release` should now use the release signing config
- url_launcher is available for `10-03-PLAN.md` (privacy policy About screen)
- applicationId is locked in — Play Console listing can be created with `ridewindow.joost.amsterdam`

---
*Phase: 10-release-internal-track-only*
*Completed: 2026-06-05*

## Self-Check: PASSED

- `android/app/build.gradle.kts` — exists and contains `create("release")` signing config
- `.gitignore` — exists and contains `*.jks` and `android/key.properties`
- `pubspec.yaml` — version line is `version: 1.0.0+1`
- `android/key.properties` — exists with no PLACEHOLDER values, correctly gitignored
- Commit `f913f51` — exists in git log (Task 3 automated commit)
- `~/upload-keystore.jks` — exists on disk (user-confirmed in Task 4)
