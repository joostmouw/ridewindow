# Phase 16: PWA Installability & iOS Polish - Context

**Gathered:** 2026-07-17
**Status:** Ready for planning

<domain>
## Phase Boundary

iOS users can add RideWindow to their Home Screen and use it as a standalone app with correct icons, splash screen, safe-area layout, and in-app navigation — and their data durably survives Safari's storage eviction policy. This phase covers `web/index.html` meta tags, `web/manifest.json`, a custom "Add to Home Screen" instructional overlay, standalone-mode navigation, and manual real-iPhone verification (PWA-01 through PWA-05).

</domain>

<decisions>
## Implementation Decisions

### App icon & branding source
- **D-01:** The web/iOS app icon and splash-screen artwork MUST be derived from RideWindow's existing custom Android launcher icon — `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png` (calendar grid + winding road + cyclist silhouette on a dark rounded-square background). The current `web/icons/Icon-192.png` / `Icon-512.png` / maskable variants are still the generic default Flutter logo placeholder — these MUST be replaced, not kept.
- **D-02:** Same source icon applies to `apple-touch-icon` in `web/index.html` (currently pointing at the default `icons/Icon-192.png`, which needs to become the real branded icon).

### Splash screen
- **D-03:** `apple-touch-startup-image` splash screens show the RideWindow icon centered on a flat background in the manifest's brand `theme_color` (`#0175C2` in the current placeholder `manifest.json` — verify this is still the intended "cycling green" brand color from PROJECT.md's Material 3 seed, or update to match; do not introduce a third, different brand color).
- **Claude's Discretion:** How many iPhone device-size splash variants to generate (full matrix vs a representative subset) — pick whatever a standard Flutter/PWA splash-generation approach produces, favoring correctness on the actual test devices used in PWA-05 verification over exhaustive coverage of every historical iPhone model.

### "Add to Home Screen" overlay timing
- **D-04:** The instructional overlay appears on **every session** while the app is running in iOS Safari browser mode (not yet installed) — NOT a one-time dismissible hint. It must auto-hide as soon as `display-mode: standalone` is detected (i.e., once the user actually installs it, the overlay disappears for good since the media query stops matching). This is a deliberate contrast with the existing `ScreenHintOverlay` pattern (`lib/features/shared/screen_hint_overlay.dart`, `shouldShowHint`/`markHintSeen` via `shared_preferences`) — do NOT reuse that one-time-dismiss persistence mechanism for this overlay. A different, simpler always-show-until-standalone component is expected.

### Standalone-mode back/close navigation
- **D-05:** No specific screen is currently known to be broken — the user has not identified a concrete failing flow. The phase's research/planning step should generically audit the app's `go_router` navigation stack (`lib/app/`) for any screen that assumes a browser back button exists, and add explicit in-app back/close affordances wherever missing, rather than the user pre-specifying which screens need it.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & requirements
- `.planning/ROADMAP.md` §"Phase 16: PWA Installability & iOS Polish" — phase goal, success criteria, requirements list (PWA-01..05)
- `.planning/REQUIREMENTS.md` §PWA-01 through PWA-05 — exact requirement wording and traceability table

### Existing branding source (must reuse, not recreate)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png` — the canonical RideWindow icon artwork (calendar + road + cyclist) to derive all new web/iOS icon and splash assets from
- `android/app/src/main/res/values/ic_launcher_background.xml` — the icon's background color definition, check for consistency with manifest `background_color`/`theme_color`

### Current web PWA scaffold (default Flutter placeholders to replace)
- `web/index.html` — current iOS meta tags (`mobile-web-app-capable`, `apple-mobile-web-app-status-bar-style`, `apple-mobile-web-app-title`, `apple-touch-icon`) exist but are generic/default; missing `apple-mobile-web-app-capable` (legacy iOS tag), `apple-touch-startup-image`, explicit `theme-color`/`background-color` `<meta>` tags (PWA-01/02 require these)
- `web/manifest.json` — generic Flutter placeholder (`"name": "ridewindow"`, `"description": "A new Flutter project."`); icons array points at the default Flutter logo files, not the branded icon

### Related existing pattern (for contrast, not reuse)
- `lib/features/shared/screen_hint_overlay.dart` — the existing one-time coach-mark overlay pattern (`shouldShowHint`/`markHintSeen`, `shared_preferences`-backed). Per D-04, the new "Add to Home Screen" overlay must NOT use this same persistence mechanism — it's referenced here only so the researcher/planner understands why a different approach is intentional, not an oversight.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png` — source artwork for all new web icon/splash generation (highest resolution available in the repo)
- Flutter web's default PWA scaffold (`web/manifest.json`, `web/index.html`) already has the basic structure (manifest link, some iOS meta tags) — this phase edits/extends it in place rather than starting from scratch

### Established Patterns
- `lib/features/shared/screen_hint_overlay.dart`'s `shouldShowHint`/`markHintSeen` `shared_preferences` pattern is the app's existing "show once" convention — explicitly NOT the pattern to follow for the Add-to-Home-Screen overlay (see D-04)
- CSS `env(safe-area-inset-*)` is not yet used anywhere in the Flutter web build (this is a new integration point — Flutter's web renderer needs this threaded through either global CSS in `index.html` or `MediaQuery.of(context).padding` equivalents in Dart, whichever the researcher determines is the correct Flutter-web-specific approach)

### Integration Points
- `web/index.html` `<head>` — where new meta tags and splash-image `<link>` tags are added
- `web/manifest.json` — icon array and `theme_color`/`background_color` fields
- `lib/app/` (go_router configuration) — where standalone-mode back/close navigation gaps would be identified and fixed
- A new Dart widget (name TBD by planner) — the "Add to Home Screen" overlay, using a `display-mode: standalone` media query check (likely via `dart:html`/`package:web` on the Flutter web target) rather than the existing `ScreenHintOverlay` infrastructure

</code_context>

<specifics>
## Specific Ideas

User was explicit and specific about one thing: **reuse the real, existing RideWindow app icon** (`android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png` — calendar grid + winding road + cyclist silhouette) as the source for all new web/iOS branding artwork, rather than commissioning new artwork or using a generic/placeholder icon. This was said plainly: "main app logo real, deze gebruiken als logo aub."

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

### Reviewed Todos (not folded)
None — no pending todos matched this phase (`todo.match-phase 16` returned zero matches).

</deferred>

---

*Phase: 16-pwa-installability-ios-polish*
*Context gathered: 2026-07-17*
