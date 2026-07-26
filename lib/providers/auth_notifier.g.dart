// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Streamt de ingelogde Supabase-gebruiker.
///
/// `keepAlive: true` omdat elke latere provider die reageert op in-/uitloggen
/// (Fase 20's repositories) hierop leunt en nooit mag disposen tussen
/// listener-drops door.
///
/// Twee Supabase-valkuilen (ARCHITECTURE.md §1) waar deze implementatie
/// expliciet omheen bouwt:
/// 1. `onAuthStateChange` herhaalt géén synchrone beginwaarde zoals
///    Firebase's `authStateChanges()` dat wel doet — de herstelde sessie is
///    direct na `Supabase.initialize()` synchroon beschikbaar via
///    `currentSession`. Zonder deze seed toont een koude start één frame
///    lang "uitgelogd" (AUTH-04 zou dan flaky zijn, niet waar).
/// 2. `User.id` is een Supabase-UUID, geen Google-account-id. AUTH-07's
///    Calendar-mismatch-vergelijking (Plan 19-05) moet `.email` gebruiken,
///    niet dit id.

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// Streamt de ingelogde Supabase-gebruiker.
///
/// `keepAlive: true` omdat elke latere provider die reageert op in-/uitloggen
/// (Fase 20's repositories) hierop leunt en nooit mag disposen tussen
/// listener-drops door.
///
/// Twee Supabase-valkuilen (ARCHITECTURE.md §1) waar deze implementatie
/// expliciet omheen bouwt:
/// 1. `onAuthStateChange` herhaalt géén synchrone beginwaarde zoals
///    Firebase's `authStateChanges()` dat wel doet — de herstelde sessie is
///    direct na `Supabase.initialize()` synchroon beschikbaar via
///    `currentSession`. Zonder deze seed toont een koude start één frame
///    lang "uitgelogd" (AUTH-04 zou dan flaky zijn, niet waar).
/// 2. `User.id` is een Supabase-UUID, geen Google-account-id. AUTH-07's
///    Calendar-mismatch-vergelijking (Plan 19-05) moet `.email` gebruiken,
///    niet dit id.

final class AuthStateProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  /// Streamt de ingelogde Supabase-gebruiker.
  ///
  /// `keepAlive: true` omdat elke latere provider die reageert op in-/uitloggen
  /// (Fase 20's repositories) hierop leunt en nooit mag disposen tussen
  /// listener-drops door.
  ///
  /// Twee Supabase-valkuilen (ARCHITECTURE.md §1) waar deze implementatie
  /// expliciet omheen bouwt:
  /// 1. `onAuthStateChange` herhaalt géén synchrone beginwaarde zoals
  ///    Firebase's `authStateChanges()` dat wel doet — de herstelde sessie is
  ///    direct na `Supabase.initialize()` synchroon beschikbaar via
  ///    `currentSession`. Zonder deze seed toont een koude start één frame
  ///    lang "uitgelogd" (AUTH-04 zou dan flaky zijn, niet waar).
  /// 2. `User.id` is een Supabase-UUID, geen Google-account-id. AUTH-07's
  ///    Calendar-mismatch-vergelijking (Plan 19-05) moet `.email` gebruiken,
  ///    niet dit id.
  AuthStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authStateProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'15824bf69fe8284fba790188c23e95b33b46d254';

/// Afgeleide waarde voor callsites die alleen het id nodig hebben.
/// Retourneert null tijdens het laden en wanneer uitgelogd.
///
/// Let op: dit is de Supabase-UUID (`auth.users.id`), niet het Google-
/// account-id -- zie de waarschuwing hierboven bij [authState].

@ProviderFor(currentUserId)
final currentUserIdProvider = CurrentUserIdProvider._();

/// Afgeleide waarde voor callsites die alleen het id nodig hebben.
/// Retourneert null tijdens het laden en wanneer uitgelogd.
///
/// Let op: dit is de Supabase-UUID (`auth.users.id`), niet het Google-
/// account-id -- zie de waarschuwing hierboven bij [authState].

final class CurrentUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Afgeleide waarde voor callsites die alleen het id nodig hebben.
  /// Retourneert null tijdens het laden en wanneer uitgelogd.
  ///
  /// Let op: dit is de Supabase-UUID (`auth.users.id`), niet het Google-
  /// account-id -- zie de waarschuwing hierboven bij [authState].
  CurrentUserIdProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentUserIdProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentUserIdHash() => r'7d253e62d8f4143b1acd7a0d3eb39aad8cd54352';
