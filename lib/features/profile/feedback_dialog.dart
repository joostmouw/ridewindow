// lib/features/profile/feedback_dialog.dart
// Backlog #33 / fase 22: "Send feedback" dialoog — 1-5 sterren + vrije tekst,
// weggeschreven naar `public.feedback` via de outbox in plaats van naar een
// mailto:.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridewindow/core/app_version.dart';
import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/services/feedback_payload.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/services/feedback_service.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Opent de feedbackdialoog.
Future<void> showFeedbackDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _FeedbackDialog(),
  );
}

class _FeedbackDialog extends ConsumerStatefulWidget {
  const _FeedbackDialog();

  @override
  ConsumerState<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<_FeedbackDialog> {
  int _rating = 0;
  bool _sending = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Vriest de context in op het moment van versturen (FB-02).
  ///
  /// Alles hiervoor komt uit providers die het scherm tóch al heeft; er wordt
  /// niets extra's opgehaald en er gaat geen netwerkverzoek aan vooraf. Faalt
  /// een van de lezingen, dan blijft dat veld leeg in plaats van dat het
  /// versturen mislukt -- feedback zonder context is nog altijd beter dan geen
  /// feedback.
  Map<String, dynamic> _buildContext() {
    final profile = ref.read(profileProvider).value;
    final slotsState = ref.read(slotsProvider);
    final RideSlot? topSlot =
        slotsState is SlotsLoaded && slotsState.slots.isNotEmpty
            ? slotsState.slots.first
            : null;
    final forecasts =
        ref.read(weatherProvider).value ?? const <HourlyForecast>[];
    final slotForecasts = topSlot == null
        ? const <HourlyForecast>[]
        : forecasts
            .where((f) =>
                !f.time.isBefore(topSlot.start) && f.time.isBefore(topSlot.end))
            .toList();

    if (profile == null) return const {};
    return buildFeedbackContext(
      profile: profile,
      topSlot: topSlot,
      slotForecasts: slotForecasts,
      city: ref.read(locationProvider).value?.city,
      appVersion: kAppVersionDisplay,
      platform: isWebPlatform ? 'web' : 'android',
    );
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final service = FeedbackService(
        ref.read(appDatabaseProvider).syncOutboxDao,
      );
      await service.submit(
        // `null` wanneer niemand is ingelogd -- dat is de anonieme route van
        // FB-03, niet een foutgeval.
        userId: ref.read(currentUserIdProvider),
        rating: _rating,
        comment: _controller.text,
        context: _buildContext(),
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(s.feedbackThanks)));
    } catch (error) {
      // De rij staat in de outbox of hij staat er niet; in beide gevallen mag
      // een mislukking geen scherm laten crashen. Zelfde afweging als bij de
      // sync-drain.
      debugPrint('Feedback versturen mislukt: $error');
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text(s.feedbackFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.sendFeedback),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.feedbackRatingLabel),
          Row(
            children: List.generate(5, (i) {
              final n = i + 1;
              final selected = n <= _rating;
              return Semantics(
                selected: selected,
                button: true,
                child: IconButton(
                  key: ValueKey('feedback_star_$n'),
                  icon: Icon(selected ? Icons.star : Icons.star_border),
                  tooltip: s.feedbackStarRating(n),
                  color: selected
                      ? context.rw.scorePerfect
                      : Theme.of(context).colorScheme.outline,
                  onPressed: () => setState(() => _rating = n),
                ),
              );
            }),
          ),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: s.feedbackCommentLabel,
              hintText: s.feedbackCommentHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        TextButton(
          onPressed: _rating == 0 || _sending ? null : _submit,
          child: Text(s.feedbackSendButton),
        ),
      ],
    );
  }
}
