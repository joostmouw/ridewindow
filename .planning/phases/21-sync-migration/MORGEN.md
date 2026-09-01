# Volgende sessie — wat jij moet doen

> **Bijgewerkt 2026-09-01 (zesde keer).** Stap 0, §4 en de tegenproef op #61 zijn allemaal
> afgetekend. **Er staan nog twee dingen open:** het verwijderen van het testaccount (§6) en de
> Play-installatie.
>
> **Bevinding #61 is gefixt én tegengeproefd op het toestel** (quick 260901-nz7, `36f4fca` +
> `abcf557`; proef in device session 9). De AAB is gebouwd op **1.0.23 (24)** en bevat de fix.

**Op je toestel staat 1.0.21+22 als sideload.** Niet via Play. Play biedt daardoor geen updates
meer aan — dat is verwacht en pas bij stap 4 relevant.

Werkboom schoon. Suite 441/1 (die ene is de bekende notificatietest die na 19:00 UTC faalt).

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

### 2. §6 — account verwijderen (AUTH-09) — 3 min, nu aan de beurt

Vernietigt het testaccount, dus pas als 1 en 1b klaar zijn — en dat zijn ze. Verwacht: automatische uitlog,
snackbar, nul rijen in `profiles`/`availability`/`planned_rides`, `feedback` blijft bestaan met
`user_id` NULL, account weg uit Authentication → Users, en **je lokale data op het toestel blijft
intact** (D-03 — dat is het vinkje dat nooit mag breken).

### 3. Afsluiten

Eén Play-installatie van de laatste build, zodat de fase eindigt op de distributieroute die
gebruikers krijgen.

**De AAB staat klaar, mét de #61-fix:** `build/app/outputs/bundle/release/app-release.aab`, versie
**1.0.23 (24)**, gebouwd 2026-09-01 17:32. Geverifieerd in het packaged manifest:
`versionCode="24"`, `versionName="1.0.23"`. Version code 24 is vrij — Play staat op 20.

Bewust gebumpt van 1.0.22+23: die AAB bestond al zónder de fix, en twee bestanden met hetzelfde
versienummer en verschillende inhoud is precies het soort verwarring dat een avond kost.

Uploaden is handwerk in Play Console — er is geen service account, geen fastlane en geen Play-workflow in dit project, alleen de
webdeploy is geautomatiseerd. Ruim bij het aanmaken van de release eerst de lege "Untitled"-draft
op, anders laat Play je geen tweede draft maken. Daarna schrijf ik `21-08-SUMMARY.md` en `21-09-SUMMARY.md` en draai ik de
fase-verificatie.

---

## Kleine dingen als je er toch bent

- **Testdata:** de geplande ritten **Tuesday 1 sep 20:00–22:00** en **Saturday 5 sep 06:00–09:00**
  zijn van mij (stap 1b). §6 ruimt ze op; gaat §6 niet door, dan mag de prullenbak erover. Ook het
  agenda-event **"Fietsrit 06:00–08:00"** op zaterdag 8 augustus is van mij (§3-test); dat mag uit
  je Google Calendar.
- **Er staat nu een RideWindow-PWA op je beginscherm** naast de native app. Die heb ik voor §3
  geïnstalleerd. Laat hem staan tot §4 gemeten is — die meting gaat juist over dat icoon.
- **Main is gepusht** (`7cec4d8`). Let op: dat triggert géén deploy — `deploy-web.yml` filtert op
  `lib/`, `web/`, `pubspec.*` en `firebase.json`, en `.planning/**` staat daar bewust niet bij. Een
  verse deploy forceer je via `workflow_dispatch` in de Actions-tab.
- **Untitled draft-release** op de internal testing track in Play Console — leeg, zonder version
  code. Moet weg vóór stap 4: Play laat geen tweede draft naast een bestaande aanmaken.

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
