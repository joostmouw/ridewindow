# RideWindow

## What This Is

RideWindow is an Android app for casual cyclists who want to know — at a glance — the best windows to ride this week. It combines an accurate cycling-specific weather score (temperature, rain, wind) with the user's personal availability calendar to produce concrete, bookable time slots like "Saturday 09:00–13:00, 4h — Perfect".

## Core Value

**Accurate cyclist-specific weather scoring translated into concrete bookable time slots.** If the score is wrong, or the slot is unrideable in practice, the app fails — everything else is decoration.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

<!-- Current scope. Building toward these. -->

**Core scoring & slot generation**
- [ ] App fetches 7-day hourly weather forecast for user's location (Open-Meteo)
- [ ] App computes a cyclist-specific score (0–100) per hour using temperature, rain, and wind
- [ ] App identifies contiguous good-weather hours and produces ride slots of 2h, 3h, and 4–5h durations
- [ ] App filters slots against user's blocked hours (work + custom) so only available slots are shown
- [ ] App displays "Why this score?" insights with 3 progress bars (temp/rain/wind) and short explanations

**Onboarding & profile**
- [ ] First-run onboarding asks user to pick a free-time preset (Evenings & weekends / Mornings & weekends / Weekends only / Custom calendar)
- [ ] Profile screen lets user edit a weekly availability calendar (block/unblock individual hour cells)
- [ ] Profile screen lets user pick ride length preferences (2h, 3h, 4–5h chips)
- [ ] Profile screen exposes 3 weather-tolerance sliders (temperature, wind, rain) that affect scoring

**Location**
- [ ] App requests location permission on first run and uses GPS as the default forecast location
- [ ] User can override location manually with a city picker (fallback when GPS unavailable or for travel)

**Calendar integration**
- [ ] User can sign in to Google Calendar (optional, on-demand at "Add to calendar" tap)
- [ ] "Add to calendar" creates a Google Calendar event with the slot's start, end, and weather summary

**Notifications**
- [ ] User can toggle "Evening before" notification (great-ride heads-up the day before)
- [ ] User can toggle "Morning of" notification (window opens in 2h)
- [ ] User can toggle "Weekly digest" (Sunday evening summary)

**Local persistence**
- [ ] All user data (profile, availability, tolerances, settings) is stored locally on device
- [ ] Forecast results are cached locally and refreshed in the background

**Release**
- [ ] App is signed and packaged as a release AAB for Google Play Console internal testing track
- [ ] Privacy policy is published and linked in the Play Store listing

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- **iOS app** — Android-only in v1. Flutter codebase is iOS-ready for v2 once Android is validated.
- **User accounts / backend** — No login, no cross-device sync. All data lives locally. Removes auth complexity, privacy policy headaches, and backend cost for v1.
- **Monetization (IAP / ads)** — Free with no ads. v1 is a portfolio/hobby project to validate core value before considering revenue.
- **Multi-location / route planning** — One location at a time, no route/elevation integration. v2 differentiator.
- **Social features** — No groups, no shared rides, no leaderboards. v1 is a personal planning tool.
- **Apple Watch / Wear OS companion** — Phone-only. Smartwatch is v3+ territory.
- **Cycling-type specialization (road / gravel / MTB)** — One generic "ride" profile in v1; tolerances cover personalisation.
- **Historical weather analytics** — Forward-looking only, 7 days. No "best ride days last month" reporting.

## Context

**Solo dev, evenings & weekends.** Joost works Mon–Fri 09:00–17:00 at Fanalists. RideWindow is a side project to validate a real personal need (concrete ride slots that respect work hours).

**Mockup exists.** A complete interactive HTML mockup lives at `/Users/joostmouw/ridewindow/mockup.html` and covers all 6 screens (Welcome, Onboarding, Home, Ride Detail, Profile, Availability). It serves as the visual contract for the UI phase — `/gsd-ui-phase` should consume it directly.

**User profile is the persona.** The primary user persona is the developer himself: casual rider, 2–5h rides, weekday work hours, wants bookable slots, not vague advice. The mockup is built around this persona.

**Weather data is solved.** Open-Meteo provides free, no-key, hourly forecasts for arbitrary coordinates. Already validated via the KNMI MCP server work earlier in 2026.

**Scoring approach is defined.** Three weighted factors (temperature, rain, wind) each scored 0–100, combined into an overall ride score. Tolerances per factor are user-adjustable via sliders. Defaults: 12–26°C ideal, wind <15 km/h ideal, rain <0.5mm ideal.

**Release strategy is conservative.** Internal testing track with 10–20 cyclist friends first. Play Console internal track has no review and unlimited invites — fast iteration loop before going to closed beta and then production.

## Constraints

- **Tech stack:** Flutter (Dart) — chosen for cross-platform readiness (iOS in v2), Material 3 out-of-the-box, hot reload DX, lower dependency-maintenance burden than React Native for solo devs.
- **Platforms:** Android-only for v1 — focus on one store, one review process, no Apple Dev Account ($99/yr) until Android proves the concept.
- **Budget:** ~€25 one-time (Google Play Developer account). No ongoing infra costs (Open-Meteo free, Firebase free tier, Google Calendar API free, all client-side).
- **Timeline:** Realistic 8–12 weeks side-project pace. Acceptable to ship a thin v1 fast and iterate.
- **No backend:** Pure client-side. Hive or Isar for local storage. Removes a whole tier of complexity (auth, hosting, GDPR) and lets v1 ship fast.
- **Privacy:** Location permission is the only sensitive permission. Privacy policy required (Play Store mandate). Data never leaves device unless user opts into Calendar integration.
- **Performance:** App must show forecast + slots within 2s of cold start (after first run). Weather refresh runs in background via WorkManager.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter over React Native | Better Material 3 defaults, less dependency churn, hot reload DX matters for solo dev | — Pending |
| Android-only in v1 | Avoid dual launch effort (~3 wk extra) until Android validates concept | — Pending |
| No backend / local-only storage | Removes auth, hosting, GDPR; fastest to ship; lose cross-device sync (acceptable for v1) | — Pending |
| Free, no ads, no IAP | Side/portfolio project — validate core value before monetization | — Pending |
| GPS + manual override for location | Best UX (auto in city, manual on travel); single-location-at-a-time is fine for v1 | — Pending |
| Defaults + tolerance sliders | Sweet spot between hardcoded (no personalisation) and full configurability (overkill); slider impact on scoring is testable | — Pending |
| Internal testing track first | Play Console internal has no review + unlimited invites; fast feedback loop with friends before production | — Pending |
| Open-Meteo for weather data | Free, no API key, hourly forecasts, proven in earlier KNMI MCP work | — Pending |

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
*Last updated: 2026-06-01 after initialization*
