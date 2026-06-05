// lib/features/shared/score_badge.dart
// ScoreBadge: shared stateless widget extracted from HomeScreen._buildBadge.
// Used by HomeScreen and RideDetailScreen (Wave 2+).

import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';

class ScoreBadge extends StatelessWidget {
  final RideTier tier;
  final String? heroTag;

  const ScoreBadge({super.key, required this.tier, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (tier) {
      case Perfect():
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF1B5E20);
      case Great():
        bg = const Color(0xFFF1F8E9);
        fg = const Color(0xFF33691E);
      case Acceptable():
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
      case Poor():
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF757575);
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _tierLabel(tier),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );

    if (heroTag != null) {
      badge = Hero(
        tag: heroTag!,
        child: Material(
          color: Colors.transparent,
          child: badge,
        ),
      );
    }

    return badge;
  }

  String _tierLabel(RideTier tier) => switch (tier) {
        Perfect() => 'Perfect',
        Great() => 'Goed',
        Acceptable() => 'Acceptabel',
        Poor() => 'Slecht',
      };
}
