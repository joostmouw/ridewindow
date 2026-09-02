# Volgende sessie — wat jij moet doen

> **Bijgewerkt 2026-09-02 08:25 (achtste keer). Er staat niets meer open in fase 21.** De laatste
> stap — de app via Play installeren — is om 08:06 uitgevoerd en AUTH-10 is aan alle kanten
> afgetekend. Wat hieronder staat is historie; lees het alleen als je wilt weten hoe iets gelopen is.
>
> **Wat er nog van jou wordt gevraagd, en geen van beide is blokkerend:**
>
> 1. **Zet je beschikbaarheidsrooster opnieuw.** De app staat op het onboarding-preset "Evenings &
>    weekends". Je eigen rooster is niet vandaag verdwenen: de cloudkopie ging weg met §6 (account
>    verwijderd) en de lokale met de verplichte deïnstallatie. Dat was de vooraf benoemde prijs.
> 2. **Ruim mijn testdata op:** de geplande rit **woensdag 2 september 20:00–22:00** in de app, en
>    het agenda-event **"Fietsrit 20:00–22:00"** op diezelfde dag in je echte Google Calendar.
>
> Optioneel, dertig seconden: kijk in de Supabase Table Editor of de rijen van vandaag in
> `profiles` / `availability` staan. Het RPC-pad zelf is al bewezen (4 augustus, met echte waarden),
> dus dit is de laatste centimeter en geen gat.

**Op je toestel staat sinds 2026-09-02 08:06 de Play-installatie 1.0.23+24** —
`installerPackageName=com.android.vending`, dus Play-gesigneerd en niet langer een sideload. Play
biedt vanaf nu weer gewoon updates aan.

> **Historie:** hiervóór stond er sinds 5 augustus een sideload met de upload-sleutel. Die kon via
> `adb install -r` bijgewerkt worden met behoud van data, maar terug naar Play vereiste
> deïnstalleren, en dát wiste de lokale database en de Calendar-grant. Beide zijn na de installatie
> opnieuw opgebouwd.

Werkboom schoon. **Suite 451/451 — volledig groen**, voor het eerst in deze fase.

> **Correctie op wat hier eerder stond.** Dit bestand meldde "441/1 (die ene is de bekende
> notificatietest die na 19:00 UTC faalt)". Dat klopte niet: de notificatietest slaagde, en de enige
> rode was `test/core/app_version_test.dart` — `lib/core/app_version.dart` stond nog op 1.0.22 (23)
> terwijl `pubspec.yaml` al op 1.0.23+24 stond. Eén bekende flaky test maakt elke níéuwe rode
> onzichtbaar zodra je "1 gefaald" leest in plaats van *welke*. Gefixt in quick 260901-r92.

---

## Wat nog open staat, in deze volgorde

### 0. Deployen — GEDAAN 2026-09-01 15:52 UTC

Main gepusht (`23d952c..1e299ed`), `deploy-web.yml` liep vanzelf omdat de commits `lib/` en
`pubspec.yaml` raken. Live geverifieerd:

- `version.json` = **1.0.23 / 24** (was 1.0.22 / 23)
- `main.dart.js` `last-modified: Tue, 01 Sep 2026 15:52:36 GMT`, 5.559.673 bytes

**De PWA draait dus de #61-fix; je toestel draait als sideload nog 1.0.21+22.** Dat is precies
waarom stap 1 en 1b op de PWA gaan en niet op de native app.

> Terzijde, een aanname die ik hier moest rechtzetten: dit bestand beweerde dat de PWA op
> 1.0.21+22 stond. Dat klopte niet — hij stond op 1.0.22+23, want de branding-commit van
> 7 augustus raakte `web/` en `pubspec.yaml` en tríggerde dus wél een deploy. De conclusie
> (er moest gedeployd worden) bleef staan, het genoemde versienummer niet.

### 1. §4 — koude start (REG-03) — GEDAAN 2026-09-01, geautomatiseerd

Niet meer nodig. Gemeten via `adb` over 36 starts, alle tijdstempels in de device-klok:

| Meetmoment na de tik | Ride slot zichtbaar |
|---|---|
| 1,52s | 0 / 6 |
| 1,77s | 3 / 6 |
| 1,93s | 5 / 6 |
| 2,03s | 9 / 12 |
| 2,28s | 6 / 6 |

