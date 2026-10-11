// lib/features/home/filled_score_badge.dart
//
// Het ronde scorebolletje van de compacte tabletrij (quick-plan 261011-l5k,
// schets 017 A): op de plek waar Gmail een avatar zet, gevuld met de
// tierkleur en met de score erin.

import 'package:flutter/material.dart';

import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// De tekstkleur op een gevulde tierkleur: wit of zwart, wat het hoogste
/// WCAG-contrast haalt.
///
/// Een vaste tekstkleur kan niet: de vier tierkleuren lopen van donkergroen
/// tot lichtgrijs, en wit op het teal van "Goed" (#26A69A) haalt maar 2,9:1.
Color onScoreFill(Color fill) {
  final l = fill.computeLuminance();
  // Contrast met wit (luminantie 1) en met zwart (luminantie 0).
  final withWhite = 1.05 / (l + 0.05);
  final withBlack = (l + 0.05) / 0.05;
  return withWhite >= withBlack ? Colors.white : const Color(0xFF000000);
}

/// Een cirkel van [size] in de tierkleur met de afgeronde score erin.
///
/// Geen animatie: de rij eromheen komt al binnen met een `SpringEntrance`.
class FilledScoreBadge extends StatelessWidget {
  const FilledScoreBadge({
    super.key,
    required this.score,
    required this.tier,
    this.size = 44,
  });

  final double score;
  final RideTier tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    final rw = context.rw;
    final s = S.of(context);
    final (Color fill, String label) = switch (tier) {
      Perfect() => (rw.scorePerfect, s.tierPerfect),
      Great() => (rw.scoreGreat, s.tierGreat),
      Acceptable() => (rw.scoreAcceptable, s.tierAcceptable),
      Poor() => (rw.scorePoor, s.tierPoor),
    };
    final rounded = score.round();

    return Semantics(
      label: s.scoreSemanticLabel(rounded, label),
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Text(
          '$rounded',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: onScoreFill(fill),
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
