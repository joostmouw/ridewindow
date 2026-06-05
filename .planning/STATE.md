---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Completed 10-01-PLAN.md — Android SDK + applicationId ridewindow.joost.amsterdam + upload keystore + release signing config + .gitignore hardening + version 1.0.0+1
last_updated: "2026-06-05T20:32:09.204Z"
last_activity: 2026-06-05 -- Plan 10-02 Task 1 completed (signed release AAB 56.5MB + APK 58.0MB built with obfuscation)
progress:
  total_phases: 12
  completed_phases: 10
  total_plans: 43
  completed_plans: 40
  percent: 85
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-01)

**Core value:** Accurate cyclist-specific weather scoring translated into concrete bookable time slots
**Current focus:** Phase 10 — release-internal-track-only

## Current Position

Phase: 10 (release-internal-track-only) — EXECUTING
Plan: 2 of 4 (Task 2 awaiting human action)
Status: Executing Phase 10 (Plan 02 Task 1 complete; waiting for physical device smoke test)
Last activity: 2026-06-05 -- Plan 10-02 Task 1 completed (signed release AAB 56.5MB + APK 58.0MB built with obfuscation)

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 12 (Phases 1, 1.5, 2)
- Average duration: ~15min voor mechanische taken (geautomatiseerd executor-modus)
- Total execution time: ~3h (Phase 1) + ~45min (Phase 1.5) + ~40min (Phase 2)

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 3 | ~3h | ~1h |
| 1.5 | 4 | ~45min | ~11min |
| 2 | 3 | ~40min | ~13min |
| 9 | 2 | - | - |

**Recent Trend:**

- Last plan: 02-03 — groen, single-attempt, WeatherRepository cache policy
- Trend: Geautomatiseerde executor verwerkt mechanische infra-taken goed

