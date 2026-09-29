# Bikewind — concurrentieanalyse

**Onderzocht:** 2026-09-29
**Bron:** bikewind.app, Google Play listing, Apple App Store listing, privacy policy
**App:** BikeWind for Cyclists — PULSEFX (Janusz Czarnak-Plawinski, Polen)
**Versie onderzocht:** 1.0.7 (aug 2026)
**Downloads:** 100+ (Google Play), nog geen ratings zichtbaar

---

## Wat Bikewind is

Een app die wind en weer analyseert **langs een specifieke fietsroute**, niet op
een punt. Je importeert of genereert een route, en de app vertelt je per
routepunt wat de wind doet: tegenwind, zijwind, meewind. Daarmee beantwoordt
hij vragen als "welke kant op rijden" en "hoe laat vertrekken".

**Fundamenteel ander uitgangspunt dan Ridewindow.** Ridewindow vraagt: *wanneer*
is het beste moment om te fietsen, gegeven jouw beschikbaarheid? Bikewind
vraagt: *welke route* rijd je, *welke kant op*, en *hoe laat* vertrek je om de
wind mee te hebben? Ridewindow is tijdsgestuurd, Bikewind is routegestuurd.

## Feature-inventaris

### Kern

| # | Feature | Wat het doet |
|---|---------|--------------|
| 1 | **Windanalyse per route** | Tegenwind/zijwind/meewind per segment van een geïmporteerde of gegenereerde route. Niet "windkracht 4 in Amsterdam" maar "op km 12-18 heb je volle tegenwind" |
| 2 | **Route-import: GPX, FIT, Strava** | Importeer bestaande routes uit bestanden of direct vanuit Strava |
| 3 | **Route-generator** | Point-to-point routeplanning met alternatieven, in de app zelf |
| 4 | **Richtingvergelijking** | Vergelijk dezelfde route heen vs. omgekeerd: "welke kant op is vandaag beter" |
| 5 | **Conditiegrafieken langs de route** | Scrollbare grafieken voor temperatuur, gevoelstemperatuur, wind, windstoten, neerslag — uitgezet tegen afstand, niet tegen tijd |
| 6 | **Weer-tijdlijn op de kaart** | Animeer de voorspelling over de routekaart: "speel" het weer af over de tijd |
| 7 | **Live-navigatie** | Navigeer de route tijdens het rijden, met je snelheid relatief aan de wind |
| 8 | **KOM-segment ranking** | Rangschik Strava-segmenten op het beste 15-minutenvenster, meewind, hellingsgraad, rijrichting |
| 9 | **Best segment alerts** | Dagelijkse melding met de beste rij-gelegenheid op een geïmporteerd segment |
| 10 | **Rijtijd-schatting** | Duur geschat op basis van fietsprofiel, wind en hoogteprofiel |
| 11 | **Hoogte- en hellingsprofielen** | Klim- en daaldetectie per route |
| 12 | **Gevoelstemperatuur voor fietsers** | "Bike feels-like" — rekent de wind chill door op fietssnelheid |
| 13 | **Eigen locaties opslaan** | Meerdere locaties bewaren om het weer te checken |

### Privacy & data

| Aspect | Bikewind | Ridewindow |
|--------|----------|------------|
| Account vereist | Nee | Nee (optioneel sinds v3.0) |
| Route-opslag | Lokaal op toestel | n.v.t. (geen routes) |
| Weerdata | Open-Meteo, direct vanaf toestel | Open-Meteo, direct vanaf toestel |
| Strava-koppeling | Optioneel | Niet aanwezig |
| Anonieme telemetrie | App-installatie-ID, versie, land/stad via IP | Geen (of opt-in per v4.1) |

---

## Wat relevant is voor Ridewindow

