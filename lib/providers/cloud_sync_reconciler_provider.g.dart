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
