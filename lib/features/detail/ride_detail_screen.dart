// lib/features/detail/ride_detail_screen.dart
// RideDetailScreen: full Wave 2 implementation + Phase 9 Google Calendar integratie.
// Toont score-banner, info-kaart "Weer", uurlijkse tabel en werkende agenda-knop.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_row.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/services/slot_generator.dart' show windVariabilityPenalty;
import 'package:ridewindow/features/detail/insights_sheet.dart';
import 'package:ridewindow/features/shared/score_badge.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/providers/hourly_scores_provider.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ridewindow/platform/notification_service.dart';
import 'package:ridewindow/services/calendar_service.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

const _pi = math.pi;
final _sin = math.sin;
final _cos = math.cos;
final _atan2 = math.atan2;

/// Factory typedef voor CalendarService — maakt dependency injection
/// in widget tests mogelijk zonder complexe DI-infrastructuur (PERS-04).
typedef CalendarServiceFactory = CalendarService Function();

CalendarService _defaultCalendarServiceFactory() => CalendarService();

class RideDetailScreen extends ConsumerStatefulWidget {
  final RideSlot slot;
  final List<HourlyForecast> forecasts;

  /// Optional Hero animation tag for ScoreBadge transition.
  final String? heroTag;

  /// Optionele factory voor testinjectie. Default maakt een echte CalendarService.
  final CalendarServiceFactory calendarServiceFactory;

  const RideDetailScreen({
    super.key,
    required this.slot,
    required this.forecasts,
    this.heroTag,
    this.calendarServiceFactory = _defaultCalendarServiceFactory,
  });

  @override
  ConsumerState<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends ConsumerState<RideDetailScreen> {
  bool _isLoading = false;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.slot.start;
    _end = widget.slot.end;
  }

