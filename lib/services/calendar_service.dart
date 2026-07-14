// lib/services/calendar_service.dart
// CalendarService: voegt een rijvenster toe aan Google Calendar via OAuth.
// GoogleSignIn.instance wordt uitsluitend lazy gebruikt (CAL-02): nooit
// aangemaakt bij app-start, alleen on-demand bij tik op de knop -- behalve
// op web, waar main.dart GoogleSignIn eagerly warmt via
// CalendarService.warmUpForWeb() (zie CAL-06).

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';

class CalendarService {
  // GoogleSignIn 7.x gebruikt een singleton via GoogleSignIn.instance.
  // initialize() wordt precies één keer aangeroepen, bewaakt door _initialized.
  static bool _initialized = false;

  // Gememoized in-flight initialize()-aanroep (Rule 1 bugfix, CAL-06 follow-up).
  // GoogleSignIn.instance.initialize() gooit "Bad state: init() has already
  // been called" als het een tweede keer wordt aangeroepen terwijl de eerste
  // aanroep nog niet is afgerond. Op web kan warmUpForWeb()'s await nog
  // in-flight zijn wanneer de gebruiker meteen op "Add to calendar" tikt en
  // _ensureInitialized() gelijktijdig start -- beide moeten dezelfde
  // onderliggende initialize()-aanroep delen in plaats van elk hun eigen te
  // starten. _initFuture wordt op falen weer op null gezet zodat een latere
  // aanroep het opnieuw kan proberen (zelfde "mislukking is niet
  // fataal"-semantiek als voorheen).
  static Future<void>? _initFuture;

  static Future<void> _sharedInitialize() {
    return _initFuture ??= GoogleSignIn.instance.initialize().then((_) {
      _initialized = true;
    }).catchError((Object e, StackTrace st) {
      _initFuture = null;
      _initialized = false;
      // ignore: only_throw_errors
      throw e;
    });
  }

  /// Web-only eager warmup (CAL-06): initialiseert GoogleSignIn.instance
  /// vooraf zodat er, tegen de tijd dat de gebruiker op "Add to calendar"
  /// tikt, geen onopgeloste await meer in de call chain zit voordat
  /// authorizeScopes() de OAuth-popup opent. Safari's popup-blocker
  /// vereist dat de tap-naar-popup call chain synchroon blijft (zie
  /// RESEARCH.md Pitfall 1) -- deze methode elimineert die async gap op de
  /// allereerste tik van een sessie.
  ///
  /// Veilig om meerdere keren aan te roepen, en veilig om gelijktijdig met
  /// [_ensureInitialized] te lopen: beide delen dezelfde gememoized
  /// [_sharedInitialize] future, dus er wordt nooit meer dan één keer
  /// `GoogleSignIn.instance.initialize()` tegelijk aangeroepen. Een mislukte
  /// warmup is nooit fataal voor de app-start: fouten worden stilzwijgend
  /// opgevangen, en [_initialized] blijft dan `false` zodat de eerste echte
  /// tik alsnog via [_ensureInitialized]'s eigen (async) init-pad loopt --
  /// hetzelfde altijd-lazy pad als native Android (CAL-02).
  static Future<void> warmUpForWeb() async {
    if (_initialized) return;
    try {
      await _sharedInitialize();
    } catch (_) {
      // Web-only best-effort warmup (CAL-06). Een fout hier mag de
      // app-start nooit laten crashen -- de eerste echte tik valt gewoon
      // terug op _ensureInitialized()'s eigen (async) init-aanroep, net als
      // native's altijd-lazy pad. _initialized blijft false zodat die
      // fallback alsnog draait.
    }
  }

  /// Initialiseert GoogleSignIn als dat nog niet is gedaan (lazy, CAL-02).
  /// Deelt [_sharedInitialize] met [warmUpForWeb] zodat een gelijktijdige
  /// web-warmup en een tik op "Add to calendar" nooit twee losse
  /// initialize()-aanroepen tegelijk starten (Rule 1 bugfix).
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _sharedInitialize();
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
