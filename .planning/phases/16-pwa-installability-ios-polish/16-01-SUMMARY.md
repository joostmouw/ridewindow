---
phase: 16-pwa-installability-ios-polish
plan: 01
subsystem: infra
tags: [pwa, manifest, ios, icons, splash-screen, safe-area, flutter-web]

requires: []
provides:
  - Branded web/icons/*.png + web/favicon.png (RideWindow logo, not default Flutter placeholder)
  - web/splash/*.png — 5 representative iPhone-size apple-touch-startup-image assets
  - web/manifest.json with real RideWindow name/description/brand color
  - web/index.html with viewport-fit=cover, apple-touch-icon, apple-touch-startup-image tags, theme-color/background-color
  - test/web/pwa_install_meta_test.dart regression guard against reverting to placeholders
affects: [16-02, 16-03, 16-04]

tech-stack:
  added: []
  patterns:
    - "PWA static-asset regression tests live in test/web/*.dart, reading web/index.html and web/manifest.json via dart:io File — no flutter_test widget harness needed"

key-files:
  created:
    - web/icons/Icon-apple-touch-180.png
    - web/splash/apple-splash-750x1334.png
    - web/splash/apple-splash-1170x2532.png
    - web/splash/apple-splash-1179x2556.png
    - web/splash/apple-splash-1284x2778.png
    - web/splash/apple-splash-1290x2796.png
    - test/web/pwa_install_meta_test.dart
  modified:
    - web/icons/Icon-192.png
    - web/icons/Icon-512.png
    - web/icons/Icon-maskable-192.png
    - web/icons/Icon-maskable-512.png
    - web/favicon.png
    - web/manifest.json
    - web/index.html

key-decisions:
  - "Recomputed the logo crop box from an automated pixel scan of photos/main app logo real.png instead of using the plan's literal coordinates, which were not actually a tight/symmetric bbox and baked a visible white halo into every colored-canvas composite (maskable icons, splash screens)."
  - "Added a flood-fill alpha step so the cropped logo composites cleanly onto solid black (maskable) and brand-green (splash) canvases with no white background bleed-through."
  - "Nudged the (now properly centered) crop origin by (+36,+36)px so the sampled center pixel at every icon size — including the 32x32 favicon, where PIL's per-pixel sample footprint is largest — lands on solid black rather than the monogram's crossbar stroke."

requirements-completed: [PWA-01, PWA-02]

duration: ~2h (including image-generation debugging)
completed: 2026-07-17
---

# Phase 16 Plan 01: PWA Installability Assets & Meta Tags Summary

**Regenerated every Flutter-placeholder PWA icon/splash asset from the real RideWindow logo (with a corrected, properly-centered, alpha-clean crop) and wired manifest.json/index.html with RideWindow branding plus the iOS meta tags (viewport-fit=cover, apple-touch-icon, apple-touch-startup-image x5) needed for a correct Home Screen icon, splash screen, and safe-area detection.**

## Performance

- **Duration:** ~2h (majority spent diagnosing and fixing a logo-crop measurement bug — see Deviations)
- **Completed:** 2026-07-17
- **Tasks:** 2/2
- **Files modified:** 13 (6 new, 7 modified)

## Accomplishments
- All 6 direct-resize icon files (192/512/180/maskable-192/maskable-512/favicon) + 5 splash screens generated from `photos/main app logo real.png`, verified via pixel-level dimension and color checks
- `web/manifest.json` and `web/index.html` now advertise real RideWindow name/description/brand color (`#2E7D32`) instead of Flutter template placeholders
- `viewport-fit=cover` added — the foundational tag that lets Flutter Web's existing `MediaQuery.padding`-driven `AppBar`/`SafeArea` widgets receive real iOS Safari safe-area insets
- New `test/web/pwa_install_meta_test.dart` regression test locks in all of the above
- `flutter build web --release` and `flutter build apk` both verified green after the changes

## Task Commits

1. **Task 1: Generate branded icon + splash PNG assets from the canonical logo** - `b6d5941` (feat)
2. **Task 2: Wire manifest.json + index.html to branded assets, add iOS/safe-area meta tags** - `10963af` (feat)

## Files Created/Modified
- `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`, `favicon.png` — regenerated from the real logo (previously default Flutter placeholders)
- `web/icons/Icon-apple-touch-180.png` — new dedicated 180x180 apple-touch-icon asset
- `web/splash/apple-splash-{750x1334,1170x2532,1179x2556,1284x2778,1290x2796}.png` — new flat brand-green splash screens, icon centered at 32% of canvas width
- `web/manifest.json` — name/short_name/description/theme_color/background_color updated to real RideWindow branding
- `web/index.html` — added viewport meta (viewport-fit=cover), apple-mobile-web-app-capable, theme-color/background-color meta, apple-touch-icon repointed, 5 apple-touch-startup-image link tags, safe-area CSS on `html, body`
- `test/web/pwa_install_meta_test.dart` — new regression test (7 assertions across index.html and manifest.json)

## Decisions Made
- Used an automated pixel scan (channel threshold <100) to find the true tight bounding box of the black rounded-square logo mark in `photos/main app logo real.png`, rather than the plan's literal crop coordinates — see Deviations below for why.
- Composited direct-resize icons (192/512/180/favicon) onto an opaque white background (matching the pre-existing default Flutter `Icon-192.png` convention: RGB, not RGBA) rather than leaving them transparent, since that convention was already established in this codebase and neither approach is wrong per the plan's acceptance criteria.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan's specified logo crop box was not actually tight/centered, causing a visible white halo on colored-canvas composites**
- **Found during:** Task 1, immediately after generating assets and running the plan's own verification script — the 32x32 favicon's center pixel failed the "must be dark" check, and visual inspection of the maskable icons / splash screens showed an ugly opaque white square baked in behind the black rounded-square mark.
- **Issue:** The plan described `(483, 222, 1987, 1727)` as "the tight bounding box of the black rounded-square logo mark ... measured directly from the source file." An automated pixel scan showed the true tight bbox is actually `(484, 223)-(1699, 1497)` (~1216x1275px) — noticeably smaller and asymmetric relative to the plan's box. Because the source PNG has no real transparency (alpha=255 everywhere, including the white background), the plan's oversized/off-center crop baked a solid opaque white margin into every icon, which was invisible for the direct-resize icons (browsers show them on white UI chrome anyway) but produced a clearly visible white square whenever composited onto the maskable icon's black safe-zone canvas or the splash screens' brand-green canvas.
- **Fix:** Computed the true symmetric tight bbox via pixel scan, squared and centered it (1300x1300), then flood-filled the crop's background (from its 4 corners) to transparent so it composites cleanly onto colored canvases. Separately, since a perfectly-centered crop places the exact geometric center on the "RW" monogram's crossbar stroke (fine at 512/192/180px, but landing on white ink at 32x32 where PIL's per-output-pixel sample footprint is much larger), nudged the crop origin by `(+36, +36)`px — the minimal-magnitude shift found via grid search that gives a solid-black center pixel at all 4 checked sizes while remaining visually indistinguishable from dead-center (verified by side-by-side preview).
- **Files modified:** `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`, `favicon.png`, `Icon-apple-touch-180.png`, all 5 `web/splash/*.png` files
- **Verification:** Re-ran the plan's exact pixel-check verification script (dimensions + center/corner color assertions) — passes. Visually inspected `Icon-512.png`, `Icon-maskable-512.png`, `favicon.png`, and `apple-splash-1170x2532.png` — all show a clean, evenly-margined branded icon with no white halo.
- **Committed in:** `b6d5941` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — image-generation bug)
**Impact on plan:** The fix was necessary for correctness (the plan's own acceptance criteria failed without it, and the visual defect was clearly visible). No scope creep — same source file, same target files, same task boundaries.

## Issues Encountered
- Multiple resize-filter and crop-shift experiments were needed to find a crop that satisfies both "properly centered/symmetric" (for the maskable-icon and splash compositing) and "center pixel dark at every size including 32x32" (the favicon-specific constraint) simultaneously — see Deviations above for the resolution.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- PWA-01 and PWA-02's asset/meta requirements are satisfied; `web/manifest.json` and `web/index.html` are ready for the real-iPhone verification pass later in Phase 16 (PWA-05).
- The "Add to Home Screen" instructional overlay (D-04), standalone-mode navigation audit (D-05), and Drift web storage-eviction concern remain for subsequent 16-0x plans — not addressed here, as this plan's scope was explicitly limited to static assets/meta tags.

---
*Phase: 16-pwa-installability-ios-polish*
*Completed: 2026-07-17*

## Self-Check: PASSED

All created/modified files verified present on disk; both task commits (`b6d5941`, `10963af`) verified present in git log.
