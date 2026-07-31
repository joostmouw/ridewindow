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

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

/// Construeert de [ProfileRepository]. Gebruikt bewust `getInstance()`
/// (asynchroon), niet `sharedPrefsProvider` -- die gooit `UnimplementedError`
/// tenzij overschreven, en de bestaande profiel-tests leunen allemaal op
/// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.

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

String _$profileRepositoryHash() => r'71a0d60c85bf0437b8ab30e03e5988fb34505800';

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

String _$profileNotifierHash() => r'ed8493d620cace731621a7f4fe898b0768c87353';

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
