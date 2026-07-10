# Stack Research

**Domain:** Flutter Web/PWA build of an existing Android app, targeting iOS Safari users, deployed to Firebase Hosting
**Researched:** 2026-07-10
**Confidence:** MEDIUM-HIGH (Context7/official docs for Drift and Flutter web; verified WebSearch + official docs for google_sign_in, geolocator, WebKit storage policy; some Flutter-official PWA doc pages are thin, filled in via community sources)

> **Scope note:** This file documents ONLY the stack additions/changes needed for the v2.0 Flutter Web/PWA milestone. It supersedes the previous (v1.0 Android-only) `STACK.md` for research purposes — v1.0's validated stack (Riverpod, Drift, http, freezed, geolocator, permission_handler, workmanager, flutter_local_notifications, go_router, google_sign_in, fl_chart) is already captured in `CLAUDE.md` and is NOT re-researched here except where web adds a caveat.

## Recommended Stack

### Core Technologies (new for v2.0 web target)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Flutter Web (built-in, no new package) | Flutter SDK 3.x (already in use) | Compiles existing Dart codebase to a web bundle | No new dependency — `flutter create . --platforms web` adds a `web/` folder to the existing project. Reuses 100% of scoring/provider/UI Dart code. |
| Drift web backend (via existing `drift` 2.33.0 + new `sqlite3` + `drift_flutter`) | `sqlite3: ^3.0.0`, `drift_flutter: ^0.3.0` | Local SQL storage in the browser (weather cache, availability grid) using sqlite3.wasm over IndexedDB/OPFS | Drift already used natively for the availability grid queries — the web target uses the *same* Drift schema/queries, just a different `QueryExecutor`. `drift_flutter`'s `driftDatabase()` helper picks the right backend per platform (native vs wasm) from one call site. |
| `google_sign_in` 7.2.0 (already in stack, no version change) | 7.2.0 | Calendar-scoped OAuth sign-in, now also on web | v7's rewrite is built directly on Google Identity Services (GIS) under the hood and lists `web: any` as a supported platform — **no separate web package needed**, unlike the pre-v6 `google_sign_in_web` era. |
| `geolocator` 14.0.2 (already in stack, no version change) | 14.0.2 | GPS/location on web via browser Geolocation API | `geolocator` auto-pulls in `geolocator_web` as a federated platform implementation; wraps `navigator.geolocation` under the hood. Works on iOS Safari since Safari implements the standard Geolocation API. |
| Firebase CLI (`firebase-tools`, not a Dart package) | latest (`npm install -g firebase-tools`) | Deploy `build/web` output to Firebase Hosting | Free tier, zero backend code, matches existing "no backend" constraint. Use classic (non-experimental) Hosting config — see "What NOT to Use" below. |

### Supporting Libraries (new for web)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `sqlite3` | `^3.0.0` (matches whatever `sqlite3.wasm` build you download) | Provides the wasm bindings drift's web backend needs | Add as a direct dependency; the installed `sqlite3.wasm` binary version **must match** this package's version or Drift throws at runtime. |
| `drift_flutter` | `^0.3.0` | Cross-platform `driftDatabase()` helper that already knows how to wire native (`sqlite3_flutter_libs`) vs web (`sqlite3` + wasm/worker) executors from one call | Recommended over hand-rolling a `WasmDatabase.open()` call per platform — less boilerplate, one code path for native+web. Compatible with drift `^2.30.0`, so 2.33.0 is fine. |
| Static asset files: `sqlite3.wasm` + `drift_worker.dart.js` | version-matched to `sqlite3` / `drift` packages respectively | Must be manually downloaded into the `web/` folder (not pulled automatically by pub) | Required for any Drift-on-web setup — the sqlite3 WASM module and the drift worker script that coordinates IndexedDB/OPFS access across tabs. Must be served with `Content-Type: application/wasm` (Firebase Hosting serves `.wasm` correctly by default; verify in `firebase.json` if issues arise). |
| `flutter_web_plugins` (part of Flutter SDK, not pub) | bundled with Flutter SDK | `setUrlStrategy(PathUrlStrategy())` to remove the `#` from `go_router` URLs on web | Needed because Flutter defaults to hash-based URLs on web; without this, deep links / shareable URLs look ugly (`/#/detail/123`) though functionality is unaffected. Call in a web-only entry point or guard with `kIsWeb`. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `firebase-tools` CLI | Build config + deploy to Firebase Hosting | Install globally via npm; `firebase login`, `firebase init hosting`, `firebase deploy`. No Flutter-specific Firebase SDK (e.g. `firebase_core`) is required just for *hosting* a static Flutter web build — those packages are only needed if you later add Firebase Auth/Firestore/Analytics, which is out of scope here. |
| Safari Web Inspector (Develop menu) | Manually verifying IndexedDB/OPFS behavior and the storage-eviction risk | Chrome DevTools won't reproduce Safari's storage-eviction heuristics — this needs on-device/on-Safari testing, not just Chrome. |

