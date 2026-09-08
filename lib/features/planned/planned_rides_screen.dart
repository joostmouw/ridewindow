import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/features/peloton/peloton_tab.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
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
import 'package:ridewindow/theme/app_icons.dart';

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
  final dirs = [
    s.compassN,
    s.compassNE,
    s.compassE,
    s.compassSE,
    s.compassS,
    s.compassSW,
    s.compassW,
    s.compassNW
  ];
  return dirs[((deg + 22.5) % 360 ~/ 45)];
}

/// Wind comes FROM this direction. To have tailwind on the return,
/// ride INTO the wind first = ride towards the wind source.
/// Wind from N (0°) → ride north first, return south with tailwind.
String _tailwindAdvice(double? deg, BuildContext context) {
  if (deg == null) return '';
  final s = S.of(context);
  final dirs = [
    s.tailwindNorth,
    s.tailwindNortheast,
    s.tailwindEast,
    s.tailwindSoutheast,
    s.tailwindSouth,
    s.tailwindSouthwest,
    s.tailwindWest,
    s.tailwindNorthwest
  ];
  return dirs[((deg + 22.5) % 360 ~/ 45).toInt()];
}

String _fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:00';

/// Vorm van een rit-kaart. De Dismissible-achtergrond en de InkWell-ripple
/// gebruiken dezelfde waarden, anders veeg je een rechthoek weg onder een kaart
/// met afgeronde hoeken.
const _cardMargin = EdgeInsets.symmetric(horizontal: 12, vertical: 4);
const double _cardRadius = 24;

/// Rides bestaat sinds epic #62 uit twee tabs: je eigen geplande ritten en
/// Peloton, waar je met je maatjes schakelt. Bewust tabs en geen aparte
/// bottom-nav-ingang -- de twee horen bij elkaar, want uitnodigen begint bij
/// een rit die je zelf al gepland hebt.
class PlannedRidesScreen extends ConsumerStatefulWidget {
  const PlannedRidesScreen({super.key});

  @override
  ConsumerState<PlannedRidesScreen> createState() => _PlannedRidesScreenState();
}

