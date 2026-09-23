// test/domain/models/peloton_group_test.dart
//
// Pint de regels van de groepsmodellen (fase 34) vast: rollen, aanvragen,
// sortering, opvolging bij vertrek (spiegel van ensure_group_admin in 0012),
// initialen en de vertaling van databasefoutsleutels (0012 + 0013).

import 'package:test/test.dart';

import 'package:ridewindow/domain/models/peloton_group.dart';

Map<String, dynamic> _member(
  String userId, {
  String role = 'member',
  String joinedAt = '2026-09-01T10:00:00Z',
  String? name,
}) =>
    {
      'group_id': 'g1',
      'user_id': userId,
      'role': role,
      'display_name': name ?? userId,
      'joined_at': joinedAt,
    };

Map<String, dynamic> _request(
  String id,
  String userId, {
  String? proposedBy,
  String createdAt = '2026-09-02T10:00:00Z',
}) =>
    {
      'id': id,
      'group_id': 'g1',
      'user_id': userId,
      'proposed_by': proposedBy,
      'display_name': 'Naam $userId',
      'proposed_by_name': proposedBy == null ? null : 'Voordrager',
      'created_at': createdAt,
    };

const _groupRow = <String, dynamic>{
  'id': 'g1',
  'name': 'Dinsdagclub',
  'created_at': '2026-09-01T09:00:00Z',
};

PelotonGroup _group(
  List<Map<String, dynamic>> members, [
  List<Map<String, dynamic>> requests = const [],
]) =>
    PelotonGroup.fromRows(_groupRow, members, requests);

