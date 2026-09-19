// lib/features/shared/add_to_home_screen_overlay.dart
// "Zet op beginscherm"-balk voor iOS Safari in browsermodus (PWA-03).
//
// **D-04 is op 2026-09-19 teruggedraaid.** Fase 16 koos bewust voor geen
// wegklikknop en geen opslag: de balk zou elke sessie terugkomen tot de
// gebruiker de app installeert, en dan voorgoed verdwijnen. Een tester meldde
// het gevolg: de balk ligt bovenop de app en gaat nooit weg, dus een strook van
// elk scherm is permanent onzichtbaar. Een uitnodiging die je niet kunt
// wegleggen is geen uitnodiging meer.
//
// Hij is nu weg te klikken, sluimert dan een week, en na drie keer wegklikken
// houdt de app erover op. Zie `InstallHintStore` voor waarom niet voorgoed.
//
// Staat bovenaan en niet onderaan, zodat hij de vaste NavigationBar in
// ScaffoldWithNav nooit afdekt.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/core/pwa_display_mode.dart';
import 'package:ridewindow/data/repositories/install_hint_store.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';

class AddToHomeScreenOverlay extends StatefulWidget {
  const AddToHomeScreenOverlay({super.key});

  @override
  State<AddToHomeScreenOverlay> createState() => _AddToHomeScreenOverlayState();
}

class _AddToHomeScreenOverlayState extends State<AddToHomeScreenOverlay> {
  /// Begint zichtbaar en wordt alleen verborgen als de opslag daar aanleiding
  /// toe geeft. Bewust die kant op: lukt het lezen niet -- geen plugin in een
  /// widget-test, geopende privémodus -- dan toont de app de balk gewoon, zoals
  /// hij het altijd deed. Falen naar zichtbaar, niet naar stil.
  bool _hidden = false;

  InstallHintStore? _store;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final store = InstallHintStore(await SharedPreferences.getInstance());
      if (!mounted) return;
      setState(() {
        _store = store;
        _hidden = store.isSuppressed();
      });
    } catch (_) {
      // Zichtbaar laten.
    }
  }

  Future<void> _dismiss() async {
    setState(() => _hidden = true);
    try {
      await _store?.recordDismissal();
    } catch (_) {
      // De balk is al weg voor deze sessie; onthouden is een extraatje.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isWebPlatform || !isIosBrowserMode || isStandaloneDisplayMode) {
      return const SizedBox.shrink();
    }
    if (_hidden) return const SizedBox.shrink();

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
            padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
            child: Row(
              children: [
                Icon(
                  AppIcons.export,
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
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(AppIcons.x, size: 18),
                  color: colorScheme.onInverseSurface,
                  // MaterialLocalizations en geen eigen ARB-sleutel: Flutter
                  // vertaalt deze al in beide talen.
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  visualDensity: VisualDensity.compact,
                  onPressed: _dismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
