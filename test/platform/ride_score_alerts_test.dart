import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridewindow/data/repositories/ride_score_alert_store.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/watched_ride.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/services/ride_window_scorer.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/platform/notification_service.dart';
import 'package:ridewindow/platform/ride_score_alerts.dart';

class _Scorer extends RideWindowScorer {
  _Scorer(
    this.current, {
    super.tolerances = const WeatherTolerances(),
  }) : super(
          forecasts: [],
          latitude: 52.37,
          longitude: 4.9,
        );
  final double? current;
  @override
  RideSlot? score(DateTime start, DateTime end) => current == null
      ? null
      : RideSlot(
          start: start,
          end: end,
          overallScore: current!,
          tier: rideTierFromScore(current!),
          hours: const [],
        );
}

class _Notifications extends NotificationService {
  bool permitted = true;
  bool fail = false;
  String? failKey;
  final List<({String key, double before, double after, String language})>
      shown = [];
  final List<String> cancelled = [];
  @override
  Future<void> init({required S strings}) async {}
  @override
  Future<bool> areNotificationsEnabled() async => permitted;
  @override
  Future<void> cancelScoreDrop(String key) async => cancelled.add(key);
  @override
  Future<void> showScoreDrop({
    required WatchedRide ride,
    required double previousScore,
    required double currentScore,
    required S strings,
  }) async {
    if (fail || failKey == ride.key) throw StateError('aflevering mislukt');
    shown.add(
      (
        key: ride.key,
        before: previousScore,
        after: currentScore,
        language: strings.localeName
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 1);
  final start = DateTime(2026, 10, 3, 12);
  final ride = WatchedRide(
    key: 'solo',
    start: start,
    end: start.add(const Duration(hours: 2)),
  );
  late SharedPreferences prefs;
  late _Notifications notifications;
  late RideScoreAlerts service;
  setUp(() async {
    SharedPreferences.setMockInitialValues({kScoreDropThresholdKey: 10});
    prefs = await SharedPreferences.getInstance();
    notifications = _Notifications();
    service = RideScoreAlerts(prefs, notifications: notifications);
  });
  Future<void> check(
    double? score, {
    List<WatchedRide>? rides,
    String? owner,
    String locale = 'nl',
    WeatherTolerances tolerances = const WeatherTolerances(),
    bool retainShared = false,
  }) =>
      service.check(
        scorer: _Scorer(score, tolerances: tolerances),
        locale: locale,
        rides: rides ?? [ride],
        owner: owner,
        now: now,
        retainShared: retainShared,
      );

  test('opt-in is standaard uit en de drempel blijft op dit toestel', () async {
    SharedPreferences.setMockInitialValues({});
    final store = RideScoreAlertStore(await SharedPreferences.getInstance());
    expect(store.threshold, 0);
    for (final value in [5, 10, 20, 0]) {
      await store.setThreshold(value);
      expect(store.threshold, value);
    }
    await expectLater(store.setThreshold(7), throwsArgumentError);
  });

  test('eerste controle stelt de vergelijking in, zonder oude waarschuwing',
      () async {
    await check(75);
    expect(notifications.shown, isEmpty);
    expect(RideScoreAlertStore(prefs).read().baselines['solo']['score'], 75);
  });

  test('cumulatieve daling, drempel inclusief, daarna geen herhaling',
      () async {
    await check(90);
    await check(86);
    await check(81);
    expect(notifications.shown, isEmpty);
    await check(80);
    await check(80);
    await check(79);
    expect(notifications.shown, hasLength(1));
    expect(notifications.shown.single.before, 90);
    expect(notifications.shown.single.after, 80);
    await check(70);
    expect(notifications.shown, hasLength(2));
  });

  test('5 en 20 procentpunt worden exact gevolgd, niet als procent', () async {
    for (final threshold in [5, 20]) {
      await RideScoreAlertStore(prefs).setThreshold(threshold);
      await check(60);
      await check(60 - threshold + 0.1);
      final before = notifications.shown.length;
      await check(60 - threshold.toDouble());
      expect(notifications.shown, hasLength(before + 1));
    }
  });

  test('gewijzigde tolerantie en gewijzigde drempel zijn geen nieuw weer',
      () async {
    await check(95);
    final changed = const WeatherTolerances().copyWith(tempMinIdealC: 20);
    await check(60, tolerances: changed);
    expect(notifications.shown, isEmpty);
    await RideScoreAlertStore(prefs).setThreshold(5);
    await check(50, tolerances: changed);
    expect(notifications.shown, isEmpty);
    await check(45, tolerances: changed);
    expect(notifications.shown, hasLength(1));
  });

  test('ontbrekende uren veranderen de vergelijking niet', () async {
    await check(90);
    await check(null);
    expect(notifications.shown, isEmpty);
    await check(80);
    expect(notifications.shown, hasLength(1));
  });

  test('een verzet venster krijgt een nieuwe vergelijking', () async {
    await check(95);
    final moved = WatchedRide(
      key: ride.key,
      start: start.add(const Duration(days: 1)),
      end: ride.end.add(const Duration(days: 1)),
    );
    await check(60, rides: [moved]);
    expect(notifications.shown, isEmpty);
  });

  test('verwijderen, uitzetten en accountwissel halen meldingen weg', () async {
    await check(90, owner: 'a');
    await check(80, owner: 'a');
    await check(60, owner: 'b');
    expect(notifications.shown, hasLength(1));
    expect(notifications.cancelled, contains(ride.key));
    await RideScoreAlertStore(prefs).setThreshold(0);
    await check(30, owner: 'b');
    expect(RideScoreAlertStore(prefs).read().baselines, isEmpty);
    await check(30, rides: [], owner: 'b');
    expect(RideScoreAlertStore(prefs).read().rides, isEmpty);
  });

  test('geen toestemming betekent geen aflevering of achterstallige spam',
      () async {
    await check(90);
    notifications.permitted = false;
    await check(50);
    expect(notifications.shown, isEmpty);
    notifications.permitted = true;
    await check(50);
    expect(notifications.shown, isEmpty);
  });

  test('pluginfout verbruikt de waarschuwing niet', () async {
    await check(90);
    notifications.fail = true;
    await expectLater(check(80), throwsStateError);
    notifications.fail = false;
    await check(80);
    expect(notifications.shown, hasLength(1));
  });

  test('een fout bij rit twee herhaalt de melding voor rit één niet', () async {
    final second = WatchedRide(key: 'two', start: start, end: ride.end);
    await check(90, rides: [ride, second]);
    notifications.failKey = 'two';
    await expectLater(check(80, rides: [ride, second]), throwsStateError);
    notifications.failKey = null;
    await check(80, rides: [ride, second]);
    expect(notifications.shown.map((s) => s.key), ['solo', 'two']);
  });

  test('uitzetten annuleert ook zonder bereikbare weersvoorspelling', () async {
    await check(90);
    await check(80);
    await RideScoreAlertStore(prefs).setThreshold(0);
    await service.disable(locale: 'nl');
    expect(notifications.cancelled, contains('solo'));
    expect(RideScoreAlertStore(prefs).read().baselines, isEmpty);
  });

  test('achtergrond leest dezelfde vergelijking en volgt de app-taal',
      () async {
    await check(90);
    service = RideScoreAlerts(prefs, notifications: notifications);
    await service.check(scorer: _Scorer(80), locale: 'en', now: now);
    expect(notifications.shown.single.language, 'en');
    expect(notifications.shown.single.key, ride.key);
  });

  test('gelijktijdige voorgrondcontroles leveren maar één melding op',
      () async {
    await check(90);
    await Future.wait([check(80), check(80), check(80)]);
    expect(notifications.shown, hasLength(1));
  });

  test('uitnodigingen en afzeggingen worden niet bewaakt', () {
    final entries = [
      for (final role in RideRole.values)
        RideEntry(start: start, end: ride.end, plannedScore: 90, role: role),
    ];
    expect(WatchedRide.fromEntries(entries), hasLength(3));
  });

  test('gedeelde cache blijft bij offline openen, niet bij afzeggen', () async {
    final shared =
        WatchedRide(key: 'shared', start: start, end: ride.end, shared: true);
    await check(90, rides: [shared], owner: 'a');
    await check(90, rides: [], owner: 'a', retainShared: true);
    expect(RideScoreAlertStore(prefs).read().rides.single.key, 'shared');
    await check(90, rides: [], owner: 'a');
    expect(RideScoreAlertStore(prefs).read().rides, isEmpty);
  });

  test('een rit die al gestart is levert geen waarschuwing op', () async {
    await check(90);
    await service.check(
      scorer: _Scorer(40),
      locale: 'nl',
      rides: [ride],
      now: start.add(const Duration(minutes: 1)),
    );
    expect(notifications.shown, isEmpty);
    expect(RideScoreAlertStore(prefs).read().rides, isEmpty);
  });
}
