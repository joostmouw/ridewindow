import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/repositories/availability_repository.dart';
import 'package:ridewindow/data/repositories/planned_rides_repository.dart';
import 'package:ridewindow/data/repositories/profile_repository.dart';
import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';

/// Table-driven invariant (plan 21-12, Task 1): every entity's *enqueued*
/// outbox payload must be a legal row for its Postgres table — its top-level
/// keys must all be real columns of that table, and it must always carry
/// `user_id`. This is the invariant whose absence let
/// `AvailabilityRepository` enqueue weekday-hour strings ("1-9", "6-14") as
/// if they were column names, so `client.from('availability').upsert(...)`
/// could never succeed (see `.planning/phases/21-sync-migration/21-12-PLAN.md`).
///
/// Column lists below are hand-copied literals from
/// `supabase/migrations/0001_accounts_sync.sql`'s three `create table`
/// blocks — deliberately NOT parsed at runtime, so a schema change forces
/// someone to consciously update this list rather than the test silently
/// tracking whatever the SQL says. They exclude columns the client never
/// sends: `updated_at`/`created_at` are stamped server-side by the
/// `set_updated_at` trigger, and `availability.version` has no client
/// writer.
const _profileColumns = {
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
};

const _availabilityColumns = {
  'user_id',
  'recurring',
};

const _plannedRideColumns = {
  'user_id',
  'ride_id',
  'start_at',
  'end_at',
  'planned_score',
};

void main() {
  // Same reasoning as availability_repository_test.dart: this suite uses
  // plain test()/group(), so TestWidgetsFlutterBinding must be initialised
  // manually before SharedPreferences.getInstance() can resolve its
  // platform channel.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Asserts [payload]'s keys are all members of [legalColumns] and that it
  /// always carries `user_id` — the two halves of "is a legal row".
  void expectLegalRow(
    Map<String, dynamic> payload,
    Set<String> legalColumns,
    String label,
  ) {
    expect(
      payload.containsKey('user_id'),
      isTrue,
      reason: '$label payload must carry user_id, got keys: ${payload.keys}',
    );
    for (final key in payload.keys) {
      expect(
        legalColumns.contains(key),
        isTrue,
        reason: '$label payload key "$key" is not a real column of its '
            'Postgres table (legal columns: $legalColumns) — got keys: '
            '${payload.keys}',
      );
    }
  }

  test('profile: enqueued payload is a legal public.profiles row', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ProfileRepository(prefs, outbox: db.syncOutboxDao, userId: 'uid-1');

    await repo.save(
      const UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 12,
          tempMaxIdealC: 26,
          windMaxIdealKmh: 15,
          rainMaxIdealMm: 0.5,
        ),
        allowedDurations: [2, 3, 5],
        theme: 'system',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      ),
    );

    final pending = await db.syncOutboxDao.pendingRows();
    expect(pending, hasLength(1));
    final payload = jsonDecode(pending.single.payload) as Map<String, dynamic>;
    expectLegalRow(payload, _profileColumns, 'profile');
  });

  test(
    'availability: enqueued payload is a legal public.availability row '
    '(FAILS today — the payload is the bare recurring map, not a row)',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo =
          AvailabilityRepository(prefs, outbox: db.syncOutboxDao, userId: 'uid-1');

      await repo.save({
        DateTime(2026, 7, 27, 9): BlockType.work,
        DateTime(2026, 7, 28, 17): BlockType.custom,
      });

      final pending = await db.syncOutboxDao.pendingRows();
      expect(pending, hasLength(1));
      final payload = jsonDecode(pending.single.payload) as Map<String, dynamic>;
      expectLegalRow(payload, _availabilityColumns, 'availability');
    },
  );

  test(
    'planned_rides: enqueued payload is a legal public.planned_rides row',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo =
          PlannedRidesRepository(prefs, outbox: db.syncOutboxDao, userId: 'uid-1');

      await repo.add(
        PlannedRide(
          start: DateTime(2026, 7, 27, 9),
          end: DateTime(2026, 7, 27, 11),
          plannedScore: 88,
        ),
      );

      final pending = await db.syncOutboxDao.pendingRows();
      expect(pending, hasLength(1));
      final payload = jsonDecode(pending.single.payload) as Map<String, dynamic>;
      expectLegalRow(payload, _plannedRideColumns, 'planned_ride');
    },
  );
}
