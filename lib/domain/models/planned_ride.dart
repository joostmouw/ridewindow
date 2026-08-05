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
  /// **Afgeleid van de UTC-instant, met opzet (plan 21-13).** `toIso8601String()`
  /// levert een andere string voor een lokale dan voor een UTC-`DateTime` die
  /// hetzelfde tijdstip aanduiden, en `start_at` is een `timestamptz`: alles wat
  /// door Postgres is geweest komt als UTC terug. Zonder `toUtc()` krijgt
  /// dezelfde rit dus twee sleutels -- lokaal `2026-08-08T12-00-00-000`, uit de
  /// cloud `2026-08-08T10-00-00-000Z` -- en houdt de union-merge ze allebei.
  /// Dat is precies het duplicaat dat op 2026-08-05 op het toestel opdook.
  /// Haal de `toUtc()` hier niet weg.
  String get rideId =>
      start.toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');

  /// `public.planned_rides` row shape (plan 21-02) — primary key
  /// `(user_id, ride_id)`. This table has no `updated_at`; it is
  /// intentionally excluded from the timestamp-comparison system (see plan
  /// 21-05's objective: rides don't have a mutable "current state" to
  /// diverge on, so foreground reconcile uses a union merge instead).
  Map<String, dynamic> toRow(String userId) => {
        'user_id': userId,
        'ride_id': rideId,
        // Expliciet UTC (plan 21-13). Een offsetloze string laat de betekenis
        // over aan de lezer: Postgres leest hem in de sessiezone (UTC), zodat
        // een rit van 12:00 lokaal als 12:00 UTC werd opgeslagen -- hetzelfde
        // klokgetal, een ander tijdstip.
        'start_at': start.toUtc().toIso8601String(),
        'end_at': end.toUtc().toIso8601String(),
        'planned_score': plannedScore,
      };

  /// Parses a pulled `public.planned_rides` row back into a [PlannedRide].
  /// `.toLocal()` is niet cosmetisch (plan 21-13): de UI drukt de velden van de
  /// `DateTime` zelf af zonder om te rekenen, dus zonder deze omzetting zou een
  /// rit uit de cloud op 10:00 renderen waar de lokale kopie 12:00 toont.
  factory PlannedRide.fromRow(Map<String, dynamic> row) => PlannedRide(
        start: DateTime.parse(row['start_at'] as String).toLocal(),
        end: DateTime.parse(row['end_at'] as String).toLocal(),
        plannedScore: (row['planned_score'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        // Ook lokaal expliciet UTC (plan 21-13), zodat de opgeslagen waarde
        // eenduidig is. Oudere, offsetloze waarden blijven leesbaar: die parsen
        // als lokale tijd, wat is wat ze bedoelden, en `.toLocal()` in
        // [fromJson] is daarop een no-op.
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'plannedScore': plannedScore,
      };

  factory PlannedRide.fromJson(Map<String, dynamic> json) {
    // Backwards compat: old format had 'time' (single hour)
    if (json.containsKey('time') && !json.containsKey('start')) {
      final time = DateTime.parse(json['time'] as String).toLocal();
      return PlannedRide(
        start: time,
        end: time.add(const Duration(hours: 1)),
        plannedScore: (json['plannedScore'] as num).toDouble(),
      );
    }
    return PlannedRide(
      start: DateTime.parse(json['start'] as String).toLocal(),
      end: DateTime.parse(json['end'] as String).toLocal(),
      plannedScore: (json['plannedScore'] as num).toDouble(),
    );
  }
}
