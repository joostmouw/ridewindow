import 'package:shared_preferences/shared_preferences.dart';

/// Wat je al eens gezien hebt, per gebruiker, zodat het rode bolletje alleen
/// telt wat nieuw is.
///
/// **Gezien is niet hetzelfde als afgehandeld.** Zo doen Instagram, Facebook
/// en LinkedIn het: het bolletje gaat weg zodra je de plek opent waar het over
/// gaat, en wat nog een antwoord vraagt, blijft in de lijst zelf gemarkeerd
/// ("wacht op jou", de aanvragenchip). Tot build 61 telde een ritvraag tot je
/// antwoordde, en dan bleef het bolletje staan terwijl je ernaar keek.
///
/// Per gebruiker, zodat een tweede account op hetzelfde toestel niet erft wat
/// het eerste zag. Eigen sleutelruimte `peloton.*`, buiten de
/// `profile.*`-synchronisatie: dit is een kijkvoorkeur van dit toestel.
abstract class SeenIdsStore {
  SeenIdsStore(this._prefs);

  final SharedPreferences _prefs;

  String keyOf(String userId);

  /// `null` betekent: voor deze gebruiker is nog nooit iets vastgelegd. Dat is
  /// iets anders dan een lege set; wat het betekent, beslist elke soort zelf.
  Set<String>? seenFor(String userId) =>
      _prefs.getStringList(keyOf(userId))?.toSet();

  Future<void> save(String userId, Iterable<String> ids) =>
      _prefs.setStringList(keyOf(userId), ids.toSet().toList()..sort());

  /// Voegt toe in plaats van te vervangen: een ritvraag die even uit de lijst
  /// valt (netwerk, filter) mag bij terugkomst niet opnieuw als nieuw tellen.
  Future<void> add(String userId, Iterable<String> ids) =>
      save(userId, {...?seenFor(userId), ...ids});
}

/// Welke maatjes je al eens op de tab Peloton hebt zien staan.
///
/// **Waarom lokaal en niet uit de database.** Een maatje komt er zonder
/// verzoek bij: `redeem_friend_invite` maakt de vriendschap meteen. Er is dus
/// niets om te accepteren, en "nieuw" kan alleen betekenen: nog niet gezien op
/// dit toestel. `friend_profiles()` geeft bewust geen `created_at` terug, en
/// daarvoor de functie verbreden zou een migratie zijn voor een kijkvoorkeur.
class SeenFriendsStore extends SeenIdsStore {
  SeenFriendsStore(super.prefs);

  static String keyFor(String userId) => 'peloton.seenFriends.$userId';

  @override
  String keyOf(String userId) => keyFor(userId);
}

/// Welke ritvragen je al eens op de tab Ritten hebt zien staan, op
/// `RideEntry.key`.
class SeenRideInvitesStore extends SeenIdsStore {
  SeenRideInvitesStore(super.prefs);

  static String keyFor(String userId) => 'peloton.seenRideInvites.$userId';

  @override
  String keyOf(String userId) => keyFor(userId);
}

/// Welke groepsaanvragen je als beheerder al eens op de tab Peloton zag, op
/// aanvraag-id.
class SeenGroupRequestsStore extends SeenIdsStore {
  SeenGroupRequestsStore(super.prefs);

  static String keyFor(String userId) => 'peloton.seenGroupRequests.$userId';

  @override
  String keyOf(String userId) => keyFor(userId);
}

/// Wat er in [current] staat en niet in [seen]. Los van opslag, zodat het
/// zonder SharedPreferences te toetsen is.
Set<String> unseenIds({
  required Iterable<String> current,
  required Set<String> seen,
}) =>
    current.where((id) => !seen.contains(id)).toSet();

/// Hoeveel maatjes er nieuw zijn.
///
/// Nooit eerder vastgelegd ([seen] is `null`) telt als nul: wie de update van
/// build 61 installeerde, had zijn bestaande maatjes al lang gezien. Ritvragen
/// en groepsaanvragen doen dat andersom: die telden vóór die update al, dus
/// daar is nooit vastgelegd hetzelfde als niets gezien.
int unseenFriendCount({
  required Iterable<String> current,
  required Set<String>? seen,
}) {
  if (seen == null) return 0;
  return unseenIds(current: current, seen: seen).length;
}
