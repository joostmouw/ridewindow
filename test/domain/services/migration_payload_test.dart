import 'package:test/test.dart';
import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/services/migration_payload.dart';

void main() {
  group('buildMigrationRpcParams — MIG-08 exact RPC payload shape', () {
    test(
        'a realistic, non-default fixture produces the exact 14-key payload '
        'migrate_account_data expects, field-by-field', () {
      // Realistic profile: 11 of 12 fields non-default (only notifMorningOf
      // stays at its default `false`) — proves field-by-field mapping, not
      // a trivial/default-only fixture.
      final profile = const UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 8.0,
          tempMaxIdealC: 24.0,
          windMaxIdealKmh: 20.0,
          rainMaxIdealMm: 1.0,
        ),
        allowedDurations: [2, 4, 6],
        theme: 'dark',
        locale: 'en',
        locationOverride: 'Utrecht',
        userName: 'Joost',
        notifEveningBefore: true,
        notifMorningOf: false,
        notifWeeklyDigest: true,
      );

      // Mix of work/custom/calendar entries spanning four different
      // weekdays (2026-08-03 = Monday, 2026-08-04 = Tuesday,
      // 2026-08-05 = Wednesday, 2026-08-07 = Friday) — the calendar entry
      // must be excluded entirely (SYNC-10, reused by toRecurringRow()).
      final availabilityHours = {
        DateTime(2026, 8, 3, 9): BlockType.work, // Monday
        DateTime(2026, 8, 3, 17): BlockType.custom, // Monday
        DateTime(2026, 8, 5, 10): BlockType.work, // Wednesday
        DateTime(2026, 8, 7, 8): BlockType.custom, // Friday
        DateTime(2026, 8, 4, 14): BlockType.calendar, // Tuesday — excluded
      };

      final ride1 = PlannedRide(
        start: DateTime.parse('2026-08-10T09:00:00.000'),
        end: DateTime.parse('2026-08-10T13:00:00.000'),
        plannedScore: 82.5,
      );
      final ride2 = PlannedRide(
        start: DateTime.parse('2026-08-12T14:00:00.000'),
        end: DateTime.parse('2026-08-12T18:00:00.000'),
        plannedScore: 65.0,
      );

      final params = buildMigrationRpcParams(
        profile: profile,
        availabilityHours: availabilityHours,
        plannedRides: [ride1, ride2],
      );

      // Exactly 14 keys: 12 profile fields + p_availability_recurring +
      // p_planned_rides.
      expect(params.keys, hasLength(14));

      expect(params['p_temp_min_ideal_c'], 8.0);
      expect(params['p_temp_max_ideal_c'], 24.0);
      expect(params['p_wind_max_ideal_kmh'], 20.0);
      expect(params['p_rain_max_ideal_mm'], 1.0);
      expect(params['p_allowed_durations'], [2, 4, 6]);
      expect(params['p_theme'], 'dark');
      expect(params['p_locale'], 'en');
      expect(params['p_location_override'], 'Utrecht');
      expect(params['p_user_name'], 'Joost');
      expect(params['p_notif_evening_before'], true);
      expect(params['p_notif_morning_of'], false);
      expect(params['p_notif_weekly_digest'], true);

      // p_availability_recurring: only work/custom survive, zero calendar
      // entries.
      expect(params['p_availability_recurring'], {
        '1-9': 'work',
        '1-17': 'custom',
        '3-10': 'work',
        '5-8': 'custom',
      });

      // p_planned_rides: camelCase keys, ISO8601 strings, matching seed
      // order.
      expect(params['p_planned_rides'], [
        {
          'rideId': ride1.rideId,
          'startAt': '2026-08-10T09:00:00.000',
          'endAt': '2026-08-10T13:00:00.000',
          'plannedScore': 82.5,
        },
        {
          'rideId': ride2.rideId,
          'startAt': '2026-08-12T14:00:00.000',
          'endAt': '2026-08-12T18:00:00.000',
          'plannedScore': 65.0,
        },
      ]);
    });

    test('an empty plannedRides list produces p_planned_rides: [], not null',
        () {
      final profile = const UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 12.0,
          tempMaxIdealC: 26.0,
          windMaxIdealKmh: 15.0,
          rainMaxIdealMm: 0.5,
        ),
        allowedDurations: [2, 3, 5],
        theme: 'system',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );

      final params = buildMigrationRpcParams(
        profile: profile,
        availabilityHours: const {},
        plannedRides: const [],
      );

      expect(params['p_planned_rides'], isA<List>());
      expect(params['p_planned_rides'], isEmpty);
      expect(params['p_planned_rides'], isNotNull);
    });
  });
}
