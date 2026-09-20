// De omrekening, los van elk scherm.
//
// Dit is het soort code waar een fout stil blijft: 15 graden die als 59 in
// plaats van 59,0 op het scherm komen valt niemand op, maar windkracht 4 die
// eigenlijk 5 is, verandert wat iemand besluit. Vandaar de grenzen uit de
// Beaufort-tabel met naam en toenaam.

import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/units.dart';

void main() {
  group('temperatuur', () {
    test('Celsius blijft Celsius', () {
      expect(convertTemp(15.4, TempUnit.celsius), 15.4);
    });

    test('de drie ijkpunten van Fahrenheit', () {
      expect(convertTemp(0, TempUnit.fahrenheit), 32);
      expect(convertTemp(100, TempUnit.fahrenheit), 212);
      // Het punt waar de twee schalen elkaar kruisen.
      expect(convertTemp(-40, TempUnit.fahrenheit), -40);
    });

    test('fietsweer', () {
      expect(convertTemp(20, TempUnit.fahrenheit), closeTo(68, 0.01));
    });
  });

  group('wind', () {
    test('km/u blijft km/u, mijl per uur is de bekende factor', () {
      expect(convertWind(30, WindUnit.kmh), 30);
      expect(convertWind(100, WindUnit.mph), closeTo(62.14, 0.01));
    });

    test('elke Beaufort-grens valt aan de juiste kant', () {
      // Onder de eerste grens is het windkracht 0, en op elke grens begint de
      // volgende kracht. Dit is de tabel, niet een benadering ervan.
      expect(beaufortFromKmh(0), 0);
      expect(beaufortFromKmh(0.9), 0);
      expect(beaufortFromKmh(1), 1);
      expect(beaufortFromKmh(5.9), 1);
      expect(beaufortFromKmh(6), 2);
      expect(beaufortFromKmh(11.9), 2);
      expect(beaufortFromKmh(12), 3);
      expect(beaufortFromKmh(19.9), 3);
      expect(beaufortFromKmh(20), 4);
      expect(beaufortFromKmh(28.9), 4);
      expect(beaufortFromKmh(29), 5);
      expect(beaufortFromKmh(38.9), 5);
      expect(beaufortFromKmh(39), 6);
      expect(beaufortFromKmh(49.9), 6);
      expect(beaufortFromKmh(50), 7);
      expect(beaufortFromKmh(62), 8);
      expect(beaufortFromKmh(75), 9);
      expect(beaufortFromKmh(89), 10);
      expect(beaufortFromKmh(103), 11);
      expect(beaufortFromKmh(118), 12);
    });

    test('de schaal houdt op bij 12, ook in een orkaan', () {
      expect(beaufortFromKmh(250), 12);
      expect(convertWind(250, WindUnit.beaufort), 12);
    });

    test('Beaufort is een geheel getal, geen afgeronde meting', () {
      // 25 km/u is midden in kracht 4. De app mag daar nooit "4,2" van maken.
      expect(convertWind(25, WindUnit.beaufort), 4);
      expect(windDecimals(WindUnit.beaufort), 0);
    });
  });

  group('opslag', () {
    test('een onbekende of ontbrekende sleutel valt terug op de standaard', () {
      expect(TempUnit.fromKey(null), TempUnit.celsius);
      expect(TempUnit.fromKey('kelvin'), TempUnit.celsius);
      expect(WindUnit.fromKey(null), WindUnit.kmh);
      expect(WindUnit.fromKey('knopen'), WindUnit.kmh);
    });

    test('de sleutels zelf liggen vast -- hernoemen wist iemands instelling',
        () {
      expect(TempUnit.fahrenheit.key, 'f');
      expect(WindUnit.beaufort.key, 'bft');
      expect(WindUnit.mph.key, 'mph');
    });
  });
}
