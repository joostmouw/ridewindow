import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/features/shared/step_controls.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';
import 'package:ridewindow/theme/app_shapes.dart';

const _kTourSeenKey = 'app_tour_seen';

/// Checks if the tour has been shown before.
Future<bool> shouldShowTour() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kTourSeenKey) ?? false);
}

/// Marks the tour as seen.
Future<void> markTourSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kTourSeenKey, true);
}

/// Shows the app tour overlay. Call once after first navigation to /home.
void showAppTour(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => const _AppTourOverlay(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

/// De rondleiding bij de eerste start: vier schermen die zeggen waar wat zit.
///
/// **Waarom dit een kaart is en geen vol scherm met witte tekst.** Het stond
/// er als tekst rechtstreeks op de schermvuller, in `Colors.white` — een van de
/// laatste twee plekken met hardgecodeerde kleuren, en het enige scherm dat
/// nooit door de papier-en-inkt-ronde van fase 23 is gegaan. Het is nu
/// dezelfde Material 3 *rich tooltip* als de spotlight-uitleg per scherm, met
/// dezelfde [StepControls] eronder. Wat je hier leert werkt daar dus ook.
///
/// **Waarom de teksten uit de ARB komen.** Ze stonden hardgecodeerd in het
/// Nederlands, dus een Engelse gebruiker kreeg bij zijn allereerste start vier
/// schermen Nederlands te zien. Dat is precies het verkeerde eerste moment om
/// dat te doen.
class _AppTourOverlay extends StatefulWidget {
  const _AppTourOverlay();

  @override
  State<_AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends State<_AppTourOverlay> {
  final _controller = PageController();
  int _page = 0;

  static const _icons = [
    AppIcons.house,
    AppIcons.calendarDots,
    AppIcons.bicycle,
    AppIcons.user,
  ];

  List<({IconData icon, String title, String body})> _pages(S s) => [
        (icon: _icons[0], title: s.tourHomeTitle, body: s.tourHomeBody),
        (icon: _icons[1], title: s.tourAgendaTitle, body: s.tourAgendaBody),
        (icon: _icons[2], title: s.tourRidesTitle, body: s.tourRidesBody),
        (icon: _icons[3], title: s.tourProfileTitle, body: s.tourProfileBody),
      ];

  void _goTo(int page) => _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

  void _next(int total) => _page < total - 1 ? _goTo(_page + 1) : _close();

  void _back() {
    if (_page > 0) _goTo(_page - 1);
  }

  void _close() {
    markTourSeen();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final pages = _pages(s);

    return Material(
      color: theme.colorScheme.scrim.withAlpha(200),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppShapes.paddingXl),
            child: Material(
              color: theme.colorScheme.surfaceContainer,
              elevation: 2,
              borderRadius: AppShapes.roundedMd,
              child: Padding(
                padding: const EdgeInsets.all(AppShapes.paddingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StepProgress(step: _page, total: pages.length),
                    const SizedBox(height: AppShapes.paddingXl),
                    // Een vaste hoogte, anders springt de kaart bij elke stap
                    // omdat de ene tekst langer is dan de andere -- en dan
                    // verschuift "Volgende" onder je duim vandaan.
                    SizedBox(
                      height: 260,
                      child: PageView(
                        controller: _controller,
                        onPageChanged: (i) => setState(() => _page = i),
                        children: [
                          for (final page in pages)
                            _TourPage(
                              icon: page.icon,
                              title: page.title,
                              body: page.body,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppShapes.paddingLg),
                    StepControls(
                      step: _page,
                      total: pages.length,
                      onBack: _back,
                      onNext: () => _next(pages.length),
                      onSkip: _close,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TourPage extends StatelessWidget {
  const _TourPage({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 34,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppShapes.paddingLg),
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppShapes.paddingSm),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
