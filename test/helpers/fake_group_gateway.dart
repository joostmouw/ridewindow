// test/helpers/fake_group_gateway.dart
//
// Gedeelde fake voor de groepstests van fase 34. Houdt groepen, leden en
// aanvragen in het geheugen en past ze aan zoals 0012 + 0013 dat in de
// database doen: create maakt je beheerder, een beheerder die voordraagt maakt
// direct lid, een lid maakt een aanvraag, accepteren maakt lid, en bij vertrek
// van de laatste beheerder wordt het langst zittende lid beheerder.
//
// Elke aanroep komt als leesbare regel in [FakeGroupGateway.calls], zodat een
// widgettest kan toetsen wat er gebeurde zonder de staat na te rekenen.

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/services/peloton_gateway.dart';

class FakeGroupGateway implements PelotonGateway {
  FakeGroupGateway({
    Map<String, PelotonGroup>? groups,
    List<Friend>? friends,
    this.me = 'uid-me',
    this.myName = 'Ik',
  })  : groups = groups ?? {},
        friends = friends ?? [];

  /// De in-memory database, op groeps-id.
  final Map<String, PelotonGroup> groups;
  final List<Friend> friends;

  /// De ingelogde gebruiker.
  String me;
  String myName;

  /// Leesbaar logboek, bijv. `createGroup:Dinsdagclub`.
  final List<String> calls = [];

  /// Methode-naam -> fout: die methode gooit dan een [GroupException].
  final Map<String, GroupError> failWith = {};

  /// Wat [redeemGroupInvite] teruggeeft; standaard een aanvraag (0013).
  GroupJoinStatus redeemStatus = GroupJoinStatus.requested;

  /// Code -> groeps-id. [groupInviteCode] vult dit; een test mag het ook.
  final Map<String, String> inviteCodes = {};

  var _seq = 0;

  // --- bouwhelpers ---------------------------------------------------------

  static final DateTime baseDate = DateTime(2026, 9, 1, 10);

  static GroupMember member(
    String userId, {
    String groupId = 'g1',
    GroupRole role = GroupRole.member,
    String? name,
    int joinedDay = 0,
  }) =>
      GroupMember(
        groupId: groupId,
        userId: userId,
        role: role,
        displayName: name ?? userId,
        joinedAt: baseDate.add(Duration(days: joinedDay)),
      );

  static GroupJoinRequest request(
    String id,
    String userId, {
    String groupId = 'g1',
    String? proposedBy,
    String? proposedByName,
    String? name,
    int createdDay = 0,
  }) =>
      GroupJoinRequest(
        id: id,
        groupId: groupId,
        userId: userId,
        proposedBy: proposedBy,
        proposedByName: proposedByName,
        displayName: name ?? userId,
        createdAt: baseDate.add(Duration(days: createdDay)),
      );

  static PelotonGroup group(
    String id,
    String name, {
    List<GroupMember> members = const [],
    List<GroupJoinRequest> requests = const [],
  }) =>
      PelotonGroup(
        id: id,
        name: name,
        createdAt: baseDate,
        members: members,
        requests: requests,
      );

  // --- intern --------------------------------------------------------------

  void _maybeFail(String method) {
    final error = failWith[method];
    if (error != null) throw GroupException(error);
  }

  PelotonGroup _require(String groupId) {
    final g = groups[groupId];
    if (g == null) throw const GroupException(GroupError.notAllowed);
    return g;
  }

  void _put(
    PelotonGroup g, {
    List<GroupMember>? members,
    List<GroupJoinRequest>? requests,
  }) {
    groups[g.id] = PelotonGroup(
      id: g.id,
      name: g.name,
      createdAt: g.createdAt,
      members: members ?? g.members,
      requests: requests ?? g.requests,
    );
  }

  GroupMember _newMember(String groupId, String userId, String? name) =>
      GroupMember(
        groupId: groupId,
        userId: userId,
        role: GroupRole.member,
        displayName: name,
        joinedAt: baseDate.add(Duration(days: 100 + _seq++)),
      );

