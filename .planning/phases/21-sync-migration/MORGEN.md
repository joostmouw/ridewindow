# Volgende sessie — wat jij moet doen

> **Bijgewerkt 2026-09-01 (vijfde keer).** §2 én §3 zijn compleet, allebei via `adb` gedreven.
> Vier stappen: een tijdmeting, de tegenproef op backlog #61, het verwijderen van het testaccount,
> en de Play-installatie.
>
> **Bevinding #61 is gefixt** (quick 260901-nz7, `36f4fca` + `abcf557`) maar alleen door tests
> gedekt — vandaar stap 1b. De AAB is opnieuw gebouwd op **1.0.23 (24)** en bevat de fix.

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

### 1. §4 — koude start (REG-03) — 2 min

Stopwatch. Tijd tussen tikken op het **PWA-icoon** (staat sinds 2026-08-07 op je beginscherm, na
de app volledig te hebben afgesloten) en de **eerste zichtbare ride slot**. Noteer: toestel,
verbindingstype, methode, waarde, omstandigheden.

> **Ik heb dit geprobeerd te automatiseren en dat is niet gelukt.** `screencap` pollen haalt maar
> ~1,7 Hz — te grof voor een grens van 2 seconden. Daarna `screenrecord` op 60fps geprobeerd, maar
> de opnames zijn nooit weggeschreven (de achtergrond-truc in `adb shell` hield geen stand) en je
> toestel moest los. ffmpeg staat nu wél geïnstalleerd, dus een volgende poging kan meteen door.
> Hang je de telefoon nog eens aan de kabel, zeg het dan — anders is de stopwatch prima, mits je
> noteert dat het met de hand gemeten is.

Boven de 2 seconden = blokkerend, dan sluiten we de fase niet.

> Let op de `BLOCKER` in §4: fase 19 heeft zijn eigen basislijn nooit gemeten, dus er is geen
> "voor"-getal. Meet toch — het bewijst de grens in absolute zin — en noteer dat er geen geldige
> vergelijking bestaat.

### 1b. Tegenproef op backlog #61 — 3 min, na de §4-meting

De fix staat er sinds 2026-09-01 (quick 260901-nz7), maar is **alleen door tests gedekt** — de
cloud-leeskant is zonder levende backend niet waarneembaar. Dit is de directe tegenproef van device
session 7:

Op de **PWA** — daar is de bug waargenomen, dus daar hoort de tegenproef. Kan zonder kabel:

1. Zorg dat er minstens één geplande rit in de cloud staat (die van §4 volstaat).
2. Android: Instellingen → Apps → **RideWindow** (de PWA, niet de native app) → Opslag →
   **Gegevens wissen**. Dat maakt de lokale opslag leeg zonder het icoon te verwijderen — lege
   lokale opslag is de discriminator, niet de koude start zelf.
3. Open de PWA via het icoon, log in als joostmouw@gmail.com.
4. **Kijk meteen naar de PLANNED-sectie.** Niet wegzetten, niet wachten op een
   voorgrond-cyclus — dat was juist de workaround die de bug maskeerde.

**PASS** = de ritten staan er bij het eerste scherm, zonder de app weg te zetten.
**FAIL** = lijst leeg, en dan blijft #61 open. Zeg het dan meteen; dan is mijn fix niet raak en
gaat hij niet mee in de release.

> Let op: dit werkt alleen ná stap 0. De fix zit in een build ná `abcf557`; de PWA van 7 augustus
> en de AAB van 12:26 die dag bevatten hem niet.
>
> Optioneel, als de kabel er toch aan hangt: dezelfde proef op de **native** app. Dat is de kant
> die nog nooit is vastgesteld (MIG-02 liep via een échte eerste login en dus langs het
> migratiepad — het verschil is precies `lastSyncedUid`). Zeg het even, dan bouw ik een release-APK
> en installeer ik hem via `adb`.

### 2. §6 — account verwijderen (AUTH-09) — 3 min, als laatste

Vernietigt het testaccount, dus pas als 1 klaar is. Verwacht: automatische uitlog,
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

- **Testdata:** de geplande rit **Saturday 8 aug 07:00–09:00** is van mij (multi-tab-proef).
  Prullenbak mag. Ook het agenda-event **"Fietsrit 06:00–08:00"** op zaterdag 8 augustus is van mij
  (§3-test); dat mag uit je Google Calendar.
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
