# Volgende sessie — wat jij moet doen

> **Bijgewerkt 2026-08-07.** Sinds de eerste versie is §5b volledig afgetekend (dashboard
> bevestigde `ride_id` op `Z` en `start_at` 10:00 UTC), is een bottom-sheet-bug gefixt
> (1.0.22+23, het debugmenu knipte zijn laatste item af) en is de webkant gediagnosticeerd.
> Zie het blok "Openstaand na de web-sessie" onderaan.

Stand van 2026-08-05, 23:15. Alles wat zonder jou kon, is af. Werkboom schoon, suite 441/1
(die ene is de bekende notificatietest die na 19:00 UTC faalt).

**Op je toestel staat 1.0.21+22 als sideload.** Niet via Play. Play biedt daardoor geen updates
meer aan — dat is verwacht en pas aan het eind van de fase relevant.

---

## Eerst: 2 minuten, en dan weet je of de kern klopt

**Supabase dashboard → Table Editor → `planned_rides`**

Er hoort nu **één rij** te staan (de zaterdagrit; de zondagrit heb ik gisteravond verwijderd als
§5c-test). Controleer daarvan:

| Kolom | Verwacht | Waarom dit het scherpste punt is |
|-------|----------|----------------------------------|
| `ride_id` | eindigt op **`Z`** | bewijst dat de sleutel uit de UTC-instant komt (21-13) |
| `start_at` | **10:00 UTC** | jouw rit is 12:00 lokaal; stond hier 12:00 UTC, dan was het tijdstip verschoven |

Staat er 12:00 UTC, zeg het meteen — dan is de sleutel wel gerepareerd maar het tijdstip niet, en
dat is een half werkende fix.

---

## Daarna, in deze volgorde

### 1. Google Calendar opnieuw koppelen — 1 min

Profiel → helemaal naar beneden → **Google Calendar** (staat nu op "Not connected") → doorloop de
Google-toestemming.

Dit is nodig omdat mijn sideload de OAuth-grant meenam. Zonder koppeling is §2's uitlog-ronde
zinloos: die toetst juist dat uitloggen de agendakoppeling **niet** meesleept (D-12), en er valt nu
niets te behouden.

### 2. §2 uitlog-ronde — 2 min

- **Sign out**, bevestig
- Controleer: je komt op de uitgelogde weergave, én **Google Calendar staat nog op "Connected"**
- Log weer in

Daarmee is §2 compleet.

### 3. §5 — twee tabbladen (SYNC-11) — 4 min

`https://my-project-joost.web.app` in **twee** Chrome-tabbladen, beide ingelogd op hetzelfde
account. Wijzig in tab A een beschikbaarheidsuur, ga naar tab B, kijk of B de wijziging oppikt en
of B's eigen volgende schrijfactie A's wijziging niet overschrijft.

Dit kan ik grotendeels overnemen zodra jij één keer ingelogd bent — zeg het maar.

### 4. §4 — koude start (REG-03) — 2 min

Stopwatch. Tijd tussen tikken op het PWA-icoon (na de app volledig te hebben afgesloten) en de
**eerste zichtbare ride slot**. Noteer: toestel, verbindingstype, methode, waarde, omstandigheden.

Boven de 2 seconden = blokkerend, dan sluiten we de fase niet.

> Let op de `BLOCKER` in §4: fase 19 heeft zijn eigen basislijn nooit gemeten, dus er is geen
> "voor"-getal. Meet toch — het bewijst de grens in absolute zin — en noteer dat er geen geldige
> vergelijking bestaat.

### 5. §3 — iPhone-PWA + cross-device — 5 min

Safari op de iPhone → PWA installeren → standalone openen → navigeren → inloggen met hetzelfde
account. Daarna: wijzig op Android één beschikbaarheidsuur, Android naar de achtergrond, iPhone
naar de voorgrond, kijk of de wijziging verschijnt (SYNC-04). En één keer "Voeg toe aan agenda".

### 6. §6 — account verwijderen (AUTH-09) — 3 min, als laatste

Vernietigt het testaccount, dus pas als 3/4/5 klaar zijn. Verwacht: automatische uitlog, snackbar,
nul rijen in `profiles`/`availability`/`planned_rides`, `feedback` blijft bestaan met `user_id`
NULL, account weg uit Authentication → Users, en **je lokale data op het toestel blijft intact**
(D-03 — dat is het vinkje dat nooit mag breken).

### 7. Afsluiten

Eén Play-installatie van de laatste build, zodat de fase eindigt op de distributieroute die
gebruikers krijgen. Daarna schrijf ik `21-08-SUMMARY.md` en `21-09-SUMMARY.md` en draai ik de
fase-verificatie.