| Phase 03-riverpod-providers-state-graph P01 | 25 | 2 tasks | 8 files |
| Phase 03-riverpod-providers-state-graph P02 | 20 | 1 task | 5 files |
| Phase 03-riverpod-providers-state-graph P03 | 35 | 2 tasks | 6 files |
| Phase 03-riverpod-providers-state-graph P04 | 15 | 2 tasks | 2 files |
| Phase 06 P02 | 3min | 2 tasks | 1 files |
| Phase 06 P04 | 8 | 2 tasks | 2 files |
| Phase 08-background-refresh-notifications P03 | 8 | 1 tasks | 1 files |
| Phase 08-background-refresh-notifications P04 | 5min | 2 tasks | 2 files |
| Phase 09-google-calendar-integration P01 | 20min | 2 tasks | 4 files |
| Phase 09-google-calendar-integration P02 | 10min | 2 tasks | 4 files |

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
- 04-03 (2026-06-03): _PresetOption plain Dart class chosen over Dart 3 records — simpler, named fields, avoids positional access syntax.
- 04-03 (2026-06-03): Dashed border for custom preset via _DashedBorderPainter CustomPainter — Flutter Border API does not support BorderStyle.dashed.
- 04-03 (2026-06-03): _HomeScreenPlaceholder retained in router.dart; Wave 4 (04-04) replaces with real HomeScreen import.
- 04-04 (2026-06-03): Weather chip values are placeholder "?°C / ?mm / ?km/u" — HourlyForecast data not directly accessible from RideSlot; Phase 5 will wire real data.
- 04-04 (2026-06-03): HomeScreen uses SingleTickerProviderStateMixin for skeleton pulse AnimationController — no shimmer package needed.
- 04-04 (2026-06-03): Day selection uses year+month+day triple comparison to avoid cross-month false matches.
- 04-05 (2026-06-03): tester.pump(Duration) used instead of pumpAndSettle in HomeScreen tests — AnimationController.repeat() causes pumpAndSettle to timeout.
- 04-05 (2026-06-03): FakeStaticSlotsNotifier omits ref.watch calls to bypass upstream provider initialization in widget tests.
- 04-05 (2026-06-03): HomeScreen._buildHeader Container color+decoration bug fixed — Container cannot have both color and decoration properties simultaneously.
- 05-01 (2026-06-03): HourlyRow is plain Dart class (no Freezed) — Phase-5-only view model merging HourlyScore + HourlyForecast by time.
- 05-01 (2026-06-03): DetailArgs uses const constructor — immutable DTO safe for go_router extra.
- 05-01 (2026-06-03): T-05-01 mitigated: router uses 'is! DetailArgs' guard before cast, returns error Scaffold for invalid navigation.
- 05-01 (2026-06-03): Weather chips show avg temp (1 decimal), total precip (1 decimal), avg wind (0 decimal); '—' when no data.
- 05-01 (2026-06-03): Forecast filtering uses !f.time.isBefore(slot.start) && f.time.isBefore(slot.end) per SLOT-02 [start, end) convention.
- 05-02 (2026-06-03): ScoreBadge widget embedded in score-banner alongside tier emoji + description text (key_links requirement in plan).
- 05-02 (2026-06-03): Inline tier switch expressions for banner colors/emoji/description — no separate helper class needed.
- 05-02 (2026-06-03): Empty-slot guard returns '—' for all avg fields when forecasts list is empty (T-05-02-02 mitigated).
- 05-03 (2026-06-03): SingleChildScrollView wraps InsightsSheet Column to prevent RenderFlex overflow in constrained viewports (bottom sheet height varies by device/test).
- 05-03 (2026-06-03): _avg() returns 50.0 for empty hours list — divide-by-zero prevented per T-05-03-01.
- 05-03 (2026-06-03): LinearProgressIndicator value uses .clamp(0.0, 1.0) as defense-in-depth per T-05-03-02.
- 05-04 (2026-06-03): Existing test files from Waves 2+3 already covered plan requirements; only the SC-4 ScoringEngine fixture pin was missing — added 1 targeted test to insights_sheet_test.dart.
- 05-04 (2026-06-03): ScoringEngine fixture pin uses closeTo(1.0, 0.0001) for double comparison safety; calls ScoringEngine().score() directly (no mocks) to prove domain-widget wiring.
- 06-01 (2026-06-03): AsyncValue.value (not .valueOrNull) is the correct nullable getter in Riverpod 3.x — valueOrNull does not exist in the 3.x API.
- 06-01 (2026-06-03): ProfileScreen Wave 1 skeleton uses // ignore: unused_field on late double slider fields — Wave 2 will fill them; suppress avoids analyzer warnings.
- 06-01 (2026-06-03): darkTheme uses same seedColor 0xFF2E7D32 with brightness: Brightness.dark; MaterialApp.router now has darkTheme + themeMode: ref.watch(themeModeProvider).
- 06-02 (2026-06-03): Explicit FilterChip widgets (3 separate) over for-loop — grep -c verification requires 3 text occurrences of FilterChip in source.
- 06-02 (2026-06-03): WeatherTolerances import not needed in ProfileScreen — copyWith() accessible via profile.tolerances instance (generated by Freezed on the class).
- 06-02 (2026-06-03): Trailing comma required after updateTolerances(tolerances.copyWith(...),) by require_trailing_commas lint rule.
- 06-03 (2026-06-03): GestureDetector count is 169 (not 168) — BackButton and horizontal SingleChildScrollView each add a GestureDetector; test uses findsAtLeastNWidgets(168).
- 06-03 (2026-06-03): SharedPreferences mock resolves synchronously in Flutter tests — AvailabilityNotifier never stays AsyncLoading; loading-state CircularProgressIndicator test is unreliable.
- [Phase ?]: 06-04: skipOffstage: false required for cell-color container search in scrollable availability grid
- [Phase ?]: 06-04: Tap-guard test uses hour 0 cell (visible in viewport) instead of hour 9 (off-screen) for reliable tester.tap() interaction
- 07-01 (2026-06-03): geolocator 14.0.2 + permission_handler 12.0.3 added; compileSdk = 35 override in build.gradle.kts (D-07-11)
- 07-01 (2026-06-03): kNlCities const list with 12 NL cities in lib/core/nl_cities.dart (D-07-05)
- 07-01 (2026-06-03): Used // comment (not ///) for nl_cities.dart header to avoid dangling_library_doc_comments lint info
- 07-02 (2026-06-03): GpsPermissionNotifier as AsyncNotifier<LocationPermission> with gpsPermissionProvider generated name (D-07-03)
- 07-02 (2026-06-03): LocationNotifier replaces stub — three-step priority: profile override > GPS > Amsterdam default (LOC-02, LOC-04, LOC-05)
- 07-02 (2026-06-03): HomeScreen updated to handle AsyncValue<LocationData> via .value?.city — locationProvider changed from sync to async (Rule 3 fix)
- 07-03 (2026-06-03): .value (niet .valueOrNull) is correcte nullable getter in Riverpod 3.x; bevestigt STATE.md 06-01 beslissing
- 07-03 (2026-06-03): skipOffstage: false vereist in ProfileScreen widget tests — LOCATIE sectie zorgt dat RIJLENGTE/THEMA buiten test-viewport rolt in scrollbare ListView
- 07-03 (2026-06-03): FakeLocationNotifier extends LocationNotifier toegevoegd aan weather_notifier_test — WeatherNotifier watchet locationProvider; ProviderContainer tests vereisen override
- 07-03 (2026-06-03): anyNamed() matcher in mockito voor named parameters na getForecast({lat, lon}) signature uitbreiding
- 07-04 (2026-06-03): HomeScreen dynamische locatienaam reeds geimplementeerd in Wave 2 als Rule 3 auto-fix — locationAsync.value?.city ?? kDefaultCity
- 07-04 (2026-06-03): kDefaultCity ('Amsterdam') als fallback tijdens AsyncLoading — consistenter dan literal '...' uit plan specificatie
- 07-05 (2026-06-03): FakeWeatherNotifier lokaal gedefinieerd in profile_screen_location_test — ProfileScreen vereist weatherProvider override om te bouwen
- 07-05 (2026-06-03): HomeScreen Test 2 verifieert 'Amsterdam' (kDefaultCity) i.p.v. '...' — conform implementatie beslissing 07-04
- 07-05 (2026-06-03): Completer<void>().future voor permanente AsyncLoading simulatie — betrouwbaarder dan Future.delayed
- 08-01 (2026-06-03): workmanager ^0.9.0+3 + flutter_local_notifications ^21.0.0 + timezone ^0.11.0 + flutter_timezone ^5.1.0 toegevoegd aan pubspec.yaml; flutter pub get geslaagd
- 08-01 (2026-06-03): AndroidManifest.xml: RECEIVE_BOOT_COMPLETED + SCHEDULE_EXACT_ALARM + POST_NOTIFICATIONS + FOREGROUND_SERVICE + WAKE_LOCK permissies; WorkManager SystemForegroundService + RescheduleOnBootReceiver; ride_alerts notificatiekanaal meta-data
- 08-01 (2026-06-03): SCHEDULE_EXACT_ALARM gedeclareerd — Android 12+ vereist expliciete gebruikerstoestemming via systeeminstellingen (T-08-01-02)
- 08-02 (2026-06-03): FlutterTimezone 5.1.0 retourneert TimezoneInfo object (niet String) — gebruik .identifier property voor tz.getLocation()
- 08-02 (2026-06-03): isInDebugMode parameter deprecated in workmanager 0.9.x — verwijderd; Workmanager().initialize(callbackDispatcher) volstaat
- 08-02 (2026-06-03): AppDatabase in WorkManager isolate geinitialiseerd met driftDatabase(name: 'ridewindow') — zelfde naam als foreground DB; Drift WAL-modus handelt gelijktijdige toegang af (T-08-02-02)
- 08-02 (2026-06-03): NetworkType.connected constraint in registerPeriodicTask — voorkomt zinloze network-retries (T-08-02-01 mitigatie)
- [Phase ?]: UI toggle placement
- [Phase ?]: Lifecycle observer teardown
- 10-01 (2026-06-05): applicationId = ridewindow.joost.amsterdam (PERMANENT — cannot change after first Play Console upload; user confirmed via Task 2 checkpoint)
- 10-01 (2026-06-05): Upload keystore at ~/upload-keystore.jks (outside project dir — never at risk of git commit); backed up to password manager
- 10-01 (2026-06-05): key.properties gitignored via android/.gitignore (pre-existing Android gitignore) — real passwords set, no PLACEHOLDER values
- 10-01 (2026-06-05): versionCode uses flutter.versionCode (derived from pubspec.yaml +1 build number) — pubspec.yaml is single source of truth for versioning
- 10-02 (2026-06-05): compileSdk bumped 35→36 — required by url_launcher_android, shared_preferences_android, flutter_local_notifications, geolocator_android, google_sign_in_android, package_info_plus; backward compatible with targetSdk/minSdk
- 10-02 (2026-06-05): isCoreLibraryDesugaringEnabled = true + desugar_jdk_libs:2.1.5 added — flutter_local_notifications v21+ requires core library desugaring
- 10-02 (2026-06-05): Android cmdline-tools/latest installed to ~/Library/Android/sdk — required for Flutter 3.44.1 post-build symbol stripping; not bundled with Android Studio on this machine

