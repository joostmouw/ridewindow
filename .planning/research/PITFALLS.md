# Pitfalls Research

**Domain:** Adding a Flutter Web/PWA build to an existing native Android Flutter app, targeting iOS Safari via "Add to Home Screen" (RideWindow v2.0 milestone)
**Researched:** 2026-07-10
**Confidence:** MEDIUM-HIGH (Flutter Web renderer/wasm mechanics and Drift web backend are well-documented via official sources; some iOS Safari PWA behaviors and google_sign_in web edge cases are corroborated by multiple community reports but not officially guaranteed to stay stable)

> Note: this file supersedes the v1.0 (native Android) pitfalls research for the purposes of the current v2.0 milestone roadmap. The v1.0 findings (setState-after-dispose, hot-reload gotchas, Play Store submission pitfalls, etc.) remain valid for the Android codebase but are not repeated here — this file is scoped specifically to the risks introduced by adding a Web/PWA target.

## Critical Pitfalls

### Pitfall 1: Choosing `--wasm` (skwasm) as the web build target and shipping a broken experience on Safari

**What goes wrong:**
Flutter's newer WebAssembly build mode (`flutter build web --wasm`) uses the skwasm renderer, which requires WasmGC. Safari added WasmGC support in 18.2 (Dec 2024), but there are still open compatibility bugs between Flutter's wasm renderer and Safari's WasmGC implementation (tracked upstream, e.g. flutter/flutter#154344). Flutter's tooling is supposed to auto-fallback to CanvasKit for browsers without working skwasm support, but this fallback logic has had bugs of its own (e.g. flutter/flutter#183265 — "FlutterLoader could not find a build compatible with configuration and environment"). Since RideWindow's entire justification for this milestone is reaching iOS Safari users, shipping a renderer path that is fragile specifically on Safari is the single highest-risk technical decision in this milestone.

**Why it happens:**
`--wasm` is marketed as the modern, faster path in Flutter docs and blog posts, and a solo dev doing a "which renderer" search will find recent enthusiastic wasm content without realizing Safari is the exact browser with unresolved compatibility bugs.

**How to avoid:**
Build with plain `flutter build web --release` (default CanvasKit-over-JS compile) for this milestone, not `--wasm`. CanvasKit is the stable, proven default and is not currently blocked by Safari-specific bugs. Explicitly test the production build in real iOS Safari (not just Chrome DevTools device emulation, which uses desktop Safari/Chrome rendering, not WebKit) before considering `--wasm` a future optimization. If `--wasm` is revisited later, gate it behind manual verification on a real iPhone running the current iOS version, not just "the build succeeded."

**Warning signs:**
Blank white screen or a `FlutterLoader` console error on iPhone Safari specifically, while desktop Chrome works fine; app works in iOS Simulator's Safari but fails on a real device (simulator and hardware WebKit can diverge on wasm feature detection).

**Phase to address:**
Web scaffolding / initial build setup phase — decide and lock the renderer/build-mode choice before any feature work, and add "verified on a real iPhone in Safari" as an explicit success criterion.

---

### Pitfall 2: Drift's web backend silently loses data due to Safari's ITP 7-day script-writable storage cap

**What goes wrong:**
Drift on web falls back through a hierarchy of storage backends (OPFS shared worker → OPFS with COOP/COEP → shared IndexedDB → "unsafe" IndexedDB → in-memory). Safari does not support the shared-worker OPFS path Chrome/Firefox get, so it lands on an IndexedDB-based backend. Safari's Intelligent Tracking Prevention deletes all script-writable storage (cookies, localStorage, IndexedDB) for a site the user hasn't interacted with in a first-party context for 7 days. For RideWindow specifically — a "check once or twice a week before planning a ride" app — a lapsed weekend user is a completely realistic scenario where availability calendar, tolerance settings, and cached forecasts vanish silently, with no error surfaced to the user (they just see onboarding again).

**Why it happens:**
This is invisible in local dev/testing because the developer interacts with the site constantly. It only manifests in production after real inactivity gaps, so it's easy to ship without ever seeing it.

**How to avoid:**
1. Confirm during a research spike whether the PWA is *installed* (Add to Home Screen) — WebKit's ITP algorithm exempts the first-party domain of home-screen web apps from the 7-day cap. This is the strongest mitigation and is exactly why this milestone should prioritize driving users to "Add to Home Screen" rather than treating it as optional polish.
2. For users who never install, treat local storage as ephemeral: don't make onboarding/setup a one-time irrecoverable investment. Design onboarding to be fast to redo (2-3 taps, not a long wizard) so silent resets are a minor annoyance, not data loss.
3. Do not rely on `Content-Type: application/wasm` alone — also verify Firebase Hosting serves the COOP/COEP headers correctly if attempting the faster OPFS path, but recognize Safari won't get OPFS regardless.

**Warning signs:**
Beta testers reporting "my settings reset" after a week away from the app; no crash, no error — just re-onboarding.

**Phase to address:**
Data layer / Drift-web-port phase should document and test this explicitly (verify storage backend selection via logging). PWA installability phase must treat "encourage install" as a data-durability feature, not just a UX nicety — cross-reference with Pitfall 7.

---

### Pitfall 3: WAL-mode / native SQLite schema doesn't carry over to the web IndexedDB backend

**What goes wrong:**
Drift's own web docs explicitly warn that WAL (write-ahead logging) is not supported on the web and WAL databases can't be imported. If the Android app's Drift database uses WAL mode (a common default with sqlite3_flutter_libs setups) and there's ever a temptation to "import" or share a database export between platforms, this path is a dead end without special handling. Separately, Drift on web is a fully separate persistence implementation (IndexedDB, async) versus native (synchronous SQLite file) — migrations that reference native-only pragmas or assume synchronous file access will not port cleanly.

**Why it happens:**
Because "no backend / local-only storage" was already a validated v1.0 decision, it's tempting to assume the same Drift schema/migrations "just work" on web since it's the same package. In reality the storage engine underneath is fundamentally different (native SQLite file vs. wasm SQLite over async IndexedDB).

**How to avoid:**
Treat the web build's Drift database as a fresh database, not a migrated one — there is no cross-device sync in scope anyway (per PROJECT.md), so there's no requirement to import a user's Android database into their web session. Explicitly verify all existing Drift migrations run cleanly against the wasm backend in a web-specific test pass (don't assume "migrations passed on Android" implies "migrations pass on web").

