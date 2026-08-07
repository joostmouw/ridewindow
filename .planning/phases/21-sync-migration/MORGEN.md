# Volgende sessie — wat jij moet doen

> **Bijgewerkt 2026-08-07 (vierde keer).** §2 én §3 zijn compleet, allebei via `adb` gedreven.
> Er staat nog één echte bevinding open (zie onderaan) en drie stappen: een tijdmeting, het
> verwijderen van het testaccount, en de Play-installatie.

**Op je toestel staat 1.0.21+22 als sideload.** Niet via Play. Play biedt daardoor geen updates
meer aan — dat is verwacht en pas bij stap 4 relevant.

Werkboom schoon. Suite 441/1 (die ene is de bekende notificatietest die na 19:00 UTC faalt).

---

## Wat nog open staat, in deze volgorde

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

### 2. §6 — account verwijderen (AUTH-09) — 3 min, als laatste

Vernietigt het testaccount, dus pas als 1 klaar is. Verwacht: automatische uitlog,
snackbar, nul rijen in `profiles`/`availability`/`planned_rides`, `feedback` blijft bestaan met
`user_id` NULL, account weg uit Authentication → Users, en **je lokale data op het toestel blijft
intact** (D-03 — dat is het vinkje dat nooit mag breken).

### 3. Afsluiten

Eén Play-installatie van de laatste build, zodat de fase eindigt op de distributieroute die
gebruikers krijgen.

**De AAB staat klaar:** `build/app/outputs/bundle/release/app-release.aab`, versie **1.0.22 (23)**,
gebouwd 2026-08-07 12:26. Version code 23 is vrij (Play staat op 20). Uploaden is handwerk in Play
Console — er is geen service account, geen fastlane en geen Play-workflow in dit project, alleen de
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
