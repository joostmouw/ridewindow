/// Widget tests voor HomeScreen.
///
/// Dekt Phase 4 success criteria 3 en 4:
///   3. HomeScreen toont skeleton cards tijdens loading state
///   4. HomeScreen toont ride cards bij data, en lege staat bij leeg
///
/// Tests gebruiken ProviderScope + overrides zodat geen netwerk of
/// echte SharedPreferences nodig is.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/core/ride_day_label.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/home/home_screen.dart';
import 'package:ridewindow/features/shared/score_display.dart';
import 'package:ridewindow/features/shared/score_badge.dart';
import 'package:ridewindow/domain/services/ride_window_scorer.dart';
import 'package:ridewindow/providers/ride_window_scorer_provider.dart';
import 'package:ridewindow/data/repositories/home_view_store.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/l10n/app_localizations_nl.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/ride_entries_provider.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

// ---------------------------------------------------------------------------
// Fake Notifiers
// ---------------------------------------------------------------------------

/// Blijft voor altijd in AsyncLoading door een Completer te gebruiken.
class FakeWeatherLoading extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async {
    await Completer<void>()
        .future; // hangt oneindig → provider blijft AsyncLoading
    return const [];
  }
}

/// Retourneert een opgeloste lege forecast (weatherProvider is niet meer loading).
class FakeWeatherReady extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => const [];
}

/// ProfileNotifier stub zonder SharedPreferences.
class FakeProfileNotifier extends ProfileNotifier {
  @override
  Future<UserProfile> build() async => const UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 10.0,
          tempMaxIdealC: 30.0,
          windMaxIdealKmh: 25.0,
          rainMaxIdealMm: 1.0,
        ),
        allowedDurations: [2, 3],
        theme: 'system',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );
}

/// AvailabilityNotifier stub: lege blocked-map.
class FakeAvailabilityNotifier extends AvailabilityNotifier {
  @override
  Future<Map<DateTime, BlockType>> build() async => const {};
}

/// Synchrone SlotsNotifier die altijd een vaste SlotsState retourneert.
/// Omzeilt alle ref.watch-aanroepen — geen upstream providers nodig.
class FakeStaticSlotsNotifier extends SlotsNotifier {
  final SlotsState _fixedState;
  FakeStaticSlotsNotifier(this._fixedState);

  @override
  SlotsState build() => _fixedState;
}

/// PlannedRidesNotifier stub — empty by default; add()/remove() are faked
/// to avoid touching sharedPrefsProvider (which is otherwise unoverridden
/// in these tests and throws "Must be overridden in ProviderScope").
class FakePlannedRidesNotifier extends PlannedRidesNotifier {
  @override
  Future<List<PlannedRide>> build() async => [];

  @override
  Future<void> add(PlannedRide ride) async {
    state = AsyncData([...?state.value, ride]);
  }

  @override
  Future<void> remove(PlannedRide ride) async {
    state = AsyncData(
      (state.value ?? const <PlannedRide>[])
          .where((r) => r.start != ride.start || r.end != ride.end)
          .toList(),
    );
  }
}

