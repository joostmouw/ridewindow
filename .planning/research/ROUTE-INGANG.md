# Route-ingang — hoe een route uit Komoot of Strava in Ridewindow komt

**Onderzocht:** 2026-10-11, op de Oppo (Komoot, Strava, BikeWind 1.0.7) en vanaf de Mac
**Voor:** epic #96 "Route bij je rit", start **na** v4.3 "Dicht huis" (beslissing Joost, 2026-10-11)
**Voorstel als pagina:** https://claude.ai/artifact/9k42ZUFHsCahTfyBSQZdSY
**Bouwt voort op:** `ROUTES.md` (GPX, kaart, tegels) en `BIKEWIND.md` (featurevergelijking)

---

## De wens, in Joosts woorden

> "Je maakt routes met Komoot en met Strava en evt andere apps en kan die inladen op een
> makkelijke en snelle manier in RW."

Het gaat dus om de **ingang**: de route ontstaat elders, Ridewindow moet hem snel binnenhalen en
aan een geplande rit hangen. Wind langs de route in de score is een later vervolg, niet de kern.

## Wat Delen werkelijk meestuurt (getest op de Oppo)

Telkens het deelmenu geopend en afgebroken; er is niets verstuurd.

| Bron | Wat Delen meestuurt | Lijn zelf ophalen? |
|---|---|---|
| **Komoot** | Alleen een **link**, als tekst: `https://www.komoot.com/smarttour/e389075652?ref=…`. Het "⋯"-menu heeft geen GPX-export. | **Ja, voor openbare tours.** Zie hieronder. Privé-tours (link met `share_token`) nog niet getest. |
| **Strava** | Eigen tussenmenu ("Send to / Post to / Copy to Clipboard / Share To"); "Share To" opent een eigen keuzelijst, dus de inhoud was niet te zien. Vrijwel zeker een (korte) link. | **Onbekend zonder inloggen.** De API (`/routes/{id}/streams`, `export_gpx`) vraagt OAuth. |
| **GPX-bestand** | Garmin, Ride with GPS, Komoot-website, mail | Ja, alles zit in het bestand |
| **Andere link** | Wat dan ook | Nee, maar de link zelf opent de route weer in de bron-app |

Opvallend: Strava staat zelf in het deelmenu van Komoot.

### Komoot-link → lijn, zonder login

- `GET https://www.komoot.com/smarttour/e389075652` (gewone browser-UA) → 200, ~3,2 MB HTML. De
  pagina bevat de volledige coördinaten als JSON: `"coordinates":{"items":[{"lat":52.367034,"lng":4.901876,"alt":2.7,"t":0},…]}`, ~3.300 punten.
- Dezelfde pagina noemt `https://api.komoot.de/v007/tours/389075652/coordinates` — dat adres geeft
  **zonder login** `{"items":[{lat,lng,alt,t},…]}` terug. Let op: het id zonder de `e`-prefix;
  `/v007/smart_tours/e389075652` geeft 400.
- `…/tours/389075652.gpx` geeft 403: GPX-export is wel achter login.
- `og:title` geeft de naam ("De Amstel – Cycleseeing in and around Amsterdam"); `og:image` bevat
  ook een vereenvoudigde gecodeerde polyline (61 punten) als lichte terugvaloptie.
- **Risico:** ongedocumenteerd. Ontwerp zo dat de link de basis is en de lijn een extra die mag
  falen.

## BikeWind van binnen (APK-analyse 1.0.7)

APK van de Oppo gehaald (`pm path pl.pulse.bikewind`), manifest via `dumpsys package`,
strings uit `libapp.so`.

- **Stack:** Flutter, Isar, MapLibre, eigen tegels `tiles.bikewind.app/*.pmtiles`, Open-Meteo, GetX.
- **Importscherm:** zoekveld + vier ingangen: *Import from Strava*, *Import GPX* ("GPX and XML"),
  *Import FIT* ("Garmin FIT"), *Generate route*.
- **Bestanden:** `file_picker` plus een `VIEW`-intentfilter op `application/gpx+xml`, `application/xml`,
  `text/xml`, `application/octet-stream` (scheme `file`/`content`) — dus "Openen met BikeWind".
  **Geen `SEND`-filter: BikeWind staat niet in het deelmenu.**
