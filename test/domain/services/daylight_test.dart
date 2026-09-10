// test/domain/services/daylight_test.dart
//
// De zonstand wordt lokaal berekend in plaats van opgehaald (zie de noot in
// `daylight.dart`), en dan moet de formule zich verantwoorden. Deze test toetst
// hem tegen de waarden die Open-Meteo zélf teruggeeft — dezelfde bron die de
// app voor het weer gebruikt, opgehaald op 2026-09-09 met `timezone=UTC`.
//
// Vier plaatsen, van Tromsø (69°N) tot Sydney (34°Z), plus een zomerdag in
// Nederland. Zou de formule er ergens naast zitten, dan zit hij er op deze
// spreiding gegarandeerd naast.

import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/services/daylight.dart';

/// Toegestane afwijking van de referentie. Open-Meteo rondt op hele minuten af,
/// dus één minuut speling is de meetonzekerheid en niet onze marge.
const _tolerance = Duration(minutes: 1);

void _expectClose(DateTime? actual, String expectedIso, String what) {
  expect(actual, isNotNull, reason: '$what ontbreekt');
  final expected = DateTime.parse('${expectedIso}Z');
  final diff = actual!.toUtc().difference(expected).abs();
  expect(
    diff <= _tolerance,
    isTrue,
    reason: '$what: berekend ${actual.toUtc().toIso8601String()}, '
        'Open-Meteo $expectedIso, verschil ${diff.inSeconds}s',
  );
}

