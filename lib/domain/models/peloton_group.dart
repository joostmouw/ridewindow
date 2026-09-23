/// Datamodellen voor Clubs (milestone v4.2, fase 34): groepen, leden en
/// aanvragen, zoals `0012_groups.sql` en `0013_group_join_requests.sql` ze
/// vastleggen.
///
/// Plain Dart met `fromRow`, net als `Friend` in `peloton.dart`.
///
/// **Een lid draagt niets anders dan naam, rol en joined_at (CLUB-05).** Leden
/// van een groep hoeven geen maatjes van elkaar te zijn; ze zien elkaars naam
/// en antwoorden op groepsritten, niet elkaars rooster of instellingen. De
/// gateway selecteert daarom expliciete kolommen, nooit `*`. Groeit
/// [GroupMember] of [GroupJoinRequest] ooit, controleer dan eerst of de
/// database die velden wel mag teruggeven -- dezelfde waarschuwing als bij
/// `Friend`.
library;

/// Max leden per groep. Spiegel van `guard_group_member_insert` (0012): de
/// database is de echte grens, de app waarschuwt alleen vooraf.
const kGroupMaxMembers = 30;

/// Max groepen per account. Spiegel van `guard_group_member_insert` (0012).
const kMaxGroupsPerAccount = 10;

/// Max open aanvragen per groep. Spiegel van `redeem_group_invite` en
/// `propose_group_member` (0013).
const kMaxOpenRequestsPerGroup = 30;

/// Max lengte van een groepsnaam in de UI (schets 015). De database staat 60
/// tekens toe; de app houdt het korter zodat de naam op een kaart past.
const kGroupNameMaxLength = 40;

enum GroupRole {
  admin,
  member;

  static GroupRole fromRow(String? value) =>
      value == 'admin' ? GroupRole.admin : GroupRole.member;

  String get row => name;
}

/// Wat `redeem_group_invite` en `propose_group_member` teruggeven (0013):
/// direct lid, of een aanvraag die bij de beheerders ligt.
enum GroupJoinStatus {
  member,
  requested;

  static GroupJoinStatus fromRow(String? value) =>
      value == 'member' ? GroupJoinStatus.member : GroupJoinStatus.requested;
}

String _labelOr(String? displayName, String fallback) {
  final name = displayName?.trim();
  return (name == null || name.isEmpty) ? fallback : name;
}

class GroupMember {
  const GroupMember({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName,
  });

  final String groupId;
  final String userId;
  final GroupRole role;
  final String? displayName;

  /// Stuurt de opvolging: bij vertrek van de laatste beheerder wordt het
  /// langst zittende lid beheerder (`ensure_group_admin`, 0012).
  final DateTime joinedAt;

  factory GroupMember.fromRow(Map<String, dynamic> row) => GroupMember(
        groupId: row['group_id'] as String,
        userId: row['user_id'] as String,
        role: GroupRole.fromRow(row['role'] as String?),
        displayName: row['display_name'] as String?,
        joinedAt: DateTime.parse(row['joined_at'] as String).toLocal(),
      );

  bool get isAdmin => role == GroupRole.admin;

  String label(String fallback) => _labelOr(displayName, fallback);
}

/// Een open aanvraag om lid te worden (0013). Een rij bestaat alleen zolang de
/// aanvraag openstaat: accepteren, afwijzen en intrekken halen hem weg.
class GroupJoinRequest {
  const GroupJoinRequest({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.createdAt,
    this.proposedBy,
    this.displayName,
    this.proposedByName,
  });

  final String id;
  final String groupId;
  final String userId;

  /// null = binnengekomen via de groepslink.
  final String? proposedBy;
  final String? displayName;
  final String? proposedByName;
  final DateTime createdAt;

