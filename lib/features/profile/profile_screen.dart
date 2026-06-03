// lib/features/profile/profile_screen.dart
// ProfileScreen: Wave 1 skeleton — AppBar 'Profiel' + vier secties.
// Wave 2 vult de slider-, chip- en thema-widgets in.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ridewindow/providers/profile_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Lokale state voor live slider-waarden (vóór onChangeEnd persistentie).
  // ignore: unused_field — Wave 2 vult de sliders in.
  late double _tempMin;
  // ignore: unused_field
  late double _tempMax;
  // ignore: unused_field
  late double _rainMax;
  // ignore: unused_field
  late double _windMax;

  @override
  void initState() {
    super.initState();
    // Initialiseer uit profileProvider snapshot (synchrone read na eerste load).
    final profile = ref.read(profileProvider).value;
    _tempMin = profile?.tolerances.tempMinIdealC ?? 12.0;
    _tempMax = profile?.tolerances.tempMaxIdealC ?? 26.0;
    _rainMax = profile?.tolerances.rainMaxIdealMm ?? 0.5;
    _windMax = profile?.tolerances.windMaxIdealKmh ?? 15.0;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profiel')),
      body: ListView(
        children: [
          // Sectie: THEMA (ingevuld in Wave 2)
          const _SectionHeader('THEMA'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Thema-instelling komt in Wave 2.'),
          ),

          // Sectie: TOLERANTIES (ingevuld in Wave 2)
          const _SectionHeader('TOLERANTIES'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Tolerantie-sliders komen in Wave 2.'),
          ),

          // Sectie: RIJLENGTE (ingevuld in Wave 2)
          const _SectionHeader('RIJLENGTE'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Rijlengte-chips komen in Wave 2.'),
          ),

          // Beschikbaarheidskalender navigatie (D-06-08)
          ListTile(
            title: const Text('Mijn schema bewerken'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/availability'),
          ),
        ],
      ),
    );
  }
}

/// Sectie-koptekst conform Material 3.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
