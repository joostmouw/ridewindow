import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ridewindow/domain/models/hourly_forecast.dart';

class OpenMeteoClient {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const List<String> _hourlyFields = [
    'temperature_2m',
    'apparent_temperature',
    'precipitation',
    'precipitation_probability',
    'windspeed_10m',
    'winddirection_10m',
  ];

  final http.Client _client;

  OpenMeteoClient({http.Client? client}) : _client = client ?? http.Client();

  Future<List<HourlyForecast>> fetch(double lat, double lon) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'hourly': _hourlyFields.join(','),
        'timezone': 'auto',
        'timeformat': 'unixtime',
      },
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Open-Meteo error: ${response.statusCode}');
    }
    return _parseResponse(response.body);
  }

  List<HourlyForecast> _parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<int>();

    double? get(String key, int i) {
      final list = hourly[key];
      if (list == null) return null;
      final val = (list as List)[i];
      if (val == null) return null;
      return (val as num).toDouble();
    }

    return List.generate(
      times.length,
      (i) => HourlyForecast(
        time: DateTime.fromMillisecondsSinceEpoch(times[i] * 1000),
        temperatureC: get('temperature_2m', i),
        apparentTemperatureC: get('apparent_temperature', i),
        precipitationMm: get('precipitation', i),
        precipitationProbability: get('precipitation_probability', i),
        windspeedKmh: get('windspeed_10m', i),
        winddirectionDeg: get('winddirection_10m', i),
      ),
    );
  }
}
