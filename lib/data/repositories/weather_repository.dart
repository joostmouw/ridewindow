import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/remote/open_meteo_client.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';

class WeatherRepository {
  static const double _amsterdamLat = 52.3676;
  static const double _amsterdamLon = 4.9041;
  // TODO Phase 7: replace with LocationService.currentLatLon()
  static const Duration _cacheDuration = Duration(hours: 1);

  final AppDatabase _db;
  final OpenMeteoClient _client;

  WeatherRepository({required AppDatabase db, required OpenMeteoClient client})
      : _db = db,
        _client = client;

  Future<List<HourlyForecast>> getForecast() async {
    final cache = await _db.forecastDao.latestCache(
      lat: _amsterdamLat,
      lon: _amsterdamLon,
    );
    if (cache != null &&
        DateTime.now().difference(cache.fetchedAt) < _cacheDuration) {
      return _db.forecastDao.hourlyForecasts(cacheId: cache.id);
    }
    final fresh = await _client.fetch(_amsterdamLat, _amsterdamLon);
    await _db.forecastDao.replaceAll(
      lat: _amsterdamLat,
      lon: _amsterdamLon,
      forecasts: fresh,
    );
    return fresh;
  }
}
