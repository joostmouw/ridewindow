// Regression test for the SYNC-05 gap found on a real device on 2026-08-04
// (see .planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md,
// "Device session" section, "SYNC-05 -- outbox drain: FAIL"): every unit
// test in test/services/sync_outbox_service_test.dart passed, and yet
// `SyncOutboxService` was never constructed anywhere in lib/ and `drain()`
// was never called in production code -- the offline outbox was write-only.
// drain()'s own tests only prove the function behaves correctly *given* a
// call; they never asserted that a call site exists. That is the exact
// asymmetry that let this defect ship across plans 21-03 through 21-09
// (each one deferred the wiring to "the next plan", and none of them ever
// did it -- see this file's plan, 21-10-PLAN.md, <context> section).
//
// A behavioural ProviderContainer test (drive reconcileOnForeground() with a
// fake send closure and assert it was invoked) was considered first, per
// this plan's Task 2 note. It was rejected: the real production wiring
// (CloudSyncReconciler.drainOutbox(), lib/providers/
// cloud_sync_reconciler_provider.dart) composes its upsertFn/deleteFn
// closures directly against `Supabase.instance.client` inside the method
// body, rather than accepting them as injectable constructor arguments --
// exercising that behaviourally would require a live or heavily mocked
// SupabaseClient, exactly the "heavy SupabaseClient mocking" case this
// plan's Task 2 note calls out as the trigger for falling back to a
// source-level structural assertion instead. This test follows the same
// style as test/structure/background_task_no_supabase_test.dart: it scans
// lib/ source text directly rather than executing it.
//
// Plan 21-11 adds a second layer below the structural scan above: 21-10's
// own wiring exists (the scan proves it) but never actually *runs*, because
// `cloudSyncReconciler`/`syncOutboxService` are bare `@riverpod` (Riverpod 3
// makes autoDispose the default) and both call sites use a bare `ref.read`
// that establishes no listener. The provider is disposed shortly after the
// read completes, and the async body then touches the now-dead `Ref` across
// an `await` boundary, throwing "Cannot use the Ref of
// cloudSyncReconcilerProvider after it has been disposed." -- silently
// swallowed by this class's own try/catch, so the drain never runs and the
// account row sits on "Syncing..." forever. The tests below drive the real
// providers through a `ProviderContainer` with a bare `container.read` --
// exactly mirroring `home_screen.dart`/`account_section.dart`'s own
// `ref.read` usage -- and force a real event-loop turn between the read and
// the later `Ref` access (matching the real-world gap that genuine network
// I/O produces on a device) so the autoDispose scheduler's `Timer.zero`
// actually fires before that later access, the same way it does in
// production.
import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/cloud_sync_reconciler_provider.dart';
import 'package:ridewindow/services/sync_outbox_service.dart';

/// The one file allowed to define `SyncOutboxService` / `drain()` without
/// counting as "a real caller" -- its own class body obviously contains both
/// the class name and the method name.
const _definingFile = 'lib/services/sync_outbox_service.dart';

/// Strips `//`/`///` line comments and `/* ... */` block comments before the
/// substring/regex scan below. Without this, `cloud_sync_reconciler_provider
/// .dart`'s own doc comments -- which describe `drain()` in prose right next
/// to the real call site -- would satisfy the regex on their own, and this
/// test would keep "passing" even if the real call site were deleted. A
/// naive line-based `//` cut (after removing `/* */` spans first) is
/// intentionally simple, matching this repo's existing structural-test style
/// (background_task_no_supabase_test.dart also does a plain line-prefix
/// check rather than a real Dart parse) -- exact enough for this file's own
/// coding style, where no `//` appears inside a string literal on a line
/// that also contains `SyncOutboxService(` or a `drain(` call.
String _stripComments(String source) {
  final withoutBlockComments =
      source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  final lines = withoutBlockComments.split('\n');
  return lines.map((line) {
    final index = line.indexOf('//');
    return index == -1 ? line : line.substring(0, index);
  }).join('\n');
}

/// Records whether [drain] was actually invoked, without doing any real
/// work -- the fake is injected via `syncOutboxServiceProvider`'s override
/// seam (see that provider's doc comment), matching this file's existing
/// `FakeAccountSyncService`-style pattern used elsewhere in this codebase
/// (`test/features/profile_account_section_test.dart`). The superclass
/// constructor needs a real `SyncOutboxDao`, but it is never touched --
/// `drain()` is fully overridden below, so an in-memory database is enough
/// to satisfy the constructor without meaning anything functionally.
class _RecordingSyncOutboxService extends SyncOutboxService {
  _RecordingSyncOutboxService(super.dao);

  bool drainCalled = false;

