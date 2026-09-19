// lib/services/analytics_service.dart
// v4.1: anonieme gebruiksstatistiek, en alleen na toestemming.

import 'dart:convert';
import 'dart:math';

import 'package:ridewindow/core/analytics_events.dart';
import 'package:ridewindow/data/database/daos/sync_outbox_dao.dart';
import 'package:ridewindow/data/database/sync_outbox_entity_types.dart';
import 'package:ridewindow/data/repositories/analytics_consent_store.dart';

/// Zet gebeurtenissen in de lokale outbox; de bestaande drain bezorgt ze.
///
/// **Waarom via de outbox.** Dezelfde reden als bij feedback (FB-04): een
/// tester in de trein moet niet onzichtbaar worden omdat hij geen bereik had.
/// Die machinerie bestaat sinds fase 21 en hoeft niet nog eens gebouwd.
///
/// **Waarom dit stil faalt.** Statistiek mag nooit de reden zijn dat iets in de
/// app niet werkt. Elke fout hier wordt geslikt; er is geen enkele aanroeper die
/// op een resultaat wacht.
///
/// **De drie sloten op wat er vertrekt.**
/// 1. Geen toestemming, geen rij -- [AnalyticsConsentStore.isEnabled].
/// 2. Geen bekende naam, geen rij -- [kKnownAnalyticsEvents].
/// 3. Props worden gesnoeid tot getallen, booleans en korte codes. Een zin die
///    per ongeluk in een prop belandt, komt er niet doorheen.
class AnalyticsService {
  AnalyticsService({
    required SyncOutboxDao outbox,
    required AnalyticsConsentStore consent,
    required String appVersion,
    required String platform,
    Random? random,
  })  : _outbox = outbox,
        _consent = consent,
        _appVersion = appVersion,
        _platform = platform,
        _random = random ?? Random.secure();

  final SyncOutboxDao _outbox;
  final AnalyticsConsentStore _consent;
  final String _appVersion;
  final String _platform;
  final Random _random;

  /// Maximale lengte van een tekstwaarde in props. Ruim genoeg voor een code
  /// als `fallback` of `nl`, te krap voor een zin.
  static const int kMaxPropStringLength = 24;

  /// Leg een gebeurtenis vast. Doet niets als er geen toestemming is.
  ///
  /// Geeft terug of er werkelijk iets in de wachtrij is gezet -- alleen voor
  /// tests; geen aanroeper in de app kijkt ernaar.
  Future<bool> track(
    String name, {
    Map<String, Object?> props = const {},
    DateTime? now,
  }) async {
    // Een nee is een nee -- ook geen wachtkamer.
    if (_consent.consent == false) return false;
    if (!kKnownAnalyticsEvents.contains(name)) {
      assert(
          false,
          'Onbekende gebeurtenis "$name" -- zet hem in '
          'lib/core/analytics_events.dart of gebruik hem niet.');
      return false;
    }

    // `null` = nog niet gevraagd. Die gebeurtenissen gaan de wachtkamer in;
    // zie [AnalyticsConsentStore.pending] voor waarom dat moet.
    final deviceId = _consent.deviceId;
    final waitingForAnswer = !_consent.isEnabled;

    try {
      final id = _uuidV4();
      final row = <String, dynamic>{
        'id': id,
        // In de wachtkamer nog leeg: de toestel-id ontstaat pas bij een ja, en
        // [flushPending] vult hem dan alsnog in.
        if (deviceId != null) 'device_id': deviceId,
        'name': name,
        'props': sanitizeProps(props),
        'platform': _platform,
        'app_version': _appVersion,
        'occurred_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
      };

      if (waitingForAnswer) {
        // Niet verstuurd, alleen vastgelegd. Past hij niet meer, dan valt hij
        // stil af -- statistiek mag nooit ergens tegenaan lopen.
        await _consent.addPending(jsonEncode(row));
        return false;
      }

      // Een verse id per gebeurtenis, zodat de coalescing van de outbox ze niet
      // samenvouwt -- exact de reden die FeedbackService voor zijn id geeft.
      await _outbox.enqueueOrCoalesce(
        entity: kOutboxEntityAnalytics,
        entityKey: id,
        operation: 'upsert',
        payload: jsonEncode(row),
      );
      return true;
    } catch (_) {
      // Statistiek mag nooit iets in de app breken.
      return false;
    }
  }

  /// Verstuurt alsnog wat er op het antwoord lag te wachten.
  ///
  /// Aangeroepen op één plek -- `AnalyticsConsent.setConsent` -- zodat de
  /// wachtkamer nooit half geleegd kan achterblijven. Bij een nee wordt hij
  /// niet geleegd maar gewist; dat doet de store zelf.
  ///
  /// Geeft terug hoeveel rijen er in de outbox zijn gezet.
  Future<int> flushPending() async {
    if (!_consent.isEnabled) return 0;
    final deviceId = _consent.deviceId;
    if (deviceId == null) return 0;

    final rows = _consent.pending;
    if (rows.isEmpty) return 0;

    var sent = 0;
    for (final raw in rows) {
      try {
        final row = jsonDecode(raw) as Map<String, dynamic>;
        // De id die er bij het vastleggen nog niet was.
        row['device_id'] = deviceId;
        await _outbox.enqueueOrCoalesce(
          entity: kOutboxEntityAnalytics,
          entityKey: row['id'] as String,
          operation: 'upsert',
          payload: jsonEncode(row),
        );
        sent++;
      } catch (_) {
        // Een onleesbare rij houdt de rest niet tegen.
      }
    }
    await _consent.clearPending();
    return sent;
  }

  /// Snoeit props tot wat een gebeurtenis mag dragen.
  ///
  /// Getallen en booleans gaan door. Tekst mag alleen als hij kort is -- dat
  /// filtert per ongeluk meegegeven vrije tekst eruit. Alles wat overblijft
  /// (lijsten, objecten, null) valt af. Openbaar omdat dit precies het stuk is
  /// dat een test moet kunnen vastpinnen.
  static Map<String, Object> sanitizeProps(Map<String, Object?> props) {
    final out = <String, Object>{};
    for (final entry in props.entries) {
      final value = entry.value;
      if (value is num || value is bool) {
        out[entry.key] = value as Object;
      } else if (value is String && value.length <= kMaxPropStringLength) {
        out[entry.key] = value;
      }
    }
    return out;
  }

  String _uuidV4() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}'
        '-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
