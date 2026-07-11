// test/features/home_screen_refresh_test.dart
// Widget-tests voor HomeScreen lastRefreshed header-weergave + Phase 14
// foreground refresh strategy (REFRESH-01/02/03/04).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/app/router.dart' show sharedPrefsProvider;
import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/home/home_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/last_refreshed_provider.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Fake Notifiers
// ---------------------------------------------------------------------------

/// FakeLastRefreshedNotifier: retourneert een vaste DateTime? waarde.
/// [refreshCallCount] telt hoe vaak [refresh] is aangeroepen -- gebruikt om
/// de nieuwe reactieve ref.listen link (Task 1) te bewijzen.
class FakeLastRefreshedNotifier extends LastRefreshedNotifier {
  final DateTime? fakeTime;
  int refreshCallCount = 0;
  FakeLastRefreshedNotifier(this.fakeTime);

  @override
  Future<DateTime?> build() async => fakeTime;

  @override
  Future<void> refresh() async {
    refreshCallCount++;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
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

/// WeatherNotifier stub die het aantal build()-aanroepen telt --
/// gebruikt om te bewijzen dat ref.invalidate(weatherProvider) daadwerkelijk
/// een her-fetch triggert (REFRESH-01).
class FakeWeatherCounting extends WeatherNotifier {
  int buildCount = 0;

  @override
  Future<List<HourlyForecast>> build() async {
    buildCount++;
    return const [];
  }
}

/// WeatherNotifier stub die op commando kan falen na een eerder succes --
/// gebruikt om REFRESH-04's stale-banner gedrag te bewijzen.
class FakeWeatherFlaky extends WeatherNotifier {
  bool shouldFail = false;

  @override
  Future<List<HourlyForecast>> build() async {
    if (shouldFail) throw Exception('offline');
    return const [];
  }
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
///
/// [weatherFn] is optioneel zodat individuele tests een eigen (tellende of
/// falende) WeatherNotifier-fake kunnen injecteren; standaard FakeWeatherReady.
/// HomeScreen watcht ook plannedRidesProvider, dat sharedPrefsProvider leest --
/// dus moet dat hier ook overridden worden met een echte (gemockte) instantie.
Future<Widget> _buildApp({
  required LastRefreshedNotifier Function() lastRefreshedFn,
  WeatherNotifier Function()? weatherFn,
  Duration? Function(int retryCount, Object error)? retry,
}) async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    // Disable Riverpod's default exponential-backoff retry when a test
    // needs a single simulated failure to settle into AsyncError
    // immediately (see slots_notifier_test.dart for the same pattern).
    retry: retry,
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      lastRefreshedProvider.overrideWith(lastRefreshedFn),
      weatherProvider.overrideWith(weatherFn ?? () => FakeWeatherReady()),
      profileProvider.overrideWith(() => FakeProfileNotifier()),
      availabilityProvider.overrideWith(() => FakeAvailabilityNotifier()),
      locationProvider.overrideWith(() => FakeLocationNotifier()),
      slotsProvider.overrideWith(() => FakeStaticSlotsNotifier()),
    ],
    child: MaterialApp.router(
      routerConfig: _makeRouter(),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: const Locale('nl'),
      theme: ThemeData(extensions: [RideWindowTheme.light]),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    // debugIsWebOverride is a process-global mutable variable -- reset it
    // so it never leaks into other test files run in the same process.
    debugIsWebOverride = null;
  });

  testWidgets(
    "Test 1: toont 'Amsterdam · Bijgewerkt 14:30' bij bekende timestamp",
    (tester) async {
      await tester.pumpWidget(
        await _buildApp(
          lastRefreshedFn: () =>
              FakeLastRefreshedNotifier(DateTime(2026, 6, 3, 14, 30)),
        ),
      );
      await tester.pump();
      // Flush the 200ms whisper-name fade-in timer and the 500ms coach-mark
      // delay in HomeScreen.initState so no Timer is left pending at
      // test-end (both are unrelated to the subtitle logic under test).
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Amsterdam · Bijgewerkt 14:30'), findsOneWidget);
    },
  );