/// Zelfde stub, maar met één geplande rit, voor de plankaart. Morgen, want
/// de entries-provider laat verstreken ritten vallen.
class FakeOnePlannedRideNotifier extends FakePlannedRidesNotifier {
  @override
  Future<List<PlannedRide>> build() async {
    final day = DateTime.now().add(const Duration(days: 1));
    final start = DateTime(day.year, day.month, day.day, 8);
    return [
      PlannedRide(
        start: start,
        end: start.add(const Duration(hours: 2)),
        plannedScore: 88,
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Fixture: minimaal RideSlot (Perfect tier, maandag 09:00-13:00)
// ---------------------------------------------------------------------------

RideSlot _makeTestSlot() {
  final start = DateTime(2026, 6, 8, 9, 0); // Maandag
  final end = DateTime(2026, 6, 8, 13, 0);
  return RideSlot(
    start: start,
    end: end,
    overallScore: 90.0,
    tier: const Perfect(),
    hours: [
      HourlyScore(
        overall: 90.0,
        temperatureScore: 90.0,
        rainScore: 95.0,
        windScore: 85.0,
        time: start,
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Helper: bouw GoRouter
// ---------------------------------------------------------------------------

GoRouter _makeRouter() => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const HomeScreen(),
        ),
      ],
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home toont de actuele lage score, niet de opgeslagen 88',
      (tester) async {
    final start = DateTime.now().add(const Duration(days: 2));
    final time = DateTime(start.year, start.month, start.day, 12);
    final entry = RideEntry(
      start: time,
      end: time.add(const Duration(hours: 1)),
      plannedScore: 88,
      role: RideRole.solo,
    );
    final scorer = RideWindowScorer(
      tolerances: const WeatherTolerances(),
      forecasts: [
        HourlyForecast(
          time: time, temperatureC: -15, apparentTemperatureC: -15,
          precipitationMm: 10, precipitationProbability: 100,
          windspeedKmh: 100, winddirectionDeg: 90,
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        weatherProvider.overrideWith(FakeWeatherReady.new),
        profileProvider.overrideWith(FakeProfileNotifier.new),
        availabilityProvider.overrideWith(FakeAvailabilityNotifier.new),
        plannedRidesProvider.overrideWith(FakePlannedRidesNotifier.new),
        slotsProvider.overrideWith(
          () => FakeStaticSlotsNotifier(const SlotsLoaded([])),
        ),
        rideEntriesProvider.overrideWith((ref) => [entry]),
        rideWindowScorerProvider.overrideWithValue(scorer),
      ],
      child: MaterialApp.router(
        routerConfig: _makeRouter(),
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: ThemeData(extensions: const [RideWindowTheme.light]),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final badge = tester.widget<ScoreBadge>(find.byType(ScoreBadge));
    expect(badge.score, scorer.score(entry.start, entry.end)!.overallScore.round());
    expect(badge.score, lessThan(50));
    expect(entry.plannedScore, 88);
  });

  // ---------------------------------------------------------------------------
  // Test 1: loading state — skeleton cards zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('HomeScreen toont skeleton cards tijdens loading state',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherLoading()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          plannedRidesProvider.overrideWith(() => FakePlannedRidesNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: _makeRouter(),
          locale: const Locale('nl'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: ThemeData(extensions: const [RideWindowTheme.light]),
        ),
      ),
    );

    // pump één frame — provider is in AsyncLoading, nog geen settle
    await tester.pump();

    // Skeleton: 3 containers met height 100 en grijze kleur
    // We verifiëren via AnimatedBuilder widgets (elk skeleton card gebruikt AnimatedBuilder)
    expect(find.byType(AnimatedBuilder), findsWidgets);

    // Geen ride cards zichtbaar (geen 'Inplannen' knop)
    expect(find.text('Inplannen'), findsNothing);

    // Flush the pending 500ms spotlight-hint timer (initState's
    // postFrameCallback in HomeScreen) so the test framework doesn't
    // fail teardown with "A Timer is still pending".
    await tester.pump(const Duration(milliseconds: 600));
  });

  // ---------------------------------------------------------------------------
  // Test 2: data state — ride card tijdreeks zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('HomeScreen toont ride cards bij SlotsLoaded met data',
      (tester) async {
    final testSlot = _makeTestSlot();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherReady()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          plannedRidesProvider.overrideWith(() => FakePlannedRidesNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(SlotsLoaded([testSlot])),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: _makeRouter(),
          locale: const Locale('nl'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: ThemeData(extensions: const [RideWindowTheme.light]),
        ),
      ),
    );
    // Pump meerdere frames: async providers resolven, animaties draaien door
    // pumpAndSettle werkt niet vanwege de oneindige skeleton-animatie in HomeScreen
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));

    // Tijdreeks-tekst: 09:00 – 13:00 · 4u
    expect(find.textContaining('09:00'), findsOneWidget);
    // Tier badge: Toprit (heette Perfect tot schets 010)
    expect(find.text('Toprit'), findsOneWidget);
    // 'Inplannen' knop
    expect(find.text('Inplannen'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 3: lege staat badWeather — tekst over slecht weer zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('HomeScreen toont lege-staat tekst bij badWeather',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherReady()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          plannedRidesProvider.overrideWith(() => FakePlannedRidesNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(
              const SlotsLoaded([], reason: SlotsEmptyReason.badWeather),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: _makeRouter(),
          locale: const Locale('nl'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: ThemeData(extensions: const [RideWindowTheme.light]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));

    // HomeScreen toont: 'Geen goede rijmomenten deze week. Slecht weer verwacht.'
    expect(find.textContaining('Slecht weer'), findsOneWidget);
    expect(find.text('Inplannen'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Test 3b: de plankaart toont de score klein, niet het tier-woord
  // ---------------------------------------------------------------------------
  testWidgets('de plankaart toont het scoregetal, niet het tier-woord',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherReady()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          plannedRidesProvider
              .overrideWith(() => FakeOnePlannedRideNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(
              const SlotsLoaded([], reason: SlotsEmptyReason.badWeather),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: _makeRouter(),
          locale: const Locale('nl'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: ThemeData(extensions: const [RideWindowTheme.light]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));

    // Het getal staat klein in de pil; het woord at de breedte van het
    // vakje op (Joost, 25 sept). De kleur van de pil blijft het oordeel
    // dragen.
    expect(find.text('88'), findsOneWidget);
    expect(find.text('Toprit'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Test 4: lege staat allBlocked — tekst over geblokkeerde uren zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('HomeScreen toont lege-staat tekst bij allBlocked',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherReady()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          plannedRidesProvider.overrideWith(() => FakePlannedRidesNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(
              const SlotsLoaded([], reason: SlotsEmptyReason.allBlocked),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: _makeRouter(),
          locale: const Locale('nl'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: ThemeData(extensions: const [RideWindowTheme.light]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));

    // HomeScreen toont: 'Alle goede momenten zijn geblokkeerd. Pas je schema aan.'
    expect(find.textContaining('geblokkeerd'), findsOneWidget);
    expect(find.text('Inplannen'), findsNothing);
  });

  // ── Weergave en volgorde (backlog #69/#70) ──
  //
  // Home kon maar op één manier kijken: losse vensters, gesorteerd op score.
  // Een tester vroeg om het aaneengesloten blok én om chronologische volgorde.
  // Deze tests leggen vast dat beide keuzes er zijn en werkelijk iets doen.

  RideSlot slotAt(int hour, int endHour, double score) => RideSlot(
        start: DateTime(2026, 6, 8, hour),
        end: DateTime(2026, 6, 8, endHour),
        overallScore: score,
        tier: rideTierFromScore(score),
        hours: const [],
      );

  Future<void> pumpHomeWithSlots(
    WidgetTester tester,
    List<RideSlot> slots,
  ) async {
    // De hint-overlay van de eerste start ligt over het hele scherm en vangt
    // elke tik. Hem als gezien markeren hoort bij het opzetten van deze test,
    // niet bij wat er getoetst wordt.
    SharedPreferences.setMockInitialValues({'hint_seen_home': true});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherReady()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          plannedRidesProvider.overrideWith(() => FakePlannedRidesNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(SlotsLoaded(slots, reason: null)),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: _makeRouter(),
          locale: const Locale('nl'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: ThemeData(extensions: const [RideWindowTheme.light]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('de vier keuzes staan op Home', (tester) async {
    await pumpHomeWithSlots(tester, [slotAt(9, 11, 100)]);

    expect(find.text('Vensters'), findsOneWidget);
    expect(find.text('Blok'), findsOneWidget);
    expect(find.text('Beste eerst'), findsOneWidget);
    expect(find.text('Op tijd'), findsOneWidget);
  });

  testWidgets('de volgordekeuze verdwijnt in blokweergave', (tester) async {
    // In blokweergave is er per dag één kaart, dus er valt niets te sorteren.
    // Een keuze tonen die niets doet is erger dan geen keuze.
    await pumpHomeWithSlots(tester, [slotAt(9, 11, 100)]);

    await tester.tap(find.text('Blok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Beste eerst'), findsNothing);
    expect(find.text('Op tijd'), findsNothing);
  });

  testWidgets('blokweergave voegt Ingrids drie vensters tot één kaart',
      (tester) async {
    // De melding van 9 september: 09:00-11:00 (100), 06:00-09:00 (99) en
    // 11:00-13:00 (95) op één zaterdag.
    await pumpHomeWithSlots(tester, [
      slotAt(9, 11, 100),
      slotAt(6, 9, 99),
      slotAt(11, 13, 95),
    ]);

    await tester.tap(find.text('Blok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.text('je kunt rijden: 06:00\u201313:00'),
      findsOneWidget,
      reason: 'drie regels, één ochtend',
    );
    // Niet "7 uur aaneengesloten": dat zou beweren dat je zeven uur achter
    // elkaar fietst. Wat de app aanbiedt is de langste rit in dat blok.
    expect(find.text('Langste rit hier: 3 uur'), findsOneWidget);

    // En de beoordeling hangt aan een tijdvak, niet aan de dag: het beste
    // venster staat boven het cijfer.
    expect(find.text('09:00\u201311:00'), findsOneWidget);
  });

  testWidgets('de keuze wordt onthouden', (tester) async {
    await pumpHomeWithSlots(tester, [slotAt(9, 11, 100)]);

    await tester.tap(find.text('Blok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(HomeViewStore.kViewKey), 'blocks');
  });

  testWidgets('"Beste eerst" sorteert op score, niet op tier-dan-tijd',
      (tester) async {
    // Joost zag 85 boven 93 staan, allebei "Toprit". De lijst sorteerde op
    // tier en binnen een tier chronologisch, dus de vroegste won -- onder een
    // knop die letterlijk "Beste eerst" belooft.
    await pumpHomeWithSlots(tester, [
      slotAt(6, 9, 85),
      slotAt(9, 12, 93),
      slotAt(12, 15, 100),
    ]);

    // Alleen de kaarten die daadwerkelijk gebouwd zijn -- SliverList bouwt
    // niet wat buiten het testvenster valt. De bewering gaat over de volgorde,
    // niet over het aantal.
    final scores = tester
        .widgetList<ScoreDisplay>(find.byType(ScoreDisplay))
        .map((w) => w.score)
        .toList();

    expect(scores.length, greaterThanOrEqualTo(2));
    expect(scores.first, 100.0, reason: 'de hoogste score staat bovenaan');
    for (var i = 1; i < scores.length; i++) {
      expect(
        scores[i],
        lessThanOrEqualTo(scores[i - 1]),
        reason: 'hoog naar laag, ongeacht starttijd: $scores',
      );
    }
  });

  testWidgets('"Op tijd" zet ze chronologisch, ook als dat de beste omlaag haalt',
      (tester) async {
    await pumpHomeWithSlots(tester, [
      slotAt(6, 9, 85),
      slotAt(9, 12, 93),
      slotAt(12, 15, 100),
    ]);

    await tester.tap(find.text('Op tijd'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final scores = tester
        .widgetList<ScoreDisplay>(find.byType(ScoreDisplay))
        .map((w) => w.score)
        .toList();

    expect(scores.length, greaterThanOrEqualTo(2));
    expect(
      scores.first,
      85.0,
      reason: 'de vroegste rit staat bovenaan, ook al scoort hij het laagst',
    );
  });

  // ── Groepsritten onder PLANNED (fase 35, CLUB-16) ──
  //
  // De groepsnaam staat vooraan in de rolregel, niet op een eigen regel.
  // Joost: "Het moet passen op het scherm" -- dus op 360 dp.
  testWidgets('een groepsrit onder PLANNED past op 360 dp met groepsnaam',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'hint_seen_home': true});

    final ride = FakeGroupGateway.groupRide(
      'r1',
      ownerId: 'uid-anna',
      ownerName: 'Anna',
      groupId: 'g1',
    );
    final entry = RideEntry(
      start: ride.start,
      end: ride.end,
      plannedScore: ride.plannedScore,
      role: RideRole.pending,
      group: ride,
      pelotonGroup: FakeGroupGateway.group(
        'g1',
        'Tour de Waterland Zondagochtend Clubrit',
        members: [
          FakeGroupGateway.member(
            'uid-anna',
            role: GroupRole.admin,
            name: 'Anna',
          ),
          FakeGroupGateway.member('uid-me', name: 'Ik', joinedDay: 1),
        ],
      ),
    );

    // De testletter is vierkant: elke letter een volle em breed. Daarmee
    // loopt de weergaverij bovenaan ("Vensters Blok ... Beste eerst Op tijd")
    // op 360 dp over, wat met een echte letter niet gebeurt en niets met
    // ritkaarten te maken heeft. Die ene fout laten we door; elke andere
    // (en zeker een in de ritkaart) laat de test falen.
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherReady()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          plannedRidesProvider.overrideWith(() => FakePlannedRidesNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(
              const SlotsLoaded([], reason: null),
            ),
          ),
          rideEntriesProvider.overrideWith((ref) => [entry]),
        ],
        child: MaterialApp.router(
          routerConfig: _makeRouter(),
          locale: const Locale('nl'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: ThemeData(extensions: const [RideWindowTheme.light]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    FlutterError.onError = previousOnError;

    final viewRow = tester.renderObject(
      find.ancestor(of: find.text('Vensters'), matching: find.byType(Row)).first,
    );
    RenderObject? overflowing(FlutterErrorDetails d) {
      for (final n in d.informationCollector?.call() ?? <DiagnosticsNode>[]) {
        if (n.value is RenderFlex) return n.value as RenderFlex;
      }
      return null;
    }

    final unexpected = errors
        .where((d) => overflowing(d) != viewRow)
        .map((d) => d.toString())
        .toList();
    expect(unexpected, isEmpty, reason: unexpected.join('\n\n'));
    expect(
      find.text('Tour de Waterland Zondagochtend Clubrit'),
      findsOneWidget,
    );
    expect(find.text('Anna vraagt of je meegaat'), findsOneWidget);
  });

  // PLANNED toont de eerstvolgende drie ritten, niet die van één week. Met
  // alleen de weekdag heette een rit over tien dagen net zo als een van deze
  // week.
  testWidgets('de plankaart zegt Morgen, en verder weg de datum erbij',
      (tester) async {
    SharedPreferences.setMockInitialValues({'hint_seen_home': true});
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 10);
    final later = DateTime(now.year, now.month, now.day + 10, 10);
    RideEntry solo(DateTime start) => RideEntry(
          start: start,
          end: start.add(const Duration(hours: 2)),
          plannedScore: 90,
          role: RideRole.solo,
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherReady()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          plannedRidesProvider.overrideWith(() => FakePlannedRidesNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(
              const SlotsLoaded([], reason: null),
            ),
          ),
          rideEntriesProvider
              .overrideWith((ref) => [solo(tomorrow), solo(later)]),
        ],
        child: MaterialApp.router(
          routerConfig: _makeRouter(),
          locale: const Locale('nl'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: ThemeData(extensions: const [RideWindowTheme.light]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Morgen'), findsOneWidget);
    final laterLabel = rideDayLabelAbsolute(later, SNl());
    expect(laterLabel, contains('${later.day} '));
    expect(find.text(laterLabel), findsOneWidget);
  });
}
