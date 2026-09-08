// lib/theme/app_icons.dart
// De iconen van RideWindow: Phosphor Regular, met Fill voor de geselecteerde tab.
//
// **Waarom de constanten hier staan en niet uit een pakket komen.** `phosphor_flutter`
// bestaat, maar versie 2.1.0 (mei 2024) doet `class PhosphorIconData extends IconData`
// en Flutter heeft `IconData` sindsdien `final` gemaakt. Het pakket lost wél op en de
// analyzer klaagt niet -- het breekt pas bij compileren:
//
//     Error: The class 'IconData' can't be extended outside of its library
//            because it's a final class.
//
// Vastgesteld 2026-09-08. In plaats van op een reparatie te wachten dragen we het font
// zelf, precies zoals `Outfit.ttf` er al staat: twee `.ttf`-bestanden in `assets/fonts/`
// en de codepunten hieronder. Nul afhankelijkheden, en niets dat met Flutter mee moet
// bewegen. De codepunten zijn overgenomen uit de gegenereerde bestanden van dat pakket;
// de tekeningen zelf zijn MIT (zie `assets/fonts/PHOSPHOR-LICENSE.txt`).
//
// **Bij het toevoegen van een icoon:** zoek de naam op phosphoricons.com, haal het
// codepunt uit dezelfde bron en zet hem hieronder. Gebruik hem altijd als constante --
// een `IconData` die alleen in een ternaire voorkomt wordt door `--tree-shake-icons`
// weggesneden en verdwijnt uit de release-build zonder dat iets faalt (zie `9bf1e38`).

import 'package:flutter/widgets.dart';

