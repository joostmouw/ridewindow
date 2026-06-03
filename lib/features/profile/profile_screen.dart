// lib/features/profile/profile_screen.dart
// ProfileScreen: Wave 2 — vier tolerantie-sliders, rijlengte-chips, thema-SegmentedButton.
// D-06-02: onChangeEnd persisteert, onChanged update lokale state.

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
  late double _tempMin;
  late double _tempMax;
  late double _rainMax;
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
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Sectie: THEMA (D-06-09: SegmentedButton, PROF-04)
          const _SectionHeader('THEMA'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // D-06-09: SegmentedButton, PROF-04
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'system', label: Text('Systeem')),
                ButtonSegment(value: 'light', label: Text('Licht')),
                ButtonSegment(value: 'dark', label: Text('Donker')),
              ],
              selected: {profile.theme},
              onSelectionChanged: (s) =>
                  ref.read(profileProvider.notifier).setTheme(s.first),
            ),
          ),

          // Sectie: TOLERANTIES
          const _SectionHeader('TOLERANTIES'),

          // --- Min. temperatuur ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Min. temperatuur'),
                    const Spacer(),
                    Text('${_tempMin.round()}°C'),
                  ],
                ),
                // D-06-02: onChangeEnd persisteert, onChanged update lokale state
                Slider(
                  value: _tempMin,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  label: '${_tempMin.round()}°C',
                  onChanged: (v) => setState(() => _tempMin = v),
                  onChangeEnd: (v) => ref
                      .read(profileProvider.notifier)
                      .updateTolerances(
                          profile.tolerances.copyWith(tempMinIdealC: v),),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Max. temperatuur ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Max. temperatuur'),
                    const Spacer(),
                    Text('${_tempMax.round()}°C'),
                  ],
                ),
                Slider(
                  value: _tempMax,
                  min: 15,
                  max: 35,
                  divisions: 20,
                  label: '${_tempMax.round()}°C',
                  onChanged: (v) => setState(() => _tempMax = v),
                  onChangeEnd: (v) => ref
                      .read(profileProvider.notifier)
                      .updateTolerances(
                          profile.tolerances.copyWith(tempMaxIdealC: v),),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Max. neerslag ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Max. neerslag'),
                    const Spacer(),
                    Text('${_rainMax.toStringAsFixed(1)}mm'),
                  ],
                ),
                Slider(
                  value: _rainMax,
                  min: 0,
                  max: 5,
                  divisions: 50,
                  label: '${_rainMax.toStringAsFixed(1)}mm',
                  onChanged: (v) => setState(() => _rainMax = v),
                  onChangeEnd: (v) => ref
                      .read(profileProvider.notifier)
                      .updateTolerances(
                          profile.tolerances.copyWith(rainMaxIdealMm: v),),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Max. wind ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Max. wind'),
                    const Spacer(),
                    Text('${_windMax.round()}km/u'),
                  ],
                ),
                Slider(
                  value: _windMax,
                  min: 0,
                  max: 50,
                  divisions: 50,
                  label: '${_windMax.round()}km/u',
                  onChanged: (v) => setState(() => _windMax = v),
                  onChangeEnd: (v) => ref
                      .read(profileProvider.notifier)
                      .updateTolerances(
                          profile.tolerances.copyWith(windMaxIdealKmh: v),),
                ),
              ],
            ),
          ),

          // Sectie: RIJLENGTE
          const _SectionHeader('RIJLENGTE'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                // PROF-02: last-chip-guard zit in ProfileNotifier.toggleDuration()
                for (final entry in [
                  (2, '2u'),
                  (3, '3u'),
                  (5, '4-5u'),
                ])
                  FilterChip(
                    label: Text(entry.$2),
                    selected: profile.allowedDurations.contains(entry.$1),
                    onSelected: (_) => ref
                        .read(profileProvider.notifier)
                        .toggleDuration(entry.$1),
                  ),
              ],
            ),
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