  @override
  Future<void> drain({
    required Future<void> Function(
      String entity,
      String entityKey,
      Map<String, dynamic> payload,
    ) upsertFn,
    required Future<void> Function(String entity, String entityKey) deleteFn,
  }) async {
    drainCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'SyncOutboxService is constructed and drain() has a real caller in lib/ '
    '(SYNC-05, SYNC-06)',
    () {
      final libDir = Directory('lib');
      expect(
        libDir.existsSync(),
        isTrue,
        reason: 'lib/ must exist and be reachable from the test working '
            'directory for this structural scan to mean anything.',
      );

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      var hasConstructionSite = false;
      var hasDrainCallSite = false;
      final constructionSites = <String>[];
      final drainCallSites = <String>[];

      for (final file in dartFiles) {
        // Normalize Windows-style separators so the definingFile comparison
        // below is platform-independent, matching
        // background_task_no_supabase_test.dart's own path handling.
        final normalizedPath = file.path.replaceAll('\\', '/');
        if (normalizedPath == _definingFile) continue;

        final source = _stripComments(file.readAsStringSync());

        if (source.contains('SyncOutboxService(')) {
          hasConstructionSite = true;
          constructionSites.add(normalizedPath);
        }

        // Matches a `drain(` call (word-boundary-guarded so it never matches
        // an unrelated identifier ending in "drain", e.g. `redrain(`).
        if (RegExp(r'\bdrain\(').hasMatch(source)) {
          hasDrainCallSite = true;
          drainCallSites.add(normalizedPath);
        }
      }

      expect(
        hasConstructionSite,
        isTrue,
        reason:
            'SyncOutboxService must be constructed somewhere in lib/ outside '
            'of $_definingFile -- the outbox needs a real production '
            'consumer, not only its own class definition. Found '
            'construction sites: $constructionSites',
      );
      expect(
        hasDrainCallSite,
        isTrue,
        reason: 'drain() must have a real caller somewhere in lib/ outside '
            'of $_definingFile -- otherwise queued rows are write-only and '
            'never reach the cloud (this is exactly the defect described at '
            'the top of this file). Found drain() call sites: '
            '$drainCallSites',
      );
    },
  );

  group('Behavioural wiring (21-11): the call reaches its work, not just '
      'that a call site exists', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'drainOutbox() reaches SyncOutboxService.drain() via a bare '
      'container.read(cloudSyncReconcilerProvider), exactly as '
      'home_screen.dart and account_section.dart call it -- no listener '
      'held on cloudSyncReconcilerProvider',
      () async {
        final fakeService = _RecordingSyncOutboxService(db.syncOutboxDao);

        final container = ProviderContainer(
          overrides: [
            syncOutboxServiceProvider.overrideWith((ref) => fakeService),
          ],
        );
        addTearDown(container.dispose);

        // Bare read -- no container.listen, no keepAlive here. This is the
        // exact call shape of `ref.read(cloudSyncReconcilerProvider)` in
        // both production call sites.
        final reconciler = container.read(cloudSyncReconcilerProvider);

        // Let the autoDispose scheduler's Timer(Duration.zero) actually run
        // between the read and the later `_ref` access below -- this is the
        // real-world gap that genuine network I/O produces on a device
        // between `ref.read(...)` and the provider's later use of `_ref`.
        // Without this, the whole call chain stays inside one synchronous
        // task and the bug never has a chance to reproduce.
        await Future<void>.delayed(Duration.zero);

        await reconciler.drainOutbox();

        expect(
          fakeService.drainCalled,
          isTrue,
          reason: 'drainOutbox() must reach SyncOutboxService.drain() even '
              'when cloudSyncReconcilerProvider/syncOutboxServiceProvider '
              'were read bare with no listener -- if this is false, the '
              'outbox is write-only again (the exact SYNC-05 regression), '
              'most likely because a disposed Ref silently swallowed the '
              'call (see this file\'s header comment).',
        );
      },
    );

    test(
      'reconcileOnForeground() invoked the same way (bare read, no '
      'listener) never lets a disposed-Ref error reach the caller -- a '
      'signed-out container is enough to prove the Ref survived long '
      'enough to be read at all',
      () async {
        final messages = <String>[];
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) messages.add(message);
        };
        addTearDown(() => debugPrint = originalDebugPrint);

        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
            appDatabaseProvider.overrideWith((ref) => db),
          ],
        );
        addTearDown(container.dispose);

        final reconciler = container.read(cloudSyncReconcilerProvider);

        // Same real event-loop gap as the drainOutbox() test above.
        await Future<void>.delayed(Duration.zero);

        // Must not throw -- reconcileOnForeground() swallows its own
        // errors, so this call always completes normally either way. The
        // real assertion is below: no disposed-Ref message was ever
        // produced internally, not even a swallowed one.
        await reconciler.reconcileOnForeground();

        final disposedRefMessages = messages
            .where((m) => m.contains('disposed'))
            .toList(growable: false);
        expect(
          disposedRefMessages,
          isEmpty,
          reason: 'reconcileOnForeground() must not hit a disposed Ref, not '
              'even one silently swallowed by its own try/catch -- a '
              'swallowed disposed-Ref error is exactly how SYNC-04\'s '
              'foreground cloud read went unnoticed for four plans. '
              'Captured debugPrint output: $messages',
        );
      },
    );

    test(
      'two syncOutboxServiceProvider reads across a real event-loop gap '
      'return the identical instance, so 21-10\'s re-entrancy guard (an '
      'instance field on SyncOutboxService) actually has something to '
      'guard',
      () async {
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => db),
          ],
        );
        addTearDown(container.dispose);

        final first = container.read(syncOutboxServiceProvider);

        // Same real event-loop gap as above -- without it, both reads
        // trivially return the same not-yet-disposed instance and the test
        // proves nothing about keepAlive.
        await Future<void>.delayed(Duration.zero);

        final second = container.read(syncOutboxServiceProvider);

        expect(
          identical(first, second),
          isTrue,
          reason: 'syncOutboxServiceProvider must return the same '
              'SyncOutboxService instance across reads separated by a real '
              'event-loop turn -- otherwise a second concurrent drain() '
              'trigger (foreground firing while a post-sign-in drain is '
              'still in flight) gets its own fresh instance with its own '
              '_inFlightDrain field, and 21-10\'s re-entrancy guard never '
              'engages.',
        );
      },
    );
  });
}
