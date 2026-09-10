import 'package:flutter/material.dart';

import 'package:ridewindow/domain/services/daylight.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Eén regel onder een rit, en alleen als er iets te melden valt.
///
/// **Waarom niet altijd.** Negen van de tien vensters vallen volledig bij
/// daglicht, en daar is "de zon gaat om 20:07 onder" ruis. De regel verschijnt
/// pas als het donker een deel van de rit raakt — dan is het precies wat
/// Ingrid miste toen de app haar donderdag 20:00–22:00 op score 100 zette
/// terwijl de zon om 20:07 onderging (2026-09-09).
///
/// Zelfde vorm als [RideRoleLine] uit schets 008: één icoon, één kleur, één
/// zin. Dat is inmiddels de manier waarop deze app iets over een rit zegt.
class DaylightNote extends StatelessWidget {
  const DaylightNote({
    super.key,
    required this.start,
    required this.end,
    required this.latitude,
    required this.longitude,
    this.dense = false,
  });

  final DateTime start;
  final DateTime end;
  final double latitude;
  final double longitude;

  /// Compacter, voor de kleinere kaarten.
  final bool dense;

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rw = context.rw;
    final theme = Theme.of(context);

    final dark = darkFraction(
      start: start,
      end: end,
      latitude: latitude,
      longitude: longitude,
    );
    // Een paar minuten schemer aan de rand is geen mededeling waard.
    if (dark <= 0.02) return const SizedBox.shrink();

    final sun = sunTimes(
      latitude: latitude,
      longitude: longitude,
      dayLocal: start,
    );
    if (!sun.hasSunTimes) return const SizedBox.shrink();

    final String text;
    if (start.isBefore(sun.sunrise!) && end.isAfter(sun.sunrise!)) {
      text = s.rideSunriseAfter(_hhmm(sun.sunrise!));
    } else if (dark >= 0.5) {
      text = s.rideSunsetMostlyDark(_hhmm(sun.sunset!));
    } else {
      text = s.rideSunsetPartly(_hhmm(sun.sunset!));
    }

    // Grotendeels donker krijgt de vollere tint, een randje schemer de zachte:
    // het verschil tussen "hier moet je iets mee" en "goed om te weten".
    final color = dark >= 0.5 ? rw.rideOrganiser : rw.warning;

    return Padding(
      padding: EdgeInsets.only(top: dense ? 3 : 6),
      child: Row(
        children: [
          Icon(dark >= 0.5 ? AppIcons.moonStars : AppIcons.sunHorizon,
              size: dense ? 13 : 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (dense
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.labelMedium)
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
