// test/platform/notification_service_test.dart
// Unit-tests voor NotificationService tijdberekeningen.
// Dekt Phase 8 Plan 05 success criteria (NOTIF-01..06).
//
// Strategie: FakeFlutterLocalNotificationsPlugin registreert zonedSchedule-
// aanroepen zodat tijdberekeningen getest kunnen worden zonder echte plugin.
// flutter_local_notifications 21.x: initialize en zonedSchedule zijn volledig
// named-parameters — override signatures moeten exact overeenkomen.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:ridewindow/platform/notification_service.dart';

// ---------------------------------------------------------------------------
// Fake plugin (v21 API: alle named parameters)
// ---------------------------------------------------------------------------

class FakeFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  /// Sla geplande zonedSchedule-aanroepen op: (id, scheduledDate).
  final List<({int id, tz.TZDateTime scheduledDate})> zonedScheduleCalls = [];

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async =>
      true;

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    zonedScheduleCalls.add((id: id, scheduledDate: scheduledDate));
  }

  @override
  Future<void> cancelAll() async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeFlutterLocalNotificationsPlugin fakePlugin;
  late NotificationService service;

  setUpAll(() {
    tz_data.initializeTimeZones();
    // Gebruik UTC als locale voor tests — tijdberekeningen zijn relatief (morgen/gisteren)
    // en hangen niet af van de specifieke tijdzone.
    tz.setLocalLocation(tz.UTC);
  });

  setUp(() {
    fakePlugin = FakeFlutterLocalNotificationsPlugin();
    service = NotificationService(plugin: fakePlugin);
  });

  group('scheduleEveningBefore', () {
    test('tijdberekening: 19:00 de dag voor slotDay', () async {
      // slotDay = morgen
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final slotDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      await service.scheduleEveningBefore(
        slotDay: slotDay,
        slotTitle: 'Test slot',
        exact: false,
      );

      expect(fakePlugin.zonedScheduleCalls, hasLength(1));
      final scheduled = fakePlugin.zonedScheduleCalls.first.scheduledDate;

      // De geplande datum moet de dag VOOR slotDay zijn (slotDay.day - 1), om 19:00
      expect(scheduled.year, slotDay.year);
      expect(scheduled.month, slotDay.month);
      expect(scheduled.day, slotDay.day - 1);
      expect(scheduled.hour, 19);
      expect(scheduled.minute, 0);
    });

    test('skip als geplande tijd in het verleden ligt (slotDay gisteren)', () async {
      // slotDay = gisteren → scheduledDate (voordag) zou 2 dagen geleden zijn
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final slotDay = DateTime(yesterday.year, yesterday.month, yesterday.day);

      await service.scheduleEveningBefore(
        slotDay: slotDay,
        slotTitle: 'Test slot',
        exact: false,
      );

      // zonedSchedule mag NIET aangeroepen zijn
      expect(fakePlugin.zonedScheduleCalls, isEmpty);
    });
  });

  group('scheduleMorningOf', () {
    test('tijdberekening: slotStart − 2 uur', () async {
      // slotStart = morgen 10:00 UTC — gebruik UTC om consistentie te garanderen
      // ongeacht de systeemtijdzone van de testmachine.
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final slotStart = DateTime.utc(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);

      await service.scheduleMorningOf(
        slotStart: slotStart,
        slotTitle: 'Test slot',
        exact: false,
      );

      expect(fakePlugin.zonedScheduleCalls, hasLength(1));
      final scheduled = fakePlugin.zonedScheduleCalls.first.scheduledDate;

      // TZDateTime.from(slotStart.subtract(2h), tz.UTC) → 08:00 UTC
      expect(scheduled.year, slotStart.year);
      expect(scheduled.month, slotStart.month);
      expect(scheduled.day, slotStart.day);
      expect(scheduled.hour, 8);
      expect(scheduled.minute, 0);
    });
  });

  group('scheduleWeeklyDigest', () {
    test('eerstvolgende zondag 19:00', () async {
      await service.scheduleWeeklyDigest(
        bodySummary: 'Beste rijmomenten van de week',
        exact: false,
      );

      expect(fakePlugin.zonedScheduleCalls, hasLength(1));
      final scheduled = fakePlugin.zonedScheduleCalls.first.scheduledDate;

      // Geplande datum moet een ZONDAG zijn om 19:00
      expect(scheduled.weekday, DateTime.sunday);
      expect(scheduled.hour, 19);
      // Bovendien: de datum moet in de toekomst liggen
      expect(
        scheduled.isAfter(tz.TZDateTime.now(tz.local)),
        isTrue,
        reason: 'Digest moet in de toekomst gepland zijn',
      );
    });
  });
}