### Pending Todos

- **Trim GSD config voor Phase 1.5 planning** — zet research, plan_check, verifier, etc. uit in .planning/config.json. Besproken met gebruiker; uitgesteld.
- **GitHub remote setup** — push project naar private GitHub-repo voor tweede computer. Uitgesteld.

### Blockers/Concerns

- Phase 9 (Google Calendar): Vereist Google Cloud project setup, OAuth consent screen, en SHA-1 fingerprint registratie. Flag dit bij afsluiting Phase 8.
- Phase 8 (Notifications): Must test on Samsung/Xiaomi physical devices for WorkManager OEM reliability.
- Phase 10 (Release): Signed release AAB (56.5MB) and APK (58.0MB) built (Plan 10-02 Task 1 complete). BLOCKING: Physical device sideload smoke test required (Task 2 checkpoint:human-action) before proceeding to Plan 10-03.
- Phase 3 notitie (opgelost 03-03): AvailabilityNotifier gebruikt SharedPreferences — de Drift AvailabilityGridEntries tabel slaat een weekpatroon op (dayOfWeek+hour), niet DateTime-instanties. SharedPreferences met ISO-8601 serialisatie is de juiste aanpak.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Tooling | Android Studio + Android SDK + accepted licenses | Resolved — Phase 10 Plan 01 | 2026-06-05 |
| Verification | Package legitimacy audit (manual pub.dev check) | Skipped (covered by CLAUDE.md) | 2026-06-02 (Plan 01-01 Task 2) |
| Infra | GitHub remote + private repo | Pending | 2026-06-02 |

## Session Continuity

Last session: 2026-06-05T00:00:00Z
Stopped at: Completed 10-01-PLAN.md — Android SDK + applicationId ridewindow.joost.amsterdam + upload keystore + release signing config + .gitignore hardening + version 1.0.0+1
Resume file: None
Next action: Execute Phase 10 Plan 02 (signed release AAB + APK build + physical device sideload smoke test)
