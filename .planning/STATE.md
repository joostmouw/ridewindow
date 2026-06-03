---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: "Completed 04-02-PLAN.md — go_router 17.3.0 + config.dart + LocationProvider stub + availability_presets + GoRouter onboarding redirect (commits f859557, 675c25f)"
last_updated: "2026-06-03T07:28:00.000Z"
last_activity: 2026-06-03 -- Phase 04 Plan 02 complete
progress:
  total_phases: 11
  completed_phases: 4
  total_plans: 19
  completed_plans: 15
  percent: 37
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-01)

**Core value:** Accurate cyclist-specific weather scoring translated into concrete bookable time slots
**Current focus:** Phase 04 — ui-phase-a-onboarding-home-welcome

## Current Position

Phase: 04 (ui-phase-a-onboarding-home-welcome) — EXECUTING
Plan: 3 of 5
Status: Executing Phase 04
Last activity: 2026-06-03 -- Phase 04 Plan 02 complete

Progress: [████████░░] 80%

## Performance Metrics

**Velocity:**

- Total plans completed: 10 (Phases 1, 1.5, 2)
- Average duration: ~15min voor mechanische taken (geautomatiseerd executor-modus)
- Total execution time: ~3h (Phase 1) + ~45min (Phase 1.5) + ~40min (Phase 2)

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 3 | ~3h | ~1h |
| 1.5 | 4 | ~45min | ~11min |
| 2 | 3 | ~40min | ~13min |

**Recent Trend:**

- Last plan: 02-03 — groen, single-attempt, WeatherRepository cache policy
- Trend: Geautomatiseerde executor verwerkt mechanische infra-taken goed

| Phase 03-riverpod-providers-state-graph P01 | 25 | 2 tasks | 8 files |
| Phase 03-riverpod-providers-state-graph P02 | 20 | 1 task | 5 files |
| Phase 03-riverpod-providers-state-graph P03 | 35 | 2 tasks | 6 files |
| Phase 03-riverpod-providers-state-graph P04 | 15 | 2 tasks | 2 files |

## Accumulated Context

### Decisions

Beslissingen zijn gelogd in PROJECT.md Key Decisions tabel.
Recente beslissingen die het huidige werk beinvloeden:

