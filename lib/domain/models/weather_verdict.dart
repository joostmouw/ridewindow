/// Het uitgeschreven oordeel naast een weerbalk — "Dry", "Breezy", "Ideal".
///
/// Dit bestaat omdat een balk alléén niet leesbaar te krijgen was. De regenbalk
/// liep van 0 tot 10 mm terwijl het ideaal `≤ 0,5 mm` is: die groene zone was
/// 5% van de balkbreedte, en bij droog weer lag de stip er bovenop. Je kon er
/// niets uit aflezen. Het woord doet sindsdien het echte werk; de balk laat
/// alleen nog zien hóe ver iets van je ideaal af zit.
///
/// De grenzen zijn afgeleid van de tolerantie die de gebruiker zelf instelt en
/// niet van vaste getallen. Verzet iemand zijn windgrens naar 25 km/u, dan
/// schuift "Calm" mee. Dat is het hele punt van die instelling.
library;

enum WeatherMetric {
  temperature(absoluteMin: -10, absoluteMax: 45, zoomMin: 0, zoomMax: 35),
  rain(absoluteMin: 0, absoluteMax: 10, zoomMin: 0, zoomMax: 3),
  wind(absoluteMin: 0, absoluteMax: 60, zoomMin: 0, zoomMax: 40);

  const WeatherMetric({
    required this.absoluteMin,
    required this.absoluteMax,
    required this.zoomMin,
    required this.zoomMax,
  });

  /// Het volledige meetbereik. Wordt niet meer getekend, maar bepaalt wél hoe
  /// erg een afwijking is — zie [WeatherVerdict.level]. Zou je die afstand op
  /// het ingezoomde bereik meten, dan zou 4 mm regen net zo alarmerend kleuren
  /// als 12 mm.
  final double absoluteMin;
  final double absoluteMax;

  /// Het bereik dat daadwerkelijk getekend wordt. Waarden erbuiten worden niet
  /// weggemoffeld: de marker klapt tegen de rand en de echte waarde blijft
  /// voluit in tekst staan.
  final double zoomMin;
  final double zoomMax;
}

/// Hoe zwaar een oordeel weegt. Stuurt alleen kleur, niet de tekst.
enum WeatherVerdictLevel { ok, warn, bad }

/// De mogelijke oordelen. De vertaling zit in de ARB-bestanden; hier staan
/// alleen de gevallen, zodat de regel los van taal getest kan worden.
enum WeatherVerdict {
  // Regen
  dry(WeatherVerdictLevel.ok),
  light(WeatherVerdictLevel.ok),
  showers(WeatherVerdictLevel.warn),
  wet(WeatherVerdictLevel.bad),
  // Wind
  calm(WeatherVerdictLevel.ok),
  breezy(WeatherVerdictLevel.warn),
  gusty(WeatherVerdictLevel.bad),
  // Temperatuur
  chilly(WeatherVerdictLevel.warn),
  ideal(WeatherVerdictLevel.ok),
  warm(WeatherVerdictLevel.warn);

  const WeatherVerdict(this.level);

  final WeatherVerdictLevel level;
}

/// Ligt [value] binnen wat de gebruiker ideaal noemt?
///
/// Regen en wind kennen alleen een bovengrens; temperatuur heeft er twee.
bool isWithinIdeal(double value, {double? idealMin, required double idealMax}) {
  if (idealMin != null) return value >= idealMin && value <= idealMax;
  return value <= idealMax;
}

/// Het oordeel voor één meting.
///
/// De vermenigvuldigers hieronder zijn geen natuurkunde maar taalgevoel, en ze
/// zijn met Joost afgestemd (2026-09-07):
///
/// - **Regen** springt naar `wet` op vier keer de grens. Bij de standaard van
///   0,5 mm is dat 2 mm — dat is het punt waarop je nat thuiskomt in plaats van
///   klam.
/// - **Wind** springt naar `gusty` op 1,7 keer de grens, oftewel ruim 25 km/u
///   bij de standaard van 15. Daaronder is het voor een fietser gewoon wind.
/// - **Temperatuur** kent geen tussenstap: je zit erin, of je zit eronder of
///   erboven. Een derde gradatie leverde geen woord op dat iets toevoegde.
WeatherVerdict weatherVerdictFor(
  WeatherMetric metric,
  double value, {
  double? idealMin,
  required double idealMax,
}) {
  switch (metric) {
    case WeatherMetric.rain:
      if (value <= 0) return WeatherVerdict.dry;
      if (value <= idealMax) return WeatherVerdict.light;
      if (value <= idealMax * 4) return WeatherVerdict.showers;
      return WeatherVerdict.wet;
    case WeatherMetric.wind:
      if (value <= idealMax) return WeatherVerdict.calm;
      if (value <= idealMax * 1.7) return WeatherVerdict.breezy;
      return WeatherVerdict.gusty;
    case WeatherMetric.temperature:
      if (isWithinIdeal(value, idealMin: idealMin, idealMax: idealMax)) {
        return WeatherVerdict.ideal;
      }
      return idealMin != null && value < idealMin
          ? WeatherVerdict.chilly
          : WeatherVerdict.warm;
  }
}
