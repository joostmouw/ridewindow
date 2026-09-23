import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/data/remote/supabase_tables.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/domain/services/invite_code.dart';

/// Hoe lang een nieuwe groepslink geldig is.
///
/// Langer dan de 14 dagen van een maatjeslink: een clublink staat een tijd in
/// een WhatsApp-groep. Intrekken kan altijd via
/// [PelotonGateway.replaceGroupInvite].
const kGroupInviteValidity = Duration(days: 30);

/// Een bestaande groepslink wordt hergebruikt zolang hij nog minstens zo lang
/// geldig is; anders komt er een nieuwe. Zo deelt niet elk lid een eigen code,
/// en werkt een net gedeelde link niet morgen al niet meer.
const kGroupInviteMinRemaining = Duration(days: 7);

/// De cloudkant van epic "Peloton", als vervangbare poort.
///
/// Zelfde vorm en dezelfde reden als [CloudSyncGateway] (backlog #60): fase 21
/// heeft vijf keer aangetoond dat code die zelf naar `Supabase.instance.client`
/// grijpt, van buitenaf niet te toetsen is en dus pas op een toestel stukgaat.
/// Deze laag begint mét die naad in plaats van hem later te moeten inbouwen.
abstract class PelotonGateway {
  /// Je maatjes, via `friend_profiles()` — niet via een select op `profiles`,
  /// want die tabel blijft dicht (zie `0002_peloton.sql`, keuze 2).
  Future<List<Friend>> listFriends();

  /// Maakt een deellink-code aan en geeft hem terug.
  Future<String> createFriendInvite({Duration validFor});

  /// Verzilvert een code en geeft het nieuwe maatje terug.
  Future<Friend> redeemFriendInvite(String code);

  Future<void> removeFriend(String friendId);

  /// Alle gedeelde ritten die je mag zien: die van jezelf plus die waar je voor
  /// uitgenodigd bent. Het filter zit in RLS, niet in deze query — dat is
  /// precies de bedoeling.
  Future<List<GroupRide>> listGroupRides();

  Future<GroupRide> createGroupRide({
    required DateTime start,
    required DateTime end,
    required double plannedScore,
    String? ownerName,
    String? note,
  });

  Future<void> inviteToRide({
    required String rideId,
    required String friendId,
    String? displayName,
  });

  /// Antwoorden op een uitnodiging. Kan alleen namens jezelf — dat staat in de
  /// policy, niet alleen hier.
  Future<void> respondToRide({
    required String rideId,
    required bool accepted,
  });

  Future<void> deleteGroupRide(String rideId);

  /// Legt vensters voor bij een rit (slice 2 van epic #65).
  ///
  /// Vervangt wat er lag: een tweede ronde voorleggen is een nieuwe vraag, en
  /// oude opties die half blijven staan zijn onnavolgbaar voor wie al gestemd
  /// had. De stemmen gaan mee weg via `on delete cascade`.
  Future<List<RideOption>> proposeOptions({
    required String rideId,
    required List<({DateTime start, DateTime end, double plannedScore})>
        windows,
  });

  /// Stemmen op een venster. Kan alleen namens jezelf -- dat staat in de
  /// policy, niet alleen hier. Nog een keer stemmen overschrijft je antwoord.
  Future<void> voteOnOption({
    required String optionId,
    required bool canRide,
  });

  /// De eigenaar hakt de knoop door: de rit verhuist naar dit venster en de
  /// keuze verdwijnt.
  Future<void> chooseOption({
    required String rideId,
    required RideOption option,
  });

  // --- Clubs (v4.2), migraties 0012 en 0013 -------------------------------
  //
  // Elke groepsmethode gooit bij een bekende databasefout een
  // [GroupException]; de UI maakt daar met `groupErrorTextOf` een zin van.

  /// Alle groepen die je mag zien: waar je lid bent, en waar je een open
  /// aanvraag hebt (0013, keuze c). Leden en aanvragen alleen zoals RLS ze
  /// levert; expliciete kolommen, nooit `*` (CLUB-05).
  Future<List<PelotonGroup>> listGroups();

