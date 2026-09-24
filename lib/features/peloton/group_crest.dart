// lib/features/peloton/group_crest.dart
// Het kenteken van een groep (de initialen op een merkvlak) en de chip
// "beheerder", zoals in schets 015.

import 'package:flutter/material.dart';

import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_colors.dart';

/// Afgeronde rechthoek met de initialen van de groep.
///
/// De kleuren staan vast, en dat is geen uitzondering op de theme-tokens maar
/// het gevolg ervan: dit vlak zet zijn achtergrond vast op een merkkleur, dus
/// zet het ook zijn voorgrond vast (zie de noot bij `buildAppTheme`). Licht is
/// het brandLight met brandDark erop, donker precies omgekeerd; hetzelfde
/// contrastpaar, dus in beide helderheden even leesbaar.
class GroupCrest extends StatelessWidget {
  const GroupCrest({super.key, required this.name, this.size = 42});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? AppColors.brandDark : AppColors.brandLight;
    final foreground = dark ? AppColors.brandLight : AppColors.brandDark;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Text(
        groupInitials(name),
        maxLines: 1,
        style: TextStyle(
          color: foreground,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

/// De chip "beheerder" (`.chip.admin` in schets 015): omlijnd, rustig, in de
/// groepskaart op de tab en achter een lid op het groepsscherm. Eén widget,
/// zodat beide plekken dezelfde chip tonen.
class GroupAdminChip extends StatelessWidget {
  const GroupAdminChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        S.of(context).groupAdminChip,
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
