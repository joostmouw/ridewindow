---
phase: 16-pwa-installability-ios-polish
plan: 04
subsystem: deployment
tags: [pwa, ios, firebase-hosting, real-device-verification]

requires:
  - phase: 16-pwa-installability-ios-polish (Plan 01)
    provides: "Branded icons/splash/manifest.json/index.html meta tags"
  - phase: 16-pwa-installability-ios-polish (Plan 02)
    provides: "Add-to-Home-Screen overlay (isStandaloneDisplayMode/isIosBrowserMode detection + banner)"
  - phase: 16-pwa-installability-ios-polish (Plan 03)
    provides: "SafeBackButton — standalone-mode navigation dead-end fix"
provides:
  - "Live deploy of all Phase 16 (16-01/02/03) changes to https://my-project-joost.web.app"
  - "Real iPhone Safari verification: install, standalone mode, branded icon/splash, navigation, safe-area — all confirmed working"
affects: []

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified: []

key-decisions:
  - "Steps 1-5 of the real-device checkpoint approved by user; step 6 (multi-day ITP storage-eviction check) carried forward as a documented pending follow-up per the plan's own allowance"

requirements-completed: [PWA-05]

duration: ~1h (including checkpoint wait)
completed: 2026-07-17
---

# Phase 16 Plan 04: Deploy + Real iPhone Safari Verification (PWA-05) Summary

**RideWindow's PWA deploy verified end-to-end on a real iPhone in Safari: branded install icon, standalone-mode launch with correct splash and safe-area, and working in-app back navigation.**

**Status: Complete. Checkpoint approved by user (steps 1-5 all pass).**

## Performance

- **Duration:** ~1h (a few minutes of build+deploy, remainder was checkpoint wait for real-device testing)
- **Completed:** 2026-07-17
- **Tasks:** 2/2

## Accomplishments
- Deployed Plans 16-01/02/03 to the live Firebase Hosting domain
- Confirmed on a real iPhone in Safari: Add-to-Home-Screen banner appears in browser mode, branded RW-monogram icon installs correctly, standalone launch shows the branded splash with no browser chrome, in-app back navigation works (Availability, Ride Detail, cold launch), and safe-area insets are respected (notch/Dynamic Island, Home indicator)

## Task Commits

Deploy-only plan — no source file changes (`files_modified: []` per plan frontmatter). The deployed snapshot was already-committed HEAD `019b888`.

## Files Created/Modified
None — deployment-only plan.

## Decisions Made
- Step 6 (multi-day ITP storage-eviction check) is accepted as a pending follow-up rather than a blocker — the plan explicitly allows closing on steps 1-5 passing, since the multi-day wait can't reasonably gate this checkpoint's approval.

## Deviations from Plan
None — Task 1 executed exactly as written (same deploy path used earlier this session: `flutter build web --release` then `firebase deploy --only hosting`, reusing the existing Phase 15-02 Firebase project configuration). Task 2's checkpoint was approved as specified.

## Issues Encountered
None.

## User Setup Required
None — real iPhone verification (the "setup" this plan required) is now complete.

## Next Phase Readiness

Phase 16 (PWA Installability & iOS Polish) is fully complete — all 5 requirements (PWA-01 through PWA-05) shipped and verified, including the real-device checkpoint. Ready to proceed to Phase 17 (Deployment Hardening & Firebase Hosting).

**Outstanding, non-blocking follow-up:** step 6's multi-day ITP storage-eviction check has not yet elapsed. Revisit in a few days — reopen the installed PWA and confirm the test Availability toggle written during verification is still present. If it was evicted, this would need a dedicated follow-up (e.g. `navigator.storage.persist()`, already noted in REQUIREMENTS.md's Future Requirements).

---
*Phase: 16-pwa-installability-ios-polish*
*Completed: 2026-07-17*

## Self-Check: PASSED

Deploy confirmed live: `firebase deploy --only hosting` reported "Deploy complete!" with Hosting URL `https://my-project-joost.web.app`. HEAD commit `019b888` confirmed as the exact snapshot built and deployed. Checkpoint approved by user for steps 1-5.
