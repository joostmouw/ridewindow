// lib/services/calendar_service.dart
// CalendarService: voegt een rijvenster toe aan Google Calendar via OAuth.
// GoogleSignIn.instance wordt uitsluitend lazy gebruikt (CAL-02): nooit
// aangemaakt bij app-start, alleen on-demand bij tik op de knop.

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';

class CalendarService {
  // GoogleSignIn 7.x gebruikt een singleton via GoogleSignIn.instance.
  // initialize() wordt precies één keer aangeroepen, bewaakt door _initialized.
  static bool _initialized = false;

  /// Initialiseert GoogleSignIn als dat nog niet is gedaan (lazy, CAL-02).
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  /// [CalendarService.addRideSlotToCalendar] voegt het rijvenster [slot] toe
  /// aan de primaire Google Calendar van de ingelogde gebruiker.
  /// Vraagt OAuth-toestemming on-demand (CAL-02).
  ///
  /// Geeft een [Exception] als de gebruiker annuleert of OAuth mislukt.
  Future<void> addRideSlotToCalendar(
    RideSlot slot,
    List<HourlyForecast> forecasts,
  ) async {
    // Stap 1: Zorg dat GoogleSignIn is geinitialiseerd (lazy).
    await _ensureInitialized();

    // Stap 2: Vraag OAuth-autorisatie voor calendarEventsScope (CAL-04).
    final GoogleSignInClientAuthorization authorization;
    try {
      authorization = await GoogleSignIn.instance.authorizationClient
          .authorizeScopes([CalendarApi.calendarEventsScope]);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Aanmelden geannuleerd');
      }
      rethrow;
    }

    // Stap 3: Bouw een authenticated HTTP-client via de extension methode.
    final client = authorization.authClient(
      scopes: [CalendarApi.calendarEventsScope],
    );

    try {
      // Stap 4: CalendarApi aanmaken.
      final calendarApi = CalendarApi(client);

      // Stap 5: Weersamenvatting opbouwen (CAL-03).
      final description = buildWeatherSummary(forecasts);

      // Stap 6: Event-titel en Event-object samenstellen.
      final title =
          'Fietsrit ${_fmtTime(slot.start)}\u2013${_fmtTime(slot.end)}';

      final event = Event(
        summary: title,
        description: description,
        start: EventDateTime(
          dateTime: slot.start,
          timeZone: 'Europe/Amsterdam',
        ),
        end: EventDateTime(
          dateTime: slot.end,
          timeZone: 'Europe/Amsterdam',
        ),
      );

      // Stap 7: Event invoegen in de primaire agenda (CAL-01, CAL-05).
      await calendarApi.events.insert(event, 'primary');
    } finally {
      // Stap 8: HTTP-client altijd sluiten (T-09-01-01: token opruimen).
      client.close();
    }
  }

  /// Haalt alle events op uit de primaire Google Calendar in het bereik
  /// [start, end). Retourneert een lijst van (start, end) DateTime-paren.
  /// Vraagt OAuth-toestemming on-demand (CAL-02).
  Future<List<({DateTime start, DateTime end})>> getEvents(
    DateTime start,
    DateTime end,
  ) async {
    await _ensureInitialized();

    final GoogleSignInClientAuthorization authorization;
    try {
      authorization = await GoogleSignIn.instance.authorizationClient
          .authorizeScopes([CalendarApi.calendarEventsScope]);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Aanmelden geannuleerd');
      }
      rethrow;
    }

    final client = authorization.authClient(
      scopes: [CalendarApi.calendarEventsScope],
    );

    try {
      final calendarApi = CalendarApi(client);
      final events = await calendarApi.events.list(
        'primary',
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      final result = <({DateTime start, DateTime end})>[];
      for (final event in events.items ?? <Event>[]) {
        final eventStart = event.start?.dateTime ?? event.start?.date;
        final eventEnd = event.end?.dateTime ?? event.end?.date;
        if (eventStart != null && eventEnd != null) {
          result.add((start: eventStart, end: eventEnd));
        }
      }
      return result;
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Public helpers (testbaar)
  // ---------------------------------------------------------------------------

  /// Bouwt een één-regel weersamenvatting van forecast-data (CAL-03).
  /// Voorbeeld: "~18°C, droog, 12km/u wind"
  /// Geeft "Geen weerdata beschikbaar" terug als [forecasts] leeg is.
  static String buildWeatherSummary(List<HourlyForecast> forecasts) {
    if (forecasts.isEmpty) return 'Geen weerdata beschikbaar';

    // Gemiddelde temperatuur.
    final temps = forecasts
        .where((f) => f.temperatureC != null)
        .map((f) => f.temperatureC!)
        .toList();
    final tempStr = temps.isEmpty
        ? '?°C'
        : '~${(temps.reduce((a, b) => a + b) / temps.length).round()}°C';

    // Totale neerslag.
    final precips = forecasts
        .where((f) => f.precipitationMm != null)
        .map((f) => f.precipitationMm!)
        .toList();
    final totalPrecip =
        precips.isEmpty ? 0.0 : precips.reduce((a, b) => a + b);
    final precipStr =
        totalPrecip == 0.0 ? 'droog' : '${totalPrecip.round()}mm';

    // Gemiddelde wind.
    final winds = forecasts
        .where((f) => f.windspeedKmh != null)
        .map((f) => f.windspeedKmh!)
        .toList();
    final windStr = winds.isEmpty
        ? '?km/u wind'
        : '${(winds.reduce((a, b) => a + b) / winds.length).round()}km/u wind';

    return '$tempStr, $precipStr, $windStr';
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
