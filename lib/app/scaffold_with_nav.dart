// lib/app/scaffold_with_nav.dart
// Shell widget voor StatefulShellRoute: persistente NavigationBar over Home en Profiel tabs.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: S.of(context).navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_view_week_outlined),
            selectedIcon: const Icon(Icons.calendar_view_week),
            label: S.of(context).navAgenda,
          ),
          NavigationDestination(
            icon: const Icon(Icons.directions_bike_outlined),
            selectedIcon: const Icon(Icons.directions_bike),
            label: S.of(context).navRides,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: S.of(context).navProfile,
          ),
        ],
      ),
    );
  }
}
