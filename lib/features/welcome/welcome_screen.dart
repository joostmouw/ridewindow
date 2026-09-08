import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_colors.dart';
import 'package:ridewindow/theme/app_motion.dart';

/// Het eerste scherm: het RW-monogram tekent zichzelf, wordt een fiets, en de
/// renner stapt op. Daarna schuift het geheel omhoog en maakt plaats.
///
/// **Waarom een geanimeerde WebP en geen video.** `video_player` is een
/// afhankelijkheid met platformcode, een audiospoor dat we niet gebruiken, en
/// autoplay-regels op het web. Een geanimeerde WebP speelt Flutter zelf af via
/// `Image.asset` — nul afhankelijkheden, werkt op Android en op het web, en het
/// bestand is met 450 kB kleiner dan de mp4. Het is gecodeerd met `loop: 1`,
/// dus hij speelt één keer en blijft op het laatste beeld staan; precies wat
/// een intro moet doen.
///
/// **Waarom de kleuren exact de merkkleuren zijn.** De bron had een licht
/// ruisende achtergrond (193–197 per kanaal). Op een vlakke `brandLight` zie je
/// dan de rand van het plaatje staan. Elke frame is daarom door een
/// luminantietabel gehaald die papier op `brandLight` zet en inkt op
/// `brandDark`. Het beeld valt nu weg in de achtergrond van dit scherm.
///
/// **Waarom de twee bewegingen overlappen.** Wachten tot de animatie klaar is
/// en dán pas verschuiven leest als twee losse gebeurtenissen. De verschuiving
/// begint daarom terwijl de laatste seconde nog speelt, en tekst en knop komen
/// omhoog mee. Dat leest als één beweging.
///
/// **Eenmalig.** Dit scherm hangt aan de redirect op `onboarding_complete` in
/// `router.dart`; wie die stap heeft gedaan ziet het nooit meer. Tikken slaat
/// het wachten over — een intro die je niet kunt overslaan is geen intro maar
/// een drempel.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  /// Wanneer het verschuiven begint. `welcome_ride.webp` duurt 8,55 s (103
  /// frames van 83 ms), dus dit valt er ruim binnen: het laatste anderhalve
  /// seconde van de rit beweegt mee in plaats van dat de app erop wacht.
  static const _settleAt = Duration(milliseconds: 6800);

  late final AnimationController _settle;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _timer = Timer(_settleAt, _startSettle);
  }

  void _startSettle() {
    _timer?.cancel();
    if (mounted && !_settle.isAnimating && _settle.value == 0) {
      _settle.forward();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    // De rit krimpt van bijna schermbreed naar iets meer dan de helft, en
    // schuift van het midden naar boven. Eén curve voor allebei, anders lopen
    // ze uit de pas en ziet het er hakkelig uit.
    final curve = CurvedAnimation(
      parent: _settle,
      curve: AppMotion.spatialEmphasizedCurve,
    );
    final scale = Tween(begin: 1.0, end: 0.62).animate(curve);
    final align = AlignmentTween(
      begin: Alignment.center,
      end: const Alignment(0, -0.58),
    ).animate(curve);
    final fadeIn = CurvedAnimation(
      parent: _settle,
      // De tekst komt pas los als de rit al onderweg is; tegelijk starten
      // maakt het scherm druk.
      curve: const Interval(0.35, 1.0, curve: AppMotion.effectsCurve),
    );
    final slideIn = Tween(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(fadeIn);

    return Scaffold(
      // Expliciet brandLight, niet `colorScheme.surface`. Sinds v4.0 is surface
      // papier (zie de noot bij `AppColors.brandLight`), maar op dit scherm en
      // op Onboarding is een groot groen vlak juist een merkmoment in plaats
      // van behang -- je ziet het één keer en het zet de toon. Keuze van Joost,
      // 2026-09-07. Deze twee schermen erven de achtergrond dus niet meer.
      backgroundColor: AppColors.brandLight,
      body: GestureDetector(
        // Tikken slaat het wachten over.
        onTap: _startSettle,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _settle,
            builder: (context, _) {
              return Stack(
                children: [
                  Align(
                    alignment: align.value,
                    child: Transform.scale(
                      scale: scale.value,
                      child: Image.asset(
                        'assets/animations/welcome_ride.webp',
                        width: math.min(
                          MediaQuery.sizeOf(context).width * 0.92,
                          460,
                        ),
                        fit: BoxFit.contain,
                        // De laatste frame blijft staan; zonder dit knippert
                        // hij bij een herbouw even naar leeg.
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 32,
                    right: 32,
                    bottom: 56,
                    child: FadeTransition(
                      opacity: fadeIn,
                      child: SlideTransition(
                        position: slideIn,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              s.welcomeTitle,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              s.welcomeSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            FilledButton(
                              onPressed: () => context.push('/onboard'),
                              child: Text(s.welcomeButton),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