Gerangschikt op hoe goed het past bij de kernwaarde ("de beste vensters om te
rijden, op basis van score en beschikbaarheid") en de bestaande constraints.

### Hoog — raakt de score of het venster direct

**1. Windrichting meenemen in de score (nu alleen windsnelheid)**

Ridewindow scoort wind als een getal (km/u), maar voor een fietser is 20 km/u
tegenwind een heel andere ervaring dan 20 km/u meewind. Bikewind laat zien dat
richting de belangrijkste dimensie is. Zelfs zonder routes zou een simpelere
versie al waarde toevoegen: als de gebruiker een voorkeursrichting heeft (bijv.
"ik rijd meestal rondjes ten noorden van de stad"), dan kan de score
tegenwind heen vs. meewind terug wegen.

*Impact op kernwaarde: hoog. Een score die 20 km/u wind neutraal behandelt
terwijl het pal tegen is, is fout — en de kernwaarde zegt expliciet: als de
score fout is, faalt de app.*

**2. Gevoelstemperatuur op fietssnelheid**

Bikewind rekent "bike feels-like": wind chill bij 25-30 km/u, niet bij
stilstand. Ridewindow heeft al `apparent_temperature` uit Open-Meteo, maar die
is berekend voor een staand persoon. Op de fiets is de effectieve wind chill
hoger. Dit is een relatief kleine aanpassing in de scoring engine met een
groot effect op de accuraatheid.

*Impact op kernwaarde: hoog. Zelfde reden als hierboven.*

**3. Route-import (GPX / Strava)**

Laat gebruikers hun vaste rondje importeren, zodat de score en het venster
niet alleen gelden voor "het weer op je thuislocatie" maar voor "het weer op
jouw rondje". Dit is een significante uitbreiding van het domeinmodel: een
`Route` met waypoints, en de scoring die per routepunt het weer ophaalt en
integreert.

*Impact op kernwaarde: hoog, maar effort is ook hoog. Het verandert de app
van "wanneer" naar "wanneer + waar". Past bij de constraint van €0/maand
(Open-Meteo is gratis), maar vraagt wel kaartweergave (kaart-tiles kosten
mogelijk geld of een keuze voor een gratis provider zoals OpenStreetMap/
Carto).*

*Alternatief dat 80% van de waarde pakt met 20% van de moeite: een
richtingvoorkeur in het profiel ("ik fiets meestal naar het noorden/
zuiden/..."), zodat de windscore richting meeneemt zonder een volledig
routemodel.*

### Middel — nuttig maar niet kern

**4. Richtingvergelijking ("welke kant op")**

Als Ridewindow routes zou kennen: "dit rondje is vandaag beter met de klok
mee". Alleen zinvol als #3 er is.

**5. Conditiegrafieken langs de route**

Per-km uitsplitsing van temperatuur, wind, neerslag. Visueel sterk, maar
vereist #3.

**6. Weer-tijdlijn-animatie op de kaart**

"Speel" het weer af over de route door de tijd heen. Mooi, maar vraagt #3 en
een kaartlaag.

**7. Rijtijd-schatting met wind**

Schat hoe lang een rit duurt op basis van afstand, wind en hoogte. Ridewindow
kent nu alleen de duur van het venster (die de gebruiker zelf kiest). Een
schatting zou kunnen helpen om te zeggen "dit venster van 2 uur is krap voor
dit rondje van 55 km bij deze wind".

### Laag — past niet of te ver weg

**8. Live-navigatie** — Ridewindow is een planningsapp, geen navigatieapp.
Dit is een bewust ander product.

**9. KOM-segment ranking** — competitief Strava-terrein. Ridewindow richt
zich op de casual fietser die wil weten wanneer het lekker weer is, niet op
KOM-jagers.

**10. Best segment alerts** — dagelijkse melding over een segment. Ridewindow
heeft al notificaties ("evening before", "morning of"). Een route-specifieke
variant zou pas zinvol zijn met #3.

**11. Route-generator** — een heel product op zich. Buiten scope.

**12. Eigen locaties opslaan** — Ridewindow heeft één locatie. Meerdere
locaties ("thuis" + "werk") zou relevant kunnen zijn, maar is geen
Bikewind-verrijking — het staat al op de backlog.

---

## Wat Ridewindow al beter doet

Bikewind heeft geen van deze dingen:

| Ridewindow-feature | Bikewind-equivalent |
|---|---|
| Beschikbaarheidsrooster (7x24) | Niet aanwezig |
| Venster-generatie ("za 09:00-13:00") | Niet aanwezig |
| Score-synthese (temp + regen + wind → één getal) | Niet aanwezig — toont ruwe data |
| Google Calendar-integratie | Niet aanwezig |
| Tolerantie-sliders | Niet aanwezig |
| Groepsritten / Peloton | Niet aanwezig |
| Accounts + sync | Niet aanwezig |

De twee apps zijn complementair: Bikewind zegt *waar* en *welke kant op*,
Ridewindow zegt *wanneer* en *of het bij jou past*. Een gebruiker die beide
installeert, dekt het hele vlak.

---

## Advies voor de backlog

Drie items om te overwegen, in volgorde van waarde-per-effort:

1. **Windrichting in de score** (S/M). Voeg een richtingscomponent toe aan de
   windscore. Minimaal: toon de windrichting op de ride cards (al gedaan,
   backlog #2) en gebruik hem in de score. Maximaal: laat de gebruiker een
   voorkeursrichting kiezen en weeg tegenwind zwaarder dan meewind.

2. **Bike feels-like temperatuur** (S). Pas de gevoelstemperatuur aan voor
   fietssnelheid. Open-Meteo levert `apparent_temperature` al; een
   correctiefactor voor 25 km/u is een kleine aanpassing in de scoring engine.

3. **GPX-import voor routegebonden score** (L). Dit is de grote stap: importeer
   een route, haal het weer op per routepunt, bereken de score langs de hele
   route, en genereer vensters die niet alleen "wanneer" maar ook "hoeveel
   tegenwind heb je op dit rondje" meenemen. Dit verdient een eigen milestone
   en past niet in v4.1. Overwegen voor v5.0.

---

## Bronnen

- [bikewind.app](https://bikewind.app/)
- [Google Play](https://play.google.com/store/apps/details?id=pl.pulse.bikewind)
- [Apple App Store](https://apps.apple.com/us/app/bikewind-for-cyclists/id6771945952)
- [Privacy policy](https://bikewind.app/privacy.html)
