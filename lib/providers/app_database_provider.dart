import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/remote/open_meteo_client.dart';
import 'package:ridewindow/data/repositories/weather_repository.dart';

part 'app_database_provider.g.dart';

/// Provides the singleton AppDatabase for the app lifetime.
/// keepAlive: true — database must survive provider disposal (always-on).
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  return AppDatabase();
}

/// Provides a stateless OpenMeteoClient.
/// AutoDispose is fine: the client holds no state.
@riverpod
OpenMeteoClient openMeteoClient(Ref ref) {
  return OpenMeteoClient();
}

/// Provides a WeatherRepository wired to appDatabase + openMeteoClient.
@riverpod
WeatherRepository weatherRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final client = ref.watch(openMeteoClientProvider);
  return WeatherRepository(db: db, client: client);
}
