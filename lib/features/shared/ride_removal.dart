// lib/features/shared/ride_removal.dart
//
// Eén manier om een rit weg te halen, op Home, op Ritten en in het ritdetail.
//
// **Waarom dit er is (Joost, 2026-09-25).** Een rit die je had gepland en
// waarvoor je een maatje had uitgenodigd, ging niet weg. Drie plekken deden
// drie verschillende dingen: Home had alleen een prullenbak voor een rit van
// jou alleen, het ritdetail haalde bij "Gepland ✓" alleen je lokale planning
// weg -- de gedeelde rit bleef in de cloud staan en kwam meteen terug als "Je
// organiseert" -- en alleen vegen op Ritten zegde hem echt af. Nu beslist de
// rol wat "weghalen" is, en roepen alle drie deze functie aan.
//
// - Van jou alleen: meteen weg, met "Ongedaan maken". Geen vraag vooraf: het
//   raakt niemand anders en is in één tik terug te zetten.
// - Jij organiseert: eerst bevestigen, want je genodigden zien de rit
//   verdwijnen en dat is niet terug te draaien. Pas als de cloud hem echt kwijt
//   is, gaat ook je eigen planning eraf.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridewindow/domain/models/planned_ride.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';

/// Haalt [entry] weg zoals bij jouw rol past. Geeft `true` als de rit weg is,
/// `false` bij annuleren of een fout -- dan staat hij er nog, en dat mag de
/// aanroeper ook zo laten zien (een weggeveegde kaart komt terug).
Future<bool> removeRide(
  BuildContext context,
  WidgetRef ref,
  RideEntry entry,
) async {
  switch (entry.role) {
    case RideRole.solo:
      return _removeSolo(context, ref, entry);
    case RideRole.organiser:
      return _cancelOrganised(context, ref, entry);
    case RideRole.pending:
    case RideRole.joined:
    case RideRole.declined:
      return false;
  }
}

Future<bool> _removeSolo(
  BuildContext context,
  WidgetRef ref,
  RideEntry entry,
) async {
  final planned = entry.planned;
  if (planned == null) return false;
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(plannedRidesProvider.notifier);
  await notifier.remove(planned);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(s.rideRemoved),
        action: SnackBarAction(
          label: s.pelotonUndo,
          onPressed: () => notifier.add(planned),
        ),
      ),
    );
  return true;
}

Future<bool> _cancelOrganised(
  BuildContext context,
  WidgetRef ref,
  RideEntry entry,
) async {
  final ride = entry.group;
  if (ride == null) return false;
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  // Vóór de dialoog gepakt: daarna kan het scherm al weg zijn.
  final gateway = ref.read(pelotonGatewayProvider);
  final planned = ref.read(plannedRidesProvider.notifier);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.pelotonCancelRideTitle),
      content: Text(s.pelotonCancelRideBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(s.pelotonCancelRide),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  try {
    await gateway.deleteGroupRide(ride.id);
  } catch (error) {
    debugPrint('Peloton: afzeggen mislukt: $error');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.pelotonCancelFailed)));
    return false;
  }

  // De persoonlijke rij gaat mee, ook als de kaart hem niet droeg: laat je
  // die staan, dan komt de rit terug als "Alleen jij" en lijkt het afzeggen
  // mislukt.
  final own = entry.planned ??
      PlannedRide(
        start: entry.start,
        end: entry.end,
        plannedScore: entry.plannedScore,
      );
  await planned.remove(own);
  ref.invalidate(groupRidesProvider);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(s.pelotonRideCancelled)));
  return true;
}
