# Volgende sessie — wat jij moet doen

> **Bijgewerkt 2026-08-07 (tweede keer).** De webkant is klaar: SYNC-11 en SYNC-04 zijn
> afgetekend met jouw twee waarnemingen, en §3 is herschreven naar Android-WebAPK met iOS
> uitgesteld naar v2. Alles wat hieronder nog staat, heeft een toestel in je hand nodig.

**Op je toestel staat 1.0.22+23 als sideload.** Niet via Play. Play biedt daardoor geen updates
meer aan — dat is verwacht en pas bij stap 6 relevant.

Werkboom schoon. Suite 441/1 (die ene is de bekende notificatietest die na 19:00 UTC faalt).

---

## Wat nog open staat, in deze volgorde

### 1. Google Calendar opnieuw koppelen — 1 min

Profiel → helemaal naar beneden → **Google Calendar** (staat nu op "Not connected") → doorloop de
Google-toestemming.

Dit is nodig omdat mijn sideload de OAuth-grant meenam. Zonder koppeling is stap 2 zinloos: die
toetst juist dat uitloggen de agendakoppeling **niet** meesleept (D-12), en er valt nu niets te
behouden.

### 2. §2 uitlog-ronde — 2 min

- **Sign out**, bevestig
- Controleer: je komt op de uitgelogde weergave, én **Google Calendar staat nog op "Connected"**
- Log weer in

Daarmee is §2 compleet.

### 3. §3 — PWA installeren op Android — 4 min

De herschreven §3. Chrome op Android → `https://my-project-joost.web.app` → **"Zet op
beginscherm"**. Dat bouwt een echte WebAPK, dus dit is een volwaardige installatietest, geen
surrogaat.

- Icoon verschijnt op het beginscherm, herkenbaar los van de native app
- Openen vanaf dat icoon → **geen adresbalk** (standalone)
- Navigeer Home → Ride Detail → Profiel en terug: geen dood eind, geen witte pagina
- Inloggen met hetzelfde account; je waarden uit §1 staan er
- Eén keer **"Voeg toe aan agenda"** vanuit de PWA, daarna controleren in je echte agenda

SYNC-04 hoef je hier niet meer te doen — die is gisteren afgetekend.

### 4. §4 — koude start (REG-03) — 2 min

Stopwatch. Tijd tussen tikken op het **PWA-icoon** (uit stap 3, na de app volledig te hebben
afgesloten) en de **eerste zichtbare ride slot**. Noteer: toestel, verbindingstype, methode,
waarde, omstandigheden.

Boven de 2 seconden = blokkerend, dan sluiten we de fase niet.

> Let op de `BLOCKER` in §4: fase 19 heeft zijn eigen basislijn nooit gemeten, dus er is geen
> "voor"-getal. Meet toch — het bewijst de grens in absolute zin — en noteer dat er geen geldige
> vergelijking bestaat.

### 5. §6 — account verwijderen (AUTH-09) — 3 min, als laatste

Vernietigt het testaccount, dus pas als 1 t/m 4 klaar zijn. Verwacht: automatische uitlog,
snackbar, nul rijen in `profiles`/`availability`/`planned_rides`, `feedback` blijft bestaan met
`user_id` NULL, account weg uit Authentication → Users, en **je lokale data op het toestel blijft
intact** (D-03 — dat is het vinkje dat nooit mag breken).

### 6. Afsluiten

Eén Play-installatie van de laatste build, zodat de fase eindigt op de distributieroute die
gebruikers krijgen. Daarna schrijf ik `21-08-SUMMARY.md` en `21-09-SUMMARY.md` en draai ik de
fase-verificatie.

---

## Kleine dingen als je er toch bent

- **Testdata:** de geplande rit **Saturday 8 aug 07:00–09:00** is van mij (multi-tab-proef).
  Prullenbak mag.
- **Main is niet gepusht** (alleen documentatie sinds de laatste push). Zeg "push" als je wilt dat
  de PWA opnieuw deployt; inhoudelijk verandert er niets.
- **Untitled draft-release** op de internal testing track in Play Console — leeg, zonder version
  code. Doet geen kwaad, maar het is precies zo'n restje dat je over een maand doet twijfelen of
  er iets niet uitgerold is. Verwijderen als je er toch bent.

---

## Afgehandeld — voor als je je afvraagt waar het gebleven is

- **SYNC-11 (multi-tab) — PASS**, 2026-08-07. Twee ritten zichtbaar in je desktop-tabblad.
- **SYNC-04 webkant — PASS**, 2026-08-07. Na een echte tabwissel verscheen de augustusrit.
- **Mijn bugvermoeden uit de web-sessie — ingetrokken.** De telefoon had in die hele sessie nooit
  een voorgrond-overgang gemaakt; de stale julirit was geen kapotte reconcile maar een reconcile
  die nog niet gelopen had. Vastgelegd in `MANUAL-VERIFICATION-21.md`.
- **§3 zonder iPhone — besloten.** iOS naar v2, §3 herschreven naar Android-WebAPK.
- **§5b/§5c, MIG-02, spookritten** — zie de eerdere sessies in `MANUAL-VERIFICATION-21.md`.
- **Backlog #60** (`CloudSyncReconciler` injecteerbaar maken) staat op HOOG. Dat is de reden dat
  fase 21 vijf gap-closure-plannen nodig had: de reconciler grijpt op vijf plaatsen rechtstreeks
  naar `Supabase.instance.client`, dus van buitenaf is niet te zien wat hij doet. Niet voor deze
  fase, wel het item dat het patroon doorbreekt in plaats van er nog een pleister op plakt.
