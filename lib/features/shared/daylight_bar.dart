import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import 'package:ridewindow/domain/services/daylight.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// De vierde weerbalk: hoeveel van je rit bij daglicht valt.
///
/// **Bewust in dezelfde vorm als [WeatherIndicatorBar] en niet als de losse
/// tegel uit de referentie.** Joost stuurde een screenshot van een paarse
/// zonsopgang-tegel uit een andere app (2026-09-10). Die liet zien wélke
/// informatie hij miste, niet in welke vorm — en dit scherm heeft al een taal
/// voor "een schaal, een zone die goed is, en waar jij erin valt". Een vreemde
/// tegel ernaast zou een tweede vormtaal introduceren voor hetzelfde soort
/// uitspraak.
///
/// Twee dingen zijn wél anders dan bij de andere drie, allebei omdat de as tijd
/// is en geen meetwaarde:
///  * de as loopt over het hele etmaal en zoomt niet in op een fietsbereik
///    (keuze van Joost, schets 011) — bij daglicht is juist de hele dag de
///    betekenisvolle context;
///  * de rit is een blok en geen streepje, want hij duurt.
///
/// **Waar jouw instelling staat, en waarom niet op de balk.** De andere drie
/// balken zetten in het middenlabel "jouw bereik ≤15 km/u" -- een grens. Bij
/// daglicht bestaat zo'n grens niet: het is een *gewicht*, en er is geen
/// bereik waarbinnen je tevreden bent. Op 2026-09-19 stond dat gewicht er een
/// middag lang wél ("half mee"), naast de lichtperiode. Joost: dat hoort in de
/// uitleg, niet op de balk.
///
/// Dus staat er nu één uitspraak onder de balk -- de gouden lichtperiode, in
/// de kleur van die band -- en vertelt het infovenster wat jouw gevoeligheid
/// met dít venster doet. Dat infovenster heeft nu ook dezelfde vorm als dat
/// van de andere drie: dezelfde sheet, dezelfde koprij, en eronder hetzelfde
/// tweede blok over waarom deze score deze score is.
class DaylightBar extends StatelessWidget {
  const DaylightBar({
    super.key,
    required this.start,
    required this.end,
    required this.latitude,
    required this.longitude,
    required this.darknessWeight,
  });

  final DateTime start;
  final DateTime end;
  final double latitude;
  final double longitude;

  /// Hoe zwaar donker meetelt in de score: 0 = niet, 1 = maximaal. Dezelfde
  /// waarde die Profiel > Jouw grenzen > Daglicht instelt.
  final double darknessWeight;

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Waar een moment op de etmaal-as staat, van 0,0 (00:00) tot 1,0 (24:00).
  double _fractionOfDay(DateTime moment, DateTime dayStart) =>
      (moment.difference(dayStart).inMinutes / 1440).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rw = context.rw;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final sun = sunTimes(
      latitude: latitude,
      longitude: longitude,
      dayLocal: start,
    );
    final dark = darkFraction(
      start: start,
      end: end,
      latitude: latitude,
      longitude: longitude,
    );

    final totalMinutes = end.difference(start).inMinutes;
    final lightMinutes = (totalMinutes * (1 - dark)).round();

    final (String verdict, Color verdictColor) = switch (dark) {
      <= 0.01 => (s.daylightVerdictFull, rw.scorePerfect),
      < 0.25 => (s.daylightVerdictMostlyLight, rw.scorePerfect),
      < 0.6 => (s.daylightVerdictPartlyDark, rw.warning),
      < 0.95 => (s.daylightVerdictMostlyDark, rw.rideOrganiser),
      _ => (s.daylightVerdictDark, rw.rideOrganiser),
    };

    final dayStart = DateTime(start.year, start.month, start.day);
    final scaleStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 9,
      color: rw.textHint,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final lightLabel = sun.hasSunTimes
        ? s.daylightLightShort(_hhmm(sun.sunrise!), _hhmm(sun.sunset!))
        : (sun.polarDaylight ? s.daylightPolarDay : s.daylightPolarNight);

    final weightLabel = switch (darknessWeight) {
      <= 0.05 => s.daylightWeightNone,
      < 0.4 => s.daylightWeightLight,
      < 0.75 => s.daylightWeightHalf,
      _ => s.daylightWeightHeavy,
    };

