# RideWindow — v1 Requirements

**Scope:** Internal Play Console testing track (max 100 testers via opt-in link). No public production. All locked decisions from `.planning/PROJECT.md`.

**REQ-ID format:** `[CATEGORY]-[NUMBER]` — stable across phase transitions.

---

## v1 Requirements

### Forecast (FORE) — Weather data acquisition

- [x] **FORE-01**: App fetches 7-day hourly weather forecast from Open-Meteo for the user's location (lat/lon)
- [x] **FORE-02**: Forecast requests pass `timezone=auto&timeformat=unixtime` so timestamps are local-correct
- [x] **FORE-03**: Forecast response includes `temperature_2m`, `apparent_temperature`, `precipitation`, `precipitation_probability`, `windspeed_10m`, `winddirection_10m`
- [x] **FORE-04**: Forecast results are cached locally (Drift) with `fetched_at` timestamp; cache is reused within 1h, refetched after
- [x] **FORE-05**: All forecast fields are modeled as nullable; missing data is surfaced (not silently treated as 0) — *gap-fix*

### Scoring (SCOR) — Cyclist-specific weather score

- [ ] **SCOR-01**: `ScoringEngine.score()` returns a 0–100 overall score per hour, plus three sub-scores (temperature/rain/wind)
- [ ] **SCOR-02**: Scoring uses user-adjustable tolerances per factor (defaults: temp 12–26°C ideal, wind <15 km/h ideal, rain <0.5mm ideal)
- [ ] **SCOR-03**: Scoring engine is pure Dart with zero Flutter / zero I/O dependencies — fully unit testable via `dart test`
- [ ] **SCOR-04**: Scoring engine handles null inputs by clamping the affected sub-score to a defined "uncertain" value (50/100) instead of crashing or coercing to 0
- [ ] **SCOR-05**: Scoring engine has documented unit tests covering: ideal conditions (all 100), cold edge, hot edge, light/heavy rain boundary, calm/strong wind boundary, mixed nulls

### Slots (SLOT) — Bookable time slot generation

- [ ] **SLOT-01**: `SlotGenerator` produces ride slots of 2h, 3h, and 4–5h durations from contiguous good-score hour runs
- [ ] **SLOT-02**: Slot boundaries use exclusive end convention `[start, end)`; documented and unit-tested with property tests
- [ ] **SLOT-03**: `AvailabilityFilter` removes slots that overlap user's blocked hours (work + custom) before display
- [ ] **SLOT-04**: Slots are categorized into tiers: Perfect (≥85), Great (70–84), Acceptable (50–69), Poor (<50, hidden)
- [ ] **SLOT-05**: Slot generation surfaces an explicit empty state when no slots qualify (bad weather week or fully blocked) — *gap-fix*

### Profile (PROF) — User preferences

- [ ] **PROF-01**: User can adjust 3 weather tolerance sliders (temperature, rain, wind) in Profile screen
- [ ] **PROF-02**: User can toggle ride length preferences (2h / 3h / 4–5h chips) — at least one must be selected
- [ ] **PROF-03**: Tolerance and ride-length changes trigger automatic slot recomputation (reactive via Riverpod)
- [ ] **PROF-04**: User can pick a Material 3 light/dark theme preference (system default acceptable)

### Availability (AVAIL) — Weekly calendar

- [ ] **AVAIL-01**: User can view and edit a 7-day × 24-hour availability grid (each cell = 1 hour)
- [ ] **AVAIL-02**: Grid cells show 3 states: free (default after preset), blocked (user-toggled), work (system-blocked from onboarding preset)
- [ ] **AVAIL-03**: Availability changes persist immediately to local storage
- [ ] **AVAIL-04**: Availability changes trigger slot recomputation

### Onboarding (ONB) — First-run flow

- [ ] **ONB-01**: First-launch shows Welcome → Onboarding flow; subsequent launches skip to Home
- [ ] **ONB-02**: Onboarding presents 4 availability presets: "Evenings & weekends" / "Mornings & weekends" / "Weekends only" / "Set my own schedule" (opens calendar)
- [ ] **ONB-03**: Selecting a preset seeds the availability grid with sensible defaults
- [ ] **ONB-04**: Onboarding completion stores a flag in shared_preferences so it's not shown again

### Location (LOC) — GPS + manual override

- [ ] **LOC-01**: App requests location permission on first run via `geolocator` + `permission_handler`
- [ ] **LOC-02**: If GPS permission granted, use device GPS for forecast location
- [ ] **LOC-03**: User can override location manually with a city picker (curated short-list of NL cities for v1)
- [ ] **LOC-04**: If GPS permanently denied, automatically fall back to manual city picker with clear explanation — *gap-fix*
- [ ] **LOC-05**: Manual override persists in shared_preferences and takes precedence over GPS until cleared

### Notifications (NOTIF) — Heads-up alerts

