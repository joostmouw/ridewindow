import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/features/detail/detail_args.dart';
import 'package:ridewindow/features/peloton/buddies_tab.dart';
import 'package:ridewindow/features/shared/daylight_note.dart';
import 'package:ridewindow/features/shared/ride_role_style.dart';
import 'package:ridewindow/features/shared/screen_hint_overlay.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/hourly_scores_provider.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/ride_entries_provider.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/theme/app_icons.dart';
import 'package:ridewindow/theme/app_theme.dart';

({Color bg, Color fg}) _scoreTonal(double score, RideWindowTheme rw) {
  final t = rw.tiers;
  if (score >= 85) return (bg: t.perfectBg, fg: t.perfectFg);
  if (score >= 70) return (bg: t.greatBg, fg: t.greatFg);
  if (score >= 50) return (bg: t.acceptableBg, fg: t.acceptableFg);
  return (bg: t.poorBg, fg: t.poorFg);
}

String _tierLabel(double score, BuildContext context) {
  final s = S.of(context);
  if (score >= 85) return s.tierPerfect;
  if (score >= 70) return s.tierGreat;
  if (score >= 50) return s.tierAcceptable;
  return s.tierPoor;
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
    s.compassNW,
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
    s.tailwindNorthwest,
  ];
  return dirs[((deg + 22.5) % 360 ~/ 45).toInt()];
}

String _fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:00';

/// Vorm van een rit-kaart. De Dismissible-achtergrond en de InkWell-ripple
/// gebruiken dezelfde waarden, anders veeg je een rechthoek weg onder een kaart
/// met afgeronde hoeken.
const _cardMargin = EdgeInsets.symmetric(horizontal: 12, vertical: 4);
const double _cardRadius = 24;

/// Rides bestaat uit twee tabs: **alle** ritten, en je maatjes.
///
/// **Dat was tot 2026-09-08 anders, en dat was het probleem.** Tab 1 heette
/// "Mijn ritten" en toonde alleen `planned_rides`; tab 2 heette "Peloton" en
/// toonde de gedeelde ritten in drie secties. Wat je organiseerde stond dus
/// niet bij je ritten, en om je week te overzien moest je twee tabbladen naast
/// elkaar leggen. Nu staan alle vier de soorten in één chronologische lijst met
/// een filterrij erboven, en gaat tab 2 alleen nog over relaties (schets 008,
/// variant A).
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
    final entries = ref.watch(rideEntriesProvider);

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
                Tab(text: S.of(context).ridesTabRides),
                Tab(text: S.of(context).ridesTabBuddies),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              RidesTab(firstRideKey: _firstRideKey),
              const BuddiesTab(),
            ],
          ),
        ),
        if (_showHints && entries.isNotEmpty)
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

/// Wat een [RideCard] met een rit kan laten doen.
///
/// **Waarom dit niet in de kaart zelf zit.** Afzeggen haalt de rit uit de
/// lijst, dus de kaart verdwijnt op datzelfde moment uit de boom -- en daarmee
/// de `State` waarop de snackbar-actie "Ongedaan maken" zou terugvallen. Die
/// knop deed dan niets meer, en `peloton_withdraw_test.dart` liet dat meteen
/// zien. De handelingen horen dus bij de lijst, die blijft staan, en de kaart
/// krijgt ze aangereikt.
abstract class RideCardHost {
  bool get busy;

  Future<void> respond(RideEntry entry, {required bool accepted});
  Future<void> withdraw(RideEntry entry);
  Future<void> cancelOwnRide(RideEntry entry);

  /// Vraagt bevestiging voor een veeg. Bij een rit die je organiseert is dat
  /// een dialoog -- daar hangen andere mensen aan. Bij een solo-rit niet: die
  /// haal je terug met de snackbar.
  Future<bool> confirmRemove(RideEntry entry);

  void removePlanned(RideEntry entry);
}

/// Alle ritten, chronologisch, met een filterrij erboven.
///
/// Openbaar zodat een test hem los kan pompen zonder een `Scaffold` met tabs
/// eromheen te bouwen.
class RidesTab extends ConsumerStatefulWidget {
  const RidesTab({super.key, this.firstRideKey});

  final GlobalKey? firstRideKey;

  @override
  ConsumerState<RidesTab> createState() => _RidesTabState();
}

class _RidesTabState extends ConsumerState<RidesTab> implements RideCardHost {
  /// `null` = alles. Geen aparte enum: "alles" is de afwezigheid van een rol.
  RideRole? _filter;