**Warning signs:**
Migration exceptions only reproducible in `flutter run -d chrome`, not on Android; any migration code path that checks `Platform.isAndroid` or uses native pragmas.

**Phase to address:**
Data layer / Drift-web-port phase — add "run full migration suite against web wasm backend" as an explicit test task.

---

### Pitfall 4: `google_sign_in` web popup blocked on first interaction in Safari, and FedCM incompatibility

**What goes wrong:**
Two distinct, well-documented failure modes:
1. **Popup blocking:** Multiple long-standing Flutter issues (e.g. flutter/flutter#81447, #54768) show `PlatformException(popup_blocked_by_browser)` specifically in Safari on the *first* sign-in attempt after a fresh page load, succeeding only on retry. Safari's popup blocker is stricter about what counts as "triggered directly by a user gesture" than Chrome's.
2. **FedCM migration:** Google is migrating Google Identity Services' underlying mechanism to FedCM (Federated Credential Management) to work around third-party cookie deprecation. Safari does not support FedCM. This is a moving target — a flow that later depends on FedCM being available could degrade on Safari without warning.

**Why it happens:**
Development and manual testing happen mostly in Chrome, where popups and FedCM both "just work," masking Safari-specific breakage until real iOS users try it.

**How to avoid:**
- Wire the sign-in button so `signIn()` is called directly and synchronously inside the tap handler (no `await` or async gap before opening the popup) — this preserves the "user gesture" context Safari's popup blocker checks for.
- Add explicit UX for the popup-blocked case: catch the `PlatformException` and show a "please allow popups for this site" message with a retry button, rather than a silent failure.
- Do not build any Calendar-integration UX that assumes silent/frictionless re-authentication (`signInSilently()`) works reliably cross-browser — always have a visible manual "Sign in" fallback button.
- Test the full OAuth round-trip in real Safari (mobile and desktop) before considering Calendar integration done — this is arguably the single feature in this milestone with the highest "works in Chrome, breaks in Safari" risk.

**Warning signs:**
"Add to calendar" sign-in works in local Chrome testing but a beta tester on iPhone reports nothing happens when they tap "Sign in with Google," or the popup flashes and closes immediately.

**Phase to address:**
Google Calendar web integration phase — success criteria should explicitly require manual verification in real Safari (iOS + macOS), not just Chrome.

---

### Pitfall 5: OAuth redirect URI / authorized origins misconfigured for the Firebase Hosting domain

**What goes wrong:**
The existing Android app's OAuth client is configured with an Android package name + SHA-1 fingerprint. The web build needs a *separate* OAuth 2.0 Web Client ID in Google Cloud Console, with "Authorized JavaScript origins" set to the exact Firebase Hosting domain(s) (both the default `*.web.app`/`*.firebaseapp.com` domain and any custom domain, plus `http://localhost:PORT` for local dev) and, if using redirect-based flows via Firebase Auth, "Authorized redirect URIs" including the `/__/auth/handler` path. Missing any one of these produces a cryptic `redirect_uri_mismatch` or `origin_mismatch` error that only appears in production (localhost testing works because it was configured, prod domain wasn't).

