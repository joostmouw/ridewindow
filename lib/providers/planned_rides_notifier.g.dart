// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_rides_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlannedRidesNotifier)
final plannedRidesProvider = PlannedRidesNotifierProvider._();

final class PlannedRidesNotifierProvider
    extends $NotifierProvider<PlannedRidesNotifier, List<PlannedRide>> {
  PlannedRidesNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'plannedRidesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$plannedRidesNotifierHash();

  @$internal
  @override
  PlannedRidesNotifier create() => PlannedRidesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PlannedRide> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PlannedRide>>(value),
    );
  }
}

String _$plannedRidesNotifierHash() =>
    r'455b713d9c4c24e740f6d76eac8d7b72c3b49220';

abstract class _$PlannedRidesNotifier extends $Notifier<List<PlannedRide>> {
  List<PlannedRide> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<PlannedRide>, List<PlannedRide>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<PlannedRide>, List<PlannedRide>>,
        List<PlannedRide>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
