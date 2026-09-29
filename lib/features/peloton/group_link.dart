// lib/features/peloton/group_link.dart
// De gedeelde groepslink (CLUB-02).

/// Basis-URL van de groepslink.
///
/// Zelfde domein en zelfde padvorm als `kInviteLinkBase` in
/// `invite_landing_screen.dart`, en om dezelfde reden: alleen een padlink kan
/// Android als App Link herkennen en in de app openen. In de browser zet
/// `web/index.html` hem om naar `/#/group/CODE`. Verandert het domein, dan
/// veranderen beide constanten mee (en lopen al verstuurde links dood).
const kGroupLinkBase = 'https://my-project-joost.web.app/group';

String groupLinkFor(String code) => '$kGroupLinkBase/$code';
