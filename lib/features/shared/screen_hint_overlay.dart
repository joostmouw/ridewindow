import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-screen spotlight coach marks.
/// Shows hints one at a time with a spotlight cutout around the target element.

const _kPrefix = 'hint_seen_';

Future<bool> shouldShowHint(String screenKey) async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool('$_kPrefix$screenKey') ?? false);
}

Future<void> markHintSeen(String screenKey) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('$_kPrefix$screenKey', true);
}

/// A single hint targeting a specific UI element via GlobalKey.
class HintItem {
  final GlobalKey targetKey;
  final IconData gestureIcon;
  final String title;
  final String description;
  /// Extra padding around the spotlight cutout.
  final double spotlightPadding;

  const HintItem({
    required this.targetKey,
    required this.gestureIcon,
    required this.title,
    required this.description,
    this.spotlightPadding = 8,
  });
}

/// Spotlight coach mark overlay. Shows one hint at a time with a
/// circular/rounded spotlight cutout around the target widget.
class ScreenHintOverlay extends StatefulWidget {
  const ScreenHintOverlay({
    super.key,
    required this.hints,
    required this.onDismiss,
  });

  final List<HintItem> hints;
  final VoidCallback onDismiss;

  @override
  State<ScreenHintOverlay> createState() => _ScreenHintOverlayState();
}

class _ScreenHintOverlayState extends State<ScreenHintOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < widget.hints.length - 1) {
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() => _currentStep++);
          _animController.forward();
        }
      });
    } else {
      widget.onDismiss();
    }
  }

  /// Get the bounding rect of the target widget in global coordinates.
  Rect? _getTargetRect(HintItem hint) {
    final renderBox =
        hint.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      offset.dx - hint.spotlightPadding,
      offset.dy - hint.spotlightPadding,
      renderBox.size.width + hint.spotlightPadding * 2,
      renderBox.size.height + hint.spotlightPadding * 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.hints[_currentStep];
    final isLast = _currentStep == widget.hints.length - 1;
    final s = S.of(context);
    final targetRect = _getTargetRect(hint);

    return GestureDetector(
      onTap: _next,
      behavior: HitTestBehavior.opaque,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Dark overlay with spotlight cutout
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  targetRect: targetRect,
                  overlayColor:
                      Theme.of(context).colorScheme.scrim.withAlpha(180),
                ),
              ),
            ),
            // Tooltip card positioned near the target
            if (targetRect != null)
              _buildTooltip(context, hint, targetRect, isLast, s),
            // Step indicator at bottom
            Positioned(
              bottom: 48,
              left: 24,
              right: 24,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.hints.length; i++)
                      Container(
                        width: i == _currentStep ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _currentStep
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withAlpha(80),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(
    BuildContext context,
    HintItem hint,
    Rect targetRect,
    bool isLast,
    S s,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final targetCenter = targetRect.center;

    // Decide if tooltip goes above or below the target
    final showBelow = targetCenter.dy < screenSize.height * 0.45;

    // Clamp positions so tooltip stays within safe area
    final minTop = safeTop + 8;
    final maxBottom = safeBottom + 80; // room for step dots

    double? tooltipTop;
    double? tooltipBottom;

    if (showBelow) {
      tooltipTop = (targetRect.bottom + 16).clamp(minTop, screenSize.height * 0.65);
    } else {
      tooltipBottom = (screenSize.height - targetRect.top + 16).clamp(maxBottom, screenSize.height * 0.65);
    }

    return Positioned(
      top: tooltipTop,
      bottom: tooltipBottom,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arrow pointing to target
          if (showBelow)
            Padding(
              padding: EdgeInsets.only(
                left: (targetCenter.dx - 20).clamp(16, screenSize.width - 56),
              ),
              child: CustomPaint(
                size: const Size(16, 8),
                painter: _ArrowPainter(
                  color: Colors.white.withAlpha(30),
                  pointUp: true,
                ),
              ),
            ),
          // Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(50)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(60),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(hint.gestureIcon,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hint.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hint.description,
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLast ? s.hintDismiss : s.hintNext,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Arrow pointing up (when tooltip is above target)
          if (!showBelow)
            Padding(
              padding: EdgeInsets.only(
                left: (targetCenter.dx - 20).clamp(16, screenSize.width - 56),
              ),
              child: CustomPaint(
                size: const Size(16, 8),
                painter: _ArrowPainter(
                  color: Colors.white.withAlpha(30),
                  pointUp: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints a dark overlay with a rounded-rect cutout (spotlight) around the target.
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;

  _SpotlightPainter({required this.targetRect, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (targetRect == null) {
      canvas.drawRect(fullRect, paint);
      return;
    }

    // Draw overlay with a rounded-rect hole
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(targetRect!, const Radius.circular(12)));
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Subtle glow around the cutout
    final glowPaint = Paint()
      ..color = Colors.white.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect!, const Radius.circular(12)),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.targetRect != targetRect;
}

/// Small triangle arrow for the tooltip.
class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pointUp;

  _ArrowPainter({required this.color, required this.pointUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => false;
}
