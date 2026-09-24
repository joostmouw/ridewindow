// test/features/rides_group_filter_test.dart
//
// Groepschips boven de rittenlijst (CLUB-26, schets 015 variant C).
//
// Wie in meerdere groepen rijdt, wil de lijst per groep kunnen bekijken. Wie
// in geen enkele groep zit, mag er niets van merken: dan staat de rij er niet
// en is de lijst precies zoals hij was.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/peloton/group_crest.dart';
import 'package:ridewindow/features/planned/planned_rides_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';
const _anna = 'uid-anna';

/// Veertig tekens: langer dan een groepsnaam in de praktijk wordt.
const _longName = 'Tour de Waterland Zondagochtend Clubrit';

const _groupMarker = Key('groepsscherm-bereikt');

class _FakePlannedRides extends PlannedRidesNotifier {
  _FakePlannedRides(this._rides);
  final List<PlannedRide> _rides;

  @override
  Future<List<PlannedRide>> build() async => _rides;
}

class _FakeWeather extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => const [];
}

class _FakeProfile extends ProfileNotifier {
  @override
  Future<UserProfile> build() async => const UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 10.0,
          tempMaxIdealC: 30.0,
          windMaxIdealKmh: 25.0,
          rainMaxIdealMm: 1.0,
        ),
        allowedDurations: [2, 3],
        theme: 'system',
        userName: 'Joost',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );
}

PelotonGroup _group(String id, String name) => FakeGroupGateway.group(
      id,
      name,
      members: [
        FakeGroupGateway.member(
          _anna,
          groupId: id,
          role: GroupRole.admin,
          name: 'Anna',
        ),
        FakeGroupGateway.member(_me, groupId: id, name: 'Joost', joinedDay: 1),
      ],
    );

DateTime _day(int offset, int hour) {
  final d = DateTime.now().add(Duration(days: offset));
  return DateTime(d.year, d.month, d.day, hour);
}

GroupRide _ride(String id, String groupId, int dayOffset, {bool mine = false}) =>
    FakeGroupGateway.groupRide(
      id,
      ownerId: mine ? _me : _anna,
      ownerName: mine ? 'Joost' : 'Anna',
      groupId: groupId,
      start: _day(dayOffset, 9),
    );

