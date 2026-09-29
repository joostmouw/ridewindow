import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/seen_friends_store.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/services/peloton_gateway.dart';

part 'peloton_providers.g.dart';

/// De poort naar de Peloton-tabellen. Eigen provider zodat een test hem kan
/// overriden met een fake — dezelfde naad als `syncOutboxServiceProvider`.
@Riverpod(keepAlive: true)
PelotonGateway pelotonGateway(Ref ref) => const SupabasePelotonGateway();

/// Je maatjes. Leeg (en niet fout) als je uitgelogd bent: Peloton is additief,
/// een uitgelogde gebruiker merkt van het hele epic niets — dat is dezelfde
/// eis als REQUIREMENTS.md regel 8 voor accounts zelf.
@riverpod
Future<List<Friend>> friends(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(pelotonGatewayProvider).listFriends();
}

/// Alle gedeelde ritten die je mag zien. Welke dat zijn bepaalt RLS, niet deze
/// code — de query vraagt bewust alles op.
@riverpod
Future<List<GroupRide>> groupRides(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(pelotonGatewayProvider).listGroupRides();
}

/// Ritten die op jouw antwoord wachten: losse uitnodigingen (status
/// `invited`) en groepsritten van anderen waarop jij nog geen rij hebt.
///
/// Afgeleid in plaats van apart opgehaald: één bron van waarheid, en het
/// scheelt een tweede netwerkrondgang die toch dezelfde rijen zou leveren.
///
/// **Groepsritten (fase 35).** Op een groepsrit krijgt niet ieder lid een rij;
/// RLS levert alleen groepsritten van groepen waar je nu lid van bent (0012,
/// `is_ride_member`). "Geen rij" betekent daar dus "nog niet geantwoord", en
/// zonder deze tak viel zo'n rit tussen alle providers door -- dezelfde vorm
/// als de fout van 2026-09-07 (zie [joinedGroupRides]).
@riverpod
Future<List<GroupRide>> pendingRideInvites(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final rides = await ref.watch(groupRidesProvider.future);
  return rides
      .where(
        (r) =>
            !r.isOwnedBy(userId) &&
            (r.statusFor(userId) == ParticipantStatus.invited ||
                (r.groupId != null && r.statusFor(userId) == null)),
      )
      .toList();
}

/// Gedeelde ritten die jij organiseert.
@riverpod
Future<List<GroupRide>> ownedGroupRides(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final rides = await ref.watch(groupRidesProvider.future);
  return rides.where((r) => r.isOwnedBy(userId)).toList();
}

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
@riverpod
Future<List<GroupRide>> joinedGroupRides(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final rides = await ref.watch(groupRidesProvider.future);
  return rides
      .where(
        (r) =>
            !r.isOwnedBy(userId) &&
            r.statusFor(userId) == ParticipantStatus.accepted,
      )
      .toList();
}

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
@riverpod
Future<List<GroupRide>> declinedGroupRides(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final rides = await ref.watch(groupRidesProvider.future);
  return rides
      .where(
        (r) =>
            !r.isOwnedBy(userId) &&
            r.statusFor(userId) == ParticipantStatus.declined,
      )
      .toList();
}

// --- Clubs (v4.2), fase 34 ---------------------------------------------------

