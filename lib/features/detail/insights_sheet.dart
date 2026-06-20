// lib/features/detail/insights_sheet.dart
// InsightsSheet: volledige bottom-sheet widget die sub-scores visualiseert
// als drie LinearProgressIndicator balken met uitleg per factor.

import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

class InsightsSheet extends StatelessWidget {
  final RideSlot slot;

  const InsightsSheet({super.key, required this.slot});

  // ---------------------------------------------------------------------------
  // Hulpfuncties: gemiddelde berekening
  // ---------------------------------------------------------------------------

  double _avg(List<HourlyScore> hours, double Function(HourlyScore) selector) {
    if (hours.isEmpty) return 50.0;
    final total = hours.fold<double>(0.0, (sum, h) => sum + selector(h));
    return total / hours.length;
  }

  // ---------------------------------------------------------------------------
  // Hulpfuncties: kleur op basis van score (D-05-05)
  // ---------------------------------------------------------------------------

  Color _scoreColor(BuildContext context, double score) {
    final rw = context.rw;
    if (score >= 80) return rw.scorePerfect;
    if (score >= 60) return rw.tiers.acceptableFg;
    return rw.errorDark;
  }

  // ---------------------------------------------------------------------------
  // Hulpfuncties: score-labels per factor (D-05-04)
  // ---------------------------------------------------------------------------

  String _tempLabel(BuildContext context, double score) {
    final s = S.of(context);
    if (score >= 80) return s.insightsTempIdeal;
    if (score >= 60) return s.insightsTempAcceptable;
    return s.insightsTempExtreme;
  }

  String _rainLabel(BuildContext context, double score) {
    final s = S.of(context);
    if (score >= 80) return s.insightsRainDry;
    if (score >= 60) return s.insightsRainLight;
    return s.insightsRainWet;
  }

  String _windLabel(BuildContext context, double score) {
    final s = S.of(context);
    if (score >= 80) return s.insightsWindCalm;
    if (score >= 60) return s.insightsWindModerate;
    return s.insightsWindStrong;
  }

  // ---------------------------------------------------------------------------
  // Hulpfuncties: uitlegteksten per factor (D-05-04)
  // ---------------------------------------------------------------------------

  String _tempNote(BuildContext context, double score) {
    final s = S.of(context);
    if (score >= 80) return s.insightsTempNoteIdeal;
    if (score >= 60) return s.insightsTempNoteAcceptable;
    return s.insightsTempNoteExtreme;
  }

  String _rainNote(BuildContext context, double score) {
    final s = S.of(context);
    if (score >= 80) return s.insightsRainNoteDry;
    if (score >= 60) return s.insightsRainNoteLight;
    return s.insightsRainNoteWet;
  }

  String _windNote(BuildContext context, double score) {
    final s = S.of(context);
    if (score >= 80) return s.insightsWindNoteCalm;
    if (score >= 60) return s.insightsWindNoteModerate;
    return s.insightsWindNoteStrong;
  }

  // ---------------------------------------------------------------------------
  // Hulpfuncties: tier-label, tijdopmaak en dagnaam
  // ---------------------------------------------------------------------------

  String _tierLabel(BuildContext context, RideTier tier) {
    final s = S.of(context);
    return switch (tier) {
      Perfect() => s.tierPerfect,
      Great() => s.tierGreat,
      Acceptable() => s.tierAcceptable,
      Poor() => s.tierPoor,
    };
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dayName(BuildContext context, DateTime dt) {
    final s = S.of(context);
    final names = <int, String>{
      DateTime.monday: s.dayMonLower,
      DateTime.tuesday: s.dayTueLower,
      DateTime.wednesday: s.dayWedLower,
      DateTime.thursday: s.dayThuLower,
      DateTime.friday: s.dayFriLower,
      DateTime.saturday: s.daySatLower,
      DateTime.sunday: s.daySunLower,
    };
    return names[dt.weekday] ?? s.dayUnknown;
  }

  // ---------------------------------------------------------------------------
  // Bouw: factor-rij widget
  // ---------------------------------------------------------------------------

  Widget _buildFactorRow({
    required BuildContext context,
    required String emoji,
    required String label,
    required double score,
    required String scoreLabel,
    required String note,
  }) {
    final rw = context.rw;
    final color = _scoreColor(context, score);
    final scoreRounded = score.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: rw.textPrimary,
                ),
              ),
            ),
            Text(
              '$scoreRounded \u00B7 $scoreLabel',
              style: TextStyle(
                fontSize: 13,
                color: rw.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 100.0).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: rw.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          note,
          style: TextStyle(
            fontSize: 12.5,
            color: rw.textTertiary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rw = context.rw;
    final hours = slot.hours;

    final avgTemp = _avg(hours, (h) => h.temperatureScore);
    final avgRain = _avg(hours, (h) => h.rainScore);
    final avgWind = _avg(hours, (h) => h.windScore);

    final s = S.of(context);
    final tierStr = _tierLabel(context, slot.tier);
    final score = slot.overallScore.round();
    final day = _dayName(context, slot.start);
    final startTime = _formatTime(slot.start);
    final endTime = _formatTime(slot.end);
    final durationHours = slot.end.difference(slot.start).inMinutes ~/ 60;

    final overallColor = _scoreColor(context, slot.overallScore);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: rw.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Titel
          Text(
            s.insightsTitle(tierStr, score.toString()),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: rw.textPrimary,
            ),
          ),
          const SizedBox(height: 4),

          // Meta
          Text(
            '$day $startTime \u2013 $endTime \u00B7 ${durationHours}u',
            style: TextStyle(
              fontSize: 13,
              color: rw.textTertiary,
            ),
          ),
          const SizedBox(height: 16),

          // Temperatuur
          _buildFactorRow(
            context: context,
            emoji: '\u{1F321}',
            label: s.weatherTemperature,
            score: avgTemp,
            scoreLabel: _tempLabel(context, avgTemp),
            note: _tempNote(context, avgTemp),
          ),
          const SizedBox(height: 18),

          // Neerslag
          _buildFactorRow(
            context: context,
            emoji: '\u{1F327}',
            label: s.weatherRain,
            score: avgRain,
            scoreLabel: _rainLabel(context, avgRain),
            note: _rainNote(context, avgRain),
          ),
          const SizedBox(height: 18),

          // Wind
          _buildFactorRow(
            context: context,
            emoji: '\u{1F4A8}',
            label: s.weatherWind,
            score: avgWind,
            scoreLabel: _windLabel(context, avgWind),
            note: _windNote(context, avgWind),
          ),
          const SizedBox(height: 16),

          // Totaal-rij
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: rw.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.totalScore,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: rw.textPrimary,
                  ),
                ),
                Text(
                  '$score/100',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: overallColor,
                  ),
                ),
              ],
            ),
          ),

          // "Begrijpen" knop
          Align(
            alignment: Alignment.center,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: rw.scorePerfect,
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                s.understood,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