/// Phosphor Regular -- de hand van de app.
abstract final class AppIcons {
  static const IconData arrowCounterClockwise =
      IconData(0xe038, fontFamily: 'Phosphor');
  static const IconData arrowLeft =
      IconData(0xe058, fontFamily: 'Phosphor');
  static const IconData arrowRight =
      IconData(0xe06c, fontFamily: 'Phosphor');
  static const IconData arrowSquareOut =
      IconData(0xe5de, fontFamily: 'Phosphor');
  static const IconData arrowsClockwise =
      IconData(0xe094, fontFamily: 'Phosphor');
  static const IconData barbell =
      IconData(0xe0b6, fontFamily: 'Phosphor');
  static const IconData bell =
      IconData(0xe0ce, fontFamily: 'Phosphor');
  static const IconData bicycle =
      IconData(0xe0d6, fontFamily: 'Phosphor');
  static const IconData buildings =
      IconData(0xe102, fontFamily: 'Phosphor');
  static const IconData calendarBlank =
      IconData(0xe10a, fontFamily: 'Phosphor');
  static const IconData calendarCheck =
      IconData(0xe712, fontFamily: 'Phosphor');
  static const IconData calendarDots =
      IconData(0xe7b4, fontFamily: 'Phosphor');
  static const IconData calendarX =
      IconData(0xe10c, fontFamily: 'Phosphor');
  static const IconData caretDown =
      IconData(0xe136, fontFamily: 'Phosphor');
  static const IconData caretLeft =
      IconData(0xe138, fontFamily: 'Phosphor');
  static const IconData caretRight =
      IconData(0xe13a, fontFamily: 'Phosphor');
  static const IconData caretUp =
      IconData(0xe13c, fontFamily: 'Phosphor');
  static const IconData chatCircleDots =
      IconData(0xe16c, fontFamily: 'Phosphor');
  static const IconData check =
      IconData(0xe182, fontFamily: 'Phosphor');
  static const IconData checkCircle =
      IconData(0xe184, fontFamily: 'Phosphor');
  static const IconData cloud =
      IconData(0xe1aa, fontFamily: 'Phosphor');
  static const IconData cloudRain =
      IconData(0xe1b4, fontFamily: 'Phosphor');
  static const IconData cloudSlash =
      IconData(0xe1b6, fontFamily: 'Phosphor');
  static const IconData copy =
      IconData(0xe1ca, fontFamily: 'Phosphor');
  static const IconData crosshair =
      IconData(0xe1d6, fontFamily: 'Phosphor');
  static const IconData drop =
      IconData(0xe210, fontFamily: 'Phosphor');
  static const IconData export =
      IconData(0xeaf0, fontFamily: 'Phosphor');
  static const IconData flag =
      IconData(0xe244, fontFamily: 'Phosphor');
  static const IconData handPointing =
      IconData(0xe29a, fontFamily: 'Phosphor');
  static const IconData handSwipeRight =
      IconData(0xec92, fontFamily: 'Phosphor');
  static const IconData hourglass =
      IconData(0xe2b2, fontFamily: 'Phosphor');
  static const IconData house =
      IconData(0xe2c2, fontFamily: 'Phosphor');
  static const IconData info =
      IconData(0xe2ce, fontFamily: 'Phosphor');
  static const IconData linkBreak =
      IconData(0xe2e4, fontFamily: 'Phosphor');
  static const IconData lock =
      IconData(0xe2fa, fontFamily: 'Phosphor');
  static const IconData mapPin =
      IconData(0xe316, fontFamily: 'Phosphor');
  static const IconData minusCircle =
      IconData(0xe32c, fontFamily: 'Phosphor');
  static const IconData moonStars =
      IconData(0xe58e, fontFamily: 'Phosphor');
  static const IconData mountains =
      IconData(0xe7ae, fontFamily: 'Phosphor');
  static const IconData navigationArrow =
      IconData(0xeade, fontFamily: 'Phosphor');
  static const IconData paperPlaneTilt =
      IconData(0xe398, fontFamily: 'Phosphor');
  static const IconData personSimpleBike =
      IconData(0xe734, fontFamily: 'Phosphor');
  static const IconData plus =
      IconData(0xe3d4, fontFamily: 'Phosphor');
  static const IconData plusCircle =
      IconData(0xe3d6, fontFamily: 'Phosphor');
  static const IconData prohibit =
      IconData(0xe3de, fontFamily: 'Phosphor');
  static const IconData shareNetwork =
      IconData(0xe408, fontFamily: 'Phosphor');
  static const IconData signIn =
      IconData(0xe428, fontFamily: 'Phosphor');
  static const IconData slidersHorizontal =
      IconData(0xe434, fontFamily: 'Phosphor');
  static const IconData star =
      IconData(0xe46a, fontFamily: 'Phosphor');
  static const IconData sun =
      IconData(0xe472, fontFamily: 'Phosphor');
  static const IconData sunHorizon =
      IconData(0xe5b6, fontFamily: 'Phosphor');
  static const IconData thermometerSimple =
      IconData(0xe5cc, fontFamily: 'Phosphor');
  static const IconData trash =
      IconData(0xe4a6, fontFamily: 'Phosphor');
  static const IconData trashSimple =
      IconData(0xe4a8, fontFamily: 'Phosphor');
  static const IconData trendDown =
      IconData(0xe4ac, fontFamily: 'Phosphor');
  static const IconData trendUp =
      IconData(0xe4ae, fontFamily: 'Phosphor');
  static const IconData user =
      IconData(0xe4c2, fontFamily: 'Phosphor');
  static const IconData userCircle =
      IconData(0xe4c4, fontFamily: 'Phosphor');
  static const IconData userMinus =
      IconData(0xe4ce, fontFamily: 'Phosphor');
  static const IconData userPlus =
      IconData(0xe4d0, fontFamily: 'Phosphor');
  static const IconData usersThree =
      IconData(0xe68e, fontFamily: 'Phosphor');
  static const IconData warning =
      IconData(0xe4e0, fontFamily: 'Phosphor');
  static const IconData warningCircle =
      IconData(0xe4e2, fontFamily: 'Phosphor');
  static const IconData wind =
      IconData(0xe5d2, fontFamily: 'Phosphor');
  static const IconData x =
      IconData(0xe4f6, fontFamily: 'Phosphor');
}

/// Phosphor Fill. Alleen voor de geselecteerde tab in de navigatiebalk:
/// Material deed dat met omlijnd-versus-gevuld, Phosphor met een gewicht.
abstract final class AppIconsFill {
  static const IconData bicycle =
      IconData(0xe0d6, fontFamily: 'PhosphorFill');
  static const IconData calendarDots =
      IconData(0xe7b4, fontFamily: 'PhosphorFill');
  static const IconData house =
      IconData(0xe2c2, fontFamily: 'PhosphorFill');
  static const IconData user =
      IconData(0xe4c2, fontFamily: 'PhosphorFill');
}
