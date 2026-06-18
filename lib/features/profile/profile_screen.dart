// lib/features/profile/profile_screen.dart
// ProfileScreen: Wave 2 — vier tolerantie-sliders, rijlengte-chips, thema-SegmentedButton.
// Wave 3 — LOCATIE sectie: stad-picker, GPS-banner (D-07-06).
// Wave 4 — NOTIFICATIES sectie: drie SwitchListTile widgets (NOTIF-01/02/03).
// D-06-02: onChangeEnd persisteert, onChanged update lokale state.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ridewindow/core/nl_cities.dart';
import 'package:ridewindow/platform/notification_service.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int _versionTapCount = 0;

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

  void _showNameDialog(BuildContext context, String? currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jouw naam'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Voer je naam in',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuleer'),
          ),
          TextButton(
            onPressed: () {
              ref.read(profileProvider.notifier).setUserName(controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }

  void _showDebugMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Debug Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Onboarding resetten'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('onboarding.completed');
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Onboarding gereset. Herstart de app.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Weerdata wissen'),
              onTap: () {
                ref.invalidate(weatherProvider);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Weerdata gewist.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Beschikbaarheid resetten'),
              onTap: () async {
                await ref.read(availabilityProvider.notifier).clearAll();
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Beschikbaarheid gereset.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Weer handmatig verversen'),
              onTap: () {
                ref.invalidate(weatherProvider);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Weer wordt ververst.')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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

          // --- Temperatuurbereik (RangeSlider) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Temperatuur',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _infoButton(
                      context,
                      _tempRangeDescription(_tempMin, _tempMax),
                    ),
                    const Spacer(),
                    Text(
                      '${_tempMin.round()}°C – ${_tempMax.round()}°C',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(_tempMin, _tempMax),
                  min: 0,
                  max: 40,
                  divisions: 40,
                  labels: RangeLabels(
                    '${_tempMin.round()}°C',
                    '${_tempMax.round()}°C',
                  ),
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (v) => setState(() {
                    _tempMin = v.start;
                    _tempMax = v.end;
                  }),
                  onChangeEnd: (v) => ref
                      .read(profileProvider.notifier)
                      .updateTolerances(
                        profile.tolerances.copyWith(
                          tempMinIdealC: v.start,
                          tempMaxIdealC: v.end,
                        ),
                      ),
                ),
                Text(
                  _tempRangeDescription(_tempMin, _tempMax),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Max. neerslag + animated drops ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Max. neerslag',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _infoButton(
                      context,
                      _rainDescription(_rainMax),
                    ),
                    const Spacer(),
                    Text(
                      '${_rainMax.toStringAsFixed(1)}mm',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 40,
                  child: _AnimatedRainDrops(intensity: _rainMax / 5.0),
                ),
                Slider(
                  value: _rainMax,
                  min: 0,
                  max: 5,
                  divisions: 50,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (v) => setState(() => _rainMax = v),
                  onChangeEnd: (v) => ref
                      .read(profileProvider.notifier)
                      .updateTolerances(
                        profile.tolerances.copyWith(rainMaxIdealMm: v),
                      ),
                ),
                Text(
                  _rainDescription(_rainMax),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Max. wind + animated windsock ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Max. wind',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _infoButton(
                      context,
                      _windDescription(_windMax),
                    ),
                    const Spacer(),
                    Text(
                      '${_windMax.round()} km/u',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 40,
                  child: _AnimatedWindFlag(intensity: _windMax / 50.0),
                ),
                Slider(
                  value: _windMax,
                  min: 0,
                  max: 50,
                  divisions: 50,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (v) => setState(() => _windMax = v),
                  onChangeEnd: (v) => ref
                      .read(profileProvider.notifier)
                      .updateTolerances(
                        profile.tolerances.copyWith(windMaxIdealKmh: v),
                      ),
                ),
                Text(
                  _windDescription(_windMax),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
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

          // Sectie: NAAM
          const _SectionHeader('NAAM'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(profile.userName ?? 'Stel je naam in'),
            subtitle: profile.userName == null
                ? const Text('Tik om je naam in te voeren voor een persoonlijke begroeting')
                : null,
            onTap: () => _showNameDialog(context, profile.userName),
          ),

          // Sectie: OVER (REL-03: privacybeleid + versie)
          const _SectionHeader('OVER'),
          ListTile(
            title: const Text('Privacybeleid'),
            trailing: const Icon(Icons.open_in_new),
            onTap: _launchPrivacyPolicy,
          ),
          ListTile(
            title: const Text('Versie'),
            trailing: const Text('1.0.0'),
            onTap: () {
              _versionTapCount++;
              if (_versionTapCount >= 5) {
                _versionTapCount = 0;
                _showDebugMenu(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper methods for contextual info descriptions
// ---------------------------------------------------------------------------

Widget _infoButton(BuildContext context, String description) {
  return IconButton(
    icon: const Icon(Icons.info_outline, size: 16, color: Color(0xFF999999)),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    tooltip: description,
    onPressed: () => showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );
}

String _tempRangeDescription(double min, double max) {
  final range = max - min;
  if (range >= 25) return 'Je fietst in bijna elk weer';
  if (range >= 15) return 'Comfortabel fietsbereik';
  if (range >= 8) return 'Alleen bij lekker weer';
  return 'Alleen bij perfect weer';
}

String _rainDescription(double mm) {
  if (mm <= 0.3) return 'Alleen bij droog weer';
  if (mm <= 1.0) return 'Een beetje motregen is ok';
  if (mm <= 3.0) return 'Lichte regen geen probleem';
  return 'Ook bij flinke buien';
}

String _windDescription(double kmh) {
  if (kmh <= 10) return 'Alleen bij windstil weer';
  if (kmh <= 20) return 'Rustig briesje is prima';
  if (kmh <= 30) return 'Stevige wind geen probleem';
  return 'Zelfs bij harde wind';
}

// ---------------------------------------------------------------------------
// Animated rain drops — more drops at higher intensity
// ---------------------------------------------------------------------------

class _AnimatedRainDrops extends StatefulWidget {
  final double intensity; // 0.0–1.0

  const _AnimatedRainDrops({required this.intensity});

  @override
  State<_AnimatedRainDrops> createState() => _AnimatedRainDropsState();
}

class _AnimatedRainDropsState extends State<_AnimatedRainDrops>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dropCount = (widget.intensity * 12).round().clamp(1, 12);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RainPainter(
            progress: _controller.value,
            dropCount: dropCount,
            intensity: widget.intensity,
          ),
          size: const Size(double.infinity, 40),
        );
      },
    );
  }
}

class _RainPainter extends CustomPainter {
  final double progress;
  final int dropCount;
  final double intensity;

  _RainPainter({
    required this.progress,
    required this.dropCount,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.lerp(
        const Color(0x4042A5F5),
        const Color(0xCC1565C0),
        intensity,
      )!
      ..strokeWidth = 1.5 + intensity
      ..strokeCap = StrokeCap.round;

    final rng = math.Random(42);
    for (var i = 0; i < dropCount; i++) {
      final x = rng.nextDouble() * size.width;
      final speed = 0.7 + rng.nextDouble() * 0.3;
      final y = ((progress * speed + rng.nextDouble()) % 1.0) * size.height;
      final length = 4 + intensity * 6;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 1, y + length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) =>
      old.progress != progress || old.dropCount != dropCount;
}

// ---------------------------------------------------------------------------
// Animated wind flag — oscillates faster/wider at higher intensity
// ---------------------------------------------------------------------------

class _AnimatedWindFlag extends StatefulWidget {
  final double intensity; // 0.0–1.0

  const _AnimatedWindFlag({required this.intensity});

  @override
  State<_AnimatedWindFlag> createState() => _AnimatedWindFlagState();
}

class _AnimatedWindFlagState extends State<_AnimatedWindFlag>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Angle: 0 at rest, up to 35 degrees at max wind
        final maxAngle = widget.intensity * 0.6; // ~35 degrees
        final angle = math.sin(_controller.value * math.pi) * maxAngle;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: angle,
              alignment: Alignment.bottomCenter,
              child: Text(
                '🚩',
                style: TextStyle(fontSize: 20 + widget.intensity * 8),
              ),
            ),
            const SizedBox(width: 8),
            // Wind lines that stretch with intensity
            ...List.generate(
              (widget.intensity * 3).round().clamp(0, 3),
              (i) => Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  width: 12 + widget.intensity * 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0x33999999),
                      const Color(0x99666666),
                      widget.intensity,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
