import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/features/shared/ride_role_style.dart';
import 'package:ridewindow/theme/app_icons.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Wie er al ja zei: een fietsje per persoon, plus de zin die ze telt.
///
/// **Waarom een plaatje bij een zin die het al zegt.** "3 gaan mee · 1 wacht
/// nog" is precies, maar je moet het lezen; de fietsjes laten in één blik zien
/// hoe groot de groep wordt en hoeveel ervan nog open staat (Joost, schets 014).
/// De doorzichtige fietsjes zijn de mensen die nog niet geantwoord hebben --
/// dezelfde afspraak als de gedempte naam in de deelnemerslijst op het
/// detailscherm.
///
/// De fietsjes volgen de zin exact: `acceptedCount` volle en `pendingCount`
/// doorzichtige. De organisator zit in geen van beide -- die staat niet in zijn
/// eigen deelnemerslijst (zie [RideEntry.acceptedCount]).
class PelotonCounter extends StatelessWidget {
  const PelotonCounter({super.key, required this.entry, this.dense = false});

  final RideEntry entry;

  /// Compacter, voor de kaartjes onder GEPLAND op Home.
  final bool dense;

  /// Meer dan dit aantal fietsjes wordt een getal. Bij zes man op een rij van
  /// 372px blijft er anders niets over voor de zin ernaast, en juist die zin
  /// draagt de precieze aantallen.
  static const _maxDrawn = 5;

  @override
  Widget build(BuildContext context) {
    final summary = pelotonSummary(context, entry);
    if (summary == null) return const SizedBox.shrink();

    final rw = context.rw;
    final theme = Theme.of(context);
    final accepted = entry.acceptedCount;
    final total = accepted + entry.pendingCount;
    final drawn = math.min(total, _maxDrawn);
    final rest = total - drawn;

    final size = dense ? 12.0 : 14.0;
    // Donker slikt lage dekking sneller op dan licht: bij .32 was de wachtende
    // fietser daar bijna weg (gemeten in de schets, beide helderheden).
    final waiting = rw.plannedRide.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.45 : 0.32,
    );

    return Padding(
      padding: EdgeInsets.only(top: dense ? 3 : 4),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < drawn; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 1),
                    child: Icon(
                      AppIcons.personSimpleBike,
                      size: size,
                      color: i < accepted ? rw.plannedRide : waiting,
                    ),
                  ),
                if (rest > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Text(
                      '+$rest',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: rw.plannedRide,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: dense ? 11 : null,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
