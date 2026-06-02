# Walking Skeleton — RideWindow

**Phase:** 1
**Generated:** 2026-06-02

## Capability Proven End-to-End

A developer can run `flutter run` on the RideWindow project and see an empty Material 3 `Scaffold` boot on an Android emulator, while `dart test` exercises the entire pure-Dart scoring + slot domain (sub-scores, aggregation, slot generation, availability filtering) with 100% line coverage of `lib/domain/`.

## Scoped Interpretation (Phase 1 — Domain Foundation)

This phase is deliberately a **domain-only** walking skeleton per CONTEXT.md `<domain>` section. The "skeleton" is:

- Flutter project boots (`flutter run` shows minimal `MaterialApp`)
- Domain layer fully implemented (Freezed models + pure-Dart scoring/slot services)
- `dart test` green; 100% line coverage of `lib/domain/`
- Zero network, zero DB, zero UI surface beyond an empty scaffold

I/O (Phase 2), Riverpod providers (Phase 3), and real UI (Phase 4+) build on this foundation **without renegotiating** the architectural decisions below.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Flutter 3.x (stable) + Dart 3.x | Locked in CLAUDE.md; Material 3 default since 3.16; cross-platform readiness for iOS v2 |
| Project layout | Feature-first under `lib/`: `core/`, `domain/`, `data/`, `features/`, `platform/` | ARCHITECTURE.md canonical tree; populated only under `lib/domain/` in Phase 1 |
| Domain isolation | Pure Dart in `lib/domain/`; structural test grep-bars `package:flutter`, `dart:io`, `package:http`, `package:drift`, etc. | SCOR-03 requires `dart test` runnability; T-1-01 prevents containment violations leaking into Phases 2+ |
| Data models | Freezed 3.x `abstract class Foo with _$Foo` + generated `.freezed.dart` / `.g.dart` committed | CLAUDE.md locked stack; avoids Phase 2 refactor; JSON ready for Open-Meteo deserialization in Phase 2 |
| Sum types | Hand-written `sealed class RideTier` with `Perfect` / `Great` / `Acceptable` / `Poor` final subclasses | CLAUDE.md locked; exhaustive switch via Dart 3 pattern matching beats stringly-typed enums |
| Aggregation | `overall = 0.6·min(t,r,w) + 0.4·mean(t,r,w)` (D-14) | Hybrid catches killer factors while rewarding near-balanced days (D-15 rationale) |
| Slot convention | `[start, end)` exclusive end (D-19) | Matches Dart `DateTime` arithmetic; documented on `RideSlot.end`; property-tested |
| Null policy | Each sub-score clamps to 50/100 when primary input null; aggregation has no special case (D-25, D-26) | SCOR-04 requires no crash, no 0-coercion; PITFALLS.md Pitfall 4 |
| Test framework | `package:test` (NOT `flutter_test`) for `lib/domain/` | Guarantees no Flutter loader; tests fail to compile if domain accidentally imports Flutter |
| Coverage | `dart test --coverage=coverage` → `dart run coverage:format_coverage --lcov --report-on=lib/domain` → `lcov --remove` strips `*.freezed.dart`/`*.g.dart` → 100% gate | dart-lang/sdk#60958 documents the JSON-vs-lcov divergence; this is the documented bridge |
| Code generation | `dart run build_runner build --delete-conflicting-outputs`; generated files COMMITTED to git | Solo-dev devloop: fresh clone runs tests immediately without build_runner step |
| Android target only | `flutter create --platforms=android --org=com.fanalists.ridewindow` | Locked in PROJECT.md; no `ios/`, `web/`, `linux/`, `macos/`, `windows/` scaffolded |
| Linting | `flutter_lints` baseline; no `custom_lint`/`import_lint` in Phase 1 | One rule ("no flutter under lib/domain/") is cheaper as a grep test than an analyzer plugin |

## Stack Touched in Phase 1

- [x] Project scaffold (`flutter create` → `pubspec.yaml`, `analysis_options.yaml`, `android/`, `lib/`, `test/`)
- [x] Test runner (`dart test` proven on Flutter package via smoke spike before further work)
- [x] Code generation pipeline (`dart run build_runner build` produces committed Freezed sources)
- [x] Pure-Dart domain layer (models + services with 100% coverage)
- [x] Coverage tooling (`tool/test_with_coverage.sh` enforces 100% lib/domain/ gate)
- [x] Minimal UI surface (`lib/main.dart` boots empty Material 3 `Scaffold` — proves the host app compiles and runs)
- [ ] Real routing — DEFERRED to Phase 4 (go_router)
- [ ] Database — DEFERRED to Phase 2 (Drift schema + migrations)
- [ ] Network — DEFERRED to Phase 2 (Open-Meteo `http` client)
- [ ] Interactive UI — DEFERRED to Phase 4+ (mockup.html)

## Out of Scope (Deferred to Later Slices)

- Weather fetching (Open-Meteo `http` client) — **Phase 2**
- Persistence (Drift schema, ProfileRepository, ForecastCache) — **Phase 2**
- Riverpod providers + state graph — **Phase 3**
- Welcome / Onboarding / Home screens — **Phase 4**
- Ride Detail + Insights sheet — **Phase 5**
- Profile / Availability / Tolerance sliders — **Phase 6**
- GPS + city picker + permission state machine — **Phase 7**
- WorkManager + notifications — **Phase 8**
- Google Calendar OAuth — **Phase 9**
- Release AAB + Play Console — **Phase 10**
- CI / GitHub Actions — Phase 10 release prep
- Property-based testing (`glados`) — example-based suffices for Phase 1
- `precipitation_probability` weighting — Phase 2/3 when real data flows
- `winddirection_10m` headwind handling — out of v1 (PROJECT.md "no route planning")

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this domain foundation without altering its architectural decisions:

- **Phase 2:** Drift schema + Open-Meteo client + WeatherRepository (1h cache); domain models gain `fromJson` consumers via existing Freezed `.g.dart` files.
- **Phase 3:** Riverpod 3 providers — WeatherNotifier, SlotsNotifier (composes Phase 1 ScoringEngine + SlotGenerator + AvailabilityFilter), ProfileNotifier, AvailabilityNotifier.
- **Phase 4:** Welcome / Onboarding / Home screens consuming providers via `ref.watch`. Material 3 default theming.
- **Phase 5:** Ride Detail + "Why this score?" InsightsSheet rendering sub-scores from Phase 1's `HourlyScore`.
- **Phase 6:** Profile screen + Tolerance sliders (stretch `WeatherTolerances` shoulder edges per D-12); Availability grid editor.
- **Phase 7:** GPS via geolocator + city picker fallback + permission state machine; replaces Amsterdam hardcode.
- **Phase 8:** WorkManager periodic refresh + flutter_local_notifications (3 notification types).
- **Phase 9:** Lazy Google OAuth + Calendar event creation.
- **Phase 10:** Signed AAB + Play Console internal testing track.
