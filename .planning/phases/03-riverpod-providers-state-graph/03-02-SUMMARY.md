---
phase: 03-riverpod-providers-state-graph
plan: 02
subsystem: state
tags: [riverpod, shared_preferences, AsyncNotifier, UserProfile, WeatherTolerances, ProviderContainer, TDD]

requires:
  - phase: 03-riverpod-providers-state-graph/03-01
    provides: flutter_riverpod 3.3.x, riverpod_annotation 4.0.x, @riverpod code-gen infrastructure
  - phase: 01.5-scoring-domain
    provides: WeatherTolerances @freezed dataklasse

provides:
  - UserProfile immutable dataklasse met tolerances, allowedDurations, theme, locationOverride, drie notif-toggles
  - ProfileNotifier als @riverpod AsyncNotifier<UserProfile> met SharedPreferences persistentie
  - profileProvider (gegenereerde provider-naam door Riverpod 3.x code-gen)
  - 4 ProviderContainer-tests: cold start defaults, persist-tolerances, toggleDuration-removes, toggleDuration-cannot-remove-last

affects: [03-03, 03-04]

tech-stack:
  added:
    - shared_preferences 2.5.5 (flutter.dev, ~2 maanden oud)
  patterns:
    - "AsyncNotifier.build() roept SharedPreferences.getInstance() aan — Riverpod cachet provider als singleton"
    - "Mutations schrijven naar SharedPreferences VOOR state update zodat dispose/re-create cyclus gegevens behoudt"
    - "toggleDuration min-1-guard: durations.length > 1 check voor verwijdering"
    - "SharedPreferences.setMockInitialValues({}) in setUp voor geïsoleerde tests"
    - "Nullable copyWith via _sentinel object patroon (geen Freezed benodigd voor UserProfile)"

key-files:
  created:
    - lib/providers/profile_notifier.dart
    - lib/providers/profile_notifier.g.dart
    - test/providers/profile_notifier_test.dart
  modified:
    - pubspec.yaml (shared_preferences ^2.5.5 toegevoegd)
    - pubspec.lock

key-decisions:
  - "UserProfile als plain Dart class met handmatige copyWith (niet Freezed) — voldoet voor scalar settings, minder boilerplate"
  - "Nullable locationOverride copyWith via _sentinel object — typecheck zonder Freezed codegen"
  - "Mutations schrijven eerst naar SharedPreferences dan state updaten — verzekert persistentie ook bij crash na write maar voor state-update"

patterns-established:
  - "ProfileNotifier profile keys: prefix 'profile.' voor alle SharedPreferences sleutels"
  - "allowedDurations opgeslagen als List<String> van int-strings in SharedPreferences"
  - "profileProvider is de gegenereerde naam (Notifier-suffix gestript door Riverpod 3.x code-gen)"

requirements-completed: [PERS-01, PROF-03]

duration: 20min
completed: 2026-06-03
---

# Phase 3 Plan 02: ProfileNotifier + UserProfile met SharedPreferences Persistentie

**ProfileNotifier als @riverpod AsyncNotifier met UserProfile die toleranties, rijduren, thema, locatie en notificatie-toggles laadt uit SharedPreferences op cold start en elke mutation direct terugschrijft**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-06-03T08:00:00Z
- **Completed:** 2026-06-03T08:20:00Z
- **Tasks:** 1 (TDD RED+GREEN)
- **Files modified:** 5

## Accomplishments

- shared_preferences 2.5.5 geinstalleerd en opgelost
- UserProfile immutable dataklasse aangemaakt met alle vereiste velden (tolerances, allowedDurations, theme, locationOverride, 3x notif-toggles)
- ProfileNotifier geimplementeerd als @riverpod AsyncNotifier<UserProfile> met build() die SharedPreferences leest
- Vier mutatiemethoden: updateTolerances, toggleDuration (min-1-guard), setTheme, setLocationOverride, setNotifEveningBefore, setNotifMorningOf, setNotifWeeklyDigest
- Alle mutaties schrijven synchroon naar SharedPreferences + state update
- 4 ProviderContainer-tests slagen: cold start defaults, persist tolerances (dispose/re-create), toggleDuration removes, toggleDuration cannot remove last
- Volledige suite: 85 tests groen (81 bestaand + 4 nieuw)
- dart analyze lib/providers/profile_notifier.dart: No issues found

