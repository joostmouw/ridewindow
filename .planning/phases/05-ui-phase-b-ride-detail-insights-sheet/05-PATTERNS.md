# Phase 05: Ride Detail + InsightsSheet — Pattern Map

**Gemaakt:** 2026-06-03
**Gebaseerd op:** Phase 04 PATTERNS.md + Phase 04 SUMMARY-bestanden + codebase-analyse

---

## Bestandsclassificatie

| Nieuw bestand | Rol | Dataflow | Dichtstbijzijnd analogon | Match-kwaliteit |
|---|---|---|---|---|
| `lib/domain/models/hourly_row.dart` | weergave-model | samenvoeging | `lib/domain/models/hourly_score.dart` | rol-match |
| `lib/features/detail/detail_args.dart` | data-transfer object | navigatie-extra | `lib/domain/models/ride_slot.dart` (plain Dart class) | rol-match |
| `lib/features/shared/score_badge.dart` | gedeelde widget | presentatie | `HomeScreen._buildBadge` (extractie) | exact |
| `lib/features/detail/ride_detail_screen.dart` | scherm | request-response | `lib/features/home/home_screen.dart` | rol-match |
| `lib/features/detail/insights_sheet.dart` | bottom-sheet widget | presentatie | `lib/features/home/home_screen.dart._buildRideCard` | rol-match |
| `lib/app/router.dart` (wijziging) | config | navigatie | zichzelf (wave-4-versie) | exact |
| `test/features/ride_detail_screen_test.dart` | widget-test | — | `test/features/home_screen_test.dart` | exact |
| `test/features/insights_sheet_test.dart` | widget-test | — | `test/features/home_screen_test.dart` | exact |

---

## Patroonopdrachtkaarten

### `lib/domain/models/hourly_row.dart` (weergave-model)

**Analogon:** `lib/domain/models/hourly_score.dart`

Plain Dart class — geen Freezed, geen part-directive, geen code-gen.
Uitsluitend voor weergave-samenvoegingsdoeleinden in Phase 5.

```dart
// lib/domain/models/hourly_row.dart
// Geen imports van Flutter of Riverpod — domein-puur
class HourlyRow {
  final DateTime time;
  final double? temperatureC;
  final double? apparentTemperatureC;
  final double? precipitationMm;
  final double? windspeedKmh;
  final double overallScore;
  final double temperatureScore;
  final double rainScore;
  final double windScore;

  const HourlyRow({
    required this.time,
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.precipitationMm,
    required this.windspeedKmh,
    required this.overallScore,
    required this.temperatureScore,
    required this.rainScore,
    required this.windScore,
  });
}
```

**Bouwpatroon (samenvoeging op tijd):**
```dart
// In RideDetailScreen of als pure hulpfunctie:
List<HourlyRow> buildHourlyRows(RideSlot slot, List<HourlyForecast> forecasts) {
  return slot.hours.map((score) {
    final fc = forecasts.firstWhere(
      (f) => f.time == score.time,
      orElse: () => HourlyForecast(
        temperatureC: null, apparentTemperatureC: null,
        precipitationMm: null, precipitationProbability: null,
        windspeedKmh: null, winddirectionDeg: null,
        time: score.time,
      ),
    );
    return HourlyRow(
      time: score.time,
      temperatureC: fc.temperatureC,
      apparentTemperatureC: fc.apparentTemperatureC,
      precipitationMm: fc.precipitationMm,
      windspeedKmh: fc.windspeedKmh,
      overallScore: score.overall,
      temperatureScore: score.temperatureScore,
      rainScore: score.rainScore,
      windScore: score.windScore,
    );
  }).toList();
}
```

---

### `lib/features/detail/detail_args.dart` (data-transfer object)

Plain Dart class — geen Freezed, geen Riverpod.

```dart
// lib/features/detail/detail_args.dart
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';

class DetailArgs {
  final RideSlot slot;
  final List<HourlyForecast> forecasts; // gefilterd op slot-tijdvenster

  const DetailArgs({required this.slot, required this.forecasts});
}
```

---

### `lib/features/shared/score_badge.dart` (gedeelde widget)

**Analogon:** `HomeScreen._buildBadge` (extractie van lines 521–554 in home_screen.dart)

```dart
// lib/features/shared/score_badge.dart
import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';

class ScoreBadge extends StatelessWidget {
  final RideTier tier;
  const ScoreBadge({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (tier) {
      case Perfect():
        bg = const Color(0xFFE8F5E9); fg = const Color(0xFF1B5E20);
      case Great():
        bg = const Color(0xFFF1F8E9); fg = const Color(0xFF33691E);
      case Acceptable():
        bg = const Color(0xFFFFF3E0); fg = const Color(0xFFE65100);
      case Poor():
        bg = const Color(0xFFF5F5F5); fg = const Color(0xFF757575);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        _tierLabel(tier),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  String _tierLabel(RideTier tier) => switch (tier) {
    Perfect()    => 'Perfect',
    Great()      => 'Goed',
    Acceptable() => 'Acceptabel',
    Poor()       => 'Slecht',
  };
}
```

---

### `lib/app/router.dart` (wijziging — /detail route toevoegen)

**Analogon:** huidige `lib/app/router.dart` (wave-4-versie)

GoRoute voor `/detail` met `DetailArgs` via `state.extra`:

```dart
GoRoute(
  path: '/detail',
  builder: (context, state) {
    final args = state.extra as DetailArgs;
    return RideDetailScreen(slot: args.slot, forecasts: args.forecasts);
  },
),
```

