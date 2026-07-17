// lib/features/shared/add_to_home_screen_overlay.dart
// Persistent "Add to Home Screen" instructional banner for iOS Safari
// browser mode (Phase 16 Plan 02, PWA-03). Deliberately simpler than
// lib/features/shared/screen_hint_overlay.dart's one-time coach-mark
// pattern -- per D-04, this has NO shared_preferences persistence and NO
// dismiss button. It reappears every session until the browser's
// `display-mode: standalone` media query matches (i.e. the user actually
// installs the app), at which point it disappears for good.
//
// Positioned at the TOP of the screen (not bottom) so it never covers the
// persistent bottom NavigationBar in ScaffoldWithNav.

import 'package:flutter/material.dart';

import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/core/pwa_display_mode.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

class AddToHomeScreenOverlay extends StatelessWidget {
  const AddToHomeScreenOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    if (!isWebPlatform || !isIosBrowserMode || isStandaloneDisplayMode) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: colorScheme.inverseSurface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.ios_share,
                  color: colorScheme.onInverseSurface,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.addToHomeScreenHint,
                    style: TextStyle(color: colorScheme.onInverseSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
