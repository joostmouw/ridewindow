// lib/services/pending_group_join.dart
// Wisselt een klaargelegde groepscode in na het inloggen (CLUB-02, plan 34-07).

import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/services/peloton_gateway.dart';
import 'package:ridewindow/services/pending_invite_store.dart';

/// Wisselt de groepscode in die vóór het inloggen is klaargelegd (door de
/// landing `/group/:code` of door de onboarding-redirect).
///
/// Geeft `null` als er geen code lag; de gateway wordt dan niet aangeroepen.
/// De code wordt vóór het inwisselen gewist, ook als dat daarna mislukt: een
/// kapotte code mag niet bij elke login dezelfde fout opleveren (zelfde regel
/// als bij de maatjescode). Fouten gaan door naar de aanroeper, die er met
/// `groupErrorTextOf` een zin van maakt -- een volle groep of tien groepen moet
/// de gebruiker horen.
///
/// Bewust zonder BuildContext, zodat hij los te toetsen is.
Future<({String groupId, String? groupName, GroupJoinStatus status})?>
    redeemPendingGroupCode(PelotonGateway gateway) async {
  final code = await PendingInviteStore.readGroup();
  if (code == null) return null;
  await PendingInviteStore.clearGroup();
  return gateway.redeemGroupInvite(code);
}
