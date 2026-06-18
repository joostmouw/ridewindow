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
          isAutoDispose: true,
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
    r'3e422b4a164cc8146003bfd7dba3c609f6bce722';

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
