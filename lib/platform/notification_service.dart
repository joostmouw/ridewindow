// lib/platform/notification_service.dart
// NotificationService: centraliseert alle notificatie-logica voor Ridewindow.
// Geen @riverpod — plain klasse, injecteerbaar voor tests.
//
// Alle gebruikerszichtbare tekst komt uit `S` (backlog #67). De service heeft
// geen BuildContext, dus de aanroeper levert de geladen `S` aan: vanuit een
// scherm met `S.of(context)`, vanuit main.dart met `S.delegate.load(locale)`.

import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/models/watched_ride.dart';
import 'package:ridewindow/domain/services/notification_plan.dart';
import 'package:ridewindow/core/ride_day_label.dart';
import 'package:ridewindow/l10n/app_localizations.dart';

/// Unieke notificatie-ID's per notificatietype.
const int kNotifIdEveningBefore = 1001;
const int kNotifIdMorningOf = 1002;
const int kNotifIdWeeklyDigest = 1003;

/// Kanaal-id's. De id is de identiteit van het kanaal en ligt vast; naam en
/// omschrijving zijn vertaalbaar en worden bijgewerkt in [ensureChannels].
const String kChannelRideAlerts = 'ride_alerts';
const String kChannelWeeklyDigest = 'weekly_digest';

/// Gecentraliseerde notification-service voor Ridewindow.
/// Beheert kanaal-registratie, permissies en drie notificatie-schedulers.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  bool _pluginInitialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Initialiseer plugin + zet beide kanalen in de taal van [strings].
  /// Idempotent: aanroepen bij elke taalwissel is veilig en bedoeld.
  Future<void> init({required S strings}) async {
    if (kIsWeb) return;

    if (!_pluginInitialized) {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings: initSettings);
      _pluginInitialized = true;
    }

    await ensureChannels(strings);
  }

  /// Maak beide kanalen aan, of werk naam en omschrijving bij als ze al bestaan.
  ///
  /// Bewust bijwerken en niet verwijderen-en-opnieuw-aanmaken: Android werkt bij
  /// een bestaande kanaal-id alleen naam en omschrijving bij en laat de keuzes
  /// van de gebruiker (geluid, trilling, belang) staan. Een delete zou die
  /// wissen — een taalwissel mag geen instellingen kosten.
  Future<void> ensureChannels(S strings) async {
    final androidPlugin = _androidPlugin;
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        kChannelRideAlerts,
        strings.notifChannelRideAlerts,
        description: strings.notifChannelRideAlertsDesc,
        importance: Importance.high,
      ),
    );
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        kChannelWeeklyDigest,
        strings.notifChannelWeeklyDigest,
        description: strings.notifChannelWeeklyDigestDesc,
        importance: Importance.defaultImportance,
      ),
    );
  }

  /// Vraag POST_NOTIFICATIONS-permissie op (Android 13+).
  /// Geeft true terug als permissie verleend is.
  Future<bool> requestPostNotificationsPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> areNotificationsEnabled() async =>
      await _androidPlugin?.areNotificationsEnabled() ?? false;

  Future<void> showScoreDrop({
    required WatchedRide ride,
    required double previousScore,
    required double currentScore,
    required S strings,
  }) async {
    // WorkManager draait zonder de locale-data die main.dart geladen heeft.
    await initializeDateFormatting(
      strings.localeName == 'nl' ? 'nl_NL' : 'en_US',
    );
    String time(DateTime value) =>
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
    final slot = '${rideDayLabelAbsolute(ride.start, strings)} '
        '${time(ride.start)}–${time(ride.end)}';
    await _plugin.show(
      id: scoreDropNotificationId(ride.key),
      title: strings.notifScoreDropTitle,
      body: strings.notifScoreDropBody(
        slot,
        (previousScore - currentScore).round(),
        previousScore.round(),
        currentScore.round(),
      ),
      notificationDetails: _rideAlertDetails(strings),
    );
  }

  Future<void> cancelScoreDrop(String key) =>
      _plugin.cancel(id: scoreDropNotificationId(key));

  /// Controleer of exacte alarmen mogelijk zijn (Android 12+).
  Future<bool> canScheduleExact() async {
    return await _androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  /// Opent de app-instellingen van het systeem, voor permissies die buiten de
  /// app liggen (bijv. POST_NOTIFICATIONS geweigerd). Exacte alarmen hebben een
  /// eigen route, [openExactAlarmSettings].
  Future<void> openSystemSettings() => openAppSettings();

  /// Deep-link naar systeeminstellingen voor exacte alarmen (Android 12+).
  /// Valt terug op openAppSettings() als requestExactAlarmsPermission faalt.
  Future<void> openExactAlarmSettings() async {
    try {
      await _androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {
      await openAppSettings();
    }
  }

  /// Plan "Avond van tevoren" notificatie op 19:00 de dag vóór slotDay.
  /// Slaat over als de geplande tijd in het verleden ligt.
  Future<void> scheduleEveningBefore({
    required DateTime slotDay,
    required String slotTitle,
    required bool exact,
    required S strings,
  }) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      slotDay.year,
      slotDay.month,
      slotDay.day - 1,
      19,
      0,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: kNotifIdEveningBefore,
      title: strings.notifEveningTitle,
      body: strings.notifEveningBody(slotTitle),
      scheduledDate: scheduledDate,
      notificationDetails: _rideAlertDetails(strings),
      androidScheduleMode: _mode(exact),
    );
  }

  /// Plan "Ochtend van de dag" notificatie op slotStart − 2 uur.
  /// Slaat over als de geplande tijd in het verleden ligt.
  Future<void> scheduleMorningOf({
    required DateTime slotStart,
    required String slotTitle,
    required bool exact,
    required S strings,
  }) async {
    final scheduledDate = tz.TZDateTime.from(
      slotStart.subtract(const Duration(hours: 2)),
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: kNotifIdMorningOf,
      title: strings.notifMorningTitle,
      body: strings.notifMorningBody(slotTitle),
      scheduledDate: scheduledDate,
      notificationDetails: _rideAlertDetails(strings),
      androidScheduleMode: _mode(exact),
    );
  }

  /// Plan "Wekelijks overzicht" notificatie op de eerstvolgende zondag 19:00.
  Future<void> scheduleWeeklyDigest({
    required String bodySummary,
    required bool exact,
    required S strings,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    final nextSunday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + (daysUntilSunday == 0 ? 7 : daysUntilSunday),
      19,
      0,
    );

    await _plugin.zonedSchedule(
      id: kNotifIdWeeklyDigest,
      title: strings.notifWeeklyTitle,
      body: bodySummary,
      scheduledDate: nextSunday,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          kChannelWeeklyDigest,
          strings.notifChannelWeeklyDigest,
          channelDescription: strings.notifChannelWeeklyDigestDesc,
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: _mode(exact),
    );
  }

  /// Annuleer alle geplande notificaties (bijv. bij toggle uitzetten).
  Future<void> cancelAll() async => _plugin.cancelAll();

  /// Voer [plans] uit: annuleer wat er stond en plan opnieuw.
  ///
  /// **Waarom eerst de herinneringen annuleren.** De drie meldingen hangen aan het
  /// eerstvolgende beste venster, en dat venster verschuift bij elke nieuwe
  /// voorspelling. Bijwerken-waar-nodig zou bijhouden vergen wat er stond;
  /// opnieuw opbouwen is korter en kan niet uit de pas lopen. Er staan er
  /// hooguit drie.
  ///
  /// [weeklySlotTitle] is het beste venster van de week, of null als er geen is.
  Future<void> applyPlans(
    List<NotificationPlan> plans, {
    required S strings,
    required bool exact,
    String? weeklySlotTitle,
  }) async {
    if (kIsWeb) return;

    // cancelAll zou ook zojuist getoonde scoredalingsmeldingen weghalen.
    for (final id in [
      kNotifIdEveningBefore,
      kNotifIdMorningOf,
      kNotifIdWeeklyDigest,
    ]) {
      await _plugin.cancel(id: id);
    }

    for (final plan in plans) {
      switch (plan) {
        case EveningBeforePlan(:final slotDay, :final slotTitle):
          await scheduleEveningBefore(
            slotDay: slotDay,
            slotTitle: slotTitle,
            exact: exact,
            strings: strings,
          );
        case MorningOfPlan(:final slotStart, :final slotTitle):
          await scheduleMorningOf(
            slotStart: slotStart,
            slotTitle: slotTitle,
            exact: exact,
            strings: strings,
          );
        case WeeklyDigestPlan():
          await scheduleWeeklyDigest(
            bodySummary: weeklySlotTitle == null
                ? strings.notifWeeklyBodyEmpty
                : strings.notifWeeklyBody(weeklySlotTitle),
            exact: exact,
            strings: strings,
          );
      }
    }
  }

  AndroidScheduleMode _mode(bool exact) => exact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexact;

  NotificationDetails _rideAlertDetails(S strings) => NotificationDetails(
        android: AndroidNotificationDetails(
          kChannelRideAlerts,
          strings.notifChannelRideAlerts,
          channelDescription: strings.notifChannelRideAlertsDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
}

/// Stabiel na een herstart en los van de drie vaste herinnerings-id's.
int scoreDropNotificationId(String key) {
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x3fffffff;
  }
  return 20000 + hash;
}

