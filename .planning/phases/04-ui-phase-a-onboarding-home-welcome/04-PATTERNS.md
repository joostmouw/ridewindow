# Phase 04: UI Phase A: Onboarding + Home + Welcome — Pattern Map

**Mapped:** 2026-06-03
**Files analyzed:** 9 new/modified files
**Analogs found:** 8 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/core/config.dart` | config | — | `lib/providers/app_database_provider.dart` | partial (constants pattern) |
| `lib/providers/location_provider.dart` | provider | request-response | `lib/providers/app_database_provider.dart` | role-match |
| `lib/providers/availability_notifier.dart` | provider (MODIFY) | CRUD | itself (lines 1–50) | exact |
| `lib/providers/availability_presets.dart` | utility | transform | `lib/domain/services/scoring_engine.dart` | role-match |
| `lib/app/router.dart` | config | request-response | `lib/main.dart` (MaterialApp wiring) | partial |
| `lib/features/welcome/welcome_screen.dart` | component | request-response | `lib/main.dart` (StatelessWidget pattern) | role-match |
| `lib/features/onboarding/onboarding_screen.dart` | component | request-response | `lib/main.dart` + `profile_notifier.dart` | role-match |
| `lib/features/home/home_screen.dart` | component | request-response | `lib/providers/slots_notifier.dart` (SlotsState consumption) | partial |
| `lib/features/availability/availability_screen.dart` | component | — | `lib/main.dart` (Scaffold stub) | role-match |

---

## Pattern Assignments

### `lib/core/config.dart` (config)

**Analog:** `lib/providers/app_database_provider.dart` (top-level constants pattern)

No analog in codebase uses `const` top-level values, but the project package name pattern is clear from every import.

**Package name pattern** (from every provider file, line 1):
```dart
// Package import convention used throughout the project:
import 'package:ridewindow/...';
```

**Config file structure to use:**
```dart
// lib/core/config.dart
// No part directive needed — pure constants, no code generation.
const double kDefaultLat = 52.3676;  // Amsterdam
const double kDefaultLon = 4.9041;
const String kDefaultCity = 'Amsterdam';
```

---

### `lib/providers/location_provider.dart` (provider, request-response)

**Analog:** `lib/providers/app_database_provider.dart`

**Imports pattern** (lines 1–7):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/data/remote/open_meteo_client.dart';
// ...

part 'app_database_provider.g.dart';
```

**Functional provider pattern** (lines 18–21 of app_database_provider.dart):
```dart
@riverpod
OpenMeteoClient openMeteoClient(Ref ref) {
  return OpenMeteoClient();
}
```

**Apply for LocationProvider stub** — use same functional `@riverpod` pattern returning a simple data class:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ridewindow/core/config.dart';

part 'location_provider.g.dart';

class LocationData {
  const LocationData({
    required this.lat,
    required this.lon,
    required this.city,
  });
  final double lat;
  final double lon;
  final String city;
}

