# Project Research Summary

**Project:** RideWindow
**Domain:** Cross-platform weather/availability planning app — Flutter Web/PWA port for iOS
**Researched:** 2026-07-10
**Confidence:** MEDIUM-HIGH

## Executive Summary

RideWindow v2.0 is a platform port of an already-shipped Android app onto Flutter Web to reach iOS users without an Apple Developer account. The existing architecture (domain logic has zero platform imports; platform-coupled code is isolated to a handful of files: `app_database.dart`, `main.dart`, `gps_permission_notifier.dart`, `calendar_service.dart`) is already well-suited to this — it's a "swap/gate implementations at existing seams" job, not a rewrite.

Every existing package (Drift, geolocator, google_sign_in, shared_preferences, go_router) has a web-compatible implementation; only `sqlite3` and `drift_flutter` are genuinely new dependencies, plus manually-downloaded `sqlite3.wasm`/`drift_worker.dart.js` assets in `web/`. `workmanager` and `home_widget` have zero web support and must be `kIsWeb`-guarded rather than ported.

The dominant risk theme is that iOS Safari behaves fundamentally differently than Chrome-first web tooling assumes: no `beforeinstallprompt` (install is always a manual Share-sheet action), stricter popup blocking on OAuth flows, ITP-driven storage eviction under prolonged inactivity, and `manifest.json` being largely ignored in favor of `apple-touch-icon`/`apple-mobile-web-app-*` meta tags. Mitigation is consistent across all four research files: drive "Add to Home Screen" adoption (installed PWAs get bigger storage quotas and are exempted from some tab-level eviction), and require real-iPhone-in-Safari verification as an explicit success criterion on every phase — none of this is catchable by widget/integration tests.

## Key Findings

### Recommended Stack

Add `sqlite3` (^3.0.0) and `drift_flutter` (^0.3.0) for Drift's web backend (OPFS-first, IndexedDB fallback), plus manually-downloaded version-matched `sqlite3.wasm` and `drift_worker.dart.js` in `web/` — this is a manual asset-pinning step, not a pub-fetched dependency, and easy to get silently wrong. `google_sign_in` 7.2.0 and `geolocator` 14.0.2 already work on web with no new packages (federated web plugins are auto-included); only a few methods (`openAppSettings()`, `getLastKnownPosition()`) throw `UnsupportedError` on web and need guards. Deploy via Firebase Hosting using classic static hosting (`build/web` as public dir) — not the framework-aware Hosting preview, which targets SSR frameworks and is unstable for this use case. Open-Meteo is CORS-enabled, so the existing `http`-based weather fetch works unmodified from the browser.

**Core technologies:**
- `drift_flutter` (^0.3.0) + `sqlite3` (^3.0.0): Drift web storage backend — additive `DriftWebOptions(sqlite3Wasm:, driftWorker:)` param, not a rewrite
- `google_sign_in` 7.2.0 (existing): already supports web via Google Identity Services — needs a platform-conditional web `clientId` from Google Cloud Console, no new package
- `geolocator` 14.0.2 (existing): web support via auto-included `geolocator_web`, wraps browser Geolocation API — guard a few unsupported methods
- Firebase Hosting (classic static mode): free tier, simple `firebase deploy`, matches CLAUDE.md's "no ongoing infra cost" constraint

### Expected Features

**Must have (table stakes):**
- Manifest icons/splash via `apple-touch-icon` + `apple-mobile-web-app-*` meta tags (Safari mostly ignores `manifest.json` for this)
- Custom "Add to Home Screen" instructional overlay (no `beforeinstallprompt` on iOS — must be built manually, hidden via `display-mode: standalone` once installed)
- Cache-then-network refresh pattern with a visible "last updated" timestamp, triggered on page-load/focus/pull-to-refresh (no background refresh capability exists on Safari at all)
- Manual city override promoted to a primary, load-bearing fallback (not a rare edge case) since iOS Safari re-prompts geolocation per session with no "Always Allow"

