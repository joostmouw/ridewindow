import 'package:shared_preferences/shared_preferences.dart';

/// Welke maatjes je al eens op de tab Peloton hebt zien staan.
///
/// **Waarom lokaal en niet uit de database.** Een maatje komt er zonder
/// verzoek bij: `redeem_friend_invite` maakt de vriendschap meteen. Er is dus
/// niets om te accepteren, en "nieuw" kan alleen betekenen: nog niet gezien op
/// dit toestel. `friend_profiles()` geeft bewust geen `created_at` terug, en
/// daarvoor de functie verbreden zou een migratie zijn voor een kijkvoorkeur.
///
/// Per gebruiker, zodat een tweede account op hetzelfde toestel niet de
/// maatjes van het eerste als gezien erft. Eigen sleutelruimte `peloton.*`,
/// buiten de `profile.*`-synchronisatie.
class SeenFriendsStore {
  SeenFriendsStore(this._prefs);

  final SharedPreferences _prefs;

  static String keyFor(String userId) => 'peloton.seenFriends.$userId';

  /// `null` betekent: voor deze gebruiker is nog nooit iets vastgelegd. Dat is
  /// iets anders dan een lege set, want dan zijn alle maatjes nieuw.
  Set<String>? seenFor(String userId) =>
      _prefs.getStringList(keyFor(userId))?.toSet();

  Future<void> save(String userId, Iterable<String> friendIds) =>
      _prefs.setStringList(keyFor(userId), friendIds.toSet().toList()..sort());
}

/// Hoeveel maatjes er nieuw zijn. Los van opslag, zodat het zonder
/// SharedPreferences te toetsen is.
///
/// Nooit eerder vastgelegd ([seen] is `null`) telt als nul: wie de update
/// installeert, heeft zijn bestaande maatjes al lang gezien.
int unseenFriendCount({
  required Iterable<String> current,
  required Set<String>? seen,
}) {
  if (seen == null) return 0;
  return current.where((id) => !seen.contains(id)).length;
}
