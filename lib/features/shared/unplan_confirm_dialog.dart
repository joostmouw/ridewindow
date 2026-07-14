// lib/features/shared/unplan_confirm_dialog.dart
// Shared confirm dialog shown before unplanning/deleting a planned ride from
// a casual tap target (Ride Detail's "Planned" button, Home's delete icon).
//
// This dialog ONLY shows the AlertDialog and returns whether the user
// confirmed. It does NOT call PlannedRidesNotifier.remove() or show the
// post-delete SnackBar — those side effects differ slightly per call site
// and stay local to each caller.

import 'package:flutter/material.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

/// Shows a confirm dialog asking whether to unplan a ride.
///
/// Returns `true` if the user confirmed the "Unplan" action, `false` if they
/// cancelled or dismissed the dialog by tapping outside it.
Future<bool> showUnplanConfirmDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(S.of(ctx).unplanConfirmTitle),
      content: Text(S.of(ctx).unplanConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(S.of(ctx).cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(S.of(ctx).unplanConfirmAction),
        ),
      ],
    ),
  );
  return result ?? false;
}
