// test/features/detail/ride_detail_screen_calendar_test.dart
// Widget tests voor de "Toevoegen aan agenda" knop en PERS-04 privacy guard.
//
// Strategie: calendarServiceFactory dependency injection — geen echte OAuth,
// geen netwerkaanroepen. FakeCalendarService vervangt de echte service.
//
// Tests:
//   Test 1 — laadstatus: CircularProgressIndicator zichtbaar terwijl Future loopt
//   Test 2 — succesmelding: SnackBar met "Rijvenster toegevoegd"
//   Test 3 — foutmelding: SnackBar met foutboodschap
//   Test 4 — PERS-04 privacy: addRideSlotToCalendar NIET aangeroepen zonder knoptik

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/features/detail/ride_detail_screen.dart';
import 'package:ridewindow/services/calendar_service.dart';

// ---------------------------------------------------------------------------
// FakeCalendarService: blokkeert voor onbepaalde tijd via Completer.
// Gebruik om de laadstatus te observeren terwijl de Future nog loopt.
// ---------------------------------------------------------------------------
class FakeCalendarService extends CalendarService {
  final Completer<void> _completer;

  FakeCalendarService(this._completer);

  @override
  Future<void> addRideSlotToCalendar(
    RideSlot slot,
    List<HourlyForecast> forecasts,
  ) async {
    return _completer.future;
  }
}

// ---------------------------------------------------------------------------
// SuccessFakeCalendarService: voltooit direct met succes.
// ---------------------------------------------------------------------------
class SuccessFakeCalendarService extends CalendarService {
  @override
  Future<void> addRideSlotToCalendar(
    RideSlot slot,
    List<HourlyForecast> forecasts,
  ) async {
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
    RideSlot slot,
    List<HourlyForecast> forecasts,
  ) async {
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
    RideSlot slot,
    List<HourlyForecast> forecasts,
  ) async {
    wasCalled = true;
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

Widget wrapInMaterial(Widget child) {
  return MaterialApp(home: child);
}

// ---------------------------------------------------------------------------
// Widget tests
// ---------------------------------------------------------------------------

void main() {
  group('RideDetailScreen agenda-knop', () {
    // -------------------------------------------------------------------------
    // Test 1: laadstatus — CircularProgressIndicator zichtbaar terwijl Future loopt.
    // -------------------------------------------------------------------------
    testWidgets('Test 1 — laadstatus: CircularProgressIndicator verschijnt bij knoptik', (tester) async {
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
      ));

      // Scroll naar de knop en tik.
      await tester.scrollUntilVisible(
        find.text('Toevoegen aan agenda'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Toevoegen aan agenda'));

      // Pump een frame — Future loopt nog (Completer niet voltooid).
      await tester.pump();

      // CircularProgressIndicator moet zichtbaar zijn.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Ruim op: voltooi de Future zodat setState() niet crasht na de test.
      completer.complete();
      await tester.pumpAndSettle();
    });

    // -------------------------------------------------------------------------
    // Test 2: succesmelding — SnackBar met "Rijvenster toegevoegd" na succes.
    // -------------------------------------------------------------------------
    testWidgets('Test 2 — succesmelding: SnackBar met "Rijvenster toegevoegd" verschijnt', (tester) async {
      final service = SuccessFakeCalendarService();
      final slot = makeSlot();
      final forecasts = makeForecasts();

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(
          slot: slot,
          forecasts: forecasts,
          calendarServiceFactory: () => service,
        ),
      ));

      await tester.scrollUntilVisible(
        find.text('Toevoegen aan agenda'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Toevoegen aan agenda'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Rijvenster toegevoegd'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 3: foutmelding — SnackBar met foutboodschap als service Exception gooit.
    // -------------------------------------------------------------------------
    testWidgets('Test 3 — foutmelding: SnackBar met foutboodschap bij Exception', (tester) async {
      final service = ErrorFakeCalendarService('test fout');
      final slot = makeSlot();
      final forecasts = makeForecasts();

      await tester.pumpWidget(wrapInMaterial(
        RideDetailScreen(
          slot: slot,
          forecasts: forecasts,
          calendarServiceFactory: () => service,
        ),
      ));

      await tester.scrollUntilVisible(
        find.text('Toevoegen aan agenda'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Toevoegen aan agenda'));
      await tester.pumpAndSettle();

      expect(find.textContaining('test fout'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 4 (PERS-04 privacy): addRideSlotToCalendar wordt NOOIT aangeroepen
    // tenzij de gebruiker expliciet op de knop tikt.
    // Data verlaat het apparaat niet zonder expliciete gebruikersactie (PERS-04).
    // -------------------------------------------------------------------------
    testWidgets('Test 4 — PERS-04 privacy: calendarServiceFactory niet aangeroepen zonder knoptik', (tester) async {
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
      ));
      await tester.pump();

      // PERS-04 verificatie: addRideSlotToCalendar mag NIET zijn aangeroepen.
      expect(service.wasCalled, isFalse,
          reason: 'PERS-04: CalendarService.addRideSlotToCalendar mag niet worden '
              'aangeroepen zonder expliciete gebruikerstik — data verlaat het '
              'apparaat niet tenzij de gebruiker toestemming geeft.');
    });
  });
}
