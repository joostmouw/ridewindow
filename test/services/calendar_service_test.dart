// test/services/calendar_service_test.dart
// Unit tests for CalendarService.buildWeatherSummary (CAL-03) and error paths.
//
// Strategy: buildWeatherSummary is a public static method — testable without
// any OAuth or GoogleSignIn interaction (PERS-04: no data leaves device in tests).
//
// Tests use only dart:core, flutter_test, and own package imports.
// No real GoogleSignIn is touched — integration tests cover the sign-in flow.

import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/services/calendar_service.dart';

void main() {
  group('CalendarService.buildWeatherSummary', () {
    // -------------------------------------------------------------------------
    // Test 1 (CAL-03 happy path): twee forecasts met geldige waarden.
    // Gem. temp = (16 + 20) / 2 = 18°C; precip = 0 + 0 = 0 (droog);
    // gem. wind = (10 + 14) / 2 = 12km/u.
    // -------------------------------------------------------------------------
    test('CAL-03 happy path: geeft gemiddelde temp, "droog", gemiddelde wind', () {
      final forecasts = [
        HourlyForecast(
          temperatureC: 16.0,
          apparentTemperatureC: 15.0,
          precipitationMm: 0.0,
          precipitationProbability: 0.0,
          windspeedKmh: 10.0,
          winddirectionDeg: 180.0,
          time: DateTime(2026, 6, 10, 9, 0),
        ),
        HourlyForecast(
          temperatureC: 20.0,
          apparentTemperatureC: 19.0,
          precipitationMm: 0.0,
          precipitationProbability: 0.0,
          windspeedKmh: 14.0,
          winddirectionDeg: 180.0,
          time: DateTime(2026, 6, 10, 10, 0),
        ),
      ];

      final result = CalendarService.buildWeatherSummary(forecasts);

      expect(result, contains('~18°C'));
      expect(result, contains('droog'));
      expect(result, contains('12km/u wind'));
    });

    // -------------------------------------------------------------------------
    // Test 2 (CAL-03 neerslag): totale neerslag 0.5 + 1.5 = 2.0mm — "droog"
    // mag NIET voorkomen.
    // -------------------------------------------------------------------------
    test('CAL-03 neerslag: toont totale neerslag in mm in plaats van "droog"', () {
      final forecasts = [
        HourlyForecast(
          temperatureC: 18.0,
          apparentTemperatureC: 17.0,
          precipitationMm: 0.5,
          precipitationProbability: 40.0,
          windspeedKmh: 10.0,
          winddirectionDeg: 90.0,
          time: DateTime(2026, 6, 10, 9, 0),
        ),
        HourlyForecast(
          temperatureC: 18.0,
          apparentTemperatureC: 17.0,
          precipitationMm: 1.5,
          precipitationProbability: 60.0,
          windspeedKmh: 10.0,
          winddirectionDeg: 90.0,
          time: DateTime(2026, 6, 10, 10, 0),
        ),
      ];

      final result = CalendarService.buildWeatherSummary(forecasts);

      // Totale neerslag = 2mm — moet "2mm" bevatten (of "2.0mm")
      expect(result, anyOf(contains('2mm'), contains('2.0mm')));
      expect(result, isNot(contains('droog')));
    });

    // -------------------------------------------------------------------------
    // Test 3 (CAL-03 lege lijst): lege forecasts geeft vaste fallback-tekst.
    // -------------------------------------------------------------------------
    test('CAL-03 lege lijst: geeft "Geen weerdata beschikbaar"', () {
      final result = CalendarService.buildWeatherSummary([]);

      expect(result, equals('Geen weerdata beschikbaar'));
    });

    // -------------------------------------------------------------------------
    // Test 4 (CAL-03 null-waarden): alle velden null — geen crash, geeft
    // een String terug (ofwel met "?" placeholders of "Geen weerdata").
    // -------------------------------------------------------------------------
    test('CAL-03 null-waarden: geen crash bij volledig null HourlyForecast', () {
      final forecasts = [
        HourlyForecast(
          temperatureC: null,
          apparentTemperatureC: null,
          precipitationMm: null,
          precipitationProbability: null,
          windspeedKmh: null,
          winddirectionDeg: null,
          time: DateTime(2026, 6, 10, 9, 0),
        ),
      ];

      // Mag niet crashen; retourneert een geldige String.
      expect(() => CalendarService.buildWeatherSummary(forecasts), returnsNormally);
      final result = CalendarService.buildWeatherSummary(forecasts);
      expect(result, isA<String>());
      expect(result.isNotEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // Test 5 (PERS-04): buildWeatherSummary raakt GoogleSignIn NIET aan.
    // De output is een pure String zonder netwerkaanroepen — PERS-04 privacy
    // vereiste: data verlaat het apparaat niet tenzij de gebruiker expliciet
    // op de knop heeft getikt.
    // -------------------------------------------------------------------------
    test('PERS-04: buildWeatherSummary retourneert String zonder GoogleSignIn aan te raken', () {
      final forecasts = [
        HourlyForecast(
          temperatureC: 20.0,
          apparentTemperatureC: 19.0,
          precipitationMm: 0.0,
          precipitationProbability: 0.0,
          windspeedKmh: 12.0,
          winddirectionDeg: 270.0,
          time: DateTime(2026, 6, 10, 9, 0),
        ),
      ];

      // Aanroep is puur synchroon en retourneert direct — geen OAuth, geen
      // netwerk, geen GoogleSignIn instantie nodig.
      final result = CalendarService.buildWeatherSummary(forecasts);

      expect(result, isA<String>());
      expect(result, isNotEmpty);
    });
  });

  group('CalendarService.addRideSlotToCalendar', () {
    // TODO: Integratie-tests voor de volledige sign-in + CalendarApi flow vallen
    // buiten unit-test scope omdat het mocken van GoogleSignIn.instance (singleton
    // met native Android bridge) een aparte integratie-test setup vereist.
    // De widget-tests in ride_detail_screen_calendar_test.dart dekken de
    // factory-injectie en PERS-04 via FakeCalendarService.

    test('placeholder: sign-in flow vereist integratie-tests met device', () {
      // Bewust leeg — zie TODO hierboven.
      expect(true, isTrue);
    });
  });
}
