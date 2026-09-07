// lib/theme/app_typography.dart
// Het lettertype van RideWindow. Epic #64 ("Eigen gezicht").

import 'package:flutter/material.dart';

/// Outfit als huisletter, gekozen door Joost (2026-09-07, epic #64).
///
/// **Wat het logo voorschrijft.** Het app-icoon is een RW-monogram dat in één
/// ononderbroken lijn is getekend: overal dezelfde lijndikte, ronde uiteinden,
/// bijna cirkelvormige bochten, nergens een scherpe hoek. Outfit levert de
/// geometrie en de cirkelvormigheid; wat het níét levert zijn ronde terminals,
/// want die zijn vlak afgesneden.
///
/// **Waarom dat hier toch werkt.** De rondheid van het merk zit in deze app al
/// in de vórmen: kaarten op radius 24, knoppen als `StadiumBorder`, chips vol
/// rond. Het lettertype hoeft die boodschap niet te herhalen. Outfit zet er een
/// strak, geometrisch contrast tegenover in plaats van nóg een laag zachtheid,
/// en dat is precies wat een scherm vol afgeronde blokken nodig heeft om niet
/// als één zachte massa te lezen. Kandidaten die wél ronde terminals hadden
/// (Quicksand) verloren het op de kleine maten waar deze app de meeste tekst
/// heeft staan.
///
/// **Waar je op moet letten bij wijzigingen.** Outfit heeft een grote x-hoogte
/// en open vormen, maar is van huis uit licht: gebruik hem niet onder gewicht
/// 400 voor lopende tekst, en controleer 11 tot 12 punt op een echt toestel
/// voordat je een stijl lichter maakt. De contrastratio's uit backlog #9 zijn
/// op Roboto gemeten; een lichter ogend lettertype kan die winst stilletjes
/// weggeven.
///
/// **Waarom een variabele font.** `assets/fonts/Outfit.ttf` is één bestand van
/// 111 kB dat alle gewichten draagt. De prijs is dat gewichtselectie via
/// [FontVariation] moet: een variabele as reageert niet op `fontWeight` alleen.
/// Beide worden hieronder gezet -- `fontWeight` zodat de rest van Flutter (en
/// een eventuele fallback naar het systeemlettertype) het juiste gewicht
/// kiest, `fontVariations` zodat Outfit zelf de juiste instantie tekent.
abstract final class AppTypography {
  static const family = 'Outfit';

  /// Eén stijl opbouwen. Houdt [fontWeight] en de `wght`-as in de pas; ze uit
  /// elkaar laten lopen levert tekst op die op het ene platform zwaarder oogt
  /// dan op het andere.
  static TextStyle _style(
    double size,
    int weight, {
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        height: height,
        letterSpacing: letterSpacing,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
        fontVariations: [FontVariation('wght', weight.toDouble())],
      );

  /// De volledige Material 3-schaal in Rubik.
  ///
  /// De maten volgen de M3-standaard; alleen de gewichten zijn aangescherpt.
  /// Titels en labels staan op 500 in plaats van 400, want in een scherm dat
  /// vrijwel uitsluitend uit korte fragmenten bestaat (een dagnaam, een
  /// tijdvak, een score) doet gewicht het werk dat elders witruimte doet.
  static TextTheme get textTheme => TextTheme(
        displayLarge: _style(57, 500, height: 1.12, letterSpacing: -0.25),
        displayMedium: _style(45, 500, height: 1.16),
        displaySmall: _style(36, 500, height: 1.22),
        headlineLarge: _style(32, 500, height: 1.25),
        headlineMedium: _style(28, 500, height: 1.29),
        headlineSmall: _style(24, 500, height: 1.33),
        titleLarge: _style(22, 500, height: 1.27),
        titleMedium: _style(16, 500, height: 1.5, letterSpacing: 0.15),
        titleSmall: _style(14, 500, height: 1.43, letterSpacing: 0.1),
        bodyLarge: _style(16, 400, height: 1.5, letterSpacing: 0.5),
        bodyMedium: _style(14, 400, height: 1.43, letterSpacing: 0.25),
        bodySmall: _style(12, 400, height: 1.33, letterSpacing: 0.4),
        labelLarge: _style(14, 500, height: 1.43, letterSpacing: 0.1),
        labelMedium: _style(12, 500, height: 1.33, letterSpacing: 0.5),
        labelSmall: _style(11, 500, height: 1.45, letterSpacing: 0.5),
      );
}
