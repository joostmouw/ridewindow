import 'package:ridewindow/core/config.dart';
import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/remote/open_meteo_client.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';

class WeatherRepository {
  // TODO Phase 7: Phase 7 wires real location via WeatherNotifier + locationProvider
  static const Duration _cacheDuration = Duration(hours: 1);

  final AppDatabase _db;
  final OpenMeteoClient _client;

  WeatherRepository({required AppDatabase db, required OpenMeteoClient client})
      : _db = db,
        _client = client;

  Future<List<HourlyForecast>> getForecast({
    double lat = kDefaultLat,
    double lon = kDefaultLon,
  }) async {
    final cache = await _db.forecastDao.latestCache(
      lat: lat,
      lon: lon,
    );
    if (cache != null &&
        DateTime.now().difference(cache.fetchedAt) < _cacheDuration) {
      return _db.forecastDao.hourlyForecasts(cacheId: cache.id);
    }
    final fresh = await _client.fetch(lat, lon);
    await _db.forecastDao.replaceAll(
      lat: lat,
      lon: lon,
      forecasts: fresh,
    );
    return fresh;
  }
}
