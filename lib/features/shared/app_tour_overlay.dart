import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _AppTourOverlay extends StatefulWidget {
  const _AppTourOverlay();

  @override
  State<_AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends State<_AppTourOverlay> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _TourPage(
      icon: Icons.home,
      title: 'Rijvensters',
      body: 'Op het Home scherm zie je de beste momenten om te fietsen deze week. '
          'Elke kaart toont de score, het tijdstip en het weer. '
          'Tik op een kaart voor meer details.',
    ),
    _TourPage(
      icon: Icons.calendar_view_week,
      title: 'Agenda',
      body: 'De Agenda toont 7 dagen met uurvakken — groen is goed, rood is slecht. '
          'Tik op een vak voor weerdetails. '
          'Houd ingedrukt en sleep verticaal om meerdere uren te selecteren voor een rit.',
    ),
    _TourPage(
      icon: Icons.directions_bike,
      title: 'Mijn Ritten',
      body: 'Plan een rit vanuit Home of de Agenda. '
          'In Mijn Ritten volg je of het weer nog steeds goed is. '
          'De windrichting-tip helpt je de route te kiezen: eerst tegenwind, dan meewind terug.',
    ),
    _TourPage(
      icon: Icons.person,
      title: 'Profiel',
      body: 'Stel je locatie in, kies je weertoleranties (temperatuur, regen, wind) '
          'en beheer je beschikbaarheid. '
          'De app berekent je scores op basis van jouw voorkeuren.',
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _close();
    }
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
    final theme = Theme.of(context);

    return Material(
      color: Colors.black.withAlpha(200),
      child: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _close,
                child: Text('Overslaan', style: TextStyle(color: Colors.white.withAlpha(180))),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: _pages,
              ),
            ),
            // Dots + next button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // Page dots
                  for (var i = 0; i < _pages.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page ? theme.colorScheme.primary : Colors.white.withAlpha(100),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_page < _pages.length - 1 ? 'Volgende' : 'Aan de slag'),
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

class _TourPage extends StatelessWidget {
  const _TourPage({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withAlpha(220),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
