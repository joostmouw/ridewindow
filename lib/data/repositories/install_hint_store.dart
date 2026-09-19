import 'package:shared_preferences/shared_preferences.dart';

/// Hoe vaak en hoe lang de "zet op beginscherm"-balk nog getoond mag worden.
///
/// **Waarom D-04 wordt teruggedraaid.** Fase 16 koos bewust voor géén
/// wegklikknop: de balk zou elke sessie terugkomen tot de gebruiker de app
/// werkelijk installeert. Dat leek netjes -- hij verdwijnt immers vanzelf zodra
/// `display-mode: standalone` aanslaat -- maar een tester meldde op
/// 2026-09-19 het gevolg: de balk staat bovenaan over de app heen en gaat
/// nooit weg, dus een strook van elk scherm is permanent onzichtbaar.
///
/// **Waarom niet gewoon voorgoed weg.** Dan installeert vrijwel niemand de app
/// nog, en juist op iOS is dat de enige manier om hem als app te gebruiken.
/// Vandaar de middenweg: wegklikken sluimert hem een week, en na drie keer
/// wegklikken houdt de app erover op. Wie hem drie keer wegklikt, meent het.
class InstallHintStore {
  InstallHintStore(this._prefs);

  final SharedPreferences _prefs;

  static const kDismissedAtKey = 'pwa.installHintDismissedAt';
  static const kDismissCountKey = 'pwa.installHintDismissCount';

  /// Na zoveel keer wegklikken vraagt de app het niet meer.
  static const int kMaxDismissals = 3;

  /// Hoe lang de balk wegblijft na één keer wegklikken.
  static const Duration kSnooze = Duration(days: 7);

  int get dismissCount => _prefs.getInt(kDismissCountKey) ?? 0;

  DateTime? get dismissedAt {
    final millis = _prefs.getInt(kDismissedAtKey);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  bool isSuppressed({DateTime? now}) => installHintSuppressed(
        dismissCount: dismissCount,
        dismissedAt: dismissedAt,
        now: now ?? DateTime.now(),
      );

  Future<void> recordDismissal({DateTime? now}) async {
    await _prefs.setInt(kDismissCountKey, dismissCount + 1);
    await _prefs.setInt(
      kDismissedAtKey,
      (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }
}

/// De beslissing zelf, los van opslag zodat ze te toetsen is zonder klok of
/// SharedPreferences.
bool installHintSuppressed({
  required int dismissCount,
  required DateTime? dismissedAt,
  required DateTime now,
}) {
  if (dismissCount >= InstallHintStore.kMaxDismissals) return true;
  if (dismissedAt == null) return false;
  return now.difference(dismissedAt) < InstallHintStore.kSnooze;
}
