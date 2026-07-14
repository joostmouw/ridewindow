# RideWindow — v2.0 Requirements

**Scope:** Flutter Web/PWA build of RideWindow, deployed to Firebase Hosting, to reach iOS users without a native App Store app. Reuses the existing Dart codebase (scoring, slots, availability — already validated in v1.0). Notifications and background refresh via WorkManager are explicitly out of scope (no web support / iOS Safari limitations). All locked decisions from `.planning/PROJECT.md`.

**REQ-ID format:** `[CATEGORY]-[NUMBER]` — stable across phase transitions. Categories `LOC` and `CAL` continue numbering from v1.0 (same feature area, now ported to web).

---

## v2.0 Requirements

### Web (WEB) — Build & scaffolding

- [ ] **WEB-01**: `web/` platform is added via `flutter create --platforms web .` and committed
- [ ] **WEB-02**: `flutter build web --release` (CanvasKit renderer, not `--wasm`) builds without errors
- [ ] **WEB-03**: Existing UI (Welcome, Onboarding, Home, Ride Detail, Profile, Availability) renders and navigates correctly via `go_router` when run in a browser, with zero domain/UI code changes
- [ ] **WEB-04**: Native-only plugins with no web implementation (`workmanager`, `home_widget`) are guarded with `kIsWeb` checks at their call sites in `main.dart`
- [ ] **WEB-05**: A `flutter build apk` regression check confirms the existing Android app still builds and runs unchanged after web-platform additions

### Persistence (PERS) — Web storage backend

- [ ] **PERS-05**: Drift database uses `DriftWebOptions` (`sqlite3.wasm` + `drift_worker.dart.js`) on web, alongside the existing native `DriftNativeOptions`
- [ ] **PERS-06**: Data written to Drift on web survives a full page reload (manually verified, not just assumed from a successful build)
- [ ] **PERS-07**: `sqlite3.wasm` is served with `Content-Type: application/wasm` from Firebase Hosting (explicit `firebase.json` header rule if needed)

### Location (LOC) — Web geolocation + fallback

- [ ] **LOC-06**: Geolocation works via the browser Geolocation API (`geolocator_web`) over HTTPS on the deployed Firebase Hosting domain
- [ ] **LOC-07**: On web, geolocation permission denial or timeout immediately surfaces the manual city picker as the primary path (not a rare fallback), reflecting iOS Safari's per-session re-prompt behavior

### Refresh (REFRESH) — Foreground refresh strategy (WorkManager replacement)

- [ ] **REFRESH-01**: A `kIsWeb`-gated foreground refresh trigger calls `ref.invalidate(weatherProvider)` on page load and on regaining focus/visibility
- [ ] **REFRESH-02**: User can manually pull-to-refresh to force a re-fetch
- [ ] **REFRESH-03**: UI displays a "Last updated HH:MM" label reflecting the cache-then-network pattern
- [ ] **REFRESH-04**: When a fetch fails (offline or error), the UI shows the last-known slots clearly labeled as stale, rather than a blank screen or crash

### Calendar (CAL) — Web OAuth integration

- [x] **CAL-06**: `CalendarService` initializes with a platform-conditional web OAuth `clientId` (from Google Cloud Console) on web; native config unchanged on Android
- [x] **CAL-07**: "Add to calendar" is manually verified end-to-end against the deployed production Firebase Hosting domain (not just localhost), including the OAuth popup/consent flow in a real browser

### PWA (PWA) — iOS installability & polish

- [ ] **PWA-01**: `web/index.html` includes `apple-touch-icon`, `apple-touch-startup-image`, `theme_color`, and `background_color` tags tuned for iOS
- [ ] **PWA-02**: Manifest and meta tags configure `display: standalone`, `apple-mobile-web-app-capable`, `apple-mobile-web-app-status-bar-style`, and `env(safe-area-inset-*)` CSS for notch/Dynamic Island devices
- [ ] **PWA-03**: A custom "Add to Home Screen" instructional overlay is shown on iOS Safari in browser mode (not standalone), detected via the `display-mode: standalone` media query; Android Chrome uses its own native `beforeinstallprompt` flow instead
- [ ] **PWA-04**: In-app back/close navigation works correctly in standalone mode (no browser chrome to fall back on)
- [ ] **PWA-05**: The install flow and storage persistence are manually verified on a real iPhone in Safari (not just desktop dev tools or simulator)

