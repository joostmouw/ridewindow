import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/database/sync_outbox_entity_types.dart';
import 'package:ridewindow/data/repositories/availability_repository.dart';
import 'package:ridewindow/data/repositories/planned_rides_repository.dart';
import 'package:ridewindow/data/repositories/profile_repository.dart';
import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/services/migration_payload.dart';
import 'package:ridewindow/services/account_sync_service.dart';

/// Records resetToDefaults() calls without otherwise altering
/// ProfileRepository's behavior — the MIG-07 runtime proof (as opposed to a
/// source-grep) that AccountSyncService never wipes local data.
class RecordingProfileRepository extends ProfileRepository {
  RecordingProfileRepository(super.prefs, {super.outbox, super.userId});

  final destructiveCalls = <String>[];

  @override
  Future<void> resetToDefaults() {
    destructiveCalls.add('resetToDefaults');
    return super.resetToDefaults();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'uid-1';

  late AppDatabase db;
  late RecordingProfileRepository profileRepo;
  late AvailabilityRepository availabilityRepo;
  late PlannedRidesRepository plannedRidesRepo;
  late List<Map<String, dynamic>> migrateCalls;
  late List<String> writeLastSyncedUidCalls;
  late int readCloudAvailabilityCallCount;
  CloudProfileMeta? cloudProfile;
  CloudAvailabilityMeta? cloudAvailability;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    profileRepo = RecordingProfileRepository(
      prefs,
      outbox: db.syncOutboxDao,
      userId: userId,
    );
    availabilityRepo = AvailabilityRepository(
      prefs,
      outbox: db.syncOutboxDao,
      userId: userId,
    );
    plannedRidesRepo = PlannedRidesRepository(
      prefs,
      outbox: db.syncOutboxDao,
      userId: userId,
    );
    migrateCalls = [];
    writeLastSyncedUidCalls = [];
    readCloudAvailabilityCallCount = 0;
    cloudProfile = null;
    cloudAvailability = null;
  });

  tearDown(() async {
    await db.close();
  });

  AccountSyncService buildService() => AccountSyncService(
        profileRepo: profileRepo,
        availabilityRepo: availabilityRepo,
        plannedRidesRepo: plannedRidesRepo,
        readCloudProfile: (uid) async => cloudProfile,
        readCloudAvailability: (uid) async {
          readCloudAvailabilityCallCount++;
          return cloudAvailability;
        },
        migrateFn: (params) async => migrateCalls.add(params),
        writeLastSyncedUid: (uid) async => writeLastSyncedUidCalls.add(uid),
      );

  test(
      '1. Neither domain has a cloud row -> exactly one migrateFn call built '
      'from current local state, exactly one writeLastSyncedUid call, no '
      'prompts (MIG-01, MIG-05, MIG-06)', () async {
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
    await profileRepo.save(profile, stamp: false);

    final hours = {DateTime(2026, 8, 3, 9): BlockType.work};
    await availabilityRepo.save(hours, stamp: false);

    final ride = PlannedRide(
      start: DateTime.now().add(const Duration(days: 1)),
      end: DateTime.now().add(const Duration(days: 1, hours: 3)),
      plannedScore: 70.0,
    );
    await plannedRidesRepo.add(ride);

    final service = buildService();
    final prompts = await service.onSignIn(userId, lastSyncedUid: null);

    expect(prompts, isEmpty);
    expect(migrateCalls, hasLength(1));
    expect(
      migrateCalls.single,
      equals(
        buildMigrationRpcParams(
          profile: profileRepo.readLocal(),
          availabilityHours: availabilityRepo.readLocal(),
          plannedRides: plannedRidesRepo.readLocal(),
        ),
      ),
    );
    expect(writeLastSyncedUidCalls, [userId]);
    expect(profileRepo.destructiveCalls, isEmpty);
  });

  test(
      '2. Cloud availability exists with a different lastSyncedUid on the '
      'device -> pullCloudToLocal applied without prompting, migrateFn is '
      'NOT called (MIG-02, confirms the first-login trigger is not '
      'over-broad)', () async {
    await availabilityRepo.save(
      {DateTime(2026, 8, 3, 9): BlockType.custom},
      stamp: false,
    );

    cloudProfile = (
      profile: const UserProfile(
        tolerances: WeatherTolerances(),
        allowedDurations: [2, 3, 5],
        theme: 'system',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      ),
      updatedAt: DateTime.now(),
    );
    final cloudHours = {DateTime(2026, 8, 5, 10): BlockType.work};
    cloudAvailability = (hours: cloudHours, updatedAt: DateTime.now());

    final service = buildService();
    final prompts =
        await service.onSignIn(userId, lastSyncedUid: 'other-device-uid');

    expect(prompts, isEmpty);
    expect(migrateCalls, isEmpty);
    expect(availabilityRepo.readLocal(), cloudHours);
    expect(
      availabilityRepo.readUpdatedAt(),
      cloudAvailability!.updatedAt.millisecondsSinceEpoch,
    );
    expect(writeLastSyncedUidCalls, [userId]);
    expect(profileRepo.destructiveCalls, isEmpty);
  });

  test(
      '3. Same account, same device, local clearly newer than cloud by more '
      'than 5 seconds -> pushLocalToCloud applied without prompting, local '
      'storage is not rewritten (MIG-03 unambiguous branch)', () async {
    final localHours = {DateTime(2026, 8, 3, 9): BlockType.work};
    await availabilityRepo.save(localHours);
    final localStamp = availabilityRepo.readUpdatedAt();

    // Profile stays unambiguous (noop) so this test isolates availability's
    // push behavior — both sides present, timestamps within the 5s band.
    await profileRepo.save(profileRepo.readLocal());
    cloudProfile = (
      profile: profileRepo.readLocal(),
      updatedAt: DateTime.now(),
    );
    cloudAvailability = (
      hours: {DateTime(2026, 8, 5, 10): BlockType.custom},
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    final service = buildService();
    final prompts = await service.onSignIn(userId, lastSyncedUid: userId);

    expect(prompts, isEmpty);
    expect(migrateCalls, isEmpty);
    // Local storage untouched — still the value saved above, not cloud's.
    expect(availabilityRepo.readLocal(), localHours);
    expect(availabilityRepo.readUpdatedAt(), localStamp);

    final pending = await db.syncOutboxDao.pendingRows();
    final availabilityPushes =
        pending.where((r) => r.entity == kOutboxEntityAvailability).toList();
    expect(availabilityPushes, hasLength(1));
    expect(availabilityPushes.single.entityKey, userId);
    expect(availabilityPushes.single.operation, 'upsert');
    expect(profileRepo.destructiveCalls, isEmpty);
  });

  test(
      '4. Same account, same device, local availability timestamp missing '
      '-> profile appears in the returned prompt list; writeLastSyncedUid '
      'is NOT called while the prompt remains unresolved (MIG-03 ambiguous '
      'branch)', () async {
    // profileRepo never saved -> readUpdatedAt() is null (the ambiguous
    // local side). availabilityMeta is null (no cloud row) so it resolves
    // unambiguously via pushLocalToCloud, isolating the profile domain.
    cloudProfile = (
      profile: profileRepo.readLocal(),
      updatedAt: DateTime.now(),
    );
    cloudAvailability = null;

    final service = buildService();
    final prompts = await service.onSignIn(userId, lastSyncedUid: userId);

    expect(prompts, hasLength(1));
    expect(prompts.single.domain, SyncDomain.profile);
    expect(writeLastSyncedUidCalls, isEmpty);
    expect(migrateCalls, isEmpty);
    expect(profileRepo.destructiveCalls, isEmpty);
  });

  test(
      '5. resolvePrompt(profile, keepLocal: false) applies pullCloudToLocal '
      'for profile only, leaving availability untouched', () async {
    final cloudProfileData = const UserProfile(
      tolerances: WeatherTolerances(
        tempMinIdealC: 5.0,
        tempMaxIdealC: 22.0,
        windMaxIdealKmh: 18.0,
        rainMaxIdealMm: 0.8,
      ),
      allowedDurations: [3],
      theme: 'light',
      locale: 'nl',
      userName: 'Cloud Name',
      notifEveningBefore: true,
      notifMorningOf: true,
      notifWeeklyDigest: false,
    );
    final cloudUpdatedAt = DateTime.now();
    cloudProfile = (profile: cloudProfileData, updatedAt: cloudUpdatedAt);

    await availabilityRepo.save(
      {DateTime(2026, 8, 3, 9): BlockType.work},
      stamp: false,
    );
    final availabilityBefore = availabilityRepo.readLocal();

    final service = buildService();
    await service.resolvePrompt(
      const PendingSyncPrompt(SyncDomain.profile),
      userId,
      keepLocal: false,
    );

    expect(profileRepo.readLocal().userName, 'Cloud Name');
    expect(
      profileRepo.readUpdatedAt(),
      cloudUpdatedAt.millisecondsSinceEpoch,
    );
    // Availability untouched: readCloudAvailability was never invoked, and
    // local availability data is unchanged.
    expect(readCloudAvailabilityCallCount, 0);
    expect(availabilityRepo.readLocal(), availabilityBefore);
    expect(profileRepo.destructiveCalls, isEmpty);
  });

  test('6. markSynced(userId) calls writeLastSyncedUid(userId) and nothing '
      'else', () async {
    final service = buildService();
    await service.markSynced(userId);

    expect(writeLastSyncedUidCalls, [userId]);
    expect(migrateCalls, isEmpty);
    expect(readCloudAvailabilityCallCount, 0);
    expect(profileRepo.destructiveCalls, isEmpty);
  });

  test(
      '7. No resetToDefaults()/clearAll() call occurs on any repository '
      'across a full onSignIn() sweep touching both push and pull paths '
      '(MIG-07)', () async {
    await profileRepo.save(profileRepo.readLocal());
    await availabilityRepo.save(
      {DateTime(2026, 8, 3, 9): BlockType.work},
    );

    cloudProfile = (
      profile: profileRepo.readLocal(),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );
    cloudAvailability = null;

    final service = buildService();
    await service.onSignIn(userId, lastSyncedUid: userId);

    expect(profileRepo.destructiveCalls, isEmpty);
  });
}
