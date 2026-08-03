import 'package:drift/drift.dart';

/// Offline write queue for cloud sync (SYNC-05). One row per pending
/// (entity, entityKey) pair — coalesced via [uniqueKeys] so repeated local
/// writes to the same entity leave exactly one row, not one per write.
class SyncOutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()(); // 'profile' | 'availability' | 'planned_ride'
  TextColumn get entityKey => text()(); // profile/availability: userId. planned_ride: '<userId>:<rideId>'
  TextColumn get operation =>
      text().withDefault(const Constant('upsert'))(); // 'upsert' | 'delete'
  TextColumn get payload => text()(); // JSON-encoded row map for 'upsert'; '{}' for 'delete'
  IntColumn get queuedAt => integer()(); // epoch-ms
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {entity, entityKey},
      ];
}
