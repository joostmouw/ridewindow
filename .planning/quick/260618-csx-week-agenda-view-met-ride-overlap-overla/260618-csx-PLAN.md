---
phase: quick
plan: 260618-csx
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/data/remote/open_meteo_client.dart
  - lib/features/agenda/week_agenda_screen.dart
  - lib/app/router.dart
  - lib/app/scaffold_with_nav.dart
autonomous: true
requirements: [QUICK-260618-CSX]
must_haves:
  truths:
    - "User can open a Week Agenda screen from the bottom navigation bar"
    - "Screen shows a 10-day scrollable time grid (columns = days, rows = hours 06-22)"
    - "Blocked hours are shaded in the grid matching the user's availability pattern"
    - "Ride slots appear as colored overlays on the grid where weather + availability align"
    - "User can scroll horizontally to see all 10 days"
  artifacts:
    - path: "lib/features/agenda/week_agenda_screen.dart"
      provides: "WeekAgendaScreen widget"
    - path: "lib/data/remote/open_meteo_client.dart"
      provides: "10-day forecast fetch (forecast_days=10)"
  key_links:
    - from: "WeekAgendaScreen"
      to: "slotsProvider"
      via: "ref.watch(slotsProvider)"
      pattern: "slotsProvider"
    - from: "WeekAgendaScreen"
      to: "availabilityProvider"
      via: "ref.watch(availabilityProvider)"
      pattern: "availabilityProvider"
    - from: "ScaffoldWithNav"
      to: "WeekAgendaScreen"
      via: "3rd NavigationDestination + StatefulShellBranch"
      pattern: "/agenda"
---

<objective>
Add a Week Agenda screen that shows 10 days of availability + ride slot overlays.

Purpose: Give the user a visual calendar view where blocked hours and ride windows are
overlaid on a time grid — so they can spot bookable windows at a glance across 10 days
without switching between the schedule editor and the ride card list.

Output:
- 10-day Open-Meteo fetch (extend forecast_days from 7 to 10)
- WeekAgendaScreen with a horizontally scrollable time grid (days as columns, hours 06-22
  as rows), blocked hours shaded in grey/blue, ride slots overlaid as tier-coloured blocks
- 3rd tab "Agenda" in the bottom NavigationBar routing to /agenda
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

Key types needed for this plan (extracted from codebase — no exploration needed):

```dart
// lib/domain/models/ride_slot.dart
class RideSlot {
  final DateTime start;   // inclusive
  final DateTime end;     // exclusive — [start, end) convention
  final double overallScore;
  final RideTier tier;
  final List<HourlyScore> hours;
}

// lib/domain/models/ride_tier.dart  (sealed classes)
sealed class RideTier {}
class Perfect extends RideTier {}
class Great    extends RideTier {}
class Acceptable extends RideTier {}
class Poor     extends RideTier {}

// lib/providers/slots_notifier.dart
sealed class SlotsState {}
final class SlotsLoaded extends SlotsState {
  final List<RideSlot> slots;   // non-Poor, non-blocked slots
  final SlotsEmptyReason? reason;
}

// lib/providers/availability_notifier.dart
enum BlockType { work, custom }
// Keys are UTC DateTime: DateTime.utc(year, month, day, hour)
// Pattern: current week only (Mon = weekday 1, Sun = weekday 7)
// Provider: availabilityProvider → AsyncValue<Map<DateTime, BlockType>>

// lib/app/router.dart — existing routes
// /welcome, /onboard, /home, /profile, /availability, /detail
// StatefulShellRoute has 2 branches: Home (/home) and Profile (/profile)

// lib/app/scaffold_with_nav.dart
// NavigationBar with 2 destinations: Home, Profiel
// Extend to 3: Home, Agenda, Profiel

// Tier colors (matches home_screen.dart conventions):
// Perfect  → Color(0xFF2E7D32)  (dark green)
// Great    → Color(0xFF66BB6A)  (light green)
// Acceptable → Color(0xFFFFA726) (amber)
// Poor     → Color(0xFFBDBDBD)  (grey — not shown in agenda either)
```
</context>

