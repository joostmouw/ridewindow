// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peloton_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// De poort naar de Peloton-tabellen. Eigen provider zodat een test hem kan
/// overriden met een fake — dezelfde naad als `syncOutboxServiceProvider`.

@ProviderFor(pelotonGateway)
final pelotonGatewayProvider = PelotonGatewayProvider._();

/// De poort naar de Peloton-tabellen. Eigen provider zodat een test hem kan
/// overriden met een fake — dezelfde naad als `syncOutboxServiceProvider`.

final class PelotonGatewayProvider
    extends $FunctionalProvider<PelotonGateway, PelotonGateway, PelotonGateway>
    with $Provider<PelotonGateway> {
  /// De poort naar de Peloton-tabellen. Eigen provider zodat een test hem kan
  /// overriden met een fake — dezelfde naad als `syncOutboxServiceProvider`.
  PelotonGatewayProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pelotonGatewayProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pelotonGatewayHash();

  @$internal
  @override
  $ProviderElement<PelotonGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PelotonGateway create(Ref ref) {
    return pelotonGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PelotonGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PelotonGateway>(value),
    );
  }
}

String _$pelotonGatewayHash() => r'f0038b2082225c6500bd464180f38b1d1e73151b';

/// Je maatjes. Leeg (en niet fout) als je uitgelogd bent: Peloton is additief,
/// een uitgelogde gebruiker merkt van het hele epic niets — dat is dezelfde
/// eis als REQUIREMENTS.md regel 8 voor accounts zelf.

@ProviderFor(friends)
final friendsProvider = FriendsProvider._();

/// Je maatjes. Leeg (en niet fout) als je uitgelogd bent: Peloton is additief,
/// een uitgelogde gebruiker merkt van het hele epic niets — dat is dezelfde
/// eis als REQUIREMENTS.md regel 8 voor accounts zelf.

final class FriendsProvider extends $FunctionalProvider<
        AsyncValue<List<Friend>>, List<Friend>, FutureOr<List<Friend>>>
    with $FutureModifier<List<Friend>>, $FutureProvider<List<Friend>> {
  /// Je maatjes. Leeg (en niet fout) als je uitgelogd bent: Peloton is additief,
  /// een uitgelogde gebruiker merkt van het hele epic niets — dat is dezelfde
  /// eis als REQUIREMENTS.md regel 8 voor accounts zelf.
  FriendsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'friendsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$friendsHash();

  @$internal
  @override
  $FutureProviderElement<List<Friend>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Friend>> create(Ref ref) {
    return friends(ref);
  }
}

String _$friendsHash() => r'09f1314e18c748984a008bc8ee6c6ef6ecff6655';

/// Alle gedeelde ritten die je mag zien. Welke dat zijn bepaalt RLS, niet deze
/// code — de query vraagt bewust alles op.

@ProviderFor(groupRides)
final groupRidesProvider = GroupRidesProvider._();

/// Alle gedeelde ritten die je mag zien. Welke dat zijn bepaalt RLS, niet deze
/// code — de query vraagt bewust alles op.

final class GroupRidesProvider extends $FunctionalProvider<
        AsyncValue<List<GroupRide>>, List<GroupRide>, FutureOr<List<GroupRide>>>
    with $FutureModifier<List<GroupRide>>, $FutureProvider<List<GroupRide>> {
  /// Alle gedeelde ritten die je mag zien. Welke dat zijn bepaalt RLS, niet deze
  /// code — de query vraagt bewust alles op.
  GroupRidesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'groupRidesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$groupRidesHash();

  @$internal
  @override
  $FutureProviderElement<List<GroupRide>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupRide>> create(Ref ref) {
    return groupRides(ref);
  }
}

String _$groupRidesHash() => r'7189bfe90716c5387435e56d79ac55aa40d52cf9';

/// Ritten waarvoor jij bent uitgenodigd en nog niet hebt geantwoord.
///
/// Afgeleid in plaats van apart opgehaald: één bron van waarheid, en het
/// scheelt een tweede netwerkrondgang die toch dezelfde rijen zou leveren.

@ProviderFor(pendingRideInvites)
final pendingRideInvitesProvider = PendingRideInvitesProvider._();

/// Ritten waarvoor jij bent uitgenodigd en nog niet hebt geantwoord.
///
/// Afgeleid in plaats van apart opgehaald: één bron van waarheid, en het
/// scheelt een tweede netwerkrondgang die toch dezelfde rijen zou leveren.

final class PendingRideInvitesProvider extends $FunctionalProvider<
        AsyncValue<List<GroupRide>>, List<GroupRide>, FutureOr<List<GroupRide>>>
    with $FutureModifier<List<GroupRide>>, $FutureProvider<List<GroupRide>> {
  /// Ritten waarvoor jij bent uitgenodigd en nog niet hebt geantwoord.
  ///
  /// Afgeleid in plaats van apart opgehaald: één bron van waarheid, en het
  /// scheelt een tweede netwerkrondgang die toch dezelfde rijen zou leveren.
  PendingRideInvitesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pendingRideInvitesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pendingRideInvitesHash();

  @$internal
  @override
  $FutureProviderElement<List<GroupRide>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupRide>> create(Ref ref) {
    return pendingRideInvites(ref);
  }
}

String _$pendingRideInvitesHash() =>
    r'a7c269166923f1d0060fa9dcba85c8f97eb29d90';

/// Gedeelde ritten die jij organiseert.

@ProviderFor(ownedGroupRides)
final ownedGroupRidesProvider = OwnedGroupRidesProvider._();

/// Gedeelde ritten die jij organiseert.

final class OwnedGroupRidesProvider extends $FunctionalProvider<
        AsyncValue<List<GroupRide>>, List<GroupRide>, FutureOr<List<GroupRide>>>
    with $FutureModifier<List<GroupRide>>, $FutureProvider<List<GroupRide>> {
  /// Gedeelde ritten die jij organiseert.
  OwnedGroupRidesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ownedGroupRidesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ownedGroupRidesHash();

  @$internal
  @override
  $FutureProviderElement<List<GroupRide>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupRide>> create(Ref ref) {
    return ownedGroupRides(ref);
  }
}

String _$ownedGroupRidesHash() => r'41f4a83f7586b8120831c75e1425a1b212e648bd';
