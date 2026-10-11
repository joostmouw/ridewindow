# Route bij je rit — epic-voorbereiding

**Onderzocht:** 2026-10-11 (avond), vanaf de Mac — de Oppo was bezet met de nulmeting van 37-05,
dus deze ronde is webonderzoek; de twee toestelvragen staan als testprotocol onderaan
**Voor:** epic #96 "Route bij je rit", te starten na v4.3 "Dicht huis"
**Bouwt voort op:** `ROUTE-INGANG.md` (ingang + fases, 11 okt), `ROUTES.md` (29 sep),
`BIKEWIND.md`, #89 (Komoot-groepsplanning), #45 (deep-links), #65 (Peloton v2)

---

## 1. Wat er in de wereld veranderd is sinds het eerdere onderzoek

### Strava's ontwikkelaarsprogramma is per 1 juni 2026 betaald geworden

Dit is de grootste verandering, en hij raakt de kern van het epic. Strava heeft het
ontwikkelaarsprogramma herbouwd in een Standard- en een Extended Access-tier:

| Aspect | Per 1 juni 2026 |
|---|---|
| Voorwaarde Standard-tier | De ontwikkelaar moet een **actief Strava-abonnement** houden (VS: $ 11,99/maand of $ 79,99/jaar); Strava zegt er expliciet bij dat het abonnement dé vergoeding is, er komt geen API-fee bovenop |
| Atleten-capaciteit | Nieuwe app start op **1 atleet** (de ontwikkelaar zelf), via het dashboard zelf op te hogen naar **10**, en alles daarboven pas na review door Strava, zonder gegarandeerde termijn |
| Rate limits | 200 requests/15 min en 2.000/dag (totaal) bij 1 atleet; 400/15 min en 4.000/dag bij 10; limieten gelden per app, gedeeld over alle aangesloten atleten |
| Tussenpersonen | Verboden: Strava-data via een derde platform routen is een policy-overtreding geworden. Een eigen worker (het BikeWind-patroon voor de token-ruil) is een eigen integratie en mag, maar blijft server-side code |
| Policy-clausules die vorm geven | Alleen de eigen data van de atleet tonen; Strava-data maximaal **7 dagen** cachen; binnen 30 dagen verwijderen na intrekking; **geen AI-gebruik**, ook niet ter inferentie |
| Nog komend | Nieuwe basis-URL `api-v3.strava.com` (beschikbaar 4 jan 2027), tokens alleen via header + `oauth/revoke` verplicht per 1 juni 2027; club-endpoints zijn 1 september 2026 verwijderd, Explore Segments alleen nog Extended Access |

**Wat dit voor het epic betekent.** "Strava met inloggen" was in ROUTES.md al "later"; het is nu
ook een bewuste **breuk van het €0-plafond** (een Strava-abonnement voor de ontwikkelaar) plus een
uitzondering op "geen server-side code" voor de token-ruil, plus review zodra meer dan tien mensen
willen koppelen. Met 44 actieve toestellen is Strava-OAuth in de praktijk een feature voor Joost
alleen, tot Strava een review toestaat. Advies van dit onderzoek: **Strava-inloggen alleen als
testers er expliciet om vragen**, en dan als bewuste productbeslissing genoteerd in
`CLAUDE.md`/`AGENTS.md`. De deel-link-ingang (fase 1) dekt Strava-gebruikers ondertussen af.

Twee bijkomende Strava-feiten:

- **Strava-routelinks zijn sinds circa april 2026 achter de login.** Tot voor kort kon een
  uitgelogde bezoeker een gedeelde route bekijken; nu vraagt Strava om inloggen (gemeld door
  cluborganisatoren op r/Strava, april 2026). Ridewindow kan uit een gedeelde Strava-route dus
  **geen lijn halen zonder OAuth**. De link blijft waardevol: hij opent Strava bij iemand die
  daar al ingelogd is, en dat is precies wat fase 1 belooft.
- **Antwoord op open vraag 4 uit ROUTE-INGANG.md:** het helpcentrum bevestigt dat de app bij een
  route "Delen" de **route-URL als tekst** deelt (route → See Details → deelpictogram), en dat
  privé-routes vanuit de app niet deelbaar zijn (alleen via de website). Te hervinden met een
  echte deelhandeling zodra fase 1 een ontvanger heeft, maar de documentaire status is: tekstlink.

