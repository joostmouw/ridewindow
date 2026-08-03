import 'package:test/test.dart';
import 'package:ridewindow/domain/services/account_sync_resolver.dart';

void main() {
  group('MIG-01: empty cloud account', () {
    test('cloudRowExists false pushes local to cloud, regardless of other params', () {
      expect(
        resolveAccountSync(
          userId: 'abc',
          lastSyncedUid: 'xyz',
          cloudRowExists: false,
          cloudUpdatedAt: null,
          localUpdatedAt: null,
        ),
        SyncDecision.pushLocalToCloud,
      );
    });
  });

  group('MIG-02: different or no local record', () {
    test('cloudRowExists true, lastSyncedUid null pulls cloud to local', () {
      expect(
        resolveAccountSync(
          userId: 'abc',
          lastSyncedUid: null,
          cloudRowExists: true,
          cloudUpdatedAt: DateTime(2026, 1, 1),
          localUpdatedAt: DateTime(2026, 1, 1),
        ),
        SyncDecision.pullCloudToLocal,
      );
    });

    test('cloudRowExists true, lastSyncedUid different uid pulls cloud to local', () {
      expect(
        resolveAccountSync(
          userId: 'abc',
          lastSyncedUid: 'xyz',
          cloudRowExists: true,
          cloudUpdatedAt: DateTime(2026, 1, 1),
          localUpdatedAt: DateTime(2026, 1, 1),
        ),
        SyncDecision.pullCloudToLocal,
      );
    });
  });

  group('MIG-03: same-account divergence', () {
    test('same account, cloud updatedAt null prompts user', () {
      expect(
        resolveAccountSync(
          userId: 'abc',
          lastSyncedUid: 'abc',
          cloudRowExists: true,
          cloudUpdatedAt: null,
          localUpdatedAt: DateTime(2026, 1, 1),
        ),
        SyncDecision.promptUser,
      );
    });

    test('same account, local updatedAt null prompts user', () {
      expect(
        resolveAccountSync(
          userId: 'abc',
          lastSyncedUid: 'abc',
          cloudRowExists: true,
          cloudUpdatedAt: DateTime(2026, 1, 1),
          localUpdatedAt: null,
        ),
        SyncDecision.promptUser,
      );
    });

    test('same account, both timestamps null prompts user', () {
      expect(
        resolveAccountSync(
          userId: 'abc',
          lastSyncedUid: 'abc',
          cloudRowExists: true,
          cloudUpdatedAt: null,
          localUpdatedAt: null,
        ),
        SyncDecision.promptUser,
      );
    });

    test('delta exactly 5 seconds falls outside noop band, local later pushes', () {
      final cloudTime = DateTime(2026, 1, 1, 12, 0, 0);
      final localTime = cloudTime.add(const Duration(seconds: 5));
      expect(
        resolveAccountSync(
          userId: 'abc',
          lastSyncedUid: 'abc',
          cloudRowExists: true,
          cloudUpdatedAt: cloudTime,
          localUpdatedAt: localTime,
        ),
        SyncDecision.pushLocalToCloud,
      );
    });

    test('delta exactly 5 seconds falls outside noop band, cloud later pulls', () {
      final localTime = DateTime(2026, 1, 1, 12, 0, 0);
      final cloudTime = localTime.add(const Duration(seconds: 5));
      expect(
        resolveAccountSync(
          userId: 'abc',
          lastSyncedUid: 'abc',
          cloudRowExists: true,
          cloudUpdatedAt: cloudTime,
          localUpdatedAt: localTime,
        ),
        SyncDecision.pullCloudToLocal,
      );
    });

    test('delta of 1 second is a noop', () {
      final cloudTime = DateTime(2026, 1, 1, 12, 0, 0);
      final localTime = cloudTime.add(const Duration(seconds: 1));
      expect(
        resolveAccountSync(
          userId: 'abc',
          lastSyncedUid: 'abc',
          cloudRowExists: true,
          cloudUpdatedAt: cloudTime,
          localUpdatedAt: localTime,
        ),
        SyncDecision.noop,
      );
    });

    test('local updatedAt 10 minutes after cloud pushes local to cloud', () {
      final cloudTime = DateTime(2026, 1, 1, 12, 0, 0);
      final localTime = cloudTime.add(const Duration(minutes: 10));
      expect(
        resolveAccountSync(
          userId: 'abc',
          lastSyncedUid: 'abc',
          cloudRowExists: true,
          cloudUpdatedAt: cloudTime,
          localUpdatedAt: localTime,
        ),
        SyncDecision.pushLocalToCloud,
      );
    });

    test('local updatedAt 10 minutes before cloud pulls cloud to local', () {
      final localTime = DateTime(2026, 1, 1, 12, 0, 0);
      final cloudTime = localTime.add(const Duration(minutes: 10));
      expect(
        resolveAccountSync(
          userId: 'abc',
          lastSyncedUid: 'abc',
          cloudRowExists: true,
          cloudUpdatedAt: cloudTime,
          localUpdatedAt: localTime,
        ),
        SyncDecision.pullCloudToLocal,
      );
    });
  });
}
