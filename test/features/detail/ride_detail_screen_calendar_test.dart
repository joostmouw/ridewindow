// test/features/detail/ride_detail_screen_calendar_test.dart
// Widget tests voor de "Toevoegen aan agenda" knop en PERS-04 privacy guard.
//
// Strategie: calendarServiceFactory dependency injection — geen echte OAuth,
// geen netwerkaanroepen. FakeCalendarService vervangt de echte service.
//
// Tests:
//   Test 1 — laadstatus: CircularProgressIndicator zichtbaar terwijl Future loopt
//   Test 2 — succesmelding: SnackBar met "Fietsmoment toegevoegd"
//   Test 3 — foutmelding: SnackBar met foutboodschap
//   Test 4 — PERS-04 privacy: addRideSlotToCalendar NIET aangeroepen zonder knoptik

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/units.dart';
import 'package:ridewindow/features/detail/ride_detail_screen.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/hourly_scores_provider.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/unit_prefs_provider.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/services/calendar_service.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Vaste locatie, zodat het detailscherm zijn daglichtbalk kan tekenen zonder
/// aan de echte geolocatie te vragen -- die plant een timer die na afloop van
/// de test nog open staat.
class _FakeLocation extends LocationNotifier {
  @override
  Future<LocationData> build() async =>
      const LocationData(lat: 52.3676, lon: 4.9041, city: 'Amsterdam', source: LocationSource.override);
}

// ---------------------------------------------------------------------------
// Fake Notifiers — same ProviderScope requirement as ride_detail_screen_test.dart:
// RideDetailScreen reads allHourlyScoresProvider, weatherProvider and
// plannedRidesProvider directly, so a bare MaterialApp with no ProviderScope
// ancestor throws "Bad state: No ProviderScope found".
// ---------------------------------------------------------------------------

class FakeWeatherNotifier extends WeatherNotifier {
  FakeWeatherNotifier(this.forecasts);
  final List<HourlyForecast> forecasts;

  @override
  Future<List<HourlyForecast>> build() async => forecasts;
}

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

// ---------------------------------------------------------------------------
// FakeCalendarService: blokkeert voor onbepaalde tijd via Completer.
// Gebruik om de laadstatus te observeren terwijl de Future nog loopt.
// ---------------------------------------------------------------------------
class FakeCalendarService extends CalendarService {
  final Completer<void> _completer;

  FakeCalendarService(this._completer);

  @override
  Future<void> addRideSlotToCalendar(
    RideSlot slot, {
    required String title,
    required String description,
  }) async {
    return _completer.future;
  }
}

// ---------------------------------------------------------------------------
// SuccessFakeCalendarService: voltooit direct met succes.
// ---------------------------------------------------------------------------
class SuccessFakeCalendarService extends CalendarService {
  @override
  Future<void> addRideSlotToCalendar(
    RideSlot slot, {
    required String title,
    required String description,
  }) async {
    // Direct succes — geen OAuth, geen netwerk.
  }
}

// ---------------------------------------------------------------------------
// ErrorFakeCalendarService: gooit altijd een Exception.
// ---------------------------------------------------------------------------
class ErrorFakeCalendarService extends CalendarService {
  final String message;

  ErrorFakeCalendarService(this.message);

  @override
  Future<void> addRideSlotToCalendar(
    RideSlot slot, {
    required String title,
    required String description,
  }) async {
    throw Exception(message);
  }
}

// ---------------------------------------------------------------------------
// TrackingFakeCalendarService: houdt bij of addRideSlotToCalendar is aangeroepen.
// Gebruikt voor PERS-04 privacy verificatie.
// ---------------------------------------------------------------------------
class TrackingFakeCalendarService extends CalendarService {
  bool wasCalled = false;

  @override
  Future<void> addRideSlotToCalendar(
    RideSlot slot, {
    required String title,
    required String description,
  }) async {
    wasCalled = true;
  }
}

// ---------------------------------------------------------------------------
// CapturingFakeCalendarService: legt title/description vast in plaats van iets
// te doen. Gebruikt om te bewijzen dat de agenda-knop en de deel-knop de
// vertaalde, eenheid-bewuste tekst doorgeven (quick 260921-p3d).
// ---------------------------------------------------------------------------
class CapturingFakeCalendarService extends CalendarService {
  String? capturedTitle;
  String? capturedDescription;

