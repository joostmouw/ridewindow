// lib/features/shared/clothing_tip.dart
// Clothing recommendation for cyclists based on feels-like temperature.
//
// Sinds fase 24 staat hier alleen nog de regel, geen weergave. Het advies wordt
// getoond door `FeelsLikeBar` (feels_like_bar.dart); de emoji-pil die hier
// stond is vervallen omdat elk platform die anders tekende.
//
// Cycling logic:
// - Legs are the engine → stay warm from pedaling → shorts until ~14°C
// - Upper body catches wind → needs protection sooner
// - So mixing = lang boven, kort onder — never the reverse
//
// Thresholds (feels-like, accounting for cycling wind chill):
//   ≥20°C  kort/kort   — t-shirt + korte broek
//   14-20°C lang/kort  — lange mouw + korte broek
//   5-14°C  lang/lang  — lange mouw + lange broek
//   <5°C    lang/lang+  — volledige bescherming + extra lagen

import 'package:ridewindow/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// De regel zelf. Pure Dart: geen BuildContext, geen widgets — alleen
// `clothingItems` heeft de vertalingen nodig.
// ---------------------------------------------------------------------------

/// De vier kledingadviezen, elk met de gevoelstemperatuur waarbij hij geldt.
///
/// **Waarom de grenzen op de enum staan en niet in [recommendClothing].** Sinds
/// fase 24 tekent `FeelsLikeBar` deze banden als schaal onder het advies. Zou
/// de balk zijn eigen getallen aanhouden, dan kan de markering in de ene band
/// staan terwijl de tekst een andere noemt — en dan liegt het scherm over zijn
/// eigen redenering. Eén bron, twee lezers.
enum ClothingCombo {
  shortShort(minFeelsC: 20),
  longShort(minFeelsC: 14, maxFeelsC: 20),
  longLong(minFeelsC: 5, maxFeelsC: 14),
  longLongExtra(maxFeelsC: 5);

  const ClothingCombo({this.minFeelsC, this.maxFeelsC});

  /// Ondergrens, inclusief. `null` voor de koudste band: die heeft er geen.
  final double? minFeelsC;

  /// Bovengrens, exclusief. `null` voor de warmste band.
  final double? maxFeelsC;

  /// De band waar deze gevoelstemperatuur in valt.
  ///
  /// De volgorde is van warm naar koud en de vergelijking is `>=`, precies
  /// zoals de oorspronkelijke if-keten. 20,0 is dus kort/kort en 19,9 is
  /// lang/kort.
  static ClothingCombo forFeelsLike(double feelsLikeC) {
    for (final combo in values) {
      if (combo.minFeelsC == null || feelsLikeC >= combo.minFeelsC!) {
        return combo;
      }
    }
    return longLongExtra;
  }
}

/// Het getekende bereik van de gevoelsbalk.
///
/// Niet het meetbereik maar het bereik dat je op de fiets tegenkomt — zelfde
/// afweging als `zoomMin`/`zoomMax` op `WeatherMetric`. Buiten dit bereik klapt
/// de markering tegen de rand; het getal in de tekst blijft de echte waarde.
const double feelsLikeZoomMinC = -5;
const double feelsLikeZoomMaxC = 25;

class ClothingAdvice {
  final ClothingCombo combo;
  final double feelsLike;
  final bool raining;
  final bool windy;

  const ClothingAdvice({
    required this.combo,
    required this.feelsLike,
    required this.raining,
    required this.windy,
  });
}

/// De snelheid die je zelf maakt, in km/u. Dat is de enige wind die nog van de
/// gevoelstemperatuur af moet, want de omgevingswind zit daar al in.
const double _ownSpeedKmh = 15;

/// Graden koeling per km/u schijnbare wind. Een grove maat, maar het is de maat
/// die dit product altijd al gebruikte; hem hier veranderen zou twee dingen
/// tegelijk verschuiven.
const double _chillPerKmh = 0.05;

ClothingAdvice recommendClothing({
  required double? avgTempC,
  double? avgApparentC,
  double? avgWindKmh,
  double? totalPrecipMm,
}) {
  // **Waarom de gevoelstemperatuur het startpunt is.** [avgTempC] is de kale
  // meting: die weet niets van zon en vocht. Op een zonnige dag van 12 graden
  // adviseerde deze functie daarom voor 12 terwijl het als 16 voelt. Open-Meteo
  // rekent zon, vocht én de omgevingswind al mee in `apparentTemperatureC`, en
  // dat getal staat elders op ditzelfde scherm ook al.
  //
  // Daarvan hoeft dus alleen de wind af die je zélf maakt. Zou hier
  // `(wind + 15)` blijven staan, dan telt de omgevingswind dubbel: één keer in
  // de gevoelstemperatuur en nog een keer hier.
  //
  // Zonder gevoelstemperatuur (die kan ontbreken in de data) valt hij terug op
  // de oude som vanaf de kale meting. Dat is de vorige versie van deze regel,
  // ongewijzigd, zodat de app nooit zonder advies zit.
  final double feelsLike = avgApparentC != null
      ? avgApparentC - _ownSpeedKmh * _chillPerKmh
      : (avgTempC ?? 15) - ((avgWindKmh ?? 0) + _ownSpeedKmh) * _chillPerKmh;
  final raining = (totalPrecipMm ?? 0) > 0.5;
  final windy = (avgWindKmh ?? 0) > 25;

  return ClothingAdvice(
    combo: ClothingCombo.forFeelsLike(feelsLike),
    feelsLike: feelsLike,
    raining: raining,
    windy: windy,
  );
}

/// Returns the detailed clothing items list for the detail screen.
List<String> clothingItems(ClothingAdvice advice, S s) {
  final items = <String>[];

  switch (advice.combo) {
    case ClothingCombo.shortShort:
      items.add(s.clothingShortSleeveJersey);
      if (advice.feelsLike >= 25) {
        items.add(s.clothingSunscreen);
      }
      if (advice.feelsLike >= 30) {
        items.add(s.clothingExtraWater);
      }
    case ClothingCombo.longShort:
      items.add(s.clothingLongSleeveJersey);
      if (advice.feelsLike < 17) {
        items.add(s.clothingArmWarmersJustInCase);
      }
    case ClothingCombo.longLong:
      items.add(s.clothingLongSleeveJersey);
      // Tussen 10 en 14 graden stond hier "kniewarmers". Weg (Joost,
      // 2026-09-08): dat is geen kledingstuk dat mensen aanhebben -- korte of
      // lange broek is genoeg, en die staat al in de bandnaam (lang/lang).
      // Er is dus bewust géén vervanger; een advies dat niets toevoegt hoort
      // er niet te staan.
      if (advice.feelsLike < 10) {
        items.addAll([s.clothingArmWarmers, s.clothingLegWarmers]);
      }
    case ClothingCombo.longLongExtra:
      items.addAll([
        s.clothingWinterJacket,
        s.clothingThermalPants,
        s.clothingGloves,
        s.clothingOvershoes,
      ]);
  }

  if (advice.raining) items.add(s.clothingRainJacket);
  if (advice.windy) items.add(s.clothingWindVest);

  return items;
}
