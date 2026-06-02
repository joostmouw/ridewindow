import 'package:drift/drift.dart';

import 'forecast_cache_entries.dart';

class HourlyForecastEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cacheId =>
      integer().references(ForecastCacheEntries, #id)();
  IntColumn get time => integer()(); // unixtime; convert to DateTime in domain layer
  RealColumn get temperatureC => real().nullable()();
  RealColumn get apparentTemperatureC => real().nullable()();
  RealColumn get precipitationMm => real().nullable()();
  RealColumn get precipitationProbability => real().nullable()();
  RealColumn get windspeedKmh => real().nullable()();
  RealColumn get winddirectionDeg => real().nullable()();
}
