// Wat backlog #60 mogelijk maakt: dít is de dekking die fase 21 niet had.
//
// Fase 21 kostte vijf gap-closure-plannen (21-10 t/m 21-14) en élk defect werd
// op een toestel gevonden. Niet omdat de tests slecht waren, maar omdat ze op
// één na buitenste laag stopten: 21-10 toetste dát de aanroep bestond, 21-11 of
// die zijn werk bereikte, 21-12 of de payload een legale rij was. Wát de
// cloudkant deed was principieel onwaarneembaar, want `CloudSyncReconciler`
// greep in zijn eigen methodebody naar `Supabase.instance.client`.
//
// Sinds backlog #60 loopt die kant door [CloudSyncGateway] en is hij
// vervangbaar. Deze test legt daarom de dingen vast die tot nu toe alleen een
// toestelsessie kon zien:
//
//  1. **Duwen vóór trekken** (plan 21-14). De outbox draagt de *intentie* van de
//     gebruiker, de cloud de laatst *overeengekomen* stand. Lees je de cloud
//     eerst, dan gooi je de intentie weg -- een verwijderde rit staat in de
//     cloud nog te wachten, de union-merge zet hem lokaal terug, en de volgende
//     cyclus pusht hem weer omhoog. Waargenomen op 2026-08-05: handmatig
//     verwijderde ritten kwamen bij elke sync terug.
//  2. **Twee drains per cyclus** (plan 21-14), want de merge enqueuet zelf.
//  3. **De opstart-reconcile leest werkelijk** (backlog #61), één keer per uid.
//  4. **De reparatie van niet-canonieke `ride_id`'s** (plan 21-13) -- op een echt
//     toestel niet meer uit te lokken, want die rijen bestaan nergens meer. Dat
//     staat in REGRESSION-CHECKLIST-21.md §5b als permanent open vinkje. Hier
//     kan het wél.
//
// De volgorde-assertie is de kern: die faalt zodra iemand `drainOutbox()` onder
// de cloudlezing schuift, en dat is precies de wijziging die er onschuldig
// uitziet.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/cloud_sync_reconciler_provider.dart';
import 'package:ridewindow/services/cloud_sync_gateway.dart';
import 'package:ridewindow/services/sync_outbox_service.dart';

User _fakeUser(String id) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-09-01T00:00:00.000Z',
      email: '$id@example.com',
    );

/// Eén gedeeld logboek voor gateway én outbox, zodat de *volgorde* tussen de
/// twee toetsbaar is. Twee losse tellers zouden elk apart kloppen terwijl de
/// bug juist in hun onderlinge volgorde zit -- dat is letterlijk plan 21-14.
class _Log {
  final events = <String>[];
  void add(String event) => events.add(event);
}

class _FakeGateway implements CloudSyncGateway {
  _FakeGateway(this._log, {this.plannedRows = const []});

  final _Log _log;

  /// Wat `planned_rides` teruggeeft. Default leeg, zodat de merge niets te doen
  /// heeft en de test over volgorde gaat en niet over merge-gedrag.
  List<Map<String, dynamic>> plannedRows;

  final deletedRideIds = <String>[];

  @override
  String? currentSessionUserId() {
    _log.add('currentSessionUserId');
    return null;
  }

  @override
  Future<Map<String, dynamic>?> readProfileRow(String userId) async {
    _log.add('readProfileRow');
    return null;
  }

  @override
  Future<Map<String, dynamic>?> readAvailabilityRow(String userId) async {
    _log.add('readAvailabilityRow');
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> readPlannedRideRows(String userId) async {
    _log.add('readPlannedRideRows');
    return plannedRows;
  }

  @override
  Future<void> upsertRow(String table, Map<String, dynamic> payload) async {
    _log.add('upsertRow:$table');
  }

  @override
  Future<void> deletePlannedRide({
    required String userId,
    required String rideId,
  }) async {
    _log.add('deletePlannedRide');
    deletedRideIds.add(rideId);
  }
}

/// Logt de drain in hetzelfde logboek. De superclass-constructor wil een echte
/// [SyncOutboxDao], maar die wordt nooit aangeraakt -- `drain()` is volledig
/// overschreven.
class _LoggingSyncOutboxService extends SyncOutboxService {
  _LoggingSyncOutboxService(super.dao, this._log);

  final _Log _log;