class _PlannedRidesScreenState extends ConsumerState<PlannedRidesScreen>
    with SingleTickerProviderStateMixin {
  bool _showHints = false;
  late final TabController _tabController;

  // Keys for spotlight coach marks
  final _firstRideKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Delay to ensure ListView has laid out the first card for spotlight measurement
      await Future.delayed(const Duration(milliseconds: 500));
      if (await shouldShowHint('rides') && mounted) {
        setState(() => _showHints = true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<HintItem> _ridesHints(BuildContext context) {
    final s = S.of(context);
    return [
      HintItem(
        targetKey: _firstRideKey,
        gestureIcon: AppIcons.handPointing,
        title: s.hintTapSummary,
        description: s.hintTapSummaryDesc,
        spotlightPadding: 4,
      ),
      HintItem(
        targetKey: _firstRideKey,
        gestureIcon: AppIcons.handSwipeRight,
        title: s.hintSwipeDelete,
        description: s.hintSwipeDeleteDesc,
        spotlightPadding: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rides =
        ref.watch(plannedRidesProvider).value ?? const <PlannedRide>[];
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
          appBar: AppBar(
            title: Text(S.of(context).ridesTitle),
            actions: [
              IconButton(
                icon: const Icon(AppIcons.info, size: 20),
                tooltip: S.of(context).showTips,
                onPressed: () => setState(() => _showHints = true),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: S.of(context).ridesTabMine),
                Tab(text: S.of(context).ridesTabPeloton),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMyRides(
                context,
                upcoming,
                allScores,
                forecasts,
                cityName,
                theme,
              ),
              const PelotonTab(),
            ],
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

  /// De oorspronkelijke inhoud van dit scherm, ongewijzigd -- alleen verhuisd
  /// naar een eigen methode zodat hij als tab-inhoud kan dienen.
  Widget _buildMyRides(
    BuildContext context,
    List<PlannedRide> upcoming,
    List<HourlyScore> allScores,
    List<HourlyForecast> forecasts,
    String cityName,
    ThemeData theme,
  ) {
    // De lege staat mag niet liegen.
    //
    // Hij zei "nog geen ritten gepland" terwijl er één tab verder een gedeelde
    // rit stond waar je ja op had gezegd (waargenomen door Joost, fase 25 in
    // EIGEN-GEZICHT.md). Dat een gedeelde rit hier niet staat is een bewuste
    // keuze -- `planned_rides` blijft strikt persoonlijk, keuze 2 van epic #62
    // -- maar die keuze mag de gebruiker niet als tegenspraak voorgeschoteld
    // krijgen. Dus: benoem wat er wél is, en zet de stap ernaartoe als knop
    // neer in plaats van iemand zelf te laten zoeken.
    final joined =
        ref.watch(joinedGroupRidesProvider).value ?? const <GroupRide>[];

    return upcoming.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.bicycle,
                      size: 48, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(S.of(context).ridesEmpty,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    joined.isEmpty
                        ? S.of(context).ridesEmptyHint
                        : S.of(context).ridesEmptySharedHint(joined.length),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (joined.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () => _tabController.animateTo(1),
                      icon: const Icon(AppIcons.usersThree, size: 18),
                      label: Text(S.of(context).ridesEmptyGoToPeloton),
                    ),
                  ],
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
        if (s.time.year == t.year &&
            s.time.month == t.month &&
            s.time.day == t.day &&
            s.time.hour == t.hour) {
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
        if (f.time.year == t.year &&
            f.time.month == t.month &&
            f.time.day == t.day &&
            f.time.hour == t.hour) {
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
    final delta =
        currentScore != null ? currentScore - ride.plannedScore : null;
    final tonal = currentScore != null
        ? _scoreTonal(currentScore, rw)
        : (bg: rw.tiers.poorBg, fg: rw.tiers.poorFg);
    final tierText =
        currentScore != null ? _tierLabel(currentScore, context) : '?';

    // Avg weather
    double? avgTemp, avgApparent, avgRain, avgRainProb, avgWind, avgWindDir;
    if (rideForecasts.isNotEmpty) {
      avgTemp = rideForecasts.fold(0.0, (s, f) => s + (f.temperatureC ?? 0)) /
          rideForecasts.length;
      avgRain = rideForecasts.fold<double>(
          0.0, (s, f) => s + (f.precipitationMm ?? 0.0));
      avgRainProb = rideForecasts.fold(
              0.0, (s, f) => s + (f.precipitationProbability ?? 0)) /
          rideForecasts.length;
      avgWind = rideForecasts.fold(0.0, (s, f) => s + (f.windspeedKmh ?? 0)) /
          rideForecasts.length;
      final apparents = rideForecasts
          .map((f) => f.apparentTemperatureC)
          .whereType<double>()
          .toList();
      avgApparent = apparents.isEmpty
          ? null
          : apparents.reduce((a, b) => a + b) / apparents.length;
      // Circular mean for wind direction
      double sinSum = 0, cosSum = 0;
      for (final f in rideForecasts) {
        final d = (f.winddirectionDeg ?? 0) * math.pi / 180;
        sinSum += math.sin(d);
        cosSum += math.cos(d);
      }
      avgWindDir = (math.atan2(sinSum, cosSum) * 180 / math.pi + 360) % 360;
    }

    // De hele Dismissible zit in één afgeronde clip: zowel de wegschuivende
    // kaart als de rode achtergrond erachter krijgen daarmee exact de vorm van
    // het blokje. Alleen de achtergrond afronden volstond niet — dan heeft niets
    // de bewegende kaart zelf nog naar die vorm gedwongen.
    return Padding(
      padding: _cardMargin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Dismissible(
          key: ValueKey(
              '${ride.start.toIso8601String()}_${ride.end.toIso8601String()}'),
          direction: DismissDirection.endToStart,
          // Geen gekleurd vlak, alleen het icoon op de gewone achtergrond —
          // dezelfde behandeling als de ritkaarten op Home (2026-09-07).
          //
          // `Dismissible` knipt zijn achtergrond af tot het onthulde stuk, en
          // die knip loopt kaarsrecht langs de rand van de kaart. Een gekleurd
          // blok houdt daar dus altijd een hoek van 90° over, hoeveel radius je
          // er ook op zet — op een scherm vol radius 24 valt dat meteen op. Wat
          // niet bestaat kan ook niet vierkant afgeknipt worden.
          background: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Icon(AppIcons.trash, color: theme.colorScheme.error),
            ),
          ),
          onDismissed: (_) {
            ref.read(plannedRidesProvider.notifier).remove(ride);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).rideRemoved)),
            );
          },
          // Deze clip beweegt mét de kaart mee en maakt er een écht afgerond
          // blok van. De `ClipRRect` hierboven staat stil en zou de kaart bij
          // het wegschuiven langs een rechte lijn afsnijden; de `shape` van de
          // `Card` rondt alleen zijn rustpositie af. Zelfde constructie als op
          // Home.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_cardRadius),
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(_cardRadius),
                // Rechtstreeks naar het detailscherm, precies zoals een tik
                // op een ritkaart op Home doet.
                onTap: () {
                  final slot = RideSlot(
                    start: ride.start,
                    end: ride.end,
                    overallScore: currentScore ?? ride.plannedScore,
                    tier: rideTierFromScore(currentScore ?? ride.plannedScore),
                    hours: scores,
                  );
                  context.push(
                    '/detail',
                    extra: DetailArgs(slot: slot, forecasts: rideForecasts),
                  );
                },
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
                                  DateFormat(
                                          'EEEE d MMM',
                                          Localizations.localeOf(context)
                                                      .languageCode ==
                                                  'en'
                                              ? 'en_US'
                                              : 'nl_NL')
                                      .format(ride.start),
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_fmtTime(ride.start)} – ${_fmtTime(ride.end)}  (${ride.durationHours}u)',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                if (cityName.isNotEmpty)
                                  Text(cityName,
                                      style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: tonal.bg,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  currentScore != null
                                      ? '${currentScore.round()} $tierText'
                                      : '?',
                                  style: TextStyle(
                                      color: tonal.fg,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                              if (delta != null && delta.abs() >= 2) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      delta > 0
                                          ? AppIcons.trendUp
                                          : AppIcons.trendDown,
                                      size: 14,
                                      color: delta > 0
                                          ? rw.scorePerfect
                                          : rw.error,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      S.of(context).rideSincePlanning(
                                          '${delta > 0 ? '+' : ''}${delta.round()}'),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: delta > 0
                                              ? rw.scorePerfect
                                              : rw.error),
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
                            _WeatherChip(
                                icon: AppIcons.thermometerSimple,
                                value: avgApparent != null &&
                                        (avgApparent - avgTemp!).abs() >= 2
                                    ? '${avgTemp.round()}° (${avgApparent.round()}°)'
                                    : '${avgTemp.round()}°C'),
                            const SizedBox(width: 12),
                            _WeatherChip(
                                icon: AppIcons.drop,
                                value: avgRainProb != null && avgRainProb > 0
                                    ? '${avgRain!.toStringAsFixed(1)}mm (${avgRainProb.round()}%)'
                                    : '${avgRain!.toStringAsFixed(1)}mm'),
                            const SizedBox(width: 12),
                            _WeatherChip(
                                icon: AppIcons.wind,
                                value: avgWind! < 5
                                    ? S.of(context).windCalm
                                    : avgWindDir != null
                                        ? '${avgWind.round()} km/h ${_windDirection(avgWindDir, context)}'
                                        : '${avgWind.round()} km/h'),
                          ],
                        ),
                        // Wind advice
                        if (avgWind != null &&
                            avgWind >= 5 &&
                            avgWindDir != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Transform.rotate(
                                angle: (avgWindDir ?? 0) * math.pi / 180,
                                child: Icon(AppIcons.navigationArrow,
                                    size: 14, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _tailwindAdvice(avgWindDir, context),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.primary,
                                      fontStyle: FontStyle.italic),
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
          ),
        ),
      ),
    );
  }

  // Hier stond `_showDetail`: een bottom sheet met de rit, een knop "View
  // details" naar het detailscherm, en een verwijderknop.
  //
  // Weg, omdat dezelfde rit daarmee op twee manieren openging -- vanaf Home
  // rechtstreeks het detailscherm, vanaf hier eerst een tussenscherm dat je nog
  // een keer moest laten doorklikken (waargenomen door Joost, fase 25 in
  // EIGEN-GEZICHT.md). Twee routes naar hetzelfde ding is er een te veel, en de
  // route via Home was de kortere.
  //
  // Verwijderen kan nog steeds: veeg de kaart weg (daar wijst de hint
  // `hintSwipeDelete` ook op), of gebruik de knop op het detailscherm zelf.
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
