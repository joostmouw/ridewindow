import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Toestemming voor gebruiksstatistiek, plus de toestel-id die eraan hangt.
///
/// **Drie standen, niet twee.** `null` betekent "nog niet gevraagd" en is iets
/// anders dan `false`. Zonder dat onderscheid zou de app de vraag bij elke
/// start opnieuw stellen, of hem juist nooit stellen -- en allebei is fout.
///
/// **De toestel-id leeft precies zolang de toestemming.** Hij wordt gemaakt bij
/// een "ja" en weggegooid bij een "nee" of bij intrekken. Daarmee is hij geen
/// blijvende identificator: zet de gebruiker het uit en later weer aan, dan is
/// hij voor de statistiek een ander toestel. Dat kost nauwkeurigheid en dat is
/// de bedoeling.
///
/// Eigen sleutelruimte `analytics.*`, net als `location.*`: dit hoort bij dit
/// toestel en mag niet meeliften op de `profile.*`-synchronisatie naar Supabase.
class AnalyticsConsentStore {
  AnalyticsConsentStore(this._prefs, {Random? random})
      : _random = random ?? Random.secure();

  final SharedPreferences _prefs;
  final Random _random;

  static const kConsentKey = 'analytics.consent';
  static const kDeviceIdKey = 'analytics.deviceId';
  static const kAppOpensKey = 'analytics.appOpens';
  static const kPendingKey = 'analytics.pending';

  /// Hoeveel gebeurtenissen er hoogstens wachten op een antwoord.
  ///
  /// De vraag komt bij de tweede start, dus in de praktijk zijn het er een
  /// handvol. Het plafond is er voor de gebruiker die de vraag blijft
  /// wegklikken: dan mag deze lijst niet ongemerkt doorgroeien. Vol is vol --
  /// de oudste blijven staan, want juist die gaan over de eerste minuut.
  static const int kMaxPending = 50;

  /// Bij de hoeveelste start de vraag gesteld wordt.
  ///
  /// Niet de eerste. Fase 29 gaat erover dat de eerste minuut van een nieuwe
  /// tester niet volloopt met overlays, en een vraag over statistiek is het
  /// slechtste dat je daar kunt neerzetten: hij gaat over jou, niet over hem.
  /// Bij de tweede start heeft hij de app zien werken en is de vraag te
  /// beantwoorden op grond van iets.
  static const int kAskAtOpenCount = 2;

  /// `null` = nog niet gevraagd, `true` = ja, `false` = nee.
  bool? get consent => _prefs.getBool(kConsentKey);

  /// Is de vraag al een keer gesteld?
  bool get hasBeenAsked => consent != null;

  /// Mag er iets vertrekken? Alleen bij een expliciete ja én een toestel-id.
  bool get isEnabled => consent == true && deviceId != null;

  String? get deviceId => _prefs.getString(kDeviceIdKey);

  /// Hoe vaak de app geopend is. Alleen om te weten wanneer we de vraag stellen.
  int get appOpens => _prefs.getInt(kAppOpensKey) ?? 0;

  /// Is dit de allereerste start op dit toestel?
  bool get isFirstRun => appOpens == 0;

  /// Tel deze start mee en geef het nieuwe totaal terug.
  Future<int> recordAppOpen() async {
    final next = appOpens + 1;
    await _prefs.setInt(kAppOpensKey, next);
    return next;
  }

  /// Moet de vraag nu gesteld worden?
  bool get shouldAsk => !hasBeenAsked && appOpens >= kAskAtOpenCount;

  /// De gebeurtenissen die wachten tot de vraag beantwoord is.
  ///
  /// **Waarom dit bestaat.** `first_run` en `onboarding_done` gebeuren bij de
  /// eerste start, en de vraag komt pas bij de tweede. Zonder wachtkamer kon
  /// geen van beide ooit aankomen -- de twee metingen waar fase 29 op stuurt
  /// waren daarmee per definitie leeg. Vastgesteld op 2026-09-19, toen het
  /// eerste echte rapport ze allebei op nul had staan.
  ///
  /// **Waarom dit de belofte niet breekt.** Hier ligt alleen vast; versturen is
  /// iets anders. Zonder een ja verlaat er niets het toestel, en bij een nee
  /// wordt deze lijst gewist zonder ooit verstuurd te zijn. De rijen dragen
  /// geen toestel-id -- die bestaat op dit moment nog niet.
  List<String> get pending => _prefs.getStringList(kPendingKey) ?? const [];

  /// Zet een gebeurtenis in de wachtkamer. Geeft terug of hij erin paste.
  Future<bool> addPending(String row) async {
    final rows = List<String>.from(pending);
    if (rows.length >= kMaxPending) return false;
    rows.add(row);
    await _prefs.setStringList(kPendingKey, rows);
    return true;
  }

  /// Leeg de wachtkamer -- na verzenden, of na een nee.
  Future<void> clearPending() async {
    await _prefs.remove(kPendingKey);
  }

  /// Leg het antwoord van de gebruiker vast.
  ///
  /// Bij een ja komt er een verse toestel-id als die er nog niet was; bij een
  /// nee gaat hij weg. Dat laatste is het hele punt: "uitzetten" moet ook
  /// betekenen dat de draad naar eerdere rijen wordt doorgeknipt.
  Future<void> setConsent(bool granted) async {
    await _prefs.setBool(kConsentKey, granted);
    if (granted) {
      if (_prefs.getString(kDeviceIdKey) == null) {
        await _prefs.setString(kDeviceIdKey, _uuidV4());
      }
    } else {
      await _prefs.remove(kDeviceIdKey);
      // Een nee geldt ook met terugwerkende kracht voor wat er in de
      // wachtkamer lag. Wie hier alleen het versturen zou stoppen, laat de
      // rijen staan tot iemand later ja zegt -- en dat is niet wat "nee"
      // betekende op het moment dat het gezegd werd.
      await clearPending();
    }
  }

  /// UUID v4. Zelfde afweging als in `FeedbackService`: geen pakket voor
  /// twintig regels, en `Random.secure()` omdat een voorspelbare id in een
  /// identificator nooit een goed idee is.
  String _uuidV4() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}'
        '-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
