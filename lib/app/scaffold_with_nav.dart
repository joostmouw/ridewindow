// lib/app/scaffold_with_nav.dart
// Shell widget voor StatefulShellRoute: persistente NavigationBar over Home en Profiel tabs.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';

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
            icon: const Icon(AppIcons.house),
            selectedIcon: const Icon(AppIconsFill.house),
            label: S.of(context).navHome,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.calendarDots),
            selectedIcon: const Icon(AppIconsFill.calendarDots),
            label: S.of(context).navAgenda,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.bicycle),
            selectedIcon: const Icon(AppIconsFill.bicycle),
            label: S.of(context).navRides,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.user),
            selectedIcon: const Icon(AppIconsFill.user),
            label: S.of(context).navProfile,
          ),
        ],
      ),
    );
  }
}
