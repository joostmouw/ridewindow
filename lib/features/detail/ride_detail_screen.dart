// lib/features/detail/ride_detail_screen.dart
// RideDetailScreen: stub scaffold for Wave 1 router compilation.
// Wave 2 will implement the full screen (score banner, hourly table, InsightsSheet).

import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';

class RideDetailScreen extends StatelessWidget {
  final RideSlot slot;
  final List<HourlyForecast> forecasts;

  const RideDetailScreen({
    super.key,
    required this.slot,
    required this.forecasts,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
