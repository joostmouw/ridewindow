# Feature Research

**Domain:** Cyclist weather-window / ride-planning app (Android)
**Researched:** 2026-06-01
**Confidence:** HIGH (6 competitor apps analyzed via official sources + review sites; confirmed by cross-referencing multiple sources)

---

## Competitor App Survey

Before categorizing features, here is what each analyzed app actually does — and what it doesn't.

| App | Core Focus | Scheduling / Time-slot feature? | Score / Rating? | Calendar integration? |
|-----|------------|--------------------------------|-----------------|----------------------|
| **MyWindsock** | Route + segment wind analysis, performance metrics (wWatts, Wind Adjusted Time) | No — shows 7-day per-route forecast, user picks start time manually | Segment difficulty score | No |
| **Epic Ride Weather** | Minute-by-minute route-specific weather along a GPS route | Shows best start time for a given route, but requires user to have a route first | No overall ride score | No |
| **Headwind** | Wind difficulty rating per Strava route, 7-day forecast per starred route | Shows difficulty forecast per day for saved routes; no availability filter | Difficulty score (not weather comfort) | No |
| **Komoot (Premium)** | Route planning + on-tour weather overlay | Weather shown per route, no slot recommendations | No | No |
| **Windy.app (cycling profile)** | General weather map with cycling-tuned feels-like temp, 10-day forecast | No scheduling | No cycling comfort score | No |
| **cyclingweather.app** | Comfort diagram (Weacodi), 7-day hourly comfort level visualization | No scheduling, no availability filter | Comfort level (visual, not numeric) | No |
| **Epic Ride Weather (detail)** | Route-timed weather (Strava, Komoot, RWGPS, Garmin integration) | Start-time picker for a route — closest to a time slot, but needs a route | No | No |
| **AccuWeather / BBC / Met Office** | Generic weather apps with standard hourly forecasts | No cycling-specific scheduling | No | No |

**Critical gap confirmed across all competitors:** None of the analyzed apps combine (a) a cyclist-specific weather score with (b) the user's personal availability calendar to output (c) ready-made bookable time slots. This is the white space RideWindow occupies.

---

## Table Stakes (Users Expect These — Missing = Uninstall)

Features users assume exist in any weather-for-cyclists app. These are not differentiators; failing to deliver them means the app feels broken.

| Feature | Why Expected | Complexity | In Mockup? | Notes |
|---------|--------------|------------|------------|-------|
| 7-day hourly weather forecast for current location | Every weather app has this; GPS-auto location is assumed | S | Yes (Home screen, week strip) | Open-Meteo covers this; no key needed |
| Cyclist-relevant weather parameters: temperature, rain, wind | Generic weather apps show humidity and pressure; cyclists care about temp/rain/wind specifically | S | Yes (card chips + detail screen) | All three are in the scoring model |
| "Feels like" temperature (wind chill / heat index) | Cyclists experience perceived temperature, not air temp; MyWindsock, Windy.app, cyclingweather.app all offer this | S | Not explicitly shown — gap | Detectable via Open-Meteo `apparent_temperature`; should appear on detail screen |
| Hourly breakdown within a ride window | Epic Ride Weather, MyWindsock, Headwind all show per-hour data inside a slot | S | Yes (Ride Detail "Hourly" card) | Already in mockup |
| Color-coded weather quality at a glance | Week-level quality indicator (green/amber/red) is table stakes in every cycling app | S | Yes (week strip dots + card border colors) | Already in mockup |
| Transparent score explanation ("why is this good?") | Users distrust black-box scores; Headwind shows difficulty components, MyWindsock shows factor breakdown | M | Yes (insights sheet with 3 progress bars + i button) | Core differentiator implemented as table stakes — good |
| Location permission + GPS auto-detection | Assumed in any location-aware app | S | Yes (PROJECT.md) | Needs graceful degradation when GPS denied |
| Manual location override (city search) | Travel use case; GPS not always desired | S | Yes (Profile location row → picker) | Mentioned in PROJECT.md; not detailed in mockup |
| Local data persistence (settings survive app restart) | Users expect their preferences to be saved | S | Yes (PROJECT.md — Hive/Isar) | No backend required |
| Basic notifications (opt-in) | Heads-up before a good window; all calendar/planning apps offer this | M | Yes (Profile notifications section, 3 types) | Android WorkManager; needs exact timing logic |
| Onboarding that sets expectations | Users need to understand what the app does and set initial availability | S | Yes (Onboarding screen, 4 preset options) | Already in mockup |

---

## Differentiators (RideWindow's Competitive Edge)

