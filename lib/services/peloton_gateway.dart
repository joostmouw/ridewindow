import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/data/remote/supabase_tables.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/services/invite_code.dart';

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

    return rides
        .map(
          (r) => GroupRide.fromRow(
            r,
            participants: byRide[r['id'] as String] ?? const [],
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
}