  /// Spiegel van ensure_group_admin: verwijderen, opvolgen, of opheffen.
  void _removeMember(PelotonGroup g, String userId) {
    final rest = g.members.where((m) => m.userId != userId).toList();
    if (rest.isEmpty) {
      groups.remove(g.id);
      return;
    }
    if (!rest.any((m) => m.isAdmin)) {
      final successor = g.successorIfLeaving(userId) ??
          (rest.toList()
                ..sort((a, b) {
                  final c = a.joinedAt.compareTo(b.joinedAt);
                  return c != 0 ? c : a.userId.compareTo(b.userId);
                }))
              .first;
      for (var i = 0; i < rest.length; i++) {
        if (rest[i].userId == successor.userId) {
          rest[i] = _withRole(rest[i], GroupRole.admin);
        }
      }
    }
    _put(g, members: rest);
  }

  GroupMember _withRole(GroupMember m, GroupRole role) => GroupMember(
        groupId: m.groupId,
        userId: m.userId,
        role: role,
        displayName: m.displayName,
        joinedAt: m.joinedAt,
      );

  String? _friendName(String userId) {
    for (final f in friends) {
      if (f.userId == userId) return f.displayName;
    }
    return null;
  }

  // --- PelotonGateway ------------------------------------------------------

  @override
  Future<List<Friend>> listFriends() async => friends;

  @override
  Future<List<GroupRide>> listGroupRides() async => const [];

  @override
  Future<List<PelotonGroup>> listGroups() async {
    calls.add('listGroups');
    _maybeFail('listGroups');
    return groups.values.toList();
  }

