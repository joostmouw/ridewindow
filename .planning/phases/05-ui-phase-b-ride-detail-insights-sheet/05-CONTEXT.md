---
phase: 05-ui-phase-b-ride-detail-insights-sheet
generated: "2026-06-03"
---

# Phase 05: Ride Detail + InsightsSheet — Context

## Beslissingen (vastgezet tijdens planningssessie)

### D-05-01: HourlyRow samenvoegmodel
`RideSlot.hours` bevat `List<HourlyScore>` (scores) — niet de ruwe `HourlyForecast`-data
(temperatuur, neerslag, windsnelheid als doubles). De uurtabel in `RideDetailScreen`
heeft beide nodig. Oplossing: maak een `HourlyRow` waardeklasse in
`lib/domain/models/hourly_row.dart` die beide samenvoegt op basis van `time`:

```dart
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
}
```

`HourlyRow` is een plain Dart class (geen Freezed nodig — Phase 5-only weergave-model).

### D-05-02: Navigatiepatroon — go_router extra
Navigatie van de ride card naar `RideDetailScreen` gebruikt `go_router`'s `extra`-parameter
om twee objecten door te sturen:
- `RideSlot` (voor scores, tijdreeks, tier)
- `List<HourlyForecast>` gefilterd op het slot-tijdvenster (voor ruwe weersdata)

Route-pad: `/detail` (geen ID — object via `extra`).
In `router.dart`: `context.go('/detail', extra: DetailArgs(slot: slot, forecasts: filteredForecasts))`.

`DetailArgs` is een plain Dart class in `lib/features/detail/detail_args.dart`:
```dart
class DetailArgs {
  final RideSlot slot;
  final List<HourlyForecast> forecasts;
  const DetailArgs({required this.slot, required this.forecasts});
}
```

### D-05-03: InsightsSheet — gemiddelde sub-scores
`InsightsSheet` toont het gemiddelde van de sub-scores over alle uren in het slot:
- `avgTempScore = hours.map((h) => h.temperatureScore).average`
- `avgRainScore = hours.map((h) => h.rainScore).average`
- `avgWindScore = hours.map((h) => h.windScore).average`

Drie `LinearProgressIndicator`-balken, elk met waarde `score / 100.0` (0.0–1.0).

### D-05-04: InsightsSheet — één-regel uitleg per factor
Uitleg wordt bepaald aan de hand van de gemiddelde sub-score (geen vrije tekst):
- Score ≥ 80 → "Ideale omstandigheden" (temp), "Droog" (rain), "Lichte wind" (wind)
- Score ≥ 60 → "Acceptabel" (temp), "Lichte neerslag verwacht" (rain), "Matige wind" (wind)
- Score < 60 → "Buiten het ideale bereik" (temp), "Neerslag verwacht" (rain), "Sterke wind" (wind)

### D-05-05: Score-kleur InsightsSheet
Kleur van de `LinearProgressIndicator` wordt bepaald door de sub-score:
- score ≥ 80 → groen `Color(0xFF2E7D32)`
- score ≥ 60 → oranje `Color(0xFFE65100)`
- score < 60 → rood `Color(0xFFC62828)`

### D-05-06: HomeScreen weather chips bijwerken
`HomeScreen._buildRideCard` toont nu placeholder chips ("?°C / ?mm / ?km/u").
In Wave 2 worden deze vervangen door echte weersdata: gemiddelde temperatuur,
totale neerslag en gemiddelde windsnelheid van de uren in het slot.
De `weatherProvider` is al beschikbaar in `HomeScreen` — filter `List<HourlyForecast>`
op `slot.start ≤ time < slot.end`.

### D-05-07: Score badge matching
`RideDetailScreen` toont dezelfde score-badge als de ride cards in `HomeScreen`
via de gedeelde `_buildBadge`-logica. In Phase 5 wordt deze logica verplaatst naar
een aparte widget `ScoreBadge` in `lib/features/shared/score_badge.dart` zodat beide
screens hem hergebruiken.

### D-05-08: Taalconventie
Alle gebruikersgerichte tekst in Dart-widgets is in het Nederlands (consistent met Phase 4):
- "Waarom deze score?" (Why this score? trigger)
- "Begrijpen" (Got it knop in InsightsSheet)
- Dag- en tijdnotaties: "09:00 – 13:00", "4u", "ma", "di", etc.

## Niet gedaan in Phase 5 (uitgesteld)

- "Toevoegen aan agenda" knop → Phase 9 (Google Calendar)
- "Herinner me de avond ervoor" knop → Phase 8 (Notificaties)
- Profielnavigatie via NavigationBar → Phase 6
- Echte GPS-locatie → Phase 7
