// test/features/home_test_harness.dart
//
// Gedeelde opzet voor de tablettests van Home (quick-plannen 261011-jru en
// 261011-kb9): nepweer over de hele dag, een vast profiel, vaste vensters en
// een go_router met een nep-/detail-route, zodat een test kan zien of er
// gepusht werd. Vanaf expanded staat het volledige ritdetail in het paneel en
// vanaf 1440 ook RidesTab; de overrides hieronder dekken wat die lezen.

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
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/ride_entries_provider.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// De dag waarop alle testvensters vallen.
final kTestDay = DateTime(2026, 6, 8);

// Over de hele dag weer, zodat elk venster zijn balken heeft.
class _FakeWeather extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => [
        for (var h = 0; h < 24; h++)
          HourlyForecast(
            time: DateTime(2026, 6, 8, h),
            temperatureC: 18,
            apparentTemperatureC: 18,
            precipitationMm: 0,
            precipitationProbability: 0,
            windspeedKmh: 10,
            winddirectionDeg: 90,
          ),
      ];
}

class _FakeProfile extends ProfileNotifier {
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

/// Vaste locatie: de echte geolocatie plant een timer die na de test nog
/// open staat (zie ride_detail_screen_test.dart).
class _FakeLocation extends LocationNotifier {
  @override
  Future<LocationData> build() async => const LocationData(
        lat: 52.3676,
        lon: 4.9041,
        city: 'Amsterdam',
        source: LocationSource.override,
      );
}

class _FakeAvailability extends AvailabilityNotifier {
  @override
  Future<Map<DateTime, BlockType>> build() async => const {};
}

/// Met een echte `add` en `remove`, zodat Inplannen in het paneel werkt,
/// zonder SharedPreferences.
class FakePlannedRides extends PlannedRidesNotifier {
  FakePlannedRides([this._initial = const []]);
  final List<PlannedRide> _initial;

  @override
  Future<List<PlannedRide>> build() async => [..._initial];

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

class _FakeSlots extends SlotsNotifier {
  _FakeSlots(this._state);
  final SlotsState _state;

  @override
  SlotsState build() => _state;
}

RideSlot testSlot(int hour, int endHour, double score) {
  final start = DateTime(2026, 6, 8, hour);
  return RideSlot(
    start: start,
    end: DateTime(2026, 6, 8, endHour),
    overallScore: score,
    tier: rideTierFromScore(score),
    hours: [
      for (var h = hour; h < endHour; h++)
        HourlyScore(
          overall: score,
          temperatureScore: score,
          rainScore: score,
          windScore: score,
          time: DateTime(2026, 6, 8, h),
        ),
    ],
  );
}

const kDetailRouteText = 'DETAILSCHERM';

/// De testletter is vierkant (elke letter een volle em), en daarmee lopen de
/// weergaverij en de kop op 400 breed over -- met een echte letter niet, zie
/// de gelijke noot in home_screen_test.dart. Alleen die overloopmeldingen
/// vallen weg; elke andere fout laat de test falen.
Future<void> ignoringTestFontOverflow(Future<void> Function() body) async {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
    previous?.call(details);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
}

/// Mount Home op [size] (logische pixels). Geeft de router terug, zodat een
/// test kan nagaan dat er niet gepusht of gepopt is.
Future<GoRouter> pumpHome(
  WidgetTester tester,
  Size size,
  List<RideSlot> slots, {
  ThemeData? theme,
  List<PlannedRide> planned = const [],
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'hint_seen_home': true});

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/detail',
        builder: (_, __) => const Scaffold(body: Text(kDetailRouteText)),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        weatherProvider.overrideWith(_FakeWeather.new),
        profileProvider.overrideWith(_FakeProfile.new),
        locationProvider.overrideWith(_FakeLocation.new),
        availabilityProvider.overrideWith(_FakeAvailability.new),
        plannedRidesProvider.overrideWith(() => FakePlannedRides(planned)),
        currentUserIdProvider.overrideWithValue(null),
        ridesTabAttentionCountProvider.overrideWithValue(0),
        pelotonTabAttentionCountProvider.overrideWithValue(0),
        slotsProvider.overrideWith(
          () => _FakeSlots(SlotsLoaded(slots, reason: null)),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: theme ?? ThemeData(extensions: const [RideWindowTheme.light]),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  return router;
}