Features that are NOT present in competitors (or are present in weak form), and which directly serve RideWindow's core value.

| Feature | Value Proposition | Complexity | In Mockup? | Notes |
|---------|-------------------|------------|------------|-------|
| **Availability-aware slot generation** — cross-referencing hourly weather score with user's blocked hours to produce only realistically rideable windows | The single biggest gap across all competitors. Epic Ride Weather picks the best start time for a given route, but requires a pre-existing route and no calendar awareness. RideWindow skips the route and outputs the window directly. | M | Yes (slot cards filtered against availability) | This IS the core differentiator — protect this |
| **Concrete, bookable time slots with duration labels** — "Saturday 09:00–13:00, 4h — Perfect" rather than a raw hourly chart | Cyclists want a decision, not more data. All competitor apps require the user to read a chart and make their own inference. | M | Yes (ride cards with time + duration + badge) | Unique UX pattern in this space |
| **Weekly availability calendar (work-hour blocking)** — user defines their weekly free-time template once, app filters slots automatically | No competitor does this. Headwind shows 7-day per-route data but the user still has to mentally check against their schedule. | M | Yes (Availability screen, hour-cell grid) | The friction-removal feature |
| **Pre-set availability patterns for onboarding** — "Evenings & weekends", "Mornings & weekends", etc., reducing setup to one tap | Competitors either skip onboarding or show a data-entry form. This lowers the barrier to first useful output. | S | Yes (Onboarding screen, 4 options) | Smart defaults accelerate time-to-value |
| **Weather tolerance sliders per factor** — user controls how temperature, rain, and wind affect their personal score | MyWindsock has CdA and performance tuning (for racers). No competitor has casual-rider tolerance sliders. | M | Referenced in mockup (Profile "Weather sensitivity" row) | Differentiates from one-size-fits-all scores |
| **Ride-length preference filter** — 2h / 3h / 4–5h chips filter which slot durations are surfaced | No competitor allows filtering by desired ride duration as a preference. | S | Yes (Profile "Ride length" chips) | Low complexity, high perceived value |
| **Google Calendar export with weather summary** — "Add to calendar" creates an event with start/end + weather detail | Generic "add to calendar" exists in planning apps; the weather-annotated description is novel | M | Yes (Plan overlay sheet, "Add to Google Calendar" button) | OAuth Google Sign-In adds complexity; optional on-demand |
| **"After work" context labels** — slots show "Thursday after work" to immediately orient the user in their week | All competitors show timestamps only; none add user-context labels | S | Yes (card subtitle "after work") | Simple but highly resonant with the target persona |

---

## Anti-Features (Explicitly NOT for v1 — With Reasoning)

Features that seem logical to add but would harm v1 by adding complexity without validating the core value. Some are already documented in PROJECT.md's Out of Scope section; this section adds the feature-level reasoning.

| Anti-Feature | Why Users Request It | Why to Avoid in v1 | What to Do Instead |
|--------------|---------------------|--------------------|--------------------|
| **Route planning / GPX upload** | Epic Ride Weather, MyWindsock, Komoot do it; feels like the "next level" | Requires map SDK, GPX parsing, route-timed weather (one weather call per segment, not one per location). Adds 4–6 weeks. Core value doesn't require a route — it requires a window. | Show the window; let the user plan the route in Komoot once they know when to ride |
| **Social / sharing / Strava sync** | Strava is where cyclists live; feels natural | Auth complexity, API rate limits, no unique value without recording. Headwind + myWindsock already fill this role. | v1 is a planning tool, not an activity tracker |
| **Historical ride analytics** | "Best month to ride", "average score last quarter" | Requires persistent ride history store; grows in complexity fast. No user feedback yet on whether this is wanted. | Forward-looking only; validate that first |
| **Multi-location / saved locations** | Travel use case ("what's it like in Mallorca next week?") | Complicates UI; all competitors with multi-location add significant UX overhead. GPS + manual override covers 90% of the persona's needs. | Manual city override is sufficient for v1 |
| **Cycling-type specialization (road / MTB / gravel profiles)** | Users assume their bike type affects weather relevance | Requires multiple scoring models or factor weights per type. Tolerance sliders already cover personalisation without adding profiles. | Sliders serve the same purpose without mode-switching complexity |
| **Wear OS companion app** | "A quick glance before I walk out the door" | Android watch support requires separate UI target, Wear OS testing environment. No validation that users want this yet. | Notification is the lightweight equivalent |
| **Radar map / live weather visualization** | Windy, AccuWeather, NOAA Weather Radar all have this | Weather maps are a commodity; adding one doesn't differentiate RideWindow. High engineering cost for commodity output. | Deep-link to Windy or Buienradar for radar if needed |
| **Clothing recommendations** | cyclingweather.app has this; feels helpful | Requires curating a clothing logic ruleset; subjective (one person's arm warmers are another's base layer). Risk of being wrong and undermining trust. | The temperature + "feels like" data is sufficient for users to decide |
| **In-app route navigation / turn-by-turn** | "One app for everything" | Komoot, Google Maps, Wahoo solve this well. Navigation is a distinct product. | Show a "Start in Komoot" or "Open in Maps" deep-link on the Ride Detail screen |
| **User accounts / cloud sync** | "I want my settings on my new phone" | Backend, auth, GDPR, cost — all removed for v1. No data to lose yet (the persona is a single device user). | Export settings as a file (v1.x) if user need surfaces |
| **Ads or IAP prompts** | Monetization is legitimate | Adds complexity, damages first-impression trust, distracts from core value validation. Wrong phase. | Free, no ads, no IAP for v1 |

