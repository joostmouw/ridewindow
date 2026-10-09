// lib/features/peloton/group_link.dart
// De gedeelde groepslink (CLUB-02).

/// Basis-URL van de groepslink.
///
/// Zelfde domein en zelfde padvorm als `kInviteLinkBase` in
/// `invite_landing_screen.dart`, en om dezelfde reden: alleen een padlink kan
/// in `invite_landing_screen.dart`, en om dezelfde reden: alleen een padlink kan
/// Android als App Link herkennen en in de app openen. In de browser zet
/// `web/index.html` hem om naar `/#/group/CODE`. Verandert het domein, dan
/// veranderen beide constanten mee; de oude Firebase-site blijft als
/// padbehoudende redirect bestaan voor al verstuurde links.

String groupLinkFor(String code) => '$kGroupLinkBase/$code';
