// lib/features/peloton/group_link.dart
// De gedeelde groepslink (CLUB-02).

/// Basis-URL van de groepslink.
///
/// Zelfde domein en zelfde `/#/` als `kInviteLinkBase` in
/// `invite_landing_screen.dart`: de app draait op go_router's hash-strategie,
/// dus zonder `/#/` komt het pad op de server terecht en geeft het een 404.
/// Verandert het domein, dan veranderen beide constanten mee (en lopen al
/// verstuurde links dood).
///
/// Let op: de live PWA kent de route `/group/:code` pas na de uitrol in fase
/// 36. Tot dan opent een gedeelde link de app zonder de landing.
const kGroupLinkBase = 'https://my-project-joost.web.app/#/group';

String groupLinkFor(String code) => '$kGroupLinkBase/$code';
