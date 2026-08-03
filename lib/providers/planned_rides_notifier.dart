import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/planned_rides_repository.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';

export 'package:ridewindow/domain/models/planned_ride.dart' show PlannedRide;

part 'planned_rides_notifier.g.dart';

/// Construeert de [PlannedRidesRepository]. Gebruikt bewust `getInstance()`
/// (asynchroon), niet de app-brede prefs-provider hieronder — die gooit
/// `UnimplementedError` tenzij overschreven, en de bestaande
/// planned-rides-tests leunen allemaal op
/// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.
///
/// `outbox`/`userId` zijn additief (ARCHITECTURE.md §4a), zelfde patroon als
/// `profileRepositoryProvider`/`availabilityRepositoryProvider` (plan 21-04).
@riverpod
Future<PlannedRidesRepository> plannedRidesRepository(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final outbox = ref.watch(appDatabaseProvider).syncOutboxDao;
  return PlannedRidesRepository(
    await SharedPreferences.getInstance(),
    outbox: outbox,
    userId: userId,
  );
}

@Riverpod(keepAlive: true)
class PlannedRidesNotifier extends _$PlannedRidesNotifier {
  @override
  Future<List<PlannedRide>> build() async {
    // D-11-reactiviteitstrigger: elke wijziging in authStateProvider (in-/
    // uitloggen, accountwissel) veroorzaakt een lokale herlezing. De waarde
    // zelf is hier niet nodig — het cloud-pad loopt via
    // plannedRidesRepositoryProvider's eigen currentUserIdProvider-watch.
    ref.watch(authStateProvider);
    final repo = await ref.watch(plannedRidesRepositoryProvider.future);
    return repo.readLocal();
  }

  Future<void> add(PlannedRide ride) async {
    final repo = await ref.read(plannedRidesRepositoryProvider.future);
    await repo.add(ride);
    state = AsyncData(repo.readLocal());
  }

  Future<void> remove(PlannedRide ride) async {
    final repo = await ref.read(plannedRidesRepositoryProvider.future);
    await repo.remove(ride);
    state = AsyncData(repo.readLocal());
  }

  /// Wist alle geplande ritten (D-09: "start fresh" bij accountwissel).
  /// Dit wist uitsluitend lokaal — er wordt geen cloud-aanroep gedaan (D-11).
  Future<void> clearAll() async {
    final repo = await ref.read(plannedRidesRepositoryProvider.future);
    await repo.save(const <PlannedRide>[]);
    state = const AsyncData(<PlannedRide>[]);
  }
}
