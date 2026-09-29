import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/seen_friends_store.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';

part 'ride_entries_provider.g.dart';

/// Alle aankomende ritten, uit alle vijf de bronnen, in chronologische
/// volgorde en met jouw rol erbij.
///
/// **Eén provider en niet vier losse watches per scherm.** Home en het
/// rittenscherm lieten allebei hun eigen deelverzameling zien -- Home toonde
/// eigen plus geaccepteerde ritten, "Mijn ritten" alleen de eigen, en wat je
/// organiseerde stond op geen van beide. Drie schermen die zelf beslissen wat
/// een rit is, geven drie antwoorden op dezelfde vraag.
///
/// Bewust `.value ?? const []` en geen `AsyncValue`: de gedeelde ritten komen
/// van het netwerk en de persoonlijke van de schijf. Op één ontbrekende
/// cloud-aanroep de hele lijst laten wachten zou een uitgelogde of offline
/// gebruiker zijn eigen geplande ritten afnemen, en Peloton is additief
/// (REQUIREMENTS.md regel 8).
@riverpod
List<RideEntry> rideEntries(Ref ref) {
  final planned =
      ref.watch(plannedRidesProvider).value ?? const <PlannedRide>[];
  final owned = ref.watch(ownedGroupRidesProvider).value ?? const <GroupRide>[];
  final joined =
      ref.watch(joinedGroupRidesProvider).value ?? const <GroupRide>[];
  final invites =
      ref.watch(pendingRideInvitesProvider).value ?? const <GroupRide>[];
  final declined =
      ref.watch(declinedGroupRidesProvider).value ?? const <GroupRide>[];
  // Zelfde reden als hierboven: een falende groepenlijst mag de ritten niet
  // wegnemen. Dan ontbreekt alleen de groepsnaam en tellen de rijen.
  final groups = ref.watch(myGroupsProvider).value ?? const <PelotonGroup>[];

  final now = DateTime.now();
  return buildRideEntries(
    planned: planned,
    owned: owned,
    joined: joined,
    invites: invites,
    declined: declined,
    groups: {for (final g in groups) g.id: g},
    // Vanaf het begin van vandaag, niet vanaf dit moment: een rit die vanochtend
    // om 07:00 begon en om 09:00 eindigde hoort de rest van de dag nog zichtbaar
    // te zijn. Dezelfde grens die "Mijn ritten" al hanteerde.
    notBefore: DateTime(now.year, now.month, now.day),
  );
}

/// Hoeveel ritten er op jouw antwoord wachten: losse uitnodigingen plus
/// groepsritten zonder jouw rij, alleen wat nog niet voorbij is.
///
/// Telt niet meer mee in het bolletje; dat telt [UnseenRideInvites].
@riverpod
int unansweredRideCount(Ref ref) => ref.watch(pendingRideKeysProvider).length;

/// De sleutels achter [unansweredRideCount].
@riverpod
List<String> pendingRideKeys(Ref ref) {
  final now = DateTime.now();
  return [
    for (final e in ref.watch(rideEntriesProvider))
      if (e.role == RideRole.pending && e.end.isAfter(now)) e.key,
  ];
}

/// De ritvragen die je nog niet op de tab Ritten zag. Zie [SeenIdsStore] voor
/// waarom gezien genoeg is: de kaart zelf blijft "vraagt je mee" zeggen tot je
/// antwoordt.
@riverpod
class UnseenRideInvites extends _$UnseenRideInvites {
  @override
  Future<Set<String>> build() async {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) return const {};
    final keys = ref.watch(pendingRideKeysProvider);
    if (keys.isEmpty) return const {};
    final store = SeenRideInvitesStore(await SharedPreferences.getInstance());
    return unseenIds(current: keys, seen: store.seenFor(me) ?? const {});
  }

  /// Aangeroepen door de tab Ritten met de kaarten die hij echt toont. Niet
  /// "alles": met een groepsfilter aan zie je een ritvraag uit een andere
  /// groep niet, en dan mag hij niet stil als gezien gelden.
  Future<void> markSeen(Iterable<String> keys) async {
    final me = ref.read(currentUserIdProvider);
    final shown = keys.toSet();
    if (me == null || shown.isEmpty) return;
    final store = SeenRideInvitesStore(await SharedPreferences.getInstance());
    await store.add(me, shown);
    state = AsyncData((state.value ?? const {}).difference(shown));
  }
}

/// Het getal op de tab Ritten: ritvragen die je nog niet zag.
@riverpod
int ridesTabAttentionCount(Ref ref) =>
    ref.watch(unseenRideInvitesProvider).value?.length ?? 0;

/// Het getal op de tab Peloton: groepsaanvragen en maatjes die je nog niet
/// zag.
@riverpod
int pelotonTabAttentionCount(Ref ref) {
  final int requests = ref.watch(unseenGroupRequestsProvider).value?.length ?? 0;
  final int friends = ref.watch(unseenFriendsProvider).value?.length ?? 0;
  return requests + friends;
}

/// Het getal in het rode bolletje op Ritten in de onderbalk: de som van de
/// twee tabs.
///
/// **Elk bolletje staat op de tab waar het over gaat.** Tot build 61 las de
/// tab Peloton dit hele getal, ook de ritvragen die op de tab Ritten staan. In
/// de video van 29 september bleef "Peloton 1" daardoor staan terwijl Joost
/// naar zijn maatjes keek: de 1 was een ritvraag van Richard. En het telde
/// wat op antwoord wachtte in plaats van wat je nog niet zag.
///
/// Groepsaanvragen tellen mee sinds 2026-09-26 (Joost): zonder pushmeldingen
/// is er geen andere plek waar een beheerder ze ziet zonder de groep te
/// openen.
@riverpod
int pelotonAttentionCount(Ref ref) =>
    ref.watch(ridesTabAttentionCountProvider) +
    ref.watch(pelotonTabAttentionCountProvider);
