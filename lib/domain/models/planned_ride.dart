class PlannedRide {
  PlannedRide({
    required this.start,
    required this.end,
    required this.plannedScore,
  });

  /// Start of the ride (inclusive).
  final DateTime start;

  /// End of the ride (exclusive, like RideSlot).
  final DateTime end;

  /// Overall score at the moment of planning.
  final double plannedScore;

  int get durationHours => end.difference(start).inHours;

  /// Deterministic, sanitized identifier — the primary key half
  /// `public.planned_rides` needs alongside `user_id`. `:` and `.` are
  /// stripped because Postgres text primary keys don't need ISO8601
  /// punctuation and it keeps the value URL/log-safe. Derived from `start`
  /// only (ARCHITECTURE.md §3) — makes upsert-on-retry safe, since the same
  /// ride always produces the same id.
  String get rideId => start.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');

  /// `public.planned_rides` row shape (plan 21-02) — primary key
  /// `(user_id, ride_id)`. This table has no `updated_at`; it is
  /// intentionally excluded from the timestamp-comparison system (see plan
  /// 21-05's objective: rides don't have a mutable "current state" to
  /// diverge on, so foreground reconcile uses a union merge instead).
  Map<String, dynamic> toRow(String userId) => {
        'user_id': userId,
        'ride_id': rideId,
        'start_at': start.toIso8601String(),
        'end_at': end.toIso8601String(),
        'planned_score': plannedScore,
      };

  /// Parses a pulled `public.planned_rides` row back into a [PlannedRide].
  factory PlannedRide.fromRow(Map<String, dynamic> row) => PlannedRide(
        start: DateTime.parse(row['start_at'] as String),
        end: DateTime.parse(row['end_at'] as String),
        plannedScore: (row['planned_score'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'plannedScore': plannedScore,
      };

  factory PlannedRide.fromJson(Map<String, dynamic> json) {
    // Backwards compat: old format had 'time' (single hour)
    if (json.containsKey('time') && !json.containsKey('start')) {
      final time = DateTime.parse(json['time'] as String);
      return PlannedRide(
        start: time,
        end: time.add(const Duration(hours: 1)),
        plannedScore: (json['plannedScore'] as num).toDouble(),
      );
    }
    return PlannedRide(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      plannedScore: (json['plannedScore'] as num).toDouble(),
    );
  }
}
