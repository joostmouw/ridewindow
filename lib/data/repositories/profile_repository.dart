import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/database/daos/sync_outbox_dao.dart';
import 'package:ridewindow/data/database/sync_outbox_entity_types.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';

/// Enige bron van waarheid voor de twaalf `profile.*`-sleutels in
/// SharedPreferences.
///
/// Alle sleutelstrings, typen en defaults zijn letterlijk hetzelfde als wat
/// vroeger in `ProfileNotifier` stond (D-01) -- deze klasse is een
/// verhuizing, geen verbouwing.
///
/// [outbox]/[userId] zijn optioneel en additief (ARCHITECTURE.md §4a): als
/// beide gezet zijn (signed-in), enqueuet elke [save] een cloud-schrijving
/// via de outbox. Zonder outbox/userId (signed-out, of de bestaande
/// `background_task.dart`-aanroepstijl) is dit een stille no-op, exact zoals
/// het patroon dat dit vervangt. Deze klasse importeert bewust nooit de
/// cloud-SDK zelf (REG-05) — de outbox is een Drift-only afhankelijkheid.
class ProfileRepository {
  ProfileRepository(this._prefs, {SyncOutboxDao? outbox, this.userId})
      : _outbox = outbox;

  final SharedPreferences _prefs;
  final SyncOutboxDao? _outbox;
  final String? userId;

  static const kTempMinKey = 'profile.tempMinIdealC';
  static const kTempMaxKey = 'profile.tempMaxIdealC';
  static const kWindMaxKey = 'profile.windMaxIdealKmh';
  static const kRainMaxKey = 'profile.rainMaxIdealMm';
  static const kDurationsKey = 'profile.allowedDurations';
  static const kThemeKey = 'profile.theme';
  static const kLocationKey = 'profile.locationOverride';
  static const kUserNameKey = 'profile.userName';
  static const kLocaleKey = 'profile.locale';
  static const kNotifEveningKey = 'profile.notifEveningBefore';
  static const kNotifMorningKey = 'profile.notifMorningOf';
  static const kNotifWeeklyKey = 'profile.notifWeeklyDigest';
  static const kUpdatedAtKey = 'profile.updatedAt';

  /// Leest het profiel van schijf, synchroon -- `_prefs` is al ingeladen.
  ///
  /// [systemLanguageCode] is de systeemtaal van het toestel, door de
  /// aanroeper opgezocht bij het besturingssysteem en als parameter
  /// meegegeven -- deze repository doet die opzoeking zelf niet en heeft
  /// geen Flutter-afhankelijkheid, zodat hij bruikbaar blijft in de
  /// WorkManager-isolate (REG-05).
  UserProfile readLocal({String? systemLanguageCode}) {
    final tempMin = _prefs.getDouble(kTempMinKey) ?? 12.0;
    final tempMax = _prefs.getDouble(kTempMaxKey) ?? 26.0;
    final windMax = _prefs.getDouble(kWindMaxKey) ?? 15.0;
    final rainMax = _prefs.getDouble(kRainMaxKey) ?? 0.5;

    final durationStrings =
        _prefs.getStringList(kDurationsKey) ?? ['2', '3', '5'];
    final durations = durationStrings
        .map((s) => int.tryParse(s) ?? 0)
        .where((d) => d > 0)
        .toList();

    final theme = _prefs.getString(kThemeKey) ?? 'system';
    final locale = _prefs.getString(kLocaleKey) ??
        (systemLanguageCode == 'nl' ? 'nl' : 'en');
    final locationOverride = _prefs.getString(kLocationKey);
    final userName = _prefs.getString(kUserNameKey);
    final notifEvening = _prefs.getBool(kNotifEveningKey) ?? false;
    final notifMorning = _prefs.getBool(kNotifMorningKey) ?? false;
    final notifWeekly = _prefs.getBool(kNotifWeeklyKey) ?? false;

    return UserProfile(
      tolerances: WeatherTolerances(
        tempMinIdealC: tempMin,
        tempMaxIdealC: tempMax,
        windMaxIdealKmh: windMax,
        rainMaxIdealMm: rainMax,
      ),
      allowedDurations: durations.isEmpty ? [2, 3, 5] : durations,
      theme: theme,
      locale: locale,
      locationOverride: locationOverride,
      userName: userName,
      notifEveningBefore: notifEvening,
      notifMorningOf: notifMorning,
      notifWeeklyDigest: notifWeekly,
    );
  }

