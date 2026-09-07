// lib/features/shared/score_display.dart
// De score als held: het getal groot, het oordeel eronder.

import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_motion.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Toont een ritscore als groot getal met het uitgeschreven oordeel eronder.
///
/// Vervangt op de ritkaarten van Home de pil met smiley uit [ScoreBadge]
/// (keuze van Joost, 2026-09-07). De reden dat dit beter werkt is niet
/// smaak: de kernwaarde van deze app is de score, en die stond als klein
/// pilletje rechtsboven visueel gelijk aan een filterchip. Een getal van 40
/// punten trekt het oog naar het enige dat de gebruiker wil weten, en het
/// uitgeschreven woord eronder houdt de betekenis leesbaar voor wie 96 niet
/// vanzelf als "perfect" leest.
///
/// De smiley is bewust vervallen en niet verkleind meeverhuisd: naast een
/// getal én een woord voegt hij niets toe wat er niet al staat, en drie
/// signalen voor één feit is er één te veel.
///
/// [ScoreBadge] blijft bestaan voor de compacte plekken waar een hele regel
/// hoogte niet past -- de geplande-rit-regels op Home, de agenda-cellen en de
/// bottom sheets.
/// Twee maten voor hetzelfde getal, en dat is het punt.
///
/// Tot fase 23 stond elke score op `displaySmall`, hoe goed of slecht de rit
/// ook was. Dat is de helft van de vlakheid die deze epic moet wegnemen: als
/// alles even groot is, wijst niets iets aan. Sinds de beste kaart geen schaduw
/// en geen accentstaaf meer draagt (Joost, 2026-09-07) is dit bovendien niet
/// langer een extra signaal maar het voornaamste — de pil zegt *dat* hij de
/// beste is, de maat laat het zíen.
enum ScoreEmphasis {
  /// De beste kaart: `displayMedium` (45), oordeel op `titleMedium`.
  hero,

  /// Elke andere kaart: `headlineMedium` (28), oordeel op `titleSmall`.
  normal,
}

class ScoreDisplay extends StatefulWidget {
  const ScoreDisplay({
    super.key,
    required this.score,
    required this.tier,
    this.emphasis = ScoreEmphasis.normal,
  });

  final double score;
  final RideTier tier;

  /// Hoe groot het getal mag zijn. Zie [ScoreEmphasis].
  final ScoreEmphasis emphasis;

  @override
  State<ScoreDisplay> createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends State<ScoreDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // Zelfde binnenkomst als ScoreBadge had, zodat het vervangen van de pil
    // geen verandering in beweging oplevert -- alleen in vorm.
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
    final theme = Theme.of(context);
    final s = S.of(context);

    final (Color fg, String label) = switch (widget.tier) {
      Perfect() => (t.perfectFg, s.tierPerfect),
      Great() => (t.greatFg, s.tierGreat),
      Acceptable() => (t.acceptableFg, s.tierAcceptable),
      Poor() => (t.poorFg, s.tierPoor),
    };

    // Rollen uit de schaal, geen losse getallen: `_style()` in
    // app_typography.dart is de enige plek waar een puntgrootte hoort te staan.
    final isHero = widget.emphasis == ScoreEmphasis.hero;
    final numberStyle =
        isHero ? theme.textTheme.displayMedium : theme.textTheme.headlineMedium;
    final labelStyle =
        isHero ? theme.textTheme.titleMedium : theme.textTheme.titleSmall;

    return ScaleTransition(
      scale: _scale,
      child: Semantics(
        // Zonder dit leest een screenreader "96" en "Perfect" als twee losse
        // brokjes tekst, zonder dat duidelijk is dat het één oordeel is.
        label: s.scoreSemanticLabel(widget.score.round(), label),
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.score.round()}',
              style: numberStyle?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                // Outfit is een variabele letter; zonder deze `fontVariations`
                // pakt de web-build de statische instantie en blijft het
                // gewicht op 500 staan.
                fontVariations: const [FontVariation('wght', 600)],
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: labelStyle?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
