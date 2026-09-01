// Regressiedekking voor backlog #61, waargenomen op een verse
// WebAPK-installatie op 2026-08-07 (zie
// .planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md, device session
// 7): een ingelogde gebruiker met lege lokale opslag zag een lege
// PLANNED-lijst tot hij de app eenmaal wegzette.
//
// De oorzaak was een ontbrekend pad, niet een kapot pad. `reconcileOnForeground()`
// had precies één productie-aanroep -- `home_screen.dart`'s
// `didChangeAppLifecycleState` op `resumed` -- en die vuurt niet bij het
// opstarten. Bij een normale login staat `lastSyncedUid` al, dus de
// eerste-login-migratie draait ook niet. Er las dus niets uit de cloud tussen
// het starten van de app en de eerste achtergrond→voorgrond-cyclus in.
//
// Dat is dezelfde vorm als de SYNC-05-bevinding die
// `outbox_drain_wiring_test.dart` bewaakt: de aangeroepen code was correct, er
// was alleen geen aanroeper. Deze test bewaakt daarom hetzelfde soort feit --
// dát het opstartpad bestaat en zijn werk bereikt -- in dezelfde stijl:
// een `ProviderContainer` met een bare `container.read`, een echte
// event-loop-onderbreking, en een `_RecordingSyncOutboxService` op de
// `syncOutboxServiceProvider`-seam.
//
// **Wat deze test bewust NIET bewijst.** Dat de cloud-lezing zelf slaagt.
// `CloudSyncReconciler` grijpt in zijn methodebody rechtstreeks naar
// `Supabase.instance.client`, dus zonder levende backend is de leeskant van
// buitenaf niet waarneembaar -- in deze suite gooit die lezing (Supabase is
// hier nooit geïnitialiseerd) en wordt door `reconcileOnForeground()`'s eigen
// try/catch opgevangen. De drain vóór die lezing is dan het waarneembare
// bewijs dat de methode überhaupt gedraaid heeft. Backlog #60
// (`CloudSyncReconciler` injecteerbaar maken) is de ingreep die dit echt
// testbaar maakt; tot die tijd staat de beperking hier expliciet in plaats van
// stilzwijgend.
import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/cloud_sync_reconciler_provider.dart';
import 'package:ridewindow/services/sync_outbox_service.dart';

User _fakeUser(String id) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-09-01T00:00:00.000Z',
      email: '$id@example.com',
    );

/// Zelfde `_stripComments` als in `outbox_drain_wiring_test.dart`: zonder dit
/// zou een doc-comment die de aanroep beschrijft de structurele assertie in
/// leven houden nadat de echte aanroep verwijderd is.
String _stripComments(String source) {
  final withoutBlockComments =
      source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  final lines = withoutBlockComments.split('\n');
  return lines.map((line) {
    final index = line.indexOf('//');
    return index == -1 ? line : line.substring(0, index);
  }).join('\n');
}

/// Telt drains zonder werk te doen. De superclass-constructor wil een echte
/// [SyncOutboxDao], maar die wordt nooit aangeraakt -- `drain()` is volledig
/// overschreven.
class _CountingSyncOutboxService extends SyncOutboxService {
  _CountingSyncOutboxService(super.dao);

  int drainCount = 0;

  @override
  Future<void> drain({
    required Future<void> Function(
      String entity,
      String entityKey,
      Map<String, dynamic> payload,
    ) upsertFn,
    required Future<void> Function(String entity, String entityKey) deleteFn,
  }) async {
    drainCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // De meting waar reconcileOnStartup()'s eigen abonnement op rust. Zonder
  // deze test leest de volgende lezer dat abonnement als overbodige ceremonie
  // en haalt het weg -- waarna de opstart-reconcile stilletjes nooit meer
  // draait, precies de faalvorm die deze fase vijf keer heeft opgeleverd.
  group('authStateProvider heeft een listener nodig om te bestaan', () {
    test(
      'zonder listener lost .future nooit op; met listener meteen',
      () async {
        final container = ProviderContainer(
          overrides: [
            authStateProvider
                .overrideWith((ref) => Stream<User?>.value(_fakeUser('u-1'))),
          ],
        );
        addTearDown(container.dispose);

        var resolvedWithoutListener = false;
        unawaited(
          container
              .read(authStateProvider.future)
              .then((_) => resolvedWithoutListener = true),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          resolvedWithoutListener,
          isFalse,
          reason: 'Een StreamProvider abonneert zich pas op zijn bron zodra '
              'iemand luistert. Lost dit ooit wél op zonder listener, dan mag '
              'reconcileOnStartup() zijn eigen abonnement laten vallen.',
        );

        final sub = container.listen(authStateProvider, (_, __) {});
        addTearDown(sub.close);

        final user = await container.read(authStateProvider.future);
        expect(user?.id, 'u-1');
      },
    );
  });

  group('reconcileOnStartup() (backlog #61)', () {
    late AppDatabase db;
    late _CountingSyncOutboxService outbox;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      outbox = _CountingSyncOutboxService(db.syncOutboxDao);
      // De cloud-lezing gooit hier gegarandeerd (Supabase is niet
      // geïnitialiseerd) en wordt intern gelogd; die ruis hoort niet in de
      // testuitvoer thuis.
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {};
      addTearDown(() => debugPrint = original);
    });

    tearDown(() async {
      await db.close();
    });

    /// De listener op `authStateProvider` is geen testceremonie: zonder hem
    /// abonneert de StreamProvider zich nooit op zijn bron en blijft hij
    /// `AsyncLoading` (zie de groep hierboven). In de app houdt de widgetboom
    /// die listener; hier moet de test dat zelf doen, want `Supabase.instance`
    /// -- de terugval die `_signedInUser()` in productie gebruikt -- is in deze
    /// suite niet geïnitialiseerd.
    ProviderContainer containerFor(Stream<User?> authStream) {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => authStream),
          syncOutboxServiceProvider.overrideWith((ref) => outbox),
          appDatabaseProvider.overrideWith((ref) => db),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(authStateProvider, (_, __) {});
      addTearDown(sub.close);
      return container;
    }

