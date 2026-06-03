// test/features/home_screen_refresh_test.dart
// Widget-tests voor HomeScreen lastRefreshed header-weergave.
// Dekt Phase 8 Plan 05 success criteria (NOTIF-06).

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
import 'package:ridewindow/providers/last_refreshed_provider.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

// ---------------------------------------------------------------------------
// Fake Notifiers
// ---------------------------------------------------------------------------

/// FakeLastRefreshedNotifier: retourneert een vaste DateTime? waarde.
class FakeLastRefreshedNotifier extends LastRefreshedNotifier {
  final DateTime? fakeTime;
  FakeLastRefreshedNotifier(this.fakeTime);

  @override
  Future<DateTime?> build() async => fakeTime;
}

/// FakeLastRefreshedNotifier die permanent in AsyncLoading blijft.
class FakeLastRefreshedLoading extends LastRefreshedNotifier {
  @override
  Future<DateTime?> build() async {
    await Completer<void>().future; // hangt oneindig
    return null;
  }
}

/// WeatherNotifier stub — lege forecast, niet loading.
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

/// LocationNotifier stub — Amsterdam.
class FakeLocationNotifier extends LocationNotifier {
  @override
  Future<LocationData> build() async =>
      const LocationData(lat: 52.3676, lon: 4.9041, city: 'Amsterdam');
}

/// SlotsNotifier stub — lege slots.
class FakeStaticSlotsNotifier extends SlotsNotifier {
  @override
  SlotsState build() => const SlotsLoaded([], reason: null);
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

/// Bouw een ProviderScope met alle benodigde overrides voor HomeScreen.
Widget _buildApp({required LastRefreshedNotifier Function() lastRefreshedFn}) {
  return ProviderScope(
    overrides: [
      lastRefreshedProvider.overrideWith(lastRefreshedFn),
      weatherProvider.overrideWith(() => FakeWeatherReady()),
      profileProvider.overrideWith(() => FakeProfileNotifier()),
      availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
      locationProvider.overrideWith(() => FakeLocationNotifier()),
      slotsProvider.overrideWith(() => FakeStaticSlotsNotifier()),
    ],
    child: MaterialApp.router(routerConfig: _makeRouter()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    "Test 1: toont 'Bijgewerkt: 14:30' bij bekende timestamp",
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          lastRefreshedFn: () =>
              FakeLastRefreshedNotifier(DateTime(2026, 6, 3, 14, 30)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Bijgewerkt: 14:30'), findsOneWidget);
    },
  );

  testWidgets(
    "Test 2: toont 'Bijgewerkt: —' bij null timestamp",
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          lastRefreshedFn: () => FakeLastRefreshedNotifier(null),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Bijgewerkt: —'), findsOneWidget);
    },
  );

  testWidgets(
    "Test 3: toont 'Bijgewerkt: —' bij loading state (permanente AsyncLoading)",
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          lastRefreshedFn: () => FakeLastRefreshedLoading(),
        ),
      );
      // Pump één frame — provider hangt in AsyncLoading
      await tester.pump();

      expect(find.text('Bijgewerkt: —'), findsOneWidget);
    },
  );
}
