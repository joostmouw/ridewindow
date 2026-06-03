/// Widget-tests voor locatienaam in HomeScreen header.
///
/// Dekt Phase 7 Plan 05 success criteria:
///   LOC-02: GPS-locatie retourneer-pad — stadsnaam zichtbaar in header
///
/// Tests gebruiken FakeNotifier-subklassen (extends concrete klasse, niet _$abstract)
/// conform het gevestigde patroon uit Phase 3/6.
///
/// Noot (07-04 STATE.md beslissing): HomeScreen toont kDefaultCity ('Amsterdam')
/// als fallback tijdens AsyncLoading — locationAsync.value?.city ?? kDefaultCity.
/// Dit is consistenter dan literal '...' uit de oorspronkelijke planspecificatie.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/home/home_screen.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

// ---------------------------------------------------------------------------
// Fake Notifiers
// ---------------------------------------------------------------------------

class FakeLocationNotifier extends LocationNotifier {
  final LocationData fakeLocation;
  FakeLocationNotifier(this.fakeLocation);

  @override
  Future<LocationData> build() async => fakeLocation;
}

/// LocationNotifier die nooit completeert — provider blijft in AsyncLoading.
class FakeLocationLoading extends LocationNotifier {
  @override
  Future<LocationData> build() async {
    await Completer<void>().future; // hangt oneindig
    return const LocationData(lat: 52.3676, lon: 4.9041, city: 'Amsterdam');
  }
}

/// WeatherNotifier stub zonder netwerk.
class FakeWeatherNotifier extends WeatherNotifier {
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Test 1 — toont stadsnaam in header als locationProvider data heeft',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationProvider.overrideWith(
            () => FakeLocationNotifier(
              const LocationData(lat: 51.92, lon: 4.48, city: 'Rotterdam'),
            ),
          ),
          weatherProvider.overrideWith(() => FakeWeatherNotifier()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(const SlotsLoaded([], reason: null)),
          ),
        ],
        child: MaterialApp.router(routerConfig: _makeRouter()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Stadsnaam 'Rotterdam' zichtbaar in de header (LOC-02)
    expect(find.text('Rotterdam'), findsOneWidget);
  });

  testWidgets(
      'Test 2 — toont kDefaultCity (Amsterdam) als locationProvider nog laadt',
      (tester) async {
    // STATE.md beslissing 07-04: HomeScreen toont kDefaultCity ('Amsterdam')
    // als fallback tijdens AsyncLoading via locationAsync.value?.city ?? kDefaultCity.
    // Literal '...' uit planspecificatie is vervangen door kDefaultCity in implementatie.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationProvider.overrideWith(() => FakeLocationLoading()),
          weatherProvider.overrideWith(() => FakeWeatherNotifier()),
          profileProvider.overrideWith(() => FakeProfileNotifier()),
          availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
          slotsProvider.overrideWith(
            () => FakeStaticSlotsNotifier(const SlotsLoaded([], reason: null)),
          ),
        ],
        child: MaterialApp.router(routerConfig: _makeRouter()),
      ),
    );

    // Slechts één pump — FakeLocationLoading completeert nooit; locationAsync blijft AsyncLoading
    await tester.pump();

    // HomeScreen toont kDefaultCity 'Amsterdam' als fallback (Rule 3 auto-fix in 07-04)
    expect(find.text('Amsterdam'), findsOneWidget);
  });
}