**Mediaan ≈ 1,75-1,8s — onder de grens.** Maar in ~1 op de 4 starts is het slot op 2,0s nog niet
zichtbaar. Ik noteer dat als PASS mét staart; wil jij die staart blokkerend noemen, dan is dat een
verdedigbare keuze en geen meetfout. Zeg het, dan draaien we hem terug naar open.

De automatisering die vorige keer strandde werkt nu wel — maar niet zoals gedacht. Twee dingen die
je moet weten, want ze staan allebei in `MANUAL-VERIFICATION-21.md` (device session 8):

- `screenrecord` is op dit toestel geblokkeerd door policy, niet door de achtergrond-truc waar de
  vorige notitie het op gooide. `screencap` mag wél naar dezelfde map schrijven.
- Android's **task snapshot** gaf eerst vier valse metingen van 0,06s: tijdens de launch-animatie
  toont Android een screenshot van hoe de app er bij het afsluiten uitzag — een scherm vol
  ride-kaarten. Dat had een prachtig getal opgeleverd dat nergens op sloeg.

### 1b. Tegenproef op backlog #61 — GEDAAN 2026-09-01 18:29-18:42, geautomatiseerd

**PASS aan beide kanten.** Niet meer nodig. Volledig via `adb`; uitgewerkt in
`MANUAL-VERIFICATION-21.md`, device session 9.

De fix bleek twee helften te hebben, en die zijn apart geproefd — één proef had er makkelijk voor
beide door kunnen gaan:

| Helft | Proef | Uitkomst |
|---|---|---|
| Inlogflow (`account_section.dart:328`) | site-data gewist → verse inlog → direct kijken | **PASS** |
| Koude start (`reconcileOnStartup`) | cloud-only rit → force-stop → koude start | **PASS** |

**Negatieve controle:** de native app 1.0.21+22 (vóór de fix) staat op hetzelfde toestel, ingelogd
met dezelfde sessie, kijkend naar dezelfde cloud — en toonde bij koude start géén PLANNED. Pas na
één achtergrond→voorgrond-cyclus verscheen de rit. De bug reproduceert dus live naast de fix, en
daarmee meet de PASS hierboven de fix en niet iets anders.

**Twee dingen die anders liepen dan dit bestand voorschreef:**

- **De wisinstructie in stap 2 was fout.** Instellingen → Apps → RideWindow → Gegevens wissen is de
  juiste hendel voor een native app en de verkeerde voor een WebAPK: dat pakket is een dunne
  launcher-shell, de opslag zit in Chrome's profiel voor het origin. Gewist via Chrome →
  Instellingen → Site-instellingen → Alle sites → `my-project-joost.web.app` → Delete site data.
  Chrome's eigen dialoog bevestigt het: "…or by its app on your Home screen".
- **De precondition ontbrak.** "My Rides" was leeg — de augustusritten zijn verleden tijd. Er is
  eerst een verse rit gepland. Daarbij bleek de outbox alleen leeg te lopen bij app-start, een
  voorgrond-overgang of na inloggen; een rit plannen enqueuet wel maar duwt niet, dus "Syncing…"
  bleef ~45s staan. Verwacht gedrag, geen vastloper — maar het ziet er bij het meten precies zo uit.

### 2. §6 — account verwijderen (AUTH-09) — GEDAAN 2026-09-01 18:55, app-kant PASS

Uitgevoerd op de PWA 1.0.23+24 via `adb`. Eén dialoog met de "cannot be undone"-waarschuwing (D-01),
automatische uitlog, snackbar "Account deleted".

**D-03 is op drie schermen gecontroleerd tegen een "voor"-opname en houdt stand:** notificatie-
instellingen ongewijzigd, beschikbaarheidsrooster identiek, en beide geplande ritten staan nog in
"My Rides". Verwijderen haalt dus alleen de server-kant weg.

**Dashboardhelft ook geverifieerd**, met twee leesqueries in de Supabase SQL-editor:

- `auth.users` met `joostmouw@gmail.com` → **0**. Account weg.
- Weesrijen in `profiles` / `availability` / `planned_rides` → **0 / 0 / 0**. De tabellen zijn niet
  leeg (3/3/2), maar die rijen horen bij andere accounts — daarom getoetst op weesrijen en niet op
  "tabel leeg". Bewijst meteen dat de nog-ingelogde native app geen spookrijen heeft teruggeduwd.