---

## Feature Dependencies

```
GPS location permission
    └──required by──> Weather forecast fetch (Open-Meteo)
                         └──required by──> Hourly weather score computation
                                              └──required by──> Slot generation
                                                                   └──required by──> Home screen ride cards
                                                                   └──required by──> Week strip day quality dots

Onboarding (availability preset)
    └──seeds──> Weekly availability calendar
                   └──required by──> Slot generation (filter)
                   └──displayed in──> Availability screen (editable)

Weather tolerance sliders
    └──modifies──> Hourly weather score computation
                      └──required by──> Slot generation

Ride length preference (2h / 3h / 4-5h chips)
    └──filters──> Slot generation output

Slot generation
    └──required by──> Ride card on Home screen
    └──required by──> Insights sheet (score breakdown)
    └──required by──> Ride Detail screen

Google Sign-In (optional, on-demand)
    └──required by──> Google Calendar export ("Add to calendar")

Notifications (WorkManager)
    └──depends on──> Slot generation (to know which slot to notify about)
    └──depends on──> Android permission (POST_NOTIFICATIONS, Android 13+)
```

### Dependency Notes

- **Slot generation is the core dependency** — almost everything in the app is downstream of it. It must be built and correct before Home screen, Detail screen, or notifications can be validated.
- **Availability calendar seeds slot generation** — onboarding must write a valid availability state before slot generation runs. The default preset must produce a usable state even if the user skips customization.
- **Google Sign-In is fully optional** — the "Add to calendar" flow is a tap-triggered enhancement; the app is fully functional without it. This decouples calendar work from core validation.
- **Tolerance sliders modify scoring** — they are an enhancement to score computation, not a blocker. Default values must exist so the app works before the user touches sliders.

---

## MVP Definition

### Launch With (v1) — All in Mockup

- [x] GPS location + manual city override
- [x] Open-Meteo 7-day hourly forecast fetch
- [x] Cycling score per hour (temp/rain/wind, weighted, tolerance-adjusted)
- [x] Slot generation filtered by availability and ride-length preference
- [x] Onboarding with 4 availability presets
- [x] Availability calendar (weekly hour-cell grid, tap to toggle)
- [x] Home screen: week strip + ride cards (Perfect/Great/Acceptable tiers)
- [x] Ride Detail: hourly breakdown, score banner, weather rows
- [x] Insights sheet: 3 progress bars + text explanations per slot
- [x] Profile: location, availability, ride length, notifications, weather sensitivity, Google Calendar
- [x] Notifications: evening before, morning of, weekly digest
- [x] Google Calendar export (optional, on-demand OAuth)
- [x] Local persistence (Hive/Isar — settings, availability, cached forecast)

**Gaps vs. mockup — items to add before first build:**
- [ ] "Feels like" temperature on Ride Detail screen (Open-Meteo `apparent_temperature` field — not shown in current mockup but table stakes)
- [ ] Location permission denied state / fallback to manual city (mockup shows happy path only)
- [ ] Empty state when no slots qualify (e.g., all week is bad weather or fully blocked) — mockup has no such state

### Add After Validation (v1.x)