## Task Commits

1. **Task 1: UserProfile dataklasse + ProfileNotifier (TDD RED→GREEN)** — `e49e116` (feat)

## Files Created/Modified

- `pubspec.yaml` — shared_preferences ^2.5.5 toegevoegd aan dependencies
- `pubspec.lock` — resolved: shared_preferences 2.5.5 + platform-specifieke pakketten
- `lib/providers/profile_notifier.dart` — UserProfile class + ProfileNotifier als @riverpod AsyncNotifier
- `lib/providers/profile_notifier.g.dart` — gegenereerde profileProvider registratie
- `test/providers/profile_notifier_test.dart` — 4 ProviderContainer-tests

## Decisions Made

- UserProfile als plain Dart class met handmatige copyWith in plaats van Freezed — UserProfile bevat geen JSON-serialisatie vereiste, en de eenvoudige immutable class met _sentinel-pattern voor nullable velden vermijdt extra code-gen complexiteit.
- Mutations schrijven eerst naar SharedPreferences, dan state updaten — verzekert dat gegevens behouden blijven ook als de app crasht na de write maar voor de state-update.
- _sentinel object patroon voor nullable `locationOverride` in copyWith — maakt onderscheid tussen "niet opgegeven" en "expliciet null".

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Code Quality] Fix doc comment HTML en trailing comma**
- **Found during:** Task 1 (dart analyze)
- **Issue:** Doc comment bevatte `List<int>` (HTML angle brackets), en missing trailing comma in setStringList aanroep
- **Fix:** Doc comment omgezet naar backtick syntax; trailing comma toegevoegd
- **Files modified:** lib/providers/profile_notifier.dart
- **Verification:** dart analyze meldt No issues found
- **Committed in:** e49e116 (onderdeel van task commit)

---

**Totaal deviaties:** 1 auto-fixed (Rule 1 — code quality, geen functionele impact)
**Impact op plan:** Minimaal — alleen docs en style fix. Alle functionaliteitseisen behaald.

## Issues Encountered

Geen onverwachte blockers — plan uitgevoerd zoals beschreven zonder Riverpod API-verrassingen (profijtend van lessen in 03-01 over Riverpod 3.x naamgeving).

## Threat Model Coverage

T-03-06 (SharedPreferences.getInstance() faalt — DoS): ProfileNotifier.build() is async; bij failure geeft Riverpod AsyncError terug — UI kan foutstate tonen. Niet crashend. Covered.

## User Setup Required

Geen — geen externe diensten vereist.

## Next Phase Readiness

- profileProvider beschikbaar voor gebruik in 03-03 (SlotsNotifier) en 03-04 (AvailabilityNotifier)
- SlotsNotifier (03-03) kan `ref.watch(profileProvider)` gebruiken om tolerances en allowedDurations te lezen
- Letpunt voor 03-03: profileProvider is een AsyncNotifier — gebruik `.when()` om loading/data/error te handelen
- UserProfile.tolerances en UserProfile.allowedDurations zijn de upstream inputs voor SlotGenerator

## Self-Check: PASSED

- FOUND: .planning/phases/03-riverpod-providers-state-graph/03-02-SUMMARY.md
- FOUND: commit e49e116 (feat(03-02): ProfileNotifier + UserProfile with SharedPreferences persistence)
- FOUND: lib/providers/profile_notifier.dart
- FOUND: lib/providers/profile_notifier.g.dart
- FOUND: test/providers/profile_notifier_test.dart

---
*Phase: 03-riverpod-providers-state-graph*
*Completed: 2026-06-03*
