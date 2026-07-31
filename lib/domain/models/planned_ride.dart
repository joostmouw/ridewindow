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
