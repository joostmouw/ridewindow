// lib/app/scaffold_with_nav.dart
// Shell widget voor StatefulShellRoute: persistente NavigationBar (telefoon)
// of NavigationRail (vanaf medium, quick-plan 261011-jru) over de vier tabs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridewindow/app/window_size.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/ride_entries_provider.dart';
import 'package:ridewindow/theme/app_icons.dart';

class ScaffoldWithNav extends ConsumerWidget {
  const ScaffoldWithNav({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attention = ref.watch(pelotonAttentionCountProvider);

    // Terug vanuit Agenda, Ritten of Profiel gaat eerst naar Home, pas daar
    // sluit terug de app (#80) -- het gewone Android-gedrag bij een onderbalk.
    // Geen "nog eens drukken om af te sluiten" op Home: dat breekt het
    // voorspellende terug-gebaar van Android 13+.
    //
    // Deze PopScope alleen is niet genoeg, zie [BackToHome]. Hij blijft nodig
    // voor de melding aan Android na een tabwissel en na het sluiten van een
    // scherm boven de shell (ritdetail, groep): dan meldt de hoofdnavigator.
    final onHome = navigationShell.currentIndex == 0;
    final s = S.of(context);

    // Eén lijst voor onderbalk én rail, zodat iconen, labels en het bolletje
    // nooit uiteen kunnen lopen (quick-plan 261011-jru).
    final destinations = <({Widget icon, Widget selectedIcon, String label})>[
      (
        icon: const Icon(AppIcons.house),
        selectedIcon: const Icon(AppIconsFill.house),
        label: s.navHome,
      ),
      (
        icon: const Icon(AppIcons.calendarDots),
        selectedIcon: const Icon(AppIconsFill.calendarDots),
        label: s.navAgenda,
      ),
      (
        icon: _AttentionBadge(
          count: attention,
          child: const Icon(AppIcons.bicycle),
        ),
        selectedIcon: _AttentionBadge(
          count: attention,
          child: const Icon(AppIconsFill.bicycle),
        ),
        label: s.navRides,
      ),
      (
        icon: const Icon(AppIcons.user),
        selectedIcon: const Icon(AppIconsFill.user),
        label: s.navProfile,
      ),
    ];

    void onSelect(int i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        );

    // Telefoon: de onderbalk. Vanaf medium (600 dp) een rail links, zoals
    // YouTube en Google Play op een tablet doen.
    final Widget scaffold;
    if (windowSizeClassOf(context) == WindowSizeClass.compact) {
      scaffold = Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: onSelect,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: d.label,
              ),
          ],
        ),
      );
    } else {
      scaffold = Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: onSelect,
                labelType: NavigationRailLabelType.all,
                // Verticaal gecentreerd (backlog #93, plan 261011-kb9 "Hoe
                // goedlopende apps het doen"): een tablet hou je met twee
                // handen vast en dan liggen de duimen halverwege de zijkant.
                // Midden werkt in portret én liggend; onderaan zou botsen met
                // de gebarenbalk van Android en ligt liggend onder de duim.
                groupAlignment: 0.0,
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return PopScope(
      canPop: onHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: scaffold,
    );
  }
}

/// Het rode bolletje met wat er in Peloton op je wacht (CLUB-25, schets 016
/// vraag 1 A): ritantwoorden, groepsaanvragen en nieuwe maatjes.
///
/// **Onderbalk en de tab Peloton lezen allebei [pelotonAttentionCountProvider]**
/// en tonen het getal met [unansweredBadgeLabel], zodat ze nooit iets anders
/// zeggen. Bij 0 is er geen bolletje: een leeg rood rondje zou "er is iets"
/// zeggen terwijl er niets is.
///
/// Geen eigen kleuren: de M3-standaard is `colorScheme.error` met `onError`,
/// in licht en donker uit het thema.
class _AttentionBadge extends StatelessWidget {
  const _AttentionBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Semantics(
      label: S.of(context).navPelotonAttention(count),
      child: ExcludeSemantics(
        child: Badge(label: Text(unansweredBadgeLabel(count)), child: child),
      ),
    );
  }
}

/// Het getal in het bolletje: boven 9 wordt het "9+", zodat het bolletje
/// klein blijft. Gedeeld met de tab Peloton in Mijn Ritten.
String unansweredBadgeLabel(int count) => count > 9 ? '9+' : '$count';

/// Zet om een tab die niet Home is: terug gaat dan naar Home (#80).
///
/// **Waarom dit naast de PopScope op de shell staat.** Met voorspellend terug
/// (standaard vanaf targetSdk 36) vraagt Android vóóraf of Flutter terug zelf
/// afhandelt. Dat antwoord komt uit `NavigationNotification`s, en elke tab
/// heeft een eigen navigator. Opent een tab voor het eerst, dan meldt die
/// navigator "ik kan niet terug", de hoofdnavigator geeft dat ongewijzigd door
/// (hij kan zelf ook niet terug), en die melding overschrijft die van de
/// shell. Android sloot de app dan zonder Flutter iets te vragen -- zo stond
/// het in build 56. Met een PopScope *binnen* de tabnavigator meldt die
/// navigator zelf "ik handel het af".
class BackToHome extends StatelessWidget {
  const BackToHome({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: child,
    );
  }
}