- `feedback` → **vervallen, niet gehaald.** Nul rijen in de tabel, dus er viel niets te observeren.
  `on delete set null` is alleen door het schema gedekt, niet op de database aangetoond.

> **Nevenwaarneming:** er staan 11 accounts in `auth.users`, allemaal `voornaamachternaam.12345@
> gmail.com`. Dat oogt gegenereerd. Geseed of echte closed-test-testers? Niets mee gedaan.

### 3. Afsluiten — GEDAAN 2026-09-02 08:06. Fase 21 is dicht.

**De Play-installatie is uitgevoerd en AUTH-10 is afgetekend.** Bewijs, in volgorde van gewicht:

| Wat | Uitkomst |
|---|---|
| Bron van de installatie | `installerPackageName=com.android.vending` — Play, geen sideload |
| Versie | `versionCode=24 / versionName=1.0.23`, in-app "Version 1.0.23 (24)" |
| Inloggen | joostmouw@gmail.com, **geen `ApiException: 10`**, status "Synced", overleeft een koude start |
| Google Calendar lezen | import gaf blauwe Calendar-blokken; profiel toont "Connected" |
| Google Calendar schrijven | `Fietsrit 20:00–22:00` staat in je echte agenda, op het juiste tijdstip |

Eén valstrik voor een volgende keer: een `market://`-intent opent op dit toestel **HeyTap Market**,
Oppo's eigen store. Gebruik `-d "https://play.google.com/store/apps/details?id=..." -p
com.android.vending`.

Volledig in `MANUAL-VERIFICATION-21.md`, device session 10.

---

### 3 (historie). Wat hier stond toen de installatie nog open was

**Play staat op 24 (1.0.23)**, internal testing track, "Available to internal testers", uitgerold
door Joost op 2026-09-02 08:00. Geverifieerd in de Console: `Latest release: 24 (1.0.23)`.

De geüploade AAB is die van **2026-09-01 19:37** — de herbouwde, mét de gecorrigeerde
`app_version.dart`. Geverifieerd op twee niveaus vóór upload: `versionName=1.0.23` in het packaged
manifest, én de string `1.0.23 (24)` letterlijk in de gecompileerde Dart
(`base/lib/arm64-v8a/libapp.so`).

**Wat toen nog restte — inmiddels gedaan, zie hierboven:**

> **Installeer de app één keer via Play op het toestel.**
>
> Dat kan niet als update: het toestel draagt een **sideload** met de upload-sleutel, Play levert een
> **Play-gesigneerde** build. Je moet dus eerst deïnstalleren, en **dat wist de lokale Drift-database
> én de Google Calendar-OAuth-grant** (dat laatste gebeurde ook op 5 augustus).
>
> Die prijs is nu laag: de lokale data is nog slechts testdata, en het D-03-bewijs is al vastgelegd.
>
> **Waarom het tóch moet:** Play hertekent de bundel met zijn eigen sleutel, dus testers draaien een
> ánders gesigneerde app dan wat er nu op het toestel staat. In dit project is precies dát al een
> keer misgegaan — Calendar werkte in een sideload en was stuk vanuit Play, door een niet-geregistreerde
> SHA-1. Fase 19's AUTH-10 eist daarom expliciet een bewijs vanaf een échte Play-installatie.
> Let na de installatie dus specifiek op **inloggen** en **Google Calendar**.

`21-09-SUMMARY.md` staat inmiddels op `complete` (2026-09-02); de fase-verificatie kan draaien.

> **Twee dingen die dit bestand eerder verkeerd had, rechtgezet door te kijken:**
> er was **geen lege "Untitled"-draft** om op te ruimen, en de internal testing track stond niet op
> version code 20 maar op **23 (1.0.22)**, uitgebracht 7 augustus 12:32. Code 24 is nog steeds vrij,
> dus de conclusie hield stand — het genoemde getal niet.
>
> Er is nog steeds geen service account, geen fastlane en geen Play-workflow in dit project; alleen
> de webdeploy is geautomatiseerd.

Daarna schrijf ik `21-08-SUMMARY.md` en `21-09-SUMMARY.md` en draai ik de
fase-verificatie.

---

## Kleine dingen als je er toch bent

- **Testdata:** de geplande ritten **Tuesday 1 sep 20:00–22:00** en **Saturday 5 sep 06:00–09:00**
  zijn van mij (stap 1b). Uit de cloud zijn ze weg via §6; de **lokale** kopieën staan nog op het
  toestel (dat is juist wat D-03 bewijst) en mogen de prullenbak in. Ook het
  agenda-event **"Fietsrit 06:00–08:00"** op zaterdag 8 augustus is van mij (§3-test); dat mag uit
  je Google Calendar.
- **Er staat nu een RideWindow-PWA op je beginscherm** naast de native app. Die heb ik voor §3
  geïnstalleerd. Laat hem staan tot §4 gemeten is — die meting gaat juist over dat icoon.
- **Main is gepusht** (`7cec4d8`). Let op: dat triggert géén deploy — `deploy-web.yml` filtert op
  `lib/`, `web/`, `pubspec.*` en `firebase.json`, en `.planning/**` staat daar bewust niet bij. Een
  verse deploy forceer je via `workflow_dispatch` in de Actions-tab.
- ~~**Untitled draft-release** op de internal testing track in Play Console.~~ **Bestond niet.**
  Nagekeken op 2026-09-01: de track had één release (23 / 1.0.22) en geen draft. Er viel niets op
  te ruimen, en het aanmaken van de nieuwe draft ging zonder blokkade.

---

## Afgehandeld — voor als je je afvraagt waar het gebleven is

- **§3 — PASS**, 2026-08-07, volledig via `adb`. WebAPK geïnstalleerd (echt pakket, geen
  bladwijzer), standalone bevestigd via het venstertype, navigatie rond, ingelogd als
  joostmouw@gmail.com, en "Fietsrit 06:00–08:00" staat geverifieerd in je echte agenda.
- **SYNC-11 (multi-tab) — PASS**, 2026-08-07. Twee ritten zichtbaar in je desktop-tabblad.
- **SYNC-04 webkant — PASS**, 2026-08-07. Na een echte tabwissel verscheen de augustusrit.
- **Mijn bugvermoeden uit de web-sessie — ingetrokken.** De telefoon had in die hele sessie nooit
  een voorgrond-overgang gemaakt; de stale julirit was geen kapotte reconcile maar een reconcile
  die nog niet gelopen had. Vastgelegd in `MANUAL-VERIFICATION-21.md`.
- **§3 zonder iPhone — besloten.** iOS naar v2, §3 herschreven naar Android-WebAPK.
- **§2 uitlog-ronde (D-12) — PASS**, 2026-08-07, via `adb` op de PLG110. Google Calendar bleef op
  "Connected" na het uitloggen, lokale instellingen bleven staan, opnieuw inloggen gaf "Synced" en
  beide ritten stonden er nog. **§2 is compleet.**
- **Twee aannames rechtgezet** door te meten in plaats van af te leiden: het toestel draait
  1.0.21+22 (niet 1.0.22+23), en Google Calendar stond al op "Connected" (niet "Not connected"),
  waardoor de herkoppel-stap overbodig bleek.
- **§5b/§5c, MIG-02, spookritten** — zie de eerdere sessies in `MANUAL-VERIFICATION-21.md`.
- **NIEUW, en het belangrijkste van vandaag: een verse installatie haalt geplande ritten niet op
  tot je hem eenmaal wegzet.** Op de net geïnstalleerde PWA was PLANNED leeg; na één
  achtergrond→voorgrond-cyclus stonden beide ritten er. Koude start mét lokale data is wél meteen
  goed, dus het ligt aan de lege lokale opslag, niet aan de koude start. Dit is de grondoorzaak van
  het hele raadsel van 6/7 augustus. Een nieuwe gebruiker die de app op een tweede toestel
  installeert, ziet een lege lijst en denkt dat de sync stuk is. Volledig uitgewerkt in
  `MANUAL-VERIFICATION-21.md`, device session 7 — dit verdient een backlog-item en mogelijk een fix
  vóór de fase dicht gaat.
- **Backlog #60** (`CloudSyncReconciler` injecteerbaar maken) staat op HOOG. Dat is de reden dat
  fase 21 vijf gap-closure-plannen nodig had: de reconciler grijpt op vijf plaatsen rechtstreeks
  naar `Supabase.instance.client`, dus van buitenaf is niet te zien wat hij doet. Niet voor deze
  fase, wel het item dat het patroon doorbreekt in plaats van er nog een pleister op plakt.
