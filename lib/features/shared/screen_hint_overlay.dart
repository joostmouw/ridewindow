import 'package:flutter/material.dart';
import 'package:ridewindow/features/shared/step_controls.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_shapes.dart';
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

    // De doelmaten zijn pas te lezen als de laag eronder gelegd is. Wordt deze
    // overlay in dezelfde frame gebouwd als zijn doel -- wat in tests gebeurt
    // en op een traag toestel kan -- dan meet de eerste `build` niets. Eén
    // rebuild na die frame lost dat op.
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealTarget());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < widget.hints.length - 1) {
      _goTo(_currentStep + 1);
    } else {
      widget.onDismiss();
    }
  }

  void _back() {
    if (_currentStep > 0) _goTo(_currentStep - 1);
  }

  /// Uit- en weer infaden tussen twee stappen. Zonder die tussenstap springt
  /// de uitsnede van het ene element naar het andere en verlies je het spoor.
  void _goTo(int step) {
    _animController.reverse().then((_) async {
      if (!mounted) return;
      setState(() => _currentStep = step);
      await _revealTarget();
      if (mounted) _animController.forward();
    });
  }

  /// Scrollt het doel in beeld voordat de spotlight erop valt, en meet daarna
  /// opnieuw.
  ///
  /// **Waarom dit nodig is.** De uitleg over de rijvensters op Home wees naar
  /// een kaart die onder de vouw hing: de uitsnede viel half buiten beeld en
  /// de kaart met de tekst kwam er bovenop te liggen. Je las dan uitleg over
  /// iets wat je niet zag (Joost, 2026-09-08). Alleen de tekst verplaatsen
  /// lost dat niet op -- het dóél moet in beeld.
  ///
  /// `alignment: 0.25` zet het doel in de bovenste kwart van het scherm. Daar
  /// is eronder ruimte voor de kaart, wat de rustigste plaatsing is: de
  /// uitleg staat dan altijd op dezelfde plek in plaats van te wisselen
  /// tussen boven en onder het doel.
  ///
  /// **Grens.** Dit werkt alleen als het doel al gebouwd is. Hangt het in een
  /// lui opgebouwde lijst zó ver naar beneden dat Flutter het nog niet heeft
  /// aangemaakt, dan is `currentContext` null en valt er niets aan te wijzen —
  /// dan gebeurt er niets in plaats van iets verkeerds. Voor de hints die de
  /// app vandaag heeft is dat geen beperking; die staan alle zes in het eerste
  /// of tweede schermbeeld. Wijst een nieuwe hint ooit naar iets diep in een
  /// lijst, dan is index-gebaseerd scrollen nodig en niet dit.
  Future<void> _revealTarget() async {
    final context = widget.hints[_currentStep].targetKey.currentContext;
    if (context != null && Scrollable.maybeOf(context) != null) {
      await Scrollable.ensureVisible(
        context,
        alignment: 0.25,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    // Ook zonder scrollen opnieuw meten: het doel kan pas ná deze frame
    // gelegd zijn.
    if (mounted) setState(() {});
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

    // Was `onTap: _next`. Elke tik op het scherm sprong daarmee vooruit, ook
    // een tik waarmee je alleen wilde lezen -- en een gemiste zin was weg,
    // want terug kon niet. Nu vangt dit gebaar de tik alleen nog af zodat de
    // app eronder niet reageert; vooruit en terug gaan via de knoppen.
    return GestureDetector(
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
            // De kaart hoort bij het doel, maar hij verschijnt óók als dat
            // doel niet te meten is. Dat was vroeger niet nodig: toen sprong
            // elke tik op het scherm vooruit, dus een lege overlay was altijd
            // weg te tikken. Sinds alleen de knoppen nog iets doen (2026-09-08)
            // zou een niet-gemeten doel je opsluiten in een donker scherm.
            _buildTooltip(context, hint, targetRect, isLast, s),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(
    BuildContext context,
    HintItem hint,
    Rect? rect,
    bool isLast,
    S s,
  ) {
    final screenSize = MediaQuery.of(context).size;
    // Geen doel: zet de kaart in het midden en teken geen pijltje. Alles
    // hieronder rekent met een rechthoek, dus dat wordt het scherm zelf --
    // waarmee `targetCoversScreen` vanzelf waar is en de kaart centreert.
    final targetRect = rect ?? Offset.zero & screenSize;
    final hasTarget = rect != null;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final targetCenter = targetRect.center;

    // Large targets (>40% of screen): center tooltip on screen instead of
    // anchoring to an edge that may push it off-screen.
    final targetCoversScreen = targetRect.height > screenSize.height * 0.4;

    // Decide if tooltip goes above or below the target
    final showBelow = targetCoversScreen || targetCenter.dy < screenSize.height * 0.45;

    // Clamp positions so tooltip stays within safe area
    final minTop = safeTop + 8;
    final maxBottom = safeBottom + 80; // room for step dots

    double? tooltipTop;
    double? tooltipBottom;

    if (targetCoversScreen) {
      // Place tooltip in the vertical center of the screen
      tooltipTop = screenSize.height * 0.38;
    } else if (showBelow) {
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
          // Arrow pointing to target (hide for large targets)
          if (hasTarget && showBelow && !targetCoversScreen)
            Padding(
              padding: EdgeInsets.only(
                left: (targetCenter.dx - 20).clamp(16, screenSize.width - 56),
              ),
              child: CustomPaint(
                size: const Size(16, 8),
                painter: _ArrowPainter(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  pointUp: true,
                ),
              ),
            ),
          // De kaart is een Material 3 *rich tooltip*: MD3 kent geen
          // rondleiding-component, maar wel deze -- een oppervlak met titel,
          // uitleg en tekstknoppen. Joost koos hem op 2026-09-08 boven een
          // eigen papieren kaart met streepjes.
          //
          // Vandaar deze maten en niet die van een ritkaart: `surfaceContainer`
          // in plaats van papier, hoek 12 (`radiusMd`) in plaats van 20, en
          // schaduwniveau 2. Was `Colors.white.withAlpha(30)` -- een doorzichtig
          // glasvlak dat nergens anders in de app voorkwam en dat als enige
          // scherm nooit door de papier-en-inkt-ronde van fase 23 is gegaan.
          Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            elevation: 2,
            borderRadius: AppShapes.roundedMd,
            child: Padding(
              padding: const EdgeInsets.all(AppShapes.paddingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StepProgress(
                    step: _currentStep,
                    total: widget.hints.length,
                  ),
                  const SizedBox(height: AppShapes.paddingLg),
                  Row(
                    children: [
                      Icon(
                        hint.gestureIcon,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppShapes.paddingMd),
                      Expanded(
                        child: Text(
                          hint.title,
                          // Title Small, wat MD3 voor de kop van een rich
                          // tooltip voorschrijft -- niet titleMedium.
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppShapes.paddingSm),
                  Text(
                    hint.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppShapes.paddingLg),
                  StepControls(
                    step: _currentStep,
                    total: widget.hints.length,
                    onBack: _back,
                    onNext: _next,
                    onSkip: widget.onDismiss,
                  ),
                ],
              ),
            ),
          ),
          // Arrow pointing up (when tooltip is above target)
          if (hasTarget && !showBelow)
            Padding(
              padding: EdgeInsets.only(
                left: (targetCenter.dx - 20).clamp(16, screenSize.width - 56),
              ),
              child: CustomPaint(
                size: const Size(16, 8),
                painter: _ArrowPainter(
                  color: Theme.of(context).colorScheme.surfaceContainer,
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