<tasks>

<task type="auto">
  <name>Task 1: Extend Open-Meteo fetch to 10 days</name>
  <files>lib/data/remote/open_meteo_client.dart</files>
  <action>
Add `'forecast_days': '10'` to the `queryParameters` map in `OpenMeteoClient.fetch()`.
Open-Meteo supports up to 16 forecast days; adding this parameter extends the returned
hourly data from the default 7 days to 10 days. No other changes to the client — parsing
is generic (List.generate over all returned hours) and works for any count.

After this change, `weatherProvider` will expose 240 hourly entries (10 × 24) instead of
168 (7 × 24). `SlotsNotifier` recomputes automatically because it watches `weatherProvider`
reactively — no changes needed in slots_notifier.dart or slot_generator.dart.

Do NOT add `'forecast_days'` as a class constant. Add it inline in the queryParameters map
alongside the existing keys for clarity.
  </action>
  <verify>
    <automated>grep -n "forecast_days" /Users/joostmouw/ridewindow/lib/data/remote/open_meteo_client.dart</automated>
  </verify>
  <done>open_meteo_client.dart contains `'forecast_days': '10'` in the queryParameters map</done>
</task>

<task type="auto">
  <name>Task 2: Build WeekAgendaScreen with time grid and ride slot overlay</name>
  <files>lib/features/agenda/week_agenda_screen.dart</files>
  <action>
Create `lib/features/agenda/week_agenda_screen.dart` as a `ConsumerStatefulWidget`.

**Layout structure:**
```
Scaffold
  appBar: AppBar(title: "Agenda")
  body: Column
    ├── _buildDayHeaderRow()   // sticky day labels + date numbers (10 columns)
    └── Expanded
          └── SingleChildScrollView (vertical, for hour rows)
                └── Row
                      ├── _buildHourLabelColumn()   // fixed-width column with 06–22 labels
                      └── Expanded
                            └── SingleChildScrollView (horizontal)
                                  └── _buildGridBody()
```

**Grid dimensions:**
- Time range: hours 06 to 22 inclusive → 17 rows
- Column count: 10 days starting from today (DateTime.now(), not week start)
- Cell width: 56.0 logical pixels per day column
- Cell height: 52.0 logical pixels per hour row
- Hour label column width: 44.0 logical pixels

**Day header row** (`_buildDayHeaderRow`):
- Fixed height 52px
- Left offset: 44px (matches hour label column width)
- 10 columns of width 56px each
- Each column shows: abbreviated weekday (Mo/Tu/We/Th/Fr/Sa/Su) + day number, 2 lines
- Today's column has text color `Color(0xFF2E7D32)` (green); others use `Color(0xFF666666)`
- Wrap the entire header row and grid body in a shared `SingleChildScrollView(scrollDirection: Axis.horizontal)` so they scroll together. Use a `Column` inside the horizontal scroll view containing [header row, grid body].

**Correct scroll architecture** (header and grid scroll together horizontally):
```
Row(
  children: [
    // Fixed left column (hour labels + corner)
    Column(
      children: [
        SizedBox(width: 44, height: 52),  // corner
        for hour in 06..22: _HourLabel(hour),
      ],
    ),
    // Scrolling area: BOTH header AND grid cells move together
    Expanded(
      child: SingleChildScrollView(   // horizontal
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            _buildDayHeaderRow(),     // 10 day-label cells
            SingleChildScrollView(    // vertical  (or use outer vertical scroll)
              child: _buildCellGrid(),
            ),
          ],
        ),
      ),
    ),
  ],
)
```
Simpler approach: put everything in one `SingleChildScrollView(vertical)` wrapping a `Row`:
- Left side: Column of hour labels (non-scrolling horizontally, scrolls with vertical scroll)
- Right side: `SingleChildScrollView(horizontal)` > Column > [day header row, cell grid rows]

Use this simpler approach: outer `SingleChildScrollView` is vertical, inner `SingleChildScrollView` inside the right side is horizontal. This is the same pattern used by the existing `AvailabilityScreen`.

