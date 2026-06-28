import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/features/detail/detail_args.dart';
import 'package:ridewindow/providers/hourly_scores_provider.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/features/shared/screen_hint_overlay.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

Color _scoreColor(double score, RideWindowTheme rw) {
  if (score >= 85) return rw.scorePerfect;
  if (score >= 70) return rw.scoreGreat;
  if (score >= 50) return rw.scoreAcceptable;
  return rw.scorePoor;
}

({Color bg, Color fg}) _scoreTonal(double score, RideWindowTheme rw) {
  final t = rw.tiers;
  if (score >= 85) return (bg: t.perfectBg, fg: t.perfectFg);
  if (score >= 70) return (bg: t.greatBg, fg: t.greatFg);
  if (score >= 50) return (bg: t.acceptableBg, fg: t.acceptableFg);
  return (bg: t.poorBg, fg: t.poorFg);
}

String _tierLabel(double score, BuildContext context) {
  final s = S.of(context);
  if (score >= 85) return s.tierPerfectAgenda;
  if (score >= 70) return s.tierGreatAgenda;
  if (score >= 50) return s.tierAcceptableAgenda;
  return s.tierPoorAgenda;
}

String _windDirection(double? deg, BuildContext context) {
  if (deg == null) return '?';
  final s = S.of(context);
  final dirs = [s.compassN, s.compassNE, s.compassE, s.compassSE, s.compassS, s.compassSW, s.compassW, s.compassNW];
  return dirs[((deg + 22.5) % 360 ~/ 45)];
}

/// Wind comes FROM this direction. To have tailwind on the return,
/// ride INTO the wind first = ride towards the wind source.
/// Wind from N (0°) → ride north first, return south with tailwind.
String _tailwindAdvice(double? deg, BuildContext context) {
  if (deg == null) return '';
  final s = S.of(context);
  final dirs = [s.tailwindNorth, s.tailwindNortheast, s.tailwindEast, s.tailwindSoutheast,
    s.tailwindSouth, s.tailwindSouthwest, s.tailwindWest, s.tailwindNorthwest];
  return dirs[((deg + 22.5) % 360 ~/ 45).toInt()];
}

String _fmtTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:00';

class PlannedRidesScreen extends ConsumerStatefulWidget {
  const PlannedRidesScreen({super.key});


  @override
  ConsumerState<PlannedRidesScreen> createState() => _PlannedRidesScreenState();
}

class _PlannedRidesScreenState extends ConsumerState<PlannedRidesScreen> {
  bool _showHints = false;

