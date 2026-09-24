// lib/features/detail/detail_args.dart
// DetailArgs: plain Dart DTO used as go_router extra for /detail navigation.
// Carries the RideSlot and the slot-filtered List<HourlyForecast>.

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';

class DetailArgs {
  final RideSlot slot;

  /// List of HourlyForecast filtered to the slot's time window [start, end).
  final List<HourlyForecast> forecasts;

  /// Welke gedeelde rit je aantikte, of `null` als je niet vanaf een rit kwam
  /// (een tijdvak op Home, de agenda). Nodig sinds 35-01 twee gedeelde ritten
  /// op hetzelfde tijdvak naast elkaar laat staan: op tijdvak zoeken zou dan
  /// altijd de eerste openen, ook als je op de tweede tikte.
  final String? groupRideId;

  const DetailArgs({
    required this.slot,
    required this.forecasts,
    this.groupRideId,
  });
}
