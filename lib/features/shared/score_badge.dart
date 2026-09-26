// lib/features/shared/score_badge.dart
// ScoreBadge: M3 Expressive pill-shaped tonal badge with spring entrance.

import 'package:flutter/material.dart';
import 'package:ridewindow/theme/app_shapes.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_motion.dart';
import 'package:ridewindow/theme/app_theme.dart';

class ScoreBadge extends StatefulWidget {
  final RideTier tier;

  /// Toon het getal in plaats van het woord. Voor de plankaartjes onder
  /// GEPLAND op Home: het woord ("Toprit") at daar de breedte van een heel
  /// vak op een rij die ook nog een merkteken, rol en prullenbak moet
  /// bevatten (Joost, 2026-09-25). De kleur blijft het oordeel dragen, het
  /// getal levert de precisie. Het detail houdt het woord.
  final int? score;

  /// Kleur die op het getal de tierkleur overruled. De plankaartjes onder
  /// GEPLAND lopen al in gepland-blauw; daar las de groene tierpil als een
  /// tweede kleur op één kaart (Joost, build 59). Met de kleur van het
  /// kaartje zelf blijft er één kleur over, en het oordeel lees je gewoon
  /// uit het Semantics-label en op het detail.
  final Color? color;

  const ScoreBadge({
    super.key,
    required this.tier,
    this.score,
    this.color,
  });

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

    final tierWord = switch (widget.tier) {
      Perfect() => S.of(context).tierPerfect,
      Great() => S.of(context).tierGreat,
      Acceptable() => S.of(context).tierAcceptable,
      Poor() => S.of(context).tierPoor,
    };
    final value = widget.score;

    // De override geldt alléén de getalvariant: een blauw woord "Toprit"
    // zou het oordeel verbergen in plaats van laten zien. De vulling is een
    // stap sterker dan het kaartje eromheen (alpha 18), zodat de pil ook op
    // een blauw kaartje nog als pil leest.
    final override = value != null ? widget.color : null;
    final pillBg = override?.withAlpha(40) ?? bg;
    final pillFg = override ?? fg;

    Widget badge = Container(
      // Strakker opgepoten als er alleen een getal in staat: het woord
      // vroeg een eigen vulling, een getal leest ook krap.
      padding: value == null
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: AppShapes.roundedXl,
      ),
      // Geen smiley meer. Die verdween in v4.0 al van de ritkaarten toen de
      // score daar een groot getal werd (zie `ScoreDisplay`), maar hij bleef
      // hier staan -- en daarmee stond dezelfde beoordeling op twee plekken in
      // twee talen. De pil draagt het woord; een gezichtje zegt daar niets
      // bovenop wat er niet al staat.
      child: value == null
          ? Text(
              tierWord,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            )
          : Semantics(
              // Het getal alléén zegt een screenreader niets over het
              // oordeel; woord en getal samen wel.
              label: '$tierWord, $value',
              child: Text(
                '$value',
                style: TextStyle(
                  color: pillFg,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
    );

    return ScaleTransition(
      scale: _scale,
      child: badge,
    );
  }
}
