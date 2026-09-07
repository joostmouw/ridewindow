import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/weather_verdict.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Eén weermeting: waarde, oordeel, en hoe ver het van je ideaal af zit.
///
/// **Waarom deze widget in v4.0 is herzien.** Hij tekende een balk over het
/// volledige meetbereik met een stip erop. Voor regen betekende dat een schaal
/// van 0 tot 10 mm terwijl het ideaal `≤ 0,5 mm` is: de groene zone was 5% van
/// de breedte en bij droog weer lag de stip er bovenop. Drie van die balken
/// onder elkaar lazen als versiering — je zag drie streepjes en las niets.
///
/// Twee dingen zijn veranderd. De schaal is ingezoomd op het bereik dat je in
/// de praktijk tegenkomt (zie [WeatherMetric]), zodat de ideaalzone een band
/// wordt waar je iets in kunt zien liggen. En er staat nu een woord naast —
/// "Dry", "Breezy", "Ideal" — dat het echte werk doet, want dat lees je zonder
/// te meten.
///
/// **Inzoomen mag niet liegen.** Een waarde buiten het bereik wordt niet
/// stilzwijgend tegen de rand geplakt; dan zouden 4 mm en 12 mm er hetzelfde
/// uitzien, precies de fout die hier werd opgelost. De marker klapt tegen de
/// rand mét een pijl, en de echte waarde staat altijd voluit in tekst. De balk
/// verliest zijn precisie buiten het bereik, het getal nooit.
class WeatherIndicatorBar extends StatelessWidget {
  const WeatherIndicatorBar({
    super.key,
    required this.metric,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.idealMax,
    this.idealMin,
    this.infoText,
  });

  final WeatherMetric metric;
  final IconData icon;
  final String label;
  final double value;

  /// Achter het getal geplakt: `°`, ` mm`, ` km/h`.
  final String unit;

  /// Het bereik dat de gebruiker zelf ideaal noemt. [idealMin] is null voor
  /// regen en wind — die kennen alleen een bovengrens.
  final double idealMax;
  final double? idealMin;

  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final rw = context.rw;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final span = metric.zoomMax - metric.zoomMin;
    final rawFraction = span > 0 ? (value - metric.zoomMin) / span : 0.5;
    final beyondScale = rawFraction > 1.0;
    final fraction = rawFraction.clamp(0.0, 1.0);

    final zoneStart = idealMin != null && span > 0
        ? ((idealMin! - metric.zoomMin) / span).clamp(0.0, 1.0)
        : 0.0;
    final zoneEnd =
        span > 0 ? ((idealMax - metric.zoomMin) / span).clamp(0.0, 1.0) : 1.0;

    final verdict = weatherVerdictFor(
      metric,
      value,
      idealMin: idealMin,
      idealMax: idealMax,
    );
    final verdictColor = switch (verdict.level) {
      WeatherVerdictLevel.ok => rw.scorePerfect,
      WeatherVerdictLevel.warn => rw.warning,
      WeatherVerdictLevel.bad => rw.error,
    };

    final rangeLabel = idealMin != null
        ? '${_trim(idealMin!)}–${_trim(idealMax)}${unit.trim()}'
        : '≤${_trim(idealMax)}${unit.trim()}';