**Why it happens:**
It's easy to reuse the existing Android OAuth client ID out of habit, or to test only against `localhost` during development and forget to add the real Firebase Hosting URL before the first production deploy.

**How to avoid:**
Create a dedicated Web application OAuth client ID in Google Cloud Console specifically for this milestone. Add every domain the app will actually be served from (Firebase default domain, custom domain if any, and localhost dev port) to Authorized JavaScript origins before attempting sign-in against deployed builds. Treat "OAuth client configured for the production Firebase Hosting URL" as a deploy-blocking checklist item, not an afterthought discovered via a support ticket.

**Warning signs:**
Sign-in works when running `flutter run -d chrome` locally but fails immediately after `firebase deploy` with a console error mentioning redirect_uri or origin mismatch.

**Phase to address:**
Google Calendar web integration phase, verified again during deployment/Firebase Hosting phase (config must be re-checked once the real production URL is known, not just the staging/preview URL).

---

### Pitfall 6: Geolocation permission re-prompts every session on iOS Safari, breaking the "instant forecast" UX

**What goes wrong:**
On iOS Safari, refreshing the page or returning in a new session commonly re-triggers the location permission prompt even after the user previously granted it — unlike native Android where the OS remembers the grant indefinitely. Since RideWindow's core value promise is "show forecast + slots within 2s of cold start," a permission re-prompt on every visit directly undermines that promise for web/iOS users and can look like a bug ("didn't I already allow this?").

**Why it happens:**
iOS Safari treats geolocation permission grants as more session-scoped/ephemeral than native OS permission systems, especially for browser tabs (installed home-screen PWAs behave somewhat better but are not guaranteed to be fully persistent either).

**How to avoid:**
Design the web onboarding/home flow to treat "ask for location" as a per-session possibility, not a one-time event: show a fast, low-friction prompt UI ("Getting your local forecast...") rather than assuming silent success, and always keep the manual city-picker override (already built for v1.0) as the primary fallback so a denied/re-prompted permission never blocks showing *some* forecast. Cache the last known location in local storage so a re-prompt-and-deny doesn't blank the screen — fall back to last-known coordinates immediately while re-requesting permission in the background.
Also confirm HTTPS is enforced everywhere (Firebase Hosting does this by default) — the Geolocation API refuses to run at all over plain HTTP, which would otherwise be a total silent failure.

**Warning signs:**
Beta tester feedback that "it asks for location every time" or that the app appears to hang/blank on repeat visits.

**Phase to address:**
Location/geolocation web-port phase — success criteria should include "app shows a forecast within 2s using last-known or fallback location even if the permission prompt reappears," not just "permission prompt implemented."

---

### Pitfall 7: Building PWA installability around `beforeinstallprompt`, which iOS Safari does not support

**What goes wrong:**
It's a common Flutter/PWA tutorial pattern to listen for the `beforeinstallprompt` browser event and show a custom "Install App" button that triggers the native install prompt programmatically. iOS Safari has never supported this event (Chrome/Edge/Android do). If the web/PWA install UX is built only around that event, iOS users — the entire target audience for this milestone — will see no install prompt and no button at all, defeating the purpose of the milestone.

**Why it happens:**
Most PWA installability guides and boilerplate are written Chrome-first, since `beforeinstallprompt` is the "proper" API-driven way to do it, and it's easy to copy that pattern without checking iOS support.

**How to avoid:**
Design install guidance as an explicit, always-visible in-app instructional UI for iOS Safari users specifically: detect iOS Safari (via user agent sniffing or feature-detecting `navigator.standalone`), and show a persistent "Add RideWindow to your Home Screen: tap Share → Add to Home Screen" banner/tooltip with a screenshot, rather than a button that silently does nothing. Given Pitfall 2's storage-durability argument, this banner should be treated as a core UX element, not a nice-to-have — the app should actively encourage installation, potentially re-surfacing the tip periodically (e.g. after the 2nd or 3rd session) rather than showing it once and never again.

**Warning signs:**
No visible install call-to-action for iOS testers; testers not realizing the app can be "installed" at all and treating it as a bookmark.