**Cell rendering** (`_buildGridCell(DateTime day, int hour, Map<DateTime, BlockType> blockedHours, List<RideSlot> slots)`):
- Compute `cellDt = DateTime.utc(day.year, day.month, day.day, hour)` — this is the UTC key matching AvailabilityNotifier's storage format.
- Check blocked: `isBlocked = blockedHours.containsKey(cellDt)`
- Check slot overlap: scan all slots where `slot.start <= cellDt < slot.end`:
  ```dart
  final cellStart = cellDt;
  final cellEnd = cellDt.add(const Duration(hours: 1));
  final overlappingSlot = slots.firstWhereOrNull(
    (s) => s.start.isBefore(cellEnd) && s.end.isAfter(cellStart),
  );
  ```
  Note: `firstWhereOrNull` is from `package:collection` — check pubspec. If collection is not available, use a for-loop with a result variable.
- Cell background color priority:
  1. If `overlappingSlot != null`: tier color (semi-transparent: `withOpacity(0.85)`)
     - Perfect   → `Color(0xFF2E7D32).withOpacity(0.85)`
     - Great     → `Color(0xFF66BB6A).withOpacity(0.85)`
     - Acceptable → `Color(0xFFFFA726).withOpacity(0.85)`
  2. Else if `isBlocked`: `Color(0xFFE0E0E0)` (light grey)
  3. Else (free): `Colors.white`
- Cell border: `Border.all(color: Color(0xFFF0F0F0), width: 0.5)`
- Cell size: `SizedBox(width: 56, height: 52)`

**Availability projection for days beyond current week:**
The `availabilityProvider` stores keys only for the current week (Mon–Sun).
For any target day (including days 8–10 which may fall in the next week), compute
the equivalent blocked hours by weekday:

```dart
Set<int> _blockedHoursForDay(DateTime targetDay, Map<DateTime, BlockType> blockedHours) {
  // Find the Monday of the current week stored in blockedHours
  final now = DateTime.now();
  final weekStart = DateTime.utc(
    now.year, now.month, now.day - (now.weekday - 1),
  );
  // The equivalent stored day for targetDay's weekday
  final equivalentDay = weekStart.add(
    Duration(days: targetDay.weekday - 1),
  );
  // Collect all hours blocked for that equivalent day
  return blockedHours.entries
    .where((e) =>
      e.key.year == equivalentDay.year &&
      e.key.month == equivalentDay.month &&
      e.key.day == equivalentDay.day)
    .map((e) => e.key.hour)
    .toSet();
}
```

Then when checking `isBlocked`, use:
```dart
final blockedHoursForThisDay = _blockedHoursForDay(day, blockedHours);
final isBlocked = blockedHoursForThisDay.contains(hour);
```

**State and providers:**
- `ref.watch(slotsProvider)`: use `SlotsLoaded.slots` when available, else `[]`
- `ref.watch(availabilityProvider)`: use `.value ?? {}` for the map
- No loading state needed beyond showing an empty grid — slots arrive quickly

**Legend** (bottom of screen, outside scroll area, fixed height 48px):
```
Row: [■ Free] [■ Blocked] [■ Ride window]
```
- Free: white box with grey border
- Blocked: `Color(0xFFE0E0E0)` box
- Ride window: `Color(0xFF2E7D32)` box (green)
- Font size 11, spacing via `SizedBox(width: 16)` between items

**Do NOT use `withOpacity` on `Color` — use `Color.fromARGB` or `Color.withValues(alpha: ...)` if opacity is needed** (Flutter 3.x lint). Use solid colors instead: Perfect = `Color(0xFF2E7D32)`, Great = `Color(0xFF81C784)`, Acceptable = `Color(0xFFFFB74D)`.

**Import `package:collection/collection.dart` only if it is already in pubspec.yaml.** Check `pubspec.yaml` first with a grep. If not present, implement `firstWhereOrNull` as a for-loop. Do not add new dependencies.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter analyze lib/features/agenda/week_agenda_screen.dart 2>&1 | tail -20</automated>
  </verify>
  <done>
