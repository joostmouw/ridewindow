import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/core/app_version.dart';
import 'package:ridewindow/data/repositories/analytics_consent_store.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/services/analytics_service.dart';

part 'analytics_provider.g.dart';

/// De toestemmingsstand. Een `Notifier` en geen simpele lees-provider, omdat
/// Profiel hem moet kunnen omzetten en Home moet zien dat de vraag beantwoord is.
@riverpod
class AnalyticsConsent extends _$AnalyticsConsent {
  AnalyticsConsentStore? _store;

  @override
  Future<AnalyticsConsentStore> build() async {
    // Bewust `getInstance()` en niet `sharedPrefsProvider`, om dezelfde reden
    // als profile_notifier.dart: die gooit tenzij overschreven, en de tests
    // leunen op setMockInitialValues.
    return _store = AnalyticsConsentStore(await SharedPreferences.getInstance());
  }

  /// Leg het antwoord van de gebruiker vast en laat iedereen het weten.
  ///
  /// Bij een ja gaat wat er in de wachtkamer lag alsnog de outbox in. Dit is
  /// de enige plek waar dat gebeurt -- `setConsent` is het enige moment waarop
  /// "nog niet gevraagd" in "ja" verandert, en de wachtkamer mag nooit half
  /// geleegd achterblijven. Bij een nee wist de store hem zelf.
  Future<void> setConsent(bool granted) async {
    final store = _store ?? await future;
    await store.setConsent(granted);
    if (granted) {
      try {
        await buildAnalyticsService(ref, store).flushPending();
      } catch (_) {
        // Statistiek mag nooit de reden zijn dat een antwoord niet landt.
      }
    }
    // Alleen als er nog iets te verversen valt. Deze provider is auto-dispose
    // en wordt op de toestemmingskaart uitsluitend met `read` benaderd, dus hij
    // is er na de awaits hierboven meestal al niet meer. `invalidateSelf` gooit
    // dan een `UnmountedRefException`, die door de `await` heen uit deze
    // methode ontsnapt -- en in de kaart betekende dat: keuze opgeslagen, maar
    // het venster ging nooit dicht. Gemeld door een tester op 1.0.35+46.
    //
    // Overslaan is hier geen noodgreep maar het juiste antwoord: is de provider
    // weggegooid, dan luistert er niemand, en dan valt er niets in te lichten.
    // De volgende lezer bouwt hem opnieuw op en leest de verse waarde uit prefs.
    if (ref.mounted) ref.invalidateSelf();
  }
}

/// De service zelf. Hangt aan dezelfde outbox als profiel, beschikbaarheid en
/// feedback -- zie `AnalyticsService` voor waarom.
@riverpod
Future<AnalyticsService> analytics(Ref ref) async {
  final consent = await ref.watch(analyticsConsentProvider.future);
  return buildAnalyticsService(ref, consent);
}

/// Bouwt de service uit een toestemmingsstand.
///
/// Apart van de provider omdat `setConsent` hem óók nodig heeft, op een moment
/// dat de provider zelf nog aan het omvallen is. Twee keer dezelfde constructor
/// uitschrijven is precies hoe `appVersion` of `platform` op één van de twee
/// plekken achterloopt.
AnalyticsService buildAnalyticsService(Ref ref, AnalyticsConsentStore consent) {
  return AnalyticsService(
    outbox: ref.read(appDatabaseProvider).syncOutboxDao,
    consent: consent,
    appVersion: '$kAppVersionName+$kAppBuildNumber',
    platform: kIsWeb ? 'web' : 'android',
  );
}

/// Legt een gebeurtenis vast zonder dat de aanroeper erop wacht.
///
/// **Waarom dit een vrije functie is en geen methode.** Elk scherm dat iets wil
/// meten heeft een `WidgetRef` en verder niets, en moet er niet aan hoeven
/// denken dat `analyticsProvider` asynchroon is. Belangrijker: geen enkel
/// scherm mag trager worden of stukgaan door statistiek. Alles wordt hier
/// geslikt -- de provider die nog laadt, een dichte database, een onbekende
/// naam. `AnalyticsService` beslist zelf of er werkelijk iets vertrekt; zonder
/// toestemming gebeurt er niets.
void trackEvent(
  WidgetRef ref,
  String name, {
  Map<String, Object?> props = const {},
}) {
  unawaited(() async {
    try {
      final analytics = await ref.read(analyticsProvider.future);
      await analytics.track(name, props: props);
    } catch (_) {
      // Met opzet stil.
    }
  }());
}