  testWidgets(
    "Test 2: toont 'Amsterdam' bij null timestamp (geen label toegevoegd)",
    (tester) async {
      await tester.pumpWidget(
        await _buildApp(
          lastRefreshedFn: () => FakeLastRefreshedNotifier(null),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Amsterdam'), findsOneWidget);
    },
  );

  testWidgets(
    "Test 3: toont 'Amsterdam' bij loading state (permanente AsyncLoading, nog geen label)",
    (tester) async {
      await tester.pumpWidget(
        await _buildApp(
          lastRefreshedFn: () => FakeLastRefreshedLoading(),
        ),
      );
      // Pump lang genoeg om de whisper-name/coach-mark timers te flushen --
      // lastRefreshedProvider blijft niettemin permanent in AsyncLoading.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Amsterdam'), findsOneWidget);
    },
  );

  testWidgets(
    'resume on web invalidates weatherProvider (REFRESH-01)',
    (tester) async {
      final fakeWeather = FakeWeatherCounting();
      await tester.pumpWidget(
        await _buildApp(
          lastRefreshedFn: () => FakeLastRefreshedNotifier(null),
          weatherFn: () => fakeWeather,
        ),
      );
      await tester.pumpAndSettle();
      expect(fakeWeather.buildCount, 1);

      debugIsWebOverride = true;
      WidgetsBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(fakeWeather.buildCount, 2);
    },
  );

  testWidgets(
    'resume on native does NOT invalidate weatherProvider (regression)',
    (tester) async {
      final fakeWeather = FakeWeatherCounting();
      await tester.pumpWidget(
        await _buildApp(
          lastRefreshedFn: () => FakeLastRefreshedNotifier(null),
          weatherFn: () => fakeWeather,
        ),
      );
      await tester.pumpAndSettle();
      expect(fakeWeather.buildCount, 1);

      // debugIsWebOverride left at its default null (native/VM test env).
      WidgetsBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(fakeWeather.buildCount, 1);
    },
  );

  testWidgets(
    'weatherProvider success updates lastRefreshedProvider reactively',
    (tester) async {
      final fakeLastRefreshed = FakeLastRefreshedNotifier(null);
      await tester.pumpWidget(
        await _buildApp(lastRefreshedFn: () => fakeLastRefreshed),
      );
      await tester.pumpAndSettle();

      // Initial weatherProvider resolution should have triggered at least
      // one call to lastRefreshedProvider.notifier.refresh() via the new
      // ref.listen link.
      final countAfterInitial = fakeLastRefreshed.refreshCallCount;
      expect(countAfterInitial, greaterThanOrEqualTo(1));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
        listen: false,
      );
      container.refresh(weatherProvider);
      await tester.pumpAndSettle();

      // Proves the ref.listen link runs on every successful weather
      // resolution, not just on lifecycle resume.
      expect(
        fakeLastRefreshed.refreshCallCount,
        greaterThan(countAfterInitial),
      );
    },
  );

  testWidgets(
    'stale banner shows and cards remain visible when weatherProvider errors after success (REFRESH-04)',
    (tester) async {
      final fakeWeather = FakeWeatherFlaky();
      await tester.pumpWidget(
        await _buildApp(
          lastRefreshedFn: () =>
              FakeLastRefreshedNotifier(DateTime(2026, 6, 3, 14, 30)),
          weatherFn: () => fakeWeather,
          // Disable retry so the simulated failure below settles into
          // AsyncError immediately instead of waiting through several
          // real-time exponential-backoff retry delays.
          retry: (retryCount, error) => null,
        ),
      );
      await tester.pumpAndSettle();

      // Force the failure via the public API, matching production's
      // ref.invalidate(weatherProvider) -> failing re-fetch path.
      fakeWeather.shouldFail = true;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
        listen: false,
      );
      container.refresh(weatherProvider);
      await tester.pumpAndSettle();

      // (a) stale/offline banner is present with the known timestamp.
      expect(
        find.text('Offline — toont rijvensters van 14:30'),
        findsOneWidget,
      );
      // (b) the blank full-screen error is NOT shown when previous data
      // exists -- proves the full-screen error path was correctly narrowed
      // to hasError && !hasValue only.
      expect(find.text('Weersdata kon niet worden geladen.'), findsNothing);
    },
  );
}
