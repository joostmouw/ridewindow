import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridewindow/data/repositories/ride_score_alert_store.dart';
import 'package:ridewindow/domain/models/watched_ride.dart';
import 'package:ridewindow/domain/services/ride_window_scorer.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/platform/notification_service.dart';

/// Eén controlepad voor voorgrond en WorkManager, zonder cloud-aanroepen.
class RideScoreAlerts {
  RideScoreAlerts(this.prefs, {NotificationService? notifications})
      : notifications = notifications ?? NotificationService();

  final SharedPreferences prefs;
  final NotificationService notifications;
  Future<void> _pending = Future.value();

  /// Serialiseert voorgrondwijzigingen: een profielslider mag geen drie
  /// overlappende controles met dezelfde oude vergelijkingsscore starten.
  Future<void> check({
    required RideWindowScorer scorer,
    required String locale,
    List<WatchedRide>? rides,
    String? owner,
    bool retainShared = false,
    DateTime? now,
    bool Function()? isCurrent,
  }) {
    final result = _pending.then(
      (_) => _check(
        scorer: scorer,
        locale: locale,
        rides: rides,
        owner: owner,
        retainShared: retainShared,
        now: now ?? DateTime.now(),
        isCurrent: isCurrent ?? () => true,
      ),
    );
    _pending = result.catchError((Object error) {});
    return result;
  }

  Future<void> _check({
    required RideWindowScorer scorer,
    required String locale,
    required List<WatchedRide>? rides,
    required String? owner,
    required bool retainShared,
    required DateTime now,
    required bool Function() isCurrent,
  }) async {
    if (kIsWeb || !isCurrent()) return;
    // Een andere isolate kan inmiddels meldingen of voorkeuren hebben
    // bijgewerkt. De oude SharedPreferences-cache is dan niet de bron.
    await prefs.reload();
    if (!isCurrent()) return;
    final store = RideScoreAlertStore(prefs);
    final old = store.read();
    final sameOwner = rides == null || old.owner == owner;
    final watched = {
      if (rides == null || (sameOwner && retainShared))
        for (final r in old.rides)
          if (rides == null || r.shared) r.key: r,
      if (rides != null)
        for (final r in rides) r.key: r,
    }.values.where((r) => r.start.isAfter(now)).toList();
    final threshold = store.threshold;
    // Instellingen/locatie herijken de vergelijking. Een zelf verlaagde
    // regentolerantie is geen verslechtering van het weer.
    final context = jsonEncode([
      scorer.tolerances.toJson(),
      scorer.latitude?.toStringAsFixed(2),
      scorer.longitude?.toStringAsFixed(2),
      threshold,
    ]);
    final baselines = sameOwner && context == old.context
        ? Map<String, dynamic>.from(old.baselines)
        : <String, dynamic>{};
    final active = watched.map((r) => r.key).toSet();
    baselines.removeWhere((key, value) => !active.contains(key));

    final strings = await S.delegate.load(Locale(locale));
    final permitted =
        threshold > 0 && await notifications.areNotificationsEnabled();
    if (watched.isNotEmpty || old.rides.isNotEmpty) {
      await notifications.init(strings: strings);
    }
    for (final ride in old.rides) {
      if (!sameOwner || !active.contains(ride.key)) {
        await notifications.cancelScoreDrop(ride.key);
      }
    }
    for (final ride in watched) {
      if (!isCurrent()) return;
      if (threshold == 0) {
        await notifications.cancelScoreDrop(ride.key);
        continue;
      }
      final score = scorer.score(ride.start, ride.end)?.overallScore;
      if (score == null) continue;
      final previous = baselines[ride.key];
      final previousScore = previous is Map ? previous['score'] : null;
      final reference = previous is Map &&
              previous['window'] == ride.window &&
              previousScore is num &&
              previousScore.isFinite
          ? previousScore.toDouble()
          : null;
      if (reference == null || score > reference || !permitted) {
        baselines[ride.key] = {'window': ride.window, 'score': score};
      } else if (reference - score >= threshold) {
        await notifications.showScoreDrop(
          ride: ride,
          previousScore: reference,
          currentScore: score,
          strings: strings,
        );
        // Pas na aflevering: een pluginfout mag de waarschuwing niet opeten.
        baselines[ride.key] = {'window': ride.window, 'score': score};
        // Per aflevering bewaren: faalt de tweede rit, dan hoort de eerste
        // volgende ronde niet nogmaals te rinkelen.
        if (!isCurrent()) return;
        await store.save(
          RideAlertSnapshot(
            owner: rides == null ? old.owner : owner,
            context: context,
            rides: watched,
            baselines: baselines,
          ),
        );
      }
    }
    if (!isCurrent()) return;
    await store.save(
      RideAlertSnapshot(
        owner: rides == null ? old.owner : owner,
        context: context,
        rides: watched,
        baselines: threshold == 0 ? {} : baselines,
      ),
    );
  }

  /// Uitzetten werkt ook zonder geladen of bereikbaar weer.
  Future<void> disable({required String locale}) async {
    await prefs.reload();
    final store = RideScoreAlertStore(prefs);
    final snapshot = store.read();
    if (snapshot.rides.isNotEmpty) {
      await notifications.init(
        strings: await S.delegate.load(Locale(locale)),
      );
      for (final ride in snapshot.rides) {
        await notifications.cancelScoreDrop(ride.key);
      }
    }
    await store.save(
      RideAlertSnapshot(
        owner: snapshot.owner,
        rides: snapshot.rides,
      ),
    );
  }
}