/// Alle groepen die je mag zien: waar je lid bent en waar je aanvraag loopt.
/// Welke dat zijn bepaalt RLS (0012 + 0013), niet deze code. Leeg en zonder
/// gateway-aanroep als je uitgelogd bent: Clubs is additief, net als Peloton.
///
/// Op naam gesorteerd, zonder onderscheid in hoofdletters.
@riverpod
Future<List<PelotonGroup>> visibleGroups(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final groups = await ref.watch(pelotonGatewayProvider).listGroups();
  return [...groups]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

/// Groepen waar jij lid van bent (de sectie "Groepen" op de Peloton-tab).
@riverpod
Future<List<PelotonGroup>> myGroups(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final groups = await ref.watch(visibleGroupsProvider.future);
  return groups.where((g) => g.isMember(userId)).toList();
}

/// Groepen waar jouw aanvraag bij de beheerders ligt (0013): via de link of
/// voorgedragen door een lid. Je ziet alleen de naam, geen leden.
@riverpod
Future<List<PelotonGroup>> myPendingGroups(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final groups = await ref.watch(visibleGroupsProvider.future);
  return groups.where((g) => g.isPendingFor(userId)).toList();
}

/// Eén groep op id, voor het groepsscherm. Afgeleid uit [visibleGroups], dus
/// geen tweede netwerkronde; null als de groep niet (meer) zichtbaar is.
@riverpod
Future<PelotonGroup?> pelotonGroup(Ref ref, String groupId) async {
  final groups = await ref.watch(visibleGroupsProvider.future);
  for (final g in groups) {
    if (g.id == groupId) return g;
  }
  return null;
}

/// Hoeveel aanvragen er bij jou als beheerder liggen, over al je groepen.
///
/// Dezelfde telling als de chip op de groepskaart ([PelotonGroup.openRequests]),
/// zodat het bolletje en de kaart nooit iets anders zeggen. Een lid dat geen
/// beheerder is ziet via RLS alleen zijn eigen voordrachten; die wachten niet
/// op hem en tellen dus niet.
@riverpod
int openGroupRequestCount(Ref ref) =>
    ref.watch(openGroupRequestIdsProvider).length;

/// De ids achter [openGroupRequestCount].
@riverpod
Set<String> openGroupRequestIds(Ref ref) {
  final me = ref.watch(currentUserIdProvider);
  if (me == null) return const {};
  final groups = ref.watch(myGroupsProvider).value ?? const <PelotonGroup>[];
  return {
    for (final g in groups.where((g) => g.isAdmin(me)))
      for (final r in g.openRequests(me)) r.id,
  };
}

/// De groepsaanvragen die je als beheerder nog niet op de tab Peloton zag.
/// Zie [SeenIdsStore] voor waarom gezien genoeg is.
@riverpod
class UnseenGroupRequests extends _$UnseenGroupRequests {
  @override
  Future<Set<String>> build() async {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) return const {};
    final ids = ref.watch(openGroupRequestIdsProvider);
    if (ids.isEmpty) return const {};
    final store = SeenGroupRequestsStore(await SharedPreferences.getInstance());
    return unseenIds(current: ids, seen: store.seenFor(me) ?? const {});
  }

  /// Aangeroepen door de tab Peloton zodra die de groepskaarten echt toont;
  /// de aanvragenchip op de kaart zegt dan waar het over gaat.
  Future<void> markAllSeen() async {
    final me = ref.read(currentUserIdProvider);
    final ids = ref.read(openGroupRequestIdsProvider);
    if (me == null || ids.isEmpty) return;
    final store = SeenGroupRequestsStore(await SharedPreferences.getInstance());
    await store.add(me, ids);
    state = const AsyncData({});
  }
}

/// De maatjes die er zijn bijgekomen sinds je de tab Peloton voor het laatst
/// zag. Zie [SeenFriendsStore] voor waarom dit lokaal is.
@riverpod
class UnseenFriends extends _$UnseenFriends {
  @override
  Future<Set<String>> build() async {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) return const {};
    final friends = await ref.watch(friendsProvider.future);
    final store = SeenFriendsStore(await SharedPreferences.getInstance());
    final seen = store.seenFor(me);
    final ids = friends.map((f) => f.userId);
    // De eerste keer na de update van build 61: wat er toen stond, was al
    // gezien.
    if (seen == null) {
      await store.save(me, ids);
      return const {};
    }
    return unseenIds(current: ids, seen: seen);
  }

  /// Aangeroepen door de tab Peloton zodra die de maatjes echt toont.
  Future<void> markAllSeen() async {
    final me = ref.read(currentUserIdProvider);
    final friends = ref.read(friendsProvider).value;
    if (me == null || friends == null) return;
    final store = SeenFriendsStore(await SharedPreferences.getInstance());
    await store.save(me, friends.map((f) => f.userId));
    state = const AsyncData({});
  }
}
