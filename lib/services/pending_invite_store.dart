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
abstract final class PendingInviteStore {
  static const _key = 'peloton.pendingInviteCode';

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
}
