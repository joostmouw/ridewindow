import 'package:flutter/material.dart';

/// Centralised shape and spacing tokens.
abstract final class AppShapes {
  // ── Border radii ──
  //
  // De schaal beschrijft wat de app werkelijk doet, en dat is geen toeval:
  // elke maat hoort bij een soort object. Tot de sweep van #73 stonden de twee
  // meest gebruikte maten -- die van een kaart en die van een paneel -- hier
  // niet eens in, terwijl ze overal in de schermen hardgecodeerd stonden. Een
  // tokenbestand dat de werkelijkheid niet beschrijft, maakt het erger dan geen
  // tokenbestand.
  //
  // Bewust géén Material 3-schaal (die kent 12, 16 en 28): v4.0 koos 24 voor
  // ritkaarten en dat is een gemaakte keuze, geen afwijking. Zie de noot over
  // "Alle kaarten dezelfde volle radius" in home_screen.dart.

  /// Een haarlijn: de onderstreping onder een actief filter, een
  /// indicatorbalkje van twee pixels hoog. Stond als 1, 2 én 3 in de code --
  /// drie toevallige getallen voor één gebaar.
  static const radiusHair = 2.0;

  /// Een cel in een raster: de beschikbaarheidskalender, de agendaweek.
  static const radiusCell = 3.0;

  /// Klein accentje.
  static const radiusXs = 4.0;

  /// Een knopje of chip.
  static const radiusSm = 8.0;

  /// Een klein vlak binnen een kaart.
  static const radiusMd = 12.0;

  /// Een balk of rij: de stale-banner, een PLANNED-regel.
  static const radiusLg = 16.0;

  /// Een pil. Alleen [ScoreBadge] gebruikt deze.
  static const radiusXl = 20.0;

  /// Een paneel: een sectiekaart, een blok binnen een scherm.
  static const radiusPanel = 18.0;

  /// Een kaart: het hoofdobject van een lijst. Ritkaarten, dagkaarten.
  static const radiusCard = 24.0;

  static const radiusFull = 999.0;

  // `BorderRadius.all(Radius.circular(...))` en niet `BorderRadius.circular()`:
  // de eerste is een const-constructor, de tweede niet. Daardoor zijn deze
  // tokens bruikbaar in een `const BoxDecoration`, en dat is precies waar ze
  // anders alsnog door een hardgecodeerd getal vervangen worden.
  static const roundedHair = BorderRadius.all(Radius.circular(radiusHair));
  static const roundedCell = BorderRadius.all(Radius.circular(radiusCell));
  static const roundedXs = BorderRadius.all(Radius.circular(radiusXs));
  static const roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const roundedPanel = BorderRadius.all(Radius.circular(radiusPanel));
  static const roundedCard = BorderRadius.all(Radius.circular(radiusCard));
  static const roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // ── Common paddings ──
  static const paddingXs = 4.0;
  static const paddingSm = 8.0;
  static const paddingMd = 12.0;
  static const paddingLg = 16.0;
  static const paddingXl = 24.0;
}