### Deployment (DEPLOY) — Firebase Hosting

- [ ] **DEPLOY-01**: `firebase.json` configures the Flutter web build output (`build/web`) as the Hosting public directory with correct rewrite rules for client-side routing
- [ ] **DEPLOY-02**: The app is deployed to Firebase Hosting via `firebase deploy` and reachable at a stable HTTPS URL
- [ ] **DEPLOY-03**: A full regression pass confirms the existing Android app (build, run, core flows) is unaffected by the web-platform additions

---

## Future Requirements (deferred)

- **Contextual "Add to Home Screen" nudge** after N genuinely useful sessions — deferred until the static overlay's install rate is measured
- **`navigator.storage.persist()` + quota warning** — no-op on iOS Safari today; revisit if real-world data loss is reported
- **`display-mode` based onboarding copy variants** (browser-tab vs. installed-app) — deferred until there's usage data to justify it
- **Availability-calendar export/import** — only worth building if the storage-eviction risk (PERS-06 related) is confirmed in practice for installed PWAs

## Out of Scope (v2.0)

See `.planning/PROJECT.md` "Out of Scope" section for full list with reasoning. Summary:

- **Push notifications on web** — iOS Safari Web Push only works for an installed PWA (16.4+) and is unreliable; not worth building until PWA install adoption is proven
- **True background refresh on web** — Safari does not implement the Periodic Background Sync API at all; on-load/on-focus/pull-to-refresh (REFRESH category) is the accepted ceiling
- **Native iOS App Store app** — v2.0 addresses iOS via web/PWA instead, avoiding the $99/yr Apple Developer account
- **User accounts / backend / cross-device sync** — still local-only, per-browser storage
- **Monetization, multi-location, social features, smartwatch companion, cycling-type profiles, historical analytics** — same reasoning as v1.0 (see PROJECT.md)

---

## Definition of Done (per Phase)

Generic acceptance criteria applied to every phase:
- All requirements mapped to the phase have passing tests where automatable (unit/widget), **plus an explicit manual real-iPhone-Safari verification step** where PITFALLS.md flags it — automated tests cannot catch iOS Safari-specific behavior
- No new pitfalls from `.planning/research/PITFALLS.md` introduced (cross-check before merge)
- Existing Android app (`flutter build apk`) still builds and passes its existing test suite — no regressions from web-platform additions
- Phase-specific success criteria from `.planning/ROADMAP.md` are demonstrably met (run the app, click through the feature, in both a browser and — where relevant — real iPhone Safari)

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| WEB-01 | Phase 11 | Pending |
| WEB-02 | Phase 11 | Pending |
| WEB-03 | Phase 11 | Pending |
| WEB-04 | Phase 11 | Pending |
| WEB-05 | Phase 11 | Pending |
| PERS-05 | Phase 12 | Pending |
| PERS-06 | Phase 12 | Pending |
| PERS-07 | Phase 12 | Pending |
| LOC-06 | Phase 13 | Pending |
| LOC-07 | Phase 13 | Pending |
| REFRESH-01 | Phase 14 | Pending |
| REFRESH-02 | Phase 14 | Pending |
| REFRESH-03 | Phase 14 | Pending |
| REFRESH-04 | Phase 14 | Pending |
| CAL-06 | Phase 15 | Complete |
| CAL-07 | Phase 15 | Complete |
| PWA-01 | Phase 16 | Pending |
| PWA-02 | Phase 16 | Pending |
| PWA-03 | Phase 16 | Pending |
| PWA-04 | Phase 16 | Pending |
| PWA-05 | Phase 16 | Pending |
| DEPLOY-01 | Phase 17 | Pending |
| DEPLOY-02 | Phase 17 | Pending |
| DEPLOY-03 | Phase 17 | Pending |

**Coverage:** 24/24 v2.0 requirements mapped. No orphans.