    return Semantics(
      label: '${s.weatherDaylight} ${s.daylightMinutes(lightMinutes)}, '
          '$verdict, $lightLabel',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(AppIcons.sunHorizon, size: 13, color: rw.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.weatherDaylight,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: rw.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  s.daylightMinutes(lightMinutes),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  verdict.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: verdictColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                Semantics(
                  button: true,
                  label: s.weatherMetricInfoTooltip(s.weatherDaylight),
                  child: GestureDetector(
                    onTap: () => _showInfo(
                      context,
                      weightLabel: weightLabel,
                      lightMinutes: lightMinutes,
                      totalMinutes: totalMinutes,
                      darkFraction: dark,
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 36,
                      height: 28,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child:
                            Icon(AppIcons.info, size: 14, color: rw.textHint),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              // Zie de gelijkluidende noot in `weather_indicator_bar.dart`:
              // zonder expliciete breedte krijgt een `SizedBox` in een `Column`
              // een losse constraint en wordt de baan nul pixels breed.
              width: double.infinity,
              height: 14,
              child: CustomPaint(
                painter: _DaylightPainter(
                  lightStart: sun.hasSunTimes
                      ? _fractionOfDay(sun.sunrise!, dayStart)
                      : (sun.polarDaylight ? 0.0 : 0.0),
                  lightEnd: sun.hasSunTimes
                      ? _fractionOfDay(sun.sunset!, dayStart)
                      : (sun.polarDaylight ? 1.0 : 0.0),
                  rideStart: _fractionOfDay(start, dayStart),
                  rideEnd: _fractionOfDay(end, dayStart),
                  trackColor: cs.surfaceContainerHigh,
                  lightColor: rw.daylight,
                  rideColor: rw.plannedRide,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Text('00:00', style: scaleStyle),
                Expanded(
                  // Eén uitspraak: de gouden band uit de balk, in de kleur van
                  // die band. Jouw gevoeligheid stond hier tot 2026-09-19 ook,
                  // en is verhuisd naar het infovenster -- zie de klassenoot.
                  child: Text(
                    lightLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: scaleStyle?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: rw.daylight,
                    ),
                  ),
                ),
                Text('24:00', style: scaleStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Het infovenster, in dezelfde vorm als dat van de andere drie balken.
  ///
  /// **Dit was het echte verschil.** Tot 2026-09-19 opende deze ⓘ een
  /// `AlertDialog` met één alinea, terwijl temperatuur, regen en wind een
  /// bottom sheet openen met een koprij, de algemene uitleg, en daaronder een
  /// tweede blok over waarom déze meting híér deze score kreeg. Joost zei twee
  /// keer dat de daglicht-info anders was dan de rest; de eerste keer
  /// repareerde ik het label onder de balk, en dat was de verkeerde helft.
  ///
  /// De getallen hieronder komen uit `darknessPenalty()`, dezelfde functie die
  /// `SlotGenerator` gebruikt. Dat is geen netheid maar noodzaak -- dezelfde
  /// reden die `weather_indicator_bar.dart` voor zijn voorbeelden geeft:
  /// verschuift de curve, dan moet deze tekst meebewegen, anders vertelt de
  /// app iets anders dan hij doet.
  void _showInfo(
    BuildContext context, {
    required String weightLabel,
    required int lightMinutes,
    required int totalMinutes,
    required double darkFraction,
  }) {
    final s = S.of(context);
    final rw = context.rw;
    final cs = Theme.of(context).colorScheme;

    // De aftrek voor dit venster, en die voor een volledig donker venster bij
    // dezelfde stand. Twee getallen, want één ervan geeft het andere pas maat.
    final points = (darknessPenalty(darkFraction, weight: darknessWeight) * 100)
        .round();
    final fullDarkPoints =
        (darknessPenalty(1.0, weight: darknessWeight) * 100).round();
    final body = TextStyle(fontSize: 14, color: rw.textSecondary, height: 1.5);

    showModalBottomSheet<void>(
      context: context,
      // Zelfde reden als bij de andere drie: een sheet zonder dit knipt zijn
      // onderkant af zodra de vertaalde tekst niet past.
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
                  Icon(AppIcons.sunHorizon, size: 20, color: rw.scorePerfect),
                  const SizedBox(width: 8),
                  Text(
                    s.daylightInfoTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(s.daylightInfo, style: body),
              const SizedBox(height: 20),
              Divider(height: 1, color: cs.outlineVariant),
              const SizedBox(height: 16),
              Text(
                s.daylightScoreTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: rw.scorePerfect,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.daylightScoreSplit(
                  totalMinutes,
                  lightMinutes,
                  totalMinutes - lightMinutes,
                ),
                style: body,
              ),
              const SizedBox(height: 8),
              Text(
                // Drie gevallen, niet twee. Nul aftrek heeft twee heel
                // verschillende oorzaken, en ze door elkaar halen levert een
                // zin op die zichzelf tegenspreekt: op het toestel stond
                // "jouw gevoeligheid staat op *donker telt een beetje*, dus
                // daglicht verandert de score niet" -- bij een rit die
                // gewoon volledig in het licht viel. Gezien op de Oppo,
                // 2026-09-19, nadat de test met gevoeligheid nul groen stond.
                switch ((darkFraction, points)) {
                  (< 0.005, _) => s.daylightScoreAllLight,
                  (_, 0) => s.daylightScoreNone(weightLabel),
                  _ => s.daylightScorePenalty(weightLabel, points),
                },
                style: body,
              ),
              if (fullDarkPoints > 0) ...[
                const SizedBox(height: 8),
                Text(s.daylightScoreScale(fullDarkPoints), style: body),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DaylightPainter extends CustomPainter {
  const _DaylightPainter({
    required this.lightStart,
    required this.lightEnd,
    required this.rideStart,
    required this.rideEnd,
    required this.trackColor,
    required this.lightColor,
    required this.rideColor,
  });

  final double lightStart;
  final double lightEnd;
  final double rideStart;
  final double rideEnd;
  final Color trackColor;
  final Color lightColor;
  final Color rideColor;

  static const _trackHeight = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final top = (size.height - _trackHeight) / 2;
    final radius = const Radius.circular(_trackHeight / 2);

    // De hele nacht-en-dag als baan.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, top, size.width, _trackHeight),
        radius,
      ),
      Paint()..color = trackColor,
    );

    // Het lichte deel. Aan beide uiteinden verloopt hij naar de baankleur,
    // want de zon springt niet aan: schemer is geen scherpe rand, en een harde
    // rand zou meer precisie suggereren dan er is.
    if (lightEnd > lightStart) {
      final rect = Rect.fromLTWH(
        lightStart * size.width,
        top,
        (lightEnd - lightStart) * size.width,
        _trackHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()
          ..shader = LinearGradient(
            colors: [
              lightColor.withValues(alpha: 0.35),
              lightColor,
              lightColor,
              lightColor.withValues(alpha: 0.35),
            ],
            stops: const [0.0, 0.12, 0.88, 1.0],
          ).createShader(rect),
      );
    }

    // De rit als blok, iets hoger dan de baan zodat hij er duidelijk óp ligt.
    const blockHeight = 12.0;
    final blockTop = (size.height - blockHeight) / 2;
    final left = rideStart * size.width;
    // Een minimumbreedte, anders is een rit van een uur op een etmaal-as maar
    // vier pixels breed en lees je hem als een streepje in plaats van een duur.
    final width = ((rideEnd - rideStart) * size.width).clamp(8.0, size.width);
    final blockRect = Rect.fromLTWH(
      left.clamp(0.0, size.width - width),
      blockTop,
      width,
      blockHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(blockRect, const Radius.circular(4)),
      Paint()..color = rideColor.withValues(alpha: 0.28),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(blockRect, const Radius.circular(4)),
      Paint()
        ..color = rideColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_DaylightPainter old) =>
      old.lightStart != lightStart ||
      old.lightEnd != lightEnd ||
      old.rideStart != rideStart ||
      old.rideEnd != rideEnd ||
      old.trackColor != trackColor ||
      old.lightColor != lightColor ||
      old.rideColor != rideColor;
}
