# Regressiechecklist — Fase 19 (Auth)

Dit bestand is bedoeld om **letterlijk herbruikt te worden in fase 21** (D-18): het beschrijft precies wat een mens moet doen om te bevestigen dat inloggen, "Voeg toe aan agenda" en de app zelf werken op een echte Android-release-installatie en een echte iPhone-PWA. Elk vinkje wordt afgevinkt op basis van een **geobserveerd resultaat**, niet aangenomen — als een stap niet is uitgevoerd, blijft het vinkje leeg en wordt de reden erbij genoteerd.

Plan 19-07 voert deze checklist uit en vult de resultaten hieronder in. Niets is hier afgevinkt op
een aanname: elk vinkje draagt de bron van de observatie erbij, en wat niet waargenomen is blijft
leeg met de reden.

**Ingevuld op 2026-09-07.** De Android-sectie is afgetekend op grond van toestelsessie 10 van
**2026-09-02**, waarin AUTH-10 vanaf een echte Play-installatie is bewezen; die sessie is destijds
wel uitgevoerd maar nooit in dit bestand vastgelegd. De iPhone-sectie blijft open, met reden. De
koudestartmeting is op 2026-09-07 alsnog gedaan.

---

## 1. Android release (Play Store internal testing track)

**Bron:** installatie via de Play Store-link van het internal testing track, **niet** een lokaal gebouwde APK/AAB. Dit is bewust (D-16/AUTH-10): Google hertekent de app met de Play App Signing-sleutel bij een Store-installatie, en die sleutel heeft een ander SHA-1-fingerprint dan de lokale upload-keystore. Alleen een Store-installatie bewijst dat het juiste OAuth-Android-client (met het Play App Signing-fingerprint, zie `docs/CONSOLE-SETUP-CHECKLIST.md` §2) daadwerkelijk werkt.

- [x] **Opstarten** — Play-installatie (`installerPackageName=com.android.vending`, 1.0.23+24) geopend op de Oppo Find X9 Pro. Geen crash, geen witte pagina. *Bron: toestelsessie 10, 2026-09-02 08:06.*
- [x] **Inloggen** — inloggen met Google slaagde **zonder `ApiException: 10`**, wat precies het bewijs is waar D-16 om vroeg: Play hertekent met zijn eigen sleutel, en juist die SHA-1 moest bij de OAuth-client staan. *Bron: toestelsessie 10.*
- [x] **"Voeg toe aan agenda"** — Calendar lezen én schrijven werkten vanaf de Play-build. Dit is in dit project eerder stukgegaan vanuit Play terwijl het gesideload wél werkte, dus deze regel is niet vanzelfsprekend. *Bron: toestelsessie 10.*
- [x] **Uitloggen** — uitloggen keert terug naar de uitgelogde weergave; de agenda-koppeling blijft intact (D-12). *Bron: toestelsessie 10, en opnieuw waargenomen op 2026-09-07 tijdens de tweeaccountstest, waar vier keer is in- en uitgelogd zonder dat de Calendar-grant verviel.*
- [x] **Herstart → nog ingelogd** — status "Synced" overleeft een koude start, geen geflikker naar "uitgelogd" (AUTH-04). *Bron: toestelsessie 10.*

## 2. iPhone PWA

**Bron:** de live PWA op `https://my-project-joost.web.app`, geïnstalleerd op een echte iPhone via Safari — niet de desktop-browser en niet een simulator.

**Status: geblokkeerd, en dat blijft zo tot er een iPhone beschikbaar is.** Er is geen iPhone in het
project; het testtoestel is een Oppo (Android). Dit is een grens aan wat waarneembaar is, geen
vergeten stap — precies zoals de kop van dit bestand voorschrijft.

