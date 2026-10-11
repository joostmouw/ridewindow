// test/features/home_two_pane_test.dart
//
// Home als lijst-plus-detail vanaf expanded (quick-plan 261011-jru): op een
// telefoon één kolom en een tik opent /detail; op 1280 breed staat het beste
// venster al rechts open en kiest een tik in de lijst wat daar staat, zonder
// te pushen -- zoals Gmail op een tablet.

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
import 'package:ridewindow/features/shared/weather_indicator_bar.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

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

class _FakeAvailability extends AvailabilityNotifier {
  @override
  Future<Map<DateTime, BlockType>> build() async => const {};
}

class _FakePlannedRides extends PlannedRidesNotifier {
  @override
  Future<List<PlannedRide>> build() async => [];
}

class _FakeSlots extends SlotsNotifier {
  _FakeSlots(this._state);
  final SlotsState _state;

  @override
  SlotsState build() => _state;
}

RideSlot _slot(int hour, int endHour, double score) {
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

const _detailText = 'DETAILSCHERM';

/// De testletter is vierkant (elke letter een volle em), en daarmee lopen de
/// weergaverij en de kop op 400 breed over -- met een echte letter niet, zie
/// de gelijke noot in home_screen_test.dart. Alleen die overloopmeldingen
/// vallen weg; elke andere fout laat de test falen.
Future<void> _ignoringTestFontOverflow(Future<void> Function() body) async {
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

Future<void> _pumpHome(
  WidgetTester tester,
  Size size,
  List<RideSlot> slots,
) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'hint_seen_home': true});

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/detail',
        builder: (_, __) => const Scaffold(body: Text(_detailText)),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        weatherProvider.overrideWith(_FakeWeather.new),
        profileProvider.overrideWith(_FakeProfile.new),
        availabilityProvider.overrideWith(_FakeAvailability.new),
        plannedRidesProvider.overrideWith(_FakePlannedRides.new),
        slotsProvider.overrideWith(
          () => _FakeSlots(SlotsLoaded(slots, reason: null)),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
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

final _pane = find.byKey(const ValueKey('home_detail_pane'));

Finder _inPane(Finder f) => find.descendant(of: _pane, matching: f);

Finder _inList(Finder f) => find.descendant(
      of: find.byType(CustomScrollView),
      matching: f,
    );

void main() {
  // Drie vensters; 11:00-13:00 is het beste.
  final slots = [
    _slot(7, 9, 80),
    _slot(11, 13, 95),
    _slot(15, 17, 70),
  ];

  testWidgets('telefoon (400x800): geen detailpaneel, tik opent /detail',
      (tester) async {
    await _ignoringTestFontOverflow(() async {
      await _pumpHome(tester, const Size(400, 800), slots);
      expect(_pane, findsNothing);

      final card = find.textContaining('07:00 – 09:00').first;
      await tester.ensureVisible(card);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(card);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(_detailText), findsOneWidget);
    });
  });

  testWidgets('1280x800: het beste venster staat rechts open', (tester) async {
    await _ignoringTestFontOverflow(() async {
      await _pumpHome(tester, const Size(1280, 800), slots);
      expect(_pane, findsOneWidget);
      expect(_inPane(find.textContaining('11:00 – 13:00')), findsOneWidget);
      expect(_inPane(find.text('Inplannen')), findsOneWidget);
      expect(_inPane(find.byType(WeatherIndicatorBar)), findsWidgets);
      // De lijst staat links, het paneel rechts.
      expect(
        tester.getTopLeft(_pane).dx,
        greaterThan(tester.getTopLeft(find.byType(CustomScrollView)).dx),
      );
    });
  });

  testWidgets('1280x800: tik in de lijst kiest het venster, zonder push',
      (tester) async {
    await _ignoringTestFontOverflow(() async {
      await _pumpHome(tester, const Size(1280, 800), slots);

      await tester.tap(_inList(find.textContaining('07:00 – 09:00')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(_detailText), findsNothing);
      expect(_inPane(find.textContaining('07:00 – 09:00')), findsOneWidget);
      expect(_inPane(find.textContaining('11:00 – 13:00')), findsNothing);
    });
  });

  testWidgets('1280x800 zonder vensters: geen crash, paneel leeg',
      (tester) async {
    await _ignoringTestFontOverflow(() async {
      await _pumpHome(tester, const Size(1280, 800), const []);
      expect(_pane, findsOneWidget);
      expect(_inPane(find.text('Inplannen')), findsNothing);
      expect(_inPane(find.byType(Card)), findsNothing);
    });
  });
}