    test(
      'een ingelogde gebruiker krijgt bij het opstarten een reconcile -- '
      'zonder dit pad hangt de pull volledig aan een achtergrond→voorgrond-'
      'cyclus en ziet een verse installatie een lege PLANNED-lijst',
      () async {
        final container = containerFor(Stream<User?>.value(_fakeUser('u-1')));

        // Bare read, exact de vorm die `HomeScreen.initState` gebruikt.
        final reconciler = container.read(cloudSyncReconcilerProvider);
        await Future<void>.delayed(Duration.zero);

        await reconciler.reconcileOnStartup();

        expect(
          outbox.drainCount,
          greaterThan(0),
          reason: 'reconcileOnStartup() moet reconcileOnForeground() bereiken. '
              'Is dit 0, dan bestaat het opstartpad niet meer en is backlog '
              '#61 terug: een verse installatie toont pas ritten nadat de '
              'gebruiker de app eenmaal heeft weggezet.',
        );
      },
    );

    test(
      'een tweede aanroep binnen dezelfde app-start doet niets -- opnieuw naar '
      'Home navigeren mag geen volledige reconcile kosten',
      () async {
        final container = containerFor(Stream<User?>.value(_fakeUser('u-1')));
        final reconciler = container.read(cloudSyncReconcilerProvider);
        await Future<void>.delayed(Duration.zero);

        await reconciler.reconcileOnStartup();
        final afterFirst = outbox.drainCount;
        await reconciler.reconcileOnStartup();

        expect(
          outbox.drainCount,
          afterFirst,
          reason: 'De one-shot-guard is per account per app-start. Loopt de '
              'reconcile bij elke HomeScreen-opbouw, dan betaalt elke '
              'navigatie een volledige cloud-rondgang.',
        );
      },
    );

    test(
      'uitgelogd reconcilet niet, en zet de guard ook niet vast -- inloggen na '
      'een uitgelogde start moet alsnog een reconcile opleveren',
      () async {
        final auth = StreamController<User?>.broadcast();
        addTearDown(auth.close);
        final container = containerFor(auth.stream);
        final reconciler = container.read(cloudSyncReconcilerProvider);
        await Future<void>.delayed(Duration.zero);

        auth.add(null);
        await Future<void>.delayed(Duration.zero);
        await reconciler.reconcileOnStartup();

        expect(
          outbox.drainCount,
          0,
          reason: 'Uitgelogd is er niets om op te halen.',
        );

        auth.add(_fakeUser('u-1'));
        await Future<void>.delayed(Duration.zero);
        await reconciler.reconcileOnStartup();

        expect(
          outbox.drainCount,
          greaterThan(0),
          reason: 'De guard mag niet dichtslaan op de uitgelogde ronde -- dan '
              'zou een gebruiker die de app opent, daarna inlogt en terugkeert '
              'naar Home nog steeds een lege lijst zien. Dat is dezelfde bug '
              'in een andere volgorde.',
        );
      },
    );
  });

  test(
    'HomeScreen.initState roept reconcileOnStartup() aan -- de aanroep moet in '
    'initState staan, niet alleen in de lifecycle-callback',
    () {
      final source = _stripComments(
        File('lib/features/home/home_screen.dart').readAsStringSync(),
      );

      final start = source.indexOf('void initState()');
      expect(start, greaterThan(-1), reason: 'initState() moet bestaan');
      final end = source.indexOf('void dispose()', start);
      expect(end, greaterThan(start), reason: 'dispose() volgt op initState()');

      expect(
        source.substring(start, end).contains('reconcileOnStartup()'),
        isTrue,
        reason: 'Zonder deze aanroep in initState leest niets uit de cloud '
            'tussen het starten van de app en de eerste achtergrond→'
            'voorgrond-cyclus in (backlog #61).',
      );
    },
  );

  test(
    'de inlogflow reconcilet, niet alleen drainen -- AccountSyncService dekt '
    'profile en availability, nooit planned_rides',
    () {
      final source = _stripComments(
        File('lib/features/profile/account_section.dart').readAsStringSync(),
      );

      expect(
        source.contains('reconcileOnForeground()'),
        isTrue,
        reason: 'Een kale drainOutbox() na het inloggen laat geplande ritten '
            'ongemoeid: onSignIn() behandelt alleen profile en availability, '
            'en de eerste-login-migratie pusht (lokaal → cloud) in plaats van '
            'te trekken. Een verse inlog op een tweede toestel haalt zijn '
            'ritten dan nooit op -- backlog #61 langs de andere route. '
            'reconcileOnForeground() begint zelf met een drain, dus 21-10\'s '
            'garantie blijft staan.',
      );
    },
  );
}
