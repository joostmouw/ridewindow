import 'package:test/test.dart';
import 'package:ridewindow/domain/models/weather_verdict.dart';

void main() {
  // De standaardtoleranties uit UserProfile. De oordelen zijn hiervan
  // afgeleid en niet hardgecodeerd — dat wordt onderaan expliciet getoetst.
  const rainMax = 0.5;
  const windMax = 15.0;
  const tempMin = 12.0;
  const tempMax = 26.0;

  WeatherVerdict rain(double v) =>
      weatherVerdictFor(WeatherMetric.rain, v, idealMax: rainMax);
  WeatherVerdict wind(double v) =>
      weatherVerdictFor(WeatherMetric.wind, v, idealMax: windMax);
  WeatherVerdict temp(double v) => weatherVerdictFor(
        WeatherMetric.temperature,
        v,
        idealMin: tempMin,
        idealMax: tempMax,
      );

  group('regen', () {
    test('0 mm is droog, niet "licht"', () {
      // Het geval dat de hele herziening uitlokte: op de oude balk lag de stip
      // bij 0 mm bovenop een groene zone van 5% breed en zei het scherm niets.
      expect(rain(0), WeatherVerdict.dry);
    });

    test('binnen de eigen grens is het licht', () {
      expect(rain(0.3), WeatherVerdict.light);
      expect(rain(rainMax), WeatherVerdict.light, reason: 'grens telt als goed');
    });

    test('net over de grens is het buien, niet meteen nat', () {
      expect(rain(0.6), WeatherVerdict.showers);
      expect(rain(1.4), WeatherVerdict.showers);
    });

    test('vier keer de grens is nat', () {
      expect(rain(rainMax * 4), WeatherVerdict.showers, reason: 'grens telt mee');
      expect(rain(2.1), WeatherVerdict.wet);
      expect(rain(9), WeatherVerdict.wet);
    });
  });

  group('wind', () {
    test('binnen de eigen grens is het windstil', () {
      expect(wind(0), WeatherVerdict.calm);
      expect(wind(windMax), WeatherVerdict.calm);
    });

    test('tot 1,7 keer de grens is het een briesje', () {
      expect(wind(18), WeatherVerdict.breezy);
      expect(wind(windMax * 1.7), WeatherVerdict.breezy);
    });

    test('daarboven is het winderig', () {
      expect(wind(27), WeatherVerdict.gusty);
      expect(wind(46), WeatherVerdict.gusty);
    });
  });

  group('temperatuur', () {
    test('binnen het bereik is ideaal, grenzen inbegrepen', () {
      expect(temp(18), WeatherVerdict.ideal);
      expect(temp(tempMin), WeatherVerdict.ideal);
      expect(temp(tempMax), WeatherVerdict.ideal);
    });

    test('eronder is fris, erboven warm', () {
      expect(temp(6), WeatherVerdict.chilly);
      expect(temp(31), WeatherVerdict.warm);
    });
  });

  group('de oordelen volgen de eigen instelling, niet vaste getallen', () {
    test('een ruimere windgrens maakt 24 km/u weer windstil', () {
      // Dit is het hele punt van de tolerantie-instelling in Profiel: wie
      // gewend is aan wind moet niet elke rit "winderig" te zien krijgen.
      expect(wind(24), WeatherVerdict.breezy);
      expect(
        weatherVerdictFor(WeatherMetric.wind, 24, idealMax: 25),
        WeatherVerdict.calm,
      );
    });

    test('een strengere regengrens maakt 0,3 mm al buien', () {
      expect(rain(0.3), WeatherVerdict.light);
      expect(
        weatherVerdictFor(WeatherMetric.rain, 0.3, idealMax: 0.1),
        WeatherVerdict.showers,
      );
    });
  });

  group('niveau bepaalt de kleur', () {
    test('goed weer is ok, grensgevallen warn, echt slecht is bad', () {
      expect(WeatherVerdict.dry.level, WeatherVerdictLevel.ok);
      expect(WeatherVerdict.ideal.level, WeatherVerdictLevel.ok);
      expect(WeatherVerdict.showers.level, WeatherVerdictLevel.warn);
      expect(WeatherVerdict.wet.level, WeatherVerdictLevel.bad);
      expect(WeatherVerdict.gusty.level, WeatherVerdictLevel.bad);
    });
  });

  group('ingezoomde bereiken', () {
    test('regen tekent 0–3 mm in plaats van 0–10', () {
      // Met 0–10 was de ideaalzone (≤0,5) 5% van de balk. Met 0–3 is het ~17%,
      // en dát is het verschil tussen versiering en informatie.
      expect(WeatherMetric.rain.zoomMax, 3);
      expect(WeatherMetric.rain.absoluteMax, 10,
          reason: 'het volle bereik blijft bestaan voor de ernst-berekening');
    });

    test('elk bereik zoomt in, nooit uit', () {
      for (final m in WeatherMetric.values) {
        expect(m.zoomMin, greaterThanOrEqualTo(m.absoluteMin), reason: m.name);
        expect(m.zoomMax, lessThanOrEqualTo(m.absoluteMax), reason: m.name);
      }
    });
  });
}
