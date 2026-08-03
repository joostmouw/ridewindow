// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_outbox_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncOutboxDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncOutboxEntriesTable get syncOutboxEntries =>
      attachedDatabase.syncOutboxEntries;
  SyncOutboxDaoManager get managers => SyncOutboxDaoManager(this);
}

class SyncOutboxDaoManager {
  final _$SyncOutboxDaoMixin _db;
  SyncOutboxDaoManager(this._db);
  $$SyncOutboxEntriesTableTableManager get syncOutboxEntries =>
      $$SyncOutboxEntriesTableTableManager(
          _db.attachedDatabase, _db.syncOutboxEntries);
}