void main() {
  group('GroupRole en GroupJoinStatus', () {
    test('admin is admin, al het andere member', () {
      expect(GroupRole.fromRow('admin'), GroupRole.admin);
      expect(GroupRole.fromRow('member'), GroupRole.member);
      expect(GroupRole.fromRow(null), GroupRole.member);
      expect(GroupRole.fromRow('owner'), GroupRole.member);
      expect(GroupRole.admin.row, 'admin');
      expect(GroupRole.member.row, 'member');
    });

    test('member is member, al het andere requested', () {
      expect(GroupJoinStatus.fromRow('member'), GroupJoinStatus.member);
      expect(GroupJoinStatus.fromRow('requested'), GroupJoinStatus.requested);
      expect(GroupJoinStatus.fromRow(null), GroupJoinStatus.requested);
    });
  });

  group('GroupMember', () {
    test('fromRow leest alle velden en zet de tijd lokaal', () {
      final m = GroupMember.fromRow(
        _member('u1', role: 'admin', name: 'Anna'),
      );
      expect(m.groupId, 'g1');
      expect(m.userId, 'u1');
      expect(m.role, GroupRole.admin);
      expect(m.isAdmin, isTrue);
      expect(m.displayName, 'Anna');
      expect(m.joinedAt.isUtc, isFalse);
      expect(m.joinedAt.toUtc(), DateTime.utc(2026, 9, 1, 10));
    });

    test('label valt terug bij null of alleen spaties', () {
      final base = _member('u1');
      expect(
        GroupMember.fromRow({...base, 'display_name': null}).label('Fietser'),
        'Fietser',
      );
      expect(
        GroupMember.fromRow({...base, 'display_name': '  '}).label('Fietser'),
        'Fietser',
      );
      expect(
        GroupMember.fromRow({...base, 'display_name': ' Bo '}).label('F'),
        'Bo',
      );
    });
  });

  group('GroupJoinRequest', () {
    test('fromRow leest alle velden; via link als proposed_by null is', () {
      final viaLink = GroupJoinRequest.fromRow(_request('r1', 'u9'));
      expect(viaLink.id, 'r1');
      expect(viaLink.groupId, 'g1');
      expect(viaLink.userId, 'u9');
      expect(viaLink.proposedBy, isNull);
      expect(viaLink.proposedByName, isNull);
      expect(viaLink.displayName, 'Naam u9');
      expect(viaLink.isViaLink, isTrue);
      expect(viaLink.createdAt.toUtc(), DateTime.utc(2026, 9, 2, 10));

      final proposed =
          GroupJoinRequest.fromRow(_request('r2', 'u8', proposedBy: 'u1'));
      expect(proposed.isViaLink, isFalse);
      expect(proposed.proposedBy, 'u1');
      expect(proposed.proposedByName, 'Voordrager');
    });

    test('label valt terug zonder naam', () {
      final r = GroupJoinRequest.fromRow(
        {..._request('r1', 'u9'), 'display_name': null},
      );
      expect(r.label('Fietser'), 'Fietser');
    });
  });

  group('PelotonGroup', () {
    test('fromRows sorteert beheerders eerst, dan joinedAt, dan userId', () {
      final g = _group([
        _member('u3', joinedAt: '2026-09-03T10:00:00Z'),
        _member('u2', joinedAt: '2026-09-02T10:00:00Z'),
        _member('u9', role: 'admin', joinedAt: '2026-09-05T10:00:00Z'),
        _member('u1', joinedAt: '2026-09-02T10:00:00Z'),
      ]);
      expect(g.members.map((m) => m.userId), ['u9', 'u1', 'u2', 'u3']);
      expect(g.id, 'g1');
      expect(g.name, 'Dinsdagclub');
      expect(g.createdAt.toUtc(), DateTime.utc(2026, 9, 1, 9));
      expect(g.memberCount, 4);
      expect(g.adminCount, 1);
      expect(g.initials, 'DI');
    });

    test('aanvragen op createdAt oplopend', () {
      final g = _group(
        [_member('u1', role: 'admin')],
        [
          _request('r2', 'u8', createdAt: '2026-09-04T10:00:00Z'),
          _request('r1', 'u7', createdAt: '2026-09-03T10:00:00Z'),
        ],
      );
      expect(g.requests.map((r) => r.id), ['r1', 'r2']);
    });

    test('isMember, isAdmin, memberFor, isPendingFor, requestFor', () {
      final g = _group(
        [_member('u1', role: 'admin'), _member('u2')],
        [_request('r1', 'u7')],
      );
      expect(g.isMember('u1'), isTrue);
      expect(g.isMember('u7'), isFalse);
      expect(g.isAdmin('u1'), isTrue);
      expect(g.isAdmin('u2'), isFalse);
      expect(g.memberFor('u2')?.userId, 'u2');
      expect(g.memberFor('u7'), isNull);
      expect(g.isPendingFor('u7'), isTrue);
      expect(g.isPendingFor('u1'), isFalse);
      expect(g.requestFor('u7')?.id, 'r1');
      expect(g.requestFor('u2'), isNull);
    });

    test('alles false of null bij uid null', () {
      final g = _group(
        [_member('u1', role: 'admin')],
        [_request('r1', 'u7')],
      );
      expect(g.isMember(null), isFalse);
      expect(g.isAdmin(null), isFalse);
      expect(g.memberFor(null), isNull);
      expect(g.isPendingFor(null), isFalse);
      expect(g.requestFor(null), isNull);
    });

    test('openRequests laat je eigen aanvraag weg', () {
      final g = _group(
        [_member('u1', role: 'admin')],
        [_request('r1', 'u7'), _request('r2', 'u8')],
      );
      expect(g.openRequests('u7').map((r) => r.id), ['r2']);
      expect(g.openRequests('u1').map((r) => r.id), ['r1', 'r2']);
      expect(g.openRequests(null).map((r) => r.id), ['r1', 'r2']);
    });

    test('successorIfLeaving: null voor geen beheerder of andere beheerder', () {
      final g = _group([
        _member('u1', role: 'admin'),
        _member('u2', role: 'admin'),
        _member('u3'),
      ]);
      expect(g.successorIfLeaving('u3'), isNull);
      expect(g.successorIfLeaving('u1'), isNull);
      expect(g.successorIfLeaving(null), isNull);
    });

    test('successorIfLeaving: null als je het enige lid bent', () {
      final g = _group([_member('u1', role: 'admin')]);
      expect(g.successorIfLeaving('u1'), isNull);
      expect(g.isLastMember('u1'), isTrue);
    });

    test('successorIfLeaving: vroegste joinedAt, bij gelijkspel kleinste id',
        () {
      final g = _group([
        _member('u1', role: 'admin', joinedAt: '2026-09-01T08:00:00Z'),
        _member('u5', joinedAt: '2026-09-03T10:00:00Z'),
        _member('u4', joinedAt: '2026-09-02T10:00:00Z'),
        _member('u3', joinedAt: '2026-09-02T10:00:00Z'),
      ]);
      expect(g.successorIfLeaving('u1')?.userId, 'u3');
      expect(g.isLastMember('u1'), isFalse);
    });

    test('isFull vanaf kGroupMaxMembers', () {
      final full = _group([
        for (var i = 0; i < kGroupMaxMembers; i++) _member('u$i'),
      ]);
      expect(full.isFull, isTrue);
      final almost = _group([
        for (var i = 0; i < kGroupMaxMembers - 1; i++) _member('u$i'),
      ]);
      expect(almost.isFull, isFalse);
    });

    test('grenzen spiegelen 0012 en 0013', () {
      expect(kGroupMaxMembers, 30);
      expect(kMaxGroupsPerAccount, 10);
      expect(kMaxOpenRequestsPerGroup, 30);
      expect(kGroupNameMaxLength, 40);
    });
  });

  group('groupInitials', () {
    test('een woord geeft de eerste twee tekens', () {
      expect(groupInitials('Dinsdagclub'), 'DI');
      expect(groupInitials('Buren'), 'BU');
    });

    test('meerdere woorden geven de eerste letter van de eerste twee', () {
      expect(groupInitials('De Zaterdagclub'), 'DZ');
      expect(groupInitials('de  zaterdag club'), 'DZ');
    });

    test('kort of leeg', () {
      expect(groupInitials('  x '), 'X');
      expect(groupInitials(''), '?');
      expect(groupInitials('   '), '?');
    });

    test('grafeem-veilig: een emoji blijft heel', () {
      expect(groupInitials('🚴 Club'), '🚴C');
      expect(groupInitials('🚴‍♀️'), '🚴‍♀️');
    });
  });

  group('GroupError.fromPostgres', () {
    test('alle tien sleutels', () {
      const cases = {
        'group_full': GroupError.groupFull,
        'too_many_groups': GroupError.tooManyGroups,
        'invite_invalid': GroupError.inviteInvalid,
        'last_admin': GroupError.lastAdmin,
        'group_name_invalid': GroupError.groupNameInvalid,
        'not_authenticated': GroupError.notAuthenticated,
        'not_member': GroupError.notMember,
        'not_friend': GroupError.notFriend,
        'not_allowed': GroupError.notAllowed,
        'too_many_requests': GroupError.tooManyRequests,
      };
      for (final entry in cases.entries) {
        expect(
          GroupError.fromPostgres(code: 'P0001', message: entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('23514 is een ongeldige naam; de rest onbekend', () {
      expect(
        GroupError.fromPostgres(code: '23514', message: 'check violation'),
        GroupError.groupNameInvalid,
      );
      expect(
        GroupError.fromPostgres(code: 'P0001', message: 'iets_anders'),
        GroupError.unknown,
      );
      expect(
        GroupError.fromPostgres(code: '42501', message: 'group_full'),
        GroupError.unknown,
      );
      expect(GroupError.fromPostgres(), GroupError.unknown);
    });

    test('GroupException.toString geeft de enumnaam', () {
      expect(
        const GroupException(GroupError.lastAdmin).toString(),
        contains('lastAdmin'),
      );
    });
  });
}
