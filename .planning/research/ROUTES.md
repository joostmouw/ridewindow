# Routes — onderzoek en ontwerpopties

**Onderzocht:** 2026-09-29
**Aanleiding:** Joost wil routes kunnen importeren, op een kaart zien met de
score, en delen met anderen. Geïnspireerd door Bikewind (zie `BIKEWIND.md`).
**Status:** onderzoek, nog geen beslissing.

---

## Wat de wens is

1. **Route importeren** — van Strava, van een GPX-bestand, eventueel van Komoot
2. **Route op een kaart zien** — met de score erop
3. **Route delen** — een link die anderen kunnen openen, zoals de
   Peloton-links nu werken

## Wat er technisch bij komt kijken

Dit raakt vier lagen die vandaag niet bestaan in de app:

| Laag | Wat er nodig is | Bestaand? |
|------|-----------------|-----------|
| Routemodel | `Route` entiteit met waypoints, afstand, naam | Nee |
| Kaartweergave | `flutter_map` + tile-provider | Nee |
| Scoring langs route | Weer ophalen per routepunt, wind richting meenemen | Nee (nu: één punt) |
| Routes delen | Link-infrastructuur (patroon van Peloton-links) | Deels — het patroon bestaat |

---

## Optie A: GPX-import (kleinste stap)

**Wat:** de gebruiker importeert een `.gpx`-bestand (van Strava, Komoot,
Garmin, of waar dan ook). De app parst het, toont de route op een kaart, en
berekent de score langs de route.

**Packages:**

| Package | Versie | Doel |
|---------|--------|------|
| `gpx` | 2.2.2 | GPX parsen (XML → waypoints, tracks, routes) |
| `flutter_map` | 8.x | Kaartweergave, pure Flutter, werkt op Android + Web |
| `latlong2` | 0.9.x | Coordinaten-model voor flutter_map |
| `file_picker` | (of `share_plus` ontvangstkant) | GPX-bestand kiezen van toestel |

**Tile-provider (kritieke keuze, €0/maand):**

| Provider | Gratis limiet | Commercieel? | Opmerking |
|----------|---------------|--------------|-----------|
| **Carto Basemaps** | 5M req/maand (non-commercial) | Nee | Beste optie. Voyager-stijl is mooi en leesbaar. API-key via e-mail, geen account nodig |
| OpenStreetMap direct | Beperkt, beleid zegt "light use only" | Nee | Niet geschikt voor productie — expliciet beleid tegen app-gebruik zonder eigen tiles |
| MapTiler | 5 GB/maand | Ja (onder voorwaarden) | Gratis tier is ruim, maar vereist account |
| Thunderforest | 150k req/maand gratis | Ja | Voldoende voor klein gebruik |

**Advies: Carto Basemaps (Voyager-stijl).** 5M requests/maand is ruim
voldoende voor een app met tientallen gebruikers. Geen account nodig, alleen
een API-key per e-mail. Werkt met `flutter_map` via een simpel URL-template.

**Wat de score langs een route betekent:**

Nu haalt de app het weer op voor één punt (de thuislocatie). Met een route
verandert dat: elk waypoint krijgt zijn eigen weerspunt, en de score wordt een
gewogen gemiddelde over de hele route. Open-Meteo ondersteunt meerdere
coördinaten per request, dus het blijft binnen de gratis tier.

Voor de wind komt er een nieuwe dimensie bij: de windrichting ten opzichte
van de rijrichting per segment. Dat is de kern van wat Bikewind doet en wat
de score accuraat maakt voor fietsers.

**Delen:** de GPX-data (waypoints) is klein genoeg om in een
Supabase-rij te passen (JSONB). Een deel-link kan dan hetzelfde patroon
volgen als de Peloton-links: `https://ridewindow.web.app/route/ABC123`.

**Effort:** M-L. Het parsen en de kaart zijn rechttoe-rechtaan. De scoring
langs een route is waar het denkwerk zit.

---

## Optie B: Strava-integratie (grotere stap)

**Wat:** koppel je Strava-account, en je routes verschijnen in de app. Tik
op een route en je ziet de score.

**Strava API (v3):**

| Aspect | Detail |
|--------|--------|
| **Endpoints** | `GET /athletes/{id}/routes` (lijst), `GET /routes/{id}/export_gpx` (GPX per route) |
| **OAuth** | Bestaand OAuth2, scopes: `read` of `read_all` (voor privé-routes) |
| **Rate limits** | 100 read-req/15min, 1000 read-req/dag (nieuwe app) |
| **Athlete capacity** | Start: 1 (alleen jezelf). Upgrade naar 10 via dashboard. Meer dan 10: review aanvragen |