**Should have (competitive):**
- Google Calendar integration ported to web (already in scope per user decision)
- Offline fallback UI for no-network state

**Defer (v2.1+):**
- Push notifications on web (out of scope per milestone decision — Safari Web Push only works for installed PWAs on 16.4+ and is unreliable)
- Background refresh via any web equivalent — doesn't exist; on-demand refresh is the permanent replacement, not a stopgap

### Architecture Approach

The current layering (domain → data → providers → UI) already isolates platform code well enough that `ScoringEngine`, `SlotGenerator`, `AvailabilityFilter`, and all UI screens need zero changes. All web-specific work concentrates in four files/areas: the Drift database opener, `main.dart`'s background-task registration, `GpsPermissionNotifier`, and the Calendar OAuth service. The project has no `web/` directory yet — `flutter create --platforms web .` is the literal first step.

**Major components:**
1. `AppDatabase` web opener — `driftDatabase(web: DriftWebOptions(...))` alongside the existing native opener
2. `kIsWeb`-guarded background trigger — replaces `workmanager` registration in `main.dart` with a foreground/resume-triggered `ref.invalidate(weatherProvider)`
3. Platform-conditional Google Sign-In `clientId` — web OAuth client ID from Google Cloud Console, passed to `initialize()` only on web
4. PWA shell — `manifest.json`, `index.html` meta tags, service worker, Firebase Hosting config (headers for `.wasm` Content-Type)

### Critical Pitfalls