/// Plant de meldingen opnieuw voor het eerstvolgende venster [slot].
///
/// **Gedeeld door voorgrond en achtergrondtaak (#74).** Tot 2026-09-24
/// gebeurde dit alleen op de voorgrond, dus liepen de meldingen leeg zodra
/// iemand de app een paar dagen niet opende. De achtergrondtaak draait elke
/// drie uur en rekent het venster toch al uit voor de widget; nu plant hij
/// ook. Verwacht dat `tz.local` al goed staat -- zie `device_timezone.dart`.
///
/// Roept [NotificationService.init] aan: in de isolate van de achtergrondtaak
/// is de plugin nog niet geïnitialiseerd. Op de voorgrond is het een no-op.
Future<void> rescheduleRideNotifications({
  required UserProfile profile,
  required RideSlot? slot,
  NotificationService? service,
  DateTime? now,
}) async {
  if (kIsWeb) return;
  final notifications = service ?? NotificationService();
  final strings = await S.delegate.load(Locale(profile.locale));
  await notifications.init(strings: strings);
  await notifications.applyPlans(
    planNotifications(
      profile: profile,
      nextSlot: slot,
      now: now ?? DateTime.now(),
    ),
    strings: strings,
    exact: await notifications.canScheduleExact(),
    weeklySlotTitle: slot == null ? null : formatSlotTitle(slot),
  );
}
