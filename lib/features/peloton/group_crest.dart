// lib/features/peloton/group_crest.dart
// Het kenteken van een groep: de initialen op een merkvlak (schets 015).

import 'package:flutter/material.dart';

import 'package:ridewindow/domain/models/peloton_group.dart';
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
