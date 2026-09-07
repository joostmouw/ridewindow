// lib/services/feedback_service.dart
// Fase 22: feedback gaat naar de database in plaats van naar een mailto:.

import 'dart:convert';
import 'dart:math';

import 'package:ridewindow/data/database/daos/sync_outbox_dao.dart';
import 'package:ridewindow/data/database/sync_outbox_entity_types.dart';
import 'package:ridewindow/domain/services/feedback_payload.dart';

/// Zet feedback in de lokale outbox; de bestaande drain bezorgt hem.
///
/// **Waarom via de outbox en niet rechtstreeks naar Supabase.** FB-04 eist dat
/// feedback die zonder verbinding is geschreven bewaard blijft en alsnog
/// vertrekt zodra er weer verbinding is. Die machinerie bestaat al sinds fase
/// 21 -- rijen blijven `pending`, een mislukte poging telt op tot een plafond,
/// en `CloudSyncReconciler.drainOutbox()` draait bij elke voorgrondovergang.
/// Feedback daar buitenom sturen zou betekenen dat juist het bericht van iemand
/// zonder bereik verloren gaat, en dat is precies de gebruiker die iets te
/// melden heeft.
///
/// De drain loopt bewust vóór de "wie is ingelogd"-controle in
/// `reconcileOnForeground`, dus dit werkt ook uitgelogd (FB-03).
class FeedbackService {
  FeedbackService(this._outbox, {Random? random})
      : _random = random ?? Random.secure();

  final SyncOutboxDao _outbox;
  final Random _random;

  /// Genereert een UUID v4.
  ///
  /// Zelf gedaan in plaats van er een pakket voor binnen te halen: dit is de
  /// enige plek in de app die een uuid nodig heeft, en de afweging uit
  /// CLAUDE.md ("geen afhankelijkheid voor iets dat je in twintig regels doet")
  /// geldt hier onverkort. `Random.secure()` omdat een voorspelbare id in een
  /// primaire sleutel nooit een goed idee is.
  String _uuidV4() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // versie 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant 10xx
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}'
        '-${h.substring(16, 20)}-${h.substring(20)}';
  }

  /// Schrijft één feedbackrij naar de outbox en geeft de gegenereerde id terug.
  ///
  /// De id is óók de `entityKey`. Dat is niet cosmetisch: de outbox
  /// *coalesceert* op (entity, entityKey), wat voor profiel en beschikbaarheid
  /// precies de bedoeling is -- tien wijzigingen worden één rij. Voor feedback
  /// zou dat betekenen dat je tweede bericht je eerste overschrijft. Een verse
  /// id per inzending zet die samenvoeging uit, terwijl een herhaalde poging op
  /// dezelfde id wél samenvalt.
  Future<String> submit({
    required String? userId,
    required int rating,
    required String comment,
    required Map<String, dynamic> context,
  }) async {
    final id = _uuidV4();
    final row = buildFeedbackRow(
      id: id,
      userId: userId,
      rating: rating,
      comment: comment,
      context: context,
    );

    await _outbox.enqueueOrCoalesce(
      entity: kOutboxEntityFeedback,
      entityKey: id,
      operation: 'upsert',
      payload: jsonEncode(row),
    );
    return id;
  }
}
