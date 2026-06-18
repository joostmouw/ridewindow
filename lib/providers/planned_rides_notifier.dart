import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ridewindow/app/router.dart';

part 'planned_rides_notifier.g.dart';

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

const _kPrefsKey = 'planned_rides';

@riverpod
class PlannedRidesNotifier extends _$PlannedRidesNotifier {
  @override
  List<PlannedRide> build() {
    final prefs = ref.read(sharedPrefsProvider);
    final raw = prefs.getString(_kPrefsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final now = DateTime.now();
    return list
        .map(PlannedRide.fromJson)
        .where((r) => r.end.isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  void add(PlannedRide ride) {
    // Don't add if overlapping with existing ride
    if (state.any((r) =>
        r.start.isBefore(ride.end) && r.end.isAfter(ride.start))) {
      return;
    }
    state = [...state, ride]..sort((a, b) => a.start.compareTo(b.start));
    _persist();
  }

  void remove(PlannedRide ride) {
    state = state
        .where((r) => r.start != ride.start || r.end != ride.end)
        .toList();
    _persist();
  }

  void _persist() {
    final prefs = ref.read(sharedPrefsProvider);
    final json = jsonEncode(state.map((r) => r.toJson()).toList());
    prefs.setString(_kPrefsKey, json);
  }
}
