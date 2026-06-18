import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/providers/hourly_scores_provider.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/features/shared/screen_hint_overlay.dart';

Color _scoreColor(double score) {
  if (score >= 85) return const Color(0xFF2E7D32);
  if (score >= 70) return const Color(0xFF66BB6A);
  if (score >= 50) return const Color(0xFFFFB74D);
  return const Color(0xFFEF9A9A);
}

String _tierLabel(double score) {
  if (score >= 85) return 'Perfect';
  if (score >= 70) return 'Geweldig';
  if (score >= 50) return 'Oké';
  return 'Slecht';
}

String _windDirection(double? deg) {
  if (deg == null) return '?';
  const dirs = ['N', 'NO', 'O', 'ZO', 'Z', 'ZW', 'W', 'NW'];
  return dirs[((deg + 22.5) % 360 ~/ 45)];
}

/// Wind comes FROM this direction. To have tailwind on the return,
/// ride INTO the wind first = ride towards the wind source.
/// Wind from N (0°) → ride north first, return south with tailwind.
String _tailwindAdvice(double? deg) {
  if (deg == null) return '';
  // Wind comes from [deg]. Ride towards that direction first.
  const dirs = ['noordwaarts', 'noordoostwaarts', 'oostwaarts', 'zuidoostwaarts',
    'zuidwaarts', 'zuidwestwaarts', 'westwaarts', 'noordwestwaarts'];
  final idx = ((deg + 22.5) % 360 ~/ 45).toInt();
  return 'Fiets ${dirs[idx]} voor wind mee terug';
}

String _fmtTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:00';

class PlannedRidesScreen extends ConsumerStatefulWidget {
  const PlannedRidesScreen({super.key});

  static final _dayFmt = DateFormat('EEEE d MMM', 'nl_NL');

  @override
  ConsumerState<PlannedRidesScreen> createState() => _PlannedRidesScreenState();
}

class _PlannedRidesScreenState extends ConsumerState<PlannedRidesScreen> {
  bool _showHints = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await shouldShowHint('rides') && mounted) {
        setState(() => _showHints = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rides = ref.watch(plannedRidesProvider);
    final allScores = ref.watch(allHourlyScoresProvider);
    final forecasts = ref.watch(weatherProvider).value ?? <HourlyForecast>[];
    final cityName = ref.watch(locationProvider).value?.city ?? '';
    final theme = Theme.of(context);

    final now = DateTime.now();
    final upcoming = rides.where((r) => r.end.isAfter(now)).toList();

    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(title: const Text('Mijn Ritten')),
      body: upcoming.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_bike, size: 48, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('Nog geen ritten gepland', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Plan een rit vanuit Home of selecteer uren in de Agenda.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: upcoming.length,
              itemBuilder: (context, i) => _RideCard(
                ride: upcoming[i],
                allScores: allScores,
                forecasts: forecasts,
                cityName: cityName,
              ),
            ),
    ),
        if (_showHints && upcoming.isNotEmpty)
          ScreenHintOverlay(
            hints: ridesHints,
            onDismiss: () {
              markHintSeen('rides');
              setState(() => _showHints = false);
            },
          ),
      ],
    );
  }
}

class _RideCard extends ConsumerWidget {
  const _RideCard({
    required this.ride,
    required this.allScores,
    required this.forecasts,
    required this.cityName,
  });

  final PlannedRide ride;
  final List<HourlyScore> allScores;
  final List<HourlyForecast> forecasts;
  final String cityName;

  List<HourlyScore> _rideScores() {
    final result = <HourlyScore>[];
    var t = ride.start;
    while (t.isBefore(ride.end)) {
      for (final s in allScores) {
        if (s.time.year == t.year && s.time.month == t.month &&
            s.time.day == t.day && s.time.hour == t.hour) {
          result.add(s);
          break;
        }
      }
      t = t.add(const Duration(hours: 1));
    }
    return result;
  }

  List<HourlyForecast> _rideForecasts() {
    final result = <HourlyForecast>[];
    var t = ride.start;
    while (t.isBefore(ride.end)) {
      for (final f in forecasts) {
        if (f.time.year == t.year && f.time.month == t.month &&
            f.time.day == t.day && f.time.hour == t.hour) {
          result.add(f);
          break;
        }
      }
      t = t.add(const Duration(hours: 1));
    }
    return result;
  }

