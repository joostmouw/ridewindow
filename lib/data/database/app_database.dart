import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'daos/forecast_dao.dart';
import 'daos/sync_outbox_dao.dart';
import 'tables/availability_grid_entries.dart';
import 'tables/forecast_cache_entries.dart';
import 'tables/hourly_forecast_entries.dart';
import 'tables/sync_outbox_entries.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ForecastCacheEntries,
    HourlyForecastEntries,
    AvailabilityGridEntries,
    SyncOutboxEntries,
  ],
  daos: [ForecastDao, SyncOutboxDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  // MIGRATION RULE: columns are append-only.
  // Never remove or rename a column; always add new columns in a new
  // schemaVersion block with a nullable default or an explicit default value.
  // New tables follow the same additive rule: add them in `tables:` above
  // and create them in `onUpgrade` behind an `if (from < N)` guard.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 -> future: add columns here
          // v1 -> v2: additive-only — new SyncOutboxEntries table (SYNC-05).
          if (from < 2) {
            await m.createTable(syncOutboxEntries);
          }
        },
      );

  @override
  ForecastDao get forecastDao => ForecastDao(this);

  @override
  SyncOutboxDao get syncOutboxDao => SyncOutboxDao(this);

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'ridewindow',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }
}
