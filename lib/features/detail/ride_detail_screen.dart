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
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ridewindow/platform/notification_service.dart';
import 'package:ridewindow/services/calendar_service.dart';

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

  // ---------------------------------------------------------------------------
  // Helpers: tier-afhankelijke waarden
  // ---------------------------------------------------------------------------

  Color _bannerBg(RideTier tier) => switch (tier) {
        Perfect() => const Color(0xFFE8F5E9),
        Great() => const Color(0xFFE8F5E9),
        Acceptable() => const Color(0xFFFFF3E0),
        Poor() => const Color(0xFFF5F5F5),
      };

  Color _bannerFg(RideTier tier) => switch (tier) {
        Perfect() => const Color(0xFF1B5E20),
        Great() => const Color(0xFF1B5E20),
        Acceptable() => const Color(0xFFE65100),
        Poor() => const Color(0xFF757575),
      };

  String _tierEmoji(RideTier tier) => switch (tier) {
        Perfect() => '\u{1F7E2}',
        Great() => '\u{1F7E2}',
        Acceptable() => '\u{1F7E1}',
        Poor() => '\u26AA',
      };

  String _tierDescription(RideTier tier) => switch (tier) {
        Perfect() => 'Perfect \u2014 het beste venster deze week',
        Great() => 'Goed \u2014 prettige rijomstandigheden',
        Acceptable() => 'Acceptabel \u2014 te doen, pak een extra laag',
        Poor() => 'Slecht \u2014 niet ideaal, maar mogelijk',
      };

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

  String _avgTempString() {
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
    return '$avgRounded\u00B0C, voelt als $avgApparent\u00B0C';
  }

  String _totalPrecipString() {
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
    if (total == 0.0 && (avgProb == null || avgProb == 0)) return 'Droog';
    if (avgProb != null && avgProb > 0) {
      return '${total.toStringAsFixed(1)}mm (${avgProb.round()}% kans)';
    }
    return '${total.toStringAsFixed(1)}mm';
  }

  String _avgWindString() {
    final vals = widget.forecasts
        .where((f) => f.windspeedKmh != null)
        .map((f) => f.windspeedKmh!)
        .toList();
    if (vals.isEmpty) return '\u2014';
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    if (avg < 5) return 'Windstil';
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
      return '${avg.round()}km/u uit ${_compassDirection(avgDir)}';
    }
    return '${avg.round()}km/u';
  }

  // ---------------------------------------------------------------------------
  // Agenda-actie
  // ---------------------------------------------------------------------------

  Future<void> _addToCalendar() async {
    setState(() => _isLoading = true);
    try {
      // CalendarService wordt uitsluitend on-demand aangemaakt via de factory
      // in onPressed (CAL-02). De factory is injecteerbaar voor tests (PERS-04).
      await widget.calendarServiceFactory().addRideSlotToCalendar(
        widget.slot,
        widget.forecasts,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rijvenster toegevoegd aan Google Agenda!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kon niet toevoegen: ${e.toString()}'),
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
    final duration = _fmtDuration(widget.slot.start, widget.slot.end);
    final tierLabel = switch (widget.slot.tier) {
      Perfect() => 'Perfect',
      Great() => 'Goed',
      Acceptable() => 'Acceptabel',
      Poor() => 'Slecht',
    };

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_fmtTime(widget.slot.start)} \u2013 ${_fmtTime(widget.slot.end)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            '$duration \u00B7 $tierLabel omstandigheden',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
    );
  }

  Widget _buildScoreBanner(BuildContext context) {
    final bg = _bannerBg(widget.slot.tier);
    final fg = _bannerFg(widget.slot.tier);
    final emoji = _tierEmoji(widget.slot.tier);
    final description = _tierDescription(widget.slot.tier);

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
                ScoreBadge(tier: widget.slot.tier, heroTag: widget.heroTag),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
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
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF999999),
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
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClothingTip() {
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

    final items = <String>[];
    String icon;

    if (avgFeelsLike < 5) {
      icon = '\u{1F9E4}'; // gloves
      items.addAll(['Winter jacket', 'Thermal tights', 'Gloves', 'Shoe covers']);
    } else if (avgFeelsLike < 10) {
      icon = '\u{1F9E5}'; // coat
      items.addAll(['Long sleeve jersey', 'Arm warmers', 'Leg warmers']);
    } else if (avgFeelsLike < 15) {
      icon = '\u{1F455}'; // shirt
      items.addAll(['Long sleeve jersey', 'Knee warmers']);
    } else if (avgFeelsLike < 20) {
      icon = '\u{1F455}';
      items.add('Short sleeve jersey');
      if (avgFeelsLike < 17) items.add('Arm warmers just in case');
    } else if (avgFeelsLike < 28) {
      icon = '\u{2600}\u{FE0F}'; // sun
      items.addAll(['Light jersey', 'Sunscreen']);
    } else {
      icon = '\u{1F975}'; // hot face
      items.addAll(['Light jersey', 'Sunscreen', 'Extra water']);
    }

    if (totalPrecip > 0.5) {
      items.add('Rain jacket');
    }
    if (windAvg > 25) {
      items.add('Wind vest');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCCE5CC), width: 0.5),
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
                const Text(
                  'What to wear',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  items.join(' \u00B7 '),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF444444),
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
    final time = _fmtTime(row.time);
    final temp = row.temperatureC != null
        ? '${row.temperatureC!.round()}\u00B0C'
        : '\u2014';
    final apparent = row.apparentTemperatureC != null
        ? 'v.a. ${row.apparentTemperatureC!.round()}\u00B0C'
        : '';
    final precip = row.precipitationMm != null
        ? (row.precipitationMm! == 0.0 && (row.precipitationProbability == null || row.precipitationProbability == 0)
            ? '\u{1F327} droog'
            : row.precipitationProbability != null && row.precipitationProbability! > 0
                ? '\u{1F327} ${row.precipitationMm!.toStringAsFixed(1)}mm ${row.precipitationProbability!.round()}%'
                : '\u{1F327} ${row.precipitationMm!.toStringAsFixed(1)}mm')
        : '\u{1F327} \u2014';
    final wind = row.windspeedKmh != null
        ? row.windspeedKmh! < 5
            ? '\u{1F4A8} windstil'
            : row.windspeedKmh! < 15 || row.winddirectionDeg == null
                ? '\u{1F4A8} ${row.windspeedKmh!.round()}km/u'
                : '\u{1F4A8} ${row.windspeedKmh!.round()}km/u ${_compassDirection(row.winddirectionDeg!)}'
        : '\u{1F4A8} \u2014';

    // Subtiele achtergrondkleur op basis van uur-score
    final Color rowBg;
    if (row.overallScore >= 85) {
      rowBg = const Color(0x0A2E7D32); // zeer licht groen
    } else if (row.overallScore >= 70) {
      rowBg = const Color(0x0AFF9800); // zeer licht oranje
    } else {
      rowBg = const Color(0x08C62828); // zeer licht rood
    }

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              time,
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
          ),
          SizedBox(
            width: 46,
            child: Text(
              temp,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              apparent,
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ),
          ),
          Text(
            precip,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
          const SizedBox(width: 8),
          Text(
            wind,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  void _shareSlot() {
    final tierLabel = switch (widget.slot.tier) {
      Perfect() => 'Perfect',
      Great() => 'Goed',
      Acceptable() => 'Acceptabel',
      Poor() => 'Slecht',
    };
    final summary = CalendarService.buildWeatherSummary(widget.forecasts);
    final day = _dayName(widget.slot.start);
    final text = 'Fietsrit $day '
        '${_fmtTime(widget.slot.start)}\u2013${_fmtTime(widget.slot.end)} '
        '($tierLabel)\n$summary\n\nVia RideWindow';
    Share.share(text);
  }

  String _dayName(DateTime dt) {
    const names = ['Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrijdag', 'Zaterdag', 'Zondag'];
    return names[dt.weekday - 1];
  }

  String _compassDirection(double degrees) {
    const dirs = ['N', 'NO', 'O', 'ZO', 'Z', 'ZW', 'W', 'NW'];
    final index = ((degrees + 22.5) % 360 / 45).floor();
    return dirs[index];
  }

  double _windPenaltyPercent() {
    return windVariabilityPenalty(widget.forecasts) * 100;
  }

  Widget _buildWindPenaltyNote() {
    final pct = _windPenaltyPercent().round();
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFFF9800)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Wisselende windrichting (-$pct% op score)',
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              ref.read(plannedRidesProvider.notifier).add(
                    PlannedRide(
                      start: widget.slot.start,
                      end: widget.slot.end,
                      plannedScore: widget.slot.overallScore,
                    ),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rit ingepland!')),
              );
            },
            icon: const Icon(Icons.directions_bike),
            label: const Text('Rit inplannen'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading ? null : _addToCalendar,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.calendar_month, size: 18),
            label: const Text('Toevoegen aan Google Agenda'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5F5F5),
              foregroundColor: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
                  const SnackBar(
                    content: Text('Herinnering gepland voor de avond ervoor!'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.notifications_outlined, size: 18),
            label: const Text('Herinner me de avond ervoor'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _shareSlot,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Deel dit rijvenster'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hourlyRows = buildHourlyRows(widget.slot, widget.forecasts);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
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
                    _buildInfoCard(
                      title: 'WEER',
                      rows: [
                        _buildWeatherRow('Temperatuur', _avgTempString()),
                        _buildWeatherRow('Neerslag', _totalPrecipString()),
                        _buildWeatherRow('Wind', _avgWindString()),
                        if (_windPenaltyPercent() > 2)
                          _buildWindPenaltyNote(),
                      ],
                    ),
                    _buildClothingTip(),
                    _buildInfoCard(
                      title: 'UURLIJKS',
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
