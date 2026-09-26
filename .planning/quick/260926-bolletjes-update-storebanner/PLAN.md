---
quick_id: 260926-bolletjes-update-storebanner
date: 2026-09-26
status: in_progress
---

# Rode bolletjes erbij, update-melding bovenaan, store-balk op de website

Drie wensen van Joost (2026-09-26), gekozen via vragen in de sessie. Drie
code-commits, elk met tests groen.

## Wat er al stond (onderzoek vooraf)

- Het rode bolletje op Ritten en op de tab Peloton bestaat sinds build 55
  (CLUB-25, `unansweredRideCountProvider`). Groepsaanvragen telden daar
  bewust niet mee (34-05, bevestigd 2026-09-24); Joost draait dat nu om.
- **Vriendverzoeken bestaan niet.** `redeem_friend_invite` maakt direct een
  vriendschap; er is niets om te accepteren. Joost koos daarom: een bolletje
  voor een *nieuw, nog niet gezien* maatje.
- Geen update-check, geen `in_app_update`, geen store-verwijzing op web.
  `web/manifest.json` heeft `prefer_related_applications: false` en geen
  `related_applications`.
- `version.json` staat al naast de webbundel en krijgt al `no-cache`
  (`firebase.json`).

## 1. Bolletjes (groepsaanvragen + nieuwe maatjes)

- `openGroupRequestCountProvider`: som van `openRequests(me)` over
  `myGroups` waar jij beheerder bent. Geen extra netwerk: `myGroups` wordt
  al gewatcht door `rideEntries`.
- `UnseenFriends` (notifier): vergelijkt de ids uit `friendsProvider` met een
  lokaal opgeslagen set "gezien" per gebruiker (SharedPreferences). Staat er
  voor deze gebruiker nog niets, dan wordt de huidige lijst als gezien
  vastgelegd: bestaande maatjes zijn niet nieuw. Blijft volledig lokaal.
  De tab Peloton (BuddiesTab) markeert alles als gezien zodra hij de lijst
  toont.
- `pelotonAttentionCountProvider` = ritantwoorden + groepsaanvragen + nieuwe
  maatjes. Onderbalk en tab Peloton lezen die ene provider (zelfde principe
  als CLUB-25: ze kunnen niet uit elkaar lopen). Nieuwe voorleestekst
  `navPelotonAttention` in beide talen; de oude `navRidesUnanswered` vervalt
  als hij nergens meer gebruikt wordt.
- Bij terugkeer in de app (resumed, ingelogd, hooguit eens per 5 minuten)
  worden friends/groupRides/visibleGroups ververst, anders verschijnt een
  nieuw bolletje pas na een koude start.

## 2. Update-melding bovenaan

- Android: `in_app_update` (Google Play Core, gratis). `checkForUpdate()` bij
  start en bij resumed; staat er een update klaar, dan een balk bovenaan
  "Nieuwe versie beschikbaar" met "Bijwerken" (start de Play-updateflow) en
  wegklikken (onthouden per aangeboden versionCode). Werkt alleen bij een
  Play-installatie; een sideload geeft een fout, en die leidt tot géén balk.
- Web: `version.json` ophalen van de eigen hosting (zelfde origin, geen
  nieuwe partij), `build_number` vergelijken met `kAppBuildNumber`. Nieuwer:
  zelfde balk, "Vernieuwen" herlaadt de pagina.
- Privacy: de Android-check loopt via de Play-app op het toestel (Google is
  al sub-processor); de web-check gaat naar dezelfde server die de app al
  serveert. Er gaat geen gebruikersgegeven mee.

## 3. Store-balk op de website (Android-bezoekers)

- Alleen op web én Android-user-agent (nieuwe testbare naad in
  `pwa_display_mode`, zelfde patroon als `isIosBrowserMode`).
- Balk "Er is een Android-app" met "Doe mee"; die opent een venster met de
  drie stappen uit de testeruitnodiging: lid worden van
  `groups.google.com/g/ridewindow-testers`, aanmelden via
  `play.google.com/apps/testing/ridewindow.joost.amsterdam`, installeren via
  de Play-pagina. Eén knop per stap (`url_launcher`).
- Wegklikken sluimert zoals de iOS-balk (week, na drie keer klaar).
- `manifest.json`: `related_applications` met de Play-id erbij;
  `prefer_related_applications` blijft false, anders onderdrukt Chrome de
  PWA-installatie.
- Na de publieke lancering: stappenvenster vervangen door één link naar de
  Play-pagina (één constante).

## Gedeeld

- Eén bovenlaag (`TopBanners`) in de `MaterialApp.router`-builder met de
  update-balk, de store-balk en de bestaande iOS-balk onder elkaar, zodat ze
  elkaar nooit overlappen. De iOS-balk verliest daarvoor zijn eigen
  `Positioned`.
- Alle tekst in `app_nl.arb` en `app_en.arb`, geen em-dashes.

## Grenzen

- Geen serverwijziging, geen migratie, geen nieuwe dienst. Eén nieuwe
  dependency: `in_app_update`.
- Geen versiebump of release in deze taak.