  /// Get the effective slot hours and forecasts for the adjusted time range.
  List<HourlyScore> get _effectiveHours {
    final allScores = ref.read(allHourlyScoresProvider);
    return allScores
        .where((s) => !s.time.isBefore(_start) && s.time.isBefore(_end))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<HourlyForecast> get _effectiveForecasts {
    final allForecasts = ref.read(weatherProvider).value ?? <HourlyForecast>[];
    return allForecasts
        .where((f) => !f.time.isBefore(_start) && f.time.isBefore(_end))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  RideSlot get _effectiveSlot {
    final hours = _effectiveHours;
    final avgScore = hours.isEmpty
        ? widget.slot.overallScore
        : hours.fold(0.0, (sum, s) => sum + s.overall) / hours.length;
    return RideSlot(
      start: _start,
      end: _end,
      overallScore: avgScore,
      tier: rideTierFromScore(avgScore),
      hours: hours,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers: tier-afhankelijke waarden
  // ---------------------------------------------------------------------------

  Color _bannerBg(RideTier tier) {
    final t = context.rw.tiers;
    return switch (tier) {
      Perfect() => t.perfectBg,
      Great() => t.perfectBg,
      Acceptable() => t.acceptableBg,
      Poor() => t.poorBg,
    };
  }

  Color _bannerFg(RideTier tier) {
    final t = context.rw.tiers;
    return switch (tier) {
      Perfect() => t.perfectFg,
      Great() => t.perfectFg,
      Acceptable() => t.acceptableFg,
      Poor() => t.poorFg,
    };
  }

  String _tierEmoji(RideTier tier) => switch (tier) {
        Perfect() => '\u{1F7E2}',
        Great() => '\u{1F7E2}',
        Acceptable() => '\u{1F7E1}',
        Poor() => '\u26AA',
      };

  String _tierDescription(BuildContext context, RideTier tier) {
    final s = S.of(context);
    return switch (tier) {
      Perfect() => s.detailTierPerfectDesc,
      Great() => s.detailTierGreatDesc,
      Acceptable() => s.detailTierAcceptableDesc,
      Poor() => s.detailTierPoorDesc,
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers: datum/tijd formattering
  // ---------------------------------------------------------------------------

  String _pad2(int n) => n.toString().padLeft(2, '0');

  String _fmtTime(DateTime dt) => '${_pad2(dt.hour)}:${_pad2(dt.minute)}';

  String _fmtDuration(DateTime start, DateTime end) {
    final diff = end.difference(start);
    final hours = diff.inMinutes ~/ 60;
    return '${hours}u';
  }

  // ---------------------------------------------------------------------------
  // Helpers: info-kaart "Weer" berekeningen
  // ---------------------------------------------------------------------------

  String _avgTempString(BuildContext context) {
    final temps = widget.forecasts
        .where((f) => f.temperatureC != null)
        .map((f) => f.temperatureC!)
        .toList();
    if (temps.isEmpty) return '\u2014';
    final avg = temps.reduce((a, b) => a + b) / temps.length;
    final avgRounded = avg.round();

    final apparent = widget.forecasts
        .where((f) => f.apparentTemperatureC != null)
        .map((f) => f.apparentTemperatureC!)
        .toList();
    if (apparent.isEmpty) return '$avgRounded\u00B0C';
    final avgApparent =
        (apparent.reduce((a, b) => a + b) / apparent.length).round();
    return '$avgRounded\u00B0C, ${S.of(context).feelsLike(avgApparent.toString())}';
  }

  String _totalPrecipString(BuildContext context) {
    final vals = widget.forecasts
        .where((f) => f.precipitationMm != null)
        .map((f) => f.precipitationMm!)
        .toList();
    if (vals.isEmpty) return '\u2014';
    final total = vals.reduce((a, b) => a + b);
    final probs = widget.forecasts
        .map((f) => f.precipitationProbability)
        .whereType<double>()
        .toList();
    final avgProb = probs.isEmpty
        ? null
        : probs.reduce((a, b) => a + b) / probs.length;
    final s = S.of(context);
    if (total == 0.0 && (avgProb == null || avgProb == 0)) return s.dry;
    if (avgProb != null && avgProb > 0) {
      return s.rainChance(total.toStringAsFixed(1), avgProb.round().toString());
    }
    return '${total.toStringAsFixed(1)}mm';
  }

  String _avgWindString(BuildContext context) {
    final vals = widget.forecasts
        .where((f) => f.windspeedKmh != null)
        .map((f) => f.windspeedKmh!)
        .toList();
    if (vals.isEmpty) return '\u2014';
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final s = S.of(context);
    if (avg < 5) return s.windCalm;
    final dirs = widget.forecasts
        .map((f) => f.winddirectionDeg)
        .whereType<double>()
        .toList();
    if (dirs.isNotEmpty) {
      double sinSum = 0, cosSum = 0;
      for (final d in dirs) {
        sinSum += _sin(d * _pi / 180);
        cosSum += _cos(d * _pi / 180);
      }
      final avgDir = (_atan2(sinSum, cosSum) * 180 / _pi + 360) % 360;
      return s.windFrom(avg.round().toString(), _compassDirection(context, avgDir));
    }
    return '${avg.round()}km/u';
  }

  // ---------------------------------------------------------------------------
  // Agenda-actie
  // ---------------------------------------------------------------------------

  Future<void> _addToCalendar() async {
    setState(() => _isLoading = true);
    try {
      await widget.calendarServiceFactory().addRideSlotToCalendar(
        widget.slot,
        widget.forecasts,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).addedToGoogleCalendar),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).couldNotAdd(e.toString())),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Widgets
  // ---------------------------------------------------------------------------

  Widget _buildAppBar(BuildContext context) {
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final slot = _effectiveSlot;
    final duration = _fmtDuration(slot.start, slot.end);
    final tierLabel = switch (slot.tier) {
      Perfect() => s.tierPerfect,
      Great() => s.tierGreat,
      Acceptable() => s.tierAcceptable,
      Poor() => s.tierPoor,
    };

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_fmtTime(slot.start)} \u2013 ${_fmtTime(slot.end)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            '$duration \u00B7 $tierLabel ${s.detailConditions}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      backgroundColor: cs.surface,
      foregroundColor: rw.textPrimary,
      elevation: 0,
    );
  }

  Widget _buildScoreBanner(BuildContext context) {
    final slot = _effectiveSlot;
    final bg = _bannerBg(slot.tier);
    final fg = _bannerFg(slot.tier);
    final emoji = _tierEmoji(slot.tier);
    final description = _tierDescription(context, slot.tier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: bg,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScoreBadge(tier: slot.tier, heroTag: widget.heroTag),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: fg),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (_) => InsightsSheet(slot: widget.slot),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> rows,
  }) {
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: rw.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: rw.textHint,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildWeatherRow(String label, String value) {
    final rw = context.rw;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: rw.borderDim)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: rw.textTertiary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: rw.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClothingTip() {
    final rw = context.rw;
    final temps = widget.forecasts
        .where((f) => f.apparentTemperatureC != null)
        .map((f) => f.apparentTemperatureC!)
        .toList();
    if (temps.isEmpty) return const SizedBox.shrink();

    final avgFeelsLike = temps.reduce((a, b) => a + b) / temps.length;
    final totalPrecip = widget.forecasts
        .where((f) => f.precipitationMm != null)
        .map((f) => f.precipitationMm!)
        .fold(0.0, (a, b) => a + b);
    final avgWind = widget.forecasts
        .where((f) => f.windspeedKmh != null)
        .map((f) => f.windspeedKmh!)
        .toList();
    final windAvg =
        avgWind.isEmpty ? 0.0 : avgWind.reduce((a, b) => a + b) / avgWind.length;

    final s = S.of(context);
    final items = <String>[];
    String icon;

    if (avgFeelsLike < 5) {
      icon = '\u{1F9E4}'; // gloves
      items.addAll([s.clothingWinterJacket, s.clothingThermalPants, s.clothingGloves, s.clothingOvershoes]);
    } else if (avgFeelsLike < 10) {
      icon = '\u{1F9E5}'; // coat
      items.addAll([s.clothingLongSleeveJersey, s.clothingArmWarmers, s.clothingLegWarmers]);
    } else if (avgFeelsLike < 15) {
      icon = '\u{1F455}'; // shirt
      items.addAll([s.clothingLongSleeveJersey, s.clothingKneeWarmers]);
    } else if (avgFeelsLike < 20) {
      icon = '\u{1F455}';
      items.add(s.clothingShortSleeveJersey);
      if (avgFeelsLike < 17) items.add(s.clothingArmWarmersJustInCase);
    } else if (avgFeelsLike < 28) {
      icon = '\u{2600}\u{FE0F}'; // sun
      items.addAll([s.clothingLightShirt, s.clothingSunscreen]);
    } else {
      icon = '\u{1F975}'; // hot face
      items.addAll([s.clothingLightShirt, s.clothingSunscreen, s.clothingExtraWater]);
    }

    if (totalPrecip > 0.5) {
      items.add(s.clothingRainJacket);
    }
    if (windAvg > 25) {
      items.add(s.clothingWindVest);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: rw.greenBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rw.greenBorder, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.clothingTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: rw.scorePerfect,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  items.join(' \u00B7 '),
                  style: TextStyle(
                    fontSize: 13,
                    color: rw.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyRowWidget(HourlyRow row) {
    final rw = context.rw;
    final s = S.of(context);
    final time = _fmtTime(row.time);
    final temp = row.temperatureC != null
        ? '${row.temperatureC!.round()}\u00B0C'
        : '\u2014';
    final apparent = row.apparentTemperatureC != null
        ? s.hourlyFeelsLike(row.apparentTemperatureC!.round().toString())
        : '';
    final precip = row.precipitationMm != null
        ? (row.precipitationMm! == 0.0 && (row.precipitationProbability == null || row.precipitationProbability == 0)
            ? '\u{1F327} ${s.hourlyDry}'
            : row.precipitationProbability != null && row.precipitationProbability! > 0
                ? '\u{1F327} ${row.precipitationMm!.toStringAsFixed(1)}mm ${row.precipitationProbability!.round()}%'
                : '\u{1F327} ${row.precipitationMm!.toStringAsFixed(1)}mm')
        : '\u{1F327} \u2014';
    final wind = row.windspeedKmh != null
        ? row.windspeedKmh! < 5
            ? '\u{1F4A8} ${s.hourlyWindstil}'
            : row.windspeedKmh! < 15 || row.winddirectionDeg == null
                ? '\u{1F4A8} ${row.windspeedKmh!.round()}km/u'
                : '\u{1F4A8} ${row.windspeedKmh!.round()}km/u ${_compassDirection(context, row.winddirectionDeg!)}'
        : '\u{1F4A8} \u2014';

    // Subtiele achtergrondkleur op basis van uur-score
    final Color rowBg;
    if (row.overallScore >= 85) {
      rowBg = rw.rowGreenTint;
    } else if (row.overallScore >= 70) {
      rowBg = rw.rowOrangeTint;
    } else {
      rowBg = rw.rowRedTint;
    }

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(top: BorderSide(color: rw.borderDim)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              time,
              style: TextStyle(fontSize: 13, color: rw.textHint),
            ),
          ),
          SizedBox(
            width: 46,
            child: Text(
              temp,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: rw.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              apparent,
              style: TextStyle(fontSize: 13, color: rw.textTertiary),
            ),
          ),
          Text(
            precip,
            style: TextStyle(fontSize: 12, color: rw.textTertiary),
          ),
          const SizedBox(width: 8),
          Text(
            wind,
            style: TextStyle(fontSize: 12, color: rw.textTertiary),
          ),
        ],
      ),
    );
  }

  void _shareSlot() {
    final s = S.of(context);
    final tierLabel = switch (widget.slot.tier) {
      Perfect() => s.tierPerfect,
      Great() => s.tierGreat,
      Acceptable() => s.tierAcceptable,
      Poor() => s.tierPoor,
    };
    final summary = CalendarService.buildWeatherSummary(widget.forecasts);
    final day = _dayName(context, widget.slot.start);
    final timeRange = '${_fmtTime(widget.slot.start)}\u2013${_fmtTime(widget.slot.end)}';
    Share.share(s.shareText(day, timeRange, tierLabel, summary));
  }

  String _dayName(BuildContext context, DateTime dt) {
    final s = S.of(context);
    const days = [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday, DateTime.saturday, DateTime.sunday];
    final names = [s.dayMonFull, s.dayTueFull, s.dayWedFull, s.dayThuFull, s.dayFriFull, s.daySatFull, s.daySunFull];
    return names[days.indexOf(dt.weekday)];
  }

  String _compassDirection(BuildContext context, double degrees) {
    final s = S.of(context);
    final dirs = [s.compassN, s.compassNE, s.compassE, s.compassSE, s.compassS, s.compassSW, s.compassW, s.compassNW];
    final index = ((degrees + 22.5) % 360 / 45).floor();
    return dirs[index];
  }

  double _windPenaltyPercent() {
    return windVariabilityPenalty(widget.forecasts) * 100;
  }

  Widget _buildWindPenaltyNote() {
    final rw = context.rw;
    final pct = _windPenaltyPercent().round();
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: rw.borderDim)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: rw.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context).windPenalty(pct.toString()),
              style: TextStyle(fontSize: 12, color: rw.textHint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAdjuster() {
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final allScores = ref.watch(allHourlyScoresProvider);

    // Scores for hours around the current range (context hours)
    final contextStart = _start.subtract(const Duration(hours: 2));
    final contextEnd = _end.add(const Duration(hours: 2));
    final contextScores = allScores
        .where((sc) => !sc.time.isBefore(contextStart) && sc.time.isBefore(contextEnd))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    final canShrinkStart = _end.difference(_start).inHours > 1;
    final canShrinkEnd = _end.difference(_start).inHours > 1;
    // Don't expand before 6:00 or after 22:00
    final canExpandStart = _start.hour > 6;
    final canExpandEnd = _end.hour < 22;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: rw.shadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.adjustTime,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: rw.textHint,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          // Start time adjuster
          Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(s.startLabel, style: TextStyle(fontSize: 12, color: rw.textTertiary)),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: rw.scorePerfect,
                onPressed: canExpandStart
                    ? () => setState(() => _start = _start.subtract(const Duration(hours: 1)))
                    : null,
              ),
              Text(
                _fmtTime(_start),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: rw.scorePerfect,
                onPressed: canShrinkStart
                    ? () => setState(() => _start = _start.add(const Duration(hours: 1)))
                    : null,
              ),
            ],
          ),
          // End time adjuster
          Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(s.endLabel, style: TextStyle(fontSize: 12, color: rw.textTertiary)),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: rw.scorePerfect,
                onPressed: canShrinkEnd
                    ? () => setState(() => _end = _end.subtract(const Duration(hours: 1)))
                    : null,
              ),
              Text(
                _fmtTime(_end),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: rw.scorePerfect,
                onPressed: canExpandEnd
                    ? () => setState(() => _end = _end.add(const Duration(hours: 1)))
                    : null,
              ),
              const Spacer(),
              // Duration label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rw.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_end.difference(_start).inHours}u',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Per-hour score strip
          SizedBox(
            height: 28,
            child: Row(
              children: contextScores.map((sc) {
                final isInRange = !sc.time.isBefore(_start) && sc.time.isBefore(_end);
                final color = sc.overall >= 85
                    ? rw.scorePerfect
                    : sc.overall >= 70
                        ? rw.scoreGreat
                        : sc.overall >= 50
                            ? rw.scoreAcceptable
                            : rw.scorePoor;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isInRange ? color : color.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                      border: isInRange
                          ? Border.all(color: rw.tiers.perfectFg, width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${sc.time.hour}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isInRange ? Theme.of(context).colorScheme.onPrimary : rw.textHint,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final rw = context.rw;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () {
              final slot = _effectiveSlot;
              ref.read(plannedRidesProvider.notifier).add(
                    PlannedRide(
                      start: slot.start,
                      end: slot.end,
                      plannedScore: slot.overallScore,
                    ),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).ridePlanned)),
              );
            },
            icon: const Icon(Icons.directions_bike),
            label: Text(S.of(context).planRide),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _addToCalendar,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.calendar_month, size: 18),
            label: Text(S.of(context).addToGoogleCalendar),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () async {
              final notifService = NotificationService();
              final canExact = await notifService.canScheduleExact();
              final slotTitle =
                  '${_fmtTime(widget.slot.start)}\u2013${_fmtTime(widget.slot.end)}';
              await notifService.scheduleEveningBefore(
                slotDay: widget.slot.start,
                slotTitle: slotTitle,
                exact: canExact,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).reminderPlanned),
                  ),
                );
              }
            },
            icon: const Icon(Icons.notifications_outlined, size: 18),
            label: Text(S.of(context).remindEveningBefore),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _shareSlot,
            icon: const Icon(Icons.share, size: 18),
            label: Text(S.of(context).shareRideWindow),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rw = context.rw;
    final slot = _effectiveSlot;
    final forecasts = _effectiveForecasts;
    final hourlyRows = buildHourlyRows(slot, forecasts);

    return Scaffold(
      backgroundColor: rw.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _buildAppBar(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildScoreBanner(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTimeAdjuster(),
                    _buildInfoCard(
                      title: S.of(context).weatherSection,
                      rows: [
                        _buildWeatherRow(S.of(context).weatherTemperature, _avgTempString(context)),
                        _buildWeatherRow(S.of(context).weatherRain, _totalPrecipString(context)),
                        _buildWeatherRow(S.of(context).weatherWind, _avgWindString(context)),
                        if (_windPenaltyPercent() > 2)
                          _buildWindPenaltyNote(),
                      ],
                    ),
                    _buildClothingTip(),
                    _buildInfoCard(
                      title: S.of(context).weatherHourly,
                      rows: hourlyRows
                          .map(_buildHourlyRowWidget)
                          .toList(),
                    ),
                    _buildActions(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
