# Phase 04 — UI Phase A: Onboarding + Home + Welcome
## Context

**Goal:** Implement the three screens of UI Phase A — Welcome, Onboarding (4 presets), and Home (week strip + ride cards) — wired to the live Riverpod provider chain from Phase 3.

**Visual contract:** `mockup.html` at the repo root covers all six screens. All visual decisions for Phase 4 are derived from that mockup. Downstream agents: read `mockup.html` before writing any widget code.

**Canonical refs:**
- `mockup.html` — interactive HTML mockup, visual source of truth for all six screens
- `.planning/REQUIREMENTS.md` — ONB-01 through ONB-04, AVAIL-01 through AVAIL-04
- `.planning/phases/03-riverpod-providers-state-graph/03-03-SUMMARY.md` — AvailabilityNotifier contract
- `.planning/phases/03-riverpod-providers-state-graph/03-04-SUMMARY.md` — provider names, ProviderScope
- `CLAUDE.md` — stack decisions, go_router 17.2.3, flutter_riverpod 3.3.1, Material 3

---

## Decisions

### 1. Navigation gate

**Decision:** go_router redirect driven by a `'onboarding_complete'` flag in SharedPreferences.

- Router's `redirect` callback reads `'onboarding_complete'` on every navigation.
- `false` (or absent) → redirect to `/welcome`.
- `true` → proceed to `/home` (no redirect).
- After the user taps "Next →" on Onboarding: write `'onboarding_complete': true` to SharedPreferences, then `context.go('/home')`.
- No splash screen, no intermediate steps — direct to `/home`.

**Routes to create in Phase 4:**
- `/welcome`
- `/onboard`
- `/home`
- `/availability` (stub — empty Scaffold with AppBar "Mijn schema", no calendar grid yet)

**Note:** `/availability` stub is created now so that "Set my own schedule" can navigate to it. The full 7×24 grid is Phase 6.

---

### 2. Preset definitions & AvailabilityNotifier architecture

#### 2a. Three-state model — implement NOW in Phase 4

**Decision:** AvailabilityNotifier must be extended from `Set<DateTime>` to `Map<DateTime, BlockType>` with:

```dart
enum BlockType { work, custom }
```

- `work` — seeded by onboarding presets; represents "I have work/other fixed obligations"
- `custom` — user-toggled ad-hoc blocks (e.g., Tuesday evening football)
- Hours not in the map = free

**Why now, not Phase 6:** The user explicitly wants the distinction visible in Phase 6's calendar. If Phase 4 only stores a flat `Set<DateTime>`, Phase 6 would need a data migration. Build it right the first time.

**AvailabilityNotifier changes:**
- State: `Map<DateTime, BlockType>` (was `Set<DateTime>`)
- `toggleCustomHour(DateTime dt)` — toggles a `custom` block (was `toggleHour`)
- `seedPreset(Map<DateTime, BlockType> preset)` — called by onboarding to install work blocks
- `clearAll()` — remains, wipes the entire map
- Persist: serialize as `List<String>` with format `"ISO8601|work"` or `"ISO8601|custom"` under key `'availability.blockedHours'`

**Breaking change from Phase 3:** AvailabilityNotifier tests (03-03) used `Set<DateTime>`. Those tests need updating as part of this plan.

#### 2b. Preset free-hour definitions

Presets define WHICH HOURS ARE FREE. All other hours are stored as `BlockType.work`.

The 7-day week is modelled as "this week starting from Monday" (rolling 7-day window).

| Preset | Free hours |
|--------|-----------|
| Evenings & weekends | Ma–Vr 17:00–23:00 + Za/Zo 00:00–23:00 |
| Mornings & weekends | Ma–Vr 06:00–09:00 + Za/Zo 00:00–23:00 |
| Weekends only | Za/Zo 00:00–23:00 |
| Set my own schedule | No preset — navigate to `/availability` stub |

"Free hours" = NOT in the map. All hours outside the free set are inserted as `BlockType.work`.

**Preset helper:** Create `lib/providers/availability_presets.dart` with a function:
```dart
Map<DateTime, BlockType> buildPreset(AvailabilityPreset preset, DateTime weekStart)
```
This is pure Dart and unit-testable.

---

### 3. Location placeholder

**Decision:** Configureerbare default in `lib/core/config.dart`.

```dart
// lib/core/config.dart
const double kDefaultLat = 52.3676;  // Amsterdam
const double kDefaultLon = 4.9041;
const String kDefaultCity = 'Amsterdam';
```

Create a `LocationProvider` stub (Riverpod provider) that returns these constants. Phase 7 replaces this stub with real GPS.

The home header shows the city name from config: "Amsterdam · This week" (matches mockup).

---

### 4. Home loading state

**Decision:** Skeleton cards while forecast is loading (AsyncLoading).

- Week strip: 7 grey shimmer blocks
- Ride cards area: 3 skeleton card outlines with shimmer animation
- Use `shimmer` package OR implement a simple grey-box shimmer via AnimatedContainer — planner decides based on existing deps
- Error state: brief SnackBar + retry icon button in header

---

### 5. Week strip interaction

**Decision:** Tap a day → filter ride cards to that day's slots only. Tap same day again → deselect → show all week.

- State: `selectedDay: DateTime?` — local widget state (no Riverpod needed, purely UI)
- `selectedDay == null` → show all slots sorted by tier (best first)
- `selectedDay != null` → filter `SlotsLoaded.slots` to only slots where `slot.start.day == selectedDay.day`
- Day indicator dots: green checkmark (has Perfect/Great slot), `~` orange (only Acceptable), `✗` red (no slots / bad weather) — derived from `SlotsLoaded`

---

### 6. "Plan it" button scope in Phase 4

**Decision:** "Plan it" shows a SnackBar: "Google Calendar integratie komt in een volgende update." (Phase 9 feature). The button is visible and tappable but does not navigate or open a sheet.

---

## Deferred Ideas

*(Captured during discussion — not in Phase 4 scope)*

- Custom work-hours picker during onboarding (e.g., "I work 08:00–16:00") — noted for Phase 6 Availability calendar redesign
- Ability to set recurring custom blocks (e.g., "every Tuesday 19:00–21:00 football") — Phase 6+

---

## Phase 4 Boundaries

**In scope:**
- Welcome screen
- Onboarding screen (4 preset options + "Set my own schedule" → /availability stub)
- Home screen (week strip, ride cards, bottom nav)
- AvailabilityNotifier architecture upgrade (Set<DateTime> → Map<DateTime, BlockType>)
- LocationProvider stub with configurable defaults
- go_router setup with onboarding gate redirect
- /availability stub route (empty Scaffold)

**Out of scope (later phases):**
- Real GPS location (Phase 7)
- Full availability calendar grid (Phase 6)
- "Plan it" → Google Calendar (Phase 9)
- Ride Detail screen (Phase 5)
- Profile screen (Phase 6)
- Tolerance sliders (Phase 6)
