# Feature Research

**Domain:** Installable PWA on iOS Safari (Flutter Web) — RideWindow v2.0 milestone
**Researched:** 2026-07-10
**Confidence:** MEDIUM-HIGH (iOS-specific mechanics verified across WebKit's own blog + multiple independent 2026 sources; storage-eviction specifics conflict between sources and are flagged where noted)

> **Note on scope:** This file supersedes the v1.0 FEATURES.md (Android competitor/feature-landscape research, dated 2026-06-01, archived in git history) for the purposes of the v2.0 milestone. v1.0's feature landscape (scoring, slot generation, availability calendar, competitor gaps) remains valid and shipped — see `.planning/PROJECT.md` "Validated" section. This research answers a narrower, milestone-specific question: what does "installable PWA on iOS Safari" actually require, separate from the already-solved core product features being ported to web.

---

## Context: What Actually Changes for the User

A regular Safari tab and an "Added to Home Screen" web app are, per Apple's own storage-policy documentation, **treated as separate contexts with their own inactivity counters** — but they otherwise share the same underlying storage quota (60% origin / 80% overall of free disk) ([WebKit: Updates to Storage Policy](https://webkit.org/blog/14403/updates-to-storage-policy/)). Practically, once a user taps "Add to Home Screen":

- **Icon:** The icon shown is *not* reliably pulled from `manifest.json` — iOS Safari prioritizes a dedicated `<link rel="apple-touch-icon">` tag in `web/index.html` and only falls back to the manifest's `icons` array if no apple-touch-icon is present. Skipping this produces a blurry auto-generated screenshot icon on the home screen ([webhint.io](https://webhint.io/docs/user-guide/hints/hint-apple-touch-icons/), [premiumfavicon.com](https://www.premiumfavicon.com/blog/apple-touch-icon-guide)). **HIGH confidence, iOS-specific — Flutter's default `manifest.json` icons are not sufficient alone.**
- **Standalone mode:** No URL bar, no Safari toolbar, and no native swipe-back-to-previous-page gesture. The app must supply its own back/close affordances; `go_router`'s default web history behavior does not by itself replace the browser chrome the user is used to. **HIGH confidence.**
- **Splash screen:** iOS shows a static launch image built from `<link rel="apple-touch-startup-image">` tags (device-size-specific — no automatic generation from the manifest like Android). `theme_color` in the manifest sets the status bar color during this launch phase; `background_color` sets the splash background. Skipping this produces a jarring white flash on launch ([web.dev/learn/pwa/enhancements](https://web.dev/learn/pwa/enhancements)). **HIGH confidence.**
- **Storage behavior:** Home-screen web apps get the *same quota* as Safari tabs, but data can still be evicted under storage pressure or extended inactivity. WebKit's official position is that home-screen apps are not expected to lose data as readily as regular-tab storage, but several independent sources report a ~7-day inactivity eviction window still applies in practice, plus a ~50MB Cache API soft cap. **MEDIUM confidence — sources conflict; treat as a real, unresolved risk** ([itnews.com.au](https://www.itnews.com.au/news/apple-cops-flak-for-deleting-local-browser-storage-after-7-days-539833), [Apple Developer Forums](https://developer.apple.com/forums/thread/710157), [WebKit blog](https://webkit.org/blog/14403/updates-to-storage-policy/)).

This context shapes every feature decision below.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features required for the web build to feel like a real app rather than "a website with a bookmark." Missing any of these makes the PWA feel broken compared to the shipped Android app.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| App icon + splash screen tuned for iOS (`apple-touch-icon`, `apple-touch-startup-image`, `theme_color`, `background_color`) | Users judge "is this a real app" by the home screen icon and launch flash; Flutter's default `manifest.json` alone is insufficient on iOS | LOW-MEDIUM | Flutter's `web/index.html` template needs manual `<link>` tags added; splash images are size-specific per device — either generate a set (e.g. via a generator script) or accept a plain-color splash with correct `background_color`/`theme_color` as the lower-effort v2.0 baseline |
| Custom "Install this app" instructional UI | iOS Safari does **not** implement `beforeinstallprompt` — there is no native one-tap install banner on iOS at all, ever. Every install is a manual Share-sheet → "Add to Home Screen" action | MEDIUM | Must detect iOS Safari specifically (Android Chrome *does* support `beforeinstallprompt` and should show its own native-triggered flow instead) and show a static illustrated instruction ("tap Share, then Add to Home Screen"). Must only render in browser mode — hide via the `display-mode: standalone` CSS media query once installed, otherwise it nags already-installed users |
| Standalone display config (`display: standalone` in manifest, `apple-mobile-web-app-capable` + `apple-mobile-web-app-status-bar-style` meta tags, `env(safe-area-inset-*)` CSS) | Without this, "Add to Home Screen" just bookmarks a Safari tab — full browser chrome stays, defeating the point of installing | LOW-MEDIUM | Standard boilerplate; safe-area insets matter for notch/Dynamic Island devices so the app bar doesn't sit under the status bar |
| Cache-then-network fetch with visible "Last updated HH:MM" label | Users lose the mental model of "the app refreshed in the background" (which they had on Android via WorkManager) — an explicit timestamp rebuilds trust that data is current | LOW | Reuses existing `AsyncNotifier` weather provider; only the trigger changes (see refresh strategy below) |
| Refresh-on-load + refresh-on-focus (page visibility) + manual pull-to-refresh | Direct replacement for the Android background-refresh feature, which has no web equivalent (`workmanager` has no web backend, and Safari does not implement the Periodic Background Sync API at all) | MEDIUM | `visibilitychange`/focus listeners trigger a re-fetch when the user reopens the tab/app; `RefreshIndicator` gives an explicit manual gesture. This is a genuine feature replacement, not a nice-to-have — without it, data can go stale for days between opens |
| Offline fallback UI (last-known slots shown, clearly labeled stale, when fetch fails) | Without connectivity or with evicted cache, the app must not show a blank screen or crash — users expect *some* content, even if stale | MEDIUM | Depends on the cache-then-network pattern above; needs a distinct "offline / showing cached data from [time]" banner state, not a silent failure |
| Graceful geolocation handling with fast fallback to manual city picker | Browser geolocation on iOS Safari has no native-style "Always Allow" — permission is asked per-origin and iOS defaults to "Ask" (re-prompting per session is common), and HTTPS is mandatory (Firebase Hosting satisfies this) | LOW-MEDIUM | The existing manual city override (already shipped in v1) becomes the primary fallback path on web, not a rarely-used secondary option — surface it immediately on permission denial/timeout rather than after a long retry loop |
| In-app back/close navigation controls | Standalone mode removes the browser's back button and (in practice) the OS-level edge-swipe-back gesture available in a normal Safari tab; the app is now solely responsible for all navigation affordances | MEDIUM | Verify `go_router`'s web history handling still produces sensible in-app back behavior when there is no browser chrome to fall back on |
| External links open without permanently ejecting the user from standalone mode | Privacy policy links, Google OAuth popups, and "Add to Calendar" flows can hand off to Safari; a careless implementation strands the user in a browser tab instead of returning them to the installed app | LOW-MEDIUM | Test the actual Google Identity Services web sign-in popup behavior inside standalone mode specifically — popup-based OAuth flows have known quirks in standalone PWA contexts on iOS |

### Differentiators (Competitive Advantage)

Not required for the PWA to function, but they turn iOS's constraints into a more transparent, trustworthy experience than a typical "silently stale" PWA — directly reinforcing the Core Value (accurate, bookable slots the user can trust).

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Explicit "Showing cached forecast from [time], refreshing…" banner during cache-then-network refresh | Most PWAs either show a stale forecast silently or flash a jarring reload — being transparent about data freshness matches the app's "accuracy is the core value" positioning | LOW | Natural extension of the "Last updated" label already required as table stakes |
| Contextual "Add to Home Screen" nudge shown after N genuinely useful visits (not on first load) | A day-one install nag has low conversion and feels spammy; a nudge after the user has already seen a good ride slot is more persuasive and less annoying | MEDIUM | Needs a lightweight local visit/engagement counter (Drift or shared_preferences) — no backend needed |
| `display-mode` detection to tailor onboarding copy (browser-tab visitor vs. installed-app user) | Lets the app skip install-nagging entirely for users who already installed, and lets browser-tab users know *why* installing helps (offline slots, faster reopen) | LOW | Single CSS media query / JS check surfaced to Flutter via a platform channel or `dart:html` |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| Web Push notifications for v2.0 | "Just port the Android notifications to web" | iOS Web Push only works for an *already-installed* standalone PWA on iOS 16.4+, requires its own separate permission opt-in, and reliability/delivery timing is materially worse than native — disproportionate effort for a milestone whose install-rate is still unproven | Already correctly deferred per PROJECT.md; revisit once install adoption is measured |
| True periodic background refresh (a web "WorkManager equivalent") | "We already built background refresh for Android, just reuse the pattern" | Safari does not implement the Periodic Background Sync API at all (not even behind a flag) — there is no browser-side background execution window on iOS Safari, installed or not | On-load / on-focus / pull-to-refresh (already listed as table stakes) is the actual ceiling of what's achievable |
| Relying on `navigator.storage.persist()` as a guarantee that the availability calendar and cached forecast survive indefinitely | Seems like the "correct" API to call to protect user data | `navigator.storage.persist()` is not supported by iOS Safari at all — there is no Persistent Storage API on iOS, so the call is effectively a no-op there (harmless to call defensively for other platforms, but must not be load-bearing for the product's data-durability story on iOS) | Treat weather/forecast cache as disposable and cheaply re-fetchable (it already is, by design). Treat the user-authored availability calendar and preferences as higher-value data; since sources conflict on whether 7-day eviction actually hits home-screen apps in practice, this needs verification during implementation (e.g., manual testing after a week of non-use) rather than being assumed solved |
| Full offline-first parity with the native app (fresh weather data available with zero connectivity) | "The Android app caches and refreshes in the background, web should too" | Impossible without fabricating data — there is no way to get a genuinely fresh forecast with zero network on iOS Safari | Offline fallback clearly shows last-known slots as stale, never presents cached data as current |
| A JS-style automatic install prompt/banner on iOS (mimicking Android Chrome's `beforeinstallprompt` UX) | Parity with Android's one-tap install banner | Technically impossible — Apple has never implemented this API in Safari, on any iOS version to date | Static instructional overlay (Share icon → Add to Home Screen), the only path that exists on iOS |

---

## Feature Dependencies

```
Custom "Install this app" instructional UI
    └──requires──> Browser/OS detection (iOS Safari vs Android Chrome vs desktop)
                       └──different-path──> Android Chrome uses native beforeinstallprompt capture instead

Offline fallback UI
    └──requires──> Cache-then-network fetch strategy
                       └──requires──> "Last updated" timestamp persisted alongside cached forecast

Refresh-on-focus / refresh-on-load / pull-to-refresh
    └──enhances──> Existing AsyncNotifier weather provider (v1 Android code, reused as-is;
                    only the trigger source changes from WorkManager periodic task to page lifecycle events)

Graceful geolocation handling on web
    └──enhances──> Existing manual city override feature (already shipped in v1 — becomes primary
                    fallback path on web rather than a rarely-used secondary option)

Standalone display config (manifest + meta tags)
    └──requires──> apple-touch-icon / apple-touch-startup-image assets generated per device size

Contextual "Add to Home Screen" nudge
    └──conflicts-with──> Showing the nudge in standalone mode
                             └──must check `display-mode: standalone` media query first
```

### Dependency Notes

- **Refresh strategy reuses existing scoring/fetch code:** The v1 Android weather-fetch and scoring logic (`AsyncNotifier`-based) does not need to change for v2.0 — only what *triggers* a refetch changes (from a WorkManager periodic task to page-visibility/focus events and a manual pull gesture). This is the single biggest complexity-reducer for the milestone: the core value (accurate scoring, slot detection) is already portable Dart code, per PROJECT.md's decision to reuse the codebase for Flutter Web.
- **Manual city override becomes load-bearing on web:** In v1 it was a fallback for GPS-unavailable/travel scenarios. On web it must handle the much more common case of a user declining or being re-prompted for geolocation permission every session — the UX needs to treat "permission denied/timed out" as an expected, frequent path, not an edge case.
- **Install UI requires platform branching:** Android Chrome visiting the same PWA *does* support `beforeinstallprompt`, so the install-prompt code needs two paths — captured native event on Android/Chrome, static illustrated instructions on iOS Safari. Don't build a single "universal" install banner; the underlying mechanisms are fundamentally different.
- **Storage durability is an open risk, not a dependency to design around confidently:** Because sources conflict on whether the ~7-day inactivity eviction applies to home-screen-installed apps the same way it applies to regular Safari tabs, this should be flagged for verification during implementation (test: leave the installed PWA untouched for 7+ days, confirm availability-calendar and cached-forecast state after reopening) rather than assumed either way.

---

## MVP Definition

### Launch With (v2.0)

Minimum viable product for the PWA milestone — what's needed to validate that iOS users can get real value without a native app. (Core scoring/slot generation/availability calendar/Google Calendar integration are already-shipped v1 features being ported per PROJECT.md — listed here only as the dependency baseline everything else sits on top of.)

- [ ] Manifest + `apple-touch-icon` + `apple-touch-startup-image` + `theme_color`/`background_color` — without this the app looks like a bookmarked website, not an app
- [ ] iOS-specific "Add to Home Screen" instructional overlay (shown once per browser-mode visit, hidden via `display-mode: standalone` check once installed) — this is the *only* install path that exists on iOS; skipping it means most users never discover the app is installable
- [ ] Standalone display config (manifest `display: standalone`, status-bar meta tags, safe-area CSS) — the entire point of installing
- [ ] Cache-then-network fetch + visible "Last updated HH:MM" label — replaces the trust signal that background refresh provided on Android
- [ ] Refresh-on-load + refresh-on-focus + manual pull-to-refresh — the actual replacement for WorkManager background refresh; there is no better alternative on Safari
- [ ] Offline fallback UI showing last-cached slots, clearly labeled stale, when a fetch fails
- [ ] Geolocation per-session request with the existing manual city picker surfaced immediately on denial/timeout
- [ ] Ported core scoring + slot generation + availability calendar + Google Calendar integration (already scoped in PROJECT.md — the dependency baseline)

### Add After Validation (v2.x)

- [ ] Contextual "Add to Home Screen" nudge after N genuinely useful sessions — trigger: install rate from the static overlay alone turns out low
- [ ] Best-effort `navigator.storage.persist()` call + `navigator.storage.estimate()` quota check with a user-facing low-storage warning — trigger: real-world reports of data loss on iOS after inactivity
- [ ] Explicit standalone-vs-browser-tab onboarding copy variants — trigger: analytics show meaningful browser-tab-only usage that never converts to install

### Future Consideration (v3+)

- [ ] Web Push notifications (iOS 16.4+ installed-PWA only) — defer until PWA install adoption is proven; not worth the reliability tradeoff yet
- [ ] Availability-calendar export/import as a hedge against storage eviction — only worth building if the 7-day-eviction risk is confirmed in practice for installed apps (currently an open, unverified risk, not a confirmed one)
- [ ] Native iOS App Store app — only if the web version validates real demand (per PROJECT.md's Out of Scope reasoning)

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| App icon + splash config (iOS-specific tags) | HIGH | LOW | P1 |
| Custom iOS install instructional UI | HIGH | MEDIUM | P1 |
| Standalone display config + safe-area handling | HIGH | LOW-MEDIUM | P1 |
| Cache-then-network + "last updated" label | HIGH | LOW | P1 |
| Refresh-on-load/focus + pull-to-refresh | HIGH | MEDIUM | P1 |
| Offline fallback UI | MEDIUM-HIGH | MEDIUM | P1 |
| Geolocation per-session handling + city fallback | HIGH | LOW-MEDIUM | P1 |
| In-app back/close navigation | MEDIUM | MEDIUM | P1 |
| External-link/OAuth standalone-mode handling | MEDIUM | LOW-MEDIUM | P1 |
| Contextual install nudge (post-first-overlay) | MEDIUM | MEDIUM | P2 |
| `storage.persist()` + quota warning | LOW-MEDIUM | LOW | P2 |
| Availability-calendar export/import | LOW (until proven necessary) | MEDIUM | P3 |
| Web Push notifications | MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Must have for the milestone to feel like a working, installable app
- P2: Should have, add once real usage data exists
- P3: Nice to have, defer until a specific trigger condition is met

---

## Competitor / Pattern Analysis

Direct competitor weather/planning PWAs with public iOS install-UX writeups are scarce; the most-cited general-purpose reference cases for "how to do iOS PWA install/offline right" are large consumer PWAs (Twitter Lite/X, Pinterest, Starbucks) rather than weather-specific apps. Treat this as directional pattern evidence (MEDIUM confidence), not a like-for-like feature comparison.

| Concern | Common PWA Pattern (Twitter/Pinterest/Starbucks-style) | Typical Weather-App Native Behavior | Our Approach |
|---------|--------------------------------------------------------|--------------------------------------|--------------|
| Install discovery | Static illustrated "Add to Home Screen" instructions shown after initial engagement, not on first load | N/A (installed via App Store, no in-app instruction needed) | Static overlay on first browser-mode visit, refined to post-engagement nudge in v2.x |
| Offline behavior | Cache last-viewed content, show clear "offline" indicator, no fabricated freshness | Native OS handles connectivity gracefully, background refresh keeps data fresh regardless | Cache-then-network with explicit "last updated" timestamp; never claim cached data is current |
| Location permission | Ask once per session if not previously permission-cached by the browser; quick fallback UI on denial | Native "Always/While Using/Never" system dialog, remembered indefinitely | Per-session ask + immediate manual-city fallback, reusing existing v1 city picker |

---

## Sources

- [WebKit: Updates to Storage Policy](https://webkit.org/blog/14403/updates-to-storage-policy/) — official storage-quota and eviction-trigger documentation for home-screen web apps vs Safari tabs
- [Apple cops flak for deleting local browser storage after 7 days — iTnews](https://www.itnews.com.au/news/apple-cops-flak-for-deleting-local-browser-storage-after-7-days-539833)
- [Safari iOS PWA Data Persistence Beyond 7 Days — Apple Developer Forums](https://developer.apple.com/forums/thread/710157)
- [PWA iOS Limitations and Safari Support [2026] — MagicBell](https://www.magicbell.com/blog/pwa-ios-limitations-safari-support-complete-guide)
- [Safari PWA Limitations on iOS — BSWEN, 2026-03-12](https://docs.bswen.com/blog/2026-03-12-safari-pwa-limitations-ios/)
- [There is no Persistent Storage API on iOS — Maximiliano Firtman](https://medium.com/@firt/there-is-no-persistent-storage-api-on-ios-and-you-dont-have-control-of-that-unfortunately-because-361adb5e9dc0)
- [web.dev: Installation prompt](https://web.dev/learn/pwa/installation-prompt)
- [web.dev: Enhancements (splash screens, theme-color, apple-touch-startup-image)](https://web.dev/learn/pwa/enhancements)
- [MDN: Making PWAs installable](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Making_PWAs_installable)
- [webhint.io: Use Apple touch icon](https://webhint.io/docs/user-guide/hints/hint-apple-touch-icons/)
- [Apple Touch Icon: The Complete Guide — Premium Favicon](https://www.premiumfavicon.com/blog/apple-touch-icon-guide)
- [Drift: Web platform docs](https://drift.simonbinder.eu/platforms/web/) — OPFS/IndexedDB backend behavior for local storage on web
- Flutter Web PWA guides on manifest.json / auto-generated `flutter_service_worker.js` / `--pwa-strategy` build flag (multiple 2025-2026 community sources, MEDIUM confidence — cross-check against Flutter's own web build docs during implementation)
- Geolocation permission behavior: Apple Community discussion threads on per-site "Ask every time" default in Safari (MEDIUM confidence, user-reported, consistent across threads)
- `flutter-geolocator` and `flutterlocation` GitHub issue trackers — documented web-platform limitations (lat/long only, no full position attributes, permission-check quirks) (HIGH confidence, primary-source issue trackers)

---
*Feature research for: Installable PWA on iOS Safari (RideWindow v2.0 Flutter Web milestone)*
*Researched: 2026-07-10*
