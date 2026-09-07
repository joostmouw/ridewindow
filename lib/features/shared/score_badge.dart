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
    switch (widget.tier) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      // Geen smiley meer. Die verdween in v4.0 al van de ritkaarten toen de
      // score daar een groot getal werd (zie `ScoreDisplay`), maar hij bleef
      // hier staan -- en daarmee stond dezelfde beoordeling op twee plekken in
      // twee talen. De pil draagt het woord; een gezichtje zegt daar niets
      // bovenop wat er niet al staat.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
