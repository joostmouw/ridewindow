// De drie sloten op wat er van een toestel vertrekt (v4.1, migratie 0008).
//
// Dit is de test die de herschreven privacy-constraint uit CLAUDE.md bewaakt.
// Faalt hier iets, dan vertrekt er iets dat niet had mogen vertrekken -- dat is
// geen gewone regressie maar een gebroken belofte aan de gebruiker.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/core/analytics_events.dart';
import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/database/daos/sync_outbox_dao.dart';
import 'package:ridewindow/data/database/sync_outbox_entity_types.dart';
import 'package:ridewindow/data/repositories/analytics_consent_store.dart';
import 'package:ridewindow/services/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SyncOutboxDao outbox;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    outbox = db.syncOutboxDao;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async => db.close());

  Future<AnalyticsService> serviceWith({required bool? consent}) async {
    final prefs = await SharedPreferences.getInstance();
    final store = AnalyticsConsentStore(prefs);
    if (consent != null) await store.setConsent(consent);
    return AnalyticsService(
      outbox: outbox,
      consent: store,
      appVersion: '1.0.31+42',
      platform: 'android',
    );
  }

  Future<int> pendingCount() async => (await outbox.select(db.syncOutboxEntries).get()).length;

  group('slot 1 — zonder toestemming vertrekt er niets', () {
    test('nooit gevraagd', () async {
      final service = await serviceWith(consent: null);
      expect(await service.track(kEvAppOpen), isFalse);
      expect(await pendingCount(), 0);
    });

    test('expliciet geweigerd', () async {
      final service = await serviceWith(consent: false);
      expect(await service.track(kEvAppOpen), isFalse);
      expect(await pendingCount(), 0);
    });

    test('toestemming ingetrokken gooit de toestel-id weg', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = AnalyticsConsentStore(prefs);

      await store.setConsent(true);
      final eersteId = store.deviceId;
      expect(eersteId, isNotNull);

      await store.setConsent(false);
      expect(store.deviceId, isNull);

      // Weer aan: een nieuwe id, dus geen draad terug naar de oude rijen.
      await store.setConsent(true);
      expect(store.deviceId, isNot(eersteId));
    });
  });

  group('slot 2 — alleen namen uit de gesloten lijst', () {
    test('een bekende naam komt erdoor', () async {
      final service = await serviceWith(consent: true);
      expect(await service.track(kEvRidePlanned), isTrue);
      expect(await pendingCount(), 1);
    });

    test('een onbekende naam wordt geweigerd', () async {
      final service = await serviceWith(consent: true);
      // De assert in AnalyticsService vuurt in debug; vangen en de uitkomst
      // toetsen, want in release moet hij stil weigeren en niet crashen.
      await expectLater(
        () => service.track('stiekem_iets_anders'),
        throwsA(isA<AssertionError>()),
      );
      expect(await pendingCount(), 0);
    });
  });

  group('slot 3 — props dragen geen vrije tekst', () {
    test('getallen, booleans en korte codes blijven', () {
      final out = AnalyticsService.sanitizeProps({
        'score': 98,
        'duration_h': 2.5,
        'signed_in': true,
        'source': 'fallback',
      });
      expect(out, {
        'score': 98,
        'duration_h': 2.5,
        'signed_in': true,
        'source': 'fallback',
      });
    });

    test('een zin valt eruit', () {
      final out = AnalyticsService.sanitizeProps({
        'comment': 'De score klopte niet, het regende gewoon keihard',
        'score': 40,
      });
      expect(out.containsKey('comment'), isFalse);
      expect(out['score'], 40);
    });

    test('lijsten, objecten en null vallen eruit', () {
      final out = AnalyticsService.sanitizeProps({
        'list': [1, 2, 3],
        'map': {'a': 1},
        'niets': null,
      });
      expect(out, isEmpty);
    });
  });

  group('de rij zelf', () {
    test('draagt geen user_id, wel een toestel-id', () async {
      final service = await serviceWith(consent: true);
      await service.track(kEvAppOpen, props: {'signed_in': true});

      final entries = await outbox.select(db.syncOutboxEntries).get();
      final row = jsonDecode(entries.single.payload) as Map<String, dynamic>;

      expect(row.containsKey('user_id'), isFalse,
          reason: 'een gebeurtenis mag niet aan een persoon hangen');
      expect(row['device_id'], isNotNull);
      expect(row['name'], kEvAppOpen);
      expect(row['platform'], 'android');
      expect(row['app_version'], '1.0.31+42');
      expect((row['props'] as Map)['signed_in'], isTrue);
      expect(entries.single.entity, kOutboxEntityAnalytics);
    });

    test('twee gebeurtenissen vouwen niet samen tot een', () async {
      // De outbox coalesceert op (entity, entityKey). Een verse id per
      // gebeurtenis zet dat uit -- anders overschrijft je tweede rit je eerste.
      final service = await serviceWith(consent: true);
      await service.track(kEvRidePlanned);
      await service.track(kEvRidePlanned);
      expect(await pendingCount(), 2);
    });

    test('occurred_at staat in UTC', () async {
      final service = await serviceWith(consent: true);
      await service.track(
        kEvAppOpen,
        now: DateTime.utc(2026, 9, 19, 8, 36),
      );

      final entries = await outbox.select(db.syncOutboxEntries).get();
      final row = jsonDecode(entries.single.payload) as Map<String, dynamic>;
      expect(row['occurred_at'], '2026-09-19T08:36:00.000Z');
    });
  });
}
