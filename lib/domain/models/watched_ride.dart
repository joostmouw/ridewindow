import 'package:ridewindow/domain/models/ride_entry.dart';

/// Alleen wat een lokale weercontrole nodig heeft. Geen namen, deelnemers of
/// cloudgegevens in de meldingscache.
class WatchedRide {
  const WatchedRide({
    required this.key,
    required this.start,
    required this.end,
    this.shared = false,
  });

  final String key;
  final DateTime start;
  final DateTime end;
  final bool shared;

  String get window => RideEntry.slotKey(start, end);

  Map<String, dynamic> toJson() => {
        'key': key,
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'shared': shared,
      };

  factory WatchedRide.fromJson(Map<String, dynamic> json) => WatchedRide(
        key: json['key'] as String,
        start: DateTime.parse(json['start'] as String).toLocal(),
        end: DateTime.parse(json['end'] as String).toLocal(),
        shared: json['shared'] as bool? ?? false,
      );

  static List<WatchedRide> fromEntries(List<RideEntry> entries) => [
        for (final e in entries)
          if (e.role == RideRole.solo ||
              e.role == RideRole.organiser ||
              e.role == RideRole.joined)
            WatchedRide(
              key: e.key,
              start: e.start,
              end: e.end,
              shared: e.group != null,
            ),
      ];
}
