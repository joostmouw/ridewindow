// Vangnet voor de Aruba-melding van 2026-09-19: een tester zag "licht van
// 01:32 tot 13:29" omdat de app de Amsterdamse zon op zijn eigen klok tekende.
// Deze test legt vast wanneer de app daar iets over hoort te zeggen -- en,
// net zo belangrijk, wanneer juist niet.

import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/domain/services/timezone_sanity.dart';

void main() {
  group('clockLooksForeign slaat aan', () {
    test('toestel in Aruba, weer van Amsterdam', () {
      expect(
        clockLooksForeign(
          lon: 4.9041, // Amsterdam
          deviceOffset: const Duration(hours: -4), // AST
        ),
        isTrue,
      );
    });

    test('toestel in Amsterdam, weer van New York', () {
      expect(
        clockLooksForeign(
          lon: -74.0060,
          deviceOffset: const Duration(hours: 2), // CEST
        ),
        isTrue,
      );
    });
  });

  group('clockLooksForeign zwijgt', () {
    // Deze vier zijn de reden dat de drempel op drie uur staat en niet lager:
    // een politieke tijdzone loopt altijd voor op zijn zonnetijd, en zomertijd
    // legt daar nog een uur bovenop.
    final ok = {
      'Nederland in de zomer': (4.9041, const Duration(hours: 2)),
      'Nederland in de winter': (4.9041, const Duration(hours: 1)),
      'VK in de zomer': (-0.1276, const Duration(hours: 1)),
      'Italie in de zomer': (12.4964, const Duration(hours: 2)),
      'New York in de zomer': (-74.0060, const Duration(hours: -4)),
      'San Francisco in de zomer': (-122.4194, const Duration(hours: -7)),
      'Aruba, en de app weet het': (-69.9683, const Duration(hours: -4)),
    };

    ok.forEach((naam, geval) {
      test(naam, () {
        expect(
          clockLooksForeign(lon: geval.$1, deviceOffset: geval.$2),
          isFalse,
          reason: 'mag niet ten onrechte waarschuwen bij $naam',
        );
      });
    });
  });
}
