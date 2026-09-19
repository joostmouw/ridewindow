/// Datamodellen voor epic "Peloton" (BACKLOG.md #62).
///
/// Plain Dart klassen met `fromRow`, net als [PlannedRide] en [UserProfile] —
/// dit project gebruikt Freezed niet voor dit soort rijen, en dat blijft zo.
library;

/// Een maatje. Alleen wat `friend_profiles()` teruggeeft.
///
/// Er staat bewust niet meer in dan dit: de rest van `profiles` blijft
/// afgeschermd, ook voor vrienden (zie `0002_peloton.sql`, keuze 2). Groeit
/// deze klasse ooit, controleer dan eerst of de database die velden wel mág
/// teruggeven.
class Friend {
  const Friend({required this.userId, this.displayName});

  final String userId;
  final String? displayName;

  factory Friend.fromRow(Map<String, dynamic> row) => Friend(
        userId: row['user_id'] as String,
        displayName: row['user_name'] as String?,
      );

  /// Wat je op het scherm zet als iemand nooit een naam heeft ingevuld.
  /// Bewust geen e-mailadres of uid: die kent de app niet en horen hier ook
  /// niet te staan.
  String label(String fallback) {
    final name = displayName?.trim();
    return (name == null || name.isEmpty) ? fallback : name;
  }
}

enum ParticipantStatus {
  invited,
  accepted,
  declined;

  static ParticipantStatus fromRow(String? value) => switch (value) {
        'accepted' => ParticipantStatus.accepted,
        'declined' => ParticipantStatus.declined,
        _ => ParticipantStatus.invited,
      };

  String get row => name;
}

class RideParticipant {
  const RideParticipant({
    required this.userId,
    required this.status,
    this.displayName,
  });

  final String userId;
  final ParticipantStatus status;
  final String? displayName;

  factory RideParticipant.fromRow(Map<String, dynamic> row) => RideParticipant(
        userId: row['user_id'] as String,
        status: ParticipantStatus.fromRow(row['status'] as String?),
        displayName: row['display_name'] as String?,
      );
}

/// Een venster dat voorligt bij een gedeelde rit (slice 2 van epic #65).
///
/// De score staat erin en wordt niet herberekend. Het weerbericht verandert
/// namelijk, en dan zou achteraf niet meer te zien zijn waarop iemand zijn stem
/// baseerde -- dezelfde reden waarom `group_rides.planned_score` bestaat.
class RideOption {
  const RideOption({
    required this.id,
    required this.rideId,
    required this.start,
    required this.end,
    required this.plannedScore,
    this.votes = const [],
  });

  final String id;
  final String rideId;
  final DateTime start;
  final DateTime end;
  final double plannedScore;
  final List<OptionVote> votes;

  /// `.toLocal()` om dezelfde reden als bij [GroupRide.fromRow].
  factory RideOption.fromRow(
    Map<String, dynamic> row, {
    List<OptionVote> votes = const [],
  }) =>
      RideOption(
        id: row['id'] as String,
        rideId: row['ride_id'] as String,
        start: DateTime.parse(row['start_at'] as String).toLocal(),
        end: DateTime.parse(row['end_at'] as String).toLocal(),
        plannedScore: (row['planned_score'] as num).toDouble(),
        votes: votes,
      );

  /// Hoeveel mensen bij dit venster kunnen.
  int get yesCount => votes.where((v) => v.canRide).length;

  /// Het antwoord van [userId], of `null` als hij nog niet gestemd heeft.
  ///
  /// Geen rij is iets anders dan "nee": dat onderscheid is de reden dat dit
  /// een `bool?` teruggeeft en geen `bool`.
  bool? voteOf(String? userId) {
    if (userId == null) return null;
    for (final v in votes) {
      if (v.userId == userId) return v.canRide;
    }
    return null;
  }
}

/// Eén stem van één persoon op één venster.
class OptionVote {
  const OptionVote({
    required this.optionId,
    required this.userId,
    required this.canRide,
  });

  final String optionId;
  final String userId;
  final bool canRide;

  factory OptionVote.fromRow(Map<String, dynamic> row) => OptionVote(
        optionId: row['option_id'] as String,
        userId: row['user_id'] as String,
        canRide: row['can_ride'] as bool,
      );
}

/// Een gedeelde rit: één object met deelnemers, geen kopie per persoon.
///
/// Dat onderscheid is Joost's keuze (2026-09-03) en het is de reden dat deze
/// klasse naast [PlannedRide] bestaat in plaats van eroverheen. `planned_rides`
/// blijft strikt persoonlijk; wijzigt de eigenaar hier de tijd, dan schuift die
/// bij iedereen mee.
class GroupRide {
  const GroupRide({
    required this.id,
    required this.ownerId,
    required this.start,
    required this.end,
    required this.plannedScore,
    this.ownerName,
    this.note,
    this.participants = const [],
    this.options = const [],
  });

  final String id;
  final String ownerId;
  final DateTime start;
  final DateTime end;
  final double plannedScore;
  final String? ownerName;
  final String? note;
  final List<RideParticipant> participants;

  /// De vensters die nog voorliggen (slice 2). Leeg is de gewone toestand: dan
  /// is er niets te kiezen en geldt gewoon [start]/[end].
  final List<RideOption> options;

  /// `.toLocal()` is niet cosmetisch (dezelfde les als plan 21-13): de UI drukt
  /// de velden van de `DateTime` rechtstreeks af, dus zonder omzetting staat
  /// een rit van 20:00 in de zomer als 18:00 op het scherm.
  factory GroupRide.fromRow(
    Map<String, dynamic> row, {
    List<RideParticipant> participants = const [],
    List<RideOption> options = const [],
  }) =>
      GroupRide(
        id: row['id'] as String,
        ownerId: row['owner_id'] as String,
        start: DateTime.parse(row['start_at'] as String).toLocal(),
        end: DateTime.parse(row['end_at'] as String).toLocal(),
        plannedScore: (row['planned_score'] as num).toDouble(),
        ownerName: row['owner_name'] as String?,
        note: row['note'] as String?,
        participants: participants,
        options: options,
      );

  bool isOwnedBy(String? userId) => userId != null && userId == ownerId;

  /// Wie er daadwerkelijk meegaat — de eigenaar niet meegerekend, die staat
  /// niet in zijn eigen deelnemerslijst.
  Iterable<RideParticipant> get accepted =>
      participants.where((p) => p.status == ParticipantStatus.accepted);

  /// Ligt er nog een keuze voor? Eén venster is geen keuze -- dan is het het
  /// voorstel zelf, en hoort er geen stemming omheen te staan.
  bool get hasOpenChoice => options.length > 1;

  /// De optie waar de meeste mensen bij kunnen. Bij gelijkspel wint de hoogste
  /// score, en daarna de vroegste -- dezelfde volgorde als Home aanhoudt, zodat
  /// "de beste" overal hetzelfde betekent.
  RideOption? get frontRunner {
    if (options.isEmpty) return null;
    final sorted = [...options]..sort((a, b) {
        final byVotes = b.yesCount.compareTo(a.yesCount);
        if (byVotes != 0) return byVotes;
        final byScore = b.plannedScore.compareTo(a.plannedScore);
        if (byScore != 0) return byScore;
        return a.start.compareTo(b.start);
      });
    return sorted.first;
  }

  /// De status van [userId] op deze rit, of `null` als hij er niet bij hoort.
  ParticipantStatus? statusFor(String? userId) {
    if (userId == null) return null;
    for (final p in participants) {
      if (p.userId == userId) return p.status;
    }
    return null;
  }
}
