// Tests voor het feedback-toestel-id (fase 38, D-08).
//
// Dekt:
//   Test 1: maakt één id bij de eerste lezing en hergebruikt het daarna --
//           het plafond van 0016 telt per toestel, dus een tweede id per
//           toestel zou die telling zinloos maken.
//   Test 2: het id is een uuid v4 (versie- en variantnibbles), met
//           geïnjecteerde Random, dus toetsbaar.
//   Test 3: onafhankelijk van `analytics.deviceId` -- dat id verdwijnt bij
//           intrekken van de statistiek-toestemming, en juist dan moet de
//           feedbacktelling het toestel nog herkennen (D-08).

import 'dart:math' show Random;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/analytics_consent_store.dart';
import 'package:ridewindow/data/repositories/feedback_device_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Test 1 — maakt één id en hergebruikt het daarna', () async {
    final store = FeedbackDeviceStore(await SharedPreferences.getInstance());
    final prefs = await SharedPreferences.getInstance();

    final first = await store.getOrCreateDeviceId();
    final second = await store.getOrCreateDeviceId();

    expect(
      first,
      second,
      reason: 'een tweede id per toestel zou het dagplafond van 0016 '
          'onmogelijk maken: elk bericht zou een nieuw toestel zijn',
    );
    expect(
      prefs.getString(FeedbackDeviceStore.kDeviceIdKey),
      first,
      reason: 'het id moet overleven tussen app-starten, anders begint de '
          'telling elke start op nul',
    );
  });

  test('Test 2 — het id is een uuid v4', () async {
    // Vast randompatroon, zodat de vorm hier iets over zegt: met Random.secure
    // zou alleen de bouw getest worden, niet de uitkomst.
    final store = FeedbackDeviceStore(
      await SharedPreferences.getInstance(),
      random: _FixedRandom(),
    );

    final id = await store.getOrCreateDeviceId();

    expect(
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
              r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
          .hasMatch(id),
      isTrue,
      reason: 'de databasekolom is uuid; alles anders weigert de insert al '
          'voordat het plafond er toe doet',
    );
  });

  test('Test 3 — een ander toestel-id dan dat van de statistiek', () async {
    final prefs = await SharedPreferences.getInstance();
    final analytics = AnalyticsConsentStore(prefs);
    await analytics.setConsent(true); // maakt analytics.deviceId aan

    final feedback = FeedbackDeviceStore(prefs);
    final feedbackId = await feedback.getOrCreateDeviceId();

    expect(
      feedbackId,
      isNot(equals(analytics.deviceId)),
      reason: 'analytics.deviceId verdwijnt bij intrekken van de '
          'toestemming; de feedbacktelling moet het toestel daarna nog '
          'herkennen (D-08)',
    );
    expect(prefs.containsKey(AnalyticsConsentStore.kDeviceIdKey), isTrue);
    expect(prefs.containsKey(FeedbackDeviceStore.kDeviceIdKey), isTrue);
  });
}

/// Geeft altijd dezelfde byte terug: voorspelbaar genoeg om de uuid-vorm te
/// toetsen, en nooit 0x00 per ongeluk "geldig". De versie- en variantnibbles
/// worden door de store zelf gezet, en dat is precies wat Test 2 meet.
class _FixedRandom implements Random {
  @override
  int nextInt(int max) => 0x2a % max;

  // Niet nodig voor de store; hier omdat de interface het eist.
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0.5;
}
