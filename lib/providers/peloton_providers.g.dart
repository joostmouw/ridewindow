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

/// Gedeelde ritten van iemand anders waar jij ja op hebt gezegd.
///
/// Dit was het gat dat de tweeaccountstest van 2026-09-07 blootlegde: na
/// accepteren viel een rit tussen alle bestaande providers door. Hij is niet
/// meer `invited` (dus weg uit [pendingRideInvites]), hij is niet van jou (dus
/// niet in [ownedGroupRides]), en accepteren maakt met opzet geen rij in
/// `planned_rides` — die blijft strikt persoonlijk. Resultaat: je zei ja en de
/// rit verdween. Deze provider is de ontbrekende derde categorie.
///
/// Alleen `accepted`, niet `declined`: wie heeft afgezegd hoeft de rit niet
/// meer op zijn Home te zien staan.

@ProviderFor(joinedGroupRides)
final joinedGroupRidesProvider = JoinedGroupRidesProvider._();

/// Gedeelde ritten van iemand anders waar jij ja op hebt gezegd.
///
/// Dit was het gat dat de tweeaccountstest van 2026-09-07 blootlegde: na
/// accepteren viel een rit tussen alle bestaande providers door. Hij is niet
/// meer `invited` (dus weg uit [pendingRideInvites]), hij is niet van jou (dus
/// niet in [ownedGroupRides]), en accepteren maakt met opzet geen rij in
/// `planned_rides` — die blijft strikt persoonlijk. Resultaat: je zei ja en de
/// rit verdween. Deze provider is de ontbrekende derde categorie.
///
/// Alleen `accepted`, niet `declined`: wie heeft afgezegd hoeft de rit niet
/// meer op zijn Home te zien staan.

final class JoinedGroupRidesProvider extends $FunctionalProvider<
        AsyncValue<List<GroupRide>>, List<GroupRide>, FutureOr<List<GroupRide>>>
    with $FutureModifier<List<GroupRide>>, $FutureProvider<List<GroupRide>> {
  /// Gedeelde ritten van iemand anders waar jij ja op hebt gezegd.
  ///
  /// Dit was het gat dat de tweeaccountstest van 2026-09-07 blootlegde: na
  /// accepteren viel een rit tussen alle bestaande providers door. Hij is niet
  /// meer `invited` (dus weg uit [pendingRideInvites]), hij is niet van jou (dus
  /// niet in [ownedGroupRides]), en accepteren maakt met opzet geen rij in
  /// `planned_rides` — die blijft strikt persoonlijk. Resultaat: je zei ja en de
  /// rit verdween. Deze provider is de ontbrekende derde categorie.
  ///
  /// Alleen `accepted`, niet `declined`: wie heeft afgezegd hoeft de rit niet
  /// meer op zijn Home te zien staan.
  JoinedGroupRidesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'joinedGroupRidesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$joinedGroupRidesHash();

  @$internal
  @override
  $FutureProviderElement<List<GroupRide>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupRide>> create(Ref ref) {
    return joinedGroupRides(ref);
  }
}

String _$joinedGroupRidesHash() => r'eea3a06a01e52001c403ef901f5923ecfe245e6b';

/// Andermans gedeelde ritten waar jij nee op hebt gezegd.
///
/// **Waarom dit bestaat.** Afzeggen was een deur die één kant op ging: een rit
/// met status `declined` viel uit [pendingRideInvites] (niet meer `invited`),
/// uit [joinedGroupRides] (niet `accepted`) én uit [ownedGroupRides] (niet van
/// jou), en was daarmee nergens meer aan te wijzen -- terwijl de rij gewoon
/// bestaat en RLS een terugweg toestaat. De snackbar met ongedaan-maken uit
/// september dekte de misklik, niet "morgen toch wel" (backlog #66).
///
/// Deze ritten horen bewust níét op Home en niet in de standaardlijst: wie nee
/// zegt, wil er niet aan herinnerd worden. Ze zijn te vinden via het filter
/// "Afgezegd", en daar is de weg terug.

@ProviderFor(declinedGroupRides)
final declinedGroupRidesProvider = DeclinedGroupRidesProvider._();

