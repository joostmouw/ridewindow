import 'package:drift/drift.dart';

// Phase 6 writes rows; schema scaffolded here to complete PERS-03 v1 baseline
class AvailabilityGridEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayOfWeek => integer()(); // 1=Monday ... 7=Sunday
  IntColumn get hour => integer()(); // 0-23
  TextColumn get state => text()(); // 'free' | 'blocked' | 'work'
}