- Roadmap geherstructureerd 2026-06-02: originele Phase 1 (skeleton + scoring) gesplitst in Phase 1 (skeleton only) + Phase 1.5 (scoring domain).
- Flutter test vereist (niet dart test) voor tests die AppDatabase importeren — drift_flutter trekt dart:ui mee; NativeDatabase.memory() direct doorgeven als QueryExecutor (DatabaseConnection wrapper niet nodig in Drift 2.x).
- Plan 02-03: mockito ^5.6.4 (niet ^5.7.0 — analyzer-versieconflict met drift_dev 2.33.0).
- Phase 3 planning (2026-06-02): riverpod_generator ^2.6.5 + riverpod_annotation ^4.0.2 + flutter_riverpod ^3.3.1 toegevoegd; shared_preferences ^2.5.5 voor ProfileNotifier en AvailabilityNotifier.
- Riverpod 3.0 patroon: gebruik @riverpod annotatie (code-gen), AutoDisposeNotifier is nu gewoon Notifier (auto-dispose is default), StateProvider/StateNotifierProvider zijn legacy — niet gebruiken.
- SlotsEmptyReason sealed enum gekozen voor SLOT-05 expliciete empty state (badWeather | allBlocked).
- AvailabilityNotifier: SharedPreferences-aanpak als fallback als Drift-tabel ontbreekt (te controleren in 03-03).
- 03-01 (2026-06-02): riverpod_generator ^4.0.4-dev.1 vereist (plan: ^2.6.5) — 2.x reeks incompatibel met riverpod_annotation 4.0.2.
- 03-01 (2026-06-02): Riverpod 3.x gegenereerde provider-naam voor WeatherNotifier is weatherProvider (Notifier-suffix gestript door code-gen).
- 03-01 (2026-06-02): Riverpod 3.x error-staat is AsyncLoading(hasError: true) door auto-retry — test checkt state.hasError ipv isA<AsyncError>().
- 03-01 (2026-06-02): Ref-parameter in Riverpod 3.x provider-functies is plain Ref (niet typed XxxRef).
- 03-02 (2026-06-03): UserProfile als plain Dart class met _sentinel-pattern voor nullable copyWith — geen Freezed benodigd voor scalar settings dataklasse.
- 03-02 (2026-06-03): profileProvider is de gegenereerde naam voor ProfileNotifier (Notifier-suffix gestript door Riverpod 3.x code-gen).
- 03-03 (2026-06-03): AvailabilityNotifier gebruikt SharedPreferences — AvailabilityGridEntries tabel slaat dayOfWeek+hour weekpatroon op, niet DateTime-instanties.
- 03-03 (2026-06-03): availabilityProvider en slotsProvider zijn de gegenereerde namen (Notifier-suffix gestript door code-gen).
- 03-03 (2026-06-03): Fake notifiers in ProviderContainer-tests moeten concrete klassen extenden (WeatherNotifier), niet de _$-abstracte klassen.
- 03-03 (2026-06-03): SlotsNotifier als synchrone Notifier<SlotsState> — build() gebruikt ref.watch() synchroon; geen AsyncNotifier nodig.
- 03-04 (2026-06-03): FakeNotifier-subclasses (extends WeatherNotifier) gekozen boven mockito voor integratietests — simpeler, state direct injecteerbaar via .state = AsyncData(...).
- 03-04 (2026-06-03): ProviderScope op buitenste runApp-niveau — gereed voor ConsumerWidget gebruik in Phase 4.
- 04-01 (2026-06-03): BlockType enum in availability_notifier.dart (niet apart bestand) — eenvoudiger voor Phase 4; refactor in Phase 6 indien nodig.
- 04-01 (2026-06-03): domain→providers import richting in availability_filter.dart geaccepteerd per PATTERNS.md notitie (tijdelijk, Phase 6 refactor).
- 04-01 (2026-06-03): try-catch around SharedPreferences deserialization voor T-04-01: corrupt entries worden overgeslagen (log + skip).
- 04-02 (2026-06-03): go_router resolved to 17.3.0 (plan specified ^17.2.3 — semver compatible, accepted).
- 04-02 (2026-06-03): buildPreset assert enforces weekStart.weekday == DateTime.monday; test date fixed from DateTime(2026,6,9) [Tuesday] to DateTime(2026,6,8) [Monday].
- 04-02 (2026-06-03): Stub screen classes (_WelcomeScreenStub etc.) in router.dart allow file to compile before Wave 3 creates real screens; replace in 04-03.

### Pending Todos

- **Trim GSD config voor Phase 1.5 planning** — zet research, plan_check, verifier, etc. uit in .planning/config.json. Besproken met gebruiker; uitgesteld.
- **GitHub remote setup** — push project naar private GitHub-repo voor tweede computer. Uitgesteld.

### Blockers/Concerns

- Phase 9 (Google Calendar): Vereist Google Cloud project setup, OAuth consent screen, en SHA-1 fingerprint registratie. Flag dit bij afsluiting Phase 8.
- Phase 8 (Notifications): Must test on Samsung/Xiaomi physical devices for WorkManager OEM reliability.
- Phase 10 (Release): Android Studio + accepted SDK licenses must be installed before `flutter build appbundle` works.
- Phase 3 notitie (opgelost 03-03): AvailabilityNotifier gebruikt SharedPreferences — de Drift AvailabilityGridEntries tabel slaat een weekpatroon op (dayOfWeek+hour), niet DateTime-instanties. SharedPreferences met ISO-8601 serialisatie is de juiste aanpak.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Tooling | Android Studio + Android SDK + accepted licenses | Deferred to Phase 10 | 2026-06-02 (Plan 01-01) |
| Verification | Package legitimacy audit (manual pub.dev check) | Skipped (covered by CLAUDE.md) | 2026-06-02 (Plan 01-01 Task 2) |
| Infra | GitHub remote + private repo | Pending | 2026-06-02 |

## Session Continuity

Last session: 2026-06-03T07:28:00Z
Stopped at: Completed 04-02-PLAN.md — go_router 17.3.0 + config.dart + LocationProvider stub + availability_presets + GoRouter onboarding redirect (commits f859557, 675c25f)
Resume file: None
Next action: Execute 04-03-PLAN.md — WelcomeScreen + OnboardingScreen + AvailabilityScreen stub + router real imports
