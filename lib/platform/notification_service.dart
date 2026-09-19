// lib/platform/notification_service.dart
// NotificationService: centraliseert alle notificatie-logica voor Ridewindow.
// Geen @riverpod — plain klasse, injecteerbaar voor tests.
//
// Alle gebruikerszichtbare tekst komt uit `S` (backlog #67). De service heeft
// geen BuildContext, dus de aanroeper levert de geladen `S` aan: vanuit een
// scherm met `S.of(context)`, vanuit main.dart met `S.delegate.load(locale)`.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

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

  /// Controleer of exacte alarmen mogelijk zijn (Android 12+).
  Future<bool> canScheduleExact() async {
    return await _androidPlugin?.canScheduleExactNotifications() ?? false;
  }

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
