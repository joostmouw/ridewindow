# RideWindow

## What This Is

RideWindow is an app for casual cyclists who want to know — at a glance — the best windows to ride this week. It combines an accurate cycling-specific weather score (temperature, rain, wind) with the user's personal availability calendar to produce concrete, bookable time slots like "Saturday 09:00–13:00, 4h — Perfect". Native Android (Play Store, v1.0) is live; a Flutter Web/PWA build reaching iOS users (v2.0) is now also live at https://my-project-joost.web.app, with zero domain/UI code changes from the Android codebase.

## Core Value

**Accurate cyclist-specific weather scoring translated into concrete bookable time slots.** If the score is wrong, or the slot is unrideable in practice, the app fails — everything else is decoration.

## Current State (post-v2.0)

**v2.0 iOS Web App (PWA) shipped 2026-07-17.** RideWindow now runs on two platforms from one Dart codebase: native Android (Play Store, v1.0) and Flutter Web/PWA for iOS (v2.0, Firebase Hosting). Both are live and confirmed unaffected by each other's platform-specific additions.

<details>
<summary>v2.0 milestone goal (archived)</summary>

**Goal:** Reach iOS users cheaply via a Flutter Web/PWA build of RideWindow, without an Apple Developer account.

**Target features:**
- Flutter Web build reusing existing Dart code (scoring, providers, UI) — core scoring, slot generation, availability calendar
- Google Calendar integration on web (Google Identity Services flow via `google_sign_in` web support)
- Deployed to Firebase Hosting

**Key context:** Notifications (Evening before / Morning of / Weekly digest) were explicitly skipped for this milestone — iOS Safari only supports Web Push for an installed PWA (iOS 16.4+) and is less reliable than native; revisit once PWA install adoption is known. `workmanager` has no web support, so background refresh became an on-foreground/on-load refresh strategy instead. Drift's web backend (IndexedDB/wasm) storage-eviction risk was accepted, not yet observed in practice.

</details>

## Next Milestone Goals

Not yet defined — run `/gsd:new-milestone` to scope v2.1+ (candidates already sitting in BACKLOG.md include: contextual "Add to Home Screen" nudge, iOS Web Push once PWA adoption is known, Android home screen widget, week-agenda overlap view, and the accumulated feedback-backlog quick tasks — see BACKLOG.md for the full list).

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

**v1.0 — Android app (shipped to Play Store, iterating since)**
- [x] App fetches 7-day hourly weather forecast for user's location (Open-Meteo)
- [x] App computes a cyclist-specific score (0–100) per hour using temperature, rain, and wind
- [x] App identifies contiguous good-weather hours and produces ride slots of 2h, 3h, and 4–5h durations
- [x] App filters slots against user's blocked hours (work + custom) so only available slots are shown
- [x] App displays "Why this score?" insights with 3 progress bars (temp/rain/wind) and short explanations
- [x] First-run onboarding asks user to pick a free-time preset (Evenings & weekends / Mornings & weekends / Weekends only / Custom calendar)
- [x] Profile screen lets user edit a weekly availability calendar (block/unblock individual hour cells)
- [x] Profile screen lets user pick ride length preferences (2h, 3h, 4–5h chips)
- [x] Profile screen exposes 3 weather-tolerance sliders (temperature, wind, rain) that affect scoring
- [x] App requests location permission on first run and uses GPS as the default forecast location
- [x] User can override location manually with a city picker (fallback when GPS unavailable or for travel)
- [x] User can sign in to Google Calendar (optional, on-demand at "Add to calendar" tap)
- [x] "Add to calendar" creates a Google Calendar event with the slot's start, end, and weather summary
- [x] User can toggle "Evening before" notification (great-ride heads-up the day before)
- [x] User can toggle "Morning of" notification (window opens in 2h)
- [x] User can toggle "Weekly digest" (Sunday evening summary)
- [x] All user data (profile, availability, tolerances, settings) is stored locally on device
- [x] Forecast results are cached locally and refreshed in the background
- [x] App is signed and packaged as a release AAB for Google Play Console internal testing track
- [x] Privacy policy is published and linked in the Play Store listing

