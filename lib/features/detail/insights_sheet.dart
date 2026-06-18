// lib/features/detail/insights_sheet.dart
// InsightsSheet: volledige bottom-sheet widget die sub-scores visualiseert
// als drie LinearProgressIndicator balken met uitleg per factor.
//
// Wave 3 implementatie — vervangt de Wave 2 stub.

import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

class InsightsSheet extends StatelessWidget {
  final RideSlot slot;

  const InsightsSheet({super.key, required this.slot});

  // ---------------------------------------------------------------------------
  // Hulpfuncties: gemiddelde berekening
  // ---------------------------------------------------------------------------

  /// Berekent het gemiddelde van een sub-score over alle uren.
  /// Geeft 50.0 terug bij een lege lijst (T-05-03-01: nul-deling voorkomen).
  double _avg(List<HourlyScore> hours, double Function(HourlyScore) selector) {
    if (hours.isEmpty) return 50.0;
    final total = hours.fold<double>(0.0, (sum, h) => sum + selector(h));
    return total / hours.length;
  }

  // ---------------------------------------------------------------------------
  // Hulpfuncties: kleur op basis van score (D-05-05)
  // ---------------------------------------------------------------------------

  Color _scoreColor(double score) {
    if (score >= 80) return const Color(0xFF2E7D32); // groen
    if (score >= 60) return const Color(0xFFE65100); // oranje
    return const Color(0xFFC62828); // rood
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
    required String emoji,
    required String label,
    required double score,
    required String scoreLabel,
    required String note,
  }) {
    final color = _scoreColor(score);
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Text(
              '$scoreRounded · $scoreLabel',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
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
            backgroundColor: const Color(0xFFECEFF1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          note,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF666666),
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

    final overallColor = _scoreColor(slot.overallScore);

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
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Titel
          Text(
            s.insightsTitle(tierStr, score.toString()),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),

          // Meta
          Text(
            '$day $startTime – $endTime · ${durationHours}u',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),

          // Temperatuur
          _buildFactorRow(
            emoji: '🌡',
            label: s.weatherTemperature,
            score: avgTemp,
            scoreLabel: _tempLabel(context, avgTemp),
            note: _tempNote(context, avgTemp),
          ),
          const SizedBox(height: 18),

          // Neerslag
          _buildFactorRow(
            emoji: '🌧',
            label: s.weatherRain,
            score: avgRain,
            scoreLabel: _rainLabel(context, avgRain),
            note: _rainNote(context, avgRain),
          ),
          const SizedBox(height: 18),

          // Wind
          _buildFactorRow(
            emoji: '💨',
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
              color: const Color(0xFFF5F5F5),
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
                    color: Color(0xFF1A1A1A),
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
                foregroundColor: const Color(0xFF2E7D32),
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
