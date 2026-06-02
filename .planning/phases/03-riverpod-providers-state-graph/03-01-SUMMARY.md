---
phase: 03-riverpod-providers-state-graph
plan: 01
subsystem: state
tags: [riverpod, flutter_riverpod, riverpod_annotation, riverpod_generator, AsyncNotifier, ProviderContainer, mockito]

requires:
  - phase: 02-data-layer-drift-open-meteo
    provides: WeatherRepository, AppDatabase, OpenMeteoClient

provides:
  - appDatabaseProvider (keepAlive singleton via @Riverpod(keepAlive: true))
  - openMeteoClientProvider (@riverpod auto-dispose)
  - weatherRepositoryProvider (@riverpod auto-dispose, wired to db + client)
  - WeatherNotifier as @riverpod AsyncNotifier<List<HourlyForecast>> (weatherProvider)
  - 3 ProviderContainer tests: loading, data, error states

affects: [03-02, 03-03, 03-04]

tech-stack:
  added:
    - flutter_riverpod 3.3.2-dev.2 (resolved from ^3.3.1)
    - riverpod_annotation 4.0.3-dev.2 (resolved from ^4.0.2)
    - riverpod_generator 4.0.4-dev.3 (resolved from ^4.0.4-dev.1)
  patterns:
    - "@riverpod functional provider for infrastructure (appDatabase, openMeteoClient, weatherRepository)"
    - "@riverpod class-based AsyncNotifier for async data fetching (WeatherNotifier)"
    - "ProviderContainer + overrideWithValue for unit-testing providers without BuildContext"
    - "Riverpod 3.x error state: AsyncLoading(hasError: true) due to auto-retry behavior"

key-files:
  created:
    - lib/providers/app_database_provider.dart
    - lib/providers/app_database_provider.g.dart
    - lib/providers/weather_notifier.dart
    - lib/providers/weather_notifier.g.dart
    - test/providers/weather_notifier_test.dart
    - test/providers/weather_notifier_test.mocks.dart
  modified:
    - pubspec.yaml (added flutter_riverpod, riverpod_annotation, riverpod_generator)

key-decisions:
  - "riverpod_generator ^2.6.5 (plan) is incompatible with riverpod_annotation 4.0.2 — upgraded to riverpod_generator ^4.0.4-dev.1"
  - "Riverpod 3.x generated provider name for WeatherNotifier is weatherProvider (code-gen strips Notifier suffix)"
  - "Riverpod 3.x auto-retry: error state is AsyncLoading(hasError: true), not AsyncError; test checks state.hasError instead of isA<AsyncError>()"
  - "Ref parameter type in provider functions is plain Ref (not XxxRef) in Riverpod 3.x"

patterns-established:
  - "Provider functions use Ref (not typed XxxRef) as first parameter"
  - "Class-based notifier name in code is WeatherNotifier but generated provider is weatherProvider"
  - "Error state testing: use container.listen() + microtask pump + state.hasError check"

requirements-completed: [PROF-03, SLOT-05]

duration: 25min
completed: 2026-06-02
---

# Phase 3 Plan 01: Riverpod Infrastructure Providers + WeatherNotifier Summary

**flutter_riverpod 3.3.1 + @riverpod code-gen voor appDatabaseProvider, openMeteoClientProvider, weatherRepositoryProvider en WeatherNotifier als AsyncNotifier met 3 passerende ProviderContainer-tests**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-02T20:07:00Z
- **Completed:** 2026-06-02T20:32:06Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Riverpod 3.x packages geinstalleerd en opgelost (3.3.2-dev.2 + 4.0.3-dev.2 + generator 4.0.4-dev.3)
- Infrastructure-providers aangemaakt: appDatabaseProvider (keepAlive), openMeteoClientProvider, weatherRepositoryProvider
- WeatherNotifier geimplementeerd als @riverpod AsyncNotifier met build() die getForecast() aanroept
- 3 ProviderContainer-tests: loading state, data state, error state — alle slagen
- Volledige test-suite: 81 tests groen (78 bestaand + 3 nieuw)
- dart analyze lib/ meldt geen issues

## Task Commits

1. **Task 1: Voeg Riverpod-pakketten toe + infrastructuur-providers** — `b0caf28` (feat)
2. **Task 2: WeatherNotifier + ProviderContainer-tests (TDD RED→GREEN)** — `67ddc86` (feat)

## Files Created/Modified

- `pubspec.yaml` — flutter_riverpod, riverpod_annotation, riverpod_generator toegevoegd
- `lib/providers/app_database_provider.dart` — appDatabaseProvider (keepAlive), openMeteoClientProvider, weatherRepositoryProvider
- `lib/providers/app_database_provider.g.dart` — gegenereerde provider-registratie
- `lib/providers/weather_notifier.dart` — WeatherNotifier als @riverpod AsyncNotifier
- `lib/providers/weather_notifier.g.dart` — gegenereerde provider-registratie (weatherProvider)
- `test/providers/weather_notifier_test.dart` — 3 ProviderContainer-tests
- `test/providers/weather_notifier_test.mocks.dart` — MockWeatherRepository gegenereerd door mockito

