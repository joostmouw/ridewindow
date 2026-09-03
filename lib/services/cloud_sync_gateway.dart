import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/data/remote/supabase_tables.dart';

/// De cloudkant van [CloudSyncReconciler], als poort in plaats van als
/// rechtstreekse `Supabase.instance.client`-aanroepen (backlog #60).
///
/// **Waarom dit bestaat.** Fase 21 had vijf gap-closure-plannen nodig (21-10
/// t/m 21-14) en élk defect werd op een toestel gevonden, nooit door de suite:
/// 21-10 of de aanroep bestond, 21-11 of die zijn werk bereikte, 21-12 of de
/// payload een legale rij was, 21-13/21-14 of de volgorde klopte. Steeds
/// dezelfde oorzaak — de reconciler greep in zijn eigen methodebody naar
/// `Supabase.instance.client`, dus van buitenaf was niet waarneembaar wát hij
/// deed. Deze poort maakt die zes aanroepen van buiten vervangbaar.
///
/// **Waarom een poort en geen mock van [SupabaseClient].** Die klasse biedt een
/// fluent query builder (`.from(...).select().eq(...)`), en een fake daarvan
/// bouwen betekent dat je de builder namaakt in plaats van je eigen gedrag te
/// toetsen. Dit project heeft dat probleem twee keer eerder opgelost en beide
/// keren zo: [AccountSyncService] krijgt zijn cloudkant als closures, en
/// `RideDetailScreen` krijgt een optionele `calendarServiceFactory` met een
/// productie-default. Zes leden, elk precies één bestaande aanroep — niet meer.
abstract class CloudSyncGateway {
  /// Het uid van de herstelde Supabase-sessie, of `null` als er niemand is
  /// ingelogd of Supabase niet geïnitialiseerd is.
  ///
  /// Alleen het uid, niet de hele [User]: de reconciler gebruikt nergens iets
  /// anders dan `.id`, en een smallere poort is een die niet stilletjes
  /// uitdijt.
  String? currentSessionUserId();

  Future<Map<String, dynamic>?> readProfileRow(String userId);

  Future<Map<String, dynamic>?> readAvailabilityRow(String userId);

  Future<List<Map<String, dynamic>>> readPlannedRideRows(String userId);

  Future<void> upsertRow(String table, Map<String, dynamic> payload);

  Future<void> deletePlannedRide({
    required String userId,
    required String rideId,
  });
}

/// De productie-implementatie: exact de aanroepen die vóór backlog #60 in
/// `cloud_sync_reconciler_provider.dart` stonden, ongewijzigd.
class SupabaseCloudSyncGateway implements CloudSyncGateway {
  const SupabaseCloudSyncGateway();

  /// **Lees dit vóór je hier iets "opruimt" (plan 21-11).** Deze lookup moet
  /// een getter blijven, aangeroepen per methode — géén veld en géén
  /// constructor-argument. `Supabase.instance` gooit wanneer Supabase niet
  /// geïnitialiseerd is, en dat is de normale toestand in de testsuite. Zou de
  /// lookup bij constructie gebeuren, dan gooit deze klasse al vóórdat de code
  /// draait die we juist willen observeren, en verdwijnt elke echte fout achter
  /// die throw. Precies zo is de disposed-`Ref`-bug van 21-11 een dag lang
  /// onzichtbaar gebleven: de `Supabase.instance.client`-lookup stond bovenaan
  /// `drainOutbox()` en gooide vóór de regel die werkelijk stuk was.
  SupabaseClient get _client => Supabase.instance.client;

  @override
  String? currentSessionUserId() {
    return _client.auth.currentSession?.user.id;
  }

  @override
  Future<Map<String, dynamic>?> readProfileRow(String userId) async {
    return await _client
        .from(kProfilesTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>?> readAvailabilityRow(String userId) async {
    return await _client
        .from(kAvailabilityTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> readPlannedRideRows(String userId) async {
    final rows =
        await _client.from(kPlannedRidesTable).select().eq('user_id', userId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> upsertRow(String table, Map<String, dynamic> payload) async {
    await _client.from(table).upsert(payload);
  }

  @override
  Future<void> deletePlannedRide({
    required String userId,
    required String rideId,
  }) async {
    await _client
        .from(kPlannedRidesTable)
        .delete()
        .eq('user_id', userId)
        .eq('ride_id', rideId);
  }
}