**Phase to address:**
PWA polish / iOS installability phase — explicit success criteria: "iOS Safari users see manual Add-to-Home-Screen guidance" (verified on real device, not emulator), independent of any `beforeinstallprompt` logic (which can still be built for Chrome/Android users as a bonus, but must not be the only path).

---

### Pitfall 8: manifest.json alone doesn't control the iOS home-screen icon or splash screen — Safari mostly ignores it

**What goes wrong:**
Flutter Web's generated `web/manifest.json` covers Chrome/Android install metadata (name, icons, theme_color, display: standalone). iOS Safari largely ignores `manifest.json` for home-screen icon/splash purposes and instead requires specific `<link rel="apple-touch-icon">` tags and `apple-mobile-web-app-*` meta tags directly in `index.html`'s `<head>`. Without these, the home-screen icon defaults to an ugly auto-generated screenshot thumbnail of the page, and there is no splash screen shown during PWA launch (users see a flash of white/blank instead).

**Why it happens:**
Flutter's default web template generates a manifest.json and favicon setup aimed at general web/Android PWA support; it does not automatically add the Apple-specific meta tags, since Flutter Web's template predates/underserves iOS-specific PWA conventions.

**How to avoid:**
Manually add to `web/index.html`: `<link rel="apple-touch-icon" href="icons/Icon-192.png">` (180x180 PNG is the safe universal size), `<meta name="apple-mobile-web-app-capable" content="yes">`, `<meta name="apple-mobile-web-app-status-bar-style" content="...">`, and `<meta name="apple-mobile-web-app-title" content="RideWindow">`. Generate a dedicated 180x180 (and ideally multiple sizes for different device pixel ratios) icon rather than relying on whatever the manifest.json icon happens to be. Verify the actual installed home-screen icon on a real iPhone, not just that manifest.json validates.

**Warning signs:**
Installed home-screen icon looks like a screenshot/blank square instead of the app icon; app title bar shows the URL/generic name instead of "RideWindow."

**Phase to address:**
PWA polish / iOS installability phase.

---

### Pitfall 9: Web-only code paths silently break the existing Android build (or vice versa) due to `kIsWeb` misuse instead of conditional imports

**What goes wrong:**
`kIsWeb` is a *runtime* boolean, not a compile-time constant. Using `if (kIsWeb) { ... } else { ... }` to branch between, say, a `dart:html`-based implementation and a `dart:io`-based one does not prevent both branches from being *compiled* — the unused branch still needs to compile for every target platform, so importing `dart:io` anywhere reachable by the web compiler (even inside an `if (!kIsWeb)` branch) breaks the web build, and importing `dart:html`/`package:web` reachable by the mobile compiler breaks the Android build. Given RideWindow already has Android-only native code paths (`workmanager`, `flutter_local_notifications` with native-only scheduling params, `home_widget` for the Android home-screen widget, `geolocator`/`permission_handler` native plugin calls), the highest-risk moment in this milestone is threading new web-specific code into files shared with those existing native features without properly isolating them.

**Why it happens:**
Solo devs reach for `kIsWeb` first because it "looks like" the obvious platform check, and it does work fine for pure Dart runtime branching (e.g. changing which widget to render) — the trap is specifically using it to gate imports or plugin calls that don't exist on the other platform.

**How to avoid:**
For any feature not shared cleanly across platforms (background refresh scheduling, notifications, home_widget bridge, any native-only plugin call), use the conditional-import pattern: a shared interface file with `export 'thing_stub.dart' if (dart.library.io) 'thing_native.dart' if (dart.library.js_interop) 'thing_web.dart';` (or the equivalent `dart.library.html`/`dart.library.js`), keeping all platform-specific imports inside the platform-specific implementation files only. Never let `workmanager`, `flutter_local_notifications`'s exact-alarm scheduling, or `home_widget` calls live in a file that's part of the web compilation unit at all — since those features are explicitly out of scope for web (per PROJECT.md), the safest approach is to keep the web build from ever importing those files, rather than trying to branch around them at runtime.
Run `flutter build web` and `flutter build apk` (or `flutter analyze` for both) as a required check after any change touching shared files — don't just run one platform's build during web feature development and assume Android still compiles.

**Warning signs:**
Web build fails with `Unsupported operation` or import-resolution errors mentioning `dart:io`/`dart:html`; conversely, an Android release build breaks after web work with errors about missing platform channels or an unexpected white screen from an accidentally-shared web-only widget.

**Phase to address:**
Web scaffolding phase should establish the conditional-import pattern and CI/build-check discipline up front, before feature work begins, since retrofitting this after several features are built into shared files is much more expensive. Every subsequent web phase should re-verify `flutter build apk`/`flutter analyze` still succeeds as an explicit regression gate.

