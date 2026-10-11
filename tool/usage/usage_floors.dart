// Vloeren voor de uitschieterregel (D-15/D-16), per bron uit
// `supabase/migrations/0014_usage_daily_counts.sql`.
//
// Waarom hier en niet in de database
// ----------------------------------
// De regel draait op twee plekken -- het lokale `tool/usage_report.dart` en de
// dagelijkse GitHub Action -- en beide lezen deze ene lijst. In de database
// zouden de vloeren een tabel met rechten, een migratie per bijstelling en een
// extra leesroute voor `usage_monitor` vragen, voor iets dat geen data is maar
// beleid. Een vloer bijstellen is zo een gewone commit met een reden erbij.
//
// Bewuste afweging: de repo is publiek (F-01), dus deze getallen ook. Dat is
// aanvaard. Een vloer is geen geheim: wie hem kent en er net onder blijft,
// wordt in fase 38/39 tegengehouden door de plafonds. De vloer bepaalt alleen
// wanneer Joost een seintje krijgt; hij houdt niemand tegen.
//
// Beginwaarden
// ------------
// Onderstaande getallen zijn ruime beginwaarden, gekozen voordat er gemeten
// is. Plan 37-05 vervangt ze door waarden op basis van de nulmeting en
// verwijst dan naar `.planning/phases/37-meten/37-NULMETING.md`.
//
// Alleen `dart:core`: dit bestand moet zonder Flutter/pub op een runner draaien.

/// De tien bronnen, in de volgorde van migratie 0014. Een test bewaakt dat
/// elke naam daar ook staat.
const kUsageSources = <String>[
  'feedback_account',
  'feedback_anoniem',
  'app_events',
  'friend_invites',
  'group_invites',
  'group_rides',
  'group_ride_options',
  'accounts_google',
  'accounts_email',
  'accounts_overig',
];

/// Bronnen zonder afzenderkolom: anonieme feedback heeft geen `device_id`
/// (F-02), en een nieuw account is per definitie zijn eigen afzender.
const kSenderlessSources = <String>{
  'feedback_anoniem',
  'accounts_google',
  'accounts_email',
  'accounts_overig',
};

/// Vloer voor regel 1: een dagtotaal moet hier boven zitten (en boven vijf
/// keer de mediaan) om als uitschieter te tellen.
const Map<String, int> kFloorTotal = {
  'feedback_account': 20,
  'feedback_anoniem': 20,
  'app_events': 3000,
  'friend_invites': 30,
  'group_invites': 30,
  'group_rides': 30,
  'group_ride_options': 120,
  'accounts_google': 20,
  'accounts_email': 20,
  'accounts_overig': 10,
};

/// Vloer voor regel 2: zoveel rijen van één afzender op één dag is genoeg
/// voor een seintje. Alleen voor bronnen met een afzender.
const Map<String, int> kFloorSender = {
  'feedback_account': 5,
  'app_events': 600,
  'friend_invites': 10,
  'group_invites': 10,
  'group_rides': 10,
  'group_ride_options': 40,
};
