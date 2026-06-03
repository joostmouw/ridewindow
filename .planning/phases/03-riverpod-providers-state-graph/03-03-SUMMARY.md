---
phase: 03-riverpod-providers-state-graph
plan: 03
subsystem: state
tags: [riverpod, shared_preferences, AsyncNotifier, Notifier, SlotsState, AvailabilityNotifier, SlotsNotifier, ProviderContainer, TDD, sealed-class]

requires:
  - phase: 03-riverpod-providers-state-graph/03-01
    provides: weatherProvider (WeatherNotifier), appDatabaseProvider, flutter_riverpod 3.3.x
  - phase: 03-riverpod-providers-state-graph/03-02
    provides: profileProvider (ProfileNotifier), UserProfile, WeatherTolerances
  - phase: 01.5-scoring-domain
    provides: ScoringEngine, SlotGenerator, AvailabilityFilter, RideSlot, HourlyScore, HourlyForecast

provides:
  - AvailabilityNotifier als @riverpod AsyncNotifier<Set<DateTime>> (availabilityProvider)
  - SlotsNotifier als @riverpod Notifier<SlotsState> (slotsProvider)
  - SlotsState sealed class met SlotsLoaded en SlotsEmptyReason (badWeather, allBlocked)
  - 4 AvailabilityNotifier-tests en 4 SlotsNotifier-tests via ProviderContainer

affects: [03-04, 04-home-screen, 05-availability-calendar]

tech-stack:
  added: []
  patterns:
    - "AvailabilityNotifier gebruikt SharedPreferences als fallback voor Drift-tabel die DateTime-instanties opslaat"
    - "SlotsNotifier als synchrone Notifier<SlotsState> watcht drie AsyncValue-providers reactief — geen handmatige refresh"
    - "Fake notifiers in tests extenden de concrete klasse (WeatherNotifier, ProfileNotifier, AvailabilityNotifier) voor overrideWith-compatibiliteit"
    - "SlotsEmptyReason sealed enum maakt UI-onderscheid tussen badWeather en allBlocked"
    - "ScoringEngine/SlotGenerator/AvailabilityFilter zijn pure-Dart singletons als static fields in SlotsNotifier"

key-files:
  created:
    - lib/providers/availability_notifier.dart
    - lib/providers/availability_notifier.g.dart
    - lib/providers/slots_notifier.dart
    - lib/providers/slots_notifier.g.dart
    - test/providers/availability_notifier_test.dart
    - test/providers/slots_notifier_test.dart

key-decisions:
  - "AvailabilityNotifier gebruikt SharedPreferences (niet Drift) — AvailabilityGridEntries tabel slaat dayOfWeek+hour op (weekpatroon), niet DateTime-instanties. SharedPreferences is de juiste aanpak voor Set<DateTime> persistentie"
  - "SlotsNotifier als Notifier<SlotsState> (synchronous) in plaats van AsyncNotifier — build() gebruikt ref.watch() wat synchronisch werkt; geen Future nodig"
  - "Fake notifiers extenden concrete klassen (WeatherNotifier etc.) voor overrideWith — Riverpod 3.x overrideWith factory moet exact het geconcrete type retourneren"
  - "SlotsEmptyReason wordt bepaald door removeHiddenPoor() te checken voordat blocked-filter wordt toegepast — onderscheidt 'geen goede slots' van 'geblokkeerd'"

patterns-established:
  - "availabilityProvider is de gegenereerde naam (Notifier-suffix gestript door Riverpod 3.x code-gen)"
  - "slotsProvider is de gegenereerde naam (Notifier-suffix gestript door Riverpod 3.x code-gen)"
  - "Fake notifiers voor ProviderContainer-tests: extend concrete notifier klasse, override build()"
  - "SharedPreferences sleutel voor availability: 'availability.blockedHours'"

requirements-completed: [SLOT-05, AVAIL-04, PROF-03]

duration: 35min
completed: 2026-06-03
---

# Phase 3 Plan 03: SlotsNotifier + AvailabilityNotifier — Reactieve Provider Chain

**SlotsNotifier (Notifier) watcht weatherProvider + profileProvider + availabilityProvider reactief en recomputed de gefilterde `List<RideSlot>` met sealed `SlotsState` voor expliciete empty-state; AvailabilityNotifier (AsyncNotifier) persisteert `Set<DateTime>` naar SharedPreferences**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-06-03T00:11:57Z
- **Completed:** 2026-06-03T00:46:00Z
- **Tasks:** 2 (beide TDD RED→GREEN)
- **Files modified:** 6

## Accomplishments

- AvailabilityNotifier geimplementeerd als @riverpod AsyncNotifier<Set<DateTime>> met SharedPreferences persistentie
- SlotsNotifier geimplementeerd als @riverpod Notifier<SlotsState> die reactief weather, profiel en availability watcht
- SlotsState sealed class met SlotsLoaded en SlotsEmptyReason (badWeather, allBlocked) gedefinieerd
- 8 nieuwe ProviderContainer-tests slagen (4 availability + 4 slots)
- Volledige suite: 93 tests groen (85 bestaand + 8 nieuw)
- dart analyze lib/providers/ meldt geen issues
- Geen handmatige refresh/invalidate calls — puur reactief via ref.watch()

## Task Commits

1. **Task 1: AvailabilityNotifier — SharedPreferences persistentie (TDD RED→GREEN)** — `1d8f946` (feat)
2. **Task 2: SlotsNotifier — reactieve provider chain (TDD RED→GREEN)** — `df8df6b` (feat)