**Alternatief dat is gecontroleerd en afvalt:** Strava schrijft voltooide activiteiten weg naar
Health Connect op Android (tijd, afstand, calorieën), maar **geen routes**; routes komen alleen via
Apple Health op iOS terecht. Health Connect helpt dus niet bij route-import op Android.

### Kaarttegels: het aanbod is verschoven, niet verdwenen

| Provider | Voorwaarde 2026 | Vorm | Oordeel |
|---|---|---|---|
| **CARTO Basemaps** | API-sleutel vereist; gratis, geen account, per e-mail in een minuut. Niet-commercieel tot **5 miljoen tegelverzoeken/maand** | Raster (Leaflet/flutter_map) en vector (MapLibre) | Praktische keuze: flutter_map + Voyager-raster. 5 M/maand is ruwweg honderdvoud van wat 44 actieve toestellen vragen (een kaartweergave laadt ~10-30 tegels) |
| **OpenFreeMap** | **Geen registratie, geen sleutel, geen limiet** | Alleen vector (MapLibre-stijlen) | Fraai fallback-idee, maar vector in Flutter vraagt de `vector_map_tiles`-plug-in (laatste pub.dev-release aug 2024; er is een actieve fork) of `maplibre_gl` (native SDK, zwaarder, ander webpad). Meer risico dan raster |
| OSM direct | Beleid zegt expliciet: "light use", niet voor productie-apps | Raster | Afgevallen, zoals ROUTES.md al concludeerde |
| Eigen PMTiles (BikeWind-patroon) | Eigen domein + hosting + tile-updates | Vector | Werkt, maar is onderhoud dat Ridewindow niet nodig heeft bij deze schaal |

**Conclusie voor fase 2: silhouet eerst, tegels erbovenop.** Een tegelloos silhouet van de lijn
(CustomPainter, zoals Komoot's WhatsApp-deelkaart en Strava's social cards) werkt **altijd, ook
offline en bij een koude start** — dat past bij de offline-eerst-kern van deze app. De
flutter_map-kaart met CARTO-tegels is een verrijking die mag falen zonder dat de route verloren
gaat. flutter_map is pure Flutter, dus de PWA krijgt dezelfde kaart gratis mee.

### Komoot Group Rides: het "nieuwe groepsplannen" uit #89, in kaart

Wat Komoot vandaag Group Rides noemt, is de verfijning van de Group Tours die #65 al vergeleek.
De feiten (komoot-support, mei 2026):

- Organisator plant een route → "Organize group ride" → uitnodigen via volgers/e-mail/QR/uitnodiglink.
- **Elke deelnemer heeft een Komoot-account nodig**, plus Komoot-notificaties aan, plus de
  **startregio ontgrendeld** (bij een gratis Komoot-account betekent dat: de juiste regio is de
  enige gratis regio).
- Route-aanpassingen van de organisator **propageren** naar wie geaccepteerd heeft, via in-app melding.
- Wie géén account heeft, kan de route alleen bekijken als die publiek staat, en kan niet accepteren.
- QR-code en uitnodiglink zijn **intrekbaar** ("Revoke invite access"), geaccepteerde deelnemers blijven.
- De datum en starttijd regelt Komoot via **route-comments**. Geen weersinformatie, geen
  beschikbaarheidskruising, geen vensterkeuze.

**Wat dit voor #89 betekent.** De overlap met Ridewindow is precies één ding: een route bij een
groepsrit (fase 4 van dit epic). Al het andere is een ander product: Komoot lost het *waar* en de
navigatie op, de *wanneer* vullen ze met comments. Ridewindow kiest het *wanneer* op basis van
weer en beschikbaarheid, en vraagt voor het meekijken geen account. Er is niets te kopiëren dat de
kernwaarde dichterbij brengt, en de positioneringszin schrijft zichzelf: **Komoot kiest het
waar, Ridewindow kiest het wanneer.** Voorstel: #89 afsluiten met dit onderzoek als uitkomst
("bewust niet doen, wel route-link accepteren"), en de Group Rides-details (propagatie,
intrekbare uitnodigingen) als referentie voor fase 4 meenemen.

---

## 2. De open vragen, beantwoord of verscherpt

