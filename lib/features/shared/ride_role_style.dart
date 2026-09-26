import 'package:flutter/material.dart';

import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Hoe een rol eruitziet: hooguit één icoon, één kleur, één zin.
///
/// **Eén bron voor alle drie de plekken waar een rit staat** -- Home, de
/// rittenlijst en het detailscherm. Tot 2026-09-08 droegen "jij organiseert"
/// en "je gaat mee" allebei [AppIcons.usersThree] en verschilden ze alleen in
/// de sectiekop waaronder ze toevallig stonden; wie de kop niet las, las het
/// verschil niet (schets 008).
///
/// **Herzien in schets 014 (2026-09-21).** Niet elke rol verdient een icoon.
/// Dat een rit gedeeld is, zegt het merkteken links op de kaart al ([RideMark]);
/// een tweede tekening in de regel eronder zei hetzelfde nog een keer. Er blijft
/// één icoon over dat iets toevoegt -- de megafoon: *jij* bent de organisator.
/// Meerijden is dan tekst, en dat is genoeg. De twee rollen die iets van jou
/// vragen of iets doorstrepen houden hun icoon, want die moeten opvallen.
({IconData? icon, Color color, String label}) rideRoleStyle(
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
    // De megafoon van de roeicoach, niet langer een vlag: een vlag zegt
    // "finish" en niet "ik heb dit georganiseerd" (Joost, schets 014).
    RideRole.organiser => (
        icon: AppIcons.megaphoneSimple,
        color: rw.rideOrganiser,
        label: s.roleOrganiser,
      ),
    RideRole.joined => (
        icon: null,
        color: rw.plannedRide,
        label: s.roleJoinedWith(who),
      ),
    RideRole.solo => (
        icon: null,
        color: rw.textTertiary,
        label: s.roleSolo,
      ),
    // Gedempt en met een doorhaal-icoon: een afgezegde rit is te vinden, maar
    // hij hoort niet om aandacht te vragen tussen de ritten die wel doorgaan.
    RideRole.declined => (
        icon: AppIcons.prohibit,
        color: rw.textTertiary,
        label: s.roleDeclined(who),
      ),
  };
}

/// De regel onder de tijd die zegt wat jouw rol is.
///
/// **Bij een groepsrit staat de groepsnaam vooraan**: "On the Roll · Anna
/// vraagt of je meegaat" (CLUB-16, schets 016 vraag 2 B). Niet als chip en niet
/// op een eigen regel: Joost koos erop dat de kaart nooit hoger wordt dan nu,
/// ook niet op 360 dp -- "Het moet passen op het scherm, dat is het
/// belangrijkste." Een chip of een extra regel kost hoogte op elke kaart; in de
/// rolregel kost de naam alleen breedte, en die regel was er al.
///
/// **De naam krijgt hooguit 45 procent van de regel.** De rolzin is wat iets
/// van je vraagt ("Anna vraagt of je meegaat"), de groepsnaam is context. Een
/// lange groepsnaam kapt dus af met een ellips en laat de rol altijd de rest:
/// 55 procent min het icoon en de punt, ook op het smalle Home-kaartje (circa
/// 180 dp) en met grote tekstschaal. Een korte naam neemt alleen zijn eigen
/// breedte.
class RideRoleLine extends StatelessWidget {
  const RideRoleLine({super.key, required this.entry, this.dense = false});

  final RideEntry entry;

  /// Compacter, voor de kaartjes onder PLANNED op Home.
  final bool dense;

  /// Deel van de regelbreedte dat de groepsnaam hooguit krijgt.
  static const _groupNameShare = 0.45;

  @override
  Widget build(BuildContext context) {
    final style = rideRoleStyle(context, entry);
    final theme = Theme.of(context);
    final textStyle =
        (dense ? theme.textTheme.bodySmall : theme.textTheme.labelMedium)
            ?.copyWith(
      color: style.color,
      // Solo is de rustige rol: hij krijgt geen vet mee, anders schreeuwt
      // "Alleen jij" net zo hard als een uitnodiging die op antwoord wacht.
      fontWeight:
          entry.role == RideRole.solo ? FontWeight.w500 : FontWeight.w600,
    );

    // Geen icoon, geen lege ruimte: bij "je gaat mee" en "alleen jij"
    // begint de zin gewoon links (schets 014).
    final icon = [
      if (style.icon case final icon?) ...[
        Icon(icon, size: dense ? 14 : 15, color: style.color),
        const SizedBox(width: 6),
      ],
    ];
    final label = Expanded(
      child: Text(
        style.label,
        // Twee regels i.p.v. één: op het smalle plankaartje van Home liep de
        // rolzin tegen een ellips aan ("You're o..."), terwijl juist deze zin
        // zegt wat er van jou gevraagd wordt. Past het op één regel, dan
        // blijft hij er ook op; de kaart groeit alleen als het echt niet
        // past (Joost, build 59).
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
    );

    final groupName = entry.groupName?.trim();
    if (groupName == null || groupName.isEmpty) {
      return Row(children: [...icon, label]);
    }

    return Semantics(
      label: '$groupName, ${style.label}',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            ...icon,
            // Geen Flexible eromheen: een niet-flexibel kind krijgt precies
            // zijn eigen breedte (tot de grens), en de rolzin in [Expanded]
            // krijgt de rest. Met Flexible zou de rij de ruimte eerlijk
            // verdelen en kreeg de rol bij een korte naam ook maar de helft.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * _groupNameShare,
              ),
              child: Text(
                groupName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: textStyle?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            // Een punt met vaste lucht eromheen in plaats van " · ": spaties
            // groeien mee met de tekstschaal, de lucht hoeft dat niet.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('·', maxLines: 1, style: textStyle),
            ),
            label,
          ],
        ),
      ),
    );
  }
}

/// "2 gaan mee · 1 wacht nog" -- bij elke gedeelde rit.
///
/// **Tot schets 014 alleen bij je eigen rit.** De redenering was dat bij
/// andermans rit "van wie is dit" de eerste vraag is; in de praktijk wilde je
/// ook daar weten met hoeveel je rijdt en wie er nog moet antwoorden. De zin
/// staat nu onder elke rit die een groep heeft -- zie [PelotonCounter], die hem
/// samen met de fietsjes toont.
String? pelotonSummary(BuildContext context, RideEntry entry) {
  // Een afgezegde rit adverteert zijn groep niet: hij is te vinden, maar
  // vraagt geen aandacht meer (zie [RideRole.declined]).
  if (entry.group == null || entry.isDeclined) return null;
  final s = S.of(context);
  final parts = <String>[s.ridePelotonGoing(entry.acceptedCount)];
  if (entry.pendingCount > 0) {
    parts.add(s.ridePelotonWaiting(entry.pendingCount));
  }
  return parts.join(' · ');
}