**v2.0 — Flutter Web/PWA for iOS (shipped 2026-07-17, Firebase Hosting)**
- [x] Flutter Web build reuses the existing Dart codebase (scoring, providers, all six screens) with zero domain/UI code changes — v2.0
- [x] Native-only plugins (`workmanager`, `home_widget`) safely guarded with `kIsWeb` checks — v2.0
- [x] Drift local database works on web via `DriftWebOptions`/`sqlite3.wasm`, data survives full page reload — v2.0
- [x] `sqlite3.wasm` served with correct `Content-Type: application/wasm` from Firebase Hosting — v2.0
- [x] Browser Geolocation API works over HTTPS on the deployed domain, with manual city picker promoted to primary path on denial/timeout (iOS Safari's per-session re-prompt behavior) — v2.0
- [x] Foreground refresh strategy (on-load, on-focus, pull-to-refresh, "Last updated" label, stale-data-with-offline-banner fallback) replaces WorkManager on web — v2.0
- [x] Google Calendar "Add to calendar" works end-to-end on web via OAuth, verified on real iPhone Safari by two independent testers — v2.0
- [x] PWA installability: branded icons/splash tuned for iOS, standalone-mode navigation (no dead ends), "Add to Home Screen" overlay for iOS Safari — v2.0 (achieved after Play Store v1.0)
- [x] Deployed to a stable HTTPS URL (Firebase Hosting) with SPA routing proven correct via real curl checks, not just config inspection — v2.0
- [x] Full regression pass confirms Android app unaffected by all web-platform additions (`flutter build apk --release` + manual smoke test) — v2.0

### Active

<!-- Current scope. Building toward these. -->

Not yet defined — awaiting `/gsd:new-milestone` for v2.1+.

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- **Native iOS App Store app** — v2 addressed iOS via Flutter Web/PWA instead, avoiding the $99/yr Apple Developer account. A native iOS app remains a possible v3+ if the web version validates demand.
- **Push notifications on web** — iOS Safari Web Push only works for an installed PWA (16.4+) and is less reliable than native; deferred until PWA install adoption is known. Still valid post-v2.0.
- **Background refresh on web** — `workmanager` has no web support; refresh happens on foreground/page-load instead of via periodic background task. Still valid — this is how it shipped.
- **User accounts / backend** — No login, no cross-device sync. All data lives locally (per platform/browser). Removes auth complexity, privacy policy headaches, and backend cost.
- **Monetization (IAP / ads)** — Free with no ads. Still a portfolio/hobby project validating core value before considering revenue.
- **Multi-location / route planning** — One location at a time, no route/elevation integration. Future differentiator.
- **Social features** — No groups, no shared rides, no leaderboards. Personal planning tool.
- **Apple Watch / Wear OS companion** — Phone/browser-only. Smartwatch is v3+ territory.
- **Cycling-type specialization (road / gravel / MTB)** — One generic "ride" profile; tolerances cover personalisation.
- **Historical weather analytics** — Forward-looking only, 7 days. No "best ride days last month" reporting.

## Context

**Solo dev, evenings & weekends.** Joost works Mon–Fri 09:00–17:00 at Fanalists. RideWindow is a side project to validate a real personal need (concrete ride slots that respect work hours).

**Mockup exists.** A complete interactive HTML mockup lives at `/Users/joostmouw/ridewindow/mockup.html` and covers all 6 screens (Welcome, Onboarding, Home, Ride Detail, Profile, Availability). It serves as the visual contract for the UI phase — `/gsd-ui-phase` should consume it directly.

**User profile is the persona.** The primary user persona is the developer himself: casual rider, 2–5h rides, weekday work hours, wants bookable slots, not vague advice. The mockup is built around this persona.

**Weather data is solved.** Open-Meteo provides free, no-key, hourly forecasts for arbitrary coordinates. Already validated via the KNMI MCP server work earlier in 2026.

**Scoring approach is defined.** Three weighted factors (temperature, rain, wind) each scored 0–100, combined into an overall ride score. Tolerances per factor are user-adjustable via sliders. Defaults: 12–26°C ideal, wind <15 km/h ideal, rain <0.5mm ideal.

**Release strategy is conservative.** Internal testing track with 10–20 cyclist friends first. Play Console internal track has no review and unlimited invites — fast iteration loop before going to closed beta and then production.

**v2.0 shipped 2026-07-17: Flutter Web/PWA live for iOS.** `CalendarService.warmUpForWeb()` (eager, concurrency-safe GoogleSignIn init) plus a real Web OAuth Client ID resolved the Safari popup-blocker risk (CAL-06); the web app is live at `https://my-project-joost.web.app` on Firebase Hosting, with "Add to calendar" verified end-to-end on real iPhone Safari by two independent testers, both clean on the first tap (CAL-07). PWA installability (branded icons, standalone-mode navigation, install overlay) verified on a real iPhone in Phase 16. Phase 17 redeployed and curl-proved the SPA rewrite + `sqlite3.wasm` headers against the live domain, corrected the automated-test baseline (215 passing / 69 failing / 13 files — pre-existing gap, tracked in BACKLOG.md #11, not a v2.0 regression), and confirmed `flutter build apk --release` still succeeds. The Google Cloud project backing web Calendar OAuth (`my-project-joost`) is a fresh project, not the (never-completed) Phase 9 Android OAuth project — Android's own Calendar OAuth client still needs equivalent Cloud Console setup if that native feature is to work in production. The OAuth consent screen remains in Testing publish status (manually-added testers only); publishing/full Google verification before public launch is tracked in BACKLOG.md (#31).

**Codebase size at v2.0 close:** ~20,400 LOC Dart in `lib/`. Automated test baseline: 215 passing / 69 failing across 13 files (pre-existing gap predating v2.0, tracked as BACKLOG.md #11 — not fixed in this milestone, scoped as future test-suite work).

**11 quick-task backlog items acknowledged as deferred at v2.0 close** (audit-tool tracking gap, not unfinished work — each has a committed PLAN+SUMMARY): Android home screen widget, week-agenda overlap view, ride-detail weather icon, send-feedback dialog, Calendar-connection backlog item, sticky plan-ride button, ride-detail plan-ride state, screen-hint overlay restyle, availability-grid two-tap range select, unplan/delete from ride-detail, agenda-tab tap-parity. See STATE.md "Deferred Items" for the full list.

## Constraints

- **Tech stack:** Flutter (Dart) — chosen for cross-platform readiness (iOS in v2), Material 3 out-of-the-box, hot reload DX, lower dependency-maintenance burden than React Native for solo devs.
- **Platforms:** Android (native, shipped v1.0) + Web/PWA for iOS (v2.0) — no native iOS App Store app, no Apple Dev Account ($99/yr).
- **Budget:** ~€25 one-time (Google Play Developer account) + Firebase Hosting free tier for the web build. No ongoing infra costs (Open-Meteo free, Firebase free tier, Google Calendar API free, all client-side).
- **Timeline:** Realistic 8–12 weeks side-project pace. Acceptable to ship a thin v1 fast and iterate.
- **No backend:** Pure client-side. Drift for local storage (native); web build uses Drift's IndexedDB/wasm backend. Removes a whole tier of complexity (auth, hosting, GDPR) and lets each version ship fast.
- **Privacy:** Location permission is the only sensitive permission. Privacy policy required (Play Store mandate; also linked from the web app). Data never leaves device unless user opts into Calendar integration.
- **Performance:** App must show forecast + slots within 2s of cold start (after first run). Weather refresh runs in background via WorkManager on Android; on-foreground/on-load on web (no `workmanager` support there).

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter over React Native | Better Material 3 defaults, less dependency churn, hot reload DX matters for solo dev | Validated — v1.0 shipped, and enables direct Flutter Web reuse for v2.0 |
| Android-only in v1 | Avoid dual launch effort (~3 wk extra) until Android validates concept | Validated — v1.0 shipped to Play Store, iterating |
| No backend / local-only storage | Removes auth, hosting, GDPR; fastest to ship; lose cross-device sync (acceptable) | Validated — v1.0 shipped; v2.0 web build keeps per-browser local storage (no sync) |
| Free, no ads, no IAP | Side/portfolio project — validate core value before monetization | Validated — v1.0 shipped free |
| GPS + manual override for location | Best UX (auto in city, manual on travel); single-location-at-a-time is fine | Validated — v1.0 shipped; browser Geolocation API used on web |
| Defaults + tolerance sliders | Sweet spot between hardcoded (no personalisation) and full configurability (overkill); slider impact on scoring is testable | Validated — v1.0 shipped |
| Internal testing track first | Play Console internal has no review + unlimited invites; fast feedback loop with friends before production | Validated — v1.0 shipped, now on public/production track |
| Open-Meteo for weather data | Free, no API key, hourly forecasts, proven in earlier KNMI MCP work | Validated — v1.0 shipped |
| iOS via Flutter Web/PWA, not native | Avoids $99/yr Apple Dev Account; reuses Dart codebase; accepts Safari/PWA limitations (no background refresh, limited push) | ✓ Validated — v2.0 shipped 2026-07-17, live at my-project-joost.web.app |
| Google Calendar included in v2.0 web scope | `google_sign_in` supports web via Google Identity Services; meaningful differentiator over a bare MVP | ✓ Validated — v2.0 shipped, verified end-to-end on real iPhone Safari by two testers |
| Notifications deferred for v2.0 web | iOS Safari Web Push only works for installed PWAs (16.4+) and is unreliable; not worth building until PWA adoption is proven | ✓ Validated — shipped without notifications, revisit post-adoption-data |
| Firebase Hosting for web deployment | Free tier, already in CLAUDE.md tech stack, simple `firebase deploy` for Flutter web builds | ✓ Validated — v2.0 shipped, SPA rewrite + wasm headers curl-proven on live domain in Phase 17 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-07-17 — v2.0 (iOS Web App) milestone shipped*
