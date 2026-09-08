import 'package:flutter/material.dart';

import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_shapes.dart';

/// De voortgangsbalk boven in een uitlegkaart.
///
/// **Waarom een `LinearProgressIndicator` en geen eigen streepjes.** Joost's
/// eerste ingeving was een rij streepjes, zoals de dagstreepjes op Home. Dat
/// zou mooi rijmen, maar het is een eigen vondst — Material 3 kent geen
/// stappenteller. De determinate voortgangsbalk is er wél, hij is al door het
/// thema gekleurd, en Flutter 3.44 tekent hem in de huidige M3-vorm met een
/// gat vóór de stopindicator. Joost koos die op 2026-09-08, na beide naast
/// elkaar te hebben gezien in schets 007.
///
/// **Waarom bovenaan en niet bij de knoppen.** Onderaan leest hij als
/// onderdeel van de besturing; bovenaan zegt hij wat hij bedoelt te zeggen —
/// "dit is stap zoveel van zoveel" — voordat je aan de tekst begint.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total});

  /// Nulgebaseerd.
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    // Bij één enkele stap zegt een balk niets, dus dan staat hij er niet.
    if (total < 2) return const SizedBox.shrink();
    return Semantics(
      label: S.of(context).hintStepOf(step + 1, total),
      child: ClipRRect(
        borderRadius: AppShapes.roundedXs,
        child: LinearProgressIndicator(
          // Nul bij de eerste stap en vol bij de laatste: de balk toont hoe ver
          // je bent, niet hoeveel je al gelezen hebt.
          value: step / (total - 1),
          minHeight: 4,
        ),
      ),
    );
  }
}

/// De knoppenrij onder een uitleg in stappen: terug, verder, overslaan.
///
/// **Waarom dit één widget is.** De app had twee uitlegsystemen die er anders
/// uitzagen en zich anders gedroegen: de spotlight per scherm
/// (`screen_hint_overlay.dart`) en de rondleiding bij eerste start
/// (`app_tour_overlay.dart`). De een had een teller maar geen terugknop, de
/// ander bolletjes en ook geen terugknop. Ze delen nu deze rij, dus wat je op
/// het ene scherm leert werkt op het andere ook.
///
/// **Waarom tekstknoppen en geen ronde pijltjes.** In een Material 3 *rich
/// tooltip* — het component waar deze kaarten op gebaseerd zijn — staan acties
/// als tekstknoppen; een rond icoonknopje is de vormtaal van een werkbalk.
/// Bovendien leest "Vorige" in één oogopslag, ook voor wie een pijl voor
/// versiering aanziet.
class StepControls extends StatelessWidget {
  const StepControls({
    super.key,
    required this.step,
    required this.total,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  /// Nulgebaseerd.
  final int step;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        TextButton(
          // Uitgeschakeld in plaats van verborgen: een knop die pas bij stap
          // twee verschijnt laat de rij verspringen, en dan zit "Volgende"
          // niet meer waar je duim hem net had.
          onPressed: step == 0 ? null : onBack,
          child: Text(s.hintBack),
        ),
        TextButton(
          onPressed: onNext,
          child: Text(step == total - 1 ? s.hintDismiss : s.hintNext),
        ),
        const Spacer(),
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
          child: Text(s.hintSkip),
        ),
      ],
    );
  }
}
