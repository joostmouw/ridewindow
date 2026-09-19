// De laatst bekende positie is de brug tussen het scherm en de
// achtergrondtaak. Ging die brug stuk, dan overschreef de taak elke drie uur
// de verse voorspelling met die van Amsterdam (backlog: Aruba, 2026-09-19).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/last_known_location_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('leeg tot er iets geschreven is', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LastKnownLocationStore(await SharedPreferences.getInstance());
    expect(store.read(), isNull);
  });

  test('schrijft en leest dezelfde positie terug', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LastKnownLocationStore(await SharedPreferences.getInstance());
    final moment = DateTime(2026, 9, 19, 9, 37);

    await store.write(lat: 12.5211, lon: -69.9683, now: moment);

    final last = store.read()!;
    expect(last.lat, closeTo(12.5211, 1e-9));
    expect(last.lon, closeTo(-69.9683, 1e-9));
    expect(last.at, moment);
  });

  test('een halve schrijving levert niets op, geen halve positie', () async {
    // Verdedigt tegen de nare variant: lat bewaard, lon weg, en dan een punt
    // midden op de nulmeridiaan tonen alsof het gemeten is.
    SharedPreferences.setMockInitialValues({
      LastKnownLocationStore.kLatKey: 52.3676,
    });
    final store = LastKnownLocationStore(await SharedPreferences.getInstance());
    expect(store.read(), isNull);
  });

  test('staat los van de profile.*-sleutels die naar de cloud gaan', () {
    for (final key in [
      LastKnownLocationStore.kLatKey,
      LastKnownLocationStore.kLonKey,
      LastKnownLocationStore.kAtKey,
    ]) {
      expect(key.startsWith('location.'), isTrue);
      expect(key.startsWith('profile.'), isFalse);
    }
  });
}
