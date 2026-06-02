import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ridewindow/data/remote/open_meteo_client.dart';
import 'package:test/test.dart';

import 'open_meteo_client_test.mocks.dart';

@GenerateMocks([], customMocks: [MockSpec<http.Client>(as: #MockHttpClient)])
void main() {
  // Single-hour arrays with all six weather fields present and non-null
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

  // windspeed_10m contains null at index 0
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

  // winddirection_10m key is entirely absent
  const String jsonMissingWinddirection = '''
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
    "windspeed_10m": [10.1]
  }
}
''';

  late MockHttpClient mockHttp;
  late OpenMeteoClient client;

  setUp(() {
    mockHttp = MockHttpClient();
    client = OpenMeteoClient(client: mockHttp);
  });

  test(
      'Test 1 — fetch() returns HourlyForecast with all six fields when all present',
      () async {
    when(mockHttp.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(validJson, 200));
    final result = await client.fetch(52.3676, 4.9041);
    expect(result.length, equals(1));
    expect(result.first.windspeedKmh, equals(10.1));
    expect(result.first.temperatureC, equals(15.5));
  });

  test(
      'Test 2 — fetch() preserves null when a field array contains null at index i',
      () async {
    when(mockHttp.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonWithNullWindspeed, 200));
    final result = await client.fetch(52.3676, 4.9041);
    expect(result.first.windspeedKmh, isNull);
  });

  test(
      'Test 3 — fetch() preserves null when a field array is entirely absent from response',
      () async {
    when(mockHttp.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonMissingWinddirection, 200));
    final result = await client.fetch(52.3676, 4.9041);
    expect(result.first.winddirectionDeg, isNull);
  });

  test('Test 4 — fetch() throws when HTTP status != 200', () async {
    when(mockHttp.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('', 503));
    expect(
      () => client.fetch(52.3676, 4.9041),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('503'),
        ),
      ),
    );
  });

  test('Test 5 — URL contains timezone=auto and timeformat=unixtime', () async {
    when(mockHttp.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(validJson, 200));
    await client.fetch(52.3676, 4.9041);
    verify(
      mockHttp.get(
        argThat(
          predicate<Uri>(
            (uri) =>
                uri.queryParameters['timezone'] == 'auto' &&
                uri.queryParameters['timeformat'] == 'unixtime',
          ),
        ),
        headers: anyNamed('headers'),
      ),
    ).called(1);
  });

  test('Test 6 — URL contains all six hourly field names', () async {
    when(mockHttp.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(validJson, 200));
    await client.fetch(52.3676, 4.9041);
    verify(
      mockHttp.get(
        argThat(
          predicate<Uri>((uri) {
            final hourly = uri.queryParameters['hourly'] ?? '';
            return hourly.contains('temperature_2m') &&
                hourly.contains('apparent_temperature') &&
                hourly.contains('precipitation') &&
                hourly.contains('precipitation_probability') &&
                hourly.contains('windspeed_10m') &&
                hourly.contains('winddirection_10m');
          }),
        ),
        headers: anyNamed('headers'),
      ),
    ).called(1);
  });
}
