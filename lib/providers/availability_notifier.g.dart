// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Construeert de [AvailabilityRepository]. Gebruikt bewust `getInstance()`
/// (asynchroon), niet `sharedPrefsProvider` — die gooit `UnimplementedError`
/// tenzij overschreven, en de bestaande availability-tests leunen allemaal op
/// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.
///
/// `outbox`/`userId` zijn additief (ARCHITECTURE.md §4a): signed-out
/// (`userId == null`) construeert nog steeds een repository, alleen een
/// waarvan de outbox-schrijvingen no-ops zijn per
/// [AvailabilityRepository]'s eigen guard.

@ProviderFor(availabilityRepository)
final availabilityRepositoryProvider = AvailabilityRepositoryProvider._();

/// Construeert de [AvailabilityRepository]. Gebruikt bewust `getInstance()`
/// (asynchroon), niet `sharedPrefsProvider` — die gooit `UnimplementedError`
/// tenzij overschreven, en de bestaande availability-tests leunen allemaal op
/// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.
///
/// `outbox`/`userId` zijn additief (ARCHITECTURE.md §4a): signed-out
/// (`userId == null`) construeert nog steeds een repository, alleen een
/// waarvan de outbox-schrijvingen no-ops zijn per
/// [AvailabilityRepository]'s eigen guard.

final class AvailabilityRepositoryProvider extends $FunctionalProvider<
        AsyncValue<AvailabilityRepository>,
        AvailabilityRepository,
        FutureOr<AvailabilityRepository>>
    with
        $FutureModifier<AvailabilityRepository>,
        $FutureProvider<AvailabilityRepository> {
  /// Construeert de [AvailabilityRepository]. Gebruikt bewust `getInstance()`
  /// (asynchroon), niet `sharedPrefsProvider` — die gooit `UnimplementedError`
  /// tenzij overschreven, en de bestaande availability-tests leunen allemaal op
  /// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.
  ///
  /// `outbox`/`userId` zijn additief (ARCHITECTURE.md §4a): signed-out
  /// (`userId == null`) construeert nog steeds een repository, alleen een
  /// waarvan de outbox-schrijvingen no-ops zijn per
  /// [AvailabilityRepository]'s eigen guard.
  AvailabilityRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'availabilityRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$availabilityRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<AvailabilityRepository> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AvailabilityRepository> create(Ref ref) {
    return availabilityRepository(ref);
  }
}

String _$availabilityRepositoryHash() =>
    r'4ed60c31efbb0ddb274b46a9aba1ebe4038379c8';

/// AvailabilityNotifier beheert de geblokkeerde uren als `Map<DateTime, BlockType>`.
///
/// Persistentie loopt via [AvailabilityRepository]. Deze notifier is een
/// dunne laag: hij houdt de publieke API en de mutatie-logica, de repository
/// is de enige plek die het opslagformaat kent.
///
/// Volledig context-loos en testbaar via ProviderContainer.

@ProviderFor(AvailabilityNotifier)
final availabilityProvider = AvailabilityNotifierProvider._();

/// AvailabilityNotifier beheert de geblokkeerde uren als `Map<DateTime, BlockType>`.
///
/// Persistentie loopt via [AvailabilityRepository]. Deze notifier is een
/// dunne laag: hij houdt de publieke API en de mutatie-logica, de repository
/// is de enige plek die het opslagformaat kent.
///
/// Volledig context-loos en testbaar via ProviderContainer.
final class AvailabilityNotifierProvider extends $AsyncNotifierProvider<
    AvailabilityNotifier, Map<DateTime, BlockType>> {
  /// AvailabilityNotifier beheert de geblokkeerde uren als `Map<DateTime, BlockType>`.
  ///
  /// Persistentie loopt via [AvailabilityRepository]. Deze notifier is een
  /// dunne laag: hij houdt de publieke API en de mutatie-logica, de repository
  /// is de enige plek die het opslagformaat kent.
  ///
  /// Volledig context-loos en testbaar via ProviderContainer.
  AvailabilityNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'availabilityProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$availabilityNotifierHash();

  @$internal
  @override
  AvailabilityNotifier create() => AvailabilityNotifier();
}

String _$availabilityNotifierHash() =>
    r'f95c802298f2f0b46891b6ae154888e827465167';

/// AvailabilityNotifier beheert de geblokkeerde uren als `Map<DateTime, BlockType>`.
///
/// Persistentie loopt via [AvailabilityRepository]. Deze notifier is een
/// dunne laag: hij houdt de publieke API en de mutatie-logica, de repository
/// is de enige plek die het opslagformaat kent.
///
/// Volledig context-loos en testbaar via ProviderContainer.

abstract class _$AvailabilityNotifier
    extends $AsyncNotifier<Map<DateTime, BlockType>> {
  FutureOr<Map<DateTime, BlockType>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<Map<DateTime, BlockType>>, Map<DateTime, BlockType>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<Map<DateTime, BlockType>>,
            Map<DateTime, BlockType>>,
        AsyncValue<Map<DateTime, BlockType>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
