// lib/features/shared/feedback_rate_limited_listener.dart
// Maakt feedback-weigeringen zichtbaar, precies één per keer (fase 38,
// RATE-05).
//
// Staat in de builder van MaterialApp.router, onder de ScaffoldMessenger en
// de Localizations van de app: juist daarom kan hier een vertaalde snackbar
// vertrekken, terwijl de reconciler zelf cloud-, widget- en contextvrij
// blijft. Voor hetzelfde patroon zie `TopBanners`, dat om diezelfde reden
// zijn navigatorKey meegeleverd krijgt.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/cloud_sync_reconciler_provider.dart';

/// Hoe lang een tweede melding over een weigering achterwege blijft.
///
/// Eén voorgrondcyclus draint twee keer (vóór en na de merge, plan 21-14) en
/// de opstart-reconcile kan vlak op de voorgrond-reconcile volgen: dezelfde
/// rij wordt dan binnen enkele tellen twee- of driemaal geweigerd. Die
/// herhaling zegt niets nieuws -- hetzelfde bewaarde bericht, dezelfde
/// belofte -- dus binnen dit venster volgt er geen tweede snackbar. Na het
/// venster doet een nieuwe weigering (een nieuw bericht, een nieuwe dag) het
/// weer. Publiek, zodat de test de productiewaarde kan zien in plaats van
/// hem te dupliceren.
const kFeedbackRefusalSuppressWindow = Duration(seconds: 10);

/// Hoe goedlopende apps het doen (werkregel van 2026-09-29): WhatsApp en
/// Strava zwijgen als alles aankomt, maar zeggen wél iets als iets van de
/// gebruiker níet is aangekomen. Bewust afgeweken van een rode error-toast:
/// dit is geen mislukking maar een uitgestelde bezorging, en de tekst zegt
/// dan ook eerlijk dat het bericht bewaard is en later opnieuw gaat.
class FeedbackRateLimitedListener extends ConsumerStatefulWidget {
  const FeedbackRateLimitedListener({
    super.key,
    this.suppressWindow = kFeedbackRefusalSuppressWindow,
  });

  /// Injecteerbaar voor de test: het venster wordt gemeten op de echte klok
  /// (`DateTime.now()`), en wie in een test klok vooruit zet met `pump`
  /// zet dáármeé geen muurklok vooruit.
  final Duration suppressWindow;

  @override
  ConsumerState<FeedbackRateLimitedListener> createState() =>
      _FeedbackRateLimitedListenerState();
}

class _FeedbackRateLimitedListenerState
    extends ConsumerState<FeedbackRateLimitedListener> {
  DateTime? _lastShownAt;

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(feedbackRateLimitedProvider, (_, next) {
      if (next <= 0) return;
      // Meteen terug op nul, zodat de volgende drain met een schone teller
      // begint. De teruggelegde nul triggert deze luisteraar opnieuw, maar de
      // guard hierboven doet dan niets.
      ref.read(feedbackRateLimitedProvider.notifier).clear();

      final now = DateTime.now();
      final last = _lastShownAt;
      if (last != null && now.difference(last) < widget.suppressWindow) {
        return;
      }
      _lastShownAt = now;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).feedbackRateLimited)),
      );
    });
    // Nul bij nul: deze widget bestaat alleen om te luisteren en mag de
    // layout niet raken.
    return const SizedBox.shrink();
  }
}
