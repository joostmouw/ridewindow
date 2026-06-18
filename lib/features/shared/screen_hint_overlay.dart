import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-screen hint overlay with frosted glass effect.
/// Shows once per screen, tracked via SharedPreferences.

const _kPrefix = 'hint_seen_';

Future<bool> shouldShowHint(String screenKey) async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool('$_kPrefix$screenKey') ?? false);
}

Future<void> markHintSeen(String screenKey) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('$_kPrefix$screenKey', true);
}

/// A single hint item with position and content.
class HintItem {
  final Alignment alignment;
  final IconData gestureIcon;
  final String title;
  final String description;

  const HintItem({
    required this.alignment,
    required this.gestureIcon,
    required this.title,
    required this.description,
  });
}

/// Shows a frosted glass overlay with contextual hints for the current screen.
/// Tapping anywhere dismisses it.
class ScreenHintOverlay extends StatelessWidget {
  const ScreenHintOverlay({
    super.key,
    required this.hints,
    required this.onDismiss,
  });

  final List<HintItem> hints;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Stack(
        children: [
          // Frosted glass background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(color: Colors.black.withAlpha(120)),
            ),
          ),
          // Hint cards positioned around the screen
          ...hints.map((hint) => _buildHintCard(context, hint)),
          // "Tik om door te gaan" at the bottom
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tik om door te gaan',
                  style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintCard(BuildContext context, HintItem hint) {
    final theme = Theme.of(context);

    // Convert alignment to positioning
    final screenSize = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;

    // Calculate approximate position from alignment
    double top;
    if (hint.alignment.y <= -0.3) {
      top = safeTop + 80 + ((hint.alignment.y + 1) * 80);
    } else if (hint.alignment.y >= 0.3) {
      top = screenSize.height * 0.45 + (hint.alignment.y * 120);
    } else {
      top = screenSize.height * 0.35;
    }

    return Positioned(
      top: top.clamp(safeTop + 20, screenSize.height - 200),
      left: 24,
      right: 24,
      child: _GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(hint.gestureIcon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hint.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint.description,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Pre-defined hints per screen
// ---------------------------------------------------------------------------

const homeHints = [
  HintItem(
    alignment: Alignment(0, -0.3),
    gestureIcon: Icons.touch_app,
    title: 'Tik op een rijvenster',
    description: 'Bekijk weerdetails, plan de rit in of voeg toe aan Google Agenda.',
  ),
  HintItem(
    alignment: Alignment(0, 0.3),
    gestureIcon: Icons.swipe,
    title: 'Filter op dag',
    description: 'Tik op een dag bovenaan om alleen die dag te zien.',
  ),
];

const agendaHints = [
  HintItem(
    alignment: Alignment(0, -0.3),
    gestureIcon: Icons.touch_app,
    title: 'Tik voor weerdetails',
    description: 'Tik op een gekleurd uurvak om temperatuur, regen en wind te bekijken.',
  ),
  HintItem(
    alignment: Alignment(0, 0.4),
    gestureIcon: Icons.swipe_vertical,
    title: 'Sleep om uren te selecteren',
    description: 'Houd een vak ingedrukt en sleep verticaal om meerdere uren te selecteren. '
        'Tik daarna op "Rit inplannen" onderaan.',
  ),
];

const ridesHints = [
  HintItem(
    alignment: Alignment(0, -0.3),
    gestureIcon: Icons.touch_app,
    title: 'Tik voor weersamenvatting',
    description: 'Tik op een rit voor een uitgebreid weeroverzicht per uur, '
        'score-opbouw en windadvies.',
  ),
  HintItem(
    alignment: Alignment(0, 0.4),
    gestureIcon: Icons.swipe_left,
    title: 'Swipe om te verwijderen',
    description: 'Veeg een rit naar links om hem te verwijderen.',
  ),
];