  @override
  Future<void> drain({
    required Future<void> Function(
      String entity,
      String entityKey,
      Map<String, dynamic> payload,
    ) upsertFn,
    required Future<void> Function(String entity, String entityKey) deleteFn,
  }) async {
    _log.add('drain');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _Log log;
  late _LoggingSyncOutboxService outbox;
  late _FakeGateway gateway;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    log = _Log();
    outbox = _LoggingSyncOutboxService(db.syncOutboxDao, log);
    gateway = _FakeGateway(log);
  });

  tearDown(() async {
    await db.close();
  });

  /// De listener op `authStateProvider` is geen ceremonie: zonder hem
  /// abonneert de StreamProvider zich nooit op zijn bron en blijft hij
  /// `AsyncLoading` (gemeten in `startup_reconcile_wiring_test.dart`).
  ProviderContainer containerFor(Stream<User?> authStream) {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => authStream),
        syncOutboxServiceProvider.overrideWith((ref) => outbox),
        appDatabaseProvider.overrideWith((ref) => db),
        // De echte provider, met alleen de cloudkant vervangen. Zo houdt de
        // reconciler de `Ref` die hij in productie ook krijgt -- inclusief
        // `keepAlive`, waar plan 21-11 een dag aan besteed heeft.
        cloudSyncReconcilerProvider.overrideWith(
          (ref) => CloudSyncReconciler(ref, gateway: gateway),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(authStateProvider, (_, __) {});
    addTearDown(sub.close);
    return container;
  }

  CloudSyncReconciler reconcilerIn(ProviderContainer container) =>
      container.read(cloudSyncReconcilerProvider);

  group('reconcileOnForeground() -- volgorde (plan 21-14)', () {
    test(
      'duwt vóór het trekt: de drain komt vóór de eerste cloudlezing, anders '
      'wekt de merge een zojuist verwijderde rit weer op',
      () async {
        final container = containerFor(
          Stream<User?>.value(_fakeUser('u-1')),
        );
        final reconciler = reconcilerIn(container);
        await Future<void>.delayed(Duration.zero);

        await reconciler.reconcileOnForeground();

        final firstDrain = log.events.indexOf('drain');
        final firstRead = log.events.indexOf('readProfileRow');

        expect(firstDrain, greaterThanOrEqualTo(0),
            reason: 'Er moet überhaupt gedraind worden.');
        expect(firstRead, greaterThanOrEqualTo(0),
            reason: 'Er moet überhaupt uit de cloud gelezen worden. Is dit -1, '
                'dan is de gateway niet bereikt en meet deze test niets.');
        expect(
          firstDrain,
          lessThan(firstRead),
          reason: 'De outbox draagt de intentie van de gebruiker, de cloud de '
              'laatst overeengekomen stand. Leest de reconcile eerst, dan '
              'zet de union-merge een zojuist verwijderde rit terug en pusht '
              'de volgende cyclus hem weer omhoog -- op 2026-08-05 op een '
              'toestel waargenomen, gedicht door plan 21-14.',
        );
      },
    );

    test(
      'draint twee keer per cyclus -- de merge enqueuet zelf, en zonder de '
      'tweede drain wacht dat een hele cyclus',
      () async {
        final container = containerFor(Stream<User?>.value(_fakeUser('u-1')));
        final reconciler = reconcilerIn(container);
        await Future<void>.delayed(Duration.zero);

        await reconciler.reconcileOnForeground();

        expect(
          log.events.where((e) => e == 'drain').length,
          2,
          reason: 'Eén drain vóór de reconcile, één erna voor wat de merge '
              'enqueuet (plan 21-14).',
        );
      },
    );

    test(
      'leest alle drie de bronnen -- profile, availability én planned_rides',
      () async {
        final container = containerFor(Stream<User?>.value(_fakeUser('u-1')));
        final reconciler = reconcilerIn(container);
        await Future<void>.delayed(Duration.zero);

        await reconciler.reconcileOnForeground();

        expect(
          log.events,
          containsAllInOrder(
            ['readProfileRow', 'readAvailabilityRow', 'readPlannedRideRows'],
          ),
          reason: 'Ontbreekt planned_rides, dan is dat backlog #61 opnieuw: '
              'ritten komen dan van geen enkel pad binnen.',
        );
      },
    );

    test('uitgelogd leest niet, maar draint wél -- een uitgelogde outbox mag '
        'niet blijven staan', () async {
      final auth = StreamController<User?>.broadcast();
      addTearDown(auth.close);
      final container = containerFor(auth.stream);
      final reconciler = reconcilerIn(container);
      auth.add(null);
      await Future<void>.delayed(Duration.zero);

      await reconciler.reconcileOnForeground();

      expect(log.events.contains('readProfileRow'), isFalse,
          reason: 'Uitgelogd is er niets om op te halen.');
      expect(log.events.contains('drain'), isTrue,
          reason: 'De drain staat bewust vóór de uitgelogd-check.');
    });
  });