| Vraag | Bron | Antwoord na dit onderzoek |
|---|---|---|
| 1. Echte kaart of eerst silhouet? | ROUTE-INGANG | **Allebei, gelaagd:** silhouet is de basis (altijd, offline), tegels de verrijking. Kaart-tegels zijn per definitie online; het silhouet houdt de offline-belofte heel |
| 2. Strava met inloggen ooit? | ROUTE-INGANG | Alleen als bewuste beslissing: betaald abonnement + server-uitzondering + review voor >10 atleten. Standaardantwoord: nee; heroverweeg bij expliciete vraag van testers |
| 3. Werkt de Komoot-coördinaten-route ook voor privé-tours? | ROUTE-INGANG | **Nog onbekend — testprotocol onderaan** (5 minuten, Joost met eigen tour). Komoot-support zegt: gedeelde inhoud moet publiek toegankelijk blijven, dus mogelijk zet Delen de tour op publiek. Dit bepaalt of fase 2 alle tours dekt of alleen publieke |
| 4. Wat stuurt Strava "Share To" mee? | ROUTE-INGANG | Gedocumenteerd: de route-URL als tekst; privé-routes niet deelbaar uit de app. Herverifiëren met de fase-1-ontvanger |
| GPX genoeg als eerste stap? | ROUTES.md | Ingetrokken door ROUTE-INGANG: de link is de eerste stap, GPX/FIT volgt als fase 3. Blijft geldig |
| Delen hoe breed? | ROUTES.md | Fase 4 deelt binnen Peloton/groepsritten (bestaand model, RLS via `is_ride_member`). Geen openbare route-pagina in dit epic; een losse deel-link is pas een vraag als testers erom vragen |

---

## 3. Techniek per fase, klaar voor de bouwplannen

**Fase 1 — Link bij de rit.** Ridewindow in het Android-deelmenu: `SEND`-intentfilter op
`text/plain`, ontvangst via `receive_sharing_intent` (pub.dev, actief gepubliceerd juni 2026),
dat zowel de koude start (initial share) als het voorgrondgeval afhandelt. Flow volgens WhatsApp/Google Maps: eerst Delen, dán pas vragen waarheen
("Bij welke rit?" + "Nieuwe rit met deze route"). Plakveld in de rit dat Komoot/Strava-links
herkent en meteen de titel via `og:title` toont (WhatsApp/YouTube-patroon; de 261011-test bewees
dat og:title op de Komoot-pagina staat). Op web: plakveld; het manifest `share_target` kan een
geïnstalleerde PWA in het deelmenu zetten, maar vraagt een POST-handler in de service worker —
bewust aparte, optionele slice. Opslag: link + titel bij de rit, lokaal (Drift/SharedPreferences
via het bestaande ritmodel). Uitgelogd blijft alles op het toestel, zoals altijd.

**Fase 2 — Lijn en kaartje.** Toestel haalt de lijn op:
`api.komoot.de/v007/tours/{id}/coordinates` (id zonder `e`-prefix; bewezen 261011 zonder login).
Ongedocumenteerd, dus: de **link blijft de basis, de lijn is een extra die mag falen** (streef:
kaartje toont "lijn niet beschikbaar" en de link blijft werken). Opslag lokaal, gedecimeerd naar
~500-1000 punten; afstand via Haversine, hoogtemeters uit `alt`. Silhouet altijd; tegels
(flutter_map + CARTO, sleutel gratis per e-mail) als verrijking. **Beleid:** api.komoot.de en
CARTO ontvangen het IP van de gebruiker (en Komoot de tour-id) — voeg beide toe aan "Wie namens
ons gegevens verwerkt" in `docs/privacy-policy.html` (NL+EN) op het moment dat fase 2 scheept,
volgens het bestaande Open-Meteo-patroon; Data Safety-verklaring op hetzelfde moment nalopen
(processor-exemplaar, geen "sharing", zelfde redenering als nu).

**Fase 3 — GPX en FIT.** `gpx`-package (pub.dev, actief, juli 2026 gepubliceerd) voor GPX;
FIT decoderen met `fit_sdk` (feb 2026) of `fit_tool` — beide pure Dart; keuze valt bij de bouw op
een echte file uit het veld (Garmin/Wahoo export). Ingangen: bestandskiezer (`file_picker`) plus
`VIEW`-intentfilters zoals BikeWind (`application/gpx+xml`, `text/xml`, `application/xml`,
`application/octet-stream`), zodat "Openen met Ridewindow" werkt.

