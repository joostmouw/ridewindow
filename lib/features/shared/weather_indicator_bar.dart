import 'package:flutter/material.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Compact horizontal bar showing an actual value against a reference range.
/// Used on ride cards and detail screens for temp, rain, and wind.
class WeatherIndicatorBar extends StatelessWidget {
  const WeatherIndicatorBar({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    this.idealMin,
    this.idealMax,
    this.infoText,
  });

  final IconData icon;
  final String label;
  final double value;
  final String unit;

  /// Absolute range for the bar (e.g. -10 to 45 for temp).
  final double min;
  final double max;

  /// User's ideal range (green zone on the bar).
  final double? idealMin;
  final double? idealMax;

  /// Info tooltip text shown on tap of info button.
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final rw = context.rw;
    final range = max - min;
    final fraction = range > 0 ? ((value - min) / range).clamp(0.0, 1.0) : 0.5;
    final idealMinFrac = idealMin != null && range > 0
        ? ((idealMin! - min) / range).clamp(0.0, 1.0)
        : null;
    final idealMaxFrac = idealMax != null && range > 0
        ? ((idealMax! - min) / range).clamp(0.0, 1.0)
        : null;

    return Row(
      children: [
        Icon(icon, size: 14, color: rw.textTertiary),
        const SizedBox(width: 6),
        SizedBox(
          width: 38,
          child: Text(
            '${value.round()}$unit',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 12,
            child: CustomPaint(
              painter: _BarPainter(
                fraction: fraction,
                idealMinFrac: idealMinFrac,
                idealMaxFrac: idealMaxFrac,
                trackColor: rw.border,
                zoneColor: rw.scoreGreenTint,
                perfectDot: rw.scorePerfect,
                warningDot: rw.warning,
                errorDot: rw.error,
              ),
            ),
          ),
        ),
        if (infoText != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showInfo(context),
            child: Icon(Icons.info_outline, size: 14, color: rw.textHint),
          ),
        ],
      ],
    );
  }

  void _showInfo(BuildContext context) {
    final rw = context.rw;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: rw.scorePerfect),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              infoText!,
              style: TextStyle(fontSize: 14, color: rw.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final double fraction;
  final double? idealMinFrac;
  final double? idealMaxFrac;
  final Color trackColor;
  final Color zoneColor;
  final Color perfectDot;
  final Color warningDot;
  final Color errorDot;

  _BarPainter({
    required this.fraction,
    this.idealMinFrac,
    this.idealMaxFrac,
    required this.trackColor,
    required this.zoneColor,
    required this.perfectDot,
    required this.warningDot,
    required this.errorDot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final radius = Radius.circular(h / 2);
    final rrect = RRect.fromLTRBR(0, 0, w, h, radius);

    // Background track
    canvas.drawRRect(rrect, Paint()..color = trackColor);

    // Ideal zone (green band)
    if (idealMinFrac != null && idealMaxFrac != null) {
      final left = idealMinFrac! * w;
      final right = idealMaxFrac! * w;
      canvas.drawRect(
        Rect.fromLTRB(left, 0, right, h),
        Paint()..color = zoneColor,
      );
    } else if (idealMaxFrac != null) {
      // Only max threshold (rain, wind): green zone is 0 to max
      canvas.drawRect(
        Rect.fromLTRB(0, 0, idealMaxFrac! * w, h),
        Paint()..color = zoneColor,
      );
    }

    // Value indicator dot
    final dotX = fraction * w;
    final dotColor = _dotColor();
    canvas.drawCircle(
      Offset(dotX.clamp(h / 2, w - h / 2), h / 2),
      h / 2,
      Paint()..color = dotColor,
    );
  }

  Color _dotColor() {
    // If within ideal range, green; otherwise orange/red
    if (idealMinFrac != null && idealMaxFrac != null) {
      if (fraction >= idealMinFrac! && fraction <= idealMaxFrac!) {
        return perfectDot;
      }
    } else if (idealMaxFrac != null) {
      if (fraction <= idealMaxFrac!) {
        return perfectDot;
      }
    }
    // How far outside ideal?
    final distance = idealMinFrac != null && fraction < idealMinFrac!
        ? idealMinFrac! - fraction
        : idealMaxFrac != null && fraction > idealMaxFrac!
            ? fraction - idealMaxFrac!
            : 0.3;
    if (distance > 0.3) return errorDot;
    return warningDot;
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.fraction != fraction ||
      old.idealMinFrac != idealMinFrac ||
      old.idealMaxFrac != idealMaxFrac;
}
