// lib/features/peloton/group_rules_sheet.dart
// De groepsregels achter de info-knop (CLUB-28): naast de kop "Groepen" op de
// Peloton-tab en in de appbar van het groepsscherm.

import 'package:flutter/material.dart';

import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';

/// Opent de sheet met de zeven groepsregels.
Future<void> showGroupRulesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final s = S.of(sheetContext);
      final theme = Theme.of(sheetContext);
      final rules = [
        s.groupRuleProposing,
        s.groupRuleLimits,
        s.groupRuleVisibility,
        s.groupRuleRides,
        s.groupRuleLeaving,
        s.groupRuleLastAdmin,
        s.groupRuleDisband,
      ];
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.groupRulesTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final (i, rule) in rules.indexed)
              Padding(
                key: ValueKey('group-rule-$i'),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        AppIcons.check,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(rule, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// De info-knop die [showGroupRulesSheet] opent. Eén widget, zodat hij op de
/// tab en op het groepsscherm hetzelfde is (patroon van `_infoButton` in
/// Profiel: onSurfaceVariant, 48x48, tooltip).
class GroupRulesButton extends StatelessWidget {
  const GroupRulesButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return IconButton(
      icon: Icon(
        AppIcons.info,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      tooltip: s.groupRulesTitle,
      onPressed: () => showGroupRulesSheet(context),
    );
  }
}