---

### Pitfall 10: Widget tests pass while the actual browser rendering / DOM behavior is broken

**What goes wrong:**
Flutter Web doesn't render "native" widgets — CanvasKit renders to a `<canvas>` element via WebGL/Wasm, and the widget/render-object tree behaves identically in unit and widget tests regardless of target platform, because Flutter's test harness never actually runs a real browser engine. This means widget tests (and even most `integration_test` runs via `flutter test`) can pass 100% while genuinely browser-specific problems — popup blocking, geolocation permission quirks, IndexedDB storage backend selection, manifest/icon rendering, actual Safari layout/scroll behavior — are completely invisible to the test suite. For this milestone, nearly every pitfall listed above (1, 2, 4, 6, 7, 8) is exactly the class of bug that automated Flutter tests will not catch.

**Why it happens:**
"Tests are green" creates false confidence that the web build is production-ready, because the existing Android-focused test suite was never designed to catch browser-engine-specific failure modes.

**How to avoid:**
Treat manual verification on real hardware (a real iPhone in Safari, ideally both a recent iOS version and one a year or two older, plus desktop Safari on macOS if available) as a mandatory, explicit step for every phase in this milestone — not an optional nice-to-have at the end. Where useful, `flutter drive`/`integration_test` can run against Safari via WebDriver for basic smoke coverage (page loads, main navigation works), but do not rely on it to catch the Safari-specific issues above — those require hands-on testing. Keep a running manual test checklist (permission prompts, sign-in flow, Add to Home Screen, offline/reload behavior) that gets executed before each deploy, since these are exactly the behaviors CI can't verify.

**Warning signs:**
"All tests pass" + "CI is green" + a beta tester on an iPhone reports something completely broken that never showed up locally.

