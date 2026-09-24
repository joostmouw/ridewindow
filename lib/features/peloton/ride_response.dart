import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/services/peloton_gateway.dart';

/// Antwoordt op een gedeelde rit, gewoon of voor een groep (fase 35).
///
/// Op een groepsrit heb je meestal nog geen participant-rij: er wordt er geen
/// per lid aangemaakt. Een update ([PelotonGateway.respondToRide]) op een rij
/// die niet bestaat doet stil niets -- je tikt "Ik ga mee" en er gebeurt niets.
/// Dat is het gat dat deze functie dicht: op een groepsrit gaat het antwoord
/// via [PelotonGateway.respondToGroupRide], een upsert.
///
/// Een functie en geen interfacemethode, zodat de bestaande test-fakes (die
/// alleen `respondToRide` opnemen) ongewijzigd geldig blijven voor gewone
/// ritten: `peloton_withdraw_test` en `peloton_options_test` hoeven niets te
/// weten van groepen.
Future<void> respondToSharedRide(
  PelotonGateway gateway,
  GroupRide ride, {
  required bool accepted,
  String? myName,
}) {
  if (ride.isGroupRide) {
    return gateway.respondToGroupRide(
      rideId: ride.id,
      accepted: accepted,
      displayName: myName,
    );
  }
  return gateway.respondToRide(rideId: ride.id, accepted: accepted);
}