  /// Rpc `create_group`: maakt de groep en jou beheerder, geeft het id terug.
  /// Er is geen client-insert op `groups`.
  Future<String> createGroup(String name);

  /// Alleen beheerders; de kolomgrant staat alleen `name` toe. Een ongeldige
  /// naam geeft een check violation (23514).
  Future<void> renameGroup({required String groupId, required String name});

  /// Alleen beheerders. Ritten met antwoorden blijven bestaan zonder label.
  Future<void> deleteGroup(String groupId);

  /// Alleen beheerders; de kolomgrant staat alleen `role` toe. De enige
  /// beheerder die zichzelf degradeert krijgt `last_admin`.
  Future<void> setGroupMemberRole({
    required String groupId,
    required String userId,
    required GroupRole role,
  });

  /// Een beheerder haalt iemand eruit. Is dat de laatste beheerder, dan wordt
  /// het langst zittende lid beheerder (`ensure_group_admin`).
  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  });

  /// Jezelf verwijderen; opvolging zoals bij [removeGroupMember].
  Future<void> leaveGroup(String groupId);

  /// Rpc `propose_group_member`: een lid draagt een eigen maatje voor (een
  /// aanvraag), een beheerder maakt hem direct lid (0013, keuze e). Dit is
  /// het enige pad om iemand toe te voegen: de app doet geen client-insert in
  /// `group_members`.
  Future<GroupJoinStatus> proposeGroupMember({
    required String groupId,
    required String userId,
  });

  /// Rpc `accept_group_request`: alleen een beheerder van de groep. Een
  /// verdwenen aanvraag geeft `not_allowed`.
  Future<void> acceptGroupRequest(String requestId);

  /// Afwijzen (beheerder) of intrekken (aanvrager of voordrager). RLS beslist
  /// wie; er is geen status-kolom, de rij verdwijnt.
  Future<void> deleteGroupRequest(String requestId);

  /// De groepslink van deze groep: een bestaande die nog minstens
  /// [kGroupInviteMinRemaining] geldig is, anders een nieuwe van
  /// [kGroupInviteValidity]. Ieder lid mag dit (0013, keuze d).
  Future<String> groupInviteCode(String groupId);

  /// Trekt alle links van de groep in en maakt een nieuwe. Intrekken is
  /// beheerderswerk (RLS op delete).
  Future<String> replaceGroupInvite(String groupId);

  /// Rpc `redeem_group_invite`: wie al lid is krijgt `member`, anders wordt
  /// het een aanvraag (`requested`).
  Future<({String groupId, String? groupName, GroupJoinStatus status})>
      redeemGroupInvite(String code);
}

class SupabasePelotonGateway implements PelotonGateway {
  const SupabasePelotonGateway();

  /// Getter, geen veld — `Supabase.instance` gooit als er nog niets
  /// geïnitialiseerd is, en dat mag pas gebeuren op het moment van de aanroep.
  /// Zie [SupabaseCloudSyncGateway] voor de dag die dat plan 21-11 gekost heeft.
  SupabaseClient get _client => Supabase.instance.client;

  String get _uid {
    final id = _client.auth.currentSession?.user.id;
    if (id == null) throw StateError('Peloton vereist een ingelogde gebruiker');
    return id;
  }

