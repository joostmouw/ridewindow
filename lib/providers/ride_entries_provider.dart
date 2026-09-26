import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
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
/// Eén van de drie delen van [pelotonAttentionCount].
@riverpod
int unansweredRideCount(Ref ref) {
  final now = DateTime.now();
  return ref
      .watch(rideEntriesProvider)
      .where((e) => e.role == RideRole.pending && e.end.isAfter(now))
      .length;
}

/// Het getal in het rode bolletje op Ritten en op de tab Peloton: ritten die
/// op jouw antwoord wachten, aanvragen die bij jou als beheerder liggen, en
/// maatjes die je nog niet zag.
///
/// CLUB-25 optie A (schets 016): onderbalk en tab lezen allebei dit ene getal,
/// zodat ze nooit iets anders zeggen. Tot 2026-09-26 telden groepsaanvragen
/// bewust niet mee (34-05); Joost wilde ze er toen toch bij, omdat er zonder
/// pushmeldingen geen andere plek is waar een beheerder ze ziet zonder de
/// groep te openen.
@riverpod
int pelotonAttentionCount(Ref ref) {
  final int rides = ref.watch(unansweredRideCountProvider);
  final int requests = ref.watch(openGroupRequestCountProvider);
  final int friends = ref.watch(unseenFriendsProvider).value ?? 0;
  return rides + requests + friends;
}