  @override
  Future<void> addRideSlotToCalendar(
    RideSlot slot, {
    required String title,
    required String description,
  }) async {
    capturedTitle = title;
    capturedDescription = description;
  }
}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

RideSlot makeSlot() {
  final start = DateTime(2026, 6, 10, 9, 0);
  final end = DateTime(2026, 6, 10, 13, 0);
  return RideSlot(
    start: start,
    end: end,
    overallScore: 0.85,
    tier: const Perfect(),
    hours: [
      HourlyScore(
        overall: 85,
        temperatureScore: 88,
        rainScore: 82,
        windScore: 85,
        time: start,
      ),
    ],
  );
}

List<HourlyForecast> makeForecasts() {
  final start = DateTime(2026, 6, 10, 9, 0);
  return [
    HourlyForecast(
      temperatureC: 18.0,
      apparentTemperatureC: 17.0,
      precipitationMm: 0.0,
      precipitationProbability: 0.0,
      windspeedKmh: 12.0,
      winddirectionDeg: 180.0,
      time: start,
    ),
  ];
}

/// Profiel-stub. De daglichtbalk leest sinds 2026-09-19 het daglichtgewicht uit
/// het profiel. Zonder deze override haalt `profileProvider` de echte
/// Drift-database op en blijft er een timer hangen tot na de test.
class _FakeProfile extends ProfileNotifier {
  @override
  Future<UserProfile> build() async => const UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 12,
          tempMaxIdealC: 26,
          windMaxIdealKmh: 15,
          rainMaxIdealMm: 0.5,
          darknessWeight: 0.5,
        ),
        allowedDurations: [2],
        theme: 'system',
        locationOverride: null,
        userName: null,
        locale: 'nl',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );
}

Widget wrapInMaterial(
  Widget child, {
  List<HourlyForecast> forecasts = const [],
  List<HourlyScore> hours = const [],
  Locale locale = const Locale('nl'),
  UnitPrefs units = UnitPrefs.defaults,
}) {
  return ProviderScope(
    overrides: [
      locationProvider.overrideWith(_FakeLocation.new),
      profileProvider.overrideWith(_FakeProfile.new),
      weatherProvider.overrideWith(() => FakeWeatherNotifier(forecasts)),
      allHourlyScoresProvider.overrideWithValue(hours),
      plannedRidesProvider.overrideWith(() => FakePlannedRidesNotifier()),
      unitsProvider.overrideWithValue(units),
    ],
    child: MaterialApp(
      home: child,
      locale: locale,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      theme: ThemeData(extensions: const [RideWindowTheme.light]),
    ),
  );
}

// ---------------------------------------------------------------------------
// Widget tests
// ---------------------------------------------------------------------------