- [ ] **NOTIF-01**: User can toggle "Evening before" notification (19:00 prior day, if next-day slot is Great or Perfect)
- [ ] **NOTIF-02**: User can toggle "Morning of" notification (slot start - 2h, if today's slot is Great or Perfect)
- [ ] **NOTIF-03**: User can toggle "Weekly digest" notification (Sunday 19:00, summary of week's best slots)
- [ ] **NOTIF-04**: App requests Android 13+ `POST_NOTIFICATIONS` permission via the standard runtime prompt
- [ ] **NOTIF-05**: App requests Android 12+ `SCHEDULE_EXACT_ALARM` permission via system settings deep-link, with fallback to inexact scheduling if denied
- [ ] **NOTIF-06**: Background refresh uses `workmanager` with 3–6h periodic interval and shows `lastRefreshed` timestamp in the UI

### Calendar (CAL) — Google Calendar integration

- [ ] **CAL-01**: User can tap "Add to calendar" on a slot to create a Google Calendar event
- [ ] **CAL-02**: Google Sign-In is initialized lazily (only when user taps "Add to calendar"), requesting `calendar.events` scope only
- [ ] **CAL-03**: Calendar event includes slot start, end, and a one-line weather summary as event description
- [ ] **CAL-04**: Auth uses `AutoRefreshingAuthClient` so token expiry is handled silently
- [ ] **CAL-05**: Calendar feature is fully optional — app is 100% functional without ever signing in

### Persistence (PERS) — Local storage

- [ ] **PERS-01**: User profile (tolerances, ride-length prefs, location override, notification toggles, theme) persists in `shared_preferences`
- [ ] **PERS-02**: Availability grid and forecast cache persist in Drift (SQLite)
- [x] **PERS-03**: Drift schema is versioned with explicit migrations for v1→v1.x upgrades
- [ ] **PERS-04**: No personal data leaves the device unless user explicitly signs into Google Calendar

### Release (REL) — Play Store internal track

- [ ] **REL-01**: App is built as a signed release AAB with Play App Signing enrolled
- [ ] **REL-02**: Upload keystore is backed up to password manager (Bitwarden/1Password) with passwords
- [ ] **REL-03**: Privacy policy is published to a stable URL (GitHub Pages) and linked from Play Console + in-app About screen
- [ ] **REL-04**: Data Safety form in Play Console declares: precise location collected for app functionality, Google account info ephemerally accessed via Calendar OAuth (if user enables)
- [ ] **REL-05**: Release AAB is sideloaded and manually tested on a physical Android device before upload
- [ ] **REL-06**: App is uploaded to Play Console Internal testing track with opt-in link for testers (max 100)

---

## Out of Scope (v1)

See `.planning/PROJECT.md` "Out of Scope" section for full list with reasoning. Summary:

- iOS app — v2 once Android validated
- User accounts / backend — local-only persistence
- Monetization (IAP / ads) — free
- Multi-location / route planning / GPS routes — single location at a time
- Social features (Strava sync, sharing) — not a tracker
- Apple Watch / Wear OS companion — phone only
- Cycling-type profiles (road/gravel/MTB) — tolerance sliders cover personalization
- Historical analytics — forward-looking only
- **Closed testing + public production track** — internal track only for v1 (per validated plan)

---

## Definition of Done (per Phase)

Generic acceptance criteria applied to every phase:
- All requirements mapped to the phase have passing tests (unit, widget, or integration as appropriate)
- No new pitfalls from PITFALLS.md introduced (cross-check before merge)
- `lib/` folder structure matches `.planning/research/ARCHITECTURE.md` proposal
- Phase-specific success criteria from `.planning/ROADMAP.md` are demonstrably met (run the app, click through the feature)

---

## Traceability

| REQ-ID | Phase | Plan(s) |
|--------|-------|---------|
| SCOR-01 | Phase 1 | TBD |
| SCOR-02 | Phase 1 | TBD |
| SCOR-03 | Phase 1 | TBD |
| SCOR-04 | Phase 1 | TBD |
| SCOR-05 | Phase 1 | TBD |
| SLOT-01 | Phase 1 | TBD |
| SLOT-02 | Phase 1 | TBD |
| SLOT-03 | Phase 1 | TBD |
| SLOT-04 | Phase 1 | TBD |
| FORE-01 | Phase 2 | TBD |
| FORE-02 | Phase 2 | TBD |
| FORE-03 | Phase 2 | TBD |
| FORE-04 | Phase 2 | TBD |
| FORE-05 | Phase 2 | TBD |
| PERS-02 | Phase 2 | TBD |
| PERS-03 | Phase 2 | 02-01 (schemaVersion=1 + MigrationStrategy) |
| PROF-03 | Phase 3 | TBD |
| AVAIL-04 | Phase 3 | TBD |
| SLOT-05 | Phase 3 | TBD |
| PERS-01 | Phase 3 | TBD |
| ONB-01 | Phase 4 | TBD |
| ONB-02 | Phase 4 | TBD |
| ONB-03 | Phase 4 | TBD |
| ONB-04 | Phase 4 | TBD |
| PROF-01 | Phase 6 | TBD |
| PROF-02 | Phase 6 | TBD |
| PROF-04 | Phase 6 | TBD |
| AVAIL-01 | Phase 6 | TBD |
| AVAIL-02 | Phase 6 | TBD |
| AVAIL-03 | Phase 6 | TBD |
| LOC-01 | Phase 7 | TBD |
| LOC-02 | Phase 7 | TBD |
| LOC-03 | Phase 7 | TBD |
| LOC-04 | Phase 7 | TBD |
| LOC-05 | Phase 7 | TBD |
| NOTIF-01 | Phase 8 | TBD |
| NOTIF-02 | Phase 8 | TBD |
| NOTIF-03 | Phase 8 | TBD |
| NOTIF-04 | Phase 8 | TBD |
| NOTIF-05 | Phase 8 | TBD |
| NOTIF-06 | Phase 8 | TBD |
| CAL-01 | Phase 9 | TBD |
| CAL-02 | Phase 9 | TBD |
| CAL-03 | Phase 9 | TBD |
| CAL-04 | Phase 9 | TBD |
| CAL-05 | Phase 9 | TBD |
| PERS-04 | Phase 9 | TBD |
| REL-01 | Phase 10 | TBD |
| REL-02 | Phase 10 | TBD |
| REL-03 | Phase 10 | TBD |
| REL-04 | Phase 10 | TBD |
| REL-05 | Phase 10 | TBD |
| REL-06 | Phase 10 | TBD |

---

*Defined: 2026-06-02 — internal track only, gap-fixes included, 10-phase structure approved.*
