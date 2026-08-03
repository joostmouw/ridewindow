import 'package:test/test.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';

void main() {
  const profile = UserProfile(
    tolerances: WeatherTolerances(
      tempMinIdealC: 8.0,
      tempMaxIdealC: 24.0,
      windMaxIdealKmh: 20.0,
      rainMaxIdealMm: 1.0,
    ),
    allowedDurations: [2, 4],
    theme: 'dark',
    locale: 'en',
    locationOverride: 'Utrecht',
    userName: 'Joost',
    notifEveningBefore: true,
    notifMorningOf: false,
    notifWeeklyDigest: true,
  );

  group('UserProfile.toRow — public.profiles kolomvorm (SYNC-01, SYNC-02)', () {
    test('bevat exact de 13 verwachte kolommen met matchende waarden', () {
      final row = profile.toRow('uid-1');

      expect(row.length, 13);
      expect(row.keys.toSet(), {
        'user_id',
        'temp_min_ideal_c',
        'temp_max_ideal_c',
        'wind_max_ideal_kmh',
        'rain_max_ideal_mm',
        'allowed_durations',
        'theme',
        'locale',
        'location_override',
        'user_name',
        'notif_evening_before',
        'notif_morning_of',
        'notif_weekly_digest',
      });

      expect(row['user_id'], 'uid-1');
      expect(row['temp_min_ideal_c'], 8.0);
      expect(row['temp_max_ideal_c'], 24.0);
      expect(row['wind_max_ideal_kmh'], 20.0);
      expect(row['rain_max_ideal_mm'], 1.0);
      expect(row['allowed_durations'], [2, 4]);
      expect(row['theme'], 'dark');
      expect(row['locale'], 'en');
      expect(row['location_override'], 'Utrecht');
      expect(row['user_name'], 'Joost');
      expect(row['notif_evening_before'], isTrue);
      expect(row['notif_morning_of'], isFalse);
      expect(row['notif_weekly_digest'], isTrue);

      // updated_at/created_at worden server-side gestempeld — nooit meegestuurd.
      expect(row.containsKey('updated_at'), isFalse);
      expect(row.containsKey('created_at'), isFalse);
    });
  });

  group('UserProfile.fromRow — round-trip met toRow', () {
    test('reconstrueert een gelijk UserProfile veld-voor-veld', () {
      final row = profile.toRow('uid-1');
      final roundTripped = UserProfile.fromRow(row);

      expect(roundTripped.tolerances.tempMinIdealC, profile.tolerances.tempMinIdealC);
      expect(roundTripped.tolerances.tempMaxIdealC, profile.tolerances.tempMaxIdealC);
      expect(roundTripped.tolerances.windMaxIdealKmh, profile.tolerances.windMaxIdealKmh);
      expect(roundTripped.tolerances.rainMaxIdealMm, profile.tolerances.rainMaxIdealMm);
      expect(roundTripped.allowedDurations, profile.allowedDurations);
      expect(roundTripped.theme, profile.theme);
      expect(roundTripped.locale, profile.locale);
      expect(roundTripped.locationOverride, profile.locationOverride);
      expect(roundTripped.userName, profile.userName);
      expect(roundTripped.notifEveningBefore, profile.notifEveningBefore);
      expect(roundTripped.notifMorningOf, profile.notifMorningOf);
      expect(roundTripped.notifWeeklyDigest, profile.notifWeeklyDigest);
    });

    test('leest null location_override/user_name correct terug', () {
      const noNamesProfile = UserProfile(
        tolerances: WeatherTolerances(),
        allowedDurations: [2, 3, 5],
        theme: 'system',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );
      final row = noNamesProfile.toRow('uid-2');
      final roundTripped = UserProfile.fromRow(row);

      expect(roundTripped.locationOverride, isNull);
      expect(roundTripped.userName, isNull);
    });
  });
}
