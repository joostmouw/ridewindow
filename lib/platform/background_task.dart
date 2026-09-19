// lib/platform/background_task.dart
// WorkManager callback — draait in aparte Dart-isolate.
// KRITISCH: Geen Riverpod/ProviderScope — eigen Drift + HTTP client initialiseren.

import 'package:drift_flutter/drift_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:ridewindow/core/config.dart';
import 'package:ridewindow/core/cities.dart';
import 'package:ridewindow/data/repositories/last_known_location_store.dart';
import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/remote/open_meteo_client.dart';
import 'package:ridewindow/data/repositories/availability_repository.dart';
import 'package:ridewindow/data/repositories/profile_repository.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/services/availability_filter.dart';
import 'package:ridewindow/domain/services/scoring_engine.dart';
import 'package:ridewindow/domain/services/slot_generator.dart';
import 'package:ridewindow/services/widget_update_service.dart';

/// Naam voor Workmanager.executeTask herkenning.
const kWeatherRefreshTaskName = 'weatherRefresh';

/// Unieke tag voor registerPeriodicTask.
const kWeatherRefreshTaskTag = 'com.ridewindow.weatherRefresh';

/// SharedPreferences sleutel voor lastRefreshed timestamp.
const _kLastRefreshedKey = 'weather.lastRefreshed';

/// Top-level callback — MOET top-level zijn voor WorkManager isolate.
/// @pragma voorkomt dat de Dart tree-shaker deze functie verwijdert in release-builds.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kWeatherRefreshTaskName) {
      await _runWeatherRefresh();
    }
    return Future.value(true);
  });
}

/// Haalt weerdata op en slaat deze op in Drift + SharedPreferences.
/// Berekent daarna het volgende beste rijslot en schrijft het naar het widget.
/// Draait volledig isolate-safe: geen Riverpod, geen foreground-staat.
Future<void> _runWeatherRefresh() async {
  // 1. Eigen Drift DB initialiseren (zelfde naam als de foreground DB)
  final db = AppDatabase(
    driftDatabase(
      name: 'ridewindow',
    ),
  );

  // 2. Eigen HTTP client instantiëren
  final client = http.Client();

  try {
    // 3. SharedPreferences ophalen voor locatie-override + profiel-instellingen
    final prefs = await SharedPreferences.getInstance();
    final profileRepo = ProfileRepository(prefs);
    final locationOverride = profileRepo.readLocal().locationOverride;

    // 4. Bepaal lat/lon. Dezelfde volgorde als location_provider.dart, op GPS
    //    na -- dit is een isolate zonder scherm en kan geen peiling vragen.
    //    Vandaar de laatst bekende positie: zonder die stap overschreef deze
    //    taak elke drie uur de verse GPS-voorspelling met die van Amsterdam,
    //    en hing het van het toeval af welke van de twee je te zien kreeg.
    final (lat, lon) = resolveBackgroundLocation(
      prefs: prefs,
      locationOverride: locationOverride,
    );

    // 5. Fetch uitvoeren via OpenMeteoClient (direct — geen WeatherRepository wrapper)
    final meteoClient = OpenMeteoClient(client: client);
    final forecasts = await meteoClient.fetch(lat, lon);

    // 6. Schrijf resultaten naar Drift ForecastEntries tabel
    await db.forecastDao.replaceAll(
      lat: lat,
      lon: lon,
      forecasts: forecasts,
    );

    // 7. Schrijf lastRefreshed timestamp naar SharedPreferences
    await prefs.setInt(
      _kLastRefreshedKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    // 8. Bereken volgende beste rijslot en update het home screen widget
    try {
      final nextSlot = await _computeNextSlot(prefs, forecasts);
      await WidgetUpdateService.update(nextSlot);
    } catch (_) {
      // Widget-update is niet kritisch — negeer fouten zodat de WeatherRefresh
      // taak alsnog succesvol wordt gerapporteerd aan WorkManager.
    }
  } finally {
    // 9. Sluit HTTP client; Drift-database wordt automatisch gesloten
    client.close();
    await db.close();
  }
}

/// Berekent het volgende beste rijslot op basis van verse [forecasts] en de
/// opgeslagen profielinstellingen in [prefs].
/// Retourneert null als er geen acceptabel slot is.
Future<RideSlot?> _computeNextSlot(
  SharedPreferences prefs,
  List<HourlyForecast> forecasts,
) async {
  // Lees profiel-instellingen via ProfileRepository (zelfde bron als ProfileNotifier)
  final profile = ProfileRepository(prefs).readLocal();
  final tolerances = profile.tolerances;
  final allowedDurations = profile.allowedDurations;

  // Lees geblokkeerde uren via AvailabilityRepository (zelfde bron als AvailabilityNotifier)
  final blockedHours = AvailabilityRepository(prefs).readLocal();

  // Score + genereer + filter — zelfde pipeline als SlotsNotifier
  final scoring = ScoringEngine();
  final generator = SlotGenerator();
  final filter = AvailabilityFilter();

  final scores = forecasts
      .map((fc) => scoring.score(fc, tolerances))
      .toList();

  var allSlots = generator.generate(
    scores,
    allowedDurations: allowedDurations,
    minHour: 6,
    maxHour: 22,
    notBefore: DateTime.now(),
  );
  allSlots = generator.refine(allSlots, forecasts);

  var filtered = filter.apply(allSlots, blockedHours);
  filtered = generator.dedup(filtered);

  return filtered.firstOrNull;
}

/// Welke plek de achtergrondtaak moet ophalen.
///
/// Dezelfde volgorde als `location_provider.dart`, op GPS na -- dit draait in
/// een isolate zonder scherm en kan geen peiling vragen. De middelste stap is
/// de reparatie van 2026-09-19: zonder de laatst bekende positie viel deze taak
/// terug op Amsterdam en overschreef ze elke drie uur de verse voorspelling van
/// een gebruiker die GPS gebruikt. Welke van de twee je zag, hing af van
/// wanneer je keek.
///
/// Staat apart van [callbackDispatcher] zodat hij zonder WorkManager te testen is.
(double, double) resolveBackgroundLocation({
  required SharedPreferences prefs,
  required String? locationOverride,
}) {
  if (locationOverride != null && locationOverride.isNotEmpty) {
    final city = kCities.where((c) => c.name == locationOverride).firstOrNull;
    if (city != null) return (city.lat, city.lon);
  }

  final lastKnown = LastKnownLocationStore(prefs).read();
  if (lastKnown != null) return (lastKnown.lat, lastKnown.lon);

  return (kDefaultLat, kDefaultLon);
}