/// Standaard: Dinsdagclub (g1) met één rit van Anna, On the Roll (g2) met een
/// rit van Anna en een van jou, plus één eigen rit zonder groep.
Future<FakeGroupGateway> _pump(
  WidgetTester tester, {
  Map<String, PelotonGroup>? groups,
  List<GroupRide>? rides,
  double scale = 1.0,
  Brightness brightness = Brightness.light,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final fake = FakeGroupGateway();
  fake.groups.addAll(
    groups ??
        {
          'g1': _group('g1', 'Dinsdagclub'),
          'g2': _group('g2', 'On the Roll'),
        },
  );
  fake.rides.addAll(
    rides ??
        [
          _ride('r-dinsdag', 'g1', 1),
          _ride('r-roll-anna', 'g2', 2),
          _ride('r-roll-mine', 'g2', 3, mine: true),
        ],
  );

  final solo = PlannedRide(
    start: _day(4, 7),
    end: _day(4, 9),
    plannedScore: 61,
  );

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: RidesTab()),
      ),
      GoRoute(
        path: '/detail',
        builder: (_, __) => const Scaffold(body: Text('detail')),
      ),
      GoRoute(
        path: '/peloton/group/:groupId',
        builder: (_, state) => Scaffold(
          body: Text(
            'groep ${state.pathParameters['groupId']}',
            key: _groupMarker,
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pelotonGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue(_me),
        plannedRidesProvider.overrideWith(() => _FakePlannedRides([solo])),
        weatherProvider.overrideWith(_FakeWeather.new),
        profileProvider.overrideWith(_FakeProfile.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: buildAppTheme(brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

Finder _chips() => find.byType(ChoiceChip);

Finder _chip(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip));

List<String> _chipLabels(WidgetTester tester) => [
      for (final e in _chips().evaluate())
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byWidget(e.widget),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data!)
            .where((d) => d.length > 2)
            .join(),
    ];

/// De ritten die de lijst op dit moment toont, op id (`solo` zonder groep).
List<String> _shownRides(WidgetTester tester) => [
      for (final c in tester.widgetList<RideCard>(find.byType(RideCard)))
        c.entry.group?.id ?? 'solo',
    ];

bool _chipSelected(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(_chip(label)).selected;

void main() {
  testWidgets('zonder groepen geen groepschips en de lijst zoals nu',
      (tester) async {
    await _pump(
      tester,
      groups: const {},
      rides: [
        FakeGroupGateway.groupRide(
          'r-shared',
          ownerId: _me,
          ownerName: 'Joost',
          start: _day(1, 9),
        ),
      ],
    );

    expect(_chips(), findsNothing);
    expect(find.byType(GroupCrest), findsNothing);
    expect(_shownRides(tester), ['r-shared', 'solo']);
  });

  testWidgets('zonder groepen door een fout ook geen groepschips',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final fake = await _pump(tester, rides: const []);
    fake.failWith['listGroups'] = GroupError.notAllowed;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RidesTab)),
    );
    container.invalidate(visibleGroupsProvider);
    await tester.pumpAndSettle();

    expect(_chips(), findsNothing);
    expect(_shownRides(tester), ['solo']);
  });

  testWidgets('met groepen: Alles gekozen, dan de groepen in volgorde',
      (tester) async {
    await _pump(tester);

    expect(_chips(), findsNWidgets(3));
    expect(_chipLabels(tester), ['Alles', 'Dinsdagclub', 'On the Roll']);
    expect(_chipSelected(tester, 'Alles'), isTrue);
    expect(_chipSelected(tester, 'Dinsdagclub'), isFalse);
    // Kenteken bij elke groepschip, niet bij Alles.
    expect(
      find.descendant(of: _chips(), matching: find.byType(GroupCrest)),
      findsNWidgets(2),
    );
    expect(
      _shownRides(tester),
      ['r-dinsdag', 'r-roll-anna', 'r-roll-mine', 'solo'],
    );
  });

  testWidgets('een groepschip filtert de lijst, Alles toont weer alles',
      (tester) async {
    await _pump(tester);

    await tester.tap(_chip('On the Roll'));
    await tester.pumpAndSettle();

    expect(_chipSelected(tester, 'On the Roll'), isTrue);
    expect(_chipSelected(tester, 'Alles'), isFalse);
    expect(_shownRides(tester), ['r-roll-anna', 'r-roll-mine']);

    await tester.tap(_chip('Alles'));
    await tester.pumpAndSettle();
    expect(
      _shownRides(tester),
      ['r-dinsdag', 'r-roll-anna', 'r-roll-mine', 'solo'],
    );
  });

  testWidgets('de rolfilterrij telt binnen de gekozen groep', (tester) async {
    await _pump(tester);

    // Alle ritten: 4 in totaal, 2 wachten op jou.
    expect(find.text('Wacht op jou'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await tester.tap(_chip('On the Roll'));
    await tester.pumpAndSettle();

    // Binnen On the Roll: 2 in totaal, 1 wacht, 1 organiseer je.
    expect(find.text('4'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Wacht op jou'), findsOneWidget);
    expect(find.text('Ik organiseer'), findsOneWidget);
    expect(find.text('Alleen ik'), findsNothing);
  });

  testWidgets('een verdwenen groep valt terug op Alles', (tester) async {
    final fake = await _pump(tester);

    await tester.tap(_chip('On the Roll'));
    await tester.pumpAndSettle();
    expect(_shownRides(tester), ['r-roll-anna', 'r-roll-mine']);

    // Je verlaat On the Roll: de groep en zijn ritten zijn weg.
    fake.groups.remove('g2');
    fake.rides.removeWhere((r) => r.groupId == 'g2');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RidesTab)),
    );
    container.invalidate(visibleGroupsProvider);
    container.invalidate(groupRidesProvider);
    await tester.pumpAndSettle();

    expect(_chipLabels(tester), ['Alles', 'Dinsdagclub']);
    expect(_chipSelected(tester, 'Alles'), isTrue);
    expect(_shownRides(tester), ['r-dinsdag', 'solo']);
  });

  testWidgets('een groep zonder ritten zegt dat', (tester) async {
    await _pump(
      tester,
      groups: {
        'g1': _group('g1', 'Dinsdagclub'),
        'g2': _group('g2', 'On the Roll'),
      },
      rides: [_ride('r-dinsdag', 'g1', 1)],
    );

    await tester.tap(_chip('On the Roll'));
    await tester.pumpAndSettle();

    expect(_shownRides(tester), isEmpty);
    expect(find.text('Nog geen ritten van On the Roll'), findsOneWidget);
    // De chips blijven staan, zodat je terug kunt.
    expect(_chips(), findsNWidgets(3));
  });

  testWidgets('lang indrukken op een groepschip opent het groepsscherm',
      (tester) async {
    await _pump(tester);

    await tester.longPress(_chip('On the Roll'));
    await tester.pumpAndSettle();

    expect(find.byKey(_groupMarker), findsOneWidget);
    expect(find.text('groep g2'), findsOneWidget);
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('360 dp, tekst $scale, lange naam: geen overflow en scrollt',
        (tester) async {
      await _pump(
        tester,
        scale: scale,
        groups: {
          'g1': _group('g1', 'Dinsdagclub'),
          'g2': _group('g2', 'On the Roll'),
          'g3': _group('g3', _longName),
        },
      );

      expect(tester.takeException(), isNull);
      expect(_chips(), findsNWidgets(4));

      // De rij is een horizontale lijst, geen Wrap.
      final list = find.ancestor(
        of: _chip('Dinsdagclub'),
        matching: find.byType(ListView),
      );
      expect(
        tester.widget<ListView>(list.first).scrollDirection,
        Axis.horizontal,
      );

      // Elke chip hooguit ~180 dp: de lange naam krijgt een ellips.
      for (final e in _chips().evaluate()) {
        final box = e.renderObject! as RenderBox;
        expect(box.size.width, lessThanOrEqualTo(200));
      }
      final longText = tester.widget<Text>(find.text(_longName));
      expect(longText.maxLines, 1);
      expect(longText.overflow, TextOverflow.ellipsis);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('gekozen chip in de M3-standaardkleur (${brightness.name})',
        (tester) async {
      await _pump(tester, brightness: brightness);
      await tester.tap(_chip('Dinsdagclub'));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(_chip('Dinsdagclub'));
      // Geen eigen kleuren: dan geldt secondaryContainer uit het thema.
      expect(chip.selectedColor, isNull);
      expect(chip.backgroundColor, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
