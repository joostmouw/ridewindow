import 'package:flutter/material.dart';

import 'package:ridewindow/theme/app_theme.dart';

/// Zet een scherm op het lichte palet, ongeacht wat de gebruiker heeft
/// ingesteld.
///
/// **Waarom dit bestaat.** Welkom en Onboarding zetten hun achtergrond bewust
/// hard op `AppColors.brandLight` -- een groot groen vlak als merkmoment, keuze
/// van Joost op 2026-09-07. Hun tekst kwam ondertussen uit het áctieve schema,
/// en in donkere modus is dat lichte tekst op een licht groen vlak: 1,21:1 voor
/// de titel en 1,09:1 voor de ondertitel en de "ik heb al een account"-link,
/// tegen 9,63:1 en 5,54:1 in lichte modus. Onleesbaar, en precies wat Joost op
/// 2026-09-08 fotografeerde.
///
/// Een scherm dat zijn achtergrond vastzet, moet zijn voorgrond ook vastzetten.
/// Bewust hier en niet in de schermen zelf: een `Theme` binnen `build` geldt
/// niet voor de `context` waarmee die `build` zelf leest, dus een wrapper
/// binnenin zou de helft van de kleuren ongemoeid laten -- juist de valkuil die
/// dit gebrek heeft veroorzaakt. Vanaf de route ligt alles eronder.
class BrandCanvas extends StatelessWidget {
  const BrandCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Theme(data: brandCanvasTheme, child: child);
}
