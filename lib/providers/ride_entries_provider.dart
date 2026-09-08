import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';

part 'ride_entries_provider.g.dart';

/// Alle aankomende ritten, uit alle vier de bronnen, in chronologische
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

  final now = DateTime.now();
  return buildRideEntries(
    planned: planned,
    owned: owned,
    joined: joined,
    invites: invites,
    // Vanaf het begin van vandaag, niet vanaf dit moment: een rit die vanochtend
    // om 07:00 begon en om 09:00 eindigde hoort de rest van de dag nog zichtbaar
    // te zijn. Dezelfde grens die "Mijn ritten" al hanteerde.
    notBefore: DateTime(now.year, now.month, now.day),
  );
}
