// lib/platform/background_task.dart
// WorkManager callback — draait in aparte Dart-isolate.
// KRITISCH: Geen Riverpod/ProviderScope — eigen Drift + HTTP client initialiseren.

import 'package:drift_flutter/drift_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:ridewindow/core/config.dart';
import 'package:ridewindow/core/nl_cities.dart';
import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/remote/open_meteo_client.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/services/availability_filter.dart';
import 'package:ridewindow/domain/services/scoring_engine.dart';
import 'package:ridewindow/domain/services/slot_generator.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/services/widget_update_service.dart';

/// Naam voor Workmanager.executeTask herkenning.
const kWeatherRefreshTaskName = 'weatherRefresh';

/// Unieke tag voor registerPeriodicTask.
const kWeatherRefreshTaskTag = 'com.ridewindow.weatherRefresh';

/// SharedPreferences sleutel voor lastRefreshed timestamp.
const _kLastRefreshedKey = 'weather.lastRefreshed';

/// SharedPreferences sleutel voor locatie-override.
const _kLocationOverrideKey = 'profile.locationOverride';

// SharedPreferences sleutels voor profiel (gespiegeld van ProfileNotifier)
const _kTempMin = 'profile.tempMinIdealC';
const _kTempMax = 'profile.tempMaxIdealC';
const _kWindMax = 'profile.windMaxIdealKmh';
const _kRainMax = 'profile.rainMaxIdealMm';
const _kDurations = 'profile.allowedDurations';

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
    final locationOverride = prefs.getString(_kLocationOverrideKey);

    // 4. Bepaal lat/lon — locatie-override heeft prioriteit boven kDefaultLat/kDefaultLon
    double lat = kDefaultLat;
    double lon = kDefaultLon;

    if (locationOverride != null && locationOverride.isNotEmpty) {
      final city = kNlCities
          .where((c) => c.name == locationOverride)
          .firstOrNull;
      if (city != null) {
        lat = city.lat;
        lon = city.lon;
      }
    }

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
  // Lees profiel-instellingen met dezelfde defaults als ProfileNotifier
  final tolerances = WeatherTolerances(
    tempMinIdealC: prefs.getDouble(_kTempMin) ?? 12.0,
    tempMaxIdealC: prefs.getDouble(_kTempMax) ?? 26.0,
    windMaxIdealKmh: prefs.getDouble(_kWindMax) ?? 15.0,
    rainMaxIdealMm: prefs.getDouble(_kRainMax) ?? 0.5,
  );

  final durationStrings = prefs.getStringList(_kDurations) ?? ['2', '3', '5'];
  final durations = durationStrings
      .map((s) => int.tryParse(s) ?? 0)
      .where((d) => d > 0)
      .toList();
  final allowedDurations = durations.isEmpty ? [2, 3, 5] : durations;

  // Lees geblokkeerde uren (zelfde formaat als AvailabilityNotifier)
  final blockedStrings =
      prefs.getStringList('availability.blockedHours') ?? [];
  final blockedHours = <DateTime, BlockType>{};
  for (final entry in blockedStrings) {
    try {
      final parts = entry.split('|');
      if (parts.length == 2) {
        final dt = DateTime.parse(parts[0]);
        final blockType = BlockType.values.byName(parts[1]);
        blockedHours[dt] = blockType;
      }
    } catch (_) {
      // Negeer corrupte entries
    }
  }

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
  );
  allSlots = generator.refine(allSlots, forecasts);

  var filtered = filter.apply(allSlots, blockedHours);
  filtered = generator.dedup(filtered);

  return filtered.firstOrNull;
}