@riverpod
LocationData location(Ref ref) {
  // Phase 7 replaces this stub with real geolocator call.
  return const LocationData(
    lat: kDefaultLat,
    lon: kDefaultLon,
    city: kDefaultCity,
  );
}
```

---

### `lib/providers/availability_notifier.dart` (MODIFY — provider, CRUD)

**Analog:** itself — `lib/providers/availability_notifier.dart` (lines 1–50)

**Current state type** (lines 17–21):
```dart
@override
Future<Set<DateTime>> build() async {
  final prefs = await SharedPreferences.getInstance();
  final strings = prefs.getStringList(_key) ?? [];
  return strings.map(DateTime.parse).toSet();
}
```

**Current persist pattern** (lines 43–49):
```dart
Future<void> _persist(Set<DateTime> hours) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _key,
    hours.map((dt) => dt.toIso8601String()).toList(),
  );
}
```

**Required changes:**
- Add `enum BlockType { work, custom }` before the class
- Change `Future<Set<DateTime>> build()` → `Future<Map<DateTime, BlockType>> build()`
- Deserialize from `"ISO8601|work"` / `"ISO8601|custom"` format
- Rename `toggleHour` → `toggleCustomHour`, operates on `BlockType.custom`
- Add `seedPreset(Map<DateTime, BlockType> preset)` method
- Update `clearAll()` to emit `const AsyncData(<DateTime, BlockType>{})`
- Update `_persist` to serialize as `"ISO8601|work"` or `"ISO8601|custom"`

**New persist pattern to use** (derived from existing lines 43–49):
```dart
Future<void> _persist(Map<DateTime, BlockType> hours) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _key,
    hours.entries
        .map((e) => '${e.key.toIso8601String()}|${e.value.name}')
        .toList(),
  );
}
```

**New build deserialization pattern:**
```dart
@override
Future<Map<DateTime, BlockType>> build() async {
  final prefs = await SharedPreferences.getInstance();
  final strings = prefs.getStringList(_key) ?? [];
  final map = <DateTime, BlockType>{};
  for (final s in strings) {
    final parts = s.split('|');
    if (parts.length == 2) {
      final dt = DateTime.parse(parts[0]);
      final type = BlockType.values.byName(parts[1]);
      map[dt] = type;
    }
  }
  return map;
}
```

**Note on SlotsNotifier:** `lib/providers/slots_notifier.dart` line 108 passes `Set<DateTime> blockedHours` to `_filter.apply`. After this change, the type becomes `Map<DateTime, BlockType>`. The AvailabilityFilter service and SlotsNotifier will also need updating, but that is tracked in the Phase 4 plan — document here so the planner captures it.

---

### `lib/providers/availability_presets.dart` (utility, transform)

**Analog:** `lib/domain/services/scoring_engine.dart` (pure Dart function/class pattern)

**ScoringEngine pattern reference** — pure class, no Riverpod, no imports of framework:
```dart
// lib/domain/services/scoring_engine.dart — no @riverpod, no BuildContext
// Constructor takes no parameters; all logic is in methods.
// Returns a plain Dart object.
```

**File structure to follow:**
```dart
// lib/providers/availability_presets.dart
// Pure Dart — no riverpod_annotation, no flutter imports.
// No part directive — no code generation needed.

import 'package:ridewindow/providers/availability_notifier.dart'; // for BlockType

enum AvailabilityPreset {
  eveningsAndWeekends,
  morningsAndWeekends,
  weekendsOnly,
  custom, // navigates to /availability — no preset seeded
}

/// Returns a Map<DateTime, BlockType> for the rolling 7-day week starting [weekStart].
/// [weekStart] must be a Monday (time 00:00:00).
/// Hours NOT in the returned map are free.
/// All hours outside the preset's free windows are stored as BlockType.work.
Map<DateTime, BlockType> buildPreset(
  AvailabilityPreset preset,
  DateTime weekStart,
) {
  // implementation ...
}
```

---

### `lib/app/router.dart` (config, request-response)

**Analog:** `lib/main.dart` (MaterialApp setup, lines 1–26)

**No existing go_router analog in codebase** — this is the first router file. Use CONTEXT.md decisions and go_router 17.2.3 docs.

**main.dart wiring pattern to extend** (lines 1–26):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: RideWindowApp()));
}

class RideWindowApp extends StatelessWidget {
  const RideWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideWindow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      // home: replaced by router.go (MaterialApp.router)
    );
  }
}
```

**Router file pattern to create:**
```dart
// lib/app/router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('onboarding_complete') ?? false;
      if (!done) return '/welcome';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/onboard', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/availability', builder: (_, __) => const AvailabilityScreen()),
    ],
  );
}
```

**main.dart must be updated** to use `MaterialApp.router(routerConfig: ref.watch(routerProvider))` and become a `ConsumerWidget`.

---

### `lib/features/welcome/welcome_screen.dart` (component, request-response)

**Analog:** `lib/main.dart` (StatelessWidget pattern, lines 11–26)