- [ ] Wind direction indicator on ride cards ("tailwind/headwind on return") — depends on user feedback that direction matters to them
- [ ] "Feels like" / apparent temperature visible on home card chips (currently only shown in detail)
- [ ] Settings export/import file (poor man's backup if no backend)
- [ ] Widget (Android home screen) — shows next ride slot at a glance

### Future Consideration (v2+)

- [ ] Route planning / GPX + weather overlay (Epic Ride Weather territory, but RideWindow can add it once slot planning is validated)
- [ ] Multi-location saved spots (travel use case)
- [ ] Cycling-type profiles (road / gravel / MTB weight presets)
- [ ] iOS port (Flutter codebase is ready; add once Android validates concept)
- [ ] Wear OS tile

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Slot generation (weather score × availability) | HIGH | MEDIUM | P1 |
| Onboarding with presets | HIGH | LOW | P1 |
| Home screen ride cards | HIGH | LOW | P1 |
| Open-Meteo weather fetch + scoring | HIGH | MEDIUM | P1 |
| Ride Detail screen + hourly rows | HIGH | LOW | P1 |
| Insights sheet (i button) | MEDIUM | LOW | P1 |
| Availability calendar grid | MEDIUM | MEDIUM | P1 |
| Tolerance sliders | MEDIUM | LOW | P1 |
| Ride-length preference chips | MEDIUM | LOW | P1 |
| Notifications (WorkManager) | MEDIUM | MEDIUM | P1 |
| Feels-like temperature | MEDIUM | LOW | P1 (gap to close) |
| Google Calendar export | MEDIUM | MEDIUM | P1 |
| Empty / error states | HIGH | LOW | P1 (gap to close) |
| Wind direction label on cards | LOW | LOW | P2 |
| Android home screen widget | MEDIUM | MEDIUM | P2 |
| Route planning / GPX | LOW (v1) | HIGH | P3 |
| Multi-location | LOW (v1) | MEDIUM | P3 |

---

## Competitor Feature Matrix

| Feature | MyWindsock | Epic Ride Weather | Headwind | Komoot Premium | Windy.app | cyclingweather.app | RideWindow (planned) |
|---------|------------|-------------------|----------|----------------|-----------|-------------------|----------------------|
| Cycling-specific weather score | Yes (complex) | No | Difficulty score | No | Feels-like temp only | Comfort level | Yes — 3-factor 0–100 |
| Score explanation ("why?") | Partial | No | No | No | No | No | Yes — 3 progress bars + text |
| Ride slot recommendations | No | Nearest hour for a route | No | No | No | No | Yes — full slot with start/end/duration |
| Availability calendar filter | No | No | No | No | No | No | Yes — weekly hour-cell grid |
| Pre-set availability patterns | No | No | No | No | No | No | Yes — 4 one-tap presets |
| Ride-length preference | No | No | No | No | No | No | Yes — 2h / 3h / 4–5h chips |
| Tolerance / preference sliders | No (fixed algo) | No | No | No | No | No | Yes — 3 sliders |
| Google Calendar export | No | No | No | No | No | No | Yes — optional on-demand |
| Hourly breakdown in window | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Push notifications | No | No | No | No | No | No | Yes — 3 types |
| Route / GPX required | Yes | Yes | Yes | Yes | No | No | No — location only |
| Free (no route needed) | Freemium | Freemium | Free | Premium | Freemium | Yes | Yes (v1) |
| Android | Yes | Yes | Yes | Yes | Yes | iOS only | Yes |

---

## Sources

- [MyWindsock app review — ProCyclingUK](https://procyclinguk.com/reviewing-the-mywindsock-app/)
- [MyWindsock premium features](https://mywindsock.com/my/premium/)
- [Epic Ride Weather — official site](https://www.epicrideweather.com/)
- [Epic Ride Weather — Google Play](https://play.google.com/store/apps/details?id=com.greensopinion.rideweather&hl=en_US)
- [Headwind app — official site](https://headwindapp.com/)
- [Komoot Premium weather features](https://www.komoot.com/premium/weather)
- [Windy.app cycling guide](https://windy.app/guide/mini-user-guide-cycling.html)
- [cyclingweather.app — official site](https://cyclingweather.app/)
- [TreadBikely — 7 top cycling weather apps](https://www.treadbikely.com/7-top-cycling-weather-apps-to-help-keep-you-dry-warm-safe/)
- [BikeRadar — best cycling apps 2026](https://www.bikeradar.com/advice/buyers-guides/best-cycling-apps)
- [CyclingWeekly — best cycling apps 2026](https://www.cyclingweekly.com/group-tests/best-cycling-apps-143222)
- [Clime blog — hourly forecasts for cyclists](https://climeradar.com/blog/best-apps-hourly-weather-forecasts-cyclists-1)

---

*Feature research for: Cyclist weather-window / ride-planning app (RideWindow)*
*Researched: 2026-06-01*
