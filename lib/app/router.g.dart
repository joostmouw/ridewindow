// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// GoRouter met onboarding-redirect en vier Phase 4 routes.
///
/// Redirect: controleert SharedPreferences 'onboarding_complete'.
/// false of afwezig → /welcome; true → geen redirect.

@ProviderFor(router)
final routerProvider = RouterProvider._();

/// GoRouter met onboarding-redirect en vier Phase 4 routes.
///
/// Redirect: controleert SharedPreferences 'onboarding_complete'.
/// false of afwezig → /welcome; true → geen redirect.

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// GoRouter met onboarding-redirect en vier Phase 4 routes.
  ///
  /// Redirect: controleert SharedPreferences 'onboarding_complete'.
  /// false of afwezig → /welcome; true → geen redirect.
  RouterProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'routerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'f5217a63c40983a9e8d8221f3eb7ba591922356b';
