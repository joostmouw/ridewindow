// Stub — implementation pending (RED phase)
import 'package:http/http.dart' as http;
import 'package:ridewindow/domain/models/hourly_forecast.dart';

class OpenMeteoClient {
  final http.Client _client;

  OpenMeteoClient({http.Client? client}) : _client = client ?? http.Client();

  Future<List<HourlyForecast>> fetch(double lat, double lon) async {
    throw UnimplementedError('OpenMeteoClient.fetch() not yet implemented');
  }
}
