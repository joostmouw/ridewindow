// lib/features/detail/insights_sheet.dart
// InsightsSheet: stub bottom sheet for Wave 3 implementation.
// Wave 3 vult de inhoud in met score breakdown per factor.

import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';

class InsightsSheet extends StatelessWidget {
  final RideSlot slot;

  const InsightsSheet({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 200); // Wave 3 vult dit in
  }
}
