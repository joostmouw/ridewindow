// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ProfileNotifier laadt alle scalaire gebruikersinstellingen uit SharedPreferences
/// op cold start en schrijft iedere update direct terug.
///
/// Iedere mutatiemethode: (1) schrijft naar SharedPreferences, (2) bouwt nieuw
/// UserProfile via copyWith, (3) zet state = AsyncData(next).
///
/// Volledig context-loos en testbaar via ProviderContainer.

@ProviderFor(ProfileNotifier)
final profileProvider = ProfileNotifierProvider._();

/// ProfileNotifier laadt alle scalaire gebruikersinstellingen uit SharedPreferences
/// op cold start en schrijft iedere update direct terug.
///
/// Iedere mutatiemethode: (1) schrijft naar SharedPreferences, (2) bouwt nieuw
/// UserProfile via copyWith, (3) zet state = AsyncData(next).
///
/// Volledig context-loos en testbaar via ProviderContainer.
final class ProfileNotifierProvider
    extends $AsyncNotifierProvider<ProfileNotifier, UserProfile> {
  /// ProfileNotifier laadt alle scalaire gebruikersinstellingen uit SharedPreferences
  /// op cold start en schrijft iedere update direct terug.
  ///
  /// Iedere mutatiemethode: (1) schrijft naar SharedPreferences, (2) bouwt nieuw
  /// UserProfile via copyWith, (3) zet state = AsyncData(next).
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

String _$profileNotifierHash() => r'9aa32d6e212c4844409be7ff0aaef1b18cb916c0';

/// ProfileNotifier laadt alle scalaire gebruikersinstellingen uit SharedPreferences
/// op cold start en schrijft iedere update direct terug.
///
/// Iedere mutatiemethode: (1) schrijft naar SharedPreferences, (2) bouwt nieuw
/// UserProfile via copyWith, (3) zet state = AsyncData(next).
///
/// Volledig context-loos en testbaar via ProviderContainer.

abstract class _$ProfileNotifier extends $AsyncNotifier<UserProfile> {
  FutureOr<UserProfile> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserProfile>, UserProfile>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<UserProfile>, UserProfile>,
        AsyncValue<UserProfile>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
