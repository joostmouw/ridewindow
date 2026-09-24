import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
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

  /// Andermans gedeelde rit waar jij nee op hebt gezegd.
  ///
  /// Staat achteraan en dat is de hele bedoeling: afzeggen viel tot 2026-09-19
  /// uit alle drie de lijsten tegelijk, waarmee de rit nergens meer aan te
  /// wijzen was terwijl de rij gewoon bestond en RLS een terugweg toestond
  /// (backlog #66). Nu is hij te vinden, maar alleen als je er expliciet naar
  /// filtert -- een afzegging hoort niet terug te komen op Home.
  ///
  /// De laatste plek in de enum betekent ook de laagste voorrang: heb je een
  /// groepsrit afgezegd maar staat datzelfde tijdvak nog als je eigen rit, dan
  /// wint die eigen rit.
  declined,
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
    this.pelotonGroup,
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

  /// Afgezegd, en daarmee uit de gewone lijst. Zie [RideRole.declined].
  bool get isDeclined => role == RideRole.declined;

  /// Wie de rit organiseert. `null` als jij dat zelf bent of als de rit solo is.
  String? get ownerName => role == RideRole.organiser ? null : group?.ownerName;

  /// De groep van een groepsrit, of `null` bij een gewone rit. Ook `null` als
  /// de groep niet bij jouw groepen hoort, bijvoorbeeld een organisator die de
  /// groep inmiddels verliet: dan valt de naam weg en tellen de rijen zoals bij
  /// een gewone gedeelde rit.
  final PelotonGroup? pelotonGroup;

  /// De naam voor de rolregel en de chip op het detail (CLUB-16).
  String? get groupName => pelotonGroup?.name;

  bool get isGroupRide => group?.isGroupRide ?? false;

  /// Tellen we over de leden van de groep in plaats van over de rijen?
  bool get _countsMembers =>
      pelotonGroup != null && group?.groupId == pelotonGroup!.id;

  /// Status per huidig lid, de organisator niet meegerekend. Geen rij (of een
  /// rij `invited`) is "nog niet geantwoord". Rijen van ex-leden vallen
  /// hierbuiten: wie de groep verliet, telt niet meer mee.
  Iterable<ParticipantStatus> get _memberStatuses sync* {
    final g = group!;
    for (final m in pelotonGroup!.members) {
      if (m.userId == g.ownerId) continue;
      yield g.statusFor(m.userId) ?? ParticipantStatus.invited;
    }
  }

  /// Hoeveel er meegaan.
  ///
  /// Bij een gewone gedeelde rit de maatjes, de organisator niet meegerekend
  /// (die staat niet in zijn eigen deelnemerslijst), zoals het altijd was.
  /// Bij een groepsrit telt de organisator wel mee (schets 016, bevestigd door
  /// Joost 2026-09-24: "2 gaan mee" is jij + Jacco). Daar staat de telling
  /// naast "kan niet" en "nog niet" van dezelfde ledenlijst, en de kaart en het
  /// detail tonen dan hetzelfde getal als de lijst per lid.
  int get acceptedCount {
    if (_countsMembers) {
      return 1 +
          _memberStatuses.where((s) => s == ParticipantStatus.accepted).length;
    }
    return group?.accepted.length ?? 0;
  }

  /// Hoeveel er nog moeten antwoorden.
  int get pendingCount {
    if (_countsMembers) {
      return _memberStatuses
          .where((s) => s == ParticipantStatus.invited)
          .length;
    }
    return group?.participants
            .where((p) => p.status == ParticipantStatus.invited)
            .length ??
        0;
  }

  /// Hoeveel er nee hebben gezegd.
  int get declinedCount {
    if (_countsMembers) {
      return _memberStatuses
          .where((s) => s == ParticipantStatus.declined)
          .length;
    }
    return group?.participants
            .where((p) => p.status == ParticipantStatus.declined)
            .length ??
        0;
  }

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

  /// Sleutel van deze regel in een lijst: per rit-id bij een gedeelde rit,
  /// per tijdvak bij een solo-rit.
  ///
  /// Twee verschillende gedeelde ritten op hetzelfde tijdvak (bijvoorbeeld een
  /// groepsrit van Jacco en jouw eigen rit met Bram, allebei op het beste
  /// venster van de week) moeten allebei zichtbaar blijven. Op tijdvak
  /// ontdubbelen liet er één winnen en de ander verdwijnen: dezelfde fout als
  /// 2026-09-07, een rit die bestond maar nergens stond.
  String get key => group != null ? 'ride_${group!.id}' : slotKey(start, end);
}

