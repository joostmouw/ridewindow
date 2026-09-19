// De achtergrondtaak en het scherm moeten dezelfde plek ophalen. Deden ze dat
// niet, dan overschreef de taak elke drie uur de verse GPS-voorspelling met die
// van Amsterdam -- de tweede van de drie fouten achter de Aruba-melding van
// 2026-09-19.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/core/config.dart';
import 'package:ridewindow/data/repositories/last_known_location_store.dart';
import 'package:ridewindow/platform/background_task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('zonder iets bekend: Amsterdam, zoals altijd', () async {
    final (lat, lon) = resolveBackgroundLocation(
      prefs: await prefsWith({}),
      locationOverride: null,
    );
    expect(lat, kDefaultLat);
    expect(lon, kDefaultLon);
  });

  test('de laatst gemeten positie wint van de standaard', () async {
    final prefs = await prefsWith({
      LastKnownLocationStore.kLatKey: 12.5211,
      LastKnownLocationStore.kLonKey: -69.9683,
      LastKnownLocationStore.kAtKey: DateTime(2026, 9, 19).millisecondsSinceEpoch,
    });

    final (lat, lon) = resolveBackgroundLocation(
      prefs: prefs,
      locationOverride: null,
    );

    expect(lat, closeTo(12.5211, 1e-9), reason: 'Aruba, niet Amsterdam');
    expect(lon, closeTo(-69.9683, 1e-9));
  });

  test('een zelfgekozen stad wint van de laatst gemeten positie', () async {
    // Dezelfde voorrangsregel als location_provider.dart (LOC-05): wie zelf
    // kiest, meent dat.
    final prefs = await prefsWith({
      LastKnownLocationStore.kLatKey: 12.5211,
      LastKnownLocationStore.kLonKey: -69.9683,
      LastKnownLocationStore.kAtKey: DateTime(2026, 9, 19).millisecondsSinceEpoch,
    });

    final (lat, lon) = resolveBackgroundLocation(
      prefs: prefs,
      locationOverride: 'Groningen',
    );

    expect(lat, closeTo(53.2194, 1e-9));
    expect(lon, closeTo(6.5665, 1e-9));
  });

  test('een stad die niet bestaat valt door naar de laatst gemeten positie',
      () async {
    final prefs = await prefsWith({
      LastKnownLocationStore.kLatKey: 12.5211,
      LastKnownLocationStore.kLonKey: -69.9683,
      LastKnownLocationStore.kAtKey: DateTime(2026, 9, 19).millisecondsSinceEpoch,
    });

    final (lat, _) = resolveBackgroundLocation(
      prefs: prefs,
      locationOverride: 'Atlantis',
    );

    expect(lat, closeTo(12.5211, 1e-9));
  });

  test('een tester in een van de vier andere testlanden kan zijn stad kiezen',
      () async {
    final prefs = await prefsWith({});
    for (final stad in ['Brussel', 'Rome', 'Londen', 'New York']) {
      final (lat, lon) =
          resolveBackgroundLocation(prefs: prefs, locationOverride: stad);
      expect(
        lat == kDefaultLat && lon == kDefaultLon,
        isFalse,
        reason: '$stad mag niet stilletjes Amsterdam worden',
      );
    }
  });
}
