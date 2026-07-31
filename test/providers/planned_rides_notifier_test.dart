import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/data/repositories/planned_rides_repository.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';

User _fakeUser(String id) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: '$id@example.com',
    );

Future<void> _seed(List<PlannedRide> rides) async {
  final prefs = await SharedPreferences.getInstance();
  final repo = PlannedRidesRepository(prefs);
  await repo.save(rides);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group(
      'PlannedRidesNotifier — D-10: vorige lijst blijft zichtbaar tijdens auth-gedreven herlaad',
      () {
    test(
        'D-10: geen enkele toestand in de listener-historie heeft .value == null nadat de eerste data er was, '
        'en elke loading-toestand draagt nog steeds de laatst bekende lijst mee via .value',
        () async {
      final now = DateTime.now();
      final future = now.add(const Duration(days: 1));
      final futureEnd = future.add(const Duration(hours: 2));
      await _seed([
        PlannedRide(start: future, end: futureEnd, plannedScore: 80.0),
      ]);

      final authController = StreamController<User?>.broadcast();
      addTearDown(authController.close);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => authController.stream),
        ],
      );
      addTearDown(container.dispose);

      // Initiële lijst is niet leeg.
      final initial = await container.read(plannedRidesProvider.future);
      expect(initial, isNotEmpty);

      final history = <AsyncValue<List<PlannedRide>>>[];
      container.listen<AsyncValue<List<PlannedRide>>>(
        plannedRidesProvider,
        (prev, next) => history.add(next),
        fireImmediately: true,
      );

      // Stuur een nieuwe gebruiker door de auth-stream (accountwissel-trigger).
      authController.add(_fakeUser('user-1'));
      // Wacht tot de rebuild is verwerkt.
      await container.read(plannedRidesProvider.future);
      await Future<void>.delayed(Duration.zero);

      // Bewijs dat de auth-wissel daadwerkelijk een herbouw veroorzaakte —
      // zonder dit zou de rest van deze test triviaal slagen op een lege
      // geschiedenis.
      expect(
        history.length,
        greaterThan(1),
        reason:
            'de auth-stream-emissie moet minstens één extra toestand hebben opgeleverd',
      );

      // D-10: zodra er ooit data was, mag .value nooit meer null zijn — ook
      // niet tijdens een tussenliggende AsyncLoading.
      final afterFirstData = history.skipWhile((s) => !s.hasValue).toList();
      expect(afterFirstData, isNotEmpty);
      for (final state in afterFirstData) {
        expect(
          state.value,
          isNotNull,
          reason:
              'D-10: vorige lijst mag nooit wegvallen tijdens een auth-gedreven herlaad',
        );
      }

      // Elke loading-toestand na de eerste data draagt de laatst bekende lijst mee.
      final loadingStatesAfterData =
          afterFirstData.where((s) => s.isLoading).toList();
      expect(
        loadingStatesAfterData,
        isNotEmpty,
        reason:
            'de auth-gedreven herbouw moet minstens één AsyncLoading-tussenstap hebben doorlopen',
      );
      for (final loading in loadingStatesAfterData) {
        expect(
          loading.value,
          isNotEmpty,
          reason:
              'D-10: een AsyncLoading tijdens een auth-gedreven herlaad moet nog steeds de vorige lijst dragen',
        );
      }
    });

    test(
        'een nieuwe auth-toestand triggert daadwerkelijk een herlezing van de repository',
        () async {
      final now = DateTime.now();
      final future1 = now.add(const Duration(days: 1));
      await _seed([
        PlannedRide(
          start: future1,
          end: future1.add(const Duration(hours: 2)),
          plannedScore: 40.0,
        ),
      ]);

      final authController = StreamController<User?>.broadcast();
      addTearDown(authController.close);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => authController.stream),
        ],
      );
      addTearDown(container.dispose);

      // Een actieve listener (zoals een echte Consumer-widget die zou
      // hebben) zorgt dat de provider direct herbouwt zodra authStateProvider
      // wijzigt, in plaats van pas lui bij een volgende read.
      container.listen(plannedRidesProvider, (prev, next) {});

      final first = await container.read(plannedRidesProvider.future);
      expect(first.length, 1);
      expect(first.first.plannedScore, 40.0);

      // Verander de onderliggende opslag tussen twee auth-events.
      final future2 = now.add(const Duration(days: 2));
      await _seed([
        PlannedRide(
          start: future1,
          end: future1.add(const Duration(hours: 2)),
          plannedScore: 40.0,
        ),
        PlannedRide(
          start: future2,
          end: future2.add(const Duration(hours: 2)),
          plannedScore: 65.0,
        ),
      ]);

      authController.add(_fakeUser('user-2'));
      // Geef de event-loop de kans om het stream-event te bezorgen voordat
      // .future opnieuw wordt opgevraagd — anders pakt .read(...future) de
      // al-afgeronde vorige build in plaats van de nieuwe rebuild.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final second = await container.read(plannedRidesProvider.future);

      expect(second.length, 2);
    });
  });
}