## Decisions Made

- `riverpod_generator ^4.0.4-dev.1` vereist in plaats van plan-versie `^2.6.5` — de 2.x reeks is incompatibel met `riverpod_annotation 4.0.2`
- Gegenereerde provider-naam is `weatherProvider` (niet `weatherNotifierProvider`) — Riverpod 3.x code-gen strippt de `Notifier`-suffix
- Fout-staat in Riverpod 3.x is `AsyncLoading(hasError: true)` door automatisch retry-gedrag, niet `AsyncError` — test aangepast naar `state.hasError`
- Ref-parameter in providerfuncties is gewoon `Ref` (niet `XxxRef`) in Riverpod 3.x

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] riverpod_generator versie-conflict opgelost**
- **Found during:** Task 1 (flutter pub get)
- **Issue:** Plan specificeert `riverpod_generator ^2.6.5`, maar deze versie vereist `riverpod_annotation 2.x` (incompatibel met `riverpod_annotation 4.0.2`)
- **Fix:** Versie bijgewerkt naar `^4.0.4-dev.1` — de 4.x reeks van riverpod_generator is de juiste match voor Riverpod 3.x
- **Files modified:** pubspec.yaml, pubspec.lock
- **Verification:** `flutter pub get` succesvol, geen conflicten
- **Committed in:** b0caf28

**2. [Rule 1 - Bug] Riverpod 3.x Ref-type in provider-functiesignatuur**
- **Found during:** Task 1 (dart analyze)
- **Issue:** Plan-voorbeeldcode gebruikt `AppDatabaseRef`, `OpenMeteoClientRef` etc. maar Riverpod 3.x genereert die typed-Ref klassen niet meer — gebruikt plain `Ref`
- **Fix:** Functiesignaturen bijgewerkt naar `AppDatabase appDatabase(Ref ref)` etc.
- **Files modified:** lib/providers/app_database_provider.dart
- **Verification:** `dart analyze lib/providers/app_database_provider.dart` — geen issues
- **Committed in:** b0caf28

**3. [Rule 1 - Bug] Gegenereerde provider-naam is weatherProvider, niet weatherNotifierProvider**
- **Found during:** Task 2 (tests RED fase)
- **Issue:** Riverpod 3.x code-gen genereert `weatherProvider` voor klasse `WeatherNotifier` (suffix `Notifier` wordt gestript)
- **Fix:** Test bijgewerkt om `weatherProvider` te gebruiken
- **Files modified:** test/providers/weather_notifier_test.dart
- **Verification:** Tests slagen
- **Committed in:** 67ddc86

**4. [Rule 1 - Bug] Riverpod 3.x fout-staat is AsyncLoading met hasError, niet AsyncError**
- **Found during:** Task 2 (tests GREEN fase — error-test bleef hangen)
- **Issue:** Riverpod 3.x heeft automatisch retry-gedrag. Na een fout transitieert de provider naar `AsyncLoading(hasError: true)` terwijl hij herprobeert — NIET naar `AsyncError`. De test `isA<AsyncError>()` hing oneindig.
- **Fix:** Error-test herschreven om `state.hasError == true` te controleren i.p.v. `isA<AsyncError>()`
- **Files modified:** test/providers/weather_notifier_test.dart
- **Verification:** Error-test slaagt in < 1 seconde
- **Committed in:** 67ddc86

---

**Totaal deviaties:** 4 auto-gefixed (Rule 1 bugs — allemaal Riverpod 3.x API-changes t.o.v. 2.x)
**Impact op plan:** Alle fixes noodzakelijk vanwege Riverpod 3.x vs 2.x API-wijzigingen. Functionaliteitseis (loading/data/error-test met ProviderContainer) is volledig behaald.

## Issues Encountered

Geen onverwachte blockers — alle deviaties waren Riverpod 3.x API-veranderingen die automatisch zijn opgelost.

## User Setup Required

Geen — geen externe diensten vereist.

## Next Phase Readiness

- appDatabaseProvider, openMeteoClientProvider, weatherRepositoryProvider beschikbaar voor gebruik in 03-02 (ProfileNotifier + AvailabilityNotifier)
- weatherProvider beschikbaar als upstream dependency voor SlotsNotifier in 03-03
- Letpunt voor plan 03-02/03-03: gebruik `weatherProvider` (niet `weatherNotifierProvider`) als provider-naam
- Letpunt voor plan 03-02/03-03: error-states controleren via `state.hasError` + `state.error` i.p.v. `isA<AsyncError>()`

## Self-Check: PASSED

- FOUND: .planning/phases/03-riverpod-providers-state-graph/03-01-SUMMARY.md
- FOUND: commit b0caf28 (feat(03-01): Riverpod packages + infrastructure providers)
- FOUND: commit 67ddc86 (feat(03-01): WeatherNotifier + ProviderContainer tests TDD RED→GREEN)

---
*Phase: 03-riverpod-providers-state-graph*
*Completed: 2026-06-02*
