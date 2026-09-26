---
quick_id: 260926-bolletjes-update-storebanner
date: 2026-09-26
status: complete
---

# Bolletjes erbij, update-melding bovenaan, store-balk op de website

## Wat er gebouwd is (drie code-commits)

1. **`462f5d0` Het rode bolletje telt drie dingen.** Ritantwoorden (zoals
   sinds build 55), open aanvragen bij jou als beheerder, en maatjes die je
   nog niet zag. Eén provider `pelotonAttentionCount` voor onderbalk en tab
   Peloton. Home ververst Peloton bij terugkeer (ingelogd, hooguit eens per
   vijf minuten).
2. **`c2adae8` Update-melding bovenaan.** Android vraagt Play via
   `in_app_update`; web leest `version.json`. "Bijwerken" start de flow van
   Play (terugval: Play-vermelding), "Vernieuwen" herlaadt de pagina.
   Wegklikken geldt per build.
3. **`4cae43d` Store-balk voor Android-bezoekers van de website.** "Doe mee"
   opent een venster met de drie teststappen (groep, opt-in, installeren).
   `kStoreAppPublic` zet dat bij de lancering om naar één Play-link.
   `manifest.json` kent de Play-app als `related_applications`.

Alle balken bovenaan staan nu in één kolom (`TopBanners`), ook de bestaande
iOS-installatiebalk, zodat ze elkaar nooit afdekken.

## Vondsten

1. **Vriendverzoeken bestaan niet.** `redeem_friend_invite` maakt de
   vriendschap meteen. "Nieuw maatje" is daarom lokaal: een set geziene ids
   per gebruiker (`SeenFriendsStore`). Bij de eerste keer na de update geldt
   alles als gezien, anders kreeg elke bestaande gebruiker een bolletje voor
   al zijn maatjes. `friend_profiles()` geeft geen `created_at` terug; een
   migratie daarvoor was het niet waard.
2. **De tab Peloton kan gebouwd zijn zonder zichtbaar te zijn.** De shell
   houdt elke tak in een IndexedStack. Zonder de check op `TickerMode` zou
   een nieuw maatje als gezien gelden terwijl je op Home staat. Afgedekt in
   `peloton_unseen_friends_test.dart`.
3. **Peloton-data werd nooit ververst bij terugkeer.** Het bestaande
   ritbolletje had dat gat ook al: een nieuwe uitnodiging verscheen pas na
   een koude start. Nu ververst Home bij resumed.
4. **"Open" op de Play-vermelding is dubbelzinnig.** Het betekent ook "al
   bijgewerkt". Bij de release van 60 legde ik het eerst uit als "nog niet
   aangeboden", terwijl Play 60 al om 16:33:59 had geïnstalleerd. Eerst
   `dumpsys package` lezen. Gecorrigeerd in STATE.md.
5. **Closed testing en een store-link gaan niet samen.** De Play-link geeft
   "niet gevonden" voor wie geen tester is, en de opt-in vraagt eerst
   groepslidmaatschap. Vandaar het stappenvenster.
6. `build_runner` wijzigt bij elke run de hashes in `router.g.dart`,
   `analytics_provider.g.dart`, `slots_notifier.g.dart` en
   `unit_prefs_provider.g.dart` zonder dat de bron veranderd is (zie ook de
   oude stash "pre-session uncommitted .g.dart changes"). Die heb ik telkens
   teruggezet in plaats van meegecommit.

## Bewijs en grenzen

- Volledige suite: **1016 tests groen** (was 986; +30).
- `flutter analyze`: **201 infos**, de bestaande baseline.
- `flutter build apk --debug` en `flutter build web --release` slagen; de
  Kotlin-waarschuwing (KGP) bestond al en komt niet van `in_app_update`.
- Nieuwe dependency: `in_app_update ^5.0.0` (gratis, Google Play Core).
  Geen serverwijziging, geen migratie, geen nieuwe dienst.
- Nieuwe ARB-sleutels in beide talen: `navPelotonAttention` (vervangt
  `navRidesUnanswered`), `updateBanner*`, `storeBanner*`, `storeStep*`.
- **Niet op het toestel geverifieerd:** de update-balk kan pas iets tonen als
  er een build boven 60 op internal staat. De store-balk is alleen in tests
  en via de webbuild gezien, nog niet in Chrome op de Oppo.
- Geen versiebump of release in deze taak.