## Files Created/Modified

- `lib/providers/availability_notifier.dart` — AvailabilityNotifier als @riverpod AsyncNotifier met toggleHour + clearAll
- `lib/providers/availability_notifier.g.dart` — gegenereerde availabilityProvider registratie
- `lib/providers/slots_notifier.dart` — SlotsNotifier + SlotsState sealed class + SlotsEmptyReason
- `lib/providers/slots_notifier.g.dart` — gegenereerde slotsProvider registratie
- `test/providers/availability_notifier_test.dart` — 4 ProviderContainer-tests voor AvailabilityNotifier
- `test/providers/slots_notifier_test.dart` — 4 ProviderContainer-tests voor SlotsNotifier

## Decisions Made

- **SharedPreferences voor AvailabilityNotifier:** De bestaande Drift `AvailabilityGridEntries` tabel slaat `dayOfWeek` + `hour` op (weekpatroon voor herhaalbare blokkades), niet specifieke `DateTime`-instanties. Voor `Set<DateTime>` persistentie is SharedPreferences met ISO-8601 serialisatie de juiste aanpak.
- **Synchrone Notifier voor SlotsNotifier:** `build()` gebruikt `ref.watch()` wat synchronisch is in Riverpod — geen Future nodig. `Notifier<SlotsState>` geeft schonere code zonder `.when()` ceremony.
- **Fake notifiers extenden concrete klassen:** In Riverpod 3.x moet de `overrideWith` factory exact het geconcrete type retourneren. `FakeWeatherNotifier extends WeatherNotifier` (niet `_$WeatherNotifier`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fake notifiers moeten concrete klassen extenden, niet abstracte _$-klassen**
- **Found during:** Task 2 (TDD RED fase — tests compileerfout)
- **Issue:** Plan-pseudocode gebruikte `FakeWeatherNotifier extends _$WeatherNotifier`, maar in Riverpod 3.x moet `overrideWith` factory exact het geconcrete type teruggeven (`WeatherNotifier`, niet `_$WeatherNotifier`). Dart compile-fout: "A value of type 'FakeWeatherNotifier' can't be returned from a function with return type 'WeatherNotifier'."
- **Fix:** Alle Fake notifiers aangepast om de concrete klassen te extenden (`WeatherNotifier`, `ProfileNotifier`, `AvailabilityNotifier`)
- **Files modified:** test/providers/slots_notifier_test.dart
- **Verification:** Tests compileren en slagen
- **Committed in:** df8df6b (Task 2 commit)

**2. [Rule 1 - Code Quality] Doc comment HTML angle brackets in availability_notifier.dart**
- **Found during:** Task 1 (dart analyze)
- **Issue:** Doc comment bevatte `Set<DateTime>` als HTML angle brackets
- **Fix:** Omgezet naar backtick syntax `` `Set<DateTime>` ``
- **Files modified:** lib/providers/availability_notifier.dart
- **Verification:** dart analyze meldt No issues found
- **Committed in:** 1d8f946 (Task 1 commit)

---

**Totaal deviaties:** 2 auto-fixed (Rule 1 — beide correctheids-fixes)
**Impact op plan:** Beide fixes noodzakelijk. De Riverpod 3.x Fake-notifier fix is een patroon-correctie die toekomstige testcodes ten goede komt.

## Issues Encountered

Geen onverwachte blockers. De Riverpod 3.x `overrideWith` Fake-notifier issue was verwacht gezien de lessen uit 03-01/03-02 over Riverpod 3.x API-wijzigingen.

## Threat Model Coverage

- T-03-10 (DoS — frequente recomputation): WeatherRepository heeft 1-uur cache-beleid (Phase 2). SlotsNotifier recomputed maximaal één keer per uur via normale flow. Covered.
- T-03-09 (Information Disclosure — DateTime-opslag): Beschikbaarheidspatronen zijn geen gevoelige PII. Opgeslagen als ISO-8601 strings in SharedPreferences. Accept.

## User Setup Required

Geen — geen externe diensten vereist.

## Next Phase Readiness

- slotsProvider beschikbaar voor gebruik in 03-04 (home screen UI binding)
- availabilityProvider beschikbaar voor 05-availability-calendar
- De volledige provider-keten weather → profiel + availability → slots is reactief en aantoonbaar getest
- Letpunt voor 03-04: gebruik `slotsProvider` (niet `slotsNotifierProvider`) — Riverpod 3.x strippt Notifier-suffix
- Letpunt voor UI: SlotsState is sealed — gebruik patroonmatching: `switch (state) { case SlotsLoaded(:final slots): ... }`
- SlotsEmptyReason.badWeather en allBlocked zijn beschikbaar voor informatieve UI-feedback

## Self-Check: PASSED

- FOUND: .planning/phases/03-riverpod-providers-state-graph/03-03-SUMMARY.md
- FOUND: commit 1d8f946 (feat(03-03): AvailabilityNotifier — SharedPreferences persistentie)
- FOUND: commit df8df6b (feat(03-03): SlotsNotifier — reactieve provider chain)
- FOUND: lib/providers/availability_notifier.dart
- FOUND: lib/providers/availability_notifier.g.dart
- FOUND: lib/providers/slots_notifier.dart
- FOUND: lib/providers/slots_notifier.g.dart
- FOUND: test/providers/availability_notifier_test.dart
- FOUND: test/providers/slots_notifier_test.dart

---
*Phase: 03-riverpod-providers-state-graph*
*Completed: 2026-06-03*