  @override
  Future<String> createGroup(String name) async {
    calls.add('createGroup:$name');
    _maybeFail('createGroup');
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60) {
      throw const GroupException(GroupError.groupNameInvalid);
    }
    final id = 'g-new-${++_seq}';
    groups[id] = PelotonGroup(
      id: id,
      name: trimmed,
      createdAt: baseDate,
      members: [
        GroupMember(
          groupId: id,
          userId: me,
          role: GroupRole.admin,
          displayName: myName,
          joinedAt: baseDate,
        ),
      ],
    );
    return id;
  }

  @override
  Future<void> renameGroup({
    required String groupId,
    required String name,
  }) async {
    calls.add('renameGroup:$groupId:$name');
    _maybeFail('renameGroup');
    final g = _require(groupId);
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60) {
      throw const GroupException(GroupError.groupNameInvalid);
    }
    groups[groupId] = PelotonGroup(
      id: g.id,
      name: trimmed,
      createdAt: g.createdAt,
      members: g.members,
      requests: g.requests,
    );
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    calls.add('deleteGroup:$groupId');
    _maybeFail('deleteGroup');
    groups.remove(groupId);
  }

  @override
  Future<void> setGroupMemberRole({
    required String groupId,
    required String userId,
    required GroupRole role,
  }) async {
    calls.add('setGroupMemberRole:$groupId:$userId:${role.row}');
    _maybeFail('setGroupMemberRole');
    final g = _require(groupId);
    final target = g.memberFor(userId);
    if (target == null) return;
    if (target.isAdmin && role == GroupRole.member && g.adminCount == 1) {
      throw const GroupException(GroupError.lastAdmin);
    }
    _put(
      g,
      members: [
        for (final m in g.members) m.userId == userId ? _withRole(m, role) : m,
      ],
    );
  }

  @override
  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    calls.add('removeGroupMember:$groupId:$userId');
    _maybeFail('removeGroupMember');
    _removeMember(_require(groupId), userId);
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    calls.add('leaveGroup:$groupId');
    _maybeFail('leaveGroup');
    _removeMember(_require(groupId), me);
  }

  @override
  Future<GroupJoinStatus> proposeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    calls.add('proposeGroupMember:$groupId:$userId');
    _maybeFail('proposeGroupMember');
    final g = _require(groupId);
    if (!g.isMember(me)) throw const GroupException(GroupError.notMember);
    if (!friends.any((f) => f.userId == userId)) {
      throw const GroupException(GroupError.notFriend);
    }
    if (g.isMember(userId)) return GroupJoinStatus.member;
    if (g.isAdmin(me)) {
      if (g.isFull) throw const GroupException(GroupError.groupFull);
      _put(
        g,
        members: [
          ...g.members,
          _newMember(groupId, userId, _friendName(userId))
        ],
        requests: g.requests.where((r) => r.userId != userId).toList(),
      );
      return GroupJoinStatus.member;
    }
    if (g.requestFor(userId) != null) return GroupJoinStatus.requested;
    if (g.isFull) throw const GroupException(GroupError.groupFull);
    if (g.requests.length >= kMaxOpenRequestsPerGroup) {
      throw const GroupException(GroupError.tooManyRequests);
    }
    _put(
      g,
      requests: [
        ...g.requests,
        GroupJoinRequest(
          id: 'r-new-${++_seq}',
          groupId: groupId,
          userId: userId,
          proposedBy: me,
          proposedByName: g.memberFor(me)?.displayName ?? myName,
          displayName: _friendName(userId),
          createdAt: baseDate.add(Duration(days: 100 + _seq)),
        ),
      ],
    );
    return GroupJoinStatus.requested;
  }

  @override
  Future<void> acceptGroupRequest(String requestId) async {
    calls.add('acceptGroupRequest:$requestId');
    _maybeFail('acceptGroupRequest');
    for (final g in groups.values.toList()) {
      final matches = g.requests.where((r) => r.id == requestId);
      if (matches.isEmpty) continue;
      if (!g.isAdmin(me)) throw const GroupException(GroupError.notAllowed);
      final r = matches.first;
      if (!g.isMember(r.userId) && g.isFull) {
        throw const GroupException(GroupError.groupFull);
      }
      _put(
        g,
        members: g.isMember(r.userId)
            ? g.members
            : [...g.members, _newMember(g.id, r.userId, r.displayName)],
        requests: g.requests.where((x) => x.id != requestId).toList(),
      );
      return;
    }
    throw const GroupException(GroupError.notAllowed);
  }

  @override
  Future<void> deleteGroupRequest(String requestId) async {
    calls.add('deleteGroupRequest:$requestId');
    _maybeFail('deleteGroupRequest');
    for (final g in groups.values.toList()) {
      if (g.requests.any((r) => r.id == requestId)) {
        _put(
          g,
          requests: g.requests.where((r) => r.id != requestId).toList(),
        );
      }
    }
  }

  @override
  Future<String> groupInviteCode(String groupId) async {
    calls.add('groupInviteCode:$groupId');
    _maybeFail('groupInviteCode');
    for (final e in inviteCodes.entries) {
      if (e.value == groupId) return e.key;
    }
    final code = 'GRPCODE${++_seq}';
    inviteCodes[code] = groupId;
    return code;
  }

  @override
  Future<String> replaceGroupInvite(String groupId) async {
    calls.add('replaceGroupInvite:$groupId');
    _maybeFail('replaceGroupInvite');
    inviteCodes.removeWhere((_, v) => v == groupId);
    final code = 'GRPCODE${++_seq}';
    inviteCodes[code] = groupId;
    return code;
  }

  @override
  Future<({String groupId, String? groupName, GroupJoinStatus status})>
      redeemGroupInvite(String code) async {
    calls.add('redeemGroupInvite:$code');
    _maybeFail('redeemGroupInvite');
    final groupId = inviteCodes[code.trim().toUpperCase()];
    final g = groupId == null ? null : groups[groupId];
    if (g == null) throw const GroupException(GroupError.inviteInvalid);
    if (g.isMember(me)) {
      return (groupId: g.id, groupName: g.name, status: GroupJoinStatus.member);
    }
    if (redeemStatus == GroupJoinStatus.member) {
      _put(g, members: [...g.members, _newMember(g.id, me, myName)]);
    } else if (g.requestFor(me) == null) {
      _put(
        g,
        requests: [
          ...g.requests,
          GroupJoinRequest(
            id: 'r-new-${++_seq}',
            groupId: g.id,
            userId: me,
            displayName: myName,
            createdAt: baseDate.add(Duration(days: 100 + _seq)),
          ),
        ],
      );
    }
    return (groupId: g.id, groupName: g.name, status: redeemStatus);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} niet nodig');
}
