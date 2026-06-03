# Phase 06: UI Phase C — Pattern Map

**Gemaakt:** 2026-06-03
**Gebaseerd op:** Fases 04 + 05 PATTERNS.md, codebase-analyse, technische beperkingen

---

## Bestandsclassificatie

| Nieuw/Gewijzigd bestand | Rol | Dataflow | Dichtstbijzijnd analogon | Match-kwaliteit |
|---|---|---|---|---|
| `lib/providers/theme_mode_provider.dart` | provider (functioneel) | transform | `lib/providers/location_provider.dart` | exact |
| `lib/app/router.dart` (wijziging) | config | navigatie | zichzelf (wave-5-versie) | exact |
| `lib/features/home/home_screen.dart` (wijziging) | component | navigatie | zichzelf (wave-4-versie) | exact |
| `lib/main.dart` (wijziging) | entry-point | theme-reactie | zichzelf (wave-4-versie) | exact |
| `lib/features/profile/profile_screen.dart` | scherm | request-response | `lib/features/home/home_screen.dart` | rol-match |
| `lib/features/availability/availability_screen.dart` (VERVANGEN) | scherm | CRUD | `lib/features/home/home_screen.dart` | rol-match |
| `test/features/profile_screen_test.dart` | widget-test | — | `test/features/home_screen_test.dart` | exact |
| `test/features/availability_screen_test.dart` | widget-test | — | `test/features/home_screen_test.dart` | exact |

---

## Patroonopdrachtkaarten

### `lib/providers/theme_mode_provider.dart` (functionele provider)

**Analogon:** `lib/providers/location_provider.dart` (functionele provider, geen async)

```dart
// lib/providers/theme_mode_provider.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ridewindow/providers/profile_notifier.dart';

part 'theme_mode_provider.g.dart';

/// Zet profile.theme (String) om naar ThemeMode.
/// Hercomputed automatisch als profileProvider een nieuwe waarde emitteert.
@riverpod
ThemeMode themeMode(Ref ref) {
  final profileValue = ref.watch(profileProvider);
  final theme = profileValue.valueOrNull?.theme ?? 'system';
  return switch (theme) {
    'light' => ThemeMode.light,
    'dark'  => ThemeMode.dark,
    _       => ThemeMode.system,
  };
}
```

**Gegenereerde naam:** `themeModeProvider` (camelCase + Provider)

---

### `lib/main.dart` (wijziging — themeMode toevoegen)

**Analogon:** zichzelf (wave-4-versie)

Huidige `MaterialApp.router` aanroep (main.dart regels 19–26):
```dart
return MaterialApp.router(
  title: 'RideWindow',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
  ),
  routerConfig: router,
);
```

Uitgebreide versie na Phase 6 Wave 1:
```dart
return MaterialApp.router(
  title: 'RideWindow',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ref.watch(themeModeProvider),
  routerConfig: router,
);
```

---

### `lib/app/router.dart` (wijziging — /profile route)

**Analogon:** zichzelf (wave-5-versie, na toevoeging van /detail)

GoRoute toevoegen na `/detail`:
```dart
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreen(),
),
```

Import toevoegen:
```dart
import 'package:ridewindow/features/profile/profile_screen.dart';
```

---

### `lib/features/home/home_screen.dart` (wijziging — bottomNav wiring)

**Analogon:** zichzelf (huidige `_buildBottomNav`, regels 616–635)

Huidig (stub):
```dart
onDestinationSelected: (i) {
  // Profiel-navigatie komt in Phase 6.
},
```

Na Phase 6 Wave 1:
```dart
onDestinationSelected: (i) {
  if (i == 1) context.go('/profile');
},
```

---

### `lib/features/profile/profile_screen.dart` (nieuw scherm)

**Analogon:** `lib/features/home/home_screen.dart` (ConsumerStatefulWidget patroon)

Structuur:
```dart
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Lokale state voor live slider-waarden (vóór onChangeEnd persistentie)
  late double _tempMin;
  late double _tempMax;
  late double _rainMax;
  late double _windMax;

  @override
  void initState() {
    super.initState();
    // Initialiseer uit profileProvider snapshot (synchrone read na eerste load)
    final profile = ref.read(profileProvider).valueOrNull;
    _tempMin = profile?.tolerances.tempMinIdealC ?? 12.0;
    _tempMax = profile?.tolerances.tempMaxIdealC ?? 26.0;
    _rainMax = profile?.tolerances.rainMaxIdealMm ?? 0.5;
    _windMax = profile?.tolerances.windMaxIdealKmh ?? 15.0;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // ...
  }
}
```

**Slider patroon (debounced via onChangeEnd):**
```dart
Slider(
  value: _tempMin,
  min: 0,
  max: 20,
  divisions: 20,
  label: '${_tempMin.round()}°C',
  onChanged: (v) => setState(() => _tempMin = v),
  onChangeEnd: (v) => ref.read(profileProvider.notifier).updateTolerances(
    profile.tolerances.copyWith(tempMinIdealC: v),
  ),
)
```

**Rijlengte-chip patroon (FilterChip):**
```dart
FilterChip(
  label: Text('2u'),
  selected: profile.allowedDurations.contains(2),
  onSelected: (_) => ref.read(profileProvider.notifier).toggleDuration(2),
)
```

**Thema-selector patroon (SegmentedButton):**
```dart
SegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'system', label: Text('Systeem')),
    ButtonSegment(value: 'light', label: Text('Licht')),
    ButtonSegment(value: 'dark', label: Text('Donker')),
  ],
  selected: {profile.theme},
  onSelectionChanged: (s) => ref.read(profileProvider.notifier).setTheme(s.first),
)
```