Navigeren vanuit HomeScreen:
```dart
final forecasts = ref.read(weatherProvider).requireValue;
final slotForecasts = forecasts.where(
  (f) => !f.time.isBefore(slot.start) && f.time.isBefore(slot.end),
).toList();
context.go('/detail', extra: DetailArgs(slot: slot, forecasts: slotForecasts));
```

---

### `lib/features/detail/ride_detail_screen.dart` (scherm)

**Analogon:** `lib/features/home/home_screen.dart` (ConsumerStatefulWidget patroon)

- `StatelessWidget` (geen lokale state nodig — slot en forecasts worden als parameters meegegeven)
- AppBar met terugknop (`context.pop()` of `context.go('/home')`)
- Score-banner: tier-emoji + tier-label + score + "Waarom deze score?" `IconButton`
- Info-kaart "Weer" (3 rijen: Temperatuur, Neerslag, Wind)
- Info-kaart "Uurlijks" (tabel met `HourlyRow`-items)
- Acties: placeholder knoppen voor Phase 8/9

**Score-bannerkleuren (consistent met HomeScreen):**
```dart
Color _tierBannerBg(RideTier tier) => switch (tier) {
  Perfect()    => const Color(0xFFE8F5E9),
  Great()      => const Color(0xFFF1F8E9),
  Acceptable() => const Color(0xFFFFF3E0),
  Poor()       => const Color(0xFFF5F5F5),
};
```

---

### `lib/features/detail/insights_sheet.dart` (bottom-sheet widget)

Wordt aangeroepen via `showModalBottomSheet` — geen navigatieroute.

```dart
// Aanroeppatroon in RideDetailScreen:
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (_) => InsightsSheet(slot: slot),
);
```

**InsightsSheet ontvangt alleen `RideSlot`** — sub-scores zijn al aanwezig in `slot.hours`.
Berekent gemiddelden intern:
```dart
double get _avgTemp => slot.hours.map((h) => h.temperatureScore).average;
double get _avgRain => slot.hours.map((h) => h.rainScore).average;
double get _avgWind => slot.hours.map((h) => h.windScore).average;
```

`Iterable<double>.average` is beschikbaar via `package:collection` of handmatig:
```dart
double _avg(Iterable<double> values) =>
    values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
```

**`LinearProgressIndicator` patroon:**
```dart
LinearProgressIndicator(
  value: score / 100.0,
  backgroundColor: const Color(0xFFECEFF1),
  valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(score)),
  minHeight: 8,
  borderRadius: BorderRadius.circular(4),
)
```

---

### Widget-testpatronen (van Phase 04 SUMMARY-05)

Alle patronen zijn gevestigd in Phase 4:

```dart
// setUp
SharedPreferences.setMockInitialValues({});

// GoRouter fixture (inline in testWidget)
final router = GoRouter(routes: [
  GoRoute(path: '/', builder: (_, __) => const SizedBox()),
  GoRoute(path: '/detail', builder: (_, state) {
    final args = state.extra as DetailArgs;
    return RideDetailScreen(slot: args.slot, forecasts: args.forecasts);
  }),
]);

// ProviderScope override (inline — niet als parameter)
await tester.pumpWidget(
  ProviderScope(
    overrides: [weatherProvider.overrideWith(...)],
    child: MaterialApp.router(routerConfig: router),
  ),
);

// Geen pumpAndSettle — gebruik pump(Duration)
await tester.pump();
await tester.pump(const Duration(milliseconds: 100));
```

**FakeNotifier patroon (extends concrete class, niet _$-abstracte):**
```dart
class FakeWeatherNotifier extends WeatherNotifier {
  final List<HourlyForecast> forecasts;
  FakeWeatherNotifier(this.forecasts);

  @override
  Future<List<HourlyForecast>> build() async => forecasts;
}
```

---

## Gedeelde patronen (overgenomen uit Phase 4)

| Patroon | Bron | Toepassen op |
|---------|------|--------------|
| `package:` imports overal | `slots_notifier.dart` r1-10 | alle nieuwe bestanden |
| `@riverpod` annotatie | `app_database_provider.dart` r18-21 | — (niet nodig in Phase 5) |
| Sealed class + patroonmatching | `slots_notifier.dart` r19-41 | `RideDetailScreen` voor `RideTier` kleuren |
| ConsumerWidget patroon | `home_screen.dart` r15-20 | `RideDetailScreen` (StatelessWidget is voldoende) |
| Theme seed kleur `0xFF2E7D32` | `main.dart` r19 | score-banners en progress bars |

---

## Aantekeningen voor de uitvoerder

1. **`RideDetailScreen` is een `StatelessWidget`** — de slot en forecasts worden als
   constructor-parameters meegegeven vanuit de router. Geen `ref.watch` nodig tenzij
   de weather-data opnieuw moet worden geladen (niet het geval in Phase 5).

2. **`ScoreBadge` vervangt `_buildBadge` in `HomeScreen`** — na aanmaken van
   `lib/features/shared/score_badge.dart` moet `HomeScreen._buildBadge` worden
   vervangen door `ScoreBadge(tier: slot.tier)`.

3. **Mockup.html is de visuele bron** — lees de `.score-banner`, `.hourly-row`,
   `.insight-row`, `.insight-bar`-CSS-secties voor kleuren, afstanden en typografie.
   Alle kleuren zijn al gedocumenteerd in CONTEXT.md D-05-05.

4. **`HourlyForecast`-filtering** — filter op `!f.time.isBefore(slot.start) && f.time.isBefore(slot.end)`
   om het tijdvenster `[start, end)` te respecteren (exclusief einde, consistent met SLOT-02).