**Blokkade voor testers:** de athlete capacity van 1 betekent dat alleen
Joost zijn eigen routes kan zien. Voor 12 testers moet de app bij Strava
worden aangemeld en goedgekeurd (review-proces met screenshots). Dat is een
hobbek, maar een eenmalige.

**Alternatief binnen Strava:** de app hoeft niet de hele Strava-integratie
te doen. Een simpeler pad: de gebruiker plakt een Strava-route-URL in de app
(bijv. `https://www.strava.com/routes/12345`), en de app haalt de GPX op via
de API. Dat vereist nog steeds OAuth, maar is een kleinere UX-stap dan een
volledige koppeling.

**Effort:** L. OAuth-flow, route-lijst, GPX-export, rate-limit handling,
review-proces bij Strava.

---

## Optie C: Komoot

**Komoot heeft geen publieke API.** Ze integreren alleen met
gevestigde hardware-partners (Garmin, Bosch, Suunto). Er zijn unofficial
scrapers (Apify, parse.bot) maar die zijn onbetrouwbaar en vragen om
blokkades.

**Wat wél kan:** Komoot laat gebruikers routes exporteren als GPX.
De gebruiker doet dat handmatig in Komoot, en importeert het bestand in
Ridewindow (optie A). Een in-app tip kan dat uitleggen.

**Effort:** geen integratie mogelijk. Valt terug op optie A.

---

## Aanbevolen aanpak

**Fase 1 (kleinste bruikbare stap):** GPX-import + kaart + score langs route.

Dit geeft meteen de kernwaarde: "hoe is het weer op dit rondje morgen
om 10 uur". Geen Strava-afhankelijkheid, geen OAuth, geen review-proces.
De gebruiker exporteert een GPX vanuit Strava/Komoot/Garmin Connect en
importeert het. Werkt voor iedereen, geen blokkades.

**Fase 2 (als testers het vragen):** Strava-koppeling voor route-import
zonder handmatig exporteren. Dan is de OAuth-infrastructuur er al (Google
Sign-In bestaat), en Strava voegt een tweede provider toe. Dit is een
bewuste keuze die je kunt uitstellen tot blijkt dat het handmatige
GPX-pad te veel frictie is.

**Fase 3 (delen):** routes opslaan in Supabase en deelbaar maken via een
link. Dit bouwt voort op de Peloton-infrastructuur (groepen, links,
Supabase). Een gedeelde route heeft een kaartje, de score, en "dit is het
rondje dat we zaterdag rijden".

---

## Open vragen voor Joost

1. **Is GPX-import als eerste stap goed genoeg?** Het vraagt één handeling
   van de gebruiker (exporteren vanuit Strava/Komoot), maar werkt meteen.
   Of is de Strava-koppeling meteen de moeite waard?

2. **Moet de kaart interactief zijn** (inzoomen, pannen, routepunten
   aantikken voor details) of is een statisch overzicht met de route en
   kleuren voldoende voor v1?

3. **Hoort dit bij v4.1 of is dit v5.0-materiaal?** Het is een zichtbare
   feature die testers zullen waarderen, maar het is ook groot. Het past
   niet in "zo snel mogelijk live in de store".

4. **Delen: alleen binnen Peloton-groepen, of ook als losse link?** Een
   losse link ("hier is het rondje voor zaterdag") is laagdrempeliger dan
   een groep oprichten, maar vraagt wel om een publieke route-pagina op
   de PWA.

---

## Bronnen

- [flutter_map docs](https://docs.fleaflet.dev/)
- [Carto Basemaps](https://carto.com/basemaps/) — 5M req/maand gratis (non-commercial)
- [OSM Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/) — expliciet: niet voor productie-apps
- [Strava API Rate Limits](https://developers.strava.com/docs/rate-limits/) — 100/15min, 1000/dag read
- [Strava API Routes](https://developers.strava.com/docs/reference/#api-Routes) — `GET /athletes/{id}/routes`, `GET /routes/{id}/export_gpx`
- [Komoot API](https://support.komoot.com/hc/en-us/articles/10331570510618-komoot-API) — geen publieke API
- [gpx package (pub.dev)](https://pub.dev/packages/gpx) — GPX parser voor Dart
- [BIKEWIND.md](BIKEWIND.md) — concurrentieanalyse
