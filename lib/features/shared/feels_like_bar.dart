import 'package:flutter/material.dart';
import 'package:ridewindow/features/shared/clothing_tip.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';
import 'package:ridewindow/theme/app_icons.dart';

/// De gevoelstemperatuur op de fiets, met de vier kledingbanden als schaal.
///
/// **Waarom het label "Op de fiets" heet en niet "voelt als".** De weerlijst op
/// ditzelfde scherm toont al `apparentTemperatureC` van Open-Meteo als "voelt
/// als" — een gevoelstemperatuur voor iemand die stilstaat, die hoger kan
/// uitvallen dan de meting. Deze balk rekent iets anders: dezelfde meting
/// minus de wind die je zelf maakt. Twee getallen onder dezelfde woorden, vier
/// centimeter uit elkaar, laten de app zichzelf tegenspreken; vandaar een eigen
/// naam plus een infovenster dat het verschil benoemt.
///
/// **Waarom deze widget bestaat.** Tot fase 24 stond hier een pil met twee
/// systeememoji — een t-shirt en een korte broek — die door het besturingssysteem
/// werd getekend en er dus op Android, iOS en het web anders uitzag. Schets 002
/// probeerde daar eigen pictogrammen voor te maken en werd afgewezen: het advies
/// gaat niet over textiel maar over hoe koud het aanvoelt, en dat is informatie,
/// geen illustratie. Dezelfde afweging die fase 23 bij de weerbalken maakte.
///
/// **Wat het oplost dat het plaatje niet oploste.** [recommendClothing] rekent
/// al met gevoelstemperatuur — `temp − (wind + 15) × 0,05`, waarbij die 15 km/u
/// je eigen snelheid is — maar dat getal stond nergens op het scherm. Daardoor
/// adviseerde de app bij een gemeten 15 °C "lange mouw" zonder ooit te zeggen
/// waarom, en zag dat eruit als een fout. Nu staat het getal er, met een
/// infovenster dat het verschil met de voorspelling uitlegt.
///
/// De anatomie is bewust die van `WeatherIndicatorBar`: label, waarde,
/// oordeelswoord, baan met markering, schaalregel. Deze balk staat op Ride
/// Detail vlak boven de regen- en windbalk, en drie balken die elk hun eigen
/// vorm hebben lezen als drie losse dingen in plaats van als één blok weer.
class FeelsLikeBar extends StatelessWidget {
  const FeelsLikeBar({
    super.key,
    required this.feelsLikeC,
    required this.measuredC,
    required this.combo,
  });

  /// Wat het op de fiets aanvoelt — het getal waar het advies op stoelt.
  final double feelsLikeC;

  /// Wat de voorspelling zegt. Alleen gebruikt in het infovenster, om het
  /// verschil te kunnen benoemen.
  final double measuredC;

  final ClothingCombo combo;