**Wat we indirect wél weten**, via een tester met een iPhone (2026-09-06, WhatsApp, met screenshot;
backlog #63): hij heeft de app op zijn iPhone draaien, is via Profiel → "Edit my schedule" op het
beschikbaarheidsscherm gekomen, en kon daar niet terug behalve met een veegbeweging. Dat bewijst
dat installeren, openen en navigeren tot op zekere hoogte wérken, en levert meteen één concreet
defect op dat op Android niet zichtbaar is. Het is te weinig om de vinkjes hieronder op te zetten.

- [ ] **Installeren** — geen iPhone beschikbaar.
- [ ] **Standalone openen** — geen iPhone beschikbaar. *(Deelbewijs: de tester draait de app en de
      screenshot toont geen Safari-chrome, maar hij is bijgesneden, dus dit is niet hard.)*
- [ ] **Navigeren** — geen iPhone beschikbaar. *(Deelbewijs: de tester navigeerde naar het
      beschikbaarheidsscherm; daar bleek juist een navigatieprobleem — zie backlog #63.)*
- [ ] **Inloggen** — geen iPhone beschikbaar.
- [ ] **"Voeg toe aan agenda"** — geen iPhone beschikbaar.

**Hoe dit alsnog dichtgaat:** vraag de bestaande iPhone-tester deze vijf stappen te doorlopen. Dat is
goedkoper dan een toestel aanschaffen en het is dezelfde persoon die #63 al meldde.

## 3. Web-koudestartmeting / cold-start measurement (D-19 — voedt REG-03 in fase 21)

Dit is een **meetmethode**, geen losse target-getal. Fase 21 herhaalt precies deze methode om REG-03 (2-secondenbudget) te beoordelen — een andere methode maakt die vergelijking betekenisloos. Vul alle velden hieronder in op het moment van meten; laat niets impliciet.

- [x] **Toestel:** desktop Chrome op macOS (Darwin 25.1.0). **Afwijking van het sjabloon**, dat een
      telefoon veronderstelde: op het toestel is de DevTools-socket van Chrome niet bereikbaar (op
      2026-09-07 geprobeerd via `adb forward`; de socket bestaat maar antwoordt niet), dus daar is
      geen betrouwbare timing te halen zonder met een stopwatch naar een scherm te kijken. Deze
      meting is reproduceerbaar en machine-afleesbaar; de telefoonmeting was dat niet.
- [x] **Verbindingstype:** vast breedband, niet gethrottled.
- [x] **Meetmethode:** `performance.getEntriesByType('navigation')[0]` in de live PWA, gelezen via de
      browserconsole direct na een navigatie naar `https://my-project-joost.web.app/`. Gerapporteerd
      worden `domContentLoadedEventEnd` en `loadEventEnd`, plus de overgedragen grootte van
      `main.dart.js`. **Let op:** Flutter tekent in een canvas, dus `paint`-entries en LCP blijven
      leeg — die zijn hier geen bruikbare maat, en fase 21 moet ze dus ook niet verwachten.
- [x] **Gemeten waarde:** 2026-09-07 ~10:05 — `domContentLoaded` **287 ms**, `loadEvent`
      **1637 ms**, `main.dart.js` **989 kB** overgedragen (van 5,7 MB ongecomprimeerd).
- [x] **Meetomstandigheden:** direct na een deploy, en sinds `d99b3bd` staat `main.dart.js` op
      `no-cache, must-revalidate` — de bundel is dus daadwerkelijk opnieuw over de lijn gekomen en
      dit is geen warme-cachemeting. **Wat dit getal níét is:** het is geen meting van §4's grens
      van 2 seconden tot het eerste zichtbare ritvenster, want `loadEvent` valt vóór het moment
      waarop Flutter de eerste slot-kaart heeft getekend, en dit is bovendien desktop over
      breedband. Wie §4 wil toetsen, moet dat op een toestel doen; deze meting is een
      reproduceerbare bovengrens voor de laadkant, niet voor de rendertijd.

---

*Geschreven door plan 19-06 (auto), uit te voeren door plan 19-07 (handmatig). Herbruikbaar as-is in fase 21 per D-18.*
