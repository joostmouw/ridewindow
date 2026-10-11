// Test voor de feedback-weigeringsmelding (fase 38, RATE-05, plan 38-02).
//
// Dekt de meldingskoppeling zelf: een stijging van de teller toont precies
// één vertaalde snackbar en zet de teller terug op nul, zodat de volgende
// drain op een schone teller begint. En de onderdrukking: één voorgrondcyclus
// draint twee keer (plan 21-14), dus een tweede stijging binnen het venster
// volgt geen tweede snackbar. Het bewijs dat de rij blijft bestaan en geen
// poging telt staat in test/services/sync_outbox_service_test.dart en
// test/providers/cloud_sync_reconciler_gateway_test.dart.
//
// Het venster wordt geïnjecteerd, want het meet op de echte muurklok:
// `pump` zet in een test alleen de klok van timers vooruit, niet
// `DateTime.now()`, dus wachten in faketijd bewijst hier niets.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/features/shared/feedback_rate_limited_listener.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/cloud_sync_reconciler_provider.dart';

const _melding =
    'Je feedback is bewaard op dit toestel en gaat later automatisch '
    'opnieuw. Voor vandaag is de daglimiet bereikt.';

Future<void> _pumpListener(
  WidgetTester tester,
  ProviderContainer container, {
  Duration suppressWindow = kFeedbackRefusalSuppressWindow,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: FeedbackRateLimitedListener(suppressWindow: suppressWindow),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'een stijging toont precies één NL snackbar, zet de teller op nul en '
      'onderdrukt een tweede stijging binnen het venster',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpListener(tester, container);

    container.read(feedbackRateLimitedProvider.notifier).bump(1);
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(_melding), findsOneWidget);
    expect(
      container.read(feedbackRateLimitedProvider),
      0,
      reason: 'de luisteraar zet na de melding terug op nul; de teruggelegde '
          'nul mag zelf geen tweede melding geven',
    );

    // Snackbar volledig uit laten laten spelen, en dan de herhaling
    // aanbieden: de tweede drain van dezelfde voorgrondcyclus (plan 21-14),
    // die opnieuw nee krijgt op dezelfde rij.
    //
    // Niet met één grote `pump(...)`: bij een klok-sprong voltooit de
    // entree-animatie ín dat ene frame en start de display-timer pas ná de
    // sprong, dus de snackbar verdwijnt nooit binnen de sprong. Per frame
    // oprekken (10 seconden totaal) verwerkt entree, display-timer en
    // afwijkanimatie stuk voor stuk.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    container.read(feedbackRateLimitedProvider.notifier).bump(1);
    await tester.pump();

    expect(
      find.byType(SnackBar),
      findsNothing,
      reason: 'binnen het venster is de herhaling geen nieuws: hetzelfde '
          'bewaarde bericht, dezelfde belofte',
    );
    expect(container.read(feedbackRateLimitedProvider), 0);
  });

  testWidgets(
      'na het venster is een nieuwe weigering wéér nieuws: met venster nul '
      'volgt de tweede melding gewoon',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpListener(tester, container, suppressWindow: Duration.zero);

    container.read(feedbackRateLimitedProvider.notifier).bump(1);
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);

    // Zelfde per-frame oprekken als in de eerste test, om dezelfde reden:
    // de eerste snackbar moet werkelijk uit de boom zijn, anders toetst de
    // findsOneWidget hieronder misschien nog de oude.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();

    container.read(feedbackRateLimitedProvider.notifier).bump(1);
    await tester.pump();

    expect(
      find.byType(SnackBar),
      findsOneWidget,
      reason: 'met venster nul staat niets herhaling in de weg; dit is de '
          'contraproef van de onderdrukking hierboven',
    );
  });

  testWidgets('een teller op nul toont niets', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpListener(tester, container);

    // De initiele build luistert; nul is de rusttoestand.
    container.read(feedbackRateLimitedProvider.notifier).clear();
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });
}
