import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

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
      duration: const Duration(milliseconds: 1200),
    );

    _fadeEmoji = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );
    _fadeTitle = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.5, curve: Curves.easeOut)),
    );
    _fadeSub = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.65, curve: Curves.easeOut)),
    );
    _fadeButton = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.85, curve: Curves.easeOut)),
    );

    const slideUp = Offset(0, 0.15);
    _slideTitle = Tween(begin: slideUp, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.5, curve: Curves.easeOut)),
    );
    _slideSub = Tween(begin: slideUp, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.65, curve: Curves.easeOut)),
    );
    _slideButton = Tween(begin: slideUp, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.85, curve: Curves.easeOut)),
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
      backgroundColor: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      height: 1.15,
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
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