  // Keys for spotlight coach marks
  final _firstRideKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Delay to ensure ListView has laid out the first card for spotlight measurement
      await Future.delayed(const Duration(milliseconds: 500));
      if (await shouldShowHint('rides') && mounted) {
        setState(() => _showHints = true);
      }
    });
  }

  List<HintItem> _ridesHints(BuildContext context) {
    final s = S.of(context);
    return [
      HintItem(
        targetKey: _firstRideKey,
        gestureIcon: Icons.touch_app,
        title: s.hintTapSummary,
        description: s.hintTapSummaryDesc,
        spotlightPadding: 4,
      ),
      HintItem(
        targetKey: _firstRideKey,
        gestureIcon: Icons.swipe,
        title: s.hintSwipeDelete,
        description: s.hintSwipeDeleteDesc,
        spotlightPadding: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rides = ref.watch(plannedRidesProvider);
    final allScores = ref.watch(allHourlyScoresProvider);
    final forecasts = ref.watch(weatherProvider).value ?? <HourlyForecast>[];
    final cityName = ref.watch(locationProvider).value?.city ?? '';
    final theme = Theme.of(context);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final upcoming = rides.where((r) => r.end.isAfter(todayStart)).toList();

    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(title: Text(S.of(context).ridesTitle)),
      body: upcoming.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_bike, size: 48, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(S.of(context).ridesEmpty, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context).ridesEmptyHint,
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
                key: i == 0 ? _firstRideKey : null,
                ride: upcoming[i],
                allScores: allScores,
                forecasts: forecasts,
                cityName: cityName,
              ),
            ),
    ),
        if (_showHints && upcoming.isNotEmpty)
          ScreenHintOverlay(
            hints: _ridesHints(context),
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
    super.key,
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
    final rw = context.rw;
    final scores = _rideScores();
    final rideForecasts = _rideForecasts();
    final currentScore = _avgScore(scores);
    final delta = currentScore != null ? currentScore - ride.plannedScore : null;
    final tonal = currentScore != null ? _scoreTonal(currentScore, rw) : (bg: rw.tiers.poorBg, fg: rw.tiers.poorFg);
    final tierText = currentScore != null ? _tierLabel(currentScore, context) : '?';

    // Avg weather
    double? avgTemp, avgApparent, avgRain, avgRainProb, avgWind, avgWindDir;
    if (rideForecasts.isNotEmpty) {
      avgTemp = rideForecasts.fold(0.0, (s, f) => s + (f.temperatureC ?? 0)) / rideForecasts.length;
      avgRain = rideForecasts.fold<double>(0.0, (s, f) => s + (f.precipitationMm ?? 0.0));
      avgRainProb = rideForecasts.fold(0.0, (s, f) => s + (f.precipitationProbability ?? 0)) / rideForecasts.length;
      avgWind = rideForecasts.fold(0.0, (s, f) => s + (f.windspeedKmh ?? 0)) / rideForecasts.length;
      final apparents = rideForecasts.map((f) => f.apparentTemperatureC).whereType<double>().toList();
      avgApparent = apparents.isEmpty ? null : apparents.reduce((a, b) => a + b) / apparents.length;
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
          SnackBar(content: Text(S.of(context).rideRemoved)),
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
                            DateFormat('EEEE d MMM', Localizations.localeOf(context).languageCode == 'en' ? 'en_US' : 'nl_NL').format(ride.start),
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
                          decoration: BoxDecoration(color: tonal.bg, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            currentScore != null ? '${currentScore.round()} $tierText' : '?',
                            style: TextStyle(color: tonal.fg, fontWeight: FontWeight.bold, fontSize: 12),
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
                                color: delta > 0 ? rw.scorePerfect : rw.error,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                S.of(context).rideSincePlanning('${delta > 0 ? '+' : ''}${delta.round()}'),
                                style: TextStyle(fontSize: 11, color: delta > 0 ? rw.scorePerfect : rw.error),
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
                      _WeatherChip(icon: Icons.thermostat, value: avgApparent != null && (avgApparent - avgTemp!).abs() >= 2
                          ? '${avgTemp.round()}° (${avgApparent.round()}°)'
                          : '${avgTemp.round()}°C'),
                      const SizedBox(width: 12),
                      _WeatherChip(icon: Icons.water_drop, value: avgRainProb != null && avgRainProb > 0
                          ? '${avgRain!.toStringAsFixed(1)}mm (${avgRainProb.round()}%)'
                          : '${avgRain!.toStringAsFixed(1)}mm'),
                      const SizedBox(width: 12),
                      _WeatherChip(icon: Icons.air, value: avgWind! < 5
                          ? S.of(context).windCalm
                          : avgWindDir != null
                              ? '${avgWind.round()} km/h ${_windDirection(avgWindDir, context)}'
                              : '${avgWind.round()} km/h'),
                    ],
                  ),
                  // Wind advice
                  if (avgWind != null && avgWind >= 5 && avgWindDir != null) ...[
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
                            _tailwindAdvice(avgWindDir, context),
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
    final rw = context.rw;
    final dayFmt = DateFormat('EEEE d MMMM', Localizations.localeOf(context).languageCode == 'en' ? 'en_US' : 'nl_NL');
    final tonal = currentScore != null ? _scoreTonal(currentScore, rw) : (bg: rw.tiers.poorBg, fg: rw.tiers.poorFg);
    final tierText = currentScore != null ? _tierLabel(currentScore, context) : '?';

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
                  decoration: BoxDecoration(color: tonal.bg, borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    currentScore != null ? '${currentScore.round()} $tierText' : '?',
                    style: TextStyle(color: tonal.fg, fontWeight: FontWeight.bold, fontSize: 13),
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
                        S.of(context).ridesWindFrom(_windDirection(avgWindDir, context), _tailwindAdvice(avgWindDir, context)),
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text(S.of(context).ridesPerHour, style: theme.textTheme.labelLarge),
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
              Text(S.of(context).ridesAvgScoreBreakdown, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              _ScoreBar(label: S.of(context).weatherTemperature,
                  value: scores.fold(0.0, (s, h) => s + h.temperatureScore) / scores.length),
              const SizedBox(height: 4),
              _ScoreBar(label: S.of(context).agendaRain,
                  value: scores.fold(0.0, (s, h) => s + h.rainScore) / scores.length),
              const SizedBox(height: 4),
              _ScoreBar(label: S.of(context).weatherWind,
                  value: scores.fold(0.0, (s, h) => s + h.windScore) / scores.length),
            ],

            // Full detail
            if (scores.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final slot = RideSlot(
                      start: ride.start,
                      end: ride.end,
                      overallScore: currentScore ?? ride.plannedScore,
                      tier: rideTierFromScore(currentScore ?? ride.plannedScore),
                      hours: scores,
                    );
                    context.push('/detail', extra: DetailArgs(slot: slot, forecasts: rideForecasts));
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(S.of(context).agendaViewDetails),
                ),
              ),
            ],

            // Delete
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              onPressed: () {
                ref.read(plannedRidesProvider.notifier).remove(ride);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.of(context).rideRemoved)),
                );
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(S.of(context).ridesDeleteRide),
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
            Builder(builder: (_) {
              final t = _scoreTonal(score!.overall, context.rw);
              return Container(
                width: 32,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${score!.overall.round()}',
                  style: TextStyle(color: t.fg, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              );
            })
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
              forecast.windspeedKmh != null && forecast.windspeedKmh! < 5
                  ? ' ${S.of(context).hourlyWindstil}'
                  : forecast.windspeedKmh != null && forecast.windspeedKmh! >= 15 && forecast.winddirectionDeg != null
                      ? ' ${forecast.windspeedKmh!.round()} km/h ${_windDirection(forecast.winddirectionDeg, context)}'
                      : ' ${forecast.windspeedKmh?.round() ?? '?'} km/h',
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
    final rw = context.rw;
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: rw.border,
              valueColor: AlwaysStoppedAnimation(_scoreColor(value, rw)),
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
