import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/analytics_provider.dart';
import 'package:ridewindow/theme/app_icons.dart';

/// De toestemmingsvraag voor gebruiksstatistiek.
///
/// **Waarom twee knoppen en geen vinkje.** Een vooraf aangevinkt vakje is geen
/// geldige toestemming, en een leeg vakje wordt door vrijwel iedereen
/// overgeslagen -- dan zou de vraag er alleen voor de vorm staan. Twee gelijke
/// knoppen dwingen een echt antwoord af, en "nee" is net zo makkelijk te geven
/// als "ja".
///
/// **Waarom dit niet op de eerste start verschijnt.** Zie
/// `AnalyticsConsentStore.kAskAtOpenCount`.
Future<void> showAnalyticsConsentSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: false,
    builder: (sheetContext) {
      final s = S.of(sheetContext);
      final cs = Theme.of(sheetContext).colorScheme;

      // Sluiten staat in een `finally` en niet achter de await.
      //
      // Het vastleggen van de keuze is de eerste handeling in `setConsent`;
      // alles daarna is boekhouding. Gooide die boekhouding, dan bleef deze
      // kaart staan terwijl de keuze allang geland was -- de gebruiker drukte
      // op een knop die zichtbaar niets deed. Dat is precies wat een tester op
      // 1.0.35+46 meldde. De oorzaak daarvan is weg (zie `setConsent`), maar de
      // volgorde blijft fout zolang het dichtgaan van dit venster afhangt van
      // of de regel ervoor slaagt.
      //
      // De fout wordt gemeld en niet doorgegooid. Doorgooien zou hem in de
      // weggegooide Future van `onPressed` laten belanden, waar niemand hem
      // ziet; `reportError` zet hem in dezelfde stroom als elke andere
      // Flutter-fout, dus in logcat en in de tests. Weggooien van de vraag is
      // niet erg: lukte het opslaan niet, dan blijft `consent` null, blijft
      // `shouldAsk` true, en staat de vraag er bij de volgende start gewoon
      // weer. Een kaart die blijft hangen herstelt zichzelf niet.
      Future<void> answer(bool granted) async {
        try {
          await ref.read(analyticsConsentProvider.notifier).setConsent(granted);
        } catch (error, stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'ridewindow analytics consent',
              context:
                  ErrorDescription('bij het vastleggen van de toestemming'),
            ),
          );
        } finally {
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        }
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.trendUp, size: 28, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                s.analyticsAskTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                s.analyticsAskBody,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              // Gelijke breedte, gelijk gewicht: "nee" mag niet moeilijker
              // klikken dan "ja".
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => answer(false),
                      child: Text(s.analyticsAskNo),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => answer(true),
                      child: Text(s.analyticsAskYes),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
