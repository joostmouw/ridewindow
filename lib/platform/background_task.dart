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

/// Naam voor Workmanager.executeTask herkenning.
const kWeatherRefreshTaskName = 'weatherRefresh';

/// Unieke tag voor registerPeriodicTask.
const kWeatherRefreshTaskTag = 'com.ridewindow.weatherRefresh';

/// SharedPreferences sleutel voor lastRefreshed timestamp.
const _kLastRefreshedKey = 'weather.lastRefreshed';

/// SharedPreferences sleutel voor locatie-override.
const _kLocationOverrideKey = 'profile.locationOverride';

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
    // 3. SharedPreferences ophalen voor locatie-override
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
  } finally {
    // 8. Sluit HTTP client; Drift-database wordt automatisch gesloten
    client.close();
    await db.close();
  }
}