  group('reconcileOnStartup() (backlog #61)', () {
    test(
      'leest werkelijk uit de cloud bij het opstarten -- niet alleen "de '
      'methode is aangeroepen"',
      () async {
        final container = containerFor(Stream<User?>.value(_fakeUser('u-1')));
        final reconciler = reconcilerIn(container);
        await Future<void>.delayed(Duration.zero);

        await reconciler.reconcileOnStartup();

        expect(
          log.events.contains('readPlannedRideRows'),
          isTrue,
          reason: 'Dít is wat vóór backlog #60 niet te meten viel: de oude test '
              'kon alleen zien dát er gedraind werd, niet dat de cloudlezing '
              'gebeurde. Een verse installatie toonde daardoor een lege '
              'PLANNED-lijst tot de app eenmaal weggezet was.',
        );
      },
    );

    test('draait één keer per uid per app-start', () async {
      final container = containerFor(Stream<User?>.value(_fakeUser('u-1')));
      final reconciler = reconcilerIn(container);
      await Future<void>.delayed(Duration.zero);

      await reconciler.reconcileOnStartup();
      final afterFirst = log.events.length;
      await reconciler.reconcileOnStartup();

      expect(log.events.length, afterFirst,
          reason: 'Anders betaalt elke navigatie naar Home een volledige '
              'cloud-rondgang.');
    });
  });

  group('niet-canonieke ride_id wordt gerepareerd (plan 21-13)', () {
    test(
      'een rij waarvan de sleutel niet bij zijn eigen start_at hoort, wordt '
      'uit de cloud verwijderd',
      () async {
        // Zo zag een rij van vóór 21-13 eruit: `ride_id` afgeleid van de lokale
        // ISO-string, terwijl `start_at` als UTC terugkomt. Sleutel en tijdstip
        // spreken elkaar dus tegen.
        gateway.plannedRows = [
          {
            'user_id': 'u-1',
            'ride_id': '2026-09-05T12-00-00-000',
            'start_at': '2026-09-05T10:00:00.000Z',
            'end_at': '2026-09-05T13:00:00.000Z',
            'planned_score': 92.0,
          },
        ];

        final container = containerFor(Stream<User?>.value(_fakeUser('u-1')));
        final reconciler = reconcilerIn(container);
        await Future<void>.delayed(Duration.zero);

        await reconciler.reconcileOnForeground();

        expect(
          gateway.deletedRideIds,
          contains('2026-09-05T12-00-00-000'),
          reason: 'Blijft deze rij staan, dan komt hij bij elke pull terug als '
              'extra kopie -- de duplicaatbug van 21-13. Dit pad is op een '
              'echt toestel niet meer uit te lokken (die rijen bestaan '
              'nergens meer), dus dit is de enige plek waar het nog vastligt.',
        );
      },
    );

    test('een canonieke rij wordt met rust gelaten', () async {
      // Zelfde rit, nu mét de sleutel die uit zijn eigen start_at volgt.
      gateway.plannedRows = [
        {
          'user_id': 'u-1',
          'ride_id': '2026-09-05T10-00-00-000Z',
          'start_at': '2026-09-05T10:00:00.000Z',
          'end_at': '2026-09-05T13:00:00.000Z',
          'planned_score': 92.0,
        },
      ];

      final container = containerFor(Stream<User?>.value(_fakeUser('u-1')));
      final reconciler = reconcilerIn(container);
      await Future<void>.delayed(Duration.zero);

      await reconciler.reconcileOnForeground();

      expect(
        gateway.deletedRideIds,
        isEmpty,
        reason: 'De reparatie mag alleen aanslaan op rijen die werkelijk '
            'verkeerd gesleuteld zijn. Slaat hij breder aan, dan verwijdert '
            'een gewone voorgrondcyclus geplande ritten uit de cloud.',
      );
    });
  });
}