**StatelessWidget pattern** (lines 11–16):
```dart
class RideWindowApp extends StatelessWidget {
  const RideWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

**No provider consumption needed** — WelcomeScreen is purely presentational. Uses `context.go('/onboard')` from go_router. No `ref.watch` needed; use `StatelessWidget`.

**Visual contract:** Read `mockup.html` at repo root before writing widget code. All colors, typography, button styles derive from that mockup.

**Theme pattern** (from main.dart line 19):
```dart
// Seed color for green cycling theme:
colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
```

---

### `lib/features/onboarding/onboarding_screen.dart` (component, request-response)

**Analog:** `lib/providers/profile_notifier.dart` (SharedPreferences write pattern)

**SharedPreferences write pattern** (lines 115–124 of profile_notifier.dart):
```dart
Future<void> updateTolerances(WeatherTolerances tolerances) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_keyTempMin, tolerances.tempMinIdealC);
  // ...
  final current = await future;
  state = AsyncData(current.copyWith(tolerances: tolerances));
}
```

**Onboarding screen must:**
1. Be a `ConsumerWidget` (needs `ref` to call `availabilityNotifierProvider.notifier`)
2. On preset tap: call `buildPreset(preset, weekStart)` then `ref.read(availabilityNotifierProvider.notifier).seedPreset(result)`
3. On "Next →": write `prefs.setBool('onboarding_complete', true)` then `context.go('/home')`
4. For "Set my own schedule": `context.go('/availability')` without seeding a preset

**ConsumerWidget pattern** (from riverpod_annotation usage across providers):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.read(availabilityNotifierProvider.notifier).seedPreset(...)
  }
}
```

---

### `lib/features/home/home_screen.dart` (component, request-response)

**Analog:** `lib/providers/slots_notifier.dart` (SlotsState pattern matching, lines 60–101)

**SlotsState sealed class consumption pattern** (lines 53–101):
```dart
// SlotsState is sealed — use pattern matching in widget:
// final state = ref.watch(slotsNotifierProvider);
// switch (state) {
//   SlotsLoaded(:final slots, :final reason) when slots.isEmpty => ...empty view...
//   SlotsLoaded(:final slots) => ...ride card list...
// }
```

**AsyncValue consumption pattern** (from slots_notifier.dart lines 62–74):
```dart
final weatherValue = ref.watch(weatherProvider);
// ...
if (weatherValue.isLoading || weatherValue.hasError || ...) {
  return const SlotsLoaded([]);
}
```

**HomeScreen requirements:**
- `ConsumerStatefulWidget` — needs local `DateTime? selectedDay` state AND `ref`
- Watch `slotsNotifierProvider` for slots
- Watch `locationProvider` for city name ("Amsterdam · This week")
- Watch `weatherProvider` for `AsyncLoading` → show skeleton shimmer
- Week strip: 7 day chips with tap → set `selectedDay`; tap same → `selectedDay = null`
- Loading state: grey shimmer blocks (3 skeleton cards + 7 day strip blocks)
- Error state: SnackBar + retry icon button
- "Plan it" button: `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Calendar integratie komt in een volgende update.')))`

**ConsumerStatefulWidget pattern:**
```dart
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final slotsState = ref.watch(slotsNotifierProvider);
    final location = ref.watch(locationProvider);
    // ...
  }
}
```

---

### `lib/features/availability/availability_screen.dart` (component, stub)

**Analog:** `lib/main.dart` (Scaffold stub pattern, lines 20–24):
```dart
home: const Scaffold(
  body: Center(child: Text('RideWindow — domain ready')),
),
```

**Stub pattern to copy:**
```dart
class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mijn schema')),
      body: const Center(child: Text('Komt in een volgende update.')),
    );
  }
}
```

---

## Shared Patterns

### @riverpod annotation (functional provider)
**Source:** `lib/providers/app_database_provider.dart` lines 18–21
**Apply to:** `location_provider.dart`, `router.dart`
```dart
@riverpod
ReturnType providerName(Ref ref) {
  return ReturnType(...);
}
// Generated name: providerNameProvider (camelCase + Provider)
```

