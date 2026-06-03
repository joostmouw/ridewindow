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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/home/home_screen.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

// ---------------------------------------------------------------------------
// Fake Notifiers
// ---------------------------------------------------------------------------

/// Blijft voor altijd in AsyncLoading door een Completer te gebruiken.
class FakeWeatherLoading extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async {
    await Completer<void>().future; // hangt oneindig → provider blijft AsyncLoading
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

  // ---------------------------------------------------------------------------
  // Test 1: loading state — skeleton cards zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('HomeScreen toont skeleton cards tijdens loading state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherLoading()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
        ],
        child: MaterialApp.router(routerConfig: _makeRouter()),
      ),
    );

    // pump één frame — provider is in AsyncLoading, nog geen settle
    await tester.pump();

    // Skeleton: 3 containers met height 100 en grijze kleur
    // We verifiëren via AnimatedBuilder widgets (elk skeleton card gebruikt AnimatedBuilder)
    expect(find.byType(AnimatedBuilder), findsWidgets);

    // Geen ride cards zichtbaar (geen 'Plan het' knop)
    expect(find.text('Plan het'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Test 2: data state — ride card tijdreeks zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('HomeScreen toont ride cards bij SlotsLoaded met data', (tester) async {
    final testSlot = _makeTestSlot();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherReady()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(SlotsLoaded([testSlot])),
          ),
        ],
        child: MaterialApp.router(routerConfig: _makeRouter()),
      ),
    );
    // Pump meerdere frames: async providers resolven, animaties draaien door
    // pumpAndSettle werkt niet vanwege de oneindige skeleton-animatie in HomeScreen
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Tijdreeks-tekst: 09:00 – 13:00 · 4u
    expect(find.textContaining('09:00'), findsOneWidget);
    // Tier badge: Perfect
    expect(find.text('Perfect'), findsOneWidget);
    // 'Plan het' knop
    expect(find.text('Plan het'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 3: lege staat badWeather — tekst over slecht weer zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('HomeScreen toont lege-staat tekst bij badWeather', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherReady()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(
              const SlotsLoaded([], reason: SlotsEmptyReason.badWeather),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: _makeRouter()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // HomeScreen toont: 'Geen goede rijmomenten deze week. Slecht weer verwacht.'
    expect(find.textContaining('Slecht weer'), findsOneWidget);
    expect(find.text('Plan het'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Test 4: lege staat allBlocked — tekst over geblokkeerde uren zichtbaar
  // ---------------------------------------------------------------------------
  testWidgets('HomeScreen toont lege-staat tekst bij allBlocked', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherProvider.overrideWith(() => FakeWeatherReady()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(
              const SlotsLoaded([], reason: SlotsEmptyReason.allBlocked),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: _makeRouter()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // HomeScreen toont: 'Alle goede momenten zijn geblokkeerd. Pas je schema aan.'
    expect(find.textContaining('geblokkeerd'), findsOneWidget);
    expect(find.text('Plan het'), findsNothing);
  });
}
