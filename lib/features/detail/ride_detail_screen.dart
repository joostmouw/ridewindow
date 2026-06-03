// lib/features/detail/ride_detail_screen.dart
// RideDetailScreen: full Wave 2 implementation + Phase 9 Google Calendar integratie.
// Toont score-banner, info-kaart "Weer", uurlijkse tabel en werkende agenda-knop.

import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_row.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/features/detail/insights_sheet.dart';
import 'package:ridewindow/features/shared/score_badge.dart';
import 'package:ridewindow/services/calendar_service.dart';

/// Factory typedef voor CalendarService — maakt dependency injection
/// in widget tests mogelijk zonder complexe DI-infrastructuur (PERS-04).
typedef CalendarServiceFactory = CalendarService Function();

CalendarService _defaultCalendarServiceFactory() => CalendarService();

class RideDetailScreen extends StatefulWidget {
  final RideSlot slot;
  final List<HourlyForecast> forecasts;

  /// Optionele factory voor testinjectie. Default maakt een echte CalendarService.
  final CalendarServiceFactory calendarServiceFactory;

  const RideDetailScreen({
    super.key,
    required this.slot,
    required this.forecasts,
    this.calendarServiceFactory = _defaultCalendarServiceFactory,
  });

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
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
    if (total == 0.0) return 'Droog';
    return '${total.toStringAsFixed(1)}mm';
  }

  String _avgWindString() {
    final vals = widget.forecasts
        .where((f) => f.windspeedKmh != null)
        .map((f) => f.windspeedKmh!)
        .toList();
    if (vals.isEmpty) return '\u2014';
    final avg = vals.reduce((a, b) => a + b) / vals.length;
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
                ScoreBadge(tier: widget.slot.tier),
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

  Widget _buildHourlyRowWidget(HourlyRow row) {
    final time = _fmtTime(row.time);
    final temp = row.temperatureC != null
        ? '${row.temperatureC!.round()}\u00B0C'
        : '\u2014';
    final apparent = row.apparentTemperatureC != null
        ? 'v.a. ${row.apparentTemperatureC!.round()}\u00B0C'
        : '';
    final precip = row.precipitationMm != null
        ? (row.precipitationMm! == 0.0
            ? '\u{1F327} droog'
            : '\u{1F327} ${row.precipitationMm!.toStringAsFixed(1)}mm')
        : '\u{1F327} \u2014';
    final wind = row.windspeedKmh != null
        ? '\u{1F4A8} ${row.windspeedKmh!.round()}km/u'
        : '\u{1F4A8} \u2014';

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
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

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading ? null : _addToCalendar,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Toevoegen aan agenda'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5F5F5),
              foregroundColor: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notificaties komen in een volgende update.'),
                ),
              );
            },
            child: const Text('Herinner me de avond ervoor'),
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
                      ],
                    ),
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