---

## Wat ik gisteravond nog heb uitgezocht

**Waarom de spookritten weg waren zonder dat de reparatie liep.** `_repairNonCanonicalRideIds`
heeft nooit gelogd. Nagegaan: de spookrijen waren al uit de cloud verdwenen vóór de sideload. Beide
alternatieven zijn uit te sluiten — een niet-canonieke sleutel had een logregel gegeven, een
canonieke had kaarten van 14:00 en 10:00 opgeleverd, en geen van beide gebeurde.

Dat betekent dat je handmatige deletes de cloud wél bereikten; wat telkens terugkwam was de lokale
kopie, opgewekt door de pull die vóór de delete liep. Dat is exact de lus die 21-14 dicht, en het
bevestigt die diagnose van een andere kant.

**Gevolg:** 21-13's cloud-reparatiepad is niet op een toestel geoefend — er was niets te
repareren. Dat schrijf ik niet als "bewezen" weg. Geen blokkade (het pad is een eenmalige
opruiming voor rijen die er niet meer zijn), wel eerlijk vastgelegd.

**Backlog #60 aangemaakt, en dit is de belangrijkste van de vijf.** Fase 21 heeft vijf
gap-closure-plannen nodig gehad, en bij élk was dezelfde beperking de reden dat de bug pas op een
toestel opdook: `CloudSyncReconciler` grijpt op vijf plaatsen rechtstreeks naar
`Supabase.instance.client` en neemt alleen een `Ref` aan. Van buitenaf is dus niet te zien wat hij
leest, wat hij stuurt, of in welke volgorde — vandaar dat 21-14's volgorde-fix nu bewaakt wordt
door een regex over broncode in plaats van een echte test.

Het patroon om dit op te lossen staat al in deze codebase: `SyncOutboxService.drain()` krijgt zijn
send-operaties als geïnjecteerde closures. Dezelfde behandeling voor de reconciler maakt die
asserties gedragstests. Ik heb het als HOOG gezet omdat het het enige item is dat het patroon
doorbreekt in plaats van er nog een pleister op plakt.

---

## Losse eindjes

- **Main is niet gepusht** (alleen documentatie sinds de laatste push). Zeg "push" als je wilt dat
  de PWA opnieuw deployt; inhoudelijk verandert er niets.
- **Untitled draft-release** op de internal testing track in Play Console — leeg, zonder version
  code. Doet geen kwaad, maar het is precies zo'n restje dat je over een maand doet twijfelen of
  er iets niet uitgerold is. Verwijderen als je er toch bent.


---

## Openstaand na de web-sessie (2026-08-06/07)

**Twee vingerbewegingen die ik niet kan doen, elk vijf seconden.** Ze beantwoorden allebei
dezelfde vraag: pikt een tabblad dat écht zichtbaar wordt een wijziging van elders op? Ik kan op
deze omgevingen geen echte voorgrond-overgang forceren, en een gesimuleerde bewijst niets — dat heb
ik twee keer geprobeerd en beide keren was de proef ongeldig (zie MANUAL-VERIFICATION-21.md).

1. **Desktop:** klik in je eigen RideWindow-tabblad. Staan er nu **twee** ritten onder PLANNED —
   Saturday 07:00–09:00 en 12:00–15:00? De eerste heb ik als testwijziging gepland in een ander
   tabblad. Verschijnt hij: SYNC-11 werkt. Verschijnt hij niet: dat is een echte bug.
2. **Telefoon (Chrome-tabblad):** wissel naar een ander tabblad, wacht twee tellen, wissel terug.
   Verandert `planned_rides` daarna naar de augustusrit, dan werkt de voorgrond-reconcile en was er
   simpelweg nooit een overgang. Blijft de julirit staan, dan vuurt het lifecycle-event niet in
   Chrome op Android — en dat raakt SYNC-04 en §3.

**Testdata om op te ruimen:** de rit **Saturday 07:00–09:00** is van mij, prullenbak mag.

**Nog te beslissen — §3 zonder iPhone.** Je hebt er geen. Mijn voorstel: het iOS-deel expliciet
uitstellen naar v2 (`CLAUDE.md` legt vast dat v1 Android-only is) en de rest van §3 herschrijven
naar wat je wél kunt aantonen — "Zet op beginscherm" in Chrome bouwt een echte WebAPK, dus
installatie, standalone modus en navigatie zijn op Android te toetsen, en SYNC-04 kun je bewijzen
met de native app tegenover de PWA. Zeg akkoord, dan pas ik §3 aan.
