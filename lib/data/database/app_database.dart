import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/availability_grid_entries.dart';
import 'tables/forecast_cache_entries.dart';
import 'tables/hourly_forecast_entries.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [ForecastCacheEntries, HourlyForecastEntries, AvailabilityGridEntries],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // MIGRATION RULE: columns are append-only.
  // Never remove or rename a column; always add new columns in a new
  // schemaVersion block with a nullable default or an explicit default value.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 -> future: add columns here
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'ridewindow',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