  bool _busy = false;

  @override
  bool get busy => _busy;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _invalidatePeloton() => ref.invalidate(groupRidesProvider);

  @override
  Future<void> respond(RideEntry entry, {required bool accepted}) =>
      _run(() async {
        final group = entry.group;
        if (group == null) return;
        await ref
            .read(pelotonGatewayProvider)
            .respondToRide(rideId: group.id, accepted: accepted);
        _invalidatePeloton();
      });

  /// Terugkomen op een "ik ga mee".
  ///
  /// **Waarom hier een ongedaan-maken zit en bij [respond] niet.** Afzeggen is
  /// een deur die maar één kant op gaat: een rit met status `declined` valt uit
  /// alle drie de providers en is daarna nergens meer aan te wijzen, terwijl de
  /// rij in de database gewoon bestaat en het RLS-beleid
  /// `group_ride_participants_update_own` een terugweg toestaat. Een misklik
  /// zou dus onherstelbaar zijn zonder dat daar een technische reden voor is.
  @override
  Future<void> withdraw(RideEntry entry) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await respond(entry, accepted: false);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(s.pelotonWithdrawn),
        action: SnackBarAction(
          label: s.pelotonUndo,
          onPressed: () async {
            await respond(entry, accepted: true);
            if (!mounted) return;
            messenger.showSnackBar(SnackBar(content: Text(s.pelotonRejoined)));
          },
        ),
      ),
    );
  }

  /// De rit die jij organiseert helemaal afzeggen.
  ///
  /// **Dit ontbrak.** `deleteGroupRide` stond sinds epic #62 in de poort en het
  /// RLS-beleid `group_rides_delete_own` stond het toe, maar geen enkel scherm
  /// riep het aan -- als organisator kwam je er niet meer vanaf. Dat viel niet
  /// op zolang je eigen geplande rit los weg te vegen was; nu die twee één
  /// kaart zijn, zou het gat een echte doodlopende weg worden.
  @override
  Future<void> cancelOwnRide(RideEntry entry) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final group = entry.group;
    if (group == null) return;

    await _run(() async {
      try {
        await ref.read(pelotonGatewayProvider).deleteGroupRide(group.id);
      } catch (error) {
        debugPrint('Peloton: afzeggen mislukt: $error');
        messenger.showSnackBar(SnackBar(content: Text(s.pelotonCancelFailed)));
        return;
      }
      // De persoonlijke rij eronder gaat mee. Laat je die staan, dan komt de
      // rit terug als "Alleen jij" en lijkt het afzeggen mislukt.
      final planned = entry.planned;
      if (planned != null) {
        await ref.read(plannedRidesProvider.notifier).remove(planned);
      }
      _invalidatePeloton();
      messenger.showSnackBar(SnackBar(content: Text(s.pelotonRideCancelled)));
    });
  }

  @override
  Future<bool> confirmRemove(RideEntry entry) async {
    if (entry.role != RideRole.organiser) return true;
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.pelotonCancelRideTitle),
        content: Text(s.pelotonCancelRideBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.pelotonCancelRide),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  void removePlanned(RideEntry entry) {
    final planned = entry.planned;
    if (planned == null) return;
    ref.read(plannedRidesProvider.notifier).remove(planned);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).rideRemoved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    final entries = ref.watch(rideEntriesProvider);
    final allScores = ref.watch(allHourlyScoresProvider);
    final forecasts = ref.watch(weatherProvider).value ?? <HourlyForecast>[];
    final location = ref.watch(locationProvider).value;
    final cityName = location?.city ?? '';

    if (entries.isEmpty) {
      return _EmptyState(
        icon: AppIcons.bicycle,
        title: s.ridesEmpty,
        hint: s.ridesEmptyHint,
        theme: theme,
      );
    }

    final counts = countByRole(entries);
    // Een filter dat op nul staat verdwijnt: een chip die gegarandeerd een lege
    // lijst oplevert is geen keuze maar een valstrik. "Wacht op jou" is er
    // daardoor alleen als er werkelijk iets op je wacht.
    final visibleFilters = [
      for (final role in RideRole.values)
        if (counts[role]! > 0) role,
    ];
    // Verdween de rol waarop gefilterd stond -- je beantwoordde de laatste
    // uitnodiging -- val dan terug op alles in plaats van op een leeg scherm.
    final filter = visibleFilters.contains(_filter) ? _filter : null;

    final shown =
        (filter == null ? entries : entries.where((e) => e.role == filter))
            .toList();

    return Column(
      children: [
        _FilterRow(
          total: entries.length,
          counts: counts,
          roles: visibleFilters,
          selected: filter,
          onSelect: (role) => setState(() => _filter = role),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            itemCount: shown.length,
            itemBuilder: (context, i) => RideCard(
              key: i == 0 ? widget.firstRideKey : null,
              entry: shown[i],
              host: this,
              allScores: allScores,
              forecasts: forecasts,
              cityName: cityName,
              location: location,
            ),
          ),
        ),
      ],
    );
  }
}

