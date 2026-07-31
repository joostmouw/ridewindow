import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ridewindow/app/router.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';

export 'package:ridewindow/domain/models/planned_ride.dart' show PlannedRide;

part 'planned_rides_notifier.g.dart';

const _kPrefsKey = 'planned_rides';

@Riverpod(keepAlive: true)
class PlannedRidesNotifier extends _$PlannedRidesNotifier {
  @override
  List<PlannedRide> build() {
    final prefs = ref.read(sharedPrefsProvider);
    final raw = prefs.getString(_kPrefsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return list
        .map(PlannedRide.fromJson)
        .where((r) => r.end.isAfter(todayStart))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  void add(PlannedRide ride) {
    // Don't add exact duplicate
    if (state.any((r) => r.start == ride.start && r.end == ride.end)) {
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

  /// Wist alle geplande ritten (D-09: "start fresh" bij accountwissel).
  void clearAll() {
    state = [];
    _persist();
  }

  void _persist() {
    final prefs = ref.read(sharedPrefsProvider);
    final json = jsonEncode(state.map((r) => r.toJson()).toList());
    prefs.setString(_kPrefsKey, json);
  }
}
