// lib/features/peloton/group_dialogs.dart
// Bevestigingen voor groep verlaten en groep opheffen (CLUB-06, CLUB-11).
//
// Vastgelegde keuze (34-CONTEXT, "kies en leg vast"):
// - **Verlaten** krijgt een bevestiging en géén ongedaan maken: terugkomen
//   kan alleen met een nieuwe aanvraag die een beheerder moet goedkeuren, dus
//   een snackbar met "Ongedaan maken" zou iets beloven wat niet kan.
// - **Opheffen** krijgt een bevestiging, want het is onomkeerbaar.
// - **Eruit halen** heeft wel een echte ongedaan maken (plan 05): daar wordt
//   de verwijdering uitgesteld tot de snackbar sluit.
//
// Beide dialogen poppen met hun eigen context: die van het groepsscherm kan
// binnen go_router naar een andere navigator wijzen (zie de noot bij
// `_infoButton` in Profiel).

import 'package:flutter/material.dart';

import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

/// Vraagt of [me] [group] wil verlaten. De tekst zegt vooraf wat er gebeurt:
/// als laatste lid verdwijnen groep en link, als enige beheerder wordt het
/// langst zittende lid beheerder.
Future<bool> showLeaveGroupDialog(
  BuildContext context, {
  required PelotonGroup group,
  required String? me,
}) async {
  final s = S.of(context);
  final successor = group.successorIfLeaving(me);
  final body = group.isLastMember(me)
      ? s.groupLeaveBodyLast
      : successor != null
          ? s.groupLeaveBodySuccessor(successor.label(s.pelotonUnnamedFriend))
          : s.groupLeaveBody;
  return _confirm(
    context,
    title: s.groupLeaveTitle(group.name),
    body: body,
    action: s.groupLeaveAction,
  );
}

/// Vraagt of [group] opgeheven mag worden, met het aantal leden en wat er met
/// de ritten gebeurt.
Future<bool> showDisbandGroupDialog(
  BuildContext context, {
  required PelotonGroup group,
}) {
  final s = S.of(context);
  return _confirm(
    context,
    title: s.groupDisbandTitle(group.name),
    body: s.groupDisbandBody(group.memberCount),
    action: s.groupDisbandAction,
  );
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(S.of(dialogContext).cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}