/// De filterrij: een tekstrij met tellingen, dezelfde vorm als het
/// periodefilter op Home.
///
/// De telling staat erbij en is het punt van dit ding -- "Ik organiseer 2"
/// beantwoordt de vraag al voordat je erop tikt.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.total,
    required this.counts,
    required this.roles,
    required this.selected,
    required this.onSelect,
  });

  final int total;
  final Map<RideRole, int> counts;
  final List<RideRole> roles;
  final RideRole? selected;
  final ValueChanged<RideRole?> onSelect;

  String _label(BuildContext context, RideRole role) {
    final s = S.of(context);
    return switch (role) {
      RideRole.pending => s.ridesFilterPending,
      RideRole.organiser => s.ridesFilterOrganising,
      RideRole.joined => s.ridesFilterJoined,
      RideRole.solo => s.ridesFilterSolo,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Eén rol plus "alles" is geen keuze -- dan verbergt de rij zichzelf, en
    // dat scheelt een regel ruis boven de lijst.
    if (roles.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _FilterItem(
            label: s.ridesFilterAll,
            count: total,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final role in roles)
            _FilterItem(
              label: _label(context, role),
              count: counts[role]!,
              selected: selected == role,
              onTap: () => onSelect(role),
            ),
        ],
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  const _FilterItem({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rw = context.rw;
    final color = selected ? rw.textPrimary : rw.textTertiary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color.withValues(alpha: 0.65),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // De selectie is een onderstreping en geen gevulde chip -- dezelfde
            // taal als de dagstrip en het periodefilter sinds fase 23.
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: selected ? rw.textPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.hint,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String hint;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              hint,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Eén rit in de lijst, welke rol je er ook in hebt.
///
/// Vier soorten, één vorm. Het verschil zit in de rolregel onder de tijd en in
/// wat eraan hangt aan handelingen -- en verder in niets. Een gedeelde rit is
/// geen ander soort ding dan een eigen rit, er zitten alleen meer mensen in.
class RideCard extends StatelessWidget {
  const RideCard({
    super.key,
    required this.entry,
    required this.host,
    required this.allScores,
    required this.forecasts,
    required this.cityName,
    required this.location,
  });

  final RideEntry entry;

  /// Wie de handelingen uitvoert. Zie [RideCardHost] voor waarom dat niet de
  /// kaart zelf is.
  final RideCardHost host;

  final List<HourlyScore> allScores;
  final List<HourlyForecast> forecasts;
  final String cityName;

  /// Waar je bent, of `null` als de app dat niet weet. Nodig voor de zonstand;
  /// zonder locatie blijft de daglichtregel gewoon weg.
  final LocationData? location;

  List<HourlyScore> _rideScores() {
    final result = <HourlyScore>[];
    var t = entry.start;
    while (t.isBefore(entry.end)) {
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
    var t = entry.start;
    while (t.isBefore(entry.end)) {
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

  void _openDetail(
    BuildContext context,
    List<HourlyScore> scores,
    List<HourlyForecast> rideForecasts,
    double? currentScore,
  ) {
    final slot = RideSlot(
      start: entry.start,
      end: entry.end,
      overallScore: currentScore ?? entry.plannedScore,
      tier: rideTierFromScore(currentScore ?? entry.plannedScore),
      hours: scores,
    );
    context.push(
      '/detail',
      extra: DetailArgs(slot: slot, forecasts: rideForecasts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final rw = context.rw;
    final scores = _rideScores();
    final rideForecasts = _rideForecasts();
    final currentScore = _avgScore(scores);
    final delta =
        currentScore != null ? currentScore - entry.plannedScore : null;
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

    final summary = pelotonSummary(context, entry);

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(_cardRadius),
          // Rechtstreeks naar het detailscherm, precies zoals een tik op een
          // ritkaart op Home doet -- óók bij een gedeelde rit. Dat die niet
          // aantikbaar waren was Joost's tweede punt (schets 008): de rijen op
          // de Peloton-tab waren `ListTile`s zonder `onTap`, terwijl elke eigen
          // rit wél doorging.
          onTap: () =>
              _openDetail(context, scores, rideForecasts, currentScore),
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
                              Localizations.localeOf(context).languageCode ==
                                      'en'
                                  ? 'en_US'
                                  : 'nl_NL',
                            ).format(entry.start),
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_fmtTime(entry.start)} – ${_fmtTime(entry.end)}  (${entry.durationHours}u)',
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (cityName.isNotEmpty)
                            Text(cityName, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 6),
                          RideRoleLine(entry: entry),
                          if (location case final loc?)
                            DaylightNote(
                              start: entry.start,
                              end: entry.end,
                              latitude: loc.lat,
                              longitude: loc.lon,
                              dense: true,
                            ),
                          if (summary != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              summary,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentScore != null
                                ? '${currentScore.round()} $tierText'
                                : '?',
                            style: TextStyle(
                              color: tonal.fg,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
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
                                color: delta > 0 ? rw.scorePerfect : rw.error,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                s.rideSincePlanning(
                                    '${delta > 0 ? '+' : ''}${delta.round()}'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: delta > 0 ? rw.scorePerfect : rw.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Andermans rit gooi je niet weg, je zegt af. Een
                        // tekstknop en geen kruisje: een kruisje naast
                        // andermans rit leest als "verwijder deze rit", en dat
                        // is precies wat hier níét gebeurt -- de rit blijft
                        // bestaan, jij gaat alleen niet mee.
                        if (entry.role == RideRole.joined) ...[
                          const SizedBox(height: 2),
                          TextButton(
                            onPressed:
                                host.busy ? null : () => host.withdraw(entry),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(s.pelotonWithdraw),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Antwoorden kan hier, in de lijst. Wie een uitnodiging ziet
                // wil hem beantwoorden, niet eerst ergens anders heen.
                if (entry.role == RideRole.pending) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: host.busy
                            ? null
                            : () => host.respond(entry, accepted: false),
                        child: Text(s.pelotonDecline),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: host.busy
                            ? null
                            : () => host.respond(entry, accepted: true),
                        child: Text(s.pelotonAccept),
                      ),
                    ],
                  ),
                ],
                if (avgTemp != null) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _WeatherChip(
                        icon: AppIcons.thermometerSimple,
                        value: avgApparent != null &&
                                (avgApparent - avgTemp).abs() >= 2
                            ? '${avgTemp.round()}° (${avgApparent.round()}°)'
                            : '${avgTemp.round()}°C',
                      ),
                      const SizedBox(width: 12),
                      _WeatherChip(
                        icon: AppIcons.drop,
                        value: avgRainProb != null && avgRainProb > 0
                            ? '${avgRain!.toStringAsFixed(1)}mm (${avgRainProb.round()}%)'
                            : '${avgRain!.toStringAsFixed(1)}mm',
                      ),
                      const SizedBox(width: 12),
                      _WeatherChip(
                        icon: AppIcons.wind,
                        value: avgWind! < 5
                            ? s.windCalm
                            : avgWindDir != null
                                ? '${avgWind.round()} km/h ${_windDirection(avgWindDir, context)}'
                                : '${avgWind.round()} km/h',
                      ),
                    ],
                  ),
                  // Wind advice
                  if (avgWind >= 5 && avgWindDir != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Transform.rotate(
                          angle: avgWindDir * math.pi / 180,
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
                              fontStyle: FontStyle.italic,
                            ),
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

    // Alleen wat van jou alleen is, is weg te vegen. Bij andermans rit staat er
    // een afzegknop op de kaart; die veeg je niet weg, want de rit blijft
    // bestaan -- jij gaat er alleen niet meer heen.
    if (!entry.isRemovable) {
      return Padding(padding: _cardMargin, child: card);
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
          key: ValueKey(entry.key),
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
          confirmDismiss: (_) => host.confirmRemove(entry),
          onDismissed: (_) => entry.role == RideRole.organiser
              ? host.cancelOwnRide(entry)
              : host.removePlanned(entry),
          // Deze clip beweegt mét de kaart mee en maakt er een écht afgerond
          // blok van. De `ClipRRect` hierboven staat stil en zou de kaart bij
          // het wegschuiven langs een rechte lijn afsnijden; de `shape` van de
          // `Card` rondt alleen zijn rustpositie af. Zelfde constructie als op
          // Home.
          child: card,
        ),
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
