import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/profile_repository.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';

void main() {
  // Deze suite gebruikt plain test()/group() (geen testWidgets()), dus
  // Flutter's TestWidgetsFlutterBinding wordt niet automatisch geinitialiseerd.
  // SharedPreferences.getInstance() heeft ServicesBinding.instance nodig om
  // het platform-kanaal te resolven — zonder deze regel faalt elke test met
  // "Binding has not yet been initialized." (zie weather_repository_test.dart).
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = ProfileRepository(prefs);
  });

  test('Test 1 — bestaande installatie behoudt zijn instellingen', () async {
    SharedPreferences.setMockInitialValues({
      'profile.tempMinIdealC': 8.0,
      'profile.tempMaxIdealC': 24.0,
      'profile.windMaxIdealKmh': 20.0,
      'profile.rainMaxIdealMm': 1.0,
      'profile.allowedDurations': ['1', '4'],
      'profile.theme': 'dark',
      'profile.locationOverride': 'Utrecht',
      'profile.userName': 'Joost',
      'profile.locale': 'en',
      'profile.notifEveningBefore': true,
      'profile.notifMorningOf': true,
      'profile.notifWeeklyDigest': true,
    });
    final prefs = await SharedPreferences.getInstance();
    repo = ProfileRepository(prefs);

    final result = repo.readLocal();

    expect(result.tolerances.tempMinIdealC, 8.0);
    expect(result.tolerances.tempMaxIdealC, 24.0);
    expect(result.tolerances.windMaxIdealKmh, 20.0);
    expect(result.tolerances.rainMaxIdealMm, 1.0);
    expect(result.allowedDurations, [1, 4]);
    expect(result.theme, 'dark');
    expect(result.locationOverride, 'Utrecht');
    expect(result.userName, 'Joost');
    expect(result.locale, 'en');
    expect(result.notifEveningBefore, isTrue);
    expect(result.notifMorningOf, isTrue);
    expect(result.notifWeeklyDigest, isTrue);
  });

  test('Test 2 — verse installatie krijgt de defaults', () async {
    final result = repo.readLocal();

    expect(result.tolerances.tempMinIdealC, 12.0);
    expect(result.tolerances.tempMaxIdealC, 26.0);
    expect(result.tolerances.windMaxIdealKmh, 15.0);
    expect(result.tolerances.rainMaxIdealMm, 0.5);
    expect(result.allowedDurations, [2, 3, 5]);
    expect(result.theme, 'system');
    expect(result.locationOverride, isNull);
    expect(result.userName, isNull);
    expect(result.notifEveningBefore, isFalse);
    expect(result.notifMorningOf, isFalse);
    expect(result.notifWeeklyDigest, isFalse);
  });

  test(
      'Test 3 — locale-default volgt de meegegeven systeemtaal, opgeslagen locale wint',
      () async {
    expect(repo.readLocal(systemLanguageCode: 'nl').locale, 'nl');
    expect(repo.readLocal(systemLanguageCode: 'de').locale, 'en');

    SharedPreferences.setMockInitialValues({'profile.locale': 'nl'});
    final prefs = await SharedPreferences.getInstance();
    repo = ProfileRepository(prefs);
    expect(repo.readLocal(systemLanguageCode: 'de').locale, 'nl');
  });

  test('Test 4 — corrupte durations vallen terug op de default', () async {
    SharedPreferences.setMockInitialValues({
      'profile.allowedDurations': ['abc', '0', '-3'],
    });
    final prefs = await SharedPreferences.getInstance();
    repo = ProfileRepository(prefs);

    final result = repo.readLocal();

    expect(result.allowedDurations, [2, 3, 5]);
  });

  test(
      'Test 5 — null wist de sleutel in plaats van een lege string te schrijven',
      () async {
    const profile = UserProfile(
      tolerances: WeatherTolerances(),
      allowedDurations: [2, 3, 5],
      theme: 'system',
      locationOverride: null,
      userName: null,
      notifEveningBefore: false,
      notifMorningOf: false,
      notifWeeklyDigest: false,
    );

    await repo.save(profile);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile.locationOverride'), isNull);
    expect(prefs.getString('profile.userName'), isNull);
    expect(prefs.containsKey('profile.locationOverride'), isFalse);
    expect(prefs.containsKey('profile.userName'), isFalse);
  });

  test('Test 6 — save() stempelt profile.updatedAt (D-07)', () async {
    final before = DateTime.now().millisecondsSinceEpoch;

    await repo.save(repo.readLocal());

    final after = DateTime.now().millisecondsSinceEpoch;
    final stamped = repo.readUpdatedAt();

    expect(stamped, isNotNull);
    expect(stamped! >= before, isTrue);
    expect(stamped <= after, isTrue);
  });

  test('Test 7 — save(stamp: false) stempelt niet (D-07)', () async {
    final prefs = await SharedPreferences.getInstance();
    const knownStamp = 1700000000000;
    await prefs.setInt('profile.updatedAt', knownStamp);

    await repo.save(repo.readLocal(), stamp: false);

    expect(repo.readUpdatedAt(), knownStamp);
  });

  test('Test 8 — readUpdatedAt() geeft null zonder dat veld (D-08)', () async {
    expect(repo.readUpdatedAt(), isNull);
  });

  test('Test 9 — resetToDefaults() wist ook profile.updatedAt', () async {
    SharedPreferences.setMockInitialValues({
      'profile.tempMinIdealC': 8.0,
      'profile.tempMaxIdealC': 24.0,
      'profile.windMaxIdealKmh': 20.0,
      'profile.rainMaxIdealMm': 1.0,
      'profile.allowedDurations': ['1', '4'],
      'profile.theme': 'dark',
      'profile.locationOverride': 'Utrecht',
      'profile.userName': 'Joost',
      'profile.locale': 'en',
      'profile.notifEveningBefore': true,
      'profile.notifMorningOf': true,
      'profile.notifWeeklyDigest': true,
      'profile.updatedAt': 1700000000000,
    });
    final prefs = await SharedPreferences.getInstance();
    repo = ProfileRepository(prefs);

    await repo.resetToDefaults();

    expect(prefs.containsKey('profile.tempMinIdealC'), isFalse);
    expect(prefs.containsKey('profile.tempMaxIdealC'), isFalse);
    expect(prefs.containsKey('profile.windMaxIdealKmh'), isFalse);
    expect(prefs.containsKey('profile.rainMaxIdealMm'), isFalse);
    expect(prefs.containsKey('profile.allowedDurations'), isFalse);
    expect(prefs.containsKey('profile.theme'), isFalse);
    expect(prefs.containsKey('profile.locationOverride'), isFalse);
    expect(prefs.containsKey('profile.userName'), isFalse);
    expect(prefs.containsKey('profile.locale'), isFalse);
    expect(prefs.containsKey('profile.notifEveningBefore'), isFalse);
    expect(prefs.containsKey('profile.notifMorningOf'), isFalse);
    expect(prefs.containsKey('profile.notifWeeklyDigest'), isFalse);
    expect(prefs.containsKey('profile.updatedAt'), isFalse);
  });
}
