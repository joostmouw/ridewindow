// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_rides_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Construeert de [PlannedRidesRepository]. Gebruikt bewust `getInstance()`
/// (asynchroon), niet de app-brede prefs-provider hieronder — die gooit
/// `UnimplementedError` tenzij overschreven, en de bestaande
/// planned-rides-tests leunen allemaal op
/// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.

@ProviderFor(plannedRidesRepository)
final plannedRidesRepositoryProvider = PlannedRidesRepositoryProvider._();

/// Construeert de [PlannedRidesRepository]. Gebruikt bewust `getInstance()`
/// (asynchroon), niet de app-brede prefs-provider hieronder — die gooit
/// `UnimplementedError` tenzij overschreven, en de bestaande
/// planned-rides-tests leunen allemaal op
/// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.

final class PlannedRidesRepositoryProvider extends $FunctionalProvider<
        AsyncValue<PlannedRidesRepository>,
        PlannedRidesRepository,
        FutureOr<PlannedRidesRepository>>
    with
        $FutureModifier<PlannedRidesRepository>,
        $FutureProvider<PlannedRidesRepository> {
  /// Construeert de [PlannedRidesRepository]. Gebruikt bewust `getInstance()`
  /// (asynchroon), niet de app-brede prefs-provider hieronder — die gooit
  /// `UnimplementedError` tenzij overschreven, en de bestaande
  /// planned-rides-tests leunen allemaal op
  /// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.
  PlannedRidesRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'plannedRidesRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$plannedRidesRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<PlannedRidesRepository> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PlannedRidesRepository> create(Ref ref) {
    return plannedRidesRepository(ref);
  }
}

String _$plannedRidesRepositoryHash() =>
    r'd2d197b9f2cef5111a25a59ea5862f4d687bcaa8';

@ProviderFor(PlannedRidesNotifier)
final plannedRidesProvider = PlannedRidesNotifierProvider._();

final class PlannedRidesNotifierProvider
    extends $AsyncNotifierProvider<PlannedRidesNotifier, List<PlannedRide>> {
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
}

String _$plannedRidesNotifierHash() =>
    r'393e079627c0cf14738806425cfece620da7baad';

abstract class _$PlannedRidesNotifier
    extends $AsyncNotifier<List<PlannedRide>> {
  FutureOr<List<PlannedRide>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PlannedRide>>, List<PlannedRide>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<PlannedRide>>, List<PlannedRide>>,
        AsyncValue<List<PlannedRide>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