/// Andermans gedeelde ritten waar jij nee op hebt gezegd.
///
/// **Waarom dit bestaat.** Afzeggen was een deur die één kant op ging: een rit
/// met status `declined` viel uit [pendingRideInvites] (niet meer `invited`),
/// uit [joinedGroupRides] (niet `accepted`) én uit [ownedGroupRides] (niet van
/// jou), en was daarmee nergens meer aan te wijzen -- terwijl de rij gewoon
/// bestaat en RLS een terugweg toestaat. De snackbar met ongedaan-maken uit
/// september dekte de misklik, niet "morgen toch wel" (backlog #66).
///
/// Deze ritten horen bewust níét op Home en niet in de standaardlijst: wie nee
/// zegt, wil er niet aan herinnerd worden. Ze zijn te vinden via het filter
/// "Afgezegd", en daar is de weg terug.

final class DeclinedGroupRidesProvider extends $FunctionalProvider<
        AsyncValue<List<GroupRide>>, List<GroupRide>, FutureOr<List<GroupRide>>>
    with $FutureModifier<List<GroupRide>>, $FutureProvider<List<GroupRide>> {
  /// Andermans gedeelde ritten waar jij nee op hebt gezegd.
  ///
  /// **Waarom dit bestaat.** Afzeggen was een deur die één kant op ging: een rit
  /// met status `declined` viel uit [pendingRideInvites] (niet meer `invited`),
  /// uit [joinedGroupRides] (niet `accepted`) én uit [ownedGroupRides] (niet van
  /// jou), en was daarmee nergens meer aan te wijzen -- terwijl de rij gewoon
  /// bestaat en RLS een terugweg toestaat. De snackbar met ongedaan-maken uit
  /// september dekte de misklik, niet "morgen toch wel" (backlog #66).
  ///
  /// Deze ritten horen bewust níét op Home en niet in de standaardlijst: wie nee
  /// zegt, wil er niet aan herinnerd worden. Ze zijn te vinden via het filter
  /// "Afgezegd", en daar is de weg terug.
  DeclinedGroupRidesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'declinedGroupRidesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$declinedGroupRidesHash();

  @$internal
  @override
  $FutureProviderElement<List<GroupRide>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupRide>> create(Ref ref) {
    return declinedGroupRides(ref);
  }
}

String _$declinedGroupRidesHash() =>
    r'6cd2c714d39367fe525e4e47cee03efb8cb3fc36';

/// Alle groepen die je mag zien: waar je lid bent en waar je aanvraag loopt.
/// Welke dat zijn bepaalt RLS (0012 + 0013), niet deze code. Leeg en zonder
/// gateway-aanroep als je uitgelogd bent: Clubs is additief, net als Peloton.
///
/// Op naam gesorteerd, zonder onderscheid in hoofdletters.

@ProviderFor(visibleGroups)
final visibleGroupsProvider = VisibleGroupsProvider._();

/// Alle groepen die je mag zien: waar je lid bent en waar je aanvraag loopt.
/// Welke dat zijn bepaalt RLS (0012 + 0013), niet deze code. Leeg en zonder
/// gateway-aanroep als je uitgelogd bent: Clubs is additief, net als Peloton.
///
/// Op naam gesorteerd, zonder onderscheid in hoofdletters.

final class VisibleGroupsProvider extends $FunctionalProvider<
        AsyncValue<List<PelotonGroup>>,
        List<PelotonGroup>,
        FutureOr<List<PelotonGroup>>>
    with
        $FutureModifier<List<PelotonGroup>>,
        $FutureProvider<List<PelotonGroup>> {
  /// Alle groepen die je mag zien: waar je lid bent en waar je aanvraag loopt.
  /// Welke dat zijn bepaalt RLS (0012 + 0013), niet deze code. Leeg en zonder
  /// gateway-aanroep als je uitgelogd bent: Clubs is additief, net als Peloton.
  ///
  /// Op naam gesorteerd, zonder onderscheid in hoofdletters.
  VisibleGroupsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'visibleGroupsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$visibleGroupsHash();

  @$internal
  @override
  $FutureProviderElement<List<PelotonGroup>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<PelotonGroup>> create(Ref ref) {
    return visibleGroups(ref);
  }
}

String _$visibleGroupsHash() => r'63c971fb03be7c32ad6882ddb74d336355950649';

/// Groepen waar jij lid van bent (de sectie "Groepen" op de Peloton-tab).

@ProviderFor(myGroups)
final myGroupsProvider = MyGroupsProvider._();

