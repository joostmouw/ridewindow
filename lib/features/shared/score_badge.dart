// lib/features/shared/score_badge.dart
// ScoreBadge: shared stateless widget extracted from HomeScreen._buildBadge.
// Used by HomeScreen and RideDetailScreen (Wave 2+).

import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

class ScoreBadge extends StatelessWidget {
  final RideTier tier;
  final String? heroTag;

  const ScoreBadge({super.key, required this.tier, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final t = context.rw.tiers;
    final Color bg;
    final Color fg;
    switch (tier) {
      case Perfect():
        bg = t.perfectBg;
        fg = t.perfectFg;
      case Great():
        bg = t.greatBg;
        fg = t.greatFg;
      case Acceptable():
        bg = t.acceptableBg;
        fg = t.acceptableFg;
      case Poor():
        bg = t.poorBg;
        fg = t.poorFg;
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        switch (tier) {
          Perfect() => S.of(context).tierPerfect,
          Great() => S.of(context).tierGreat,
          Acceptable() => S.of(context).tierAcceptable,
          Poor() => S.of(context).tierPoor,
        },
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

}
