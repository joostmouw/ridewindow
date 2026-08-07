# Volgende sessie — wat jij moet doen

> **Bijgewerkt 2026-08-07 (derde keer).** De webkant is klaar en **§2 is compleet** — de
> uitlog-ronde is via `adb` gedreven en D-12 haalde het. Vier stappen resteren; die vragen allemaal
> een echte handeling op het toestel die ik niet kan nabootsen (een PWA installeren, een stopwatch,
> en een account dat je zelf wilt zien verdwijnen).

**Op je toestel staat 1.0.21+22 als sideload.** Niet via Play. Play biedt daardoor geen updates
meer aan — dat is verwacht en pas bij stap 4 relevant.

Werkboom schoon. Suite 441/1 (die ene is de bekende notificatietest die na 19:00 UTC faalt).

---

## Wat nog open staat, in deze volgorde

### 1. §3 — PWA installeren op Android — 4 min

De herschreven §3. Chrome op Android → `https://my-project-joost.web.app` → **"Zet op
beginscherm"**. Dat bouwt een echte WebAPK, dus dit is een volwaardige installatietest, geen
surrogaat.

- Icoon verschijnt op het beginscherm, herkenbaar los van de native app
- Openen vanaf dat icoon → **geen adresbalk** (standalone)
- Navigeer Home → Ride Detail → Profiel en terug: geen dood eind, geen witte pagina
- Inloggen met hetzelfde account; je waarden uit §1 staan er
- Eén keer **"Voeg toe aan agenda"** vanuit de PWA, daarna controleren in je echte agenda

SYNC-04 hoef je hier niet meer te doen — die is afgetekend, zowel op de webkant als tussen de
native app en het web.

### 2. §4 — koude start (REG-03) — 2 min

Stopwatch. Tijd tussen tikken op het **PWA-icoon** (uit stap 1, na de app volledig te hebben
afgesloten) en de **eerste zichtbare ride slot**. Noteer: toestel, verbindingstype, methode,
waarde, omstandigheden.

Boven de 2 seconden = blokkerend, dan sluiten we de fase niet.

> Let op de `BLOCKER` in §4: fase 19 heeft zijn eigen basislijn nooit gemeten, dus er is geen
> "voor"-getal. Meet toch — het bewijst de grens in absolute zin — en noteer dat er geen geldige
> vergelijking bestaat.

### 3. §6 — account verwijderen (AUTH-09) — 3 min, als laatste

Vernietigt het testaccount, dus pas als 1 en 2 klaar zijn. Verwacht: automatische uitlog,
snackbar, nul rijen in `profiles`/`availability`/`planned_rides`, `feedback` blijft bestaan met
`user_id` NULL, account weg uit Authentication → Users, en **je lokale data op het toestel blijft
intact** (D-03 — dat is het vinkje dat nooit mag breken).

### 4. Afsluiten

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
  Prullenbak mag.
- **Main is gepusht** (`7cec4d8`). Let op: dat triggert géén deploy — `deploy-web.yml` filtert op
  `lib/`, `web/`, `pubspec.*` en `firebase.json`, en `.planning/**` staat daar bewust niet bij. Een
  verse deploy forceer je via `workflow_dispatch` in de Actions-tab.
- **Untitled draft-release** op de internal testing track in Play Console — leeg, zonder version
  code. Moet weg vóór stap 4: Play laat geen tweede draft naast een bestaande aanmaken.

---

## Afgehandeld — voor als je je afvraagt waar het gebleven is

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
- **Backlog #60** (`CloudSyncReconciler` injecteerbaar maken) staat op HOOG. Dat is de reden dat
  fase 21 vijf gap-closure-plannen nodig had: de reconciler grijpt op vijf plaatsen rechtstreeks
  naar `Supabase.instance.client`, dus van buitenaf is niet te zien wat hij doet. Niet voor deze
  fase, wel het item dat het patroon doorbreekt in plaats van er nog een pleister op plakt.