/// Voegt de bronnen samen tot één chronologische lijst.
///
/// **Gedeelde ritten ontdubbelen per rit-id.** Staat dezelfde rit in twee
/// bronnen (kan in theorie niet, maar de cloud is geen bewijs), dan wint de
/// lagere rolindex. Twee *verschillende* gedeelde ritten op hetzelfde tijdvak
/// blijven allebei staan; zie [RideEntry.key].
///
/// **Persoonlijke ritten hangen aan een gedeelde rit op hetzelfde tijdvak.**
/// Uitnodigen begint bij een rit die je al bekijkt (zie
/// `invite_buddies_sheet.dart`), dus wie maatjes uitnodigt heeft dat tijdvak
/// meestal al als persoonlijke rit staan. Zonder deze stap zou diezelfde rit
/// twee keer in de lijst komen -- één keer als "Alleen jij" en één keer als
/// "Jij organiseert". De gedeelde rit wint, want die draagt meer. Staan er op
/// het tijdvak meerdere gedeelde ritten, dan gaat de persoonlijke rij naar de
/// rit die jij organiseert (die is het meest waarschijnlijk uit jouw plan
/// ontstaan), anders naar de regel met de hoogste voorrang.
///
/// [groups] zijn jouw groepen op id; een groepsrit krijgt zo zijn
/// [RideEntry.pelotonGroup] mee voor de naam en de tellingen per lid.
///
/// [notBefore] snijdt ritten weg die al voorbij zijn. Geef `null` om alles te
/// houden.
List<RideEntry> buildRideEntries({
  required List<PlannedRide> planned,
  required List<GroupRide> owned,
  required List<GroupRide> joined,
  required List<GroupRide> invites,
  List<GroupRide> declined = const [],
  Map<String, PelotonGroup> groups = const {},
  DateTime? notBefore,
}) {
  // Invoegvolgorde bewaard (LinkedHashMap), zodat een gelijkspel bij het
  // kiezen van de regel voor een persoonlijke rit voorspelbaar uitvalt.
  final byRide = <String, RideEntry>{};

  void putGroup(GroupRide g, RideRole role) {
    final existing = byRide[g.id];
    // Lagere index in de enum wint (pending < organiser < joined < ...).
    if (existing != null && existing.role.index <= role.index) return;
    byRide[g.id] = RideEntry(
      start: g.start,
      end: g.end,
      plannedScore: g.plannedScore,
      role: role,
      group: g,
      pelotonGroup: g.groupId == null ? null : groups[g.groupId],
    );
  }

  for (final g in invites) {
    putGroup(g, RideRole.pending);
  }
  for (final g in owned) {
    putGroup(g, RideRole.organiser);
  }
  for (final g in joined) {
    putGroup(g, RideRole.joined);
  }
  for (final g in declined) {
    putGroup(g, RideRole.declined);
  }

  final sharedBySlot = <String, List<String>>{};
  for (final e in byRide.values) {
    sharedBySlot.putIfAbsent(RideEntry.slotKey(e.start, e.end), () => []).add(
          e.group!.id,
        );
  }

  final solo = <String, RideEntry>{};
  for (final p in planned) {
    final key = RideEntry.slotKey(p.start, p.end);
    final rideIds = sharedBySlot[key];
    if (rideIds != null && rideIds.isNotEmpty) {
      final candidates = [for (final id in rideIds) byRide[id]!];
      // Jouw eigen gedeelde rit eerst, ook als er een openstaande
      // uitnodiging (lagere index) op hetzelfde tijdvak staat.
      var target = candidates.firstWhere(
        (c) => c.role == RideRole.organiser,
        orElse: () => candidates.reduce(
          (a, b) => b.role.index < a.role.index ? b : a,
        ),
      );
      // De gedeelde rit blijft staan, maar onthoudt wél de persoonlijke rij
      // eronder -- anders is die na het afzeggen van de groepsrit niet meer
      // op te ruimen en blijft er een wees achter in `planned_rides`.
      //
      // Uitzondering: een afgezegde groepsrit mag jouw eigen rit niet
      // meetrekken naar de verborgen hoek. Zeg je nee tegen andermans rit maar
      // stond datzelfde tijdvak al als jouw eigen plan, dan is het gewoon jouw
      // rit -- die hoort op Home te blijven staan.
      byRide[target.group!.id] = RideEntry(
        start: target.start,
        end: target.end,
        plannedScore: target.plannedScore,
        role: target.role == RideRole.declined ? RideRole.solo : target.role,
        group: target.group,
        planned: p,
        pelotonGroup: target.pelotonGroup,
      );
      continue;
    }
    solo[key] = RideEntry(
      start: p.start,
      end: p.end,
      plannedScore: p.plannedScore,
      role: RideRole.solo,
      planned: p,
    );
  }

  final result = [...byRide.values, ...solo.values]
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
