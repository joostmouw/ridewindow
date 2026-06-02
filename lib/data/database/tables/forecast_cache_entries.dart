import 'package:drift/drift.dart';

class ForecastCacheEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  DateTimeColumn get fetchedAt => dateTime()();
}
