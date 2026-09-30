import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridewindow/domain/models/watched_ride.dart';

const kScoreDropThresholdKey = 'rideScoreAlerts.threshold';
const _kSnapshotKey = 'rideScoreAlerts.snapshot';
const kScoreDropThresholds = [5, 10, 20];

/// Toestelinstelling: een toestemming en aflevergeschiedenis zijn geen
/// cloudprofiel. Een cloudadoptie mag de eigen opt-in niet overschrijven.
class RideScoreAlertStore {
  RideScoreAlertStore(this.prefs);
  final SharedPreferences prefs;

  int get threshold {
    final value = prefs.getInt(kScoreDropThresholdKey) ?? 0;
    return kScoreDropThresholds.contains(value) ? value : 0;
  }

  Future<void> setThreshold(int value) async {
    if (value != 0 && !kScoreDropThresholds.contains(value)) {
      throw ArgumentError.value(value, 'value');
    }
    await prefs.setInt(kScoreDropThresholdKey, value);
  }

  RideAlertSnapshot read() {
    try {
      final raw = prefs.getString(_kSnapshotKey);
      if (raw == null) return RideAlertSnapshot();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return RideAlertSnapshot(
        owner: json['owner'] as String?,
        context: json['context'] as String?,
        rides: [
          for (final row in json['rides'] as List)
            WatchedRide.fromJson(Map<String, dynamic>.from(row as Map)),
        ],
        baselines: Map<String, dynamic>.from(json['baselines'] as Map),
      );
    } on FormatException {
      return RideAlertSnapshot();
    } on TypeError {
      return RideAlertSnapshot();
    }
  }

  Future<void> save(RideAlertSnapshot snapshot) => prefs.setString(
        _kSnapshotKey,
        jsonEncode({
          'owner': snapshot.owner,
          'context': snapshot.context,
          'rides': snapshot.rides.map((r) => r.toJson()).toList(),
          'baselines': snapshot.baselines,
        }),
      );
}

class RideAlertSnapshot {
  RideAlertSnapshot({
    this.owner,
    this.context,
    this.rides = const [],
    Map<String, dynamic>? baselines,
  }) : baselines = baselines ?? {};

  final String? owner;
  final String? context;
  final List<WatchedRide> rides;
  final Map<String, dynamic> baselines;
}
