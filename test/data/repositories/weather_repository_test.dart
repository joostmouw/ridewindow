import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/database/tables/forecast_cache_entries.dart';
import 'package:ridewindow/data/database/tables/hourly_forecast_entries.dart';
import 'package:ridewindow/data/remote/open_meteo_client.dart';
import 'package:ridewindow/data/repositories/weather_repository.dart';
import 'package:test/test.dart';

import 'weather_repository_test.mocks.dart';

@GenerateMocks([], customMocks: [MockSpec<http.Client>(as: #MockHttpClient)])
void main() {
  // Single-hour arrays with all six weather fields present and non-null.
  const String validJson = '''
{
  "latitude": 52.366,
  "longitude": 4.901,
  "timezone": "Europe/Amsterdam",
  "hourly": {
    "time": [1780351200],
    "temperature_2m": [15.5],
    "apparent_temperature": [14.0],
    "precipitation": [0.1],
    "precipitation_probability": [30.0],
    "windspeed_10m": [10.1],
    "winddirection_10m": [218.0]
  }
}
''';

  // windspeed_10m contains null at index 0.
  const String jsonWithNullWindspeed = '''
{
  "latitude": 52.366,
  "longitude": 4.901,
  "timezone": "Europe/Amsterdam",
  "hourly": {
    "time": [1780351200],
    "temperature_2m": [15.5],
    "apparent_temperature": [14.0],
    "precipitation": [0.1],
    "precipitation_probability": [30.0],
    "windspeed_10m": [null],
    "winddirection_10m": [218.0]
  }
}
''';

  late AppDatabase db;
  late MockHttpClient mockHttp;
  late WeatherRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockHttp = MockHttpClient();
    repo = WeatherRepository(db: db, client: OpenMeteoClient(client: mockHttp));
  });

  tearDown(() async {
    await db.close();
  });

  test('Test 1 — cold start: getForecast() calls HTTP and returns forecasts',
      () async {
    when(mockHttp.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(validJson, 200));

    final result = await repo.getForecast();

    expect(result, isNotEmpty);
    verify(mockHttp.get(any, headers: anyNamed('headers'))).called(1);
  });

  test(
      'Test 2 — fresh cache (< 1 hour): getForecast() returns data without HTTP call',
      () async {
    when(mockHttp.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(validJson, 200));

    // Seed the cache via a cold-start call.
    await repo.getForecast();

    // Reset interaction tracking.
    clearInteractions(mockHttp);

    // Second call — cache is fresh.
    final result = await repo.getForecast();

    verifyNever(mockHttp.get(any, headers: anyNamed('headers')));
    expect(result, isNotEmpty);
  });

  test('Test 3 — stale cache (> 1 hour): getForecast() re-fetches', () async {
    // Insert a cache row with fetchedAt = 2 hours ago.
    final staleTime = DateTime.now().subtract(const Duration(hours: 2));
    final cacheId = await db.into(db.forecastCacheEntries).insert(
          ForecastCacheEntriesCompanion.insert(
            lat: 52.3676,
            lon: 4.9041,
            fetchedAt: staleTime,
          ),
        );

    // Insert at least one hourly row to make the cache non-empty.
    await db.into(db.hourlyForecastEntries).insert(
          HourlyForecastEntriesCompanion.insert(
            cacheId: cacheId,
            time: 1780351200,
          ),
        );

    when(mockHttp.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(validJson, 200));

    await repo.getForecast();

    verify(mockHttp.get(any, headers: anyNamed('headers'))).called(1);
  });

  test('Test 4 — null field preserved end-to-end: windspeedKmh == null',
      () async {
    when(mockHttp.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonWithNullWindspeed, 200));

    final result = await repo.getForecast();

    expect(result.first.windspeedKmh, isNull);
  });

  test('Test 5 — getForecast() uses Amsterdam coordinates', () async {
    Uri? capturedUri;
    when(mockHttp.get(any, headers: anyNamed('headers'))).thenAnswer((inv) {
      capturedUri = inv.positionalArguments.first as Uri;
      return Future.value(http.Response(validJson, 200));
    });

    await repo.getForecast();

    expect(capturedUri, isNotNull);
    expect(capturedUri!.queryParameters['latitude'], equals('52.3676'));
    expect(capturedUri!.queryParameters['longitude'], equals('4.9041'));
  });
}
