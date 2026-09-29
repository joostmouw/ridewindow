// lib/features/shared/banner_close_button.dart
// Het kruisje van de balken bovenaan (TopBanners).

import 'package:flutter/material.dart';

import 'package:ridewindow/theme/app_icons.dart';

/// Een kruisje zonder tooltip, met het label op het icoon.
///
/// **Waarom geen `tooltip:`.** De balken staan in `MaterialApp.router(builder:)`,
/// boven de Navigator en dus boven elke Overlay. Een tooltip heeft een Overlay
/// nodig: lang indrukken (of op web met de muis erboven hangen) gooide daar
/// "No Overlay widget found". Het label op het icoon geeft de schermlezer
/// hetzelfde woord.
class BannerCloseButton extends StatelessWidget {
  const BannerCloseButton({
    super.key,
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        AppIcons.x,
        size: 18,
        // MaterialLocalizations en geen eigen ARB-sleutel: Flutter vertaalt
        // deze al in beide talen.
        semanticLabel: MaterialLocalizations.of(context).closeButtonTooltip,
      ),
      color: color,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}