**Phase to address:**
Applies across all phases, but should be made an explicit, named success-criterion category (e.g. "Manual Safari/iOS verification") in every phase touching web-specific behavior, not just a general QA phase at the end.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Reuse the Android OAuth client ID for web instead of creating a dedicated Web client ID | Saves 10 minutes of Cloud Console setup | Origin/redirect mismatches in production; harder to reason about which domains are trusted | Never — the Web client ID is required by Google's own client-type separation |
| Test only in desktop Chrome during development, defer Safari testing to "later" | Faster iteration loop, no need for a physical iPhone during early dev | Popup blocking, ITP storage eviction, geolocation re-prompting, and manifest/icon issues are all invisible until the first real Safari test — discovered late, expensive to fix under deploy pressure | Acceptable only for the first 1-2 days of scaffolding; must switch to Safari-inclusive testing before any auth/geolocation/PWA-install work is considered "done" |
| Skip building the "Add to Home Screen" guidance banner and ship only a bookmark-able web page | Less UI work | Undermines the entire premise of this milestone — non-installed Safari tabs are subject to the 7-day ITP storage wipe, so users lose their settings repeatedly and never realize install is possible | Never acceptable as the final state for this milestone; could be deferred by a phase or two but must ship before calling v2.0 done |
| Use `kIsWeb` runtime branching instead of proper conditional imports for platform-specific plugin calls | Faster to write, feels more "Dart-native" | Breaks compilation on one platform the moment the branch references a platform-unavailable import; expensive to untangle once spread across many files | Acceptable only for pure-Dart UI/behavior branching (e.g., "show this widget vs that widget") — never for gating imports of platform-specific packages |
| Ship without server cache-control tuning on Firebase Hosting (defaults only) | No extra config work | Users can get stuck on a stale cached build indefinitely after a deploy (flutter_service_worker.js aggressive caching), especially painful for an installed PWA that isn't manually refreshed often | Acceptable only for the very first internal test deploy; must be fixed (no-cache on index.html/service worker, immutable+hashed filenames for JS/CSS) before public beta |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Google Sign-In (web) | Calling `signIn()` after an `await` or inside an async callback, breaking the "direct user gesture" chain Safari's popup blocker requires | Call `signIn()` synchronously in the button's tap handler; do any async setup before the tap, not between tap and popup |
| Google Calendar OAuth | Configuring Authorized JavaScript Origins only for `localhost`, forgetting the production Firebase Hosting domain | Add every real domain (default `*.web.app`/`*.firebaseapp.com`, custom domain if any, and localhost dev ports) to the Web OAuth client before first production deploy |
| Firebase Hosting deploy | Relying on default cache headers, letting `flutter_service_worker.js` and `index.html` get cached indefinitely by browsers/CDN | Configure `firebase.json` with `Cache-Control: no-cache` for `index.html` and the service worker, and hashed/immutable filenames for JS/CSS bundles |
| Drift web wasm asset | Not verifying the hosting server sends `Content-Type: application/wasm` for `sqlite3.wasm` | Explicitly test the deployed (not just locally-served) build's network tab to confirm the wasm file's content-type; Firebase Hosting generally infers this correctly by extension but must be verified, not assumed |
| Geolocation (browser API) | Assuming a granted permission persists across sessions like native Android | Cache last-known location locally and always keep the manual city-picker as first-class fallback, not an edge-case-only feature |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Shipping full default Material icon font instead of a subset | Larger-than-necessary initial JS/font payload, slower first paint on mobile Safari's cellular connections | Use `--tree-shake-icons` where it works reliably, or replace with SVG/custom subset fonts for the small icon set RideWindow actually uses | Noticeable on 3G/4G cold loads; matters most for the "2s cold start" performance constraint carried over from the native app |
| Not using deferred/lazy loading for rarely used screens (e.g. Profile/Availability calendar editor) | Larger main bundle than necessary, slower first interactive paint on the Home screen (the screen that matters for the "2s" promise) | Use Dart's `deferred as` imports for less-frequently-hit routes | Becomes noticeable as more screens/dependencies (fl_chart, googleapis) are pulled into the web build |
| Relying on the "unsafe IndexedDB" Drift backend without shared-worker synchronization | Data corruption/loss risk if the user has the PWA open in two tabs simultaneously | Confirm which backend Drift actually selects at runtime (log it) and treat multi-tab usage as a known limitation to document, not silently ignore | Multi-tab usage is uncommon for this app's use case but should be a known, documented risk rather than a surprise bug report |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing the Google OAuth client secret or any sensitive config in web-shipped JS | Client-side web bundles are fully inspectable; any secret embedded in `index.html`/`main.dart.js` is public | Use only the public Web Client ID (which is meant to be public) via `google_sign_in`'s web implementation — never embed a client *secret*, which OAuth's implicit/PKCE web flows do not require anyway |
| Leaving broad CORS/COOP/COEP headers misconfigured while chasing OPFS performance | Overly permissive `Cross-Origin-Embedder-Policy: unsafe-none` or missing headers can silently disable cross-origin isolation needed for OPFS, or (if misconfigured the other way) break loading of third-party resources like Google Sign-In's popup/iframe | Only add COOP/COEP headers if actually pursuing the OPFS storage path (Chrome/Firefox benefit only, since Safari doesn't get OPFS anyway); if skipped, don't add unnecessary restrictive headers that break the Google auth popup |
| Treating the web app's local storage as equivalently private/durable as native app-sandboxed storage in privacy-facing copy | Privacy policy or in-app copy could overpromise data persistence/isolation guarantees the web platform doesn't actually provide (ITP eviction, no OS-level sandboxing guarantees) | Review and, if needed, update the privacy policy language to reflect browser storage's different persistence/isolation model versus the native Android app |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|------------------|
| No visible guidance for "Add to Home Screen" on iOS | Users treat the site as a disposable bookmark, never install, and repeatedly lose settings to ITP eviction (Pitfall 2) | Persistent, dismissible-but-re-surfacing install banner with a screenshot-based walkthrough specific to iOS Safari's Share-sheet flow |
| Location permission re-prompting every visit with no fallback | App appears broken/stuck on a permission dialog or shows nothing while waiting | Show cached last-known-location forecast immediately, request permission in the background, and always surface the manual city picker prominently (not buried in settings) |
| Sign-in button that silently does nothing when a popup is blocked | User thinks Calendar integration is broken or the app doesn't work at all | Catch the specific blocked-popup exception and show an actionable "please allow popups for this site" message with a retry action |
| Generic/blank home-screen icon and no splash screen after install | Feels unpolished, undermines trust that the "app" is a real, cared-for product versus a bookmark | Explicit Apple touch icon + apple-mobile-web-app meta tags (Pitfall 8), tested on a real device before considering the milestone done |
| Treating "workmanager background refresh" as simply "missing" on web without a replacement mental model | Forecast can go stale if the user leaves a tab open for a long time with no foreground refresh trigger | Add an explicit on-foreground/on-visibility-change refresh trigger (e.g., refresh when the tab regains focus or on each app open) so staleness is bounded, even without background scheduling |

## "Looks Done But Isn't" Checklist