    final scaleStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 9,
      color: rw.textHint,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Semantics(
      // Zonder dit leest een screenreader "18", "Ideal" en de twee schaalranden
      // als losse fragmenten, terwijl het één uitspraak is.
      label: '$label ${_formatValue()}${unit.trim()}, '
          '${_verdictLabel(context, verdict)}, $rangeLabel',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(icon, size: 13, color: rw.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: rw.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${_formatValue()}$unit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _verdictLabel(context, verdict).toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: verdictColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                if (infoText != null)
                  Semantics(
                    button: true,
                    label: S.of(context).weatherMetricInfoTooltip(label),
                    child: GestureDetector(
                      onTap: () => _showInfo(context),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 36,
                        height: 28,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.info_outline,
                            size: 14,
                            color: rw.textHint,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              // `width` is niet optioneel. Een `SizedBox` zonder breedte krijgt
              // in een `Column` een losse breedte-constraint en valt zonder
              // kind terug op 0 — de baan werd dan nul pixels breed en de
              // painter rekende zich stuk. Dit is het verschil met de vorige
              // versie, waar de breedte uit een `Expanded` in een `Row` kwam.
              width: double.infinity,
              height: 14,
              child: CustomPaint(
                painter: _BarPainter(
                  fraction: fraction.toDouble(),
                  beyondScale: beyondScale,
                  zoneStart: zoneStart.toDouble(),
                  zoneEnd: zoneEnd.toDouble(),
                  trackColor: cs.surfaceContainerHigh,
                  zoneColor: rw.scoreGreenTint,
                  markColor: verdictColor,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Text(
                  '${_trim(metric.zoomMin)}${unit.trim()}',
                  style: scaleStyle,
                ),
                Expanded(
                  child: Text(
                    S.of(context).weatherYourRange(rangeLabel),
                    textAlign: TextAlign.center,
                    style: scaleStyle?.copyWith(
                      color: rw.scorePerfect,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${_trim(metric.zoomMax)}${unit.trim()}${beyondScale ? '+' : ''}',
                  style: scaleStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// De gemeten waarde zoals hij op de kaart staat.
  ///
  /// Graden en km/u zijn hele getallen — "13.9°" op een kaart die verder
  /// alleen hele graden toont leest als valse precisie, en de balk staat er
  /// juist om te laten zien dat het níét op de tiende aankomt. Regen is de
  /// uitzondering: daar zit het verschil tussen droog en nat in de tienden,
  /// want de standaardgrens is 0,5 mm.
  String _formatValue() => switch (metric) {
        WeatherMetric.rain => _trim(value),
        WeatherMetric.temperature || WeatherMetric.wind =>
          value.round().toString(),
      };

  /// 0,5 blijft "0.5" maar 18,0 wordt "18" — anders staat er "18.0" waar een
  /// heel getal bedoeld is.
  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  String _verdictLabel(BuildContext context, WeatherVerdict verdict) {
    final s = S.of(context);
    return switch (verdict) {
      WeatherVerdict.dry => s.verdictDry,
      WeatherVerdict.light => s.verdictLight,
      WeatherVerdict.showers => s.verdictShowers,
      WeatherVerdict.wet => s.verdictWet,
      WeatherVerdict.calm => s.verdictCalm,
      WeatherVerdict.breezy => s.verdictBreezy,
      WeatherVerdict.gusty => s.verdictGusty,
      WeatherVerdict.chilly => s.verdictChilly,
      WeatherVerdict.ideal => s.verdictIdeal,
      WeatherVerdict.warm => s.verdictWarm,
    };
  }

  void _showInfo(BuildContext context) {
    final rw = context.rw;
    // Zelfde behandeling als het debugmenu (2026-08-06): een sheet zonder
    // `isScrollControlled` en zonder scrollende body knipt zijn onderkant af
    // zodra de inhoud niet past. Hier is de tekst vertaald en dus van
    // variabele lengte, wat dat risico reëel maakt.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                infoText!,
                style: TextStyle(
                  fontSize: 14,
                  color: rw.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.fraction,
    required this.beyondScale,
    required this.zoneStart,
    required this.zoneEnd,
    required this.trackColor,
    required this.zoneColor,
    required this.markColor,
  });

  final double fraction;
  final bool beyondScale;
  final double zoneStart;
  final double zoneEnd;
  final Color trackColor;
  final Color zoneColor;
  final Color markColor;

  static const _trackHeight = 6.0;
  static const _markWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // Zonder deze grens kost een baan van nul breedte een RangeError in de
    // clamps hieronder — en een exceptie tijdens paint neemt de hele kaart mee,
    // niet alleen de balk. Dat is precies wat er de eerste keer gebeurde.
    if (w <= 0 || size.height <= 0) return;
    final top = (size.height - _trackHeight) / 2;
    final radius = const Radius.circular(_trackHeight / 2);
    final track =
        RRect.fromLTRBR(0, top, w, top + _trackHeight, radius);

    canvas.drawRRect(track, Paint()..color = trackColor);

    canvas.save();
    canvas.clipRRect(track);
    // Een ondergrens-loze meting (regen, wind) heeft zijn zone van 0 tot de
    // grens; met een ondergrens is het een band. Minimaal 4px breed, anders is
    // een strenge instelling weer onzichtbaar -- exact het probleem dat deze
    // herziening oplost.
    final left = zoneStart * w;
    var right = zoneEnd * w;
    if (right < left + 4) right = left + 4;
    if (right > w) right = w;
    canvas.drawRect(
      Rect.fromLTRB(left, top, right, top + _trackHeight),
      Paint()..color = zoneColor,
    );
    canvas.restore();

    // De marker steekt boven en onder de baan uit, zodat hij ook op een zone
    // van dezelfde kleurfamilie leesbaar blijft.
    final markX = w > _markWidth
        ? (fraction * w).clamp(_markWidth / 2, w - _markWidth / 2)
        : w / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(markX, size.height / 2),
          width: _markWidth,
          height: size.height,
        ),
        const Radius.circular(1.5),
      ),
      Paint()..color = markColor,
    );

    if (beyondScale) _paintBeyondArrow(canvas, size, markX);
  }

  /// Een pijltje voorbij de marker: deze waarde valt buiten het getekende
  /// bereik. Zonder dit zouden 4 mm en 12 mm er identiek uitzien.
  void _paintBeyondArrow(Canvas canvas, Size size, double markX) {
    final cy = size.height / 2;
    final tipX = (markX + 6).clamp(0.0, size.width);
    final path = Path()
      ..moveTo(markX + 2, cy - 4)
      ..lineTo(tipX, cy)
      ..lineTo(markX + 2, cy + 4);
    canvas.drawPath(
      path,
      Paint()
        ..color = markColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.fraction != fraction ||
      old.beyondScale != beyondScale ||
      old.zoneStart != zoneStart ||
      old.zoneEnd != zoneEnd ||
      old.markColor != markColor;
}
