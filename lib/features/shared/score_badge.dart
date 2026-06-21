// lib/features/shared/score_badge.dart
// ScoreBadge: M3 Expressive pill-shaped tonal badge with spring entrance.

import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_motion.dart';
import 'package:ridewindow/theme/app_theme.dart';

class ScoreBadge extends StatefulWidget {
  final RideTier tier;

  const ScoreBadge({super.key, required this.tier});

  @override
  State<ScoreBadge> createState() => _ScoreBadgeState();
}

class _ScoreBadgeState extends State<ScoreBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.spatialDuration,
    );
    _scale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.spatialCurve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rw.tiers;
    final Color bg;
    final Color fg;
    final IconData icon;
    switch (widget.tier) {
      case Perfect():
        bg = t.perfectBg;
        fg = t.perfectFg;
        icon = Icons.sentiment_very_satisfied;
      case Great():
        bg = t.greatBg;
        fg = t.greatFg;
        icon = Icons.sentiment_satisfied;
      case Acceptable():
        bg = t.acceptableBg;
        fg = t.acceptableFg;
        icon = Icons.sentiment_neutral;
      case Poor():
        bg = t.poorBg;
        fg = t.poorFg;
        icon = Icons.sentiment_dissatisfied;
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            switch (widget.tier) {
              Perfect() => S.of(context).tierPerfect,
              Great() => S.of(context).tierGreat,
              Acceptable() => S.of(context).tierAcceptable,
              Poor() => S.of(context).tierPoor,
            },
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );

    return ScaleTransition(
      scale: _scale,
      child: badge,
    );
  }
}