  /// Schrijft alle twaalf sleutels van [profile] weg. Als [stamp] true is
  /// (default), wordt [kUpdatedAtKey] bijgewerkt naar nu (epoch-ms).
  ///
  /// `locationOverride` en `userName` gebruiken `remove()` bij `null` in
  /// plaats van een lege string schrijven (D-01) -- dat onderscheid is
  /// zichtbaar in het opslagformaat.
  Future<void> save(UserProfile profile, {bool stamp = true}) async {
    await _prefs.setDouble(kTempMinKey, profile.tolerances.tempMinIdealC);
    await _prefs.setDouble(kTempMaxKey, profile.tolerances.tempMaxIdealC);
    await _prefs.setDouble(kWindMaxKey, profile.tolerances.windMaxIdealKmh);
    await _prefs.setDouble(kRainMaxKey, profile.tolerances.rainMaxIdealMm);
    await _prefs.setStringList(
      kDurationsKey,
      profile.allowedDurations.map((d) => d.toString()).toList(),
    );
    await _prefs.setString(kThemeKey, profile.theme);
    await _prefs.setString(kLocaleKey, profile.locale);
    if (profile.locationOverride == null) {
      await _prefs.remove(kLocationKey);
    } else {
      await _prefs.setString(kLocationKey, profile.locationOverride!);
    }
    if (profile.userName == null) {
      await _prefs.remove(kUserNameKey);
    } else {
      await _prefs.setString(kUserNameKey, profile.userName!);
    }
    await _prefs.setBool(kNotifEveningKey, profile.notifEveningBefore);
    await _prefs.setBool(kNotifMorningKey, profile.notifMorningOf);
    await _prefs.setBool(kNotifWeeklyKey, profile.notifWeeklyDigest);

    if (stamp) {
      await _prefs.setInt(
        kUpdatedAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    if (_outbox != null && userId != null) {
      await _outbox.enqueueOrCoalesce(
        entity: kOutboxEntityProfile,
        entityKey: userId!,
        operation: 'upsert',
        payload: jsonEncode(profile.toRow(userId!)),
      );
    }
  }

  /// Zet [kUpdatedAtKey] op een expliciete waarde in plaats van "nu" — alleen
  /// gebruikt bij het overnemen van een gepulde cloud-rij, zodat de lokale
  /// tijdstempel weerspiegelt wanneer de CLOUD-data voor het laatst
  /// veranderde, niet wanneer dit toestel toevallig pulde. Zonder dit zou
  /// `resolveAccountSync` lokaal "nu" als nieuwer zien dan de cloud bij de
  /// eerstvolgende vergelijking, terwijl er lokaal niets echt veranderd is.
  Future<void> stampUpdatedAt(DateTime value) =>
      _prefs.setInt(kUpdatedAtKey, value.millisecondsSinceEpoch);

  /// Verwijdert alle twaalf profiel-sleutels én [kUpdatedAtKey].
  ///
  /// Dit is een gebruikersactie, dus de `updatedAt` hoort niet blijven staan
  /// alsof er nog iets van het oude profiel over is -- een reset maakt de
  /// installatie gelijk aan een verse.
  Future<void> resetToDefaults() async {
    await _prefs.remove(kTempMinKey);
    await _prefs.remove(kTempMaxKey);
    await _prefs.remove(kWindMaxKey);
    await _prefs.remove(kRainMaxKey);
    await _prefs.remove(kDurationsKey);
    await _prefs.remove(kThemeKey);
    await _prefs.remove(kLocationKey);
    await _prefs.remove(kUserNameKey);
    await _prefs.remove(kLocaleKey);
    await _prefs.remove(kNotifEveningKey);
    await _prefs.remove(kNotifMorningKey);
    await _prefs.remove(kNotifWeeklyKey);
    await _prefs.remove(kUpdatedAtKey);
  }

  /// Geeft het epoch-ms tijdstip van de laatste [save]-aanroep, of `null` als
  /// dat veld nog nooit geschreven is.
  ///
  /// Een ontbrekende waarde wordt hier **niet** retroactief op "nu" gezet
  /// (D-08). Fase 20 leest dit veld nergens om iets te beslissen -- de getter
  /// bestaat voor fase 21.
  int? readUpdatedAt() => _prefs.getInt(kUpdatedAtKey);
}
