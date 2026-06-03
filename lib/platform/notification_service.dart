// lib/platform/notification_service.dart
// NotificationService: centraliseert alle notificatie-logica voor RideWindow.
// Geen @riverpod — plain klasse, injecteerbaar voor tests.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// Unieke notificatie-ID's per notificatietype.
const int kNotifIdEveningBefore = 1001;
const int kNotifIdMorningOf = 1002;
const int kNotifIdWeeklyDigest = 1003;

/// Gecentraliseerde notification-service voor RideWindow.
/// Beheert kanaal-registratie, permissies en drie notificatie-schedulers.
class NotificationService {
  static const _channelRideAlerts = AndroidNotificationChannel(
    'ride_alerts',
    'Rijmeldingen',
    description: 'Avond-van-tevoren en ochtend-van-de-dag rijmeldingen',
    importance: Importance.high,
  );

  static const _channelWeeklyDigest = AndroidNotificationChannel(
    'weekly_digest',
    'Wekelijks overzicht',
    description: 'Zondagavond overzicht van de beste rijmomenten',
    importance: Importance.defaultImportance,
  );

  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Initialiseer plugin + maak beide kanalen aan.
  /// Aanroepen in main() na tz.initializeTimeZones().
  Future<void> init() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channelRideAlerts);
    await androidPlugin?.createNotificationChannel(_channelWeeklyDigest);
  }

  /// Vraag POST_NOTIFICATIONS-permissie op (Android 13+).
  /// Geeft true terug als permissie verleend is.
  Future<bool> requestPostNotificationsPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Controleer of exacte alarmen mogelijk zijn (Android 12+).
  Future<bool> canScheduleExact() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  /// Deep-link naar systeeminstellingen voor exacte alarmen (Android 12+).
  /// Valt terug op openAppSettings() als requestExactAlarmsPermission faalt.
  Future<void> openExactAlarmSettings() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidPlugin?.requestExactAlarmsPermission();
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

    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexact;

    await _plugin.zonedSchedule(
      id: kNotifIdEveningBefore,
      title: 'Top rijmoment morgen!',
      body: '$slotTitle — perfecte omstandigheden verwacht',
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelRideAlerts.id,
          _channelRideAlerts.name,
          channelDescription: _channelRideAlerts.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: mode,
    );
  }

  /// Plan "Ochtend van de dag" notificatie op slotStart − 2 uur.
  /// Slaat over als de geplande tijd in het verleden ligt.
  Future<void> scheduleMorningOf({
    required DateTime slotStart,
    required String slotTitle,
    required bool exact,
  }) async {
    final scheduledDate = tz.TZDateTime.from(
      slotStart.subtract(const Duration(hours: 2)),
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexact;

    await _plugin.zonedSchedule(
      id: kNotifIdMorningOf,
      title: 'Over 2 uur een top rijmoment!',
      body: '$slotTitle — maak je klaar om te rijden',
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelRideAlerts.id,
          _channelRideAlerts.name,
          channelDescription: _channelRideAlerts.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: mode,
    );
  }

  /// Plan "Wekelijks overzicht" notificatie op de eerstvolgende zondag 19:00.
  Future<void> scheduleWeeklyDigest({
    required String bodySummary,
    required bool exact,
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

    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexact;

    await _plugin.zonedSchedule(
      id: kNotifIdWeeklyDigest,
      title: 'Je rijoverzicht voor deze week',
      body: bodySummary,
      scheduledDate: nextSunday,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelWeeklyDigest.id,
          _channelWeeklyDigest.name,
          channelDescription: _channelWeeklyDigest.description,
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: mode,
    );
  }

  /// Annuleer alle geplande notificaties (bijv. bij toggle uitzetten).
  Future<void> cancelAll() async => _plugin.cancelAll();
}
