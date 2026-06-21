// lib/theme/app_motion.dart
// M3 Expressive motion system: spring-based curves and animation helpers.

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

// ---------------------------------------------------------------------------
// Spring Curves
// ---------------------------------------------------------------------------

/// A [Curve] driven by a critically/under-damped spring simulation.
/// M3 Expressive defines two spring families:
///   - **Spatial** (position/scale): slight overshoot, bouncy settle
///   - **Effects** (opacity/color): smooth, no overshoot
class SpringCurve extends Curve {
  const SpringCurve({
    required this.mass,
    required this.stiffness,
    required this.damping,
  });

  final double mass;
  final double stiffness;
  final double damping;

  @override
  double transformInternal(double t) {
    final spring = SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );
    // Simulate from 0 → 1 with initial velocity 0.
    final sim = SpringSimulation(spring, 0.0, 1.0, 0.0);
    return sim.x(t);
  }
}

// ---------------------------------------------------------------------------
// Motion tokens — use these throughout the app
// ---------------------------------------------------------------------------

class AppMotion {
  AppMotion._();

  // -- Spatial springs: for position, scale, size changes ----------------
  // Slight overshoot gives that alive, bouncy M3 Expressive feel.

  /// Standard spatial spring — card taps, list entrances, chip selections.
  static const spatialCurve = SpringCurve(
    mass: 1.0,
    stiffness: 400.0,
    damping: 22.0,
  );

  /// Emphasized spatial spring — page transitions, hero moments.
  static const spatialEmphasizedCurve = SpringCurve(
    mass: 1.0,
    stiffness: 300.0,
    damping: 20.0,
  );

  // -- Effects springs: for opacity, color, blur changes -----------------
  // No overshoot — smooth and settling.

  /// Standard effects spring — fades, color transitions.
  static const effectsCurve = SpringCurve(
    mass: 1.0,
    stiffness: 800.0,
    damping: 40.0,
  );

  // -- Durations ---------------------------------------------------------
  // Springs are time-independent, but AnimatedContainer/TweenAnimationBuilder
  // need a duration. These are generous enough for the spring to settle.

  /// Duration for spatial spring animations (position, scale).
  static const spatialDuration = Duration(milliseconds: 500);

  /// Duration for emphasized spatial springs (page transitions).
  static const spatialEmphasizedDuration = Duration(milliseconds: 600);

  /// Duration for effects spring animations (opacity, color).
  static const effectsDuration = Duration(milliseconds: 350);

  /// Short micro-interaction (press feedback).
  static const microDuration = Duration(milliseconds: 150);

  // -- Stagger delay -----------------------------------------------------

  /// Delay between staggered list items.
  static const staggerDelay = Duration(milliseconds: 50);

  /// Max items to stagger (avoid long waits on big lists).
  static const maxStaggerItems = 8;
}

// ---------------------------------------------------------------------------
// Reusable animated wrappers
// ---------------------------------------------------------------------------

/// A widget that scales down on press and springs back — M3 Expressive
/// press feedback for cards and tappable surfaces.
///
/// If [onTap] is null, the widget is a passive visual wrapper that reacts
/// to pointer down/up without intercepting the tap (child InkWell still works).
class SpringPressEffect extends StatefulWidget {
  const SpringPressEffect({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// How much to scale down on press (1.0 = no effect, 0.95 = 5% shrink).
  final double scaleFactor;

  @override
  State<SpringPressEffect> createState() => _SpringPressEffectState();
}

class _SpringPressEffectState extends State<SpringPressEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.spatialDuration,
    );
    _scale = Tween(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.spatialCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent _) {
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent _) {
    _controller.reverse();
  }

  void _onPointerCancel(PointerCancelEvent _) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.translucent,
      child: ScaleTransition(
        scale: _scale,
        child: widget.onTap != null
            ? GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: widget.child,
              )
            : widget.child,
      ),
    );
  }
}

/// A widget that fades + scales in with a spring, optionally delayed
/// for stagger effects in lists.
class SpringEntrance extends StatefulWidget {
  const SpringEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<SpringEntrance> createState() => _SpringEntranceState();
}

class _SpringEntranceState extends State<SpringEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.spatialDuration,
    );
    _scale = Tween(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.spatialCurve),
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.effectsCurve),
    );
    _slide = Tween(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.spatialCurve),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}
