---
phase: 10-release-internal-track-only
plan: "03"
subsystem: ui
tags: [privacy-policy, github-pages, profile-screen, url-launcher, about-section]

# Dependency graph
requires:
  - plan: 10-01
    provides: url_launcher added to pubspec.yaml
provides:
  - Privacy policy at https://joostmouw.github.io/ridewindow-privacy/
  - ProfileScreen OVER section with Privacybeleid link + Versie 1.0.0
affects:
  - 10-04 (Play Console store listing — privacy policy URL needed for store listing)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "launchUrl with LaunchMode.externalApplication for opening external URLs"
    - "_kPrivacyPolicyUrl as top-level const for privacy policy URL"

key-files:
  modified:
    - lib/features/profile/profile_screen.dart (OVER section added after RIJLENGTE)

key-decisions:
  - "Privacy policy published in Dutch at https://joostmouw.github.io/ridewindow-privacy/ via separate public GitHub repo"
  - "_kPrivacyPolicyUrl as file-level const (not class-level) — consistent with other constants in the file"
  - "canLaunchUrl guard before launchUrl — graceful no-op if browser unavailable"

# Metrics
duration: ~5 minutes
completed: 2026-06-05
---

# Phase 10 Plan 03: Privacy Policy + ProfileScreen OVER Section Summary

**Privacy policy published at GitHub Pages; ProfileScreen OVER section added with Privacybeleid link (external browser) and Versie 1.0.0 tile**

## Performance

- **Duration:** ~5 minutes
- **Started:** 2026-06-05
- **Completed:** 2026-06-05
- **Tasks:** 2 (1 human-action checkpoint, 1 automated)
- **Files modified:** 1 (lib/features/profile/profile_screen.dart)

## Accomplishments

- Privacy policy published at https://joostmouw.github.io/ridewindow-privacy/ (separate public GitHub repo, GitHub Pages enabled)
- ProfileScreen OVER section added with:
  - "Privacybeleid" ListTile with open_in_new icon → opens GitHub Pages URL via launchUrl(mode: LaunchMode.externalApplication)
  - "Versie" ListTile showing "1.0.0"
- `flutter analyze` clean — no issues found

## Task Commits

1. **Task 1: Create ridewindow-privacy GitHub repo and publish GitHub Pages** — human-action (completed by developer)
2. **Task 2: Add OVER section to ProfileScreen** — `694d1b7` (feat)

## Files Created/Modified

- `lib/features/profile/profile_screen.dart` — Added `import 'package:url_launcher/url_launcher.dart'`, `_kPrivacyPolicyUrl` const, `_launchPrivacyPolicy()` method, OVER section with Privacybeleid and Versie ListTiles

## Deviations from Plan

None — plan executed as specified.

## Issues Encountered

None.

## Threat Model Compliance

- **T-10-08** (privacy policy URL changes): Mitigated — URL is hardcoded as `_kPrivacyPolicyUrl` const; GitHub Pages URL is stable as long as repo exists
- **T-10-09** (privacy policy understates data collection): Mitigated — policy declares location (GPS, app functionality) and Google Calendar (optional, user-initiated only)

## Known Stubs

None.

## Next Phase Readiness

- Privacy policy URL ready for Play Console store listing (Plan 10-04 Task 1 Step 3)
- ProfileScreen OVER section complete — no further changes needed

---
*Phase: 10-release-internal-track-only*
*Completed: 2026-06-05*

## Self-Check: PASSED

- `lib/features/profile/profile_screen.dart` contains `url_launcher/url_launcher.dart` import (1)
- `lib/features/profile/profile_screen.dart` contains `_kPrivacyPolicyUrl` (2 occurrences: declaration + usage)
- `lib/features/profile/profile_screen.dart` contains `launchUrl` (1)
- `lib/features/profile/profile_screen.dart` contains `LaunchMode.externalApplication` (1)
- `lib/features/profile/profile_screen.dart` contains `'Privacybeleid'` (1)
- `lib/features/profile/profile_screen.dart` contains `'Versie'` (1)
- `lib/features/profile/profile_screen.dart` contains `'1.0.0'` (1)
- `flutter analyze lib/features/profile/profile_screen.dart` — No issues found