1. **Wasm/Skwasm renderer has open Safari compatibility bugs** — build with `flutter build web --release` (CanvasKit), not `--wasm`, for this milestone; verify on real iPhone hardware.
2. **Safari's ITP storage eviction threatens Drift's IndexedDB-backed cache** — directly relevant given RideWindow's "check once or twice a week" usage pattern; driving PWA installation is a data-durability requirement, not just UX polish, since installed PWAs get exempted/larger quotas.
3. **`google_sign_in` web has two Safari-specific failure modes** — popup blocked unless `signIn()` is called synchronously inside the tap handler, and Safari doesn't support FedCM at all (Google is migrating GIS toward it) — needs hands-on validation, not just doc-reading.
4. **`kIsWeb` is a runtime check, not compile-time** — using it alone to gate native-only plugin imports (workmanager, exact-alarm notifications, home_widget) can break a platform's build; proper conditional-import stub files are needed, plus a `flutter build apk` regression check on every phase touching shared code.
5. **Widget/integration tests structurally cannot catch most of these pitfalls** — real Safari/iOS device verification must be a named, explicit success criterion on every phase, not a final QA afterthought.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Web Scaffolding & Build Baseline
**Rationale:** Nothing else can be verified until the existing UI/routing/domain layer is proven to render on `flutter build web` with zero code changes — establishes the renderer choice and conditional-import discipline that every later phase depends on.
**Delivers:** `web/` platform added via `flutter create --platforms web .`; app builds and runs in a browser using CanvasKit (not `--wasm`); `kIsWeb` guard pattern established for native-only plugins.
**Addresses:** Baseline app-shell rendering (FEATURES.md table stakes).
**Avoids:** Wasm/Skwasm renderer compatibility bugs (Pitfall #1).

### Phase 2: Drift Web Persistence
**Rationale:** Highest silent-failure risk in the milestone — must be proven with a real write-then-reload test before any feature work depends on it.
**Delivers:** `sqlite3` + `drift_flutter` wired with `DriftWebOptions`; manually-pinned `sqlite3.wasm`/`drift_worker.dart.js` assets in `web/`; verified data survives a page reload.
**Uses:** `sqlite3` (^3.0.0), `drift_flutter` (^0.3.0) from STACK.md.
**Implements:** `AppDatabase` web opener component from ARCHITECTURE.md.

### Phase 3: Geolocation & Manual Fallback
**Rationale:** iOS Safari's per-session geolocation re-prompting means the existing manual-city-override feature must be promoted from edge case to primary, load-bearing fallback to protect the app's "2s cold start" promise.
**Delivers:** `geolocator` web wiring with guards around unsupported methods (`getLastKnownPosition`, `openAppSettings`); manual city picker surfaced prominently in the web UI flow.
**Addresses:** Geolocation feature parity (FEATURES.md).
**Avoids:** Silent failures from calling web-unsupported geolocator methods (noted in ARCHITECTURE.md).

### Phase 4: Foreground Refresh Strategy
**Rationale:** No web equivalent to WorkManager exists at all (not just "unsupported" — the Periodic Background Sync API isn't implemented in Safari); the replacement is a permanent behavior change, not a stopgap.
**Delivers:** `kIsWeb`-guarded removal of `workmanager` registration; on-load/on-focus refresh trigger via `ref.invalidate(weatherProvider)`; visible "last updated" timestamp; offline fallback UI.
**Uses:** Cache-then-network pattern from FEATURES.md.
**Implements:** Foreground refresh trigger component from ARCHITECTURE.md.

### Phase 5: Google Calendar Web Integration
**Rationale:** OAuth web behavior (popup vs redirect, FedCM incompatibility) is the lowest-confidence research area and needs hands-on validation against a real deployed domain, not just doc-reading.
**Delivers:** Web OAuth client ID configured in Google Cloud Console for the Firebase Hosting domain; `signIn()` called synchronously inside the tap handler to survive Safari's popup blocker; end-to-end "Add to calendar" verified in a real browser.
**Addresses:** Calendar integration feature (in scope per milestone decision).
**Avoids:** Popup-blocked and FedCM failure modes (Pitfall #3).

### Phase 6: PWA Installability & iOS Polish
**Rationale:** Treated as core, not optional polish — it directly mitigates the ITP storage-eviction data-loss risk identified in Phase 2, since installed PWAs get exempted/larger storage quotas.
**Delivers:** `apple-touch-icon` + `apple-mobile-web-app-*` meta tags; custom "Add to Home Screen" instructional overlay (hidden via `display-mode: standalone` once installed); real-iPhone Safari verification of install flow and storage behavior over time.
**Addresses:** Install UX + storage durability (FEATURES.md, PITFALLS.md).
**Avoids:** iOS ignoring `manifest.json` for icons/splash (related to Pitfall #2).

### Phase 7: Deployment Hardening & Firebase Hosting
**Rationale:** Low-risk, well-documented final step — validates the full pipeline works end-to-end in production before calling the milestone done.
**Delivers:** `firebase.json` config with correct `Content-Type: application/wasm` headers; classic static hosting deploy (`build/web` as public dir, not framework-aware Hosting preview); full production regression checklist across Android + web.
**Uses:** Firebase Hosting from STACK.md.

### Phase Ordering Rationale

- Scaffolding and storage (Phases 1–2) come first because every later phase's success criteria depend on being able to build for web at all and trust that data persists.
- Geolocation and refresh strategy (Phases 3–4) come next since they're self-contained platform-behavior changes with no external dependencies (unlike Calendar, which needs Google Cloud Console setup lead time).
- Calendar (Phase 5) is deliberately not first despite being a feature requirement — it has the lowest research confidence and benefits from the app already being deployable (Phase 1) and durable (Phase 2) before debugging OAuth popup timing.
- PWA installability (Phase 6) comes after Calendar rather than earlier because it depends on the app being otherwise feature-complete before investing in install-conversion UX.
- Deployment hardening (Phase 7) is last by nature — it's a wrap-up/verification phase, not new capability.
- Every phase should carry an explicit "verified on real iPhone Safari" success criterion per PITFALLS.md — none of this is catchable by automated widget tests.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 5 (Google Calendar Web Integration):** `authorizeScopes()`/`authorizationClient()` web behavior for `google_sign_in` 7.x is LOW confidence — no single authoritative source confirms exact popup/redirect behavior in iOS Safari standalone PWA mode.
- **Phase 6 (PWA Installability):** Sources conflict on whether the ITP storage-eviction exemption for installed (Add to Home Screen) PWAs actually holds in current iOS versions vs. only applying to regular Safari tabs — needs a real-device test (leave app untouched 7+ days).

Phases with standard patterns (skip research-phase):
- **Phase 1 (Web Scaffolding):** Well-documented `flutter create --platforms web` + CanvasKit renderer choice, no ambiguity.
- **Phase 2 (Drift Web Persistence):** Officially documented `drift_flutter` API pattern (`DriftWebOptions`), verified via Context7/official docs.
- **Phase 3 (Geolocation):** `geolocator_web` is a mature federated plugin with clear platform support tables.
- **Phase 4 (Foreground Refresh):** Standard PWA cache-then-network pattern, no iOS-specific caveats found.
- **Phase 7 (Deployment):** Firebase Hosting static deploy is a well-trodden path.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Drift web setup verified via official docs (HIGH); Firebase Hosting PWA specifics thinner, cross-verified with community sources (MEDIUM) |
| Features | MEDIUM-HIGH | Install UX mechanics confirmed via WebKit blog + MDN (HIGH); storage-eviction exemption for installed PWAs genuinely conflicting across sources (MEDIUM) |
| Architecture | MEDIUM-HIGH | Drift/workmanager web-support facts HIGH confidence; exact `google_sign_in` 7.x web popup/FedCM runtime behavior LOW confidence, flagged for phase-time validation |
| Pitfalls | MEDIUM-HIGH | Renderer choice and Drift/ITP interaction HIGH (official docs + tracked GitHub issues); OAuth and geolocation iOS quirks MEDIUM (multiple corroborating but non-official sources) |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- Whether the ~7-day Safari storage eviction actually exempts installed (standalone) PWAs in practice on current iOS versions, or only applies to regular tabs — requires a real-device test (leave the deployed PWA untouched 7+ days, check state) during Phase 2/6 planning, not an assumption baked into the roadmap.
- Exact `google_sign_in` 7.x web `authorizeScopes()`/popup behavior inside iOS standalone PWA mode — validate hands-on early in Phase 5 rather than trusting documentation alone.
- Whether `flutter build web --wasm` (Skwasm) is safe on target iOS Safari versions — the CanvasKit decision in Phase 1 sidesteps this, but worth a quick spot-check against the actual Flutter version pinned in this project.
- Whether Firebase Hosting serves `.wasm` with the correct `Content-Type` out of the box or needs an explicit `firebase.json` header rule — verify during Phase 2 (Drift web wiring), not assumed until Phase 7.

## Sources

### Primary (HIGH confidence)
- drift.simonbinder.eu official docs (via Context7 `/websites/drift_simonbinder_eu`) — Drift web backend, `DriftWebOptions`, OPFS/IndexedDB selection
- WebKit official blog — Safari storage eviction policy (LRU/heuristic, not a hard 7-day timer), installed-PWA storage quota exemptions
- pub.dev package pages — `google_sign_in` 7.2.0, `geolocator` 14.0.2, `drift_flutter`, `sqlite3` platform support tables and changelogs
- MDN / web.dev — PWA manifest, `beforeinstallprompt`, `display-mode: standalone` behavior
- Official Flutter web rendering docs — CanvasKit vs Skwasm renderer tradeoffs

### Secondary (MEDIUM confidence)
- Flutter/package GitHub issue trackers — `workmanager`/`home_widget` web-support absence, `google_sign_in` 7.x breaking-change discussions, Skwasm Safari compatibility bugs (flutter/flutter#183265)
- Apple Developer Forums threads — iOS Safari geolocation per-session re-prompt behavior (no single authoritative Apple doc confirms this)
- Google's FedCM migration documentation — Safari's lack of FedCM support and implications for `google_sign_in` web

### Tertiary (LOW confidence)
- Community blog posts on Firebase Hosting + Flutter Web PWA config — cross-verified but thinner than official docs, needs validation at implementation time

---
*Research completed: 2026-07-10*
*Ready for roadmap: yes*