- [ ] **Renderer choice:** Often "done" after `flutter build web` succeeds locally in Chrome — verify it also loads correctly in real Safari on an actual iPhone (not just Chrome DevTools device emulation, which does not use WebKit).
- [ ] **Google Calendar sign-in:** Often "done" after working once in desktop Chrome — verify the full OAuth round-trip on real Safari (mobile and macOS), including the first-attempt-after-fresh-load case where popup blocking is most likely.
- [ ] **PWA installability:** Often "done" because `manifest.json` validates and Chrome shows an install icon — verify the actual iOS Add-to-Home-Screen experience end-to-end: correct icon, correct app title, no blank splash flash, and (if launched from home screen) `navigator.standalone === true`.
- [ ] **Geolocation:** Often "done" because it worked once during dev — verify behavior on a second/third visit in Safari, including what happens if the user denies or the browser re-prompts, and confirm the manual city picker is a real fallback, not just present in the code.
- [ ] **Data persistence:** Often "done" because Drift reads/writes work in a single test session — verify (or at minimum document/log) which storage backend Safari actually selects, and consciously decide the fallback plan for ITP eviction rather than assuming IndexedDB is durable.
- [ ] **Android regression:** Often assumed "unaffected" because no Android-specific code was touched — explicitly run `flutter build apk` (or `flutter analyze` targeting Android) after any change to files shared between web and native code paths, since conditional-import mistakes break silently otherwise.
- [ ] **Cache/deploy freshness:** Often "done" once `firebase deploy` succeeds — verify a second deploy actually reaches already-visiting users (test by loading the app before a deploy, deploying, then reloading without hard-clearing cache) rather than assuming Firebase Hosting's CDN invalidation alone is sufficient.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Chose `--wasm` and it breaks on Safari post-launch | LOW | Rebuild and redeploy with plain `flutter build web --release` (CanvasKit/JS); no data migration needed since this is a build-flag change, not a schema change |
| Users losing local data to ITP eviction | MEDIUM | Cannot recover already-lost data (by design — it's device/browser-local). Mitigate going forward by shipping the Add-to-Home-Screen banner (Pitfall 7) and a faster re-onboarding flow; consider a lightweight settings export/import as a future improvement if this proves to be a frequent complaint |
| OAuth misconfigured for production domain after launch | LOW | Add the missing domain to Authorized JavaScript Origins / redirect URIs in Google Cloud Console — takes effect immediately, no app redeploy needed, but affected users must retry sign-in |
| Android build broken by a web-only import leaking into shared code | LOW-MEDIUM | Isolate the offending import behind a conditional-import stub file, recompile both targets, and add `flutter build apk` as a required pre-merge/pre-deploy check going forward so this doesn't recur |
| Stale cached build stuck on users' devices after a deploy | LOW-MEDIUM | Add proper `Cache-Control` headers in `firebase.json` (no-cache for index.html/service worker) and redeploy; already-stuck users may need to manually force-refresh once (a one-time in-app "new version available, tap to reload" banner driven by service-worker update detection helps here) |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. `--wasm`/skwasm Safari breakage | Web scaffolding / build setup | Manual load test on a real iPhone in Safari, not just Chrome/emulator |
| 2. ITP 7-day storage eviction | Data layer (Drift web port) + PWA installability | Log/confirm selected storage backend; confirm home-screen-installed exemption; design re-onboarding to be fast |
| 3. WAL/native schema not portable to web | Data layer (Drift web port) | Run full migration suite against the web wasm backend specifically, not just native |
| 4. google_sign_in popup blocking / FedCM gap | Google Calendar web integration | Manual OAuth round-trip test in real Safari (fresh-load first-attempt case) |
| 5. OAuth origin/redirect misconfiguration | Google Calendar web integration + deployment/hosting | Confirm sign-in works against the actual production Firebase Hosting URL, not just localhost |
| 6. Geolocation re-prompt / no fallback | Location/geolocation web port | Verify forecast shows within 2s using cached/fallback location even when prompt reappears |
| 7. No `beforeinstallprompt` on iOS | PWA installability | Manual verification that iOS Safari users see explicit Add-to-Home-Screen guidance |
| 8. manifest.json ignored by iOS for icon/splash | PWA installability | Real-device check of installed home-screen icon, title, and launch experience |
| 9. `kIsWeb` vs conditional imports breaking a platform | Web scaffolding (pattern established up front) | `flutter build apk` + `flutter build web` (or `flutter analyze` for both) required after any shared-file change, every phase |
| 10. Tests green, Safari broken | All phases (cross-cutting) | Explicit "manual Safari/iOS verification" success criterion in every phase touching web-visible behavior |

## Sources

- [Flutter: Web renderers](https://docs.flutter.dev/platform-integration/web/renderers) — HIGH confidence, official docs
- [Flutter: Support for WebAssembly (Wasm)](https://docs.flutter.dev/platform-integration/web/wasm) — HIGH confidence, official docs
- [flutter/flutter#154344 — Support WasmGC on Safari](https://github.com/flutter/flutter/issues/154344) — MEDIUM confidence, open upstream issue tracking Safari wasm compatibility
- [flutter/flutter#183265 — FlutterLoader could not find a build compatible with configuration and environment](https://github.com/flutter/flutter/issues/183265) — MEDIUM confidence, reported fallback-logic bug
- [Drift: Web platform docs](https://drift.simonbinder.eu/platforms/web/) — HIGH confidence, official package docs (storage backend hierarchy, WAL limitation, Content-Type requirement, Safari worker-cache bug)
- [simolus3/drift#2382 — Feedback wanted: Drift on the web](https://github.com/simolus3/drift/issues/2382) — MEDIUM confidence, maintainer discussion of IndexedDB/OPFS tradeoffs
- [Safari Un-Intelligent Tracking Prevention: Data loss by design](https://lapcatsoftware.com/articles/2023/8/5.html) — MEDIUM confidence, independent analysis, corroborated by WebKit's own tracking-prevention docs
- [WebKit: Tracking Prevention in WebKit](https://webkit.org/tracking-prevention/) — HIGH confidence, official WebKit documentation of the 7-day script-writable storage cap and home-screen-app exemption
- [What Safari's 7-day cap on script-writeable storage means for PWA developers](https://searchengineland.com/what-safaris-7-day-cap-on-script-writeable-storage-means-for-pwa-developers-332519) — MEDIUM confidence
- [Google: Migrate to FedCM](https://developers.google.com/identity/gsi/web/guides/fedcm-migration) — HIGH confidence, official Google Identity docs (confirms Safari lacks FedCM support)
- [flutter/flutter#81447 — popup_blocked_by_browser](https://github.com/flutter/flutter/issues/81447) and [#54768](https://github.com/flutter/flutter/issues/54768) — MEDIUM confidence, multiple independent reports of the same Safari popup-blocking pattern
- [How to correctly set up Google Sign-In Redirect on Flutter Web (firebase/flutterfire discussion #17896)](https://github.com/firebase/flutterfire/discussions/17896) — MEDIUM confidence, community-verified setup steps
- [Apple Developer Forums: HTML Geolocation API does not work...](https://developer.apple.com/forums/thread/751189) and [After granting location permission...](https://developer.apple.com/forums/thread/740270) — LOW-MEDIUM confidence, user reports on Apple's own forums describing iOS Safari geolocation re-prompt behavior
- [geolocator pub.dev package page](https://pub.dev/packages/geolocator) — HIGH confidence, official package docs (web permission-API limitations)
- [Getting 'Save to Home Screen' to Kinda Work on iOS](https://naildrivin5.com/blog/2023/08/24/braindump-of-pwa-on-ios.html) — MEDIUM confidence, detailed practitioner write-up of iOS PWA manifest/icon quirks
- [Cached flutter-web service worker — flutter/flutter#106943](https://github.com/flutter/flutter/issues/106943) — MEDIUM confidence, well-known caching issue with community-verified Firebase Hosting mitigation
- [Optimizing performance in Flutter web apps with tree shaking and deferred loading (Flutter blog)](https://blog.flutter.dev/optimizing-performance-in-flutter-web-apps-with-tree-shaking-and-deferred-loading-535fbe3cd674) — HIGH confidence, official Flutter team blog
- [flutter/flutter#154986 — Icon tree shaking doesn't work well on web](https://github.com/flutter/flutter/issues/154986) — MEDIUM confidence, open tooling issue
- [Flutter: Conditional imports across Flutter and Web (Medium, Flutter Community)](https://medium.com/flutter-community/conditional-imports-across-flutter-and-web-4b88885a886e) — MEDIUM confidence, widely-cited community pattern reference
- [Flutter: Check app functionality with an integration test](https://docs.flutter.dev/testing/integration-tests) — HIGH confidence, official docs (confirms widget-test/browser-engine gap)
- Existing project context: `/Users/joostmouw/ridewindow/CLAUDE.md`, `/Users/joostmouw/ridewindow/pubspec.yaml`, `/Users/joostmouw/ridewindow/.planning/PROJECT.md`

---
*Pitfalls research for: Flutter Web/PWA milestone (v2.0), targeting iOS Safari via Firebase Hosting, added onto existing native Android app*
*Researched: 2026-07-10*
