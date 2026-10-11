import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';

/// De lokale kopie van de gedeelde ritten en groepen, per account, zodat Home
/// en de Peloton-tab bij een koude start openen op wat er de vorige keer stond
/// in plaats van op niets (bug 0a, dossier
/// `.planning/debug/planned-kaartjes-koude-start.md`).
///
/// Zo doen WhatsApp, Instagram en Strava het: het scherm opent op de kopie en
/// de server werkt stil bij. Home doet dat voor het weer al via de Drift
/// forecast-cache; voor Peloton is SharedPreferences genoeg — het zijn hooguit
/// tientallen objecten en er hoeft nooit SQL overheen.
///
/// Per account gesleuteld, zoals [SeenIdsStore]: een tweede account op
/// hetzelfde toestel erft nooit andermans ritten. De server blijft leidend;
/// de eerste geslaagde refresh overschrijft de kopie volledig.
class PelotonCacheStore {
  PelotonCacheStore(this._prefs);

  final SharedPreferences _prefs;

  static const _ridesPrefix = 'peloton.ridesCache.';
  static const _groupsPrefix = 'peloton.groupsCache.';
  static const _friendsPrefix = 'peloton.friendsCache.';

  static String ridesKeyFor(String userId) => '$_ridesPrefix$userId';
  static String groupsKeyFor(String userId) => '$_groupsPrefix$userId';
  static String friendsKeyFor(String userId) => '$_friendsPrefix$userId';

  /// `null` betekent: geen bruikbare kopie. Dat dekt "nog nooit opgehaald",
  /// maar ook corrupte of oudere JSON — wie geen cache heeft, haalt gewoon het
  /// netwerk op, precies zoals het voor deze cache was.
  List<GroupRide>? readGroupRides(String userId) {
    final raw = _prefs.getString(ridesKeyFor(userId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return [
        for (final r in decoded.cast<Map<String, dynamic>>())
          GroupRide.fromJson(r),
      ];
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGroupRides(String userId, List<GroupRide> rides) =>
      _prefs.setString(
        ridesKeyFor(userId),
        jsonEncode([for (final r in rides) r.toJson()]),
      );

  List<PelotonGroup>? readGroups(String userId) {
    final raw = _prefs.getString(groupsKeyFor(userId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return [
        for (final g in decoded.cast<Map<String, dynamic>>())
          PelotonGroup.fromJson(g),
      ];
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGroups(String userId, List<PelotonGroup> groups) =>
      _prefs.setString(
        groupsKeyFor(userId),
        jsonEncode([for (final g in groups) g.toJson()]),
      );

  List<Friend>? readFriends(String userId) {
    final raw = _prefs.getString(friendsKeyFor(userId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return [
        for (final f in decoded.cast<Map<String, dynamic>>())
          Friend.fromJson(f),
      ];
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFriends(String userId, List<Friend> friends) =>
      _prefs.setString(
        friendsKeyFor(userId),
        jsonEncode([for (final f in friends) f.toJson()]),
      );

  /// Wist de kopieën van álle accounts. Hoort bij de "start fresh"-tak van
  /// een accountwissel (D-09): wie opnieuw begint, wil ook geen oude
  /// pelotondaten meer op het toestel. De Drift forecast-cache wordt daar
  /// bewust niet aangeraakt omdat die afgeleid en accountloos is; deze kopieën
  /// zijn dat niet.
  Future<void> clearAllAccounts() async {
    for (final key in _prefs.getKeys()) {
      if (key.startsWith(_ridesPrefix) ||
          key.startsWith(_groupsPrefix) ||
          key.startsWith(_friendsPrefix)) {
        await _prefs.remove(key);
      }
    }
  }
}
