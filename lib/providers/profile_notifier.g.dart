// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Construeert de [ProfileRepository]. Gebruikt bewust `getInstance()`
/// (asynchroon), niet `sharedPrefsProvider` -- die gooit `UnimplementedError`
/// tenzij overschreven, en de bestaande profiel-tests leunen allemaal op
/// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.
///
/// `outbox`/`userId` zijn additief (ARCHITECTURE.md §4a): signed-out
/// (`userId == null`) construeert nog steeds een repository, alleen een
/// waarvan de outbox-schrijvingen no-ops zijn per
/// [ProfileRepository]'s eigen guard.

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

/// Construeert de [ProfileRepository]. Gebruikt bewust `getInstance()`
/// (asynchroon), niet `sharedPrefsProvider` -- die gooit `UnimplementedError`
/// tenzij overschreven, en de bestaande profiel-tests leunen allemaal op
/// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.
///
/// `outbox`/`userId` zijn additief (ARCHITECTURE.md §4a): signed-out
/// (`userId == null`) construeert nog steeds een repository, alleen een
/// waarvan de outbox-schrijvingen no-ops zijn per
/// [ProfileRepository]'s eigen guard.

final class ProfileRepositoryProvider extends $FunctionalProvider<
        AsyncValue<ProfileRepository>,
        ProfileRepository,
        FutureOr<ProfileRepository>>
    with
        $FutureModifier<ProfileRepository>,
        $FutureProvider<ProfileRepository> {
  /// Construeert de [ProfileRepository]. Gebruikt bewust `getInstance()`
  /// (asynchroon), niet `sharedPrefsProvider` -- die gooit `UnimplementedError`
  /// tenzij overschreven, en de bestaande profiel-tests leunen allemaal op
  /// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.
  ///
  /// `outbox`/`userId` zijn additief (ARCHITECTURE.md §4a): signed-out
  /// (`userId == null`) construeert nog steeds een repository, alleen een
  /// waarvan de outbox-schrijvingen no-ops zijn per
  /// [ProfileRepository]'s eigen guard.
  ProfileRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'profileRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<ProfileRepository> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ProfileRepository> create(Ref ref) {
    return profileRepository(ref);
  }
}

String _$profileRepositoryHash() => r'8003869af3940609163f725dd56ff8232d538fb6';

/// ProfileNotifier laadt alle scalaire gebruikersinstellingen uit SharedPreferences
/// op cold start en schrijft iedere update direct terug.
///
/// Persistentie loopt via [ProfileRepository]. Deze notifier is een dunne
/// laag: hij houdt de publieke API en de mutatie-logica, de repository is de
/// enige plek die het opslagformaat kent.
///
/// Iedere mutatiemethode: (1) leest de huidige state, (2) bouwt nieuw
/// UserProfile via copyWith, (3) schrijft via de repository, (4) zet
/// state = AsyncData(next).
///
/// Volledig context-loos en testbaar via ProviderContainer.

@ProviderFor(ProfileNotifier)
final profileProvider = ProfileNotifierProvider._();

/// ProfileNotifier laadt alle scalaire gebruikersinstellingen uit SharedPreferences
/// op cold start en schrijft iedere update direct terug.
///
/// Persistentie loopt via [ProfileRepository]. Deze notifier is een dunne
/// laag: hij houdt de publieke API en de mutatie-logica, de repository is de
/// enige plek die het opslagformaat kent.
///
/// Iedere mutatiemethode: (1) leest de huidige state, (2) bouwt nieuw
/// UserProfile via copyWith, (3) schrijft via de repository, (4) zet
/// state = AsyncData(next).
///
/// Volledig context-loos en testbaar via ProviderContainer.
final class ProfileNotifierProvider
    extends $AsyncNotifierProvider<ProfileNotifier, UserProfile> {
  /// ProfileNotifier laadt alle scalaire gebruikersinstellingen uit SharedPreferences
  /// op cold start en schrijft iedere update direct terug.
  ///
  /// Persistentie loopt via [ProfileRepository]. Deze notifier is een dunne
  /// laag: hij houdt de publieke API en de mutatie-logica, de repository is de
  /// enige plek die het opslagformaat kent.
  ///
  /// Iedere mutatiemethode: (1) leest de huidige state, (2) bouwt nieuw
  /// UserProfile via copyWith, (3) schrijft via de repository, (4) zet
  /// state = AsyncData(next).
  ///
  /// Volledig context-loos en testbaar via ProviderContainer.
  ProfileNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'profileProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$profileNotifierHash();

  @$internal
  @override
  ProfileNotifier create() => ProfileNotifier();
}

String _$profileNotifierHash() => r'7333f0e465828f0b1497fda0cc0daff1c6c72e1e';

/// ProfileNotifier laadt alle scalaire gebruikersinstellingen uit SharedPreferences
/// op cold start en schrijft iedere update direct terug.
///
/// Persistentie loopt via [ProfileRepository]. Deze notifier is een dunne
/// laag: hij houdt de publieke API en de mutatie-logica, de repository is de
/// enige plek die het opslagformaat kent.
///
/// Iedere mutatiemethode: (1) leest de huidige state, (2) bouwt nieuw
/// UserProfile via copyWith, (3) schrijft via de repository, (4) zet
/// state = AsyncData(next).
///
/// Volledig context-loos en testbaar via ProviderContainer.

abstract class _$ProfileNotifier extends $AsyncNotifier<UserProfile> {
  FutureOr<UserProfile> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserProfile>, UserProfile>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<UserProfile>, UserProfile>,
        AsyncValue<UserProfile>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
