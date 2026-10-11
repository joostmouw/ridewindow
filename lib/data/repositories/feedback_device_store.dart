import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Het toestel-id dat met feedback meereist (fase 38, D-08).
///
/// **Waarom een eigen id en niet de `analytics.deviceId`.** Dat laatste leeft
/// precies zolang de toestemming voor statistiek: bij intrekken wordt hij
/// weggegooid, en dan is het voor de database een ander toestel. De daggrens
/// op feedback (migratie 0016) moet juist ook dan blijven werken -- wie zijn
/// statistiek-toestemming intrekt en daarna twintig keer feedback stuurt,
/// hoort op hetzelfde toestel geteld te worden. Daarom leeft dit id los van
/// die toestemming en verdwijnt het pas als de gebruiker de appgegevens wist.
///
/// Eigen sleutelruimte `feedback.*`, net als `analytics.*`: het hoort bij dit
/// toestel en mag niet meeliften op de `profile.*`-synchronisatie.
///
/// Het privacybeleid beschrijft in fase 40 (AFR-01) dat dit id meegaat met
/// feedback en dat de afzender serverzijds maar één dag als hash bestaat.
class FeedbackDeviceStore {
  FeedbackDeviceStore(this._prefs, {Random? random})
      : _random = random ?? Random.secure();

  final SharedPreferences _prefs;
  final Random _random;

  static const kDeviceIdKey = 'feedback.deviceId';

  /// Geeft het bestaande id, of maakt er één en bewaart het.
  ///
  /// Aangemaakt bij de eerste feedbackversturing en daarna hergebruikt, zodat
  /// het dagplafond van 0016 een toestel over de dagen heen als hetzelfde
  /// herkent -- maar binnen één dag telt, niet over dagen heen: die telling
  /// doet de database, dit id is alleen de naam.
  Future<String> getOrCreateDeviceId() async {
    final existing = _prefs.getString(kDeviceIdKey);
    if (existing != null) return existing;

    final id = _uuidV4();
    await _prefs.setString(kDeviceIdKey, id);
    return id;
  }

  /// UUID v4. Zelfde afweging als in `AnalyticsConsentStore` en
  /// `FeedbackService`: geen pakket voor twintig regels, en `Random.secure()`
  /// omdat een voorspelbare id in een identificator nooit een goed idee is.
  String _uuidV4() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // versie 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant 10xx
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}'
        '-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
