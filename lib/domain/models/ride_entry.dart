import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';

/// Jouw rol in een rit.
///
/// Dit is de vraag die de app tot 2026-09-08 niet beantwoordde: een rit stond
/// óf op "Mijn ritten" óf op "Peloton", en welke van de twee bepaalde alles.
/// Ritten die je organiseert stonden daardoor nergens op Home, en `joined` en
/// `owned` droegen hetzelfde icoon -- de rol zat in de sectiekop, niet in de
/// rit (waargenomen door Joost, schets 008).
///
/// De volgorde van de waarden is de voorrangsvolgorde bij [buildRideEntries]:
/// staat hetzelfde tijdvak in meerdere bronnen, dan wint de eerste.
enum RideRole {
  /// Iemand heeft je gevraagd en jij hebt nog niet geantwoord. Staat vooraan
  /// omdat het het enige is wat iets van jóu vraagt.
  pending,

  /// Jij bent de eigenaar van de gedeelde rit.
  organiser,

  /// Andermans gedeelde rit waar jij ja op hebt gezegd.
  joined,

  /// Een rit uit `planned_rides` waar geen gedeelde rit bij hoort.
  solo,
}

/// Eén rit in de lijst, ongeacht waar hij vandaan komt.
///
/// Bewust een weergavemodel en geen tabel: `planned_rides` blijft strikt
/// persoonlijk en `group_rides` blijft het gedeelde object (keuze 2 van epic
/// #62). Dit is de laag die ze naast elkaar op één scherm zet.
class RideEntry {
  const RideEntry({
    required this.start,
    required this.end,
    required this.plannedScore,
    required this.role,
    this.group,
    this.planned,
  });

  final DateTime start;
  final DateTime end;

  /// De score op het moment van plannen -- uit de gedeelde rit als die er is,
  /// anders uit de persoonlijke.
  final double plannedScore;

  final RideRole role;

  /// De gedeelde rit, of `null` bij [RideRole.solo].
  final GroupRide? group;

  /// De persoonlijke rij, of `null` als deze rit alleen als gedeelde rit
  /// bestaat. Accepteren maakt met opzet géén `planned_rides`-rij, dus bij
  /// [RideRole.joined] en [RideRole.pending] is dit vrijwel altijd `null`.
  final PlannedRide? planned;

  int get durationHours => end.difference(start).inHours;

  bool get isShared => role != RideRole.solo;

  /// Wie de rit organiseert. `null` als jij dat zelf bent of als de rit solo is.
  String? get ownerName => role == RideRole.organiser ? null : group?.ownerName;

  /// Hoeveel maatjes er meegaan (de organisator niet meegerekend -- die staat
  /// niet in zijn eigen deelnemerslijst).
  int get acceptedCount => group?.accepted.length ?? 0;

  /// Hoeveel er nog moeten antwoorden.
  int get pendingCount =>
      group?.participants
          .where((p) => p.status == ParticipantStatus.invited)
          .length ??
      0;

  /// Of deze rit met een veeg weg te halen is. Alleen waar jij als enige over
  /// gaat: een solo-rit, of een rit die jij organiseert (die zegt dan de hele
  /// rit af, inclusief de persoonlijke rij eronder). Andermans rit gooi je niet
  /// weg -- daar zeg je af, en dat is een andere handeling met een andere knop.
  bool get isRemovable => role == RideRole.solo || role == RideRole.organiser;

  /// Sleutel waarop twee bronnen dezelfde rit blijken te zijn.
  ///
  /// Uit UTC en niet uit de lokale velden, om dezelfde reden als
  /// [PlannedRide.rideId]: een rit uit de cloud en zijn lokale kopie duiden
  /// hetzelfde tijdstip aan maar hebben een andere zone-notatie, en op de
  /// lokale velden vergelijken levert dan twee sleutels voor één rit.
  static String slotKey(DateTime start, DateTime end) =>
      '${start.toUtc().millisecondsSinceEpoch}_${end.toUtc().millisecondsSinceEpoch}';

  String get key => slotKey(start, end);
}

/// Voegt de vier bronnen samen tot één chronologische lijst.
///
/// **Waarom ontdubbelen nodig is.** Uitnodigen begint bij een rit die je al
/// bekijkt (zie `invite_buddies_sheet.dart`), dus wie maatjes uitnodigt heeft
/// dat tijdvak meestal al als persoonlijke rit staan. Zonder deze stap zou
/// diezelfde rit twee keer in de lijst komen -- één keer als "Alleen jij" en
/// één keer als "Jij organiseert" -- en dat is precies de tegenspraak die dit
/// scherm moest opheffen. De gedeelde rit wint, want die draagt meer: wie er
/// meegaat en wie nog moet antwoorden.
///
/// [notBefore] snijdt ritten weg die al voorbij zijn. Geef `null` om alles te
/// houden.
List<RideEntry> buildRideEntries({
  required List<PlannedRide> planned,
  required List<GroupRide> owned,
  required List<GroupRide> joined,
  required List<GroupRide> invites,
  DateTime? notBefore,
}) {
  final byKey = <String, RideEntry>{};

  void put(RideEntry entry) {
    final existing = byKey[entry.key];
    // Lagere index in de enum wint (pending < organiser < joined < solo).
    if (existing == null || entry.role.index < existing.role.index) {
      byKey[entry.key] = entry;
    }
  }

  void putGroup(GroupRide g, RideRole role) => put(
        RideEntry(
          start: g.start,
          end: g.end,
          plannedScore: g.plannedScore,
          role: role,
          group: g,
        ),
      );

  for (final g in invites) {
    putGroup(g, RideRole.pending);
  }
  for (final g in owned) {
    putGroup(g, RideRole.organiser);
  }
  for (final g in joined) {
    putGroup(g, RideRole.joined);
  }
  for (final p in planned) {
    final key = RideEntry.slotKey(p.start, p.end);
    final existing = byKey[key];
    if (existing != null) {
      // De gedeelde rit blijft staan, maar onthoudt wél de persoonlijke rij
      // eronder -- anders is die na het afzeggen van de groepsrit niet meer
      // op te ruimen en blijft er een wees achter in `planned_rides`.
      byKey[key] = RideEntry(
        start: existing.start,
        end: existing.end,
        plannedScore: existing.plannedScore,
        role: existing.role,
        group: existing.group,
        planned: p,
      );
      continue;
    }
    byKey[key] = RideEntry(
      start: p.start,
      end: p.end,
      plannedScore: p.plannedScore,
      role: RideRole.solo,
      planned: p,
    );
  }

  final result = byKey.values
      .where((e) => notBefore == null || e.end.isAfter(notBefore))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  return result;
}

/// Hoeveel ritten er per rol in [entries] zitten. Voor de tellingen in de
/// filterrij, die het antwoord geven vóór je erop tikt.
Map<RideRole, int> countByRole(List<RideEntry> entries) {
  final counts = {for (final role in RideRole.values) role: 0};
  for (final e in entries) {
    counts[e.role] = counts[e.role]! + 1;
  }
  return counts;
}