void main() {
  group('sunTimes tegen Open-Meteo (referentie opgehaald 2026-09-09)', () {
    test('Amsterdam, 10 september', () {
      final sun = sunTimes(
        latitude: 52.37,
        longitude: 4.90,
        dayLocal: DateTime.utc(2026, 9, 10),
      );
      _expectClose(sun.sunrise, '2026-09-10T05:06', 'zonsopgang Amsterdam');
      _expectClose(sun.sunset, '2026-09-10T18:07', 'zonsondergang Amsterdam');
    });

    test('Tromsø, 10 september — hoge breedtegraad', () {
      final sun = sunTimes(
        latitude: 69.65,
        longitude: 18.96,
        dayLocal: DateTime.utc(2026, 9, 10),
      );
      _expectClose(sun.sunrise, '2026-09-10T03:37', 'zonsopgang Tromsø');
      _expectClose(sun.sunset, '2026-09-10T17:42', 'zonsondergang Tromsø');
    });

    test('Sydney, 10 september — zuidelijk halfrond', () {
      final sun = sunTimes(
        latitude: -33.87,
        longitude: 151.21,
        dayLocal: DateTime.utc(2026, 9, 10),
      );
      // Open-Meteo geeft hier de opgang op 9 september UTC: Sydney loopt 10 uur
      // voor, dus de ochtend van de 10e lokaal is de avond van de 9e in UTC.
      // De formule rekent op de UTC-dag, dus de opgang van de UTC-dag zelf is
      // die van 10 september 20:01 UTC.
      _expectClose(sun.sunset, '2026-09-10T07:43', 'zonsondergang Sydney');
    });

    test('New York, 10 september — westelijke lengtegraad', () {
      final sun = sunTimes(
        latitude: 40.71,
        longitude: -74.01,
        dayLocal: DateTime.utc(2026, 9, 10),
      );
      _expectClose(sun.sunrise, '2026-09-10T10:31', 'zonsopgang New York');
      _expectClose(sun.sunset, '2026-09-10T23:13', 'zonsondergang New York');
    });

    test('Amsterdam, 21 juni — langste dag', () {
      final sun = sunTimes(
        latitude: 52.37,
        longitude: 4.90,
        dayLocal: DateTime.utc(2026, 6, 21),
      );
      _expectClose(sun.sunrise, '2026-06-21T03:18', 'zonsopgang midzomer');
      _expectClose(sun.sunset, '2026-06-21T20:06', 'zonsondergang midzomer');
    });
  });

  group('poolgebieden', () {
    test('Tromsø eind juni: middernachtszon, geen opgang of ondergang', () {
      final sun = sunTimes(
        latitude: 69.65,
        longitude: 18.96,
        dayLocal: DateTime.utc(2026, 6, 21),
      );
      expect(sun.hasSunTimes, isFalse);
      expect(sun.polarDaylight, isTrue);
      expect(sun.isLightAt(DateTime.utc(2026, 6, 21, 2)), isTrue);
    });

    test('Tromsø eind december: poolnacht, het blijft donker', () {
      final sun = sunTimes(
        latitude: 69.65,
        longitude: 18.96,
        dayLocal: DateTime.utc(2026, 12, 21),
      );
      expect(sun.hasSunTimes, isFalse);
      expect(sun.polarDaylight, isFalse);
      expect(sun.isLightAt(DateTime.utc(2026, 12, 21, 12)), isFalse);
    });
  });

  group('darkFraction', () {
    // Het venster waar deze hele wijziging uit voortkomt. Ingrid, 2026-09-09:
    // "tot 22u fietsen staat er, maar dan is het al bijna donker". De app zette
    // dit venster op score 100.
    test('20:00–22:00 op 10 september in Amsterdam is vrijwel helemaal donker',
        () {
      // Zonsondergang lokaal (UTC+2 in september) om 20:07.
      final f = darkFraction(
        start: DateTime.utc(2026, 9, 10, 18),
        end: DateTime.utc(2026, 9, 10, 20),
        latitude: 52.37,
        longitude: 4.90,
      );
      expect(f, greaterThan(0.9));
      expect(f, lessThanOrEqualTo(1.0));
    });

    test('midden op de dag is niets donker', () {
      final f = darkFraction(
        start: DateTime.utc(2026, 9, 10, 9),
        end: DateTime.utc(2026, 9, 10, 13),
        latitude: 52.37,
        longitude: 4.90,
      );
      expect(f, 0);
    });

    test('midden in de nacht is alles donker', () {
      final f = darkFraction(
        start: DateTime.utc(2026, 9, 10, 1),
        end: DateTime.utc(2026, 9, 10, 3),
        latitude: 52.37,
        longitude: 4.90,
      );
      expect(f, 1);
    });

    test(
        'een venster dat de zonsondergang doorsnijdt telt alleen het donkere '
        'deel', () {
      // 17:00–19:00 UTC = 19:00–21:00 lokaal, zonsondergang 18:07 UTC.
      final f = darkFraction(
        start: DateTime.utc(2026, 9, 10, 17),
        end: DateTime.utc(2026, 9, 10, 19),
        latitude: 52.37,
        longitude: 4.90,
      );
      // 67 minuten licht van de 120, dus ongeveer 44% donker.
      expect(f, closeTo(0.44, 0.02));
    });
  });

  group('darknessPenalty', () {
    test('daglicht kost niets', () {
      expect(darknessPenalty(0), 0);
    });

    test(
        'een volledig donker venster kost bij de standaardstand de helft van '
        'het maximum', () {
      expect(darknessPenalty(1), kMaxDarknessPenalty * kDefaultDarknessWeight);
      expect(darknessPenalty(2), kMaxDarknessPenalty * kDefaultDarknessWeight,
          reason:
              'de fractie wordt begrensd, dus meer dan donker bestaat niet');
    });

    test('de schuif in Profiel schaalt de aftrek van niets tot het maximum',
        () {
      expect(darknessPenalty(1, weight: 0), 0,
          reason: 'helemaal links: de app trekt zich niets van donker aan');
      expect(darknessPenalty(1, weight: 1), kMaxDarknessPenalty,
          reason: 'helemaal rechts: een donker venster verliest 40 van de 100');
      expect(darknessPenalty(1, weight: 2), kMaxDarknessPenalty,
          reason: 'ook het gewicht wordt begrensd');
    });

    test('score 100 zakt naar 80 bij de standaardstand, en blijft vindbaar',
        () {
      expect(100 * (1 - darknessPenalty(1)), 80);
    });

    test(
        'het gewraakte venster van Ingrid zakt van 100 naar ruwweg 81 — onder '
        'elk daglichtvenster dat die week ook Perfect scoort', () {
      final f = darkFraction(
        start: DateTime.utc(2026, 9, 10, 18),
        end: DateTime.utc(2026, 9, 10, 20),
        latitude: 52.37,
        longitude: 4.90,
      );
      final adjusted = 100 * (1 - darknessPenalty(f));
      expect(adjusted, closeTo(81, 1.5));
    });
  });
}
