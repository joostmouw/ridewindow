// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_sync_reconciler_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cloudSyncReconciler)
final cloudSyncReconcilerProvider = CloudSyncReconcilerProvider._();

final class CloudSyncReconcilerProvider extends $FunctionalProvider<
    CloudSyncReconciler,
    CloudSyncReconciler,
    CloudSyncReconciler> with $Provider<CloudSyncReconciler> {
  CloudSyncReconcilerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'cloudSyncReconcilerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$cloudSyncReconcilerHash();

  @$internal
  @override
  $ProviderElement<CloudSyncReconciler> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CloudSyncReconciler create(Ref ref) {
    return cloudSyncReconciler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudSyncReconciler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudSyncReconciler>(value),
    );
  }
}

String _$cloudSyncReconcilerHash() =>
    r'eda8ca8ba30905816581f18f019e64e49f08ca32';

/// Emits the current pending-outbox-row count (SYNC-06/D-06/D-07's sync
/// status indicator). Generated as `outboxPendingCountProvider` — watched
/// directly from `AccountSection._buildSignedInRow()` via
/// `ref.watch(outboxPendingCountProvider)`.

@ProviderFor(outboxPendingCount)
final outboxPendingCountProvider = OutboxPendingCountProvider._();

/// Emits the current pending-outbox-row count (SYNC-06/D-06/D-07's sync
/// status indicator). Generated as `outboxPendingCountProvider` — watched
/// directly from `AccountSection._buildSignedInRow()` via
/// `ref.watch(outboxPendingCountProvider)`.

final class OutboxPendingCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Emits the current pending-outbox-row count (SYNC-06/D-06/D-07's sync
  /// status indicator). Generated as `outboxPendingCountProvider` — watched
  /// directly from `AccountSection._buildSignedInRow()` via
  /// `ref.watch(outboxPendingCountProvider)`.
  OutboxPendingCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'outboxPendingCountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$outboxPendingCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return outboxPendingCount(ref);
  }
}

String _$outboxPendingCountHash() =>
    r'0ef1220fd99e466ed372c04e91d55db4d62c30de';

/// Constructs the offline outbox's real production consumer (plan 21-10,
/// SYNC-05/SYNC-06) — `SyncOutboxService` bound to the app's own
/// `SyncOutboxDao`. Deliberately its own provider (rather than being built
/// inline inside `CloudSyncReconciler.drainOutbox()`) so a test can override
/// it with a fake service, matching this file's existing
/// `accountSyncServiceProvider` seam.

@ProviderFor(syncOutboxService)
final syncOutboxServiceProvider = SyncOutboxServiceProvider._();

/// Constructs the offline outbox's real production consumer (plan 21-10,
/// SYNC-05/SYNC-06) — `SyncOutboxService` bound to the app's own
/// `SyncOutboxDao`. Deliberately its own provider (rather than being built
/// inline inside `CloudSyncReconciler.drainOutbox()`) so a test can override
/// it with a fake service, matching this file's existing
/// `accountSyncServiceProvider` seam.

final class SyncOutboxServiceProvider extends $FunctionalProvider<
    SyncOutboxService,
    SyncOutboxService,
    SyncOutboxService> with $Provider<SyncOutboxService> {
  /// Constructs the offline outbox's real production consumer (plan 21-10,
  /// SYNC-05/SYNC-06) — `SyncOutboxService` bound to the app's own
  /// `SyncOutboxDao`. Deliberately its own provider (rather than being built
  /// inline inside `CloudSyncReconciler.drainOutbox()`) so a test can override
  /// it with a fake service, matching this file's existing
  /// `accountSyncServiceProvider` seam.
  SyncOutboxServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'syncOutboxServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$syncOutboxServiceHash();

  @$internal
  @override
  $ProviderElement<SyncOutboxService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncOutboxService create(Ref ref) {
    return syncOutboxService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncOutboxService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncOutboxService>(value),
    );
  }
}

String _$syncOutboxServiceHash() => r'131ce74676d267d936ba01523a88dd729ab8ba2d';

/// Constructs the real [AccountSyncService] (plan 21-06) with production
/// dependencies (plan 21-07): the three repositories, the two cloud-read
/// closures composed from `CloudReconcileService`'s pure row parsers plus
/// the actual `.from(...).select()...` network calls, the
/// `migrate_account_data` RPC closure, and the `account.lastSyncedUid`
/// writer. `AccountSection._runAccountSync()` reads this via `.future`
/// rather than constructing `AccountSyncService` inline, so widget tests can
/// override it with a fake service instead of needing a live Supabase
/// client (see `test/features/profile_account_section_test.dart`'s
/// `FakeAccountSyncService`).

@ProviderFor(accountSyncService)
final accountSyncServiceProvider = AccountSyncServiceProvider._();

/// Constructs the real [AccountSyncService] (plan 21-06) with production
/// dependencies (plan 21-07): the three repositories, the two cloud-read
/// closures composed from `CloudReconcileService`'s pure row parsers plus
/// the actual `.from(...).select()...` network calls, the
/// `migrate_account_data` RPC closure, and the `account.lastSyncedUid`
/// writer. `AccountSection._runAccountSync()` reads this via `.future`
/// rather than constructing `AccountSyncService` inline, so widget tests can
/// override it with a fake service instead of needing a live Supabase
/// client (see `test/features/profile_account_section_test.dart`'s
/// `FakeAccountSyncService`).

final class AccountSyncServiceProvider extends $FunctionalProvider<
        AsyncValue<AccountSyncService>,
        AccountSyncService,
        FutureOr<AccountSyncService>>
    with
        $FutureModifier<AccountSyncService>,
        $FutureProvider<AccountSyncService> {
  /// Constructs the real [AccountSyncService] (plan 21-06) with production
  /// dependencies (plan 21-07): the three repositories, the two cloud-read
  /// closures composed from `CloudReconcileService`'s pure row parsers plus
  /// the actual `.from(...).select()...` network calls, the
  /// `migrate_account_data` RPC closure, and the `account.lastSyncedUid`
  /// writer. `AccountSection._runAccountSync()` reads this via `.future`
  /// rather than constructing `AccountSyncService` inline, so widget tests can
  /// override it with a fake service instead of needing a live Supabase
  /// client (see `test/features/profile_account_section_test.dart`'s
  /// `FakeAccountSyncService`).
  AccountSyncServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'accountSyncServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$accountSyncServiceHash();

  @$internal
  @override
  $FutureProviderElement<AccountSyncService> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AccountSyncService> create(Ref ref) {
    return accountSyncService(ref);
  }
}

String _$accountSyncServiceHash() =>
    r'8db802f05a84dca8db39a1f2327c610e342d29d4';
