// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast_dao.dart';

// ignore_for_file: type=lint
mixin _$ForecastDaoMixin on DatabaseAccessor<AppDatabase> {
  $ForecastCacheEntriesTable get forecastCacheEntries =>
      attachedDatabase.forecastCacheEntries;
  $HourlyForecastEntriesTable get hourlyForecastEntries =>
      attachedDatabase.hourlyForecastEntries;
  ForecastDaoManager get managers => ForecastDaoManager(this);
}

class ForecastDaoManager {
  final _$ForecastDaoMixin _db;
  ForecastDaoManager(this._db);
  $$ForecastCacheEntriesTableTableManager get forecastCacheEntries =>
      $$ForecastCacheEntriesTableTableManager(
          _db.attachedDatabase, _db.forecastCacheEntries);
  $$HourlyForecastEntriesTableTableManager get hourlyForecastEntries =>
      $$HourlyForecastEntriesTableTableManager(
          _db.attachedDatabase, _db.hourlyForecastEntries);
}
