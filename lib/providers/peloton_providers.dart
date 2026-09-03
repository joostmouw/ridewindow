import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/services/peloton_gateway.dart';

part 'peloton_providers.g.dart';

/// De poort naar de Peloton-tabellen. Eigen provider zodat een test hem kan
/// overriden met een fake — dezelfde naad als `syncOutboxServiceProvider`.
@Riverpod(keepAlive: true)
PelotonGateway pelotonGateway(Ref ref) => const SupabasePelotonGateway();

/// Je maatjes. Leeg (en niet fout) als je uitgelogd bent: Peloton is additief,
/// een uitgelogde gebruiker merkt van het hele epic niets — dat is dezelfde
/// eis als REQUIREMENTS.md regel 8 voor accounts zelf.
@riverpod
Future<List<Friend>> friends(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(pelotonGatewayProvider).listFriends();
}

/// Alle gedeelde ritten die je mag zien. Welke dat zijn bepaalt RLS, niet deze
/// code — de query vraagt bewust alles op.
@riverpod
Future<List<GroupRide>> groupRides(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(pelotonGatewayProvider).listGroupRides();
}

/// Ritten waarvoor jij bent uitgenodigd en nog niet hebt geantwoord.
///
/// Afgeleid in plaats van apart opgehaald: één bron van waarheid, en het
/// scheelt een tweede netwerkrondgang die toch dezelfde rijen zou leveren.
@riverpod
Future<List<GroupRide>> pendingRideInvites(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final rides = await ref.watch(groupRidesProvider.future);
  return rides
      .where(
        (r) =>
            !r.isOwnedBy(userId) &&
            r.statusFor(userId) == ParticipantStatus.invited,
      )
      .toList();
}

/// Gedeelde ritten die jij organiseert.
@riverpod
Future<List<GroupRide>> ownedGroupRides(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final rides = await ref.watch(groupRidesProvider.future);
  return rides.where((r) => r.isOwnedBy(userId)).toList();
}