  factory GroupJoinRequest.fromRow(Map<String, dynamic> row) =>
      GroupJoinRequest(
        id: row['id'] as String,
        groupId: row['group_id'] as String,
        userId: row['user_id'] as String,
        proposedBy: row['proposed_by'] as String?,
        displayName: row['display_name'] as String?,
        proposedByName: row['proposed_by_name'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );

  bool get isViaLink => proposedBy == null;

  String label(String fallback) => _labelOr(displayName, fallback);
}

class PelotonGroup {
  const PelotonGroup({
    required this.id,
    required this.name,
    required this.createdAt,
    this.members = const [],
    this.requests = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;

  /// Beheerders eerst, dan op joinedAt, dan op userId.
  final List<GroupMember> members;

  /// Alleen wat RLS jou laat zien: als beheerder alle aanvragen, anders je
  /// eigen aanvraag en je eigen voordrachten. Oplopend op createdAt.
  final List<GroupJoinRequest> requests;

  factory PelotonGroup.fromRows(
    Map<String, dynamic> groupRow,
    Iterable<Map<String, dynamic>> memberRows,
    Iterable<Map<String, dynamic>> requestRows,
  ) {
    final members = memberRows.map(GroupMember.fromRow).toList()
      ..sort((a, b) {
        if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
        final byJoined = a.joinedAt.compareTo(b.joinedAt);
        if (byJoined != 0) return byJoined;
        return a.userId.compareTo(b.userId);
      });
    final requests = requestRows.map(GroupJoinRequest.fromRow).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return PelotonGroup(
      id: groupRow['id'] as String,
      name: groupRow['name'] as String,
      createdAt: DateTime.parse(groupRow['created_at'] as String).toLocal(),
      members: members,
      requests: requests,
    );
  }

  int get memberCount => members.length;
  int get adminCount => members.where((m) => m.isAdmin).length;
  bool get isFull => memberCount >= kGroupMaxMembers;
  String get initials => groupInitials(name);

  GroupMember? memberFor(String? uid) {
    if (uid == null) return null;
    for (final m in members) {
      if (m.userId == uid) return m;
    }
    return null;
  }

  bool isMember(String? uid) => memberFor(uid) != null;

  bool isAdmin(String? uid) => memberFor(uid)?.isAdmin ?? false;

  GroupJoinRequest? requestFor(String? uid) {
    if (uid == null) return null;
    for (final r in requests) {
      if (r.userId == uid) return r;
    }
    return null;
  }

  /// Je bent geen lid, maar je aanvraag ligt bij de beheerders.
  bool isPendingFor(String? uid) => !isMember(uid) && requestFor(uid) != null;

  /// De aanvragen van anderen, voor de sectie "Aanvragen" van een beheerder.
  List<GroupJoinRequest> openRequests(String? uid) =>
      requests.where((r) => r.userId != uid).toList();

  bool isLastMember(String? uid) => memberCount == 1 && isMember(uid);

  /// Wie beheerder wordt als [uid] vertrekt, of null als er niets verandert.
  ///
  /// Spiegel van `ensure_group_admin` (0012): alleen als [uid] de laatste
  /// beheerder is en er nog iemand overblijft. Het langst zittende lid, bij
  /// gelijke joined_at de kleinste user_id.
  GroupMember? successorIfLeaving(String? uid) {
    if (!isAdmin(uid)) return null;
    if (adminCount > 1) return null;
    final others = members.where((m) => m.userId != uid).toList()
      ..sort((a, b) {
        final byJoined = a.joinedAt.compareTo(b.joinedAt);
        if (byJoined != 0) return byJoined;
        return a.userId.compareTo(b.userId);
      });
    return others.isEmpty ? null : others.first;
  }
}

/// Twee tekens voor het kenteken van een groep.
///
/// Een woord: de eerste twee tekens ("Dinsdagclub" -> "DI"). Meer woorden: de
/// eerste letter van de eerste twee ("De Zaterdagclub" -> "DZ"). Leeg: "?".
/// Per grafeem, zodat een emoji of een letter met accent heel blijft.
///
/// Geen `package:characters`: die komt alleen transitief binnen via Flutter,
/// en lib/domain importeert niets wat niet in pubspec.yaml staat. [_graphemes]
/// dekt wat in een groepsnaam voorkomt (combinerende accenten, ZWJ-reeksen,
/// huidskleur, variatiekiezers, vlaggen).
String groupInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  final String result;
  if (words.length == 1) {
    result = _graphemes(words.first).take(2).join();
  } else {
    result = words.take(2).map((w) => _graphemes(w).first).join();
  }
  return result.toUpperCase();
}

bool _isExtender(int rune) =>
    (rune >= 0x0300 && rune <= 0x036F) || // combinerende accenten
    (rune >= 0xFE00 && rune <= 0xFE0F) || // variatiekiezers
    (rune >= 0x1F3FB && rune <= 0x1F3FF) || // huidskleur
    (rune >= 0xE0020 && rune <= 0xE007F) || // tag-tekens (subvlaggen)
    rune == 0x20E3; // keycap

bool _isRegionalIndicator(int rune) => rune >= 0x1F1E6 && rune <= 0x1F1FF;

/// Een vereenvoudigde grafeemsplitsing op runes.
Iterable<String> _graphemes(String word) sync* {
  final runes = word.runes.toList();
  var i = 0;
  while (i < runes.length) {
    final buffer = StringBuffer()..writeCharCode(runes[i]);
    final first = runes[i];
    i++;
    if (_isRegionalIndicator(first) &&
        i < runes.length &&
        _isRegionalIndicator(runes[i])) {
      buffer.writeCharCode(runes[i]);
      i++;
    }
    while (i < runes.length) {
      if (_isExtender(runes[i])) {
        buffer.writeCharCode(runes[i]);
        i++;
      } else if (runes[i] == 0x200D && i + 1 < runes.length) {
        buffer
          ..writeCharCode(runes[i])
          ..writeCharCode(runes[i + 1]);
        i += 2;
      } else {
        break;
      }
    }
    yield buffer.toString();
  }
}

/// Foutsleutels uit 0012 en 0013, als waarde. De app toont ze nooit zelf: zie
/// `groupErrorText` in `lib/features/peloton/group_error_text.dart`.
enum GroupError {
  groupFull,
  tooManyGroups,
  inviteInvalid,
  lastAdmin,
  groupNameInvalid,
  notAuthenticated,
  notMember,
  notFriend,
  notAllowed,
  tooManyRequests,
  unknown;

  /// Vertaalt een Postgres-fout. De functies gooien `P0001` met een vaste
  /// Engelse sleutel; hernoemen via een update geeft bij een ongeldige naam
  /// een check violation (`23514`). Al het andere is [unknown].
  static GroupError fromPostgres({String? code, String? message}) {
    if (code == '23514') return GroupError.groupNameInvalid;
    if (code != 'P0001') return GroupError.unknown;
    return switch (message) {
      'group_full' => GroupError.groupFull,
      'too_many_groups' => GroupError.tooManyGroups,
      'invite_invalid' => GroupError.inviteInvalid,
      'last_admin' => GroupError.lastAdmin,
      'group_name_invalid' => GroupError.groupNameInvalid,
      'not_authenticated' => GroupError.notAuthenticated,
      'not_member' => GroupError.notMember,
      'not_friend' => GroupError.notFriend,
      'not_allowed' => GroupError.notAllowed,
      'too_many_requests' => GroupError.tooManyRequests,
      _ => GroupError.unknown,
    };
  }
}

class GroupException implements Exception {
  const GroupException(this.error);

  final GroupError error;

  /// Voor debugPrint, nooit voor de gebruiker.
  @override
  String toString() => 'GroupException(${error.name})';
}