  double? _avgScore(List<HourlyScore> scores) {
    if (scores.isEmpty) return null;
    return scores.fold(0.0, (s, h) => s + h.overall) / scores.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scores = _rideScores();
    final rideForecasts = _rideForecasts();
    final currentScore = _avgScore(scores);
    final delta = currentScore != null ? currentScore - ride.plannedScore : null;
    final tierColor = currentScore != null ? _scoreColor(currentScore) : Colors.grey;
    final tierText = currentScore != null ? _tierLabel(currentScore) : '?';

    // Avg weather
    double? avgTemp, avgRain, avgWind, avgWindDir;
    if (rideForecasts.isNotEmpty) {
      avgTemp = rideForecasts.fold(0.0, (s, f) => s + (f.temperatureC ?? 0)) / rideForecasts.length;
      avgRain = rideForecasts.fold(0.0, (s, f) => s + (f.precipitationProbability ?? 0)) / rideForecasts.length;
      avgWind = rideForecasts.fold(0.0, (s, f) => s + (f.windspeedKmh ?? 0)) / rideForecasts.length;
      // Circular mean for wind direction
      double sinSum = 0, cosSum = 0;
      for (final f in rideForecasts) {
        final d = (f.winddirectionDeg ?? 0) * math.pi / 180;
        sinSum += math.sin(d);
        cosSum += math.cos(d);
      }
      avgWindDir = (math.atan2(sinSum, cosSum) * 180 / math.pi + 360) % 360;
    }

    return Dismissible(
      key: ValueKey('${ride.start.toIso8601String()}_${ride.end.toIso8601String()}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) {
        ref.read(plannedRidesProvider.notifier).remove(ride);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rit verwijderd')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDetail(context, ref, scores, rideForecasts, currentScore, avgWindDir),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            PlannedRidesScreen._dayFmt.format(ride.start),
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_fmtTime(ride.start)} – ${_fmtTime(ride.end)}  (${ride.durationHours}u)',
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (cityName.isNotEmpty)
                            Text(cityName, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: tierColor, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            currentScore != null ? '${currentScore.round()} $tierText' : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        if (delta != null && delta.abs() >= 2) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                delta > 0 ? Icons.trending_up : Icons.trending_down,
                                size: 14,
                                color: delta > 0 ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${delta > 0 ? '+' : ''}${delta.round()} sinds planning',
                                style: TextStyle(fontSize: 11, color: delta > 0 ? const Color(0xFF2E7D32) : const Color(0xFFE53935)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (avgTemp != null) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _WeatherChip(icon: Icons.thermostat, value: '${avgTemp.round()}°C'),
                      const SizedBox(width: 12),
                      _WeatherChip(icon: Icons.water_drop, value: '${avgRain!.round()}%'),
                      const SizedBox(width: 12),
                      _WeatherChip(icon: Icons.air, value: '${avgWind!.round()} km/h ${_windDirection(avgWindDir)}'),
                    ],
                  ),
                  // Wind advice
                  if (avgWind != null && avgWind > 5) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Transform.rotate(
                          angle: (avgWindDir ?? 0) * math.pi / 180,
                          child: Icon(Icons.navigation, size: 14, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _tailwindAdvice(avgWindDir),
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    WidgetRef ref,
    List<HourlyScore> scores,
    List<HourlyForecast> rideForecasts,
    double? currentScore,
    double? avgWindDir,
  ) {
    final theme = Theme.of(context);
    final dayFmt = DateFormat('EEEE d MMMM', 'nl_NL');
    final tierColor = currentScore != null ? _scoreColor(currentScore) : Colors.grey;
    final tierText = currentScore != null ? _tierLabel(currentScore) : '?';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dayFmt.format(ride.start),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${_fmtTime(ride.start)} – ${_fmtTime(ride.end)}  (${ride.durationHours}u)',
                          style: theme.textTheme.bodyLarge),
                      if (cityName.isNotEmpty) Text(cityName, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: tierColor, borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    currentScore != null ? '${currentScore.round()} $tierText' : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),

            // Wind advice
            if (avgWindDir != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Transform.rotate(
                      angle: avgWindDir * math.pi / 180,
                      child: Icon(Icons.navigation, size: 20, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wind uit ${_windDirection(avgWindDir)}. ${_tailwindAdvice(avgWindDir)}.',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text('Per uur', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),

            // Hourly breakdown table
            for (var i = 0; i < rideForecasts.length; i++) ...[
              _HourRow(
                forecast: rideForecasts[i],
                score: i < scores.length ? scores[i] : null,
              ),
              if (i < rideForecasts.length - 1) const Divider(height: 1),
            ],

            // Score breakdown (averages)
            if (scores.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Gemiddelde score-opbouw', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              _ScoreBar(label: 'Temperatuur',
                  value: scores.fold(0.0, (s, h) => s + h.temperatureScore) / scores.length),
              const SizedBox(height: 4),
              _ScoreBar(label: 'Regen',
                  value: scores.fold(0.0, (s, h) => s + h.rainScore) / scores.length),
              const SizedBox(height: 4),
              _ScoreBar(label: 'Wind',
                  value: scores.fold(0.0, (s, h) => s + h.windScore) / scores.length),
            ],

            // Delete
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              onPressed: () {
                ref.read(plannedRidesProvider.notifier).remove(ride);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rit verwijderd')),
                );
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Rit verwijderen'),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Hourly row in detail sheet --

class _HourRow extends StatelessWidget {
  const _HourRow({required this.forecast, this.score});
  final HourlyForecast forecast;
  final HourlyScore? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${forecast.time.hour}:00',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (score != null)
            Container(
              width: 32,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _scoreColor(score!.overall),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${score!.overall.round()}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          else
            const SizedBox(width: 32),
          const SizedBox(width: 8),
          Icon(Icons.thermostat, size: 14, color: theme.colorScheme.onSurfaceVariant),
          Text(' ${forecast.temperatureC?.round() ?? '?'}°', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Icon(Icons.water_drop, size: 14, color: theme.colorScheme.onSurfaceVariant),
          Text(' ${forecast.precipitationProbability?.round() ?? '?'}%', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Icon(Icons.air, size: 14, color: theme.colorScheme.onSurfaceVariant),
          Expanded(
            child: Text(
              ' ${forecast.windspeedKmh?.round() ?? '?'} km/h ${_windDirection(forecast.winddirectionDeg)}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// -- Helpers --

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 3),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation(_scoreColor(value)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text('${value.round()}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