## Installation

```bash
# 1. Add web platform to the existing Flutter project (no pubspec change)
flutter create . --platforms web

# 2. Add web-only Drift dependencies
flutter pub add sqlite3
flutter pub add drift_flutter

# 3. Download version-matched static assets into web/ (manual, not via pub)
#    - sqlite3.wasm         -> must match the `sqlite3` package version installed above
#    - drift_worker.dart.js -> must match the `drift` package version (2.33.0)
#    See https://drift.simonbinder.eu/platforms/web/ for the exact release URLs matching your versions.

# 4. Firebase Hosting (one-time project setup)
npm install -g firebase-tools
firebase login
firebase init hosting   # choose "Use an existing project", public dir = build/web, configure as single-page app = Yes

# 5. Build + deploy
flutter build web --release
firebase deploy --only hosting
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|--------------------------|
| `drift_flutter` helper for web wiring | Hand-rolled `WasmDatabase.open()` + custom `DatabaseConnection.delayed` | Only if you need fine-grained control over `localSetup`/custom worker naming that `drift_flutter`'s API doesn't expose — not needed for RideWindow's simple single-DB use case. |
| Classic Firebase Hosting (`firebase init hosting`, static `build/web` as public dir) | Firebase "framework-aware Hosting" (`firebase experiments:enable webframeworks`) | Only relevant for SSR frameworks (Next.js/Angular Universal); it's explicitly an "early public preview... not subject to any SLA." RideWindow is a pure static SPA — classic Hosting is simpler and stable. |
| `google_sign_in` 7.2.0 native web support | `google_sign_in_web` as a separate pub dependency | Not applicable anymore — pre-v6 architecture required a separate federated web plugin; v7's rewrite folds web support into the main package via GIS. Do not add `google_sign_in_web` manually; it will conflict/be redundant. |
| `geolocator` 14.0.2 native web support via `geolocator_web` | A hand-rolled `dart:js_interop`/`package:web` wrapper around `navigator.geolocation` | Only if you need browser Permissions-API nuances `geolocator` doesn't expose (e.g., custom permission-prompt UX) — unlikely needed for RideWindow's simple "ask once, fall back to manual city picker" flow. |
| `firebase-tools` CLI deploy | GitHub Pages / Vercel / Netlify static hosting | Firebase already named in CLAUDE.md constraints and free tier is sufficient; other static hosts work equally well technically but add a second account/tool for no benefit here. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|--------------|
| `workmanager` on web | Explicitly has no web platform support (federated plugin only ships Android/iOS implementations) — confirmed by existing project decision already in PROJECT.md | On-foreground/on-page-load refresh: trigger the weather fetch provider when the app resumes/loads, same `AsyncNotifier` pattern already used, just re-triggered manually instead of via background task |
| `flutter_local_notifications` for iOS Safari web push | Out of scope per milestone context; also iOS Safari only supports Web Push for an installed (Add to Home Screen) PWA on 16.4+, and is materially less reliable than native — not a drop-in replacement for the existing native notification flows | Nothing — deferred entirely for v2.0 per PROJECT.md decision |
| `sqlite3_flutter_libs` on web | It's the **native**-platform sqlite3 binary loader (Android/iOS/macOS/Linux/Windows); has no web implementation | `sqlite3` (pure Dart/wasm package) + manually-hosted `sqlite3.wasm` for web, as described above |
| Relying on IndexedDB persistence without `navigator.storage.persist()` on iOS Safari | WebKit's storage policy evicts script-writable storage (IndexedDB/OPFS) under storage pressure or after a period with no user interaction, using a least-recently-used heuristic — confirmed via WebKit's own "Updates to Storage Policy" post. Persistent-storage grants are heuristic-based and favor installed Home Screen apps | Call `navigator.storage.persist()` (via `dart:js_interop`/`package:web`) on first load, encourage "Add to Home Screen" install (Home Screen web apps get materially higher quota: up to 60%/80% vs 15%/20% for regular tabs), and design the app to tolerate a cleared local DB (re-fetch weather, re-derive defaults) rather than treating local storage as durable |
| Assuming `extension_google_sign_in_as_googleapis_auth` needs replacing for v7/web | Unfounded concern — verified current release (3.0.0) already depends on `google_sign_in: ^7.0.0` and lists `web` as a supported platform | Keep using it as-is; just confirm the calling code follows v7's split authenticate/authorize API (see Pitfalls below) |
| Firebase "framework-aware Hosting" preview for this project | It's targeted at SSR frameworks and is explicitly unstable/preview; RideWindow has no server-rendering need | Classic static Hosting config (`public: build/web`, SPA rewrite to `index.html`) |

## Stack Patterns by Variant

**If targeting installed-PWA users specifically (Add to Home Screen on iOS):**
- Use a full `manifest.json` (name, short_name, icons incl. sizes suited to `apple-touch-icon`, `display: standalone`, `theme_color`, `background_color`) plus `<link rel="apple-touch-icon">` and `apple-mobile-web-app-*` meta tags in `web/index.html` — iOS Safari does not read all of `manifest.json` the way Chrome/Android does and needs the legacy Apple meta tags for a proper home-screen icon/splash experience.
- Because installed PWAs get a much larger storage quota/eviction exemption on iOS, actively prompt "Add to Home Screen" — RideWindow can't trigger the native `beforeinstallprompt` on iOS since it doesn't fire on Safari; this must be a manual instructional UI (e.g. "tap Share -> Add to Home Screen").

**If targeting browser-tab (non-installed) users:**
- Treat local storage (Drift/IndexedDB) as a **cache, not durable source of truth** — expect eviction after inactivity and design the first-load path to gracefully rebuild state (re-run onboarding defaults, refetch weather) rather than erroring.
- Consider `--pwa-strategy none` instead of the default `offline-first` if you don't want Flutter's built-in service worker aggressively caching every asset for offline use in a context where users may not "install" the app — `none` avoids surprising stale-asset issues for a browser-tab-only audience, at the cost of no offline support. `offline-first` is the better default if PWA installation is actively encouraged (see above).

**If build size / load time matters (2s cold-start budget in CLAUDE.md):**
- The default web build uses the `canvaskit` renderer; evaluate `flutter build web --wasm` (Skwasm renderer) for potentially faster startup on modern browsers, but Safari WASM/Skwasm support should be spot-checked on-device since renderer support and performance varies by browser/OS version — treat as a phase-level verification item, not a settled decision here.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `drift@2.33.0` | `drift_flutter@^0.3.0` (requires drift `^2.30.0`) | 2.33.0 satisfies the `^2.30.0` constraint — no drift version bump needed. |
| `drift_flutter@^0.3.0` | `sqlite3@^3.0.0` (web), `sqlite3_flutter_libs@^0.6.0+eol` (native, already in use) | The `+eol` suffix on `sqlite3_flutter_libs` in drift_flutter's own dependency listing is worth flagging — check pub.dev for a newer non-EOL release before locking versions, though the existing native app likely already pins a working version independently. |
| `sqlite3.wasm` (static asset) | Must match installed `sqlite3` package version exactly | Drift's own docs state: "If you use a sqlite3.wasm from version x, the version of package:sqlite3 must be at least that version." Mismatches cause runtime failures, not compile-time ones — verify manually after every `sqlite3` package bump. |
| `drift_worker.dart.js` (static asset) | Must match installed `drift` package version | Same version-drift risk as sqlite3.wasm — re-download after any `drift` package upgrade. |
| `google_sign_in@7.2.0` | `extension_google_sign_in_as_googleapis_auth@3.0.0` | Extension already targets `google_sign_in ^7.0.0` and lists web support — no change needed for the web target. |
| `geolocator@14.0.2` | `geolocator_web` (auto-resolved, federated plugin, no explicit pubspec entry needed) | Web requires a secure context (HTTPS) — Firebase Hosting serves HTTPS by default, so this is satisfied automatically. |
| `go_router@17.2.3` | `flutter_web_plugins` (Flutter SDK bundled) | No version pinning needed; `flutter_web_plugins` ships with the Flutter SDK matching your Flutter version. |
| `http@1.6.0` | Open-Meteo API (CORS-enabled) | Open-Meteo confirmed to send CORS headers allowing direct browser `fetch`/XHR — no proxy needed for the existing weather-fetch code path to work unmodified on web. |
| `fl_chart`, `freezed`, `flutter_riverpod` | Flutter Web (all platforms) | All three are pure-Dart/rendering libraries with no platform channels — no known web-compatibility caveats found; existing scoring/provider/chart code should compile and run on web unmodified. |

## Sources

- `/websites/drift_simonbinder_eu` (Context7) — Drift web platform setup: `DriftWebOptions`, `WasmDatabase.open`, required `web/` directory files (`sqlite3.wasm`, `drift_worker.dart.js`), worker compilation via `dart2js`
- [Drift: Web platform docs](https://drift.simonbinder.eu/platforms/web/) — OPFS vs IndexedDB tiered storage strategy, Safari 16 worker-caching bug, COOP/COEP header requirements, version-matching requirement between `sqlite3` package and `sqlite3.wasm`
- [drift_flutter on pub.dev](https://pub.dev/packages/drift_flutter) — current version 0.3.0, dependency versions (`sqlite3_flutter_libs ^0.6.0+eol`, `sqlite3 ^3.0.0`), drift `^2.30.0` compatibility — MEDIUM confidence (WebFetch-summarized page content)
- [WebKit blog: Updates to Storage Policy](https://webkit.org/blog/14403/updates-to-storage-policy/) — HIGH confidence, official WebKit source: eviction is LRU-based on last interaction/storage operation, not a strict "7 days" hard rule; Home Screen web apps get 60%/80% quota vs 15%/20% for regular tabs; `navigator.storage.persist()` mitigation and its heuristic (favors installed PWAs), `QuotaExceededError` handling recommended — **this refines the "7-day eviction" framing already in PROJECT.md**: it's engagement-based eviction under storage pressure rather than a hard 7-day timer, but the practical risk (data loss for inactive/non-installed users) is confirmed and real
- [pub.dev: google_sign_in](https://pub.dev/packages/google_sign_in) — MEDIUM confidence (WebFetch summary) — confirms `web: any` platform support in 7.x, built on GIS, `authorizeScopes()`/`authorizationClient` API for Calendar scope, access token expires after 3600s on web with no auto-refresh
- [pub.dev: extension_google_sign_in_as_googleapis_auth](https://pub.dev/packages/extension_google_sign_in_as_googleapis_auth) — MEDIUM confidence — v3.0.0 depends on `google_sign_in ^7.0.0`, lists web as supported platform
- [pub.dev: geolocator](https://pub.dev/packages/geolocator) — MEDIUM-HIGH confidence — confirms `geolocator_web` auto-included since 6.2.0+, wraps browser Geolocation API, HTTPS-only, several methods throw `UnsupportedError` on web (`getLastKnownPosition`, `openAppSettings`, `openLocationSettings`, `getServiceStatusStream`)
- [Flutter docs: Building a web app](https://docs.flutter.dev/platform-integration/web/building) — HIGH confidence official source, though thin on PWA specifics (confirmed via WebFetch that this page does not cover manifest.json/service worker/pwa-strategy in detail)
- [Flutter docs: Build and release a web app](https://docs.flutter.dev/deployment/web) — HIGH confidence — build modes (debug/profile/release), renderers (`canvaskit`/`skwasm`), `flutter build web --wasm`
- WebSearch (multiple, cross-verified) — `--pwa-strategy offline-first|none` flag behavior, `flutter_service_worker.js` auto-generation, `manifest.json` role — MEDIUM confidence, not found verbatim in the official Flutter docs pages fetched, but consistent across multiple community sources and matches known Flutter CLI behavior
- [Firebase Hosting: Integrate Flutter Web](https://firebase.google.com/docs/hosting/frameworks/flutter) — MEDIUM confidence (WebFetch summary) — flags the webframeworks integration as "early public preview," recommends Firebase CLI >=12.1.0; classic static hosting (public dir = `build/web`) recommended instead for this project's pure-SPA needs
- WebSearch — `go_router` + `PathUrlStrategy`/`flutter_web_plugins` for hash-free URLs on web — MEDIUM confidence, consistent across multiple sources, matches known Flutter web routing behavior
- WebSearch — Open-Meteo CORS support for direct browser access — MEDIUM confidence (no official Open-Meteo docs page fetched directly, but consistent across multiple sources and matches the API's stated "no auth, public" design)

---
*Stack research for: Flutter Web/PWA build (v2.0) targeting iOS Safari users, deployed via Firebase Hosting*
*Researched: 2026-07-10*
