import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_motion.dart';
import 'package:ridewindow/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeEmoji;
  late final Animation<double> _fadeTitle;
  late final Animation<double> _fadeSub;
  late final Animation<double> _fadeButton;
  late final Animation<Offset> _slideTitle;
  late final Animation<Offset> _slideSub;
  late final Animation<Offset> _slideButton;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Effects springs for fades (smooth, no overshoot)
    _fadeEmoji = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: AppMotion.effectsCurve)),
    );
    _fadeTitle = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.5, curve: AppMotion.effectsCurve)),
    );
    _fadeSub = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.65, curve: AppMotion.effectsCurve)),
    );
    _fadeButton = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.85, curve: AppMotion.effectsCurve)),
    );

    // Spatial springs for slides (bouncy overshoot)
    const slideUp = Offset(0, 0.15);
    _slideTitle = Tween(begin: slideUp, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.5, curve: AppMotion.spatialEmphasizedCurve)),
    );
    _slideSub = Tween(begin: slideUp, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.65, curve: AppMotion.spatialEmphasizedCurve)),
    );
    _slideButton = Tween(begin: slideUp, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.85, curve: AppMotion.spatialEmphasizedCurve)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeTransition(
                opacity: _fadeEmoji,
                child: const Text(
                  '\u{1F6B4}',
                  style: TextStyle(fontSize: 80),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              SlideTransition(
                position: _slideTitle,
                child: FadeTransition(
                  opacity: _fadeTitle,
                  child: Text(
                    S.of(context).welcomeTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SlideTransition(
                position: _slideSub,
                child: FadeTransition(
                  opacity: _fadeSub,
                  child: Text(
                    S.of(context).welcomeSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              SlideTransition(
                position: _slideButton,
                child: FadeTransition(
                  opacity: _fadeButton,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.push('/onboard'),
                      child: Text(S.of(context).welcomeButton),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
