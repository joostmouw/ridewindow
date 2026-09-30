import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/services/scoring_engine.dart';
import 'package:ridewindow/domain/services/slot_generator.dart';

/// Scoort een bestaand tijdvak, ook als het geen suggestie meer is.
///
/// Beschikbaarheid, favoriete duur, deduplicatie en de ondergrens van 50
/// selecteren suggesties, niet plannen. Dezelfde weer-, trend-, wind- en
/// daglichtcorrecties gelden wel: anders krijgt één rit per scherm een score.
class RideWindowScorer {
  RideWindowScorer({
    required List<HourlyForecast> forecasts,
    required this.tolerances,
    this.latitude,
    this.longitude,
  }) : _forecasts = {
          for (final f in forecasts) f.time.millisecondsSinceEpoch: f,
        };

  final Map<int, HourlyForecast> _forecasts;
  final WeatherTolerances tolerances;
  final double? latitude;
  final double? longitude;

  RideSlot? score(DateTime start, DateTime end) {
    const hour = Duration(hours: 1);
    final duration = end.difference(start);
    if (duration <= Duration.zero ||
        duration.inMicroseconds % hour.inMicroseconds != 0) {
      return null;
    }

    final forecasts = <HourlyForecast>[];
    for (var time = start; time.isBefore(end); time = time.add(hour)) {
      final forecast = _forecasts[time.millisecondsSinceEpoch];
      // Een halve voorspelling mag niet als de hele rit worden gepresenteerd.
      if (forecast == null) return null;
      forecasts.add(forecast);
    }
    final engine = ScoringEngine();
    final hours = forecasts.map((f) => engine.score(f, tolerances)).toList();
    final average = hours.fold(0.0, (sum, h) => sum + h.overall) / hours.length;
    final generator = SlotGenerator();
    var slots = generator.refine(
      [
        RideSlot(
          start: start,
          end: end,
          overallScore: average,
          tier: rideTierFromScore(average),
          hours: hours,
        ),
      ],
      forecasts,
    );
    if (latitude != null && longitude != null) {
      slots = generator.applyDaylight(
        slots,
        latitude: latitude!,
        longitude: longitude!,
        darknessWeight: tolerances.darknessWeight,
      );
    }
    return slots.single;
  }
}
