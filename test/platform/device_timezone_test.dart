import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:ridewindow/platform/device_timezone.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  setUp(() => tz.setLocalLocation(tz.UTC));

  Future<SharedPreferences> prefsWith([Map<String, Object> values = const {}]) {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('het toestel weet het: tz.local staat erop en de naam wordt bewaard',
      () async {
    final prefs = await prefsWith();

    final name = await applyDeviceTimezone(
      prefs,
      lookup: () async => 'Europe/Amsterdam',
    );

    expect(name, 'Europe/Amsterdam');
    expect(tz.local.name, 'Europe/Amsterdam');
    expect(prefs.getString(kDeviceTimezoneKey), 'Europe/Amsterdam');
  });

  test('peiling faalt in de isolate: de bewaarde zone van de voorgrond geldt',
      () async {
    final prefs = await prefsWith({kDeviceTimezoneKey: 'America/Aruba'});

    final name = await applyDeviceTimezone(
      prefs,
      lookup: () async => throw Exception('geen plugin in deze isolate'),
    );

    expect(name, 'America/Aruba');
    expect(tz.local.name, 'America/Aruba');
  });

  test('op reis wint het toestel van de bewaarde zone, en die schuift mee',
      () async {
    final prefs = await prefsWith({kDeviceTimezoneKey: 'Europe/Amsterdam'});

    await applyDeviceTimezone(prefs, lookup: () async => 'America/Aruba');

    expect(tz.local.name, 'America/Aruba');
    expect(prefs.getString(kDeviceTimezoneKey), 'America/Aruba');
  });

  test('een onbekende naam van het toestel valt terug op de bewaarde', () async {
    final prefs = await prefsWith({kDeviceTimezoneKey: 'Europe/Amsterdam'});

    final name =
        await applyDeviceTimezone(prefs, lookup: () async => 'Mars/Olympus');

    expect(name, 'Europe/Amsterdam');
    expect(tz.local.name, 'Europe/Amsterdam');
  });

  test('niets bekend: null, en tz.local blijft onaangeroerd -- geen gok',
      () async {
    final prefs = await prefsWith();

    final name = await applyDeviceTimezone(
      prefs,
      lookup: () async => throw Exception('geen plugin'),
    );

    expect(name, isNull);
    expect(tz.local, tz.UTC);
    expect(prefs.getString(kDeviceTimezoneKey), isNull);
  });
}