  @override
  Future<List<Friend>> listFriends() async {
    final rows = await _client.rpc(kFriendProfilesRpc);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Friend.fromRow)
        .toList();
  }

  @override
  Future<String> createFriendInvite({
    Duration validFor = const Duration(days: 14),
  }) async {
    final code = generateInviteCode();
    await _client.from(kFriendInvitesTable).insert({
      'code': code,
      'inviter_id': _uid,
      'expires_at': DateTime.now().toUtc().add(validFor).toIso8601String(),
    });
    return code;
  }

  @override
  Future<Friend> redeemFriendInvite(String code) async {
    final rows = await _client.rpc(
      kRedeemFriendInviteRpc,
      params: {'p_code': normalizeInviteCode(code)},
    );
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      throw StateError('uitnodiging bestaat niet of is verlopen');
    }
    final row = list.first;
    return Friend(
      userId: row['friend_id'] as String,
      displayName: row['friend_name'] as String?,
    );
  }

  @override
  Future<void> removeFriend(String friendId) async {
    // De rij staat in canonieke volgorde opgeslagen, dus welke van de twee
    // kolommen ik ben hangt af van de uid-vergelijking. `or` op beide
    // volgordes is korter dan hier de sortering nabouwen.
    final me = _uid;
    await _client.from(kFriendshipsTable).delete().or(
          'and(user_a.eq.$me,user_b.eq.$friendId),'
          'and(user_a.eq.$friendId,user_b.eq.$me)',
        );
  }

  @override
  Future<List<GroupRide>> listGroupRides() async {
    final rideRows = await _client
        .from(kGroupRidesTable)
        .select()
        .order('start_at', ascending: true);
    final rides = (rideRows as List).cast<Map<String, dynamic>>();
    if (rides.isEmpty) return const [];

    final participantRows =
        await _client.from(kGroupRideParticipantsTable).select();
    final byRide = <String, List<RideParticipant>>{};
    for (final row in (participantRows as List).cast<Map<String, dynamic>>()) {
      (byRide[row['ride_id'] as String] ??= [])
          .add(RideParticipant.fromRow(row));
    }

    // Opties en stemmen in twee vaste rondgangen, niet een per rit: RLS
    // levert toch alleen wat je mag zien, en een lus over ritten zou bij tien
    // gedeelde ritten twintig verzoeken doen.
    final optionRows = await _client
        .from(kGroupRideOptionsTable)
        .select()
        .order('start_at', ascending: true);
    final options = (optionRows as List).cast<Map<String, dynamic>>();

    final votesByOption = <String, List<OptionVote>>{};
    if (options.isNotEmpty) {
      final voteRows = await _client.from(kGroupRideOptionVotesTable).select();
      for (final row in (voteRows as List).cast<Map<String, dynamic>>()) {
        (votesByOption[row['option_id'] as String] ??= [])
            .add(OptionVote.fromRow(row));
      }
    }

    final optionsByRide = <String, List<RideOption>>{};
    for (final row in options) {
      final id = row['id'] as String;
      (optionsByRide[row['ride_id'] as String] ??= []).add(
        RideOption.fromRow(row, votes: votesByOption[id] ?? const []),
      );
    }

    return rides
        .map(
          (r) => GroupRide.fromRow(
            r,
            participants: byRide[r['id'] as String] ?? const [],
            options: optionsByRide[r['id'] as String] ?? const [],
          ),
        )
        .toList();
  }

  @override
  Future<GroupRide> createGroupRide({
    required DateTime start,
    required DateTime end,
    required double plannedScore,
    String? ownerName,
    String? note,
  }) async {
    // Expliciet UTC (de les van plan 21-13): een offsetloze string leest
    // Postgres in de sessiezone, waardoor een rit van 20:00 lokaal als 20:00
    // UTC opgeslagen wordt -- hetzelfde klokgetal, twee uur verschoven.
    final row = await _client
        .from(kGroupRidesTable)
        .insert({
          'owner_id': _uid,
          'start_at': start.toUtc().toIso8601String(),
          'end_at': end.toUtc().toIso8601String(),
          'planned_score': plannedScore,
          'owner_name': ownerName,
          'note': note,
        })
        .select()
        .single();
    return GroupRide.fromRow(row);
  }

  @override
  Future<void> inviteToRide({
    required String rideId,
    required String friendId,
    String? displayName,
  }) async {
    await _client.from(kGroupRideParticipantsTable).insert({
      'ride_id': rideId,
      'user_id': friendId,
      'display_name': displayName,
      'status': ParticipantStatus.invited.row,
    });
  }

  @override
  Future<void> respondToRide({
    required String rideId,
    required bool accepted,
  }) async {
    await _client
        .from(kGroupRideParticipantsTable)
        .update({
          'status': accepted
              ? ParticipantStatus.accepted.row
              : ParticipantStatus.declined.row,
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('ride_id', rideId)
        .eq('user_id', _uid);
  }

  @override
  Future<void> deleteGroupRide(String rideId) async {
    await _client.from(kGroupRidesTable).delete().eq('id', rideId);
  }

  @override
  Future<List<RideOption>> proposeOptions({
    required String rideId,
    required List<({DateTime start, DateTime end, double plannedScore})>
        windows,
  }) async {
    await _client.from(kGroupRideOptionsTable).delete().eq('ride_id', rideId);
    if (windows.isEmpty) return const [];

    // Expliciet UTC, dezelfde les als in createGroupRide: een offsetloze
    // string leest Postgres in de sessiezone.
    final rows = await _client
        .from(kGroupRideOptionsTable)
        .insert([
          for (final w in windows)
            {
              'ride_id': rideId,
              'start_at': w.start.toUtc().toIso8601String(),
              'end_at': w.end.toUtc().toIso8601String(),
              'planned_score': w.plannedScore,
            },
        ])
        .select();
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map((r) => RideOption.fromRow(r))
        .toList();
  }

  @override
  Future<void> voteOnOption({
    required String optionId,
    required bool canRide,
  }) async {
    await _client.from(kGroupRideOptionVotesTable).upsert({
      'option_id': optionId,
      'user_id': _uid,
      'can_ride': canRide,
      'voted_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> chooseOption({
    required String rideId,
    required RideOption option,
  }) async {
    // Eerst de rit verzetten, dan pas de opties weghalen. Andersom zou een
    // mislukte update een rit achterlaten op de oude tijd zonder dat er nog
    // iets voorligt -- en dan is niet meer te zien wat de groep koos.
    await _client
        .from(kGroupRidesTable)
        .update({
          'start_at': option.start.toUtc().toIso8601String(),
          'end_at': option.end.toUtc().toIso8601String(),
          'planned_score': option.plannedScore,
        })
        .eq('id', rideId);
    await _client.from(kGroupRideOptionsTable).delete().eq('ride_id', rideId);
  }

  // --- Clubs (v4.2), migraties 0012 en 0013 -------------------------------

  /// Vertaalt een bekende databasefout naar een [GroupException]. Onbekende
  /// fouten gaan ongewijzigd door: die horen in de log, niet vermomd als een
  /// nette melding.
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PostgrestException catch (e) {
      final error = GroupError.fromPostgres(code: e.code, message: e.message);
      if (error == GroupError.unknown) rethrow;
      throw GroupException(error);
    }
  }

  @override
  Future<List<PelotonGroup>> listGroups() => _guard(() async {
        // Drie vaste rondgangen, geen lus per groep: RLS levert alleen wat je
        // mag zien. Expliciete kolommen (CLUB-05).
        final groupRows = (await _client
                .from(kGroupsTable)
                .select('id, name, created_at') as List)
            .cast<Map<String, dynamic>>();
        if (groupRows.isEmpty) return const <PelotonGroup>[];

        final memberRows = (await _client
                    .from(kGroupMembersTable)
                    .select('group_id, user_id, role, display_name, joined_at')
                as List)
            .cast<Map<String, dynamic>>();
        final requestRows = (await _client.from(kGroupJoinRequestsTable).select(
                  'id, group_id, user_id, proposed_by, display_name, '
                  'proposed_by_name, created_at',
                ) as List)
            .cast<Map<String, dynamic>>();

        final membersByGroup = <String, List<Map<String, dynamic>>>{};
        for (final row in memberRows) {
          (membersByGroup[row['group_id'] as String] ??= []).add(row);
        }
        final requestsByGroup = <String, List<Map<String, dynamic>>>{};
        for (final row in requestRows) {
          (requestsByGroup[row['group_id'] as String] ??= []).add(row);
        }

        return groupRows
            .map(
              (g) => PelotonGroup.fromRows(
                g,
                membersByGroup[g['id'] as String] ?? const [],
                requestsByGroup[g['id'] as String] ?? const [],
              ),
            )
            .toList();
      });

  @override
  Future<String> createGroup(String name) => _guard(() async {
        final id = await _client.rpc(
          kCreateGroupRpc,
          params: {'p_name': name.trim()},
        );
        return id as String;
      });

  @override
  Future<void> renameGroup({required String groupId, required String name}) =>
      _guard(() async {
        await _client
            .from(kGroupsTable)
            .update({'name': name.trim()}).eq('id', groupId);
      });

  @override
  Future<void> deleteGroup(String groupId) => _guard(() async {
        await _client.from(kGroupsTable).delete().eq('id', groupId);
      });

  @override
  Future<void> setGroupMemberRole({
    required String groupId,
    required String userId,
    required GroupRole role,
  }) =>
      _guard(() async {
        await _client
            .from(kGroupMembersTable)
            .update({'role': role.row})
            .eq('group_id', groupId)
            .eq('user_id', userId);
      });

  @override
  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  }) =>
      _guard(() async {
        await _client
            .from(kGroupMembersTable)
            .delete()
            .eq('group_id', groupId)
            .eq('user_id', userId);
      });

  @override
  Future<void> leaveGroup(String groupId) =>
      removeGroupMember(groupId: groupId, userId: _uid);

  @override
  Future<GroupJoinStatus> proposeGroupMember({
    required String groupId,
    required String userId,
  }) =>
      _guard(() async {
        final status = await _client.rpc(
          kProposeGroupMemberRpc,
          params: {'p_group_id': groupId, 'p_user_id': userId},
        );
        return GroupJoinStatus.fromRow(status as String?);
      });

  @override
  Future<void> acceptGroupRequest(String requestId) => _guard(() async {
        await _client.rpc(
          kAcceptGroupRequestRpc,
          params: {'p_request_id': requestId},
        );
      });

  @override
  Future<void> deleteGroupRequest(String requestId) => _guard(() async {
        await _client
            .from(kGroupJoinRequestsTable)
            .delete()
            .eq('id', requestId);
      });

  @override
  Future<String> groupInviteCode(String groupId) => _guard(() async {
        // Expliciet UTC (les 21-13).
        final threshold = DateTime.now()
            .toUtc()
            .add(kGroupInviteMinRemaining)
            .toIso8601String();
        final rows = (await _client
                .from(kGroupInvitesTable)
                .select('code, expires_at')
                .eq('group_id', groupId)
                .gt('expires_at', threshold)
                .order('expires_at', ascending: false)
                .limit(1) as List)
            .cast<Map<String, dynamic>>();
        if (rows.isNotEmpty) return rows.first['code'] as String;
        return _insertGroupInvite(groupId);
      });

  @override
  Future<String> replaceGroupInvite(String groupId) => _guard(() async {
        await _client.from(kGroupInvitesTable).delete().eq('group_id', groupId);
        return _insertGroupInvite(groupId);
      });

  /// Zonder `.select()`: insert-returning loopt tegen de select-policy aan
  /// (valkuil uit 0003, zie PELOTON.md). De code kennen we zelf al.
  Future<String> _insertGroupInvite(String groupId) async {
    final code = generateInviteCode();
    await _client.from(kGroupInvitesTable).insert({
      'code': code,
      'group_id': groupId,
      'created_by': _uid,
      'expires_at':
          DateTime.now().toUtc().add(kGroupInviteValidity).toIso8601String(),
    });
    return code;
  }

  @override
  Future<({String groupId, String? groupName, GroupJoinStatus status})>
      redeemGroupInvite(String code) => _guard(() async {
            final rows = await _client.rpc(
              kRedeemGroupInviteRpc,
              params: {'p_code': normalizeInviteCode(code)},
            );
            final list = (rows as List).cast<Map<String, dynamic>>();
            if (list.isEmpty) {
              throw const GroupException(GroupError.inviteInvalid);
            }
            final row = list.first;
            return (
              groupId: row['group_id'] as String,
              groupName: row['group_name'] as String?,
              status: GroupJoinStatus.fromRow(row['status'] as String?),
            );
          });
}
