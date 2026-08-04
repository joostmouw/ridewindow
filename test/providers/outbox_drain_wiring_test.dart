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
import 'dart:io';

import 'package:test/test.dart';

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

void main() {
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
}
