import 'package:flutter/material.dart';

import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Hoe een rol eruitziet: één icoon, één kleur, één zin.
///
/// **Eén bron voor alle drie de plekken waar een rit staat** -- Home, de
/// rittenlijst en het detailscherm. Tot 2026-09-08 droegen "jij organiseert"
/// en "je gaat mee" allebei [AppIcons.usersThree] en verschilden ze alleen in
/// de sectiekop waaronder ze toevallig stonden; wie de kop niet las, las het
/// verschil niet (schets 008). Vier rollen, vier iconen, vier kleuren -- en op
/// elk scherm dezelfde.
({IconData icon, Color color, String label}) rideRoleStyle(
  BuildContext context,
  RideEntry entry,
) {
  final s = S.of(context);
  final rw = context.rw;
  final owner = entry.ownerName?.trim();
  final who = (owner == null || owner.isEmpty) ? s.pelotonUnnamedFriend : owner;

  return switch (entry.role) {
    RideRole.pending => (
        icon: AppIcons.hourglass,
        color: rw.ridePending,
        label: s.rolePendingFrom(who),
      ),
    RideRole.organiser => (
        icon: AppIcons.flag,
        color: rw.rideOrganiser,
        label: s.roleOrganiser,
      ),
    RideRole.joined => (
        icon: AppIcons.usersThree,
        color: rw.plannedRide,
        label: s.roleJoinedWith(who),
      ),
    RideRole.solo => (
        icon: AppIcons.personSimpleBike,
        color: rw.textTertiary,
        label: s.roleSolo,
      ),
  };
}

/// De regel onder de tijd die zegt wat jouw rol is.
class RideRoleLine extends StatelessWidget {
  const RideRoleLine({super.key, required this.entry, this.dense = false});

  final RideEntry entry;

  /// Compacter, voor de kaartjes onder PLANNED op Home.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = rideRoleStyle(context, entry);
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(style.icon, size: dense ? 14 : 15, color: style.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            style.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (dense
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.labelMedium)
                ?.copyWith(
              color: style.color,
              // Solo is de rustige rol: hij krijgt geen vet mee, anders schreeuwt
              // "Alleen jij" net zo hard als een uitnodiging die op antwoord wacht.
              fontWeight: entry.role == RideRole.solo
                  ? FontWeight.w500
                  : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// "2 gaan mee · 1 wacht nog" -- alleen voor de rit die jij organiseert.
///
/// Bij andermans rit bewust niet: daar is "van wie is dit" de eerste vraag en
/// niet "hoeveel man gaat er mee", en dat antwoord staat al in [RideRoleLine].
String? pelotonSummary(BuildContext context, RideEntry entry) {
  if (entry.role != RideRole.organiser) return null;
  final s = S.of(context);
  final parts = <String>[s.ridePelotonGoing(entry.acceptedCount)];
  if (entry.pendingCount > 0) {
    parts.add(s.ridePelotonWaiting(entry.pendingCount));
  }
  return parts.join(' · ');
}