---

### `lib/features/availability/availability_screen.dart` (VERVANGEN — volledige implementatie)

**Analogon:** `lib/features/home/home_screen.dart` (ConsumerWidget + Riverpod consumption)

Structuur:
```dart
class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availValue = ref.watch(availabilityProvider);
    return availValue.when(
      loading: () => const Scaffold(appBar: ..., body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: ..., body: Center(child: Text('Fout: $e'))),
      data: (blockedHours) => _AvailabilityGrid(blockedHours: blockedHours, ref: ref),
    );
  }
}
```

**Rooster-bouwpatroon (7×24 interactief raster):**
```dart
// Weekstart: maandag van de huidige week
final now = DateTime.now();
final weekStart = now.subtract(Duration(days: now.weekday - DateTime.monday));

// Normaliseer naar middernacht UTC voor DateTime-sleutelconsistentie
DateTime cellKey(int dayIndex, int hour) =>
    DateTime.utc(weekStart.year, weekStart.month, weekStart.day + dayIndex, hour);

// Celkleur op basis van BlockType
Color cellColor(DateTime key, Map<DateTime, BlockType> blocked) {
  final type = blocked[key];
  return switch (type) {
    BlockType.work   => const Color(0xFFB0BEC5), // blauw/grijs
    BlockType.custom => const Color(0xFFFF9800), // oranje
    null             => Colors.white,             // vrij
  };
}

// Tap: alleen custom-blokken togglen (werk-blokken zijn niet toggelbaar)
void onCellTap(DateTime key, Map<DateTime, BlockType> blocked, WidgetRef ref) {
  if (blocked[key] == BlockType.work) return; // D-06-06: werk niet toggelbaar
  ref.read(availabilityProvider.notifier).toggleCustomHour(key);
}
```

**DateTime-sleutelnormalisatie:** Gebruik `DateTime.utc(...)` voor roostercellen, consistent
met hoe `AvailabilityNotifier.toggleCustomHour` DateTime-objecten vergelijkt na SharedPreferences
deserialisatie (ISO 8601 round-trip).

---

### Widget-testpatronen (overgenomen uit Phase 5)

Alle patronen zijn gevestigd in Phase 4/5:

```dart
// setUp
SharedPreferences.setMockInitialValues({});

// FakeNotifier patroon (extends concrete class)
class FakeProfileNotifier extends ProfileNotifier {
  final UserProfile fakeProfile;
  FakeProfileNotifier(this.fakeProfile);

  @override
  Future<UserProfile> build() async => fakeProfile;
}

class FakeAvailabilityNotifier extends AvailabilityNotifier {
  final Map<DateTime, BlockType> fakeMap;
  FakeAvailabilityNotifier(this.fakeMap);

  @override
  Future<Map<DateTime, BlockType>> build() async => fakeMap;
}

// ProviderScope override
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      profileProvider.overrideWith(() => FakeProfileNotifier(testProfile)),
      availabilityProvider.overrideWith(() => FakeAvailabilityNotifier(testMap)),
    ],
    child: MaterialApp(home: const ProfileScreen()),
  ),
);

// Geen pumpAndSettle — gebruik pump(Duration)
await tester.pump();
await tester.pump(const Duration(milliseconds: 100));
```

---

## Gedeelde patronen (overgenomen uit vorige fases)

| Patroon | Bron | Toepassen op |
|---------|------|--------------|
| `package:` imports overal | `slots_notifier.dart` r1-10 | alle nieuwe bestanden |
| `@riverpod` functionele provider | `location_provider.dart` | `theme_mode_provider.dart` |
| `ConsumerStatefulWidget` | `home_screen.dart` r18-23 | `profile_screen.dart` |
| `ConsumerWidget` | `onboarding_screen.dart` | `availability_screen.dart` |
| `AsyncValue.when` pattern | `home_screen.dart` (loading/error/data) | `availability_screen.dart` |
| Theme seed kleur `0xFF2E7D32` | `main.dart` r19 | darkTheme seed |
| FakeNotifier testpatroon | `home_screen_test.dart` | `profile_screen_test.dart`, `availability_screen_test.dart` |
| SharedPreferences mock setup | alle widget-tests | alle Phase 6 widget-tests |

---

## Aantekeningen voor de uitvoerder

1. **`themeModeProvider` heeft een `part` directive nodig** — voeg `part 'theme_mode_provider.g.dart';`
   toe en run `flutter pub run build_runner build --delete-conflicting-outputs`.

2. **ProfileScreen `initState` valkuil** — `ref.read(profileProvider)` in `initState` geeft
   `AsyncValue<UserProfile>`. Gebruik `.valueOrNull` en val terug op defaults als de provider
   nog laadt. Sla opnieuw in met `ref.watch` in `build`.

3. **Rooster DateTime-sleutels** — `AvailabilityNotifier` persisteert via ISO 8601. Na
   deserialisatie zijn UTC-DateTimes noodzakelijk voor `Map.containsKey`. Gebruik altijd
   `DateTime.utc(...)` voor roostercellen.

4. **`onChangeEnd` vs. `onChanged`** — `onChanged` update lokale `setState` voor directe
   UI-feedback. `onChangeEnd` persisteert naar SharedPreferences (per D-06-02).

5. **Mockup.html is de visuele bron** — lees `.profile-*`, `.avail-*`, `.slider-*` CSS-secties
   voor kleuren en spacing.

6. **Bouw volgorde** — Na nieuwe `@riverpod`-bestanden: altijd `flutter pub run build_runner
   build --delete-conflicting-outputs` uitvoeren voor compilatie.
