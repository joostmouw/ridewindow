// lib/features/profile/profile_screen.dart
// ProfileScreen: Wave 2 — vier tolerantie-sliders, rijlengte-chips, thema-SegmentedButton.
// Wave 3 — LOCATIE sectie: stad-picker, GPS-banner (D-07-06).
// Wave 4 — NOTIFICATIES sectie: drie SwitchListTile widgets (NOTIF-01/02/03).
// D-06-02: onChangeEnd persisteert, onChanged update lokale state.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ridewindow/core/nl_cities.dart';
import 'package:ridewindow/platform/notification_service.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

const _kPrivacyPolicyUrl = 'https://joostmouw.github.io/ridewindow-privacy/';

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Lokale state voor live slider-waarden (vóór onChangeEnd persistentie).
  late double _tempMin;
  late double _tempMax;
  late double _rainMax;
  late double _windMax;

  final _notifService = NotificationService();

  Future<void> _launchPrivacyPolicy() async {
    final uri = Uri.parse(_kPrivacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Vraag POST_NOTIFICATIONS op en toon SnackBar als SCHEDULE_EXACT_ALARM niet beschikbaar is.
  /// Aanroepen bij inschakelen van een notificatie-toggle (NOTIF-04, NOTIF-05).
  Future<void> _scheduleNotificationsIfPermitted(BuildContext context) async {
    // 1. Vraag POST_NOTIFICATIONS op
    final granted = await _notifService.requestPostNotificationsPermission();
    if (!granted) return;

    // 2. Controleer SCHEDULE_EXACT_ALARM
    final canExact = await _notifService.canScheduleExact();
    if (!canExact) {
      // Toon SnackBar met uitleg (per NOTIF-05 fallback, D-08-09)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Exacte timing niet gegarandeerd. Sta exacte alarmen toe in Instellingen voor betrouwbaarheid.',
            ),
            action: SnackBarAction(
              label: 'Instellingen',
              onPressed: () => _notifService.openExactAlarmSettings(),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
    // Verdere scheduling vindt plaats via SlotsNotifier data in de toekomst (Phase 8 scope: permissie-flow)
  }

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

  void _openCityPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: ListView.builder(
            itemCount: kNlCities.length,
            itemBuilder: (_, i) {
              final city = kNlCities[i];
              return ListTile(
                title: Text(city.name),
                onTap: () {
                  ref
                      .read(profileProvider.notifier)
                      .setLocationOverride(city.name);
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final permissionAsync = ref.watch(gpsPermissionProvider);
    final permission = permissionAsync.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profiel')),
      body: ListView(
        key: const PageStorageKey('profile_settings'),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Sectie: LOCATIE (D-07-06: stad-picker + GPS-banner, LOC-03, LOC-04)
          const _SectionHeader('LOCATIE'),

          // ELEMENT 1 — GPS-geblokkeerd banner (deniedForever)
          if (permission == LocationPermission.deniedForever)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locatie-toegang geblokkeerd',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kies een stad of open instellingen om GPS opnieuw in te schakelen.',
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(gpsPermissionProvider.notifier)
                          .openSettings(),
                      child: const Text('Instellingen openen'),
                    ),
                  ],
                ),
              ),
            ),

          // ELEMENT 2 — GPS toestemming vragen (denied, niet deniedForever)
          if (permission == LocationPermission.denied)
            ListTile(
              leading: const Icon(Icons.location_searching),
              title: const Text('GPS-locatie gebruiken'),
              trailing: TextButton(
                onPressed: () => ref
                    .read(gpsPermissionProvider.notifier)
                    .requestPermission(),
                child: const Text('Toestemming geven'),
              ),
            ),

          // ELEMENT 3 — Actieve locatie + stad-picker
          ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(profile.locationOverride ?? 'GPS (automatisch)'),
            subtitle: const Text('Tik om stad te kiezen'),
            trailing: profile.locationOverride != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => ref
                        .read(profileProvider.notifier)
                        .setLocationOverride(null),
                  )
                : null,
            onTap: () => _openCityPicker(context),
          ),

          // Sectie: NOTIFICATIES (NOTIF-01, NOTIF-02, NOTIF-03)
          const _SectionHeader('NOTIFICATIES'),

          SwitchListTile(
            title: const Text('Avond van tevoren'),
            subtitle: const Text('19:00 de vorige dag als er een top-slot is'),
            value: profile.notifEveningBefore,
            onChanged: (v) async {
              await ref.read(profileProvider.notifier).setNotifEveningBefore(v);
              if (v && context.mounted) await _scheduleNotificationsIfPermitted(context);
            },
          ),

          SwitchListTile(
            title: const Text('Ochtend van de dag'),
            subtitle: const Text('2 uur voor het slot begint'),
            value: profile.notifMorningOf,
            onChanged: (v) async {
              await ref.read(profileProvider.notifier).setNotifMorningOf(v);
              if (v && context.mounted) await _scheduleNotificationsIfPermitted(context);
            },
          ),

          SwitchListTile(
            title: const Text('Wekelijks overzicht'),
            subtitle: const Text('Zondagavond 19:00 — beste momenten van de week'),
            value: profile.notifWeeklyDigest,
            onChanged: (v) async {
              await ref.read(profileProvider.notifier).setNotifWeeklyDigest(v);
              if (v && context.mounted) await _scheduleNotificationsIfPermitted(context);
            },
          ),

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
                FilterChip(
                  label: const Text('2u'),
                  selected: profile.allowedDurations.contains(2),
                  onSelected: (_) {
                    HapticFeedback.lightImpact();
                    ref.read(profileProvider.notifier).toggleDuration(2);
                  },
                ),
                FilterChip(
                  label: const Text('3u'),
                  selected: profile.allowedDurations.contains(3),
                  onSelected: (_) {
                    HapticFeedback.lightImpact();
                    ref.read(profileProvider.notifier).toggleDuration(3);
                  },
                ),
                FilterChip(
                  label: const Text('4-5u'),
                  selected: profile.allowedDurations.contains(5),
                  onSelected: (_) {
                    HapticFeedback.lightImpact();
                    ref.read(profileProvider.notifier).toggleDuration(5);
                  },
                ),
              ],
            ),
          ),

          // Beschikbaarheidskalender navigatie (D-06-08)
          ListTile(
            title: const Text('Mijn schema bewerken'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/availability'),
          ),

          // Sectie: OVER (REL-03: privacybeleid + versie)
          const _SectionHeader('OVER'),
          ListTile(
            title: const Text('Privacybeleid'),
            trailing: const Icon(Icons.open_in_new),
            onTap: _launchPrivacyPolicy,
          ),
          const ListTile(
            title: Text('Versie'),
            trailing: Text('1.0.0'),
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
