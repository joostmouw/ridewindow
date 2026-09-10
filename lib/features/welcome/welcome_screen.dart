import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
/// **Waarom het bestand 1:1 met de bron is.** 756×512 is precies de uitsnede
/// uit het origineel van 1280×720; er wordt niets verkleind, want elke
/// verkleining kost scherpte die je in het monogram als eerste ziet. Scherper
/// dan dit kan niet — het zit niet in de bron.
///
/// **Waarom hij op 3,5× staat en niet op de snelheid van de bron.** Joost,
/// 2026-09-08, na de vier tempo's naast elkaar te hebben gezien: op ware
/// snelheid duurt de intro 8,65 s en dat is lang voor iets dat je één keer
/// ziet en daarna nooit meer. Eerst werd dat 1,75×; op 2026-09-10 vond hij
/// ook dat nog te lang voor een nieuwe tester, en ging het nog eens 2× sneller.
/// De frames zijn dezelfde gebleven — alleen de
/// framelengte in de ANMF-chunks is van 42 ms naar 12 ms gepatcht met
/// `tool/webp_speed.py`, dus er is niets hercodeerd en het bestand is nog
/// exact even groot. Wil je een ander tempo, draai dan dat script opnieuw op
/// de bron en pas `_settleAt` hieronder aan.
///
/// **Hoe de tekst is weggehaald.** De fiets loopt tijdens de morph door tot
/// y 579 in de bron, dus wegsnijden onder de tekst kost je de wielen. Maar de
/// tekst verschijnt pas na 6,7 s, en dán is de fiets al opgetrokken tot y 461.
/// Vanaf dat frame ligt er een vlak in `brandLight` over alles onder y 508 —
/// de tekst verdwijnt zonder dat de fiets ooit wordt aangeraakt.
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
  /// Wanneer het verschuiven begint. `welcome_ride.webp` duurt 2,47 s (206
  /// frames van 12 ms) en het verschuiven zelf 1,5 s, dus ze eindigen samen:
  /// de rit rijdt zijn laatste seconde uit terwijl hij al omhoog gaat.
  ///
  /// **Dit getal is afgeleid, niet gekozen.** Het is de duur van de animatie
  /// min de 1,5 s hieronder. Verandert het tempo van de WebP, dan verandert
  /// dit mee — anders staat het scherm stil terwijl de rit al klaar is, of
  /// schuift hij weg terwijl de renner nog fietst.
  static const _settleAt = Duration(milliseconds: 972);

  late final AnimationController _settle;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(
      vsync: this,
      // Rustig. Op 900 ms schoot de renner het scherm in; over deze afstand
      // leest alles onder de anderhalve seconde als een sprong — dus precies
      // die, sinds de intro zelf 2,47 s duurt.
      duration: const Duration(milliseconds: 1500),
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Het decoderen niet laten concurreren met de eerste opbouw van het
    // scherm: dat is bij een animatie van 206 frames het verschil tussen
    // vloeiend beginnen en de eerste halve seconde overslaan.
    precacheImage(
      const AssetImage('assets/animations/welcome_ride.webp'),
      context,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _settle.dispose();
    super.dispose();
  }

  /// "Ik heb al een account": sla de onboarding over en land op Profiel, waar
  /// inloggen zit.
  ///
  /// **Waarom hier geen eigen inlogknop staat.** De Google-stroom in
  /// `account_section.dart` regelt initialisatie, de nonce, het uitwisselen van
  /// het id-token bij Supabase en alle foutpaden — en die stroom heeft in dit
  /// project al twee keer een subtiele bug gehad (zie `260726-o3m`). Een tweede
  /// exemplaar op dit scherm zou die geschiedenis verdubbelen. De link brengt
  /// je naar de plek waar het werkt.
  ///
  /// **Waarom de onboarding-vlag hier al omgaat.** Wie een account heeft, heeft
  /// die stap ooit gedaan; zijn beschikbaarheid en voorkeuren komen bij het
  /// inloggen uit Supabase terug. Hem opnieuw door de onboarding sturen is
  /// precies het huiswerk dat deze epic wil afschaffen. Haakt hij af zonder in
  /// te loggen, dan staat hij in de app met de standaardinstellingen — dezelfde
  /// staat als een nieuwe gebruiker ná onboarding, en vanuit Profiel alsnog aan
  /// te passen.
  Future<void> _goToSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    // De rit krimpt van bijna schermbreed naar iets meer dan de helft, en
    // schuift van het midden naar boven. Eén curve voor allebei, anders lopen
    // ze uit de pas en ziet het er hakkelig uit.
    // Bewust géén SpringCurve hier. De veren in `app_motion.dart` schieten
    // door en veren terug; op een verplaatsing van een half scherm leest dat
    // als een schok in plaats van als een beweging. Een symmetrische cubic
    // vertrekt traag en komt traag aan, en dat is precies wat dit moment wil.
    final curve = CurvedAnimation(
      parent: _settle,
      curve: Curves.easeInOutCubic,
    );
    final scale = Tween(begin: 1.0, end: 0.62).animate(curve);
    final align = AlignmentTween(
      begin: Alignment.center,
      end: const Alignment(0, -0.58),
    ).animate(curve);
    // De tekst komt pas los als de rit al onderweg is; tegelijk starten maakt
    // het scherm druk. De verplaatsing loopt daarna door tot het eind.
    final appear = CurvedAnimation(
      parent: _settle,
      curve: const Interval(0.35, 1.0, curve: AppMotion.effectsCurve),
    );
    final slideIn = Tween(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(appear);

    // **De dekking loopt bewust niet mee met de verplaatsing.** Dat deed hij
    // wel, en dan stond het tekstblok 1170 ms lang halfzichtbaar op zijn plek
    // te wachten. Een tester fotografeerde precies dat moment en meldde "font
    // is lastig te lezen met kleuren" (2026-09-08) -- terwijl de kleuren goed
    // zijn: de titel haalt 9,63:1 op `brandLight` en de subtitel 5,54:1,
    // allebei ruim boven de AA-drempel van 4,5. Het was geen kleurprobleem
    // maar een moment waarin je oog begint te lezen en faalt.
    //
    // Tekst hoort er niet te zijn, of leesbaar te zijn -- nooit iets
    // ertussenin. Vandaar 0.35 tot 0.46: ruwweg 200 ms van de 1800 ms, en
    // daarna trekt alleen de bewéging nog het oog. Joost koos dit op een
    // specimen met de drie varianten naast elkaar.
    //
    // `Curves.easeOut` en niet de veer hierboven: die is onderdempt
    // (dempingsverhouding 0,71) en schiet dus door voorbij 1,0. Voor een
    // verplaatsing is dat precies de bedoeling, voor een dekking is het een
    // waarde die niet bestaat.
    final fadeIn = CurvedAnimation(
      parent: _settle,
      curve: const Interval(0.35, 0.46, curve: Curves.easeOut),
    );

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
                      child: RepaintBoundary(
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
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: _goToSignIn,
                              child: Text(s.welcomeHaveAccount),
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