/// Groepen waar jij lid van bent (de sectie "Groepen" op de Peloton-tab).

final class MyGroupsProvider extends $FunctionalProvider<
        AsyncValue<List<PelotonGroup>>,
        List<PelotonGroup>,
        FutureOr<List<PelotonGroup>>>
    with
        $FutureModifier<List<PelotonGroup>>,
        $FutureProvider<List<PelotonGroup>> {
  /// Groepen waar jij lid van bent (de sectie "Groepen" op de Peloton-tab).
  MyGroupsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'myGroupsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$myGroupsHash();

  @$internal
  @override
  $FutureProviderElement<List<PelotonGroup>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<PelotonGroup>> create(Ref ref) {
    return myGroups(ref);
  }
}

String _$myGroupsHash() => r'5c5d25a0c7e5989d188baef22cb21dfec2ccec3b';

/// Groepen waar jouw aanvraag bij de beheerders ligt (0013): via de link of
/// voorgedragen door een lid. Je ziet alleen de naam, geen leden.

@ProviderFor(myPendingGroups)
final myPendingGroupsProvider = MyPendingGroupsProvider._();

/// Groepen waar jouw aanvraag bij de beheerders ligt (0013): via de link of
/// voorgedragen door een lid. Je ziet alleen de naam, geen leden.

final class MyPendingGroupsProvider extends $FunctionalProvider<
        AsyncValue<List<PelotonGroup>>,
        List<PelotonGroup>,
        FutureOr<List<PelotonGroup>>>
    with
        $FutureModifier<List<PelotonGroup>>,
        $FutureProvider<List<PelotonGroup>> {
  /// Groepen waar jouw aanvraag bij de beheerders ligt (0013): via de link of
  /// voorgedragen door een lid. Je ziet alleen de naam, geen leden.
  MyPendingGroupsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'myPendingGroupsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$myPendingGroupsHash();

  @$internal
  @override
  $FutureProviderElement<List<PelotonGroup>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<PelotonGroup>> create(Ref ref) {
    return myPendingGroups(ref);
  }
}

String _$myPendingGroupsHash() => r'3dd6cb6a2907381261fba50df40a4bbfff490f68';

/// Eén groep op id, voor het groepsscherm. Afgeleid uit [visibleGroups], dus
/// geen tweede netwerkronde; null als de groep niet (meer) zichtbaar is.

@ProviderFor(pelotonGroup)
final pelotonGroupProvider = PelotonGroupFamily._();

/// Eén groep op id, voor het groepsscherm. Afgeleid uit [visibleGroups], dus
/// geen tweede netwerkronde; null als de groep niet (meer) zichtbaar is.

final class PelotonGroupProvider extends $FunctionalProvider<
        AsyncValue<PelotonGroup?>, PelotonGroup?, FutureOr<PelotonGroup?>>
    with $FutureModifier<PelotonGroup?>, $FutureProvider<PelotonGroup?> {
  /// Eén groep op id, voor het groepsscherm. Afgeleid uit [visibleGroups], dus
  /// geen tweede netwerkronde; null als de groep niet (meer) zichtbaar is.
  PelotonGroupProvider._(
      {required PelotonGroupFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'pelotonGroupProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pelotonGroupHash();

  @override
  String toString() {
    return r'pelotonGroupProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PelotonGroup?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PelotonGroup?> create(Ref ref) {
    final argument = this.argument as String;
    return pelotonGroup(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PelotonGroupProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pelotonGroupHash() => r'9907119cfe775fbde493e85ee2900cd32259ce52';

/// Eén groep op id, voor het groepsscherm. Afgeleid uit [visibleGroups], dus
/// geen tweede netwerkronde; null als de groep niet (meer) zichtbaar is.

final class PelotonGroupFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PelotonGroup?>, String> {
  PelotonGroupFamily._()
      : super(
          retry: null,
          name: r'pelotonGroupProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Eén groep op id, voor het groepsscherm. Afgeleid uit [visibleGroups], dus
  /// geen tweede netwerkronde; null als de groep niet (meer) zichtbaar is.

  PelotonGroupProvider call(
    String groupId,
  ) =>
      PelotonGroupProvider._(argument: groupId, from: this);

  @override
  String toString() => r'pelotonGroupProvider';
}
