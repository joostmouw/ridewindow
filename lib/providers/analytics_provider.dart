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
  Future<void> setConsent(bool granted) async {
    final store = _store ?? await future;
    await store.setConsent(granted);
    ref.invalidateSelf();
  }
}

/// De service zelf. Hangt aan dezelfde outbox als profiel, beschikbaarheid en
/// feedback -- zie `AnalyticsService` voor waarom.
@riverpod
Future<AnalyticsService> analytics(Ref ref) async {
  final consent = await ref.watch(analyticsConsentProvider.future);
  return AnalyticsService(
    outbox: ref.watch(appDatabaseProvider).syncOutboxDao,
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