  @override
  Widget build(BuildContext context) {
    final rw = context.rw;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = S.of(context);

    const span = feelsLikeZoomMaxC - feelsLikeZoomMinC;
    final rawFraction = (feelsLikeC - feelsLikeZoomMinC) / span;
    final beyondScale = rawFraction > 1.0;
    final fraction = rawFraction.clamp(0.0, 1.0).toDouble();

    final label = _comboLabel(s, combo);
    final range = _rangeLabel(s, combo);
    final value = '${feelsLikeC.round()}°';

    final scaleStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 9,
      color: rw.textHint,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Semantics(
      // Zonder dit leest een screenreader de waarde, het advies en de twee
      // schaalranden als losse fragmenten, terwijl het één uitspraak is.
      label: '${s.clothingOnTheBike} $value, $label, $range',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(AppIcons.thermometerSimple, size: 13, color: rw.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.clothingOnTheBike,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: rw.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: rw.scorePerfect,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              Semantics(
                button: true,
                label: s.weatherMetricInfoTooltip(s.clothingOnTheBike),
                child: GestureDetector(
                  onTap: () => _showInfo(context),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 36,
                    height: 28,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        AppIcons.info,
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
            // `width` is niet optioneel — zie de toelichting in
            // weather_indicator_bar.dart: een SizedBox zonder breedte valt in
            // een Column terug op 0 en de painter rekent zich stuk.
            width: double.infinity,
            height: 14,
            child: CustomPaint(
              painter: _FeelsLikeBarPainter(
                fraction: fraction,
                beyondScale: beyondScale,
                bands: _bandsFor(rw),
                trackColor: cs.surfaceContainerHigh,
                markColor: rw.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text('${feelsLikeZoomMinC.round()}°', style: scaleStyle),
              Expanded(
                child: Text(
                  '$label · $range',
                  textAlign: TextAlign.center,
                  style: scaleStyle?.copyWith(
                    color: rw.scorePerfect,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${feelsLikeZoomMaxC.round()}°${beyondScale ? '+' : ''}',
                style: scaleStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// De vier banden als getekende tint.
  ///
  /// De kleuren komen alle drie uit tokens die al bestaan, zodat er geen nieuw
  /// palet bijkomt: blauw is `calendarBusy`, groen is `scorePerfect`, oranje is
  /// `warning`. Wel is dit de eerste plek waar kleur in deze app *temperatuur*
  /// betekent in plaats van *kwaliteit* — vandaar de lage dekking: de banden
  /// mogen de schaal kleuren, niet de markering overstemmen.
  List<_Band> _bandsFor(RideWindowTheme rw) => [
        for (final c in ClothingCombo.values)
          _Band(
            start: _fractionFor(c.minFeelsC ?? feelsLikeZoomMinC),
            end: _fractionFor(c.maxFeelsC ?? feelsLikeZoomMaxC),
            color: switch (c) {
              ClothingCombo.longLongExtra =>
                rw.calendarBusy.withValues(alpha: 0.45),
              ClothingCombo.longLong => rw.calendarBusy.withValues(alpha: 0.18),
              ClothingCombo.longShort => rw.scorePerfect.withValues(alpha: 0.20),
              ClothingCombo.shortShort => rw.warning.withValues(alpha: 0.28),
            },
          ),
      ];

  static double _fractionFor(double tempC) =>
      ((tempC - feelsLikeZoomMinC) / (feelsLikeZoomMaxC - feelsLikeZoomMinC))
          .clamp(0.0, 1.0)
          .toDouble();

  static String _comboLabel(S s, ClothingCombo combo) => switch (combo) {
        ClothingCombo.shortShort => s.comboShortShort,
        ClothingCombo.longShort => s.comboLongShort,
        ClothingCombo.longLong => s.comboLongLong,
        ClothingCombo.longLongExtra => s.comboLongLongExtra,
      };

  /// "5–14°", "onder 5°" of "vanaf 20°" — de uiteinden hebben maar één grens,
  /// en "Lang/lang + · 5°" zou lezen als "bij 5 graden".
  static String _rangeLabel(S s, ClothingCombo combo) {
    final min = combo.minFeelsC;
    final max = combo.maxFeelsC;
    if (min == null) return s.clothingBandBelow(max!.round());
    if (max == null) return s.clothingBandAbove(min.round());
    return s.clothingBandBetween(min.round(), max.round());
  }

  void _showInfo(BuildContext context) {
    final rw = context.rw;
    final s = S.of(context);
    final drop = (measuredC - feelsLikeC).round();
    // Zelfde behandeling als de weerbalken: isScrollControlled plus een
    // scrollende body, anders knipt de sheet zijn onderkant af zodra de
    // vertaalde tekst langer uitvalt.
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
                  Icon(AppIcons.thermometerSimple, size: 20, color: rw.scorePerfect),
                  const SizedBox(width: 8),
                  Text(
                    s.clothingOnTheBike,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                s.clothingFeelsLikeInfo,
                style: TextStyle(
                  fontSize: 14,
                  color: rw.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                // Het concrete geval erbij, want een formule uitleggen zonder
                // de eigen cijfers laat de gebruiker het zelf narekenen.
                drop > 0
                    ? s.clothingFeelsLikeDrop(
                        measuredC.round(),
                        feelsLikeC.round(),
                        drop,
                      )
                    : s.clothingFeelsLikeNoDrop(measuredC.round()),
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

class _Band {
  const _Band({required this.start, required this.end, required this.color});
  final double start;
  final double end;
  final Color color;
}

/// Dezelfde baan als `_BarPainter` in weather_indicator_bar.dart, met één
/// verschil: daar ligt één ideaalzone op de baan, hier liggen vier banden naast
/// elkaar die de baan volledig vullen.
class _FeelsLikeBarPainter extends CustomPainter {
  _FeelsLikeBarPainter({
    required this.fraction,
    required this.beyondScale,
    required this.bands,
    required this.trackColor,
    required this.markColor,
  });

  final double fraction;
  final bool beyondScale;
  final List<_Band> bands;
  final Color trackColor;
  final Color markColor;

  static const _trackHeight = 6.0;
  static const _markWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // Een baan van nul breedte kost een RangeError in de clamps hieronder, en
    // een exceptie tijdens paint neemt de hele kaart mee — niet alleen de balk.
    if (w <= 0 || size.height <= 0) return;
    final top = (size.height - _trackHeight) / 2;
    final radius = const Radius.circular(_trackHeight / 2);
    final track = RRect.fromLTRBR(0, top, w, top + _trackHeight, radius);

    canvas.drawRRect(track, Paint()..color = trackColor);

    canvas.save();
    canvas.clipRRect(track);
    for (final band in bands) {
      final left = band.start * w;
      final right = band.end * w;
      if (right <= left) continue;
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, top + _trackHeight),
        Paint()..color = band.color,
      );
    }
    canvas.restore();

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
  bool shouldRepaint(_FeelsLikeBarPainter old) =>
      old.fraction != fraction ||
      old.beyondScale != beyondScale ||
      old.markColor != markColor ||
      old.trackColor != trackColor;
}