- **Strava:** inloggen via de Strava-app (`/oauth/mobile/authorize`), redirect
  `go.bikewind.app/strava/callback`. Token-ruil en verversen lopen via een **eigen worker**
  (`/strava/exchange`, `/strava/refresh`, `/strava/revoke`, `/strava/sync-status`) zodat het
  client-geheim niet in de app zit; de data zelf haalt de app rechtstreeks van
  `https://www.strava.com/api/v3`: `/athlete/activities`, `/routes`, `/segments/starred`, streams.
  Drie bronnen: opgeslagen routes, recente activiteiten (instelbare periode), gesterde segmenten
  ("import them as short routes").
- **Importeren = lokale kopie:** "Downloading track from Strava…", "Import only the variant you want
  to keep." Routes staan in Isar op het toestel; niets naar de server.
- **Geen Komoot:** het woord komt in de binary niet voor.
- **Generator:** server-side (`/routes/generate-shape`), vormen driehoek/hart/cirkel/ovaal/trapezium/lijn
  + afstand + plek; op 2026-10-11 "currently available only in Poland".
- **Export:** GPX nu, FIT "als volgende".
- **Privacy-detail om te onthouden:** "Hide the start and end of the route by trimming the same
  distance from both sides."

## Hoe goedlopende apps het doen

- **WhatsApp, Google Maps:** staan in het deelmenu en vragen pas *daarna* waarheen ("Stuur naar…",
  "Opslaan in lijst…"). → **Overnemen:** Delen → Ridewindow → "Bij welke rit?" met de geplande ritten
  en "Nieuwe rit met deze route".
- **WhatsApp, YouTube:** herkennen een link zodra je plakt en tonen meteen een voorbeeld. →
  **Overnemen:** in de rit een plakveld dat zelf ziet dat het een Komoot- of Strava-link is en de
  titel toont.
- **Bewust anders dan BikeWind:** geen losse routebibliotheek (de route hoort bij een rit) en in
  het begin geen Strava-inlog.

## Twee ingangen

1. **Vanuit de bron-app:** route open → Delen → Ridewindow → kies rit (of nieuwe rit).
2. **Vanuit Ridewindow:** rit open → Route toevoegen → plak link / kies GPX of FIT / (later) uit Strava.
   Plus "Openen met Ridewindow" voor `.gpx`.

## Voorgestelde fases

1. **Link bij de rit** — Ridewindow in het deelmenu (`SEND` text/plain), link + titel bij de rit,
   tik opent de bron-app. Werkt voor elke app, raakt de server niet als de rit lokaal is.
2. **Komoot-lijn en kaartje** — toestel haalt de coördinaten op; kaartje, afstand, hoogtemeters.
   Falen = link blijft werken.
3. **GPX en FIT** — bestand kiezen + `VIEW`-intent.
4. **Route mee naar de groep** — Peloton en groepsritten tonen dezelfde route; vanaf hier gaat een
   route naar de server, binnen de grenzen van v4.3.
- **Later:** Strava met inloggen (vraagt een uitzondering op "geen Edge Functions" voor de
  token-ruil, zoals BikeWind's worker) en wind langs de route in de score.

## Risico's

- Komoot-endpoint is ongedocumenteerd en kan veranderen → link is de basis.
- Een route begint vaak bij de voordeur → bij delen met de groep (fase 4) begin/eind inkorten of
  bewust laten kiezen.
- Kaarttegels: Carto, 5M verzoeken/maand gratis (zie `ROUTES.md`), past binnen €0.
- Strava-API: nieuwe apps hebben "athlete capacity 1" tot Strava ze goedkeurt (zie #96).

## Open vragen voor de milestone-start

1. Echte kaart om in te zoomen, of eerst een silhouet van de lijn zonder tegels?
2. Strava met inloggen ooit wel of niet (en dus een server-uitzondering)?
3. Werkt de Komoot-coördinatenroute ook voor Joosts eigen privé-tours (met `share_token`)? Testen
   met een eigen tour vóór fase 2 gepland wordt.
4. Wat stuurt Strava's "Share To" precies mee? Testen door naar Ridewindow te delen zodra fase 1
   een ontvanger heeft.
