/// In welke eenheid de app getallen laat zien.
///
/// **Alleen weergave.** De motor rekent overal in graden Celsius, millimeters
/// en kilometers per uur -- dat is wat Open-Meteo levert en wat de scores en de
/// toleranties gebruiken. Hier wordt uitsluitend omgezet op het moment dat een
/// getal tekst wordt. Zou de omrekening dieper zitten, dan zouden een ingestelde
/// grens en een gemeten waarde in verschillende eenheden kunnen belanden, en dat
/// is precies het soort fout dat je pas ziet als iemand zich afvraagt waarom een
/// score niet klopt.
///
/// **Waarom dit per toestel staat en niet in de cloud.** Een eenheid is geen
/// eigenschap van jou maar van het scherm waar je naar kijkt, en het is de enige
/// instelling waarvoor dat geldt. Hij hoort dus bij de sleutels die bewust
/// lokaal blijven (`location.*`, `analytics.*`), niet bij `profiles`. Dat
/// scheelt ook een migratie op een tabel waar er al elf op staan.
library;

/// Waarin temperatuur op het scherm komt.
enum TempUnit {
  celsius('c', '°C'),
  fahrenheit('f', '°F');

  const TempUnit(this.key, this.suffix);

  /// Wat er in SharedPreferences staat. Een korte code en niet de enum-naam:
  /// hernoemen van een enum mag nooit iemands instelling wissen.
  final String key;

  /// Wat er achter het getal komt.
  final String suffix;

  static TempUnit fromKey(String? key) =>
      TempUnit.values.firstWhere((u) => u.key == key, orElse: () => celsius);
}

/// Waarin wind op het scherm komt.
///
/// Beaufort staat erbij omdat dat de schaal is waarin een Nederlandse fietser
/// denkt ("windkracht 6"), en mijl per uur omdat wie Fahrenheit kiest vrijwel
/// zeker ook geen kilometers gebruikt.
enum WindUnit {
  kmh('kmh'),
  beaufort('bft'),
  mph('mph');

  const WindUnit(this.key);

  final String key;

  static WindUnit fromKey(String? key) =>
      WindUnit.values.firstWhere((u) => u.key == key, orElse: () => kmh);
}

/// De twee keuzes samen. Eén object, zodat een scherm er één ding van hoeft te
/// lezen en een test er één ding van hoeft te zetten.
class UnitPrefs {
  const UnitPrefs({this.temp = TempUnit.celsius, this.wind = WindUnit.kmh});

  final TempUnit temp;
  final WindUnit wind;

  UnitPrefs copyWith({TempUnit? temp, WindUnit? wind}) =>
      UnitPrefs(temp: temp ?? this.temp, wind: wind ?? this.wind);

  /// De standaard: Celsius en km/u, zoals de app het altijd deed.
  static const UnitPrefs defaults = UnitPrefs();
}

/// Celsius naar de gekozen eenheid.
double convertTemp(double celsius, TempUnit unit) => switch (unit) {
      TempUnit.celsius => celsius,
      TempUnit.fahrenheit => celsius * 9 / 5 + 32,
    };

/// Kilometer per uur naar de gekozen eenheid.
///
/// Beaufort geeft een geheel getal terug: de schaal *is* geheel. Wie 3,4
/// Beaufort op een scherm zet, doet alsof er een precisie is die er niet is.
double convertWind(double kmh, WindUnit unit) => switch (unit) {
      WindUnit.kmh => kmh,
      WindUnit.mph => kmh * 0.621371,
      WindUnit.beaufort => beaufortFromKmh(kmh).toDouble(),
    };

/// De ondergrenzen van windkracht 1 tot en met 12, in km/u.
///
/// Uit de standaard Beaufort-tabel. Onder de eerste grens is het windkracht 0
/// ("stil"), boven de laatste windkracht 12 ("orkaan") -- die schaal houdt
/// daar op, en dat is geen afronding maar de definitie.
const List<double> kBeaufortLowerBoundsKmh = [
  1, 6, 12, 20, 29, 39, 50, 62, 75, 89, 103, 118,
];

/// Windkracht bij een snelheid in km/u, 0 tot en met 12.
int beaufortFromKmh(double kmh) {
  var force = 0;
  for (final bound in kBeaufortLowerBoundsKmh) {
    if (kmh >= bound) {
      force++;
    } else {
      break;
    }
  }
  return force;
}

/// De tekst achter een windgetal. Leeg voor Beaufort: daar hoort het woord
/// ervóór ("windkracht 5"), en dat staat in de vertaalbestanden.
String windSuffix(WindUnit unit) => switch (unit) {
      WindUnit.kmh => 'km/h',
      WindUnit.mph => 'mph',
      WindUnit.beaufort => 'Bft',
    };

/// Hoeveel cijfers achter de komma een waarde in deze eenheid verdient.
///
/// Geen van drieën heeft er een nodig: wind meet je niet op een tiende
/// nauwkeurig, en een halve graad Fahrenheit is een schijnnauwkeurigheid die
/// uit de omrekening komt en niet uit de meting.
int windDecimals(WindUnit unit) => 0;