**Fase 4 — Route mee naar de groep.** Route als kolom bij de bestaande rit (JSONB, gedecimeerd),
RLS via de bestaande `is_ride_member`-helper, dus geen nieuw tabelmodel. Wijziging door de
organisator propageert naar de groep: het Komoot Group Rides-patroon; het ritmodel heeft al een
update-pad, een meldingstype ontbreekt nog. Twee bewuste keuzes vóór de bouw: (a) **rijgrootte** —
een gedecimeerde route is ~20-60 KB JSON; leg de grens bewust vast (bv. 64 KB) in plaats van te
wachten op wat fase 38/39 toevallig instelt — die fases begrenzen feedback, app_events, codes en
aanmaak-aantallen, en zeggen niets over de rit-tabel; (b) **privacy bij delen** — een route begint
vaak bij de voordeur; BikeWind trimt standaard begin én eind. Minimaal: de optie bewust
documenteren (trimmen als keuze van de organisator), en in de app benoemen dat delen met de groep
de route zichtbaar maakt. Het privacybeleid noemt gedeelde ritten al; de route valt daaronder.

**Vervolg, bewust buiten dit epic** (tenzij Joost anders beslist): wind langs de route in de score
(raakt de ScoringEngine — het zwaarste onderdeel van de repo, en de kernwaarde; verdient een eigen
epic ná het venster-question of gelijktijdig daarmee), en Strava-OAuth (betaald, zie hierboven).

---

## 4. Hoe goedlopende apps het doen

De werkregel van 2026-09-29: eerst kijken hoe Instagram, WhatsApp, Strava, Google Maps, YouTube het
oplossen, en noteren wat we overnemen en waar we bewust afwijken.

