import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_colors.dart';
import 'package:ridewindow/theme/app_theme.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/availability_presets.dart';
import 'package:ridewindow/theme/app_icons.dart';

/// Interne data-structuur voor een onboarding preset-optie.
class _PresetOption {
  const _PresetOption({
    required this.preset,
    required this.label,
    required this.sub,
    required this.isDashed,
  });

  final AvailabilityPreset preset;
  final String label;
  final String sub;
  final bool isDashed;
}

/// OnboardingScreen — laat de gebruiker een beschikbaarheidsschema kiezen.
///
/// Toont vier preset-opties. Tapping een optie selecteert hem visueel.
/// Tapping 'Volgende →': seed AvailabilityNotifier, schrijf onboarding_complete=true,
/// navigeer naar /home. Tapping 'Stel mijn eigen schema in': navigeer naar /availability.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  AvailabilityPreset? _selected;

  static List<_PresetOption> _options(BuildContext context) {
    final s = S.of(context);
    return [
      _PresetOption(
        preset: AvailabilityPreset.eveningsAndWeekends,
        label: s.presetEveningsWeekends,
        sub: s.presetEveningsWeekendsSub,
        isDashed: false,
      ),
      _PresetOption(
        preset: AvailabilityPreset.morningsAndWeekends,
        label: s.presetMorningsWeekends,
        sub: s.presetMorningsWeekendsSub,
        isDashed: false,
      ),
      _PresetOption(
        preset: AvailabilityPreset.weekendsOnly,
        label: s.presetWeekendsOnly,
        sub: s.presetWeekendsOnlySub,
        isDashed: false,
      ),
      _PresetOption(
        preset: AvailabilityPreset.custom,
        label: s.presetCustom,
        sub: s.presetCustomSub,
        isDashed: true,
      ),
    ];
  }

  Future<void> _handleNext() async {
    if (_selected == null) return;
    if (_selected == AvailabilityPreset.custom) {
      context.go('/availability?from=onboarding');
      return;
    }
    // Berekening van huidige week-maandag
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    final preset = buildPreset(_selected!, weekStart);
    await ref.read(availabilityProvider.notifier).seedPreset(preset);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final green = context.rw.scorePerfect;
    final greenBg = context.rw.tiers.perfectBg;

    return Scaffold(
      // Expliciet brandLight -- zie de gelijkluidende noot in
      // `welcome_screen.dart`. Dit scherm en Welcome houden hun groene vlak;
      // de rest van de app is sinds v4.0 papier.
      backgroundColor: AppColors.brandLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Terug-knop
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(AppIcons.caretLeft),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => context.go('/welcome'),
                ),
              ),
              const SizedBox(height: 16),
              // Titel
              Text(
                S.of(context).onboardingTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.rw.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitel
              Text(
                S.of(context).onboardingSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  // Niet `rw.textTertiary`: die is in v4.0 lichter gezet voor
                  // de papieren achtergrond en haalt op brandLight nog maar
                  // 3.63:1. Deze waarde haalt 4.55:1 op groen.
                  color: AppColors.brandScreenTextTertiary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
              // Preset-opties
              Expanded(
                child: ListView.separated(
                  itemCount: _options(context).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = _options(context)[index];
                    final isSelected = _selected == option.preset;
                    return _PresetTile(
                      option: option,
                      isSelected: isSelected,
                      green: green,
                      greenBg: greenBg,
                      onTap: () => setState(() => _selected = option.preset),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Volgende-knop
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _handleNext,
                  child: Text(S.of(context).onboardingNext),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individuele preset-tegel widget.
class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.option,
    required this.isSelected,
    required this.green,
    required this.greenBg,
    required this.onTap,
  });

  final _PresetOption option;
  final bool isSelected;
  final Color green;
  final Color greenBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rw = context.rw;
    final borderColor = isSelected ? green : rw.borderLight;
    // Een niet-geselecteerde tegel gaat op in de achtergrond en wordt alleen
    // door zijn rand begrensd -- dat was zo en blijft zo. Daarom brandLight en
    // niet `colorScheme.surface`: die is sinds v4.0 papier, en een witte tegel
    // op een groen scherm is een verandering aan Onboarding die niet gevraagd
    // is. Dit scherm blijft er precies zo uitzien als voorheen.
    final backgroundColor = isSelected ? greenBg : AppColors.brandLight;

    Widget tileContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        // Dashed-optie krijgt geen standaard border — CustomPaint tekent die
        border: option.isDashed
            ? null
            : Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        children: [
          // Cirkel-check indicator
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? green : Colors.transparent,
              border: Border.all(
                color: isSelected ? green : rw.border,
                width: 2,
              ),
            ),
            child: isSelected
                ? Icon(
                    AppIcons.check,
                    size: 13,
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Label + sub
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? green : rw.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  option.sub,
                  style: const TextStyle(
                    fontSize: 12,
                    // Zie de noot bij de subtitel hierboven: `rw.textHint`
                    // zakt op brandLight naar 3.12:1, deze waarde haalt 4.51:1.
                    color: AppColors.brandScreenTextHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Dashed-border wrapper voor de custom optie
    if (option.isDashed) {
      tileContent = CustomPaint(
        painter: _DashedBorderPainter(
          color: borderColor,
          borderRadius: 14,
          strokeWidth: 2,
          dashLength: 6,
          dashGap: 4,
        ),
        child: tileContent,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: tileContent,
    );
  }
}

/// CustomPainter die een gestippelde rand tekent.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
  });

  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final extractedPath = metric.extractPath(
          distance,
          distance + dashLength,
        );
        canvas.drawPath(extractedPath, paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.strokeWidth != strokeWidth;
}

