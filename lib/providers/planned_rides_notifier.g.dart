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
///
/// `outbox`/`userId` zijn additief (ARCHITECTURE.md §4a), zelfde patroon als
/// `profileRepositoryProvider`/`availabilityRepositoryProvider` (plan 21-04).

@ProviderFor(plannedRidesRepository)
final plannedRidesRepositoryProvider = PlannedRidesRepositoryProvider._();

/// Construeert de [PlannedRidesRepository]. Gebruikt bewust `getInstance()`
/// (asynchroon), niet de app-brede prefs-provider hieronder — die gooit
/// `UnimplementedError` tenzij overschreven, en de bestaande
/// planned-rides-tests leunen allemaal op
/// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.
///
/// `outbox`/`userId` zijn additief (ARCHITECTURE.md §4a), zelfde patroon als
/// `profileRepositoryProvider`/`availabilityRepositoryProvider` (plan 21-04).

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
  ///
  /// `outbox`/`userId` zijn additief (ARCHITECTURE.md §4a), zelfde patroon als
  /// `profileRepositoryProvider`/`availabilityRepositoryProvider` (plan 21-04).
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
    r'4bd2afd14a87e6e52e463c41b830fb07a8a7dddf';

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
    r'a4007e74da99b658ace25d5ff9746852eeb1ea89';

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