| App | Wat zij doen | Overnemen / afwijken |
|---|---|---|
| **WhatsApp, Google Maps** | Staan in het deelmenu en vragen pas dáárna waarheen ("Stuur naar…", "Opslaan in lijst…") | **Overnemen:** Delen → Ridewindow → "Bij welke rit?" |
| **WhatsApp, YouTube** | Een geplakte link wordt meteen herkend met titel en voorbeeld | **Overnemen:** plakveld herkent Komoot/Strava-links en toont de titel |
| **Komoot** | Deelt een link of QR; naar WhatsApp deelt hij alleen een afbeelding zonder link. Gedeelde routes moeten publiek toegankelijk blijven of de link sterft | **Overnemen:** link én silhouet samen (Komoot's afbeelding is precies ons fase-2-silhouet). **Les:** waarschuw dat een gedeelde route publiek moet blijven |
| **Strava** | Route delen = URL; "Send to device" naar Garmin/Wahoo = export als bestand | **Overnemen:** de URL-fase (onze 1) en de bestandsfase (onze 3) zijn precies deze twee patronen |
| **Garmin Connect, RideWithGPS** | GPX/FIT als universele interchange-taal tussen alle fietsapps | **Overnemen:** fase 3 |
| **Komoot Group Rides** | Account-verplicht, propagatie van routewijzigingen, intrekbare uitnodigingen | Fase 4 haalt het patroon, zonder account-plicht: wie meekijkt in Ridewindow heeft het pelotonmodel al |
| **BikeWind** | Routebibliotheek als los hoofdscherm, Strava-OAuth via eigen worker, routegenerator | **Bewust afwijken:** geen bibliotheek (de rit is de plek), nu geen OAuth (betaald), geen generator |

Bewust niet in dit epic: route-generator, live navigatie, segmenten, KOM-ranking (zelfde redenen
als in BIKEWIND.md en #65: andere missie, en de kernwaarde is het venster).

---

## 5. Besluiten die Joost moet nemen vóór de milestone-start

1. **Strava-abonnement: nee** (advies), tenzij testers expliciet om inloggen vragen. Dit houdt
   het €0-plafond heel; de deel-link dekt Strava voor fase 1-3.
2. **Silhouet-eerst bevestigen** — fase 2 bouwt tegelloos, tegels komen daarnaheen zodra de
   CARTO-sleutel er is (gratis, per e-mail, geen account: carto.com/basemaps/apikey).
3. **Prive-tour-test draaien** (protocol onderaan, 5 minuten) — bepaalt de belofte van fase 2.
4. **Fase-4-keuzes bij de bouwplanning:** rijgrootte-grens en trim-optie; geen besluit nu nodig.
5. **Milestonenummer en naam:** voorstel v5.0 "Route bij je rit", maar dat is de
   GSD-milestone-stap (`/gsd-plan`), niet dit onderzoek.

## 6. Testprotocol: Komoot privé-tour via de share-link (Joost, ~5 minuten)

1. In Komoot (Oppo of web) een **eigen, privé staande tour** openen → Delen → link kopiëren.
2. De link naar de Mac halen (bijv. naar jezelf mailen). Noteer de vorm: `komoot.com/tour/{id}`
   met of zonder `share_token`-parameter?
3. `curl -s -A "Mozilla/5.0" "<link>" | head -c 2000` — staat er een `coordinates`-blok of een
   verwijzing naar `api.komoot.de`? Zo ja: het smarttour-pad werkt ook hier.
4. `curl -s "https://api.komoot.de/v007/tours/{id}/coordinates"` proberen (id zonder `e`-prefix),
   daarna met `?share_token=…` uit de link, als die erin zit.
5. Uitkomst hier noteren. Drie mogelijkheden: (a) lijn zonder login → fase 2 dekt alles;
   (b) lijn alleen met share_token → fase 2 dekt gedeelde tours, bewust programmeerbaar;
   (c) niets zonder login → fase 2 dekt alleen publieke tours, en de app zegt dat eerlijk.

Let op bij stap 1: als Delen de tour op **publiek** zet (Komoot-support suggereert dat gedeelde
inhoud publiek toegankelijk moet blijven), is dat een privacyvermelding in fase 2 waard:
"via Delen maak je de tour openbaar bij Komoot".

## 7. Wat deze ronde níét heeft onderzocht

- De Oppo: niet aangeraakt (37-05-nulmeting draaide). De twee toestelvragen (prive-tour, Strava
  Share To in het echt) staan hierboven als protocol.
- Komoot's rate-gedrag op `api.komoot.de` (ongedocumenteerd; mitigatie staat vast: decimeren,
  cachen, en falen mag). Niet meten vóór fase 2 bouwt.
- Of de `vector_map_tiles`-fork productierijp is: alleen relevant als Joost OpenFreeMap boven
  CARTO verkiest; raster heeft de voorkeur.
- Wind langs de route in de score: bewust buiten scope (later epic, raakt de ScoringEngine).

## Bronnen

- [Strava: An Update To Our Developer Program (1 juni 2026)](https://communityhub.strava.com/insider-journal-9/an-update-to-our-developer-program-13428)
- [Strava API FAQ](https://communityhub.strava.com/developers-knowledge-base-14/strava-api-faq-12906), [API Policy](https://www.strava.com/legal/api_policy), [Rate Limits](https://developers.strava.com/docs/rate-limits/), [Changelog](https://developers.strava.com/docs/changelog/) — samengevat en gecontroleerd via [Sahha's analyse (9 okt 2026)](https://sahha.ai/blog/strava-api-changes-2026/) en [Terra (11 sep 2026)](https://tryterra.co/blog/strava-api-changes-2026)
- [Strava Help: How Do I Get and Share Links From Strava?](https://support.strava.com/hc/en-us/articles/4418607378189) — route delen = URL
- [r/Strava: Login to view routes (april 2026)](https://www.reddit.com/r/Strava/comments/1sl59ob/login_to_view_routes/)
- [Strava Support: Health Connect and Strava](https://support.strava.com/en-us/articles/15401554-health-connect-and-strava) — geen routes op Android
- [Komoot: Share and embed komoot content](https://support.komoot.com/hc/en-us/articles/10331539580442), [Organize and manage group activities](https://support.komoot.com/hc/en-us/articles/10374965887130), [komoot API](https://support.komoot.com/hc/en-us/articles/10331570510618-komoot-API)
- [CARTO Basemaps API key](https://carto.com/basemaps/apikey/), [CARTO Basemaps FAQ](https://docs.carto.com/faqs/carto-basemaps), [Basemap Terms](https://carto.com/legal/basemap-terms/)
- [OpenFreeMap](https://openfreemap.org/), [GitHub: hyperknot/openfreemap](https://github.com/hyperknot/openfreemap)
- [OSM Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/)
- [flutter_map docs](https://docs.fleaflet.dev/), [Tile Layer (provider-voorwaarden)](https://docs.fleaflet.dev/layers/tile-layer)
- [pub.dev: receive_sharing_intent](https://pub.dev/packages/receive_sharing_intent), [gpx](https://pub.dev/packages/gpx), [fit_sdk](https://pub.dev/packages/fit_sdk), [fit_tool](https://pub.dev/documentation/fit_tool/latest/), [vector_map_tiles](https://pub.dev/packages/vector_map_tiles)
- [MDN: share_target](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest/Reference/share_target), [web.dev: Web Share Target](https://web.dev/web-share-target/)
- Eigen metingen: `ROUTE-INGANG.md` (261011-rzn), `docs/privacy-policy.html` (verwerkerslijst als patroon)