WeekAgendaScreen file exists, `flutter analyze` reports zero errors for the file.
Grid renders days 0–9 from today, hours 06–22, with blocked/free/slot cell coloring.
  </done>
</task>

<task type="auto">
  <name>Task 3: Wire route and add Agenda tab to NavigationBar</name>
  <files>lib/app/router.dart, lib/app/scaffold_with_nav.dart</files>
  <action>
**scaffold_with_nav.dart:**
Add a 3rd `NavigationDestination` for the Agenda tab between Home and Profiel:
```dart
NavigationDestination(
  icon: Icon(Icons.calendar_view_week_outlined),
  selectedIcon: Icon(Icons.calendar_view_week),
  label: 'Agenda',
),
```
The `navigationShell.goBranch(i, ...)` call is already generic — no change needed there.

**router.dart:**
1. Add import: `import 'package:ridewindow/features/agenda/week_agenda_screen.dart';`
2. Add a 3rd `StatefulShellBranch` to the existing `StatefulShellRoute.indexedStack` branches list, between the Home branch and the Profile branch:
```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/agenda',
      pageBuilder: (context, state) =>
          _fadeTransition(state, const WeekAgendaScreen()),
    ),
  ],
),
```
Branch order in `branches` list must match `NavigationDestination` order in `scaffold_with_nav.dart`:
- Index 0: Home (/home)
- Index 1: Agenda (/agenda)   ← insert here
- Index 2: Profile (/profile)

Also add '/agenda' to the redirect guard in `router.dart` so it doesn't redirect to /welcome when onboarding is complete. The current guard already passes through authenticated users — no change needed for `/agenda` since authenticated users have `done == true` and the redirect returns `null`.

After adding the branch, run `dart run build_runner build --delete-conflicting-outputs` to regenerate `router.g.dart`.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -10 && flutter analyze lib/app/router.dart lib/app/scaffold_with_nav.dart 2>&1 | tail -10</automated>
  </verify>
  <done>
`flutter analyze` reports zero errors on router.dart and scaffold_with_nav.dart.
NavigationBar has 3 destinations (Home, Agenda, Profiel).
Tapping Agenda navigates to WeekAgendaScreen with the 10-day time grid.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Open-Meteo API → app | Extended to 10 days; response parsing is already generic |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-csx-01 | Information Disclosure | WeekAgendaScreen reads blockedHours | accept | Data stays on-device; no network exposure; same data already shown in AvailabilityScreen |
| T-csx-02 | Denial of Service | 10-day forecast = 240 hourly rows × 10 columns = 2400 cell widgets | mitigate | Render only hours 06–22 (17 rows × 10 cols = 170 cells) — well within Flutter's widget budget |
</threat_model>

<verification>
1. `flutter analyze lib/features/agenda/week_agenda_screen.dart` → zero errors
2. `flutter analyze lib/app/router.dart lib/app/scaffold_with_nav.dart` → zero errors
3. `grep -n "forecast_days" lib/data/remote/open_meteo_client.dart` → shows `'forecast_days': '10'`
4. `grep -c "NavigationDestination" lib/app/scaffold_with_nav.dart` → 3
5. Hot reload on device: 3-tab NavigationBar appears; Agenda tab opens grid; scrolling works horizontally across 10 days
</verification>

<success_criteria>
- Open-Meteo client requests 10 forecast days
- WeekAgendaScreen renders a time grid: columns = 10 days from today, rows = hours 06–22
- Blocked hours show as grey cells, ride slots show as green/amber overlay cells
- Availability projection handles days 8–10 (next week) via weekday mapping
- 3rd "Agenda" tab in NavigationBar navigates to WeekAgendaScreen
- Zero analyzer errors on new/modified files
</success_criteria>

<output>
Create `.planning/quick/260618-csx-week-agenda-view-met-ride-overlap-overla/260618-csx-SUMMARY.md` when done.
</output>
