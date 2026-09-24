// lib/services/pending_invite_store.dart
// Onthoudt de uitnodigingscode van iemand die nog moet inloggen.

import 'package:shared_preferences/shared_preferences.dart';

/// Bewaart de code uit een `/invite/:code`-link tot er iemand is ingelogd.
///
/// **Waarom dit bestaat.** Op 2026-09-07 opende een tester (Jacco) een gedeelde
/// link, kreeg "log eerst in, voer daarna deze code in onder Rides → Peloton"
/// te zien, en vroeg terecht: "En nu?" — gevolgd door het verzoek om een
/// copy-knop, zodat hij de code niet hoefde over te typen. Dat verzoek was een
/// symptoom: **de app kende de code al**, hij stond in de URL waar hij net op
/// had getikt. Iemand vragen om over te typen wat het programma zelf weet, is
/// het probleem; een copy-knop is er de pleister op.
///
/// De code overleeft daarom het inloggen, en wordt daarna vanzelf verzilverd.
/// Bewust in SharedPreferences en niet in geheugen: inloggen kan het scherm
/// verlaten (de knop staat in Profiel) en op het web kan de pagina er zelfs
/// door herladen.
///
/// **Groepslinks (`/group/:code`, plan 34-07) hebben een eigen sleutel.**
/// Iemand kan een maatjeslink en een groepslink tegelijk hebben openstaan --
/// bijvoorbeeld Joost stuurt allebei in één appje -- en de ene mag de andere
/// niet overschrijven. Beide worden na het inloggen los van elkaar ingewisseld.
abstract final class PendingInviteStore {
  /// Sleutel van de maatjescode. Dezelfde waarde als vóór de groepslinks, zodat
  /// een al klaargelegde code na een update nog gevonden wordt. Publiek omdat
  /// de router hem synchroon wegschrijft (zie de onboarding-redirect).
  static const friendKey = 'peloton.pendingInviteCode';

  /// Sleutel van de groepscode.
  static const groupKey = 'peloton.pendingGroupCode';

  static const _key = friendKey;

  /// Legt een code klaar. Overschrijft een eerdere: wie twee links opent,
  /// bedoelt de laatste.
  static Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  /// De klaargelegde code, of `null`.
  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Wist de code. Altijd aanroepen ná een verzilverpoging — ook als die
  /// mislukte omdat de code verlopen was. Een code die niet werkt blijven
  /// bewaren betekent dat elke volgende login opnieuw dezelfde foutmelding
  /// oplevert.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Legt een groepscode klaar. Zelfde regels als [save]: de laatste link wint.
  static Future<void> saveGroup(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(groupKey, code);
  }

  /// De klaargelegde groepscode, of `null`.
  static Future<String?> readGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(groupKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Wist de groepscode. Zelfde reden als bij [clear]: ook na een mislukte
  /// poging, anders komt dezelfde fout bij elke login terug.
  static Future<void> clearGroup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(groupKey);
  }
}