void main() {
  group('RideDetailScreen agenda-knop', () {
    // -------------------------------------------------------------------------
    // Test 1: laadstatus — CircularProgressIndicator zichtbaar terwijl Future loopt.
    // -------------------------------------------------------------------------
    testWidgets(
        'Test 1 — laadstatus: CircularProgressIndicator verschijnt bij knoptik',
        (tester) async {
      final completer = Completer<void>();
      final service = FakeCalendarService(completer);
      final slot = makeSlot();
      final forecasts = makeForecasts();

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(
          slot: slot,
          forecasts: forecasts,
          calendarServiceFactory: () => service,
        ),
        forecasts: forecasts,
        hours: slot.hours,
      ));

      // Scroll naar de knop en tik.
      await tester.scrollUntilVisible(
        find.text('Toevoegen aan Google Agenda'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Toevoegen aan Google Agenda'));

      // Pump een frame — Future loopt nog (Completer niet voltooid).
      await tester.pump();

      // CircularProgressIndicator moet zichtbaar zijn.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Ruim op: voltooi de Future zodat setState() niet crasht na de test.
      completer.complete();
      await tester.pumpAndSettle();
    });

    // -------------------------------------------------------------------------
    // Test 2: succesmelding — SnackBar met "Fietsmoment toegevoegd" na succes.
    // -------------------------------------------------------------------------
    testWidgets(
        'Test 2 — succesmelding: SnackBar met "Fietsmoment toegevoegd" verschijnt',
        (tester) async {
      final service = SuccessFakeCalendarService();
      final slot = makeSlot();
      final forecasts = makeForecasts();

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(
          slot: slot,
          forecasts: forecasts,
          calendarServiceFactory: () => service,
        ),
        forecasts: forecasts,
        hours: slot.hours,
      ));

      await tester.scrollUntilVisible(
        find.text('Toevoegen aan Google Agenda'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Toevoegen aan Google Agenda'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Fietsmoment toegevoegd'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 3: foutmelding — SnackBar met foutboodschap als service Exception gooit.
    // -------------------------------------------------------------------------
    testWidgets(
        'Test 3 — foutmelding: SnackBar met foutboodschap bij Exception',
        (tester) async {
      final service = ErrorFakeCalendarService('test fout');
      final slot = makeSlot();
      final forecasts = makeForecasts();

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(
          slot: slot,
          forecasts: forecasts,
          calendarServiceFactory: () => service,
        ),
        forecasts: forecasts,
        hours: slot.hours,
      ));

      await tester.scrollUntilVisible(
        find.text('Toevoegen aan Google Agenda'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Toevoegen aan Google Agenda'));
      await tester.pumpAndSettle();

      expect(find.textContaining('test fout'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 4 (PERS-04 privacy): addRideSlotToCalendar wordt NOOIT aangeroepen
    // tenzij de gebruiker expliciet op de knop tikt.
    // Data verlaat het apparaat niet zonder expliciete gebruikersactie (PERS-04).
    // -------------------------------------------------------------------------
    testWidgets(
        'Test 4 — PERS-04 privacy: calendarServiceFactory niet aangeroepen zonder knoptik',
        (tester) async {
      final service = TrackingFakeCalendarService();
      final slot = makeSlot();
      final forecasts = makeForecasts();

      // Pump het scherm zonder enige interactie.
      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(
          slot: slot,
          forecasts: forecasts,
          calendarServiceFactory: () => service,
        ),
        forecasts: forecasts,
        hours: slot.hours,
      ));
      await tester.pump();

      // PERS-04 verificatie: addRideSlotToCalendar mag NIET zijn aangeroepen.
      expect(service.wasCalled, isFalse,
          reason:
              'PERS-04: CalendarService.addRideSlotToCalendar mag niet worden '
              'aangeroepen zonder expliciete gebruikerstik — data verlaat het '
              'apparaat niet tenzij de gebruiker toestemming geeft.');
    });
  });

  // ---------------------------------------------------------------------------
  // Regressiematrix (quick 260921-p3d): de agenda-knop bouwt title/description
  // via S.of(context) en unitsProvider in plaats van CalendarService's oude,
  // altijd-Nederlandse km/u-tekst. _shareSlot() roept dezelfde private
  // _weatherSummaryText aan als de agenda-knop, dus deze matrix via de
  // agenda-knop dekt beide aanroepers -- share_plus zelf is niet via DI
  // vervangbaar en blijft daarom buiten deze testlaag.
  // ---------------------------------------------------------------------------
  group('RideDetailScreen agenda-tekst volgt taal en eenheden', () {
    Future<void> tapAddToCalendar(WidgetTester tester, S s) async {
      await tester.scrollUntilVisible(
        find.text(s.addToGoogleCalendar),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(s.addToGoogleCalendar));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'NL, standaardeenheden: titel "Fietsrit", omschrijving "droog" en "km/h" (niet "km/u")',
        (tester) async {
      final s = await S.delegate.load(const Locale('nl'));
      final service = CapturingFakeCalendarService();
      final slot = makeSlot();
      final forecasts = makeForecasts();

      await tester.pumpWidget(
        wrapInMaterial(
          RideDetailScreen(
            slot: slot,
            forecasts: forecasts,
            calendarServiceFactory: () => service,
          ),
          forecasts: forecasts,
          hours: slot.hours,
          locale: const Locale('nl'),
        ),
      );
      await tapAddToCalendar(tester, s);

      expect(service.capturedTitle, contains('Fietsrit'));
      expect(service.capturedDescription, contains('droog'));
      expect(service.capturedDescription, contains('km/h'));
      expect(service.capturedDescription, isNot(contains('km/u')));
    });

    testWidgets(
        'EN, standaardeenheden: titel "Bike ride", omschrijving "dry" en "km/h"',
        (tester) async {
      final s = await S.delegate.load(const Locale('en'));
      final service = CapturingFakeCalendarService();
      final slot = makeSlot();
      final forecasts = makeForecasts();

      await tester.pumpWidget(
        wrapInMaterial(
          RideDetailScreen(
            slot: slot,
            forecasts: forecasts,
            calendarServiceFactory: () => service,
          ),
          forecasts: forecasts,
          hours: slot.hours,
          locale: const Locale('en'),
        ),
      );
      await tapAddToCalendar(tester, s);

      expect(service.capturedTitle, contains('Bike ride'));
      expect(service.capturedDescription, contains('dry'));
      expect(service.capturedDescription, contains('km/h'));
    });

    testWidgets(
        'WindUnit.mph: omschrijving bevat de omgerekende waarde en "mph"',
        (tester) async {
      final s = await S.delegate.load(const Locale('nl'));
      final service = CapturingFakeCalendarService();
      final slot = makeSlot();
      final forecasts = makeForecasts();

      await tester.pumpWidget(
        wrapInMaterial(
          RideDetailScreen(
            slot: slot,
            forecasts: forecasts,
            calendarServiceFactory: () => service,
          ),
          forecasts: forecasts,
          hours: slot.hours,
          units: const UnitPrefs(wind: WindUnit.mph),
        ),
      );
      await tapAddToCalendar(tester, s);

      // 12km/u * 0.621371 = 7,46 -> afgerond 7 mph.
      expect(service.capturedDescription, contains('7 mph'));
    });

    testWidgets(
        'WindUnit.beaufort: omschrijving bevat de met beaufortFromKmh berekende windkracht en "Bft"',
        (tester) async {
      final s = await S.delegate.load(const Locale('nl'));
      final service = CapturingFakeCalendarService();
      final slot = makeSlot();
      final forecasts = makeForecasts();

      await tester.pumpWidget(
        wrapInMaterial(
          RideDetailScreen(
            slot: slot,
            forecasts: forecasts,
            calendarServiceFactory: () => service,
          ),
          forecasts: forecasts,
          hours: slot.hours,
          units: const UnitPrefs(wind: WindUnit.beaufort),
        ),
      );
      await tapAddToCalendar(tester, s);

      // beaufortFromKmh(12) == 3 (grenzen 1, 6, 12, 20 ...).
      expect(service.capturedDescription, contains('3 Bft'));
    });

    testWidgets(
        'TempUnit.fahrenheit: omschrijving bevat de omgerekende temperatuur en "°F"',
        (tester) async {
      final s = await S.delegate.load(const Locale('nl'));
      final service = CapturingFakeCalendarService();
      final slot = makeSlot();
      final forecasts = makeForecasts();

      await tester.pumpWidget(
        wrapInMaterial(
          RideDetailScreen(
            slot: slot,
            forecasts: forecasts,
            calendarServiceFactory: () => service,
          ),
          forecasts: forecasts,
          hours: slot.hours,
          units: const UnitPrefs(temp: TempUnit.fahrenheit),
        ),
      );
      await tapAddToCalendar(tester, s);

      // 18°C -> 18*9/5+32 = 64,4 -> afgerond 64°F.
      expect(service.capturedDescription, contains('64°F'));
    });

    testWidgets(
        'Lege forecast-lijst, NL: omschrijving is exact calendarNoWeatherData (NL)',
        (tester) async {
      final s = await S.delegate.load(const Locale('nl'));
      final service = CapturingFakeCalendarService();
      final slot = makeSlot();

      await tester.pumpWidget(
        wrapInMaterial(
          RideDetailScreen(
            slot: slot,
            forecasts: const [],
            calendarServiceFactory: () => service,
          ),
          hours: slot.hours,
          locale: const Locale('nl'),
        ),
      );
      await tapAddToCalendar(tester, s);

      expect(service.capturedDescription, equals(s.calendarNoWeatherData));
      expect(service.capturedDescription, equals('Geen weerdata beschikbaar'));
    });

    testWidgets(
        'Lege forecast-lijst, EN: omschrijving is exact calendarNoWeatherData (EN)',
        (tester) async {
      final s = await S.delegate.load(const Locale('en'));
      final service = CapturingFakeCalendarService();
      final slot = makeSlot();

      await tester.pumpWidget(
        wrapInMaterial(
          RideDetailScreen(
            slot: slot,
            forecasts: const [],
            calendarServiceFactory: () => service,
          ),
          hours: slot.hours,
          locale: const Locale('en'),
        ),
      );
      await tapAddToCalendar(tester, s);

      expect(service.capturedDescription, equals(s.calendarNoWeatherData));
      expect(service.capturedDescription, equals('No weather data available'));
    });
  });
}
