// lib/features/shared/store_app_banner.dart
// "Er is ook een Android-app": de balk voor wie de website op een
// Android-toestel opent.
//
// Zolang de app in closed testing staat, geeft de Play-link "niet gevonden"
// voor iedereen die geen tester is (TESTERS.md: groepsleden kregen "App not
// available"). Meedoen gaat in drie stappen, en die passen niet in één knop.
// Daarom opent "Doe mee" een venster met de stappen uit de testeruitnodiging.
// Na de publieke lancering wordt [kStoreAppPublic] true en opent de knop de
// Play-vermelding direct.
//
// Ook in de geïnstalleerde PWA: de native app kan meer (widget, meldingen,
// agenda), dus de verwijzing blijft zinvol. Wegklikken sluimert zoals de
// iOS-balk: een week, en na drie keer houdt de app erover op.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ridewindow/core/pwa_display_mode.dart';
import 'package:ridewindow/core/store_links.dart';
import 'package:ridewindow/data/repositories/install_hint_store.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';

class StoreAppBanner extends StatefulWidget {
  const StoreAppBanner({super.key});

  @override
  State<StoreAppBanner> createState() => _StoreAppBannerState();
}

class _StoreAppBannerState extends State<StoreAppBanner> {
  /// Falen naar zichtbaar, zoals de iOS-balk: lukt het lezen niet, dan staat
  /// hij er gewoon.
  bool _hidden = false;
  InstallHintStore? _store;

  @override
  void initState() {
    super.initState();
    if (isAndroidWeb) _loadState();
  }

  Future<void> _loadState() async {
    try {
      final store = InstallHintStore.storeApp(
        await SharedPreferences.getInstance(),
      );
      if (!mounted) return;
      setState(() {
        _store = store;
        _hidden = store.isSuppressed();
      });
    } catch (_) {
      // Zichtbaar laten.
    }
  }

  Future<void> _dismiss() async {
    setState(() => _hidden = true);
    try {
      await _store?.recordDismissal();
    } catch (_) {
      // Voor deze sessie is hij weg; onthouden is een extraatje.
    }
  }

  Future<void> _join() async {
    if (kStoreAppPublic) {
      await openStoreLink(kPlayStoreListingUrl);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const TesterStepsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAndroidWeb || _hidden) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final onColor = colorScheme.onInverseSurface;

    return Material(
      color: colorScheme.inverseSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
        child: Row(
          children: [
            Icon(AppIcons.personSimpleBike, color: onColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(s.storeBannerText, style: TextStyle(color: onColor)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.inversePrimary,
              ),
              onPressed: _join,
              child: Text(s.storeBannerAction),
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

/// Opent een store- of groepslink buiten de app: op web in een nieuw tabblad,
/// zodat de PWA zelf blijft staan.
Future<void> openStoreLink(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    // Niets te doen: de gebruiker ziet dat er niets opende en kan opnieuw.
  }
}

/// De drie stappen om tester te worden, elk met een eigen knop. Dezelfde
/// volgorde als de testeruitnodiging (.planning/testers/uitnodiging.html).
class TesterStepsSheet extends StatelessWidget {
  const TesterStepsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final steps = [
      (s.storeStepGroup, kTesterGroupUrl),
      (s.storeStepOptIn, kTesterOptInUrl),
      (s.storeStepInstall, kPlayStoreListingUrl),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.storeStepsTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              s.storeStepsIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final (i, (label, url)) in steps.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text('${i + 1}'),
                ),
                title: Text(label),
                trailing: TextButton.icon(
                  onPressed: () => openStoreLink(url),
                  icon: const Icon(AppIcons.arrowSquareOut, size: 18),
                  label: Text(s.storeStepOpen),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
