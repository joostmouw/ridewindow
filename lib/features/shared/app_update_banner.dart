// lib/features/shared/app_update_banner.dart
// De balk bovenaan als er een nieuwere build klaarstaat: in Play op Android,
// op de webserver voor de PWA. Zie AppUpdateService voor de twee bronnen.
//
// Hij vraagt het bij de start en bij terugkeer in de app, hooguit eens per
// kwartier: testers laten de app dagen openstaan, en juist dan loopt een
// release langs ze heen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/data/repositories/update_banner_store.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/app_update_provider.dart';
import 'package:ridewindow/theme/app_icons.dart';

class AppUpdateBanner extends ConsumerStatefulWidget {
  const AppUpdateBanner({super.key});

  /// Hoe lang een antwoord geldig blijft voordat terugkeer opnieuw vraagt.
  static const Duration kRecheckAfter = Duration(minutes: 15);

  @override
  ConsumerState<AppUpdateBanner> createState() => _AppUpdateBannerState();
}

class _AppUpdateBannerState extends ConsumerState<AppUpdateBanner>
    with WidgetsBindingObserver {
  int? _available;
  int? _dismissed;
  DateTime? _checkedAt;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _checkedAt;
    if (last != null &&
        DateTime.now().difference(last) < AppUpdateBanner.kRecheckAfter) {
      return;
    }
    _check();
  }

  Future<void> _check() async {
    _checkedAt = DateTime.now();
    final available =
        await ref.read(appUpdateServiceProvider).availableBuild();
    int? dismissed;
    try {
      dismissed =
          UpdateBannerStore(await SharedPreferences.getInstance()).dismissedBuild;
    } catch (_) {
      // Niet te lezen: dan geldt er niets als weggeklikt.
    }
    if (!mounted) return;
    setState(() {
      _available = available;
      _dismissed = dismissed;
    });
  }

  Future<void> _dismiss() async {
    final build = _available;
    if (build == null) return;
    setState(() => _dismissed = build);
    try {
      await UpdateBannerStore(await SharedPreferences.getInstance())
          .dismiss(build);
    } catch (_) {
      // Voor deze sessie is hij weg; onthouden is een extraatje.
    }
  }

  Future<void> _apply() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(appUpdateServiceProvider).apply();
    } catch (_) {
      // De dienst vangt zelf af; dit is het laatste vangnet.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!showUpdateBanner(available: _available, dismissed: _dismissed)) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final onColor = colorScheme.onInverseSurface;

    return Material(
      color: colorScheme.inverseSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
        child: Row(
          children: [
            Icon(AppIcons.arrowsClockwise, color: onColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(s.updateBannerText, style: TextStyle(color: onColor)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.inversePrimary,
              ),
              onPressed: _busy ? null : _apply,
              child: Text(
                isWebPlatform ? s.updateBannerReload : s.updateBannerUpdate,
              ),
            ),
            IconButton(
              icon: const Icon(AppIcons.x, size: 18),
              color: onColor,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: _dismiss,
            ),
          ],
        ),
      ),
    );
  }
}
