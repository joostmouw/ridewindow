import 'package:drift/drift.dart';
import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/database/tables/forecast_cache_entries.dart';
import 'package:ridewindow/data/database/tables/hourly_forecast_entries.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';

part 'forecast_dao.g.dart';

@DriftAccessor(tables: [ForecastCacheEntries, HourlyForecastEntries])
class ForecastDao extends DatabaseAccessor<AppDatabase>
    with _$ForecastDaoMixin {
  ForecastDao(super.db);

  /// Returns the most recent cache entry for the given coordinates, or null if
  /// no cache exists.
  Future<ForecastCacheEntry?> latestCache({
    required double lat,
    required double lon,
  }) {
    return (select(forecastCacheEntries)
          ..where((t) => t.lat.equals(lat) & t.lon.equals(lon))
          ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Returns all hourly forecasts for the given cache id, ordered by time ASC.
  Future<List<HourlyForecast>> hourlyForecasts({required int cacheId}) async {
    final rows = await (select(hourlyForecastEntries)
          ..where((t) => t.cacheId.equals(cacheId))
          ..orderBy([(t) => OrderingTerm.asc(t.time)]))
        .get();
    return rows
        .map(
          (row) => HourlyForecast(
            time: DateTime.fromMillisecondsSinceEpoch(row.time * 1000),
            temperatureC: row.temperatureC,
            apparentTemperatureC: row.apparentTemperatureC,
            precipitationMm: row.precipitationMm,
            precipitationProbability: row.precipitationProbability,
            windspeedKmh: row.windspeedKmh,
            winddirectionDeg: row.winddirectionDeg,
          ),
        )
        .toList();
  }

  /// Replaces all cached forecasts for the given coordinates in a single
  /// transaction: deletes existing data, inserts fresh cache entry and rows.
  Future<void> replaceAll({
    required double lat,
    required double lon,
    required List<HourlyForecast> forecasts,
  }) async {
    await transaction(() async {
      // Find existing cache entries for this lat/lon to delete their hourly rows
      final existingCaches = await (select(forecastCacheEntries)
            ..where((t) => t.lat.equals(lat) & t.lon.equals(lon)))
          .get();

      for (final cache in existingCaches) {
        await (delete(hourlyForecastEntries)
              ..where((t) => t.cacheId.equals(cache.id)))
            .go();
      }

      // Delete all cache metadata rows for this location
      await (delete(forecastCacheEntries)
            ..where((t) => t.lat.equals(lat) & t.lon.equals(lon)))
          .go();

      // Insert new cache metadata row
      final cacheId = await into(forecastCacheEntries).insert(
        ForecastCacheEntriesCompanion.insert(
          lat: lat,
          lon: lon,
          fetchedAt: DateTime.now(),
        ),
      );

      // Insert hourly forecast rows linked to the new cache entry
      for (final forecast in forecasts) {
        await into(hourlyForecastEntries).insert(
          HourlyForecastEntriesCompanion.insert(
            cacheId: cacheId,
            time: forecast.time.millisecondsSinceEpoch ~/ 1000,
            temperatureC: Value(forecast.temperatureC),
            apparentTemperatureC: Value(forecast.apparentTemperatureC),
            precipitationMm: Value(forecast.precipitationMm),
            precipitationProbability: Value(forecast.precipitationProbability),
            windspeedKmh: Value(forecast.windspeedKmh),
            winddirectionDeg: Value(forecast.winddirectionDeg),
          ),
        );
      }
    });
  }
}