### @riverpod AsyncNotifier class
**Source:** `lib/providers/availability_notifier.dart` lines 12–50
**Apply to:** `availability_notifier.dart` (modified), any future AsyncNotifier
```dart
@riverpod
class XyzNotifier extends _$XyzNotifier {
  @override
  Future<T> build() async { ... }

  Future<void> mutate(...) async {
    final current = await future;
    // ... compute next ...
    state = AsyncData(next);
  }
}
// Generated name: xyzNotifierProvider, ref.watch(xyzNotifierProvider.notifier)
```

### @Riverpod(keepAlive: true) — singleton provider
**Source:** `lib/providers/app_database_provider.dart` lines 11–14
**Apply to:** `router.dart` (router must survive navigation)
```dart
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) { ... }
```

### SharedPreferences read/write
**Source:** `lib/providers/profile_notifier.dart` lines 76–111 (read) + 115–124 (write)
**Apply to:** `router.dart` (redirect reads `'onboarding_complete'`), `onboarding_screen.dart` (writes `'onboarding_complete'`)
```dart
// Read:
final prefs = await SharedPreferences.getInstance();
final value = prefs.getBool('key') ?? false;

// Write:
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('key', true);
```

### Package import path convention
**Source:** `lib/providers/slots_notifier.dart` lines 1–10
**Apply to:** all new files
```dart
// Always use package: imports, never relative imports for cross-feature deps
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
// Exception: same-directory files may use relative imports (e.g. in domain/models/)
import 'hourly_score.dart'; // only within same directory
```

### Sealed class + pattern matching
**Source:** `lib/providers/slots_notifier.dart` lines 19–41
**Apply to:** `home_screen.dart` (consuming SlotsState)
```dart
sealed class SlotsState { const SlotsState(); }
final class SlotsLoaded extends SlotsState {
  final List<RideSlot> slots;
  final SlotsEmptyReason? reason;
  const SlotsLoaded(this.slots, {this.reason});
}
// Consumption in widget:
switch (slotsState) {
  SlotsLoaded(:final slots) when slots.isEmpty => EmptyView(),
  SlotsLoaded(:final slots) => SlotList(slots),
}
```

### Theme seed color
**Source:** `lib/main.dart` line 19
**Apply to:** `main.dart` (updated), `router.dart` wrapping widget
```dart
colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/app/router.dart` | config | request-response | No go_router usage exists yet in codebase |

---

## Downstream Notes for Planner

1. **SlotsNotifier breaking change:** `lib/providers/slots_notifier.dart` line 108 passes `Set<DateTime>` to `AvailabilityFilter.apply`. After the `Map<DateTime, BlockType>` change, `AvailabilityFilter` signature must change too. Plan must include updating `lib/domain/services/availability_filter.dart` and its tests.

2. **Part directive requirement:** Every `@riverpod`-annotated file needs `part 'filename.g.dart';` and `build_runner` must be run after adding `location_provider.dart` and `router.dart`.

3. **main.dart must become ConsumerWidget:** To use `ref.watch(routerProvider)` inside `RideWindowApp.build`, the class must extend `ConsumerWidget` and accept `WidgetRef ref`.

4. **Visual source of truth:** All widget files must read `mockup.html` at repo root before writing any widget layout. Colors, spacing, card shape, bottom nav style — all derived from that file.

5. **availability_presets.dart imports BlockType:** `BlockType` enum will be declared in `availability_notifier.dart`. The presets file must import `package:ridewindow/providers/availability_notifier.dart` to access it. Alternatively, move `BlockType` to a separate `lib/domain/models/block_type.dart` to avoid a domain→providers import direction issue. Planner should decide placement.

---

## Metadata

**Analog search scope:** `/Users/joostmouw/ridewindow/lib/`
**Files scanned:** 10 source files (main.dart + 5 providers + 3 domain models + 1 domain service)
**Pattern extraction date:** 2026-06-03
